package MuScope::Controller::Station;

use Mojo::Base 'Mojolicious::Controller';

# ----------------------------------------------------------------------
sub view {
    my $self       = shift;
    my $station_id = $self->param('station_id');
    my $Station    = $self->db->schema->resultset('Station')->find($station_id)
      or return $self->reply->exception("Bad station id ($station_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => { $Station->get_inflated_columns } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title  => sprintf("Station: %s", $Station->station_number),
                station => $Station,
            );
        },

        txt => sub {
            $self->render( text => dump({
                station => { $Station->get_inflated_columns() },
            }))
        },
    );
}

# ----------------------------------------------------------------------
sub list {
    my $self      = shift;
    my $schema    = $self->db->schema;
    my $cruise_id = $self->param('cruise_id');
    my $Cruise    = $self->db->schema->resultset('Cruise')->find($cruise_id)
      or return $self->reply->exception("Bad cruise id ($cruise_id)");

    $self->respond_to(
        json => sub {
            $self->render( json => 
                [ map {{$_->get_inflated_columns}} $Cruise->stations ]
            );
        },

        html => sub {
            $self->layout('default');

            $self->render( 
                cruise  => $Cruise, 
                title   => 'Stations',
            );
        },

        txt => sub {
            $self->render( text => dump($Cruise->stations) );
        },
    );
}

1;
