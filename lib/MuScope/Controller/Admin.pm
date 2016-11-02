package MuScope::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dump 'dump';

# ----------------------------------------------------------------------
sub create_project_page {
    my $self       = shift;
    my $project_id = $self->param('project_id')    or die 'No project id';
    my $title      = $self->param('title')         or die 'No title';
    my $contents   = $self->param('contents')      or die 'No contents';
    my $order      = $self->param('display_order') || '1';
    my $format     = $self->param('format')        || 'html';
    my $db         = $self->db;
    my $schema     = $db->schema;

    my $Page          = $schema->resultset('ProjectPage')->create({
        project_id    => $project_id,
        title         => $title,
        contents      => $contents,
        display_order => $order,
        format        => lc $format,
    });

    return $self->redirect_to("/admin/view_project_pages/$project_id");
}

# ----------------------------------------------------------------------
sub create_project_pub {
    my $self       = shift;
    my $project_id = $self->param('project_id')     or die 'No project id';
    my $pub_id     = $self->param('publication_id') or die 'No publication_id';
    my $db         = $self->db;
    my $schema     = $db->schema;
    my $Pub        = $schema->resultset('Publication')->find($pub_id);

    $Pub->project_id($project_id);
    $Pub->update();

    return $self->redirect_to("/admin/edit_project_publications/$project_id");
}

# ----------------------------------------------------------------------
sub create_publication {
    my $self        = shift;
    my $title       = $self->param('title')  or die 'No title';
    my $author      = $self->param('author') or die 'No author(s)';
    my $db          = $self->db;
    my $Publication = $db->schema->resultset('Publication')->find_or_create({
        title  => $title, 
        author => $author, 
    });

    for my $fld (qw[journal project_id pub_code doi pubmed_id]) {
        if (my $val = $self->param($fld)) {
            $Publication->$fld($val); 
        }
    }

    $Publication->update();

    return $self->redirect_to("/admin/list_projects");
}

# ----------------------------------------------------------------------
sub create_publication_form {
    my $self     = shift;
    my $db       = $self->db;
    my $Projects = $db->schema->resultset('Project')->search(
        {}, 
        { order_by => { -asc => 'project_name' } }
    );

    $self->layout('admin');
    $self->render(projects => $Projects);
}

# ----------------------------------------------------------------------
sub create_project_page_form {
    my $self       = shift;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;
    my $Project    = $db->schema->resultset('Project')->find($project_id);

    $self->layout('admin');
    $self->render(project => $Project);
}

# ----------------------------------------------------------------------
sub create_project_pub_form {
    my $self       = shift;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;
    my $Project    = $db->schema->resultset('Project')->find($project_id);
    my $Pubs       = $db->schema->resultset('Publication')->search(
        { project_id => undef },
        { order_by   => { -asc => 'title' } }
    );

    $self->layout('admin');
    $self->render(
        pubs    => $Pubs,
        project => $Project,
    );
}

# ----------------------------------------------------------------------
sub delete_project_page {
    my $self       = shift;
    my $pp_id      = $self->param('project_page_id');
    my $db         = $self->db;
    my $schema     = $db->schema;
    my $Page       = $schema->resultset('ProjectPage')->find($pp_id);

    if (!$Page) {
        return $self->reply->exception("Bad project page id ($pp_id)");
    }

    my $project_id = $Page->project_id;

    $Page->delete();

    $self->respond_to(
        json => sub {
            $self->render( json => { result  => 'ok' });
        },

        html => sub {
            return $self->redirect_to("/admin/edit_project/$project_id");
        },
    );
}

# ----------------------------------------------------------------------
sub delete_project_pub {
    my $self   = shift;
    my $pub_id = $self->param('publication_id');
    my $db     = $self->db;
    my $schema = $db->schema;
    my $Pub    = $schema->resultset('Publication')->find($pub_id);

    if (!$Pub) {
        return $self->reply->exception("Bad publication id ($pub_id)");
    }

    my $project_id = $Pub->project_id;
    $Pub->project_id(undef);
    $Pub->update;

    $self->respond_to(
        json => sub {
            $self->render( json => { result  => 'ok' });
        },

        html => sub {
            return $self->redirect_to("/admin/edit_project/$project_id");
        },
    );
}

