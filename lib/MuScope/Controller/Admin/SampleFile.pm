package MuScope::Controller::Admin::SampleFile;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create {
    my $self      = shift;
    my $sample_id = $self->param('sample_id');
    my $schema    = $self->db->schema;
    my $Sample    = $schema->resultset('Sample')->find($sample_id)
                    or die "Bad sample_id ($sample_id)\n";

    $self->layout('admin');
    $self->render(
        sample => $Sample,
        sample_file_types 
            => $schema->resultset('SampleFileType')->search_rs({},
               { order_by => { -asc => 'type' } }),
    );
}

# ----------------------------------------------------------------------
sub insert {
    my $self      = shift;
    my $sample_id = $self->param('sample_id') or die "Missing sample_id\n";
    my $file      = $self->param('file')      or die "Missing file\n";
    my $type_id   = $self->param('sample_file_type_id') 
                    or die "Missing sample_file_type_id\n";
    my $File      = $self->db->schema->resultset('SampleFile')->create({
        sample_file_type_id => $type_id,
        sample_id           => $sample_id,
        file                => $file,
    });

    return $self->redirect_to("/admin/sample/edit/$sample_id");
}

# ----------------------------------------------------------------------
sub edit {
    my $self    = shift;
    my $file_id = $self->param('sample_file_id');
    my $schema  = $self->db->schema;
    my $File    = $schema->resultset('SampleFile')->find($file_id)
                  or die "Bad sample_file_id ($file_id)\n";

    $self->layout('admin');
    $self->render( 
        title       => 'Edit Sample Fileibute',
        sample_file => $File,
        sample_file_types 
            => $schema->resultset('SampleFileType')->search_rs({},
               { order_by => { -asc => 'type' } }),
    );
}

# ----------------------------------------------------------------------
sub delete {
    my $self      = shift;
    my $file_id   = $self->param('sample_file_id');
    my $File      = $self->db->schema->resultset('SampleFile')->find($file_id)
                    or die "Bad sample_file_id ($file_id)\n";
    my $sample_id = $File->sample_id;
    $File->delete;

    return $self->redirect_to("/admin/sample/edit/$sample_id");
}

# ----------------------------------------------------------------------
sub update {
    my $self    = shift;
    my $file_id = $self->param('sample_file_id');
    my $File    = $self->db->schema->resultset('SampleFile')->find($file_id)
                  or die "Bad sample_file_id ($file_id)\n";

    for my $fld (qw[file sample_file_type_id]) {
        my $val = $self->param($fld) or next;
        $File->$fld($val);
        $File->update;
    }

    return $self->redirect_to("/admin/sample/edit/" . $File->sample_id);
}

1;
