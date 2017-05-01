package MuScope::Controller::Admin::User;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub list {
    my $self  = shift;
    $self->layout('admin');
    $self->render(users => $self->db->schema->resultset('User'));
}

# ----------------------------------------------------------------------
sub view {
    my $self    = shift;
    my $user_id = $self->param('user_id');
    my $User    = $self->db->schema->resultset('User')->find($user_id)
                    or die "Bad user id ($user_id)";

    $self->layout('admin');
    $self->render( 
        user  => $User,
        title => 'View User',
    );
}

1;
