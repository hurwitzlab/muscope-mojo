package MuScope::Controller::Admin::Station;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id');
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
                    or die "Bad cruise_id ($cruise_id)\n";

    $self->layout('admin');
    $self->render(cruise => $Cruise);
}

# ----------------------------------------------------------------------
sub insert {
    my $self      = shift;
    my $cruise_id = $self->param('cruise_id') or die "Missing cruise_id\n";
    my $num       = $self->param('station_number') 
                    or die "Missing station number\n";
    my $Station   = $self->db->schema->resultset('Station')->create({
                        cruise_id      => $cruise_id,
                        station_number => $num,
                    });

    return $self->redirect_to("/admin/station/edit/" . $Station->id);
}

# ----------------------------------------------------------------------
sub edit {
    my $self       = shift;
    my $station_id = $self->param('station_id');
    my $Station    = $self->db->schema->resultset('Station')->find($station_id)
                    or die "Bad station id ($station_id)\n";

    $self->layout('admin');
    $self->render( 
        station => $Station,
        title  => 'Edit Station',
    );
}

# ----------------------------------------------------------------------
sub update {
    my $self      = shift;
    my $station_id = $self->param('station_id') or die "No station_id\n";
    my $Station    = $self->db->schema->resultset('Station')->find($station_id)
                    or die "Bad station id ($station_id)\n";

    for my $fld (qw[station_number latitude longitude]) {
        my $val = $self->param($fld) or next;
        $Station->$fld($val);
        $Station->update;
    }

    return $self->redirect_to("/admin/station/edit/" . $Station->id);
}

1;
