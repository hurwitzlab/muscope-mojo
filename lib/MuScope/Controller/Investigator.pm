package MuScope::Controller::Investigator;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use String::Trim qw(trim);

# ----------------------------------------------------------------------
sub info {
    my $self = shift;

    $self->respond_to(
        json => sub {
            $self->render(json => { 
                list => {
                    results => 'a list of investigators',
                },

                view => {
                    params => {
                        investigator_id => {
                            type => 'int',
                            desc => 'the investigator id',
                            required => 'true'
                        }
                    },
                    results => 'the details of an investigator',
                }
            });
        }
    );
}

# ----------------------------------------------------------------------
sub list {
    my $self   = shift;
    my $schema = $self->db->schema;
    my $Invs   = $schema->resultset('Investigator')->search(
        { investigator_id => { '>', '1' } }
    );
    my $data   = sub { map { {$_->get_inflated_columns()} } $Invs->all() };

    $self->respond_to(
        json => sub {
            $self->render( json => [ $data->() ]);
        },

        html => sub {
            $self->layout('default');
            $self->render( title => 'Investigators', investigators => $Invs );
        },

        txt => sub {
            $self->render( text => dump($data->()) );
        },

        tab => sub {
            my $text = $self->tablify($data->());
            $self->render( text => $text );
        },
    );
}

# ----------------------------------------------------------------------
sub view {
    my $self      = shift;
    my $inv_id    = $self->param('investigator_id') or die 'No investigator_id';
    my $schema    = $self->db->schema;

    my ($Inv) = $schema->resultset('Investigator')->find($inv_id);
    if (!$Inv) {
        return $self->reply->exception("Bad investigator id ($inv_id)");
    }

    $self->respond_to(
        json => sub {
            $self->render( json => { $Inv->get_inflated_columns() });
        },

        html => sub {
            $self->layout('default');

            $self->render( 
                title        => 'View Investigator',
                investigator => $Inv,
            );
        },

        txt => sub {
            $self->render( text => dump({ 
                investigator => { $Inv->get_inflated_columns() }
            }));
        },
    );
}

1;
