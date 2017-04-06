package MuScope;

use Mojo::Base 'Mojolicious';
use MuScope::DB;

sub startup {
    my $self = shift;

    $self->plugin('tt_renderer');

    $self->plugin('JSONConfig', { file => 'muscope.json' });

    $self->sessions->default_expiration(86400);

    $self->app->secrets(['N5DsbR4yYCi0Fe37yG9CCDTIGdCXYWE0GkrvMYKCEL80Mb9T5AinStEFygJ5wNoUmxrd51eR6IJKhLGkzsrXJKQhhpB86tjkL3EF']);

    my $r = $self->routes;

    # 
    # Admin endpoints
    # 
    $r->get('/admin')->to('admin#index');

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
    # Station
    #
    $r->get('/admin/station/create/:cruise_id')->to('admin-station#create');

    $r->get('/admin/station/edit/:station_id')->to('admin-station#edit');

    $r->post('/admin/station/insert')->to('admin-station#insert');

    $r->post('/admin/station/update')->to('admin-station#update');

    #
    # Cast
    #
    $r->get('/admin/cast/create/:station_id')->to('admin-cast#create');

    $r->get('/admin/cast/edit/:cast_id')->to('admin-cast#edit');

    $r->post('/admin/cast/insert')->to('admin-cast#insert');

    $r->post('/admin/cast/update')->to('admin-cast#update');

    #
    # Sample
    #
    $r->get('/admin/sample/create/:cast_id')->to('admin-sample#create');

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
    # Sample File
    #
    $r->get('/admin/sample_file/create/:sample_id')->to('admin-sample_file#create');

    $r->get('/admin/sample_file/edit/:sample_file_id')->to('admin-sample_file#edit');

    $r->post('/admin/sample_file/insert')->to('admin-sample_file#insert');

    $r->post('/admin/sample_file/update')->to('admin-sample_file#update');

    $r->post('/admin/sample_file/delete/:sample_file_id')->to('admin-sample_file#delete');


    #
    # User endpoints
    #
    $r->get('/')->to('welcome#index');

    $r->get('/download')->to('download#format');

    $r->post('/download/get')->to('download#get');

    $r->get('/feedback')->to('feedback#form');

    $r->post('/feedback/submit')->to('feedback#submit');

    $r->post('/cart/add')->to('cart#add');

    $r->get('/cart/files')->to('cart#files');

    $r->get('/cart/icon')->to('cart#icon');

    $r->get('/cart/remove/:item')->to('cart#remove');

    $r->get('/cart/purge')->to('cart#purge');

    $r->get('/cart/view')->to('cart#view');

    $r->get('/library_kit/view/:library_kit_id')->to('library_kit#view');

    $r->get('/filter_type/view/:filter_type_id')->to('filter_type#view');

    $r->get('/sequencing_method/view/:sequencing_method_id')->to('sequencing_method#view');

    $r->get('/investigator/list')->to('investigator#list');

    $r->get('/investigator/view/:investigator_id')->to('investigator#view');

    $r->get('/cruise/list')->to('cruise#list');

    $r->get('/cruise/info')->to('cruise#info');

    $r->get('/cruise/browse')->to('cruise#browse');

    $r->get('/cruise/view/:cruise_id')->to('cruise#view');

    $r->get('/station/list/:cruise_id')->to('station#list');

    $r->get('/station/view/:station_id')->to('station#view');

    $r->get('/cast/view/:cast_id')->to('cast#view');

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

    $self->helper(
        db => sub {
            my $self   = shift;
            my $config = $self->config;
            return MuScope::DB->new($config->{'db'});
        }
    );
}

1;
