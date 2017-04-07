package MuScope::Controller::Sample;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use String::Trim qw(trim);

# ----------------------------------------------------------------------
#sub info {
#    my $self = shift;
#
#    $self->respond_to(
#        json => sub {
#            $self->render(json => { 
#                list => {
#                    params => {
#                        project_id => {
#                            type => 'int',
#                            desc => 'value of the project id to which the '
#                                 .  'samples belong',
#                            required => 'false',
#                        }
#                    },
#                    results => 'a list of samples',
#                },
#
#                search => {
#                    params => {
#                        latitude_min => {
#                            type     => 'int',
#                            desc     => 'latitude_min',
#                            required => 'false',
#                        },
#                        latitude_max => {
#                            type     => 'int',
#                            desc     => 'latitude_max',
#                            required => 'false',
#                        },
#                        longitude_min => {
#                            type     => 'int',
#                            desc     => 'longitude_min',
#                            required => 'false',
#                        },
#                        longitude_max => {
#                            type     => 'int',
#                            desc     => 'longitude_max',
#                            required => 'false',
#                        },
#                    },
#                    results => 'search results',
#                },
#
#                view => {
#                    params => {
#                        sample_id => {
#                            type => 'int',
#                            desc => 'the sample id',
#                            required => 'true'
#                        }
#                    },
#                    results => 'the details of a sample',
#                }
#            });
#        }
#    );
#}

# ----------------------------------------------------------------------
sub list {
    my $self   = shift;
    my $db     = $self->db;
    my $schema = $self->db->schema;
    my $where  = {};

    if (my $inv_id = $self->param('investigator_id')) {
        $where->{'investigator_id'} = $inv_id;
    }

    my @Samples = $schema->resultset('Sample')->search($where);

    $self->respond_to(
        json => sub {
            $self->render( 
                json => [ 
                    map {{
                        $_->get_inflated_columns,
                        latitude => $_->cast->station->latitude,
                        longitude => $_->cast->station->longitude,
                    }} 
                    @Samples 
                ]
            );
        },

        html => sub {
            $self->layout('default');
            $self->render( title => 'Samples', samples => \@Samples );
        },

#        txt => sub {
#            $self->render( text => dump($samples) );
#        },
    );
}

# ----------------------------------------------------------------------
sub view {
    my $self      = shift;
    my $sample_id = $self->param('sample_id') or die 'No sample id';
    my $db        = $self->db;
    my $dbh       = $db->dbh;
    my $schema    = $db->schema;

    if ($sample_id =~ /^\D/) {
        for my $fld (qw[ sample_name sample_acc ]) {
            my $sql = "select sample_id from sample where $fld=?";
            if (my $id = $dbh->selectrow_array($sql, {}, $sample_id)) {
                $sample_id = $id;
                last;    
            }
        }
    }

    my ($Sample) = $schema->resultset('Sample')->find($sample_id);
    if (!$Sample) {
        return $self->reply->exception("Bad sample id ($sample_id)");
    }

    $self->respond_to(
        json => sub {
            $self->render( json => { $Sample->get_inflated_columns });
        },

        html => sub {
            $self->layout('default');

            $self->render( 
                sample => $Sample,
            );
        },

        txt => sub {
            $self->render( text => dump({ 
                sample => $Sample,
            }));
        },
    );
}

# ----------------------------------------------------------------------
sub search {
    my $self = shift;
    $self->layout('default');
    $self->render( title => 'Samples Search', session => $self->session );
}

# ----------------------------------------------------------------------
sub search_param_values {
    my $self    = shift;
    my $field   = $self->param('field')   or return;
    my $db      = $self->db;
    my $mongo   = $db->mongo;
    my $mdb     = $mongo->get_database('muscope');
    my $result  = $mdb->run_command([
       distinct => 'sample',
       key      => $field,
       query    => {}
    ]);
    my %param_types = map { $_->[0], $_->[1] } $self->_search_params();
    my $type = %param_types{ $field } || '';

    my @values;
    if ($result->{'ok'}) {
        my $by  = $type eq 'number' ? sub { $a <=> $b } : sub { $a cmp $b };
        @values = sort $by @{ $result->{'values'} };
    }

    $self->respond_to(
        json => sub {
            $self->render( json => \@values );
        },

        txt => sub {
            $self->render( text => dump(\@values) );
        },
    );
}

