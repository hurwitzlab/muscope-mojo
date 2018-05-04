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
    my $self    = shift;
    my $schema  = $self->db->schema;
    my $inv_ids = $self->db->dbh->selectall_arrayref(
        q[
            select i.investigator_id, count(s2i.sample_id) as num_samples
            from   investigator i, sample_to_investigator s2i
            where  i.investigator_id=s2i.investigator_id
            group by 1
            having num_samples > 0
        ]
    );
    
    my @Invs = map { $schema->resultset('Investigator')->find($_->[0]) } 
               @$inv_ids;
    my $data = sub { map { {$_->get_inflated_columns()} } @Invs };

    $self->respond_to(
        json => sub {
            $self->render( json => [ $data->() ]);
        },

        html => sub {
            $self->layout('default');
            $self->render( 
                title         => 'Investigators', 
                investigators => \@Invs 
            );
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
