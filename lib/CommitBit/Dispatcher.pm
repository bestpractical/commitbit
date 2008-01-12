package CommitBit::Dispatcher;
use Jifty::Dispatcher -base;


# Protect elements directories
before qr'/_elements/' => run { # do not anchor this, runs on _any_ level
    # Requesting an internal component by hand -- naughty
  redirect("/errors/requested_private_component");
}; 


before '*' => run {
    if ( Jifty->web->current_user->id ) {
        Jifty->web->navigation->child(
            prefs     =>
                label => _('Preferences'),
            url        => '/prefs',
            sort_order => 998
        );
    } else {
    }

    if (    Jifty->web->current_user->user_object
        and Jifty->web->current_user->user_object->admin )
    {
        Jifty->web->navigation->child(
            admin     =>
                label => _('Admin'),
            url => '/admin'
        );
    }

};

before qr'/admin/|/prefs' => run {
    unless (Jifty->web->current_user->id) {
            tangent '/login';
    }
};

on 'prefs' => run {
    set 'action' =>
        Jifty->web->new_action(
	    class => 'UpdateUser',
	    moniker => 'prefsbox',
        record => Jifty->web->current_user->user_object
	);

};

before qr'^/admin' => run {
    my $admin = Jifty->web->navigation->child('admin')
        || Jifty->web->navigation->child(
        admin => label => _('Admin'),
        url   => '/admin'
        );
    if ( Jifty->web->current_user->user_object->admin ) {
        $admin->child(
            'repos' => label => 'Repositories',
            url     => '/admin/repositories'
        );
    }
    $admin->child( 'proj' => label => 'Projects', url => '/admin/projects/' );

};

before qr'^/admin/repository' => run {
    unless  (Jifty->web->current_user->user_object->admin ) {
        redirect '/__jifty/error/permission_denied/not_admin'; 
    }

};
before qr'^/admin/repository/([^/]+)(?:/.*|)$' => run {
    my $name    = $1;
    $name = URI::Escape::uri_unescape($name);
    my $repository = CommitBit::Model::Repository->new();
    $repository->load_by_cols( name => $name );
    unless ($repository->id) {
        redirect '/__jifty/error/repository/not_found';
    }

    my $admin =   Jifty->web->navigation->child('admin')->child('repos');
    $radmin =   $admin->child($repository->name => url => '/admin/repository/'.$name.'/index.html');
    $radmin->child( $repository->name => label => 'Overview', url => '/admin/repository/'.$name.'/index.html');
    $radmin->child( $repository->name."projects" => label => 'Projects', url => '/admin/repository/'.$name.'/projects');
    set repository => $repository;
};

on qr'^/admin/repository/(?:[^/]+)(/.*|)$' => run {
    my $path    = $1||'index.html';
    show "/admin/repository/$path";
};



before qr'^/admin/project/(.*?)(?:\/|$)' => run  {
    my $proj_name = $1;
    my $admin =   Jifty->web->navigation->child('admin')->child('proj');
    my $proj = $admin->child( $proj_name => label => $proj_name, url => '/admin/project/'.$proj_name.'/index.html');
    $proj->child( base => label => _('Overview'), url => '/admin/project/'.$proj_name.'/index.html'); 
    $proj->child( people => label => _('People'), url => '/admin/project/'.$proj_name.'/people'); 
};


on qr'^/(.*?/)?project/([^/]+)(/.*|)$' => run {
    my $prefix = $1 ||'';
    my $name    = $2;
    my $path    = $3;
    warn "Got to $1 $2 $3";


    if ( (lc($prefix) ne 'admin') && !  Jifty->web->navigation->child('admin') ) {
        Jifty->web->navigation->child(admin => label => _('Admin project'), url =>  '/admin/project/'.$name, order => 5);
    }

    $name = URI::Escape::uri_unescape($name);
    my $project = CommitBit::Model::Project->new();
    $project->load_by_cols( name => $name );
    unless ($project->id) {
        redirect '/__jifty/error/project/not_found';
    }

    if (lc($prefix) eq 'admin') {
    unless  ($project->is_project_admin(Jifty->web->current_user)
             or Jifty->web->current_user->user_object->admin) {
        redirect '/__jifty/error/permission_denied/not_admin'; 
    }
    }

    set project => $project;
    my $url = $prefix . ($path ? '/project/' . $path : '/project/index.html' );

    show $url;
};

1;
