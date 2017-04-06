package MuScope::Controller::Admin::Cruise;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use Time::ParseDate;

# ----------------------------------------------------------------------
sub create {
    my $self = shift;

    $self->layout('admin');
    $self->render();
}

# ----------------------------------------------------------------------
sub insert {
    my $self   = shift;
    my $name   = $self->param('cruise_name') or die "Must have cruise name\n";
    my $schema = $self->db->schema;
    my $Cruise = $schema->resultset('Cruise')->create({cruise_name => $name});

    return $self->redirect_to("/admin/cruise/edit/" . $Cruise->id);
}

# ----------------------------------------------------------------------
sub edit {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id');
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
                    or die "Bad cruise id ($cruise_id)";

    $self->layout('admin');
    $self->render( 
        cruise => $Cruise,
        title  => 'Edit Cruise',
    );
}

# ----------------------------------------------------------------------
sub list {
    my $self = shift;

    $self->layout('admin');
    $self->render(cruises => $self->db->schema->resultset('Cruise'));
}

# ----------------------------------------------------------------------
sub update {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id') or die "No cruise_id\n";
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
                    or die "Bad cruise id ($cruise_id)";

    for my $fld (qw[start_date end_date]) {
        my $val   = $self->param($fld) or next;
        my $epoch = parsedate($val) or die "Invalid date: $val";
        my $dt    = DateTime->from_epoch(epoch => $epoch);
        $Cruise->$fld($dt->ymd('/'));
        $Cruise->update;
    }

    return $self->redirect_to("/admin/cruise/list");
}

1;
