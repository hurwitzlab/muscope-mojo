package MuScope::Controller::Admin::SampleAttr;

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
        sample_attr_types 
            => $schema->resultset('SampleAttrType')->search_rs({},
               { order_by => { -asc => 'type' } }),
    );
}

# ----------------------------------------------------------------------
sub insert {
    my $self      = shift;
    my $sample_id = $self->param('sample_id') or die "Missing sample_id\n";
    my $value     = $self->param('value')     or die "Missing value\n";
    my $type_id   = $self->param('sample_attr_type_id') 
                    or die "Missing sample_attr_type_id\n";
    my $Attr      = $self->db->schema->resultset('SampleAttr')->create({
        sample_attr_type_id => $type_id,
        sample_id           => $sample_id,
        value               => $value,
    });

    return $self->redirect_to("/admin/sample/edit/$sample_id");
}

# ----------------------------------------------------------------------
sub edit {
    my $self    = shift;
    my $attr_id = $self->param('sample_attr_id');
    my $schema  = $self->db->schema;
    my $Attr    = $schema->resultset('SampleAttr')->find($attr_id)
                  or die "Bad sample_attr_id ($attr_id)\n";

    $self->layout('admin');
    $self->render( 
        title       => 'Edit Sample Attribute',
        sample_attr => $Attr,
        sample_attr_types 
            => $schema->resultset('SampleAttrType')->search_rs({},
               { order_by => { -asc => 'type' } }),
    );
}

# ----------------------------------------------------------------------
sub delete {
    my $self      = shift;
    my $attr_id   = $self->param('sample_attr_id');
    my $Attr      = $self->db->schema->resultset('SampleAttr')->find($attr_id)
                    or die "Bad sample_attr_id ($attr_id)\n";
    my $sample_id = $Attr->sample_id;
    $Attr->delete;

    return $self->redirect_to("/admin/sample/edit/$sample_id");
}

# ----------------------------------------------------------------------
sub update {
    my $self    = shift;
    my $attr_id = $self->param('sample_attr_id');
    my $Attr    = $self->db->schema->resultset('SampleAttr')->find($attr_id)
                  or die "Bad sample_attr_id ($attr_id)\n";

    for my $fld (qw[value sample_attr_type_id]) {
        my $val = $self->param($fld) or next;
        $Attr->$fld($val);
        $Attr->update;
    }

    return $self->redirect_to("/admin/sample/edit/" . $Attr->sample_id);
}

1;
