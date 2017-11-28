package MuScope;

use Mojo::Base 'Mojolicious';
use MuScope::DB;
use Data::Dump 'dump';

sub startup {
    my $self = shift;

    $self->plugin('tt_renderer');

    $self->plugin('write_excel');

    $self->plugin('JSONConfig' => { file => 'muscope.json' });

    my $config = $self->config;
    if (my $secret = $config->{'secret'}) {
        $self->secrets([$secret]);
    }

    $self->sessions->default_expiration(86400);

    my $r = $self->routes;

    #
    # Auth
    #
    my $auth = $r->under(sub {
        my $self    = shift;
        my $token   = $self->session->{'token'};
        my $expired = 1;

        if ($token && ref $token eq 'HASH') {
            my $expires = $token->{'expires'} ||  0;
            my $now     = time();
            $expired    = $expires < $now;
        }

        if ($expired) {
            my $state  = $self->req->headers->referrer || '000';
            my $config = $self->config;
            my $key    = $config->{'tacc_api_key'} or die "No TACC API key\n";
            my $params = join '&',
                'client_id='    . $key->{'public'},
                'redirect_uri=' . $key->{'redirect_url'},
                'state='        . $state,
                'scope=PRODUCTION',
                'response_type=code';

            my $url = "https://agave.iplantc.org/authorize?$params";

            $self->redirect_to($url);
            return 0;
        }
        else {
            return 1;
        }
    });

    # 
    # Admin endpoints
    # 
    $r->get('/admin')->to('admin#index');

    #
    # App
    #
    $r->get('/admin/app/list')->to('admin-app#list');

    $r->get('/admin/app/create')->to('admin-app#create');

    $r->get('/admin/app/edit/:app_id')->to('admin-app#edit');

    $r->post('/admin/app/insert')->to('admin-app#insert');

    $r->get('/admin/app/delete/:app_id')->to('admin-app#delete');

    $r->post('/admin/app/update')->to('admin-app#update');

    #
    # AppRun
    #
    $r->get('/admin/app_run/view/:app_run_id')->to('admin-app_run#view');

    #
    # Cruise
    #
    $r->get('/admin/cruise/list')->to('admin-cruise#list');

    $r->get('/admin/cruise/create')->to('admin-cruise#create');

    $r->get('/admin/cruise/edit/:cruise_id')->to('admin-cruise#edit');

    $r->post('/admin/cruise/insert')->to('admin-cruise#insert');

    $r->post('/admin/cruise/update')->to('admin-cruise#update');

    #
    # Investigator
    #

    $r->get('/admin/investigator/list')->to('admin-investigator#list');

    $r->get('/admin/investigator/edit/:investigator_id')->to('admin-investigator#edit');

    $r->post('/admin/investigator/update')->to('admin-investigator#update');

    $r->get('/admin/investigator/create')->to('admin-investigator#create');

    $r->post('/admin/investigator/insert')->to('admin-investigator#insert');

    #
    # Sample
    #
    $r->get('/admin/sample/create/:cruise_id')->to('admin-sample#create');

    $r->get('/admin/sample/edit/:sample_id')->to('admin-sample#edit');

    $r->post('/admin/sample/insert')->to('admin-sample#insert');

    $r->post('/admin/sample/update')->to('admin-sample#update');

    #
    # Sample Attr
    #
    $r->get('/admin/sample_attr/create/:sample_id')->to('admin-sample_attr#create');

    $r->get('/admin/sample_attr/edit/:sample_attr_id')->to('admin-sample_attr#edit');

    $r->post('/admin/sample_attr/insert')->to('admin-sample_attr#insert');

    $r->post('/admin/sample_attr/update')->to('admin-sample_attr#update');

    $r->post('/admin/sample_attr/delete/:sample_attr_id')->to('admin-sample_attr#delete');

    #
    # Sample Attr Type
    #
    $r->get('/admin/sample_attr_type/create')->to('admin-sample_attr_type#create');

    $r->get('/admin/sample_attr_type/edit/:sample_attr_type_id')->to('admin-sample_attr_type#edit');

    $r->get('/admin/sample_attr_type/list')->to('admin-sample_attr_type#list');

    $r->post('/admin/sample_attr_type/insert')->to('admin-sample_attr_type#insert');

    $r->post('/admin/sample_attr_type/update')->to('admin-sample_attr_type#update');

    #
    # Sample Attr Type Alias
    #
    $r->get('/admin/sample_attr_type_alias/create/:sample_attr_type_id')->to('admin-sample_attr_type_alias#create');

    $r->get('/admin/sample_attr_type_alias/edit/:sample_attr_type_alias_id')->to('admin-sample_attr_type_alias#edit');

    $r->post('/admin/sample_attr_type_alias/insert')->to('admin-sample_attr_type_alias#insert');

    $r->post('/admin/sample_attr_type_alias/update')->to('admin-sample_attr_type_alias#update');

    $r->post('/admin/sample_attr_type_alias/delete/:sample_attr_type_alias_id')->to('admin-sample_attr_type_alias#delete');

    #
    # Sample File
    #
    $r->get('/admin/sample_file/create/:sample_id')->to('admin-sample_file#create');

    $r->get('/admin/sample_file/edit/:sample_file_id')->to('admin-sample_file#edit');

    $r->post('/admin/sample_file/insert')->to('admin-sample_file#insert');

    $r->post('/admin/sample_file/update')->to('admin-sample_file#update');

    $r->post('/admin/sample_file/delete/:sample_file_id')->to('admin-sample_file#delete');

    #
    # User
    #
    $r->get('/admin/user/list')->to('admin-user#list');

    $r->get('/admin/user/view/:user_id')->to('admin-user#view');

    #
    # User endpoints
    #
    $r->get('/')->to('welcome#index');

    $r->any('/app/launch')->to('app#launch');

    $auth->get('/app/run/#app_id')->to('app#run');

    $r->get('/app/list')->to('app#list');

    $auth->post('/app/file_upload')->to('app#file_upload');

    $r->get('/index')->to('welcome#index');

    $r->get('/download')->to('download#format');

    $r->post('/download/get')->to('download#get');

    $r->get('/feedback')->to('feedback#form');

    $r->post('/feedback/submit')->to('feedback#submit');

    $r->get('/cart/add/:item')->to('cart#add');

    $r->post('/cart/add')->to('cart#add');

    $r->get('/cart/files/:file_type_id')->to('cart#files');

    $r->get('/cart/file_types')->to('cart#file_types');

    $r->get('/cart/files')->to('cart#files');

    $r->get('/cart/icon')->to('cart#icon');

    $r->get('/cart/remove/:item')->to('cart#remove');

    $r->get('/cart/purge')->to('cart#purge');

    $r->get('/cart/view')->to('cart#view');

    $r->get('/cruise/list')->to('cruise#list');

    $r->get('/cruise/info')->to('cruise#info');

    $r->get('/cruise/download/:cruise_id')->to('cruise#download');

    $r->get('/cruise/view/:cruise_id')->to('cruise#view');

    $r->get('/investigator/list')->to('investigator#list');

    $r->get('/investigator/view/:investigator_id')->to('investigator#view');

    $auth->get('/job/list')->to('job#list');

    $auth->get('/job/view/:job_id')->to('job#view');

    $auth->get('/login')->to('login#login');

    $r->get('/logout')->to('login#logout');

    $r->get('/auth')->to('login#auth');

    $r->get('/sample/info')->to('sample#info');

    $r->get('/sample/list')->to('sample#list');

    $r->get('/sample/map_search')->to('sample#map_search');

    $r->get('/sample/map_search_results')->to('sample#map_search_results');

    $r->get('/sample/sample_file_list/:sample_id')->to('sample#sample_file_list');

    $r->get('/sample/search')->to('sample#search');

    $r->get('/sample/search_params')->to('sample#search_params');

    $r->get('/sample/search_param_values/:field')->to('sample#search_param_values');

    $r->get('/sample/search_results')->to('sample#search_results');

    $r->get('/sample/search_results_map')->to('sample#search_results_map');

    $r->get('/sample/view/:sample_id')->to('sample#view');

    $r->get('/sample_file/view/:sample_file_id')->to('sample_file#view');

    $r->get('/search')->to('search#results');

    $r->get('/search/info')->to('search#info');

    $self->hook(
        before_render => sub {
            my ($c, $args) = @_;

            return unless my $template = $args->{'template'};

            $args->{'config'} = $c->config;

            if ($c->accepts('html')) {
                $args->{'title'} //= ucfirst $template;
                $c->layout('default');
            }
            elsif ($c->accepts('json')) {
                $args->{'json'} = {
                    status    => $args->{'status'},
                    exception => $args->{'exception'},
                };
            }
        }
    );

    $self->hook(
        after_dispatch => sub {
            my $c = shift;
            if ( defined $c->param('download') ) {
                $c->res->headers->add(
                    'Content-type' => 'application/force-download' 
                );
                
                (my $file = $c->req->url->path) =~ s{.+/}{};
                my $name = $c->param('download') || '';

                if ($name =~ /\D/) {
                    $file = $name;
                }

                $c->res->headers->add(
                    'Content-Disposition' => qq[attachment; filename=$file] 
                );
            }
        }
    );

    my $db;
    $self->helper(
        db => sub {
            my $self   = shift;
            my $config = $self->config;
            return MuScope::DB->new($config->{'db'});
            #if (!$db || !$db->ping) {
            #    $db = MuScope::DB->new($config->{'db'});
            #}
            #return $db;
        }
    );

    $self->helper(
        tablify => sub {
            my ($self, @data) = @_;
            my $out  = '';

            if (@data && ref $data[0] eq 'HASH') {
                my @hdr  = sort keys %{ $data[0] };
                my @out  = join "\t", @hdr;
                for my $row (@data) {
                    push @out, join "\t", (map { $row->{$_} // '' } @hdr);
                }
                $out = join "\n", @out;
            }

            return $out;
        }
    );

#    $self->helper( get_access_token => sub {
#        my ($self, %args) = @_;
#        my $token   = $self->session->{'token'};
#        my $expired = 1;
#
#        if ($token && ref $token eq 'HASH') {
#            my $expires = $token->{'expires'} ||  0;
#            my $now     = time();
#            $expired    = $expires < $now;
#        }
#
#        if ($expired) {
#            my $state  = $args{'state'} || '000';
#            my $config = $self->config;
#            my $key    = $config->{'tacc_api_key'} or die "No TACC API key\n";
#            my $params = join '&',
#                'client_id='    . $key->{'public'},
#                'redirect_uri=' . $key->{'redirect_url'},
#                'state='        . $state,
#                'scope=PRODUCTION',
#                'response_type=code';
#
#            my $url = "https://agave.iplantc.org/authorize?$params";
#
#            $self->redirect_to($url);
#        }
#        else {
#            $token;
#        }
#    });
}

1;
