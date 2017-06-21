package MuScope::Controller::Admin::Sample;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create {
    my $self    = shift;
    my $cast_id = $self->param('cast_id');
    my $Cast    = $self->db->schema->resultset('Cast')->find($cast_id)
                  or die "Bad cast_id ($cast_id)\n";

    $self->layout('admin');
    $self->render(cast => $Cast);
}

# ----------------------------------------------------------------------
sub insert {
    my $self    = shift;
    my $cast_id = $self->param('cast_id')     or die "Missing cast_id\n";
    my $name    = $self->param('sample_name') or die "Missing sample_name\n";
    my $Sample  = $self->db->schema->resultset('Sample')->create({
                      cast_id     => $cast_id,
                      sample_name => $name,
                  });

    return $self->redirect_to("/admin/sample/edit/" . $Sample->id);
}

# ----------------------------------------------------------------------
sub edit {
    my $self      = shift;
    my $sample_id = $self->param('sample_id');
    my $schema    = $self->db->schema;
    my $Sample    = $schema->resultset('Sample')->find($sample_id)
                    or die "Bad sample id ($sample_id)\n";

    $self->layout('admin');
    $self->render( 
        title         => 'Edit Sample',
        sample        => $Sample,
        investigators 
            => $schema->resultset('Investigator')->search_rs({}, 
               { order_by => { -asc => [qw/last_name first_name/] } }),
    );
}

# ----------------------------------------------------------------------
sub update {
    my $self      = shift;
    my $sample_id = $self->param('sample_id') or die "No sample_id\n";
    my $Sample    = $self->db->schema->resultset('Sample')->find($sample_id)
                    or die "Bad sample id ($sample_id)\n";

    my @flds = qw[sample_number seq_name filter_type_id
        sample_type_id investigator_id sequencing_method_id
        library_kit_id];

    for my $fld (@flds) {
        my $val = $self->param($fld) or next;
        $Sample->$fld($val);
        $Sample->update;
    }

    return $self->redirect_to("/admin/sample/edit/" . $Sample->id);
}

1;
