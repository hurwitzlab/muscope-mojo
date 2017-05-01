package MuScope::Controller::Cruise;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use Spreadsheet::WriteExcel;

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
    my @Cruises = $self->db->schema->resultset('Cruise')->all;
    my $struct  = sub { map { { $_->get_inflated_columns } } @Cruises };

    $self->respond_to(
        json => sub {
            $self->render( json => [ $struct->() ]);
        },

        html => sub {
            $self->layout('default');

            $self->render( 
                cruises => \@Cruises, 
                title   => 'Cruises',
            );
        },

        txt => sub {
            $self->render( text => dump($struct->()) );
        },

        tab => sub {
            my $out = $self->tablify($struct->());
            $self->render( text => $out );
        },
    );
}

# ----------------------------------------------------------------------
sub download {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id');
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
                    or die "Bad cruise id ($cruise_id)\n";
    my $workbook  = Spreadsheet::WriteExcel->new(
        sprintf('muscope-cruise-%s.xls', $Cruise->id)
    );

    my $cruise_ws   = $workbook->add_worksheet('cruise');
    my $cruise_cols = $Cruise->columns;
    $cruise_ws->write_row('A1', [ $Cruise->columns ]);

    $self->render(data => $cruise_ws);
}

# ----------------------------------------------------------------------
sub view {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id');
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
                    or die "Bad cruise id ($cruise_id)\n";

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
            $self->render( text => dump(cruise => 
                    {$Cruise->get_inflated_columns()}));
        },

        xls => sub {
        }
    );
}

1;
