package MuScope::Controller::Admin::SampleAttrType;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create {
    my $self = shift;

    $self->layout('admin');
    $self->render(
        sample_attr_type_categories =>
            $self->db->schema->resultset('SampleAttrTypeCategory')->search_rs,
    );
}

# ----------------------------------------------------------------------
sub insert {
    my $self     = shift;
    my $type     = $self->param('type')     or die "Missing type\n";
    my $unit     = $self->param('unit')     or die "Missing unit\n";
    my $cat_id   = $self->param('sample_attr_type_category_id') 
                   or die "Missing sample_attr_type_category_id\n";
    my $AttrType = $self->db->schema->resultset('SampleAttrType')->create({
        type     => $type,
        unit     => $unit,
        sample_attr_type_category_id => $cat_id,
    });

    return $self->redirect_to("/admin/sample_attr_type/list");
}

# ----------------------------------------------------------------------
sub edit {
    my $self      = shift;
    my $type_id  = $self->param('sample_attr_type_id');
    my $AttrType = 
        $self->db->schema->resultset('SampleAttrType')->find($type_id)
        or die "Bad sample_attr_type_id ($type_id)\n";

    $self->layout('admin');
    $self->render( 
        title            => 'Edit Sample Attribute',
        sample_attr_type => $AttrType,
        sample_attr_type_categories =>
            $self->db->schema->resultset('SampleAttrTypeCategory')->search_rs,
    );
}

# ----------------------------------------------------------------------
sub list {
    my $self = shift;

    $self->layout('admin');
    $self->render(sample_attr_types => 
        $self->db->schema->resultset('SampleAttrType'));
}

# ----------------------------------------------------------------------
sub update {
    my $self     = shift;
    my $type_id  = $self->param('sample_attr_type_id');
    my $AttrType = 
        $self->db->schema->resultset('SampleAttrType')->find($type_id)
        or die "Bad sample_attr_type_id ($type_id)\n";

    for my $fld (qw[type unit sample_attr_type_category_id]) {
        my $val = $self->param($fld) or next;
        $AttrType->$fld($val);
        $AttrType->update;
    }

    return $self->redirect_to("/admin/sample_attr_type/list");
}

1;