# ----------------------------------------------------------------------
sub _search_params {
    my $self  = shift;
    my $db    = $self->db;
    my $dbh   = $db->dbh;
    my $mongo = $db->mongo;
    my $mdb   = $mongo->get_database('muscope');
    my $coll  = $mdb->get_collection('sampleKeys');
    my @types;
    for my $ref (
        sort { $a->[0] cmp $b->[0] }
        grep { $_->[0] ne '_id' }
        grep { $_->[0] !~ /(\.floatApprox|\.bottom|\.top|text|none)/i }
        map  { [$_->{'_id'}{'key'}, lc $_->{'value'}{'types'}[0]] }
        $coll->find->all()
    ) {
        my ($name, $type) = @$ref;
        my $unit = '';
        if ( $name =~ /^(?:core|ctd)__(.+)/i ) {
            my $ctd_type = $1;
            $unit = $dbh->selectrow_array(
                'select unit from sample_attr_type where type=?', {}, $ctd_type
            );
        }
        push @types, [$name, $type, $unit];
    }

    return @types;
}

# ----------------------------------------------------------------------
sub search_params {
    my $self   = shift;
    my @params = $self->_search_params();

    $self->respond_to(
        json => sub {
            $self->render( json => \@params );
        },

        txt => sub {
            $self->render( text => dump(\@params) );
        },
    );
}

