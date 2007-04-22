package CommitBit::Dispatcher;
use Jifty::Dispatcher -base;


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

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

before qr'^/admin' => run {
    my $admin =   Jifty->web->navigation->child('admin') || Jifty->web->navigation->child( admin => label => _('Admin'), url => '/admin');
    if (Jifty->web->current_user->user_object->admin ) {
        $admin->child( 'repos' => label => 'Repositories', url => '/admin/repositories');
    }
     $admin->child( 'proj' => label => 'Projects', url => '/admin/projects');


};

before qr'^/admin/repository' => run {
    unless  (Jifty->web->current_user->user_object->admin ) {
        redirect '/__jifty/error/permission_denied/not_admin'; 
    }

};
on qr'^/admin/repository/([^/]+)(/.*|)$' => run {
    my $name    = $1;
    my $path    = $2||'index.html';
    $name = URI::Escape::uri_unescape($name);
    warn "Name - $name - $path";
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
    show "/admin/repository/$path";
};



on qr'^/admin/project/([^/]+)(/.*|)$' => run  {
    my $admin =   Jifty->web->navigation->child('admin')->child('proj');
    my $proj = $admin->child( "111".$1 => label => $1, url => '/admin/project/'.$1.'/index.html');
    $proj->child( base => label => _('Overview'), url => '/admin/project/'.$1.'/index.html'); 
    $proj->child( people => label => _('People'), url => '/admin/project/'.$1.'/people'); 
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
