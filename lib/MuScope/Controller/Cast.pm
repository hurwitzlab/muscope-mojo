package MuScope::Controller::Cast;

use Mojo::Base 'Mojolicious::Controller';

# ----------------------------------------------------------------------
sub view {
    my $self    = shift;
    my $cast_id = $self->param('cast_id');
    my $Cast    = $self->db->schema->resultset('Cast')->find($cast_id)
      or return $self->reply->exception("Bad cast id ($cast_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $Cast->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => sprintf("Cast: %s", $Cast->cast_number),
                cast => $Cast,
            );
        },

        txt => sub {
            $self->render( text => dump({
                cast => { $Cast->get_inflated_columns() },
            }))
        },
    );
}

1;