# ----------------------------------------------------------------------
sub search_results {
    my $self        = shift;
    my $db          = $self->db;
    my $dbh         = $db->dbh;
    my $mongo       = $db->mongo;
    my $mdb         = $mongo->get_database('muscope');
    my $coll        = $mdb->get_collection('sample');
    my @param_types = $self->_search_params();

    my %search;
    for my $ptype (@param_types) {
        my ($name, $type) = @$ptype;
        if (my @vals = 
            map { split /\s*,\s*/ } @{ $self->every_param($name) || [] }
        ) {
            if (@vals == 1) {
                $search{$name} = $vals[0];
            }
            else {
                $search{$name} = { '$in' => \@vals };
            }
        }
        else {
            my $min = $self->param('min_'.$name);
            my $max = $self->param('max_'.$name);

            next unless (defined $min && $min ne '')
                     || (defined $max && $max ne '');

            if ($min == $max) {
                $search{$name}{'$eq'} = $min;
            }
            else {
                if (defined $min && $min =~ /\d+/) {
                    $search{$name}{'$gte'} = $min;
                }

                if (defined $max && $max =~ /\d+/) {
                    $search{$name}{'$lte'} = $max;
                }
            }
        }
    }

    my (@samples, @search_params);
    if (%search) {
        @search_params = map { s/^(max|min)_//; $_ } keys %search;
        my @return_fields; 

        if ($self->param('download')) {
            @return_fields = map { $_->[0] } $self->_search_params;
        }
        else {
            @return_fields = (
                'Sample__cruise_id', 
                'Sample__cruise_name',
                'Sample__sample_id',
                'Sample__sample_name', 
                'Cast__latitude', 
                'Cast__longitude',
                @search_params
            );
        }

        my %fields = map { $_, 1 } @return_fields;
        my $cursor = $coll->find(\%search); #->fields(\%fields);

        for my $sample ($cursor->all) {
            $sample->{'search_values'} = [
                map { $sample->{ $_ } } @search_params
            ];

            push @samples, $sample;
        }
    }

    $self->respond_to(
        json => sub {
            $self->render( json      => { 
                samples              => \@samples, 
                search_fields        => \@search_params,
                search_fields_pretty => [
                    map { s/__/: /; s/_/ /g; ucfirst($_) } @search_params
                ],
            });
        },

        tab => sub {
            my $text = '';

            if (@samples > 0) {
                my @flds = sort keys %{ $samples[0] };
                my @data = (join "\t", @flds);

                for my $sample (@samples) {
                    push @data, join "\t", map { $sample->{$_} // '' } @flds;
                }

                $text = join "\n", @data;
            }

            $self->render( text => $text );
        },

        txt => sub {
            $self->render( text => dump(\@samples) );
        },
    );
}

# ----------------------------------------------------------------------
sub search_results_map {
    my $self = shift;
    $self->layout('default');
    $self->render(title => 'Samples Search Map View');
}

# ----------------------------------------------------------------------
sub map_search {
    my $self = shift;
    $self->layout('default');
    $self->render(title => 'Samples Map Search');
}

# ----------------------------------------------------------------------
sub map_search_results {
    my $self = shift;
    my $dbh  = $self->db->dbh;
    my $sql  = q'
        select cr.cruise_id, cr.cruise_name, 
               i.investigator_id, i.investigator_name,
               s.sample_id, s.sample_name, st.latitude, st.longitude
        from   sample s, cast c, station st, cruise cr, investigator i
        where  s.investigator_id=i.investigator_id
        and    s.cast_id=c.cast_id
        and    c.station_id=st.station_id
        and    st.cruise_id=cr.cruise_id
    ';

    my @samples;
    if (my $bounds = $self->param('bounds')) {
        my @tmp;
        for my $area (split(/:/, $bounds)) {
            my ($lat_lo, $lng_lo, $lat_hi, $lng_hi) = split(',', $area);

            ($lat_lo, $lat_hi) = sort { $a <=> $b } ($lat_lo, $lat_hi);
            ($lng_lo, $lng_hi) = sort { $a <=> $b } ($lng_lo, $lng_hi);

            my $run = $sql . sprintf(
                q'
                    and    (st.latitude  >= %s and st.latitude  <= %s)
                    and    (st.longitude >= %s and st.longitude <= %s)
                ',
                $lat_lo, $lat_hi, $lng_lo, $lng_hi
            );

            push @tmp, @{ 
                $dbh->selectall_arrayref($run, { Columns => {} }) 
            };
        }

        my %seen;
        for my $sample (@tmp) {
            unless ($seen{ $sample->{'sample_id'} }++) {
                push @samples, $sample;
            }
        }
    }
    else {
        @samples = @{ $dbh->selectall_arrayref($sql, { Columns => {} }) };
    }

    $self->respond_to(
        json => sub {
            $self->render( json => { samples => \@samples } );
        },

        tab => sub {
            my $text = '';

            if (@samples > 0) {
                my @flds = sort keys %{ $samples[0] };
                my @data = (join "\t", @flds);

                for my $sample (@samples) {
                    push @data, join "\t", map { $sample->{$_} // '' } @flds;
                }

                $text = join "\n", @data;
            }

            $self->render( text => $text );
        },

        txt => sub {
            $self->render( text => dump(\@samples) );
        },
    );
}

# ----------------------------------------------------------------------
sub sample_file_list {
    my $self      = shift;
    my $sample_id = $self->param('sample_id');
    my $schema    = $self->db->schema;
    my $Sample    = $schema->resultset('Sample')->find($sample_id) or 
        return $self->reply->exception("Bad sample id ($sample_id)");

    my @files = map { 
        { type => $_->sample_file_type->type, location => $_->file } 
    } $Sample->sample_files->all;

    $self->respond_to(
        json => sub {
            $self->render( json => \@files );
        },

        tab => sub {
            my $text = '';

            if (@files) {
                my @flds = sort keys %{ $files[0] };
                my @data = (join "\t", @flds);
                for my $file (@files) {
                    push @data, join "\t", map { $file->{$_} } @flds;
                }
                $text = join "\n", @data;
            }

            $self->render( text => $text );
        },

        txt => sub {
            $self->render( text => dump(\@files) );
        },
    );
}

1;
