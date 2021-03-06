package MuScope::Controller::Cart;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use Data::GUID;
use List::Util 'uniq';
use JSON::XS;
use File::Temp 'tempfile';

# ----------------------------------------------------------------------
sub add {
    my $self = shift;

    unless ($self->session->{'id'}) {
        $self->session(id => Data::GUID->new->as_string);
    }

    if (my $item = $self->param('item')) {
        my @current = @{ $self->session->{'items'} || [] };
        $self->session(items => [uniq(@current, split(/\s*,\s*/, $item))]);
    }

    return $self->redirect_to("/cart/view");
}

# ----------------------------------------------------------------------
sub icon {
    my $self = shift;

    $self->layout('');
    $self->render(session => $self->session);
}

# ----------------------------------------------------------------------
sub file_types {
    my $self    = shift;
    my $schema  = $self->db->schema;
    my $session = $self->session;

    my %file_type;
    for my $sample_id (@{ $session->{'items'} || [] }) {
        if (my $Sample = $schema->resultset('Sample')->find($sample_id)) {
            for my $File ($Sample->sample_files) {
                $file_type{ $File->sample_file_type_id }++
            }
        }
    }

    my @types;
    for my $id (keys %file_type) {
        if (my ($FileType) = $schema->resultset('SampleFileType')->find($id)) {
            push @types, { 
                sample_file_type_id => $FileType->id,
                sample_file_type    => $FileType->type,
            };
        }
    }

    @types = sort { $a->{'sample_file_type'} cmp $b->{'sample_file_type'} }
             @types;

    $self->respond_to(
        json => sub {
            $self->render( json => \@types );
        },

        tab => sub {
            my $out = $self->tablify(@types);
            $self->render( text => $out );
        },

        txt => sub {
            $self->render( text => dump(\@types));
        },
    );
}

# ----------------------------------------------------------------------
sub files {
    my $self    = shift;
    my $schema  = $self->db->schema;
    my $session = $self->session;

    my @FileTypes;

    if (my @type_ids = split(/\s*,\s*/, $self->param('file_type_id'))) {
        @FileTypes = map { $schema->resultset('SampleFileType')->find($_) }
                     @type_ids;
    }
    elsif (my @file_types = split(/\s*,\s*/, $self->param('file_type'))) {
        @FileTypes = 
            map { $schema->resultset('SampleFileType')->search({ type => $_ }) }
            @file_types;
    }

    my @files;
    for my $sample_id (@{ $session->{'items'} || [] }) {
        if (@FileTypes) {
            push @files, map { 
                $schema->resultset('SampleFile')->search({
                    sample_id           => $sample_id,
                    sample_file_type_id => $_->id
                });
            } @FileTypes;
        }
        else {
            push @files, $schema->resultset('SampleFile')->search({ 
                sample_id => $sample_id
            });
        }
    }

    my $struct = sub {
        if ($self->param('file_list')) {
            map { s{^/iplant/home/}{agave://data.iplantcollaborative.org/}; $_ }
            map { $_->file } @files;
        }
        else {
            map { 
                sample_file_id => $_->id, 
                sample_id      => $_->sample_id, 
                sample_name    => $_->sample->sample_name,
                file           => $_->file,
                type           => $_->sample_file_type->type,
            },
            @files;
        }
    };

    $self->respond_to(
        json => sub {
            $self->render( json => [$struct->()] );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title   => 'View Files',
                session => $session,
                files   => \@files,
            );
        },

        tab => sub {
            my $out = $self->tablify($struct->());
            $self->render( text => $out );
        },

        txt => sub {
            $self->render( text => join ';', $struct->())
        },
    );
}

# ----------------------------------------------------------------------
sub remove {
    my $self = shift;

    if (my $item = $self->param('item')) {
        my %remove  = map { $_, 1 } split(/\s*,\s*/, $item);
        my @current = @{ $self->session->{'items'} || [] };
        $self->session(items => [
            grep { $remove{ $_ } ? () : $_ } @current
        ]);
    }

    return $self->redirect_to("/cart/view");
}

# ----------------------------------------------------------------------
sub purge {
    my $self = shift;

    $self->session(items => []);

    return $self->redirect_to("/cart/view");
}

# ----------------------------------------------------------------------
sub view {
    my $self    = shift;
    my $schema  = $self->db->schema;
    my $session = $self->session;

    my @samples;
    my %file_type_id;
    for my $sample_id (@{ $session->{'items'} || [] }) {
        my $Sample = $schema->resultset('Sample')->find($sample_id);
        push @samples, $Sample;
        for my $File ($Sample->sample_files) {
            $file_type_id{ $File->sample_file_type->id }++;
        }
    }

    my @FileTypes = map $schema->resultset('SampleFileType')->find($_),
                    keys %file_type_id;

    my $struct = sub {
        map { 
            sample_id   => $_->id, 
            sample_name => $_->sample_name,
            sample_acc  => $_->sample_name,
            cruise_id   => $_->cruise_id,
            cruise_name => $_->cruise->cruise_name,
        },
        @samples;
    };

    $self->respond_to(
        json => sub {
            $self->render( json => [$struct->()] );
        },

        html => sub {
            my $conf = $self->config;

            $self->layout('default');

            $self->render(
                title      => 'View Cart',
                session    => $session,
                samples    => \@samples,
                file_types => \@FileTypes,
                apps       => $conf->{'apps'},
            );
        },

        tab => sub {
            my $out = $self->tablify($struct->());
            $self->render( text => $out );
        },

        txt => sub {
            $self->render( text => dump($struct->()) )
        },
    );
}

1;
