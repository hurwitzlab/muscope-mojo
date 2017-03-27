package MuScope::Controller::Cart;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';
use Data::GUID;
use List::Util 'uniq';
use JSON::XS;
use File::Temp 'tempfile';

# ----------------------------------------------------------------------
sub add {
    my $self = shift;

    unless ($self->session->{'id'}) {
        $self->session(id => Data::GUID->new->as_string);
    }

    if (my $item = $self->param('item')) {
        my @current = @{ $self->session->{'items'} || [] };
        $self->session(items => [uniq(@current, split(/\s*,\s*/, $item))]);
    }

    return $self->redirect_to("/cart/view");
}

# ----------------------------------------------------------------------
sub icon {
    my $self = shift;

    $self->layout('');
    $self->render(session => $self->session);
}

# ----------------------------------------------------------------------
sub launch_app {
    my $self   = shift;
    my $app_id = $self->param('app_id') || '';
    my $status = '';

    if ($app_id) {
        my @sample_ids = @{ $self->session->{'items'} || [] };
        if (my $json = `jobs-template $app_id`) {
            my $template = decode_json($json);
            $template->{'inputs'}{'INPUT'} = join ',', @sample_ids;
            my ($fh, $tmp_file) = tempfile();
            print $fh encode_json($template);
            close($fh);
            $status = `jobs-submit -F $tmp_file`;
            unlink $tmp_file;
        }
        else {
            $status = "Bad app_id ($app_id)";        
        }
    }

    $self->layout('default');
    $self->render(
        app_id => $app_id,
        status => $status
    );
}

# ----------------------------------------------------------------------
sub remove {
    my $self = shift;

    if (my $item = $self->param('item')) {
        my %remove  = map { $_, 1 } split(/\s*,\s*/, $item);
        my @current = @{ $self->session->{'items'} || [] };
        $self->session(items => [
            grep { $remove{ $_ } ? () : $_ } @current
        ]);
    }

    return $self->redirect_to("/cart/view");
}

# ----------------------------------------------------------------------
sub purge {
    my $self = shift;

    $self->session(items => []);

    return $self->redirect_to("/cart/view");
}

# ----------------------------------------------------------------------
sub view {
    my $self    = shift;
    my $schema  = $self->db->schema;
    my $session = $self->session;

    my @samples;
    for my $sample_id (@{ $session->{'items'} || [] }) {
        push @samples, $schema->resultset('Sample')->find($sample_id);
    }


    $self->respond_to(
        json => sub {
            $self->render( json => { $session } );
        },

        html => sub {
            $self->layout('default');

            $self->render(
                title   => 'session',
                session => $session,
                samples => \@samples,
                app_ids => ['remote-test-0.0.1']
            );
        },

        txt => sub {
            $self->render( text => dump($session) )
        },
    );
}

1;