# ----------------------------------------------------------------------
sub delete_publication {
    my $self   = shift;
    my $pub_id = $self->param('publication_id');
    my $db     = $self->db;
    my $schema = $db->schema;
    my $Pub    = $schema->resultset('Publication')->find($pub_id);

    if (!$Pub) {
        return $self->reply->exception("Bad publication id ($pub_id)");
    }

    $Pub->delete;

    $self->respond_to(
        json => sub {
            $self->render( json => { result  => 'ok' });
        },

        html => sub {
            return $self->redirect_to("/admin/list_publications");
        },
    );
}

# ----------------------------------------------------------------------
sub edit_project {
    my $self       = shift;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;

    my $sql = sprintf(
        'select project_id from project where %s=?',
        $project_id =~ /\D+/ ? 'project_code' : 'project_id'
    );

    my $sth = $db->dbh->prepare($sql);
    $sth->execute($project_id);
    my $id = $sth->fetchrow_hashref;

    my $Project = $db->schema->resultset('Project')->find($project_id);

    if (!$Project) {
        return $self->reply->exception("Bad project id ($project_id)");
    }

    $self->layout('admin');
    $self->render( 
        project   => $Project,
        title     => 'Edit Project',
    );
}

# ----------------------------------------------------------------------
sub edit_project_publications {
    my $self       = shift;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;
    my $Project    = $db->schema->resultset('Project')->find($project_id);

    $self->layout('admin');
    $self->render( 
        project   => $Project,
        title     => 'Edit Project Pubs: ' . $Project->project_name,
    );
}

# ----------------------------------------------------------------------
sub edit_project_page {
    my $self   = shift;
    my $db     = $self->db;
    my $schema = $db->schema;
    my $pp_id  = $self->param('project_page_id');
    my $Page   = $schema->resultset('ProjectPage')->find($pp_id);

    $self->layout('admin');
    $self->render( 
        title   => 'Create Project Page',
        page    => $Page,
    );
}

# ----------------------------------------------------------------------
sub edit_sample {
    my $self      = shift;
    my $sample_id = $self->param('sample_id');
    my $schema    = $self->db->schema;
    my $Sample    = $schema->resultset('Sample')->find($sample_id);

    if (!$Sample) {
        return $self->reply->exception("Bad sample id ($sample_id)");
    }

    $self->layout('admin');
    $self->render( 
        title  => 'Edit Sample: ' . $Sample->sample_name,
        sample => $Sample,
    );
}

# ----------------------------------------------------------------------
sub home_publications {
    my $self = shift;
    $self->layout('admin');
    $self->render;
}

# ----------------------------------------------------------------------
sub index {
    my $self = shift;
    $self->layout('admin');
    $self->render;
}

# ----------------------------------------------------------------------
sub list_projects {
    my $self     = shift;
    my $schema   = $self->db->schema;
    my $Projects = $schema->resultset('Project');

    $self->layout('admin');
    $self->render(projects => $Projects);
}

# ----------------------------------------------------------------------
sub list_publications {
    my $self   = shift;
    my $schema = $self->db->schema;
    my $Pubs   = $schema->resultset('Publication');

    $self->respond_to(
        json => sub {
            $self->render( json => {
                Result  => 'OK',
                Records => $Pubs 
            });
        },

        html => sub {
            $self->layout('admin');
            $self->render(pubs => $Pubs);
        },
    );
}

# ----------------------------------------------------------------------
sub update_project {
    my $self       = shift;
    my $req        = $self->req;
    my $project_id = $req->param('project_id');

    my @flds = qw[ 
        project_name pi institution project_code project_type description 
    ];
    my @vals = map { $req->param($_) } @flds;

    my $dbh  = $self->db->dbh;
    my $sql  = sprintf(
        'update project set %s where project_id=?',
        join(', ', map { "$_=?" } @flds),
    );
        
    $dbh->do($sql, {}, @vals, $project_id);

    return $self->redirect_to("/admin/edit_project/$project_id");
}

