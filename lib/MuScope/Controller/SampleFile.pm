package MuScope::Controller::SampleType;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub view {
    my $self           = shift;
    my $sample_type_id = $self->param('sample_type_id');
    my $SampleType 
      = $self->db->schema->resultset('SampleType')->find($sample_type_id)
      or return $self->reply->exception("Bad sample_type id ($sample_type_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $SampleType->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => sprintf("Sample Type: %s", $SampleType->sample_type),
                sample_type => $SampleType,
            );
        },

        txt => sub {
            $self->render( text => dump({
                sample_type => { $SampleType->get_inflated_columns() },
            }))
        },
    );
}

1;
