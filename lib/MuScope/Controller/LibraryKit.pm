package MuScope::Controller::LibraryKit;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub view {
    my $self           = shift;
    my $library_kit_id = $self->param('library_kit_id');
    my $LibraryKit 
      = $self->db->schema->resultset('LibraryKit')->find($library_kit_id)
      or return $self->reply->exception("Bad library_kit_id ($library_kit_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $LibraryKit->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => 
                sprintf("Library Kit &quot;%s&quot;", $LibraryKit->library_kit),
                library_kit => $LibraryKit,
            );
        },

        txt => sub {
            $self->render( text => dump({
                library_kit => { $LibraryKit->get_inflated_columns() },
            }))
        },
    );
}

1;