# ----------------------------------------------------------------------
sub update_project_page {
    my $self       = shift;
    my $id         = $self->param('project_page_id') or die 'No page id';
    my $title      = $self->param('title')           or die 'No title';
    my $contents   = $self->param('contents')        or die 'No contents';
    my $order      = $self->param('display_order')   || '1';
    my $format     = $self->param('format')          || 'html';
    my $db         = $self->db;
    my $schema     = $db->schema;

    my $Page = $schema->resultset('ProjectPage')->find($id);
    $Page->title($title);
    $Page->contents($contents);
    $Page->display_order($order);
    $Page->format(lc $format);
    $Page->update();

    my $project_id = $Page->project_id;
    return $self->redirect_to("/admin/view_project_pages/$project_id");
}

# ----------------------------------------------------------------------
sub update_publication {
    my $self   = shift;
    my $req    = $self->req;
    my $pub_id = $req->param('publication_id');

    my @flds = qw[ 
        title author journal pub_code pub_date doi pubmed_id project_id
    ];
    my @vals = map { $req->param($_) } @flds;

    my $dbh  = $self->db->dbh;
    my $sql  = sprintf(
        'update publication set %s where publication_id=?',
        join(', ', map { "$_=?" } @flds),
    );
        
    $dbh->do($sql, {}, @vals, $pub_id);

    return $self->redirect_to('/admin/list_publications');
}

# ----------------------------------------------------------------------
sub update_sample {
    my $self      = shift;
    my $req       = $self->req;
    my $sample_id = $req->param('sample_id');
    my $schema    = $self->db->schema;
    my $Sample    = $schema->resultset('Sample')->find($sample_id);

    if (!$Sample) {
        return $self->reply->exception("Bad sample_id ($sample_id)");
    }

    my @flds = qw[ 
        sample_name sample_acc reads_file fastq_file
    ];

    for my $fld (@flds) {
        my $val = $req->param($fld);
        next unless defined $val;
        $Sample->$fld($val);
        $Sample->update;
    }

    return $self->redirect_to(
        '/admin/view_project_samples/' . $Sample->project_id
    );
}

# ----------------------------------------------------------------------
sub view_project {
    my $self       = shift;
    my $req        = $self->req;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;
    my $Project    = $db->schema->resultset('Project')->find($project_id);

    $self->layout('admin');
    $self->render(
        project => $Project
    );
}

# ----------------------------------------------------------------------
sub view_project_pages {
    my $self       = shift;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;
    my $Project    = $db->schema->resultset('Project')->find($project_id);
    my $pages      = $db->dbh->selectall_arrayref(
        'select * from project_page where project_id=?', 
        { Columns => {} }, 
        $project_id
    );


    $self->layout('admin');
    $self->render(pages => $pages, project => $Project);
}

# ----------------------------------------------------------------------
sub view_project_samples {
    my $self       = shift;
    my $req        = $self->req;
    my $project_id = $self->param('project_id');
    my $db         = $self->db;
    my $Project    = $db->schema->resultset('Project')->find($project_id);

    $self->layout('admin');
    $self->render(
        project => $Project
    );
}

# ----------------------------------------------------------------------
sub view_publication {
    my $self     = shift;
    my $req      = $self->req;
    my $pub_id   = $self->param('publication_id');
    my $db       = $self->db;
    my $Pub      = $db->schema->resultset('Publication')->find($pub_id);
    my $Projects = $db->schema->resultset('Project')->search(
        {},
        { order_by => { -asc => 'project_name' } }
    );

    if (!$Pub) {
        return $self->reply->exception("Bad publication id ($pub_id)");
    }

    $self->layout('admin');
    $self->render(
        pub      => $Pub,
        projects => $Projects, 
    );
}

1;
