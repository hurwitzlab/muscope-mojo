package MuScope::Controller::FilterType;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub view {
    my $self           = shift;
    my $filter_type_id = $self->param('filter_type_id');
    my $FilterType 
      = $self->db->schema->resultset('FilterType')->find($filter_type_id)
      or return $self->reply->exception("Bad filter_type id ($filter_type_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $FilterType->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => sprintf("Filter Type: %s", $FilterType->filter_type),
                filter_type => $FilterType,
            );
        },

        txt => sub {
            $self->render( text => dump({
                filter_type => { $FilterType->get_inflated_columns() },
            }))
        },
    );
}

1;
