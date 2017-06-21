package MuScope::Controller::SampleFile;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub view {
    my $self           = shift;
    my $sample_file_id = $self->param('sample_file_id');
    my $SampleFile 
      = $self->db->schema->resultset('SampleFile')->find($sample_file_id)
      or return $self->reply->exception("Bad sample_file id ($sample_file_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $SampleFile->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => sprintf("Sample File: %s", $SampleFile->file),
                sample_file => $SampleFile,
            );
        },

        txt => sub {
            $self->render( text => dump({
                sample_file => { $SampleFile->get_inflated_columns() },
            }))
        },
    );
}

1;
