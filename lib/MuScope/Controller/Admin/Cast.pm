package MuScope::Controller::Admin::Cast;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use Time::ParseDate;
use DateTime;

# ----------------------------------------------------------------------
sub create {
    my $self       = shift;
    my $station_id = $self->param('station_id');
    my $Station    = $self->db->schema->resultset('Station')->find($station_id)
                     or die "Bad station_id ($station_id)\n";

    $self->layout('admin');
    $self->render(station => $Station);
}

# ----------------------------------------------------------------------
sub insert {
    my $self       = shift;
    my $station_id = $self->param('station_id')  or die "Missing station_id\n";
    my $num        = $self->param('cast_number') or die "Missing cast_number\n";
    my $Cast       = $self->db->schema->resultset('Cast')->create({
                        station_id  => $station_id,
                        cast_number => $num,
                    });

    return $self->redirect_to("/admin/cast/edit/" . $Cast->id);
}

# ----------------------------------------------------------------------
sub edit {
    my $self    = shift;
    my $cast_id = $self->param('cast_id');
    my $Cast    = $self->db->schema->resultset('Cast')->find($cast_id)
                  or die "Bad cast id ($cast_id)\n";

    $self->layout('admin');
    $self->render( 
        cast => $Cast,
        title  => 'Edit Cast',
    );
}

# ----------------------------------------------------------------------
sub update {
    my $self    = shift;
    my $cast_id = $self->param('cast_id') or die "No cast_id\n";
    my $Cast    = $self->db->schema->resultset('Cast')->find($cast_id)
                  or die "Bad cast id ($cast_id)\n";

    for my $fld (
        qw[cast_number collection_date collection_time collection_time_zone]
    ) {
        my $val = $self->param($fld) or next;
        if ($fld =~ /_date/) {
            my $epoch = parsedate($val) or die "Invalid date: $val";
            my $dt    = DateTime->from_epoch(epoch => $epoch);
            $Cast->$fld($dt->ymd('/'));
        }
        else {
            $Cast->$fld($val);
        }

        $Cast->update;
    }

    return $self->redirect_to("/admin/cast/edit/" . $Cast->id);
}

1;
