package MuScope::Controller::SequencingMethod;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub view {
    my $self      = shift;
    my $id        = $self->param('sequencing_method_id');
    my $SeqMethod = $self->db->schema->resultset('SequencingMethod')->find($id)
      or return $self->reply->exception("Bad sequencing_method id ($id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $SeqMethod->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => 
                 sprintf("Sequencing Method &quot;%s&quot;", $SeqMethod->sequencing_method),
                method => $SeqMethod,
            );
        },

        txt => sub {
            $self->render( text => dump({
                method => { $SeqMethod->get_inflated_columns() },
            }))
        },
    );
}

1;
