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

    $r->get('/admin/list_investigators')->to('admin#list_investigators');

    $r->get('/admin/edit_investigator/:investigator_id')->to('admin#edit_investigator');

    $r->post('/admin/update_investigator')->to('admin#update_investigator');

#    $r->get('/admin/list_publications')->to('admin#list_publications');
#
#    $r->post('/admin/create_project_page')->to('admin#create_project_page');
#
#    $r->post('/admin/create_project_pub')->to('admin#create_project_pub');
#
#    $r->get('/admin/create_project_pub_form/:project_id')->to('admin#create_project_pub_form');
#
#    $r->post('/admin/create_publication')->to('admin#create_publication');
#
#    $r->get('/admin/create_publication_form')->to('admin#create_publication_form');
#
#    $r->get('/admin/create_project_page_form/:project_id')->to('admin#create_project_page_form');
#
#    $r->post('/admin/delete_project_page/:project_page_id')->to('admin#delete_project_page');
#
#    $r->post('/admin/delete_project_pub/:publication_id')->to('admin#delete_project_pub');
#
#    $r->post('/admin/delete_publication/:publication_id')->to('admin#delete_publication');
#
#    $r->get('/admin/edit_project_page/:project_page_id')->to('admin#edit_project_pub');
#
#    $r->get('/admin/edit_project_publications/:project_id')->to('admin#edit_project_publications');
#
#    $r->get('/admin/edit_sample/:sample_id')->to('admin#edit_sample');
#
#    $r->post('/admin/update_project_page')->to('admin#update_project_page');
#
#    $r->get('/admin/home_publications')->to('admin#home_publications');
#
#    $r->get('/admin/edit_project/:project_id')->to('admin#edit_project');
#
#    $r->get('/admin/view_project/:project_id')->to('admin#view_project');
#
#    $r->get('/admin/view_project_pages/:project_id')->to('admin#view_project_pages');
#
#    $r->get('/admin/view_project_samples/:project_id')->to('admin#view_project_samples');
#
#    $r->get('/admin/view_publication/:publication_id')->to('admin#view_publication');
#
#    $r->post('/admin/update_project')->to('admin#update_project');
#
#    $r->post('/admin/update_publication')->to('admin#update_publication');
#
#    $r->post('/admin/update_sample')->to('admin#update_sample');
#
    #
    # User endpoints
    #
    $r->get('/')->to('welcome#index');

    $r->get('/feedback')->to('feedback#form');

#    $r->get('/assembly/info')->to('assembly#info');
#
#    $r->get('/assembly/list')->to('assembly#list');
#
#    $r->get('/assembly/view/:assembly_id')->to('assembly#view');
#
#    $r->get('/combined_assembly/info')->to('combined_assembly#info');
#
#    $r->get('/combined_assembly/list')->to('combined_assembly#list');
#
#    $r->get('/combined_assembly/view/:combined_assembly_id')->to('combined_assembly#view');
#
#    $r->get('/download')->to('download#format');
#
#    $r->post('/download/get')->to('download#get');
#

#    $r->post('/feedback/submit')->to('feedback#submit');
#
#    $r->get('/index')->to('welcome#index');
#
#    $r->get('/info')->to('welcome#index');
#
    $r->post('/cart/add')->to('cart#add');

    $r->get('/cart/launch_app')->to('cart#launch_app');

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
