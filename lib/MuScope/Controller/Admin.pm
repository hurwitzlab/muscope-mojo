package MuScope::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create_investigator_form {
    my $self = shift;

    $self->layout('admin');
    $self->render();
}

# ----------------------------------------------------------------------
sub create_investigator {
    my $self   = shift;
    my $name   = $self->param('investigator_name') 
                 or die 'No investigator_name';
    my $schema = $self->db->schema;
    my $Inv    = $schema->resultset('Investigator')->create({
        investigator_name => $name,
    });

    if (!$Inv) {
        return $self->reply->exception("Could not create investigator ($name)");
    }

    for my $fld (qw[website institution project bio project]) {
        my $val = $self->param($fld) or next;
        $Inv->$fld($val);
        $Inv->update;
    }

    return $self->redirect_to("/admin/list_investigators");
}

# ----------------------------------------------------------------------
sub edit_investigator {
    my $self   = shift;
    my $inv_id = $self->param('investigator_id');
    my $db     = $self->db;
    my $Inv    = $db->schema->resultset('Investigator')->find($inv_id);

    if (!$Inv) {
        return $self->reply->exception("Bad investigator id ($inv_id)");
    }

    $self->layout('admin');
    $self->render( 
        investigator => $Inv,
        title        => 'Edit Investigator',
    );
}

# ----------------------------------------------------------------------
sub index {
    my $self = shift;
    $self->layout('admin');
    $self->render;
}

# ----------------------------------------------------------------------
sub list_investigators {
    my $self   = shift;
    my $schema = $self->db->schema;
    my $Invs   = $schema->resultset('Investigator');

    $self->layout('admin');
    $self->render(investigators => $Invs);
}

# ----------------------------------------------------------------------
sub update_investigator {
    my $self   = shift;
    my $req    = $self->req;
    my $inv_id = $req->param('investigator_id');
    my $db     = $self->db;
    my $Inv    = $db->schema->resultset('Investigator')->find($inv_id);

    if (!$Inv) {
        return $self->reply->exception("Bad investigator id ($inv_id)");
    }

    for my $fld (@{ $req->params->names }) {
        next if $fld eq 'investigator_id';
        my $val = $req->param($fld);
        $Inv->$fld($val);
    }
    $Inv->update;

    return $self->redirect_to("/admin/edit_investigator/$inv_id");
}

1;
