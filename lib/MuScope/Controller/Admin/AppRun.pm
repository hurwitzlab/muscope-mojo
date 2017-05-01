package MuScope::Controller::Admin::AppRun;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use Time::ParseDate;

# ----------------------------------------------------------------------
sub view {
    my $self   = shift;
    my $id     = $self->param('app_run_id');
    my $AppRun = $self->db->schema->resultset('AppRun')->find($id)
                 or die "Bad app id ($id)\n";

    $self->layout('admin');
    $self->render( 
        app_run => $AppRun,
        title   => 'Edit AppRun',
    );
}

1;
