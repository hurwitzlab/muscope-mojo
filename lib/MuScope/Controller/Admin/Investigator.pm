package MuScope::Controller::Admin::Investigator;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create {
    my $self = shift;

    $self->layout('admin');
    $self->render();
}

# ----------------------------------------------------------------------
sub insert {
    my $self   = shift;
    my $fname  = $self->param('first_name') || '';
    my $lname  = $self->param('last_name')  || '';

    die "Must have first/last names\n" unless $fname && $lname;

    my $schema     = $self->db->schema;
    my $Inv        = $schema->resultset('Investigator')->create({
        first_name => $fname,
        last_name  => $lname,
    });

    return $self->redirect_to("/admin/investigator/edit/" . $Inv->id);
}

# ----------------------------------------------------------------------
sub edit {
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
sub list {
    my $self = shift;
    $self->layout('admin');
    $self->render(
        investigators => $self->db->schema->resultset('Investigator')
    );
}

# ----------------------------------------------------------------------
sub update {
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

    return $self->redirect_to("/admin/investigator/list");
}

1;
