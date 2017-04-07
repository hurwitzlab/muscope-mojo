package MuScope::Controller::Cruise;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

## ----------------------------------------------------------------------
#sub browse {
#    my $self     = shift;
#    my $dbh      = $self->db->dbh;
# 
#    my @cruises = map { 
#            $_->{'url'} = 
#                sprintf('/cruise/list?domain=%s', $_->{'domain_name'});
#            $_;
#        }
#        @{ 
#            $dbh->selectall_arrayref(
#            q[
#                select   count(*) as count, d.domain_name
#                from     cruise p, domain d, cruise_to_domain p2d
#                where    p.cruise_id=p2d.cruise_id
#                and      p2d.domain_id=d.domain_id
#                group by 2
#                order by 2
#            ],
#            { Columns => {} }
#        )};
#
#    $self->respond_to(
#        json => sub {
#            $self->render( json => \@cruises );
#        },
#
#        html => sub {
#            $self->layout('default');
#
#            $self->render( 
#                cruises => \@cruises,
#                title    => 'Cruises by Domain of Life',
#            );
#        },
#
#        tab => sub {
#            my $text = '';
#
#            if (@cruises) {
#                my @flds = sort keys %{ $cruises[0] };
#                my @data = (join "\t", @flds);
#                for my $cruise (@cruises) {
#                    push @data, join "\t", map { $cruise->{$_} } @flds;
#                }
#                $text = join "\n", @data;
#            }
#
#            $self->render( text => $text );
#        },
#
#        txt => sub {
#            $self->render( text => dump(\@cruises) );
#        },
#    );
#}
#
## ----------------------------------------------------------------------
#sub info {
#    my $self = shift;
#
#    $self->respond_to(
#        json => sub {
#            $self->render(json => { 
#                browse => {
#                    results => 'a list of the number of cruises associated '
#                            .  'with a domain of life'
#                },
#
#                list => {
#                    params => {
#                        domain => {
#                            type => 'str',
#                            desc => 'a domain of life to which '
#                                 .  'cruises belong',
#                            required => 'false',
#                        }
#                    },
#                    results => 'a list of combined assemblies',
#                },
#
#                view => {
#                    params => {
#                        cruise_id => {
#                            type     => 'int',
#                            desc     => 'the cruise id',
#                            required => 'true'
#                        }
#                    },
#                    results => 'the details of a cruise',
#                }
#            });
#        }
#    );
#}

# ----------------------------------------------------------------------
sub list {
    my $self    = shift;
    my $db      = $self->db;
    my $dbh     = $db->dbh;
    my $schema  = $db->schema;
    my $Cruises = $schema->resultset('Cruise')->search_rs;

    $self->respond_to(
        json => sub {
            $self->render( json => [ 
               map { $_->get_inflated_columns } $Cruises 
            ]);
        },

        html => sub {
            $self->layout('default');

            $self->render( 
                cruises => $Cruises, 
                title   => 'Cruises',
            );
        },

        txt => sub {
            $self->render( text => dump($Cruises) );
        },
    );
}

# ----------------------------------------------------------------------
sub view {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id');
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
      or return $self->reply->exception("Bad cruise id ($cruise_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $Cruise->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => sprintf("Cruise: %s", $Cruise->cruise_name),
                cruise => $Cruise,
            );
        },

        txt => sub {
            $self->render( text => dump({
                cruise => { $Cruise->get_inflated_columns() },
            }))
        },
    );
}

1;
