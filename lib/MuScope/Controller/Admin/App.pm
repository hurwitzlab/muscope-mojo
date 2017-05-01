package MuScope::Controller::Admin::App;

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
    my $name   = $self->param('app_name') or die "Must have app name\n";

    if ($name =~ /^[a-zA-Z0-9-]+ [-] \d+ \. \d+ \. \d+$/xms) {
        my $schema = $self->db->schema;
        my $App    = $schema->resultset('App')->create({app_name => $name});
        return $self->redirect_to("/admin/app/edit/" . $App->id);
    }
    else {
        die "Invalid app name ($name). E.g., &quot;foo-bar-0.0.1&quot;\n";
    }
}

# ----------------------------------------------------------------------
sub delete {
    my $self   = shift;
    my $app_id = $self->param('app_id');
    my $App    = $self->db->schema->resultset('App')->find($app_id)
                    or die "Bad app id ($app_id)\n";

    if ($App->app_runs->count == 0) {
        $App->delete;
        $self->redirect_to('/admin/app/list');
    }
    else {
        die "Cannot delete app with runs.\n";
    }
}

# ----------------------------------------------------------------------
sub edit {
    my $self   = shift;
    my $app_id = $self->param('app_id');
    my $App    = $self->db->schema->resultset('App')->find($app_id)
                 or die "Bad app id ($app_id)\n";

    $self->layout('admin');
    $self->render( 
        app   => $App,
        title => 'Edit App',
    );
}

# ----------------------------------------------------------------------
sub list {
    my $self = shift;

    $self->layout('admin');
    $self->render(apps => $self->db->schema->resultset('App'));
}

# ----------------------------------------------------------------------
sub update {
    my $self      = shift;
    my $app_id = $self->param('app_id') or die "No app_id\n";
    my $App    = $self->db->schema->resultset('App')->find($app_id)
                    or die "Bad app id ($app_id)";

    for my $fld (qw[is_active]) {
        my $val = $self->param($fld);
        say "$fld = $val";
        next unless defined $val;
        $App->$fld($val);
        $App->update;
    }

    return $self->redirect_to("/admin/app/edit/" . $App->id);
}

1;
