package MuScope::Controller::Admin::SampleAttrTypeAlias;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create {
    my $self    = shift;
    my $type_id = $self->param('sample_attr_type_id')     
                  or die "Missing sample_attr_type_id\n";
    my $schema  = $self->db->schema;
    my $Type    = $schema->resultset('SampleAttrType')->find($type_id)
                  or die "Bad sample_attr_type_id ($type_id)\n";

    $self->layout('admin');
    $self->render(sample_attr_type => $Type);
}

# ----------------------------------------------------------------------
sub delete {
    my $self     = shift;
    my $alias_id = $self->param('sample_attr_type_alias_id');
    my $Alias    = 
        $self->db->schema->resultset('SampleAttrTypeAlias')->find($alias_id)
        or die "Bad sample_attr_type_alias_id ($alias_id)\n";
    my $type_id  = $Alias->sample_attr_type->id; 

    $Alias->delete;

    return $self->redirect_to("/admin/sample_attr_type/edit/$type_id");
}

# ----------------------------------------------------------------------
sub insert {
    my $self    = shift;
    my $alias   = $self->param('alias') or die "Missing alias\n";
    my $type_id = $self->param('sample_attr_type_id')     
                  or die "Missing sample_attr_type_id\n";
    my $schema  = $self->db->schema;
    my $Type    = $schema->resultset('SampleAttrType')->find($type_id)
                  or die "Bad sample_attr_type_id ($type_id)\n";
    my $Alias   = $self->db->schema->resultset('SampleAttrTypeAlias')->create({
        alias               => $alias,
        sample_attr_type_id => $Type->id,
    });

    return $self->redirect_to("/admin/sample_attr_type/edit/" . $Type->id);
}

# ----------------------------------------------------------------------
sub edit {
    my $self     = shift;
    my $alias_id = $self->param('sample_attr_type_alias_id');
    my $Alias    = 
        $self->db->schema->resultset('SampleAttrTypeAlias')->find($alias_id)
        or die "Bad sample_attr_type_alias_id ($alias_id)\n";

    $self->layout('admin');
    $self->render( 
        title => 'Edit Sample Attribute Type Alias',
        alias => $Alias,
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
    my $alias_id = $self->param('sample_attr_type_alias_id');
    my $Alias    = 
        $self->db->schema->resultset('SampleAttrTypeAlias')->find($alias_id)
        or die "Bad sample_attr_type_alias_id ($alias_id)\n";

    for my $fld (qw[alias]) {
        my $val = $self->param($fld) or next;
        $Alias->$fld($val);
        $Alias->update;
    }

    return $self->redirect_to(
        "/admin/sample_attr_type/edit/" . $Alias->sample_attr_type->id
    );
}

1;
