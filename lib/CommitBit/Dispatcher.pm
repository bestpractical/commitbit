package CommitBit::Dispatcher;
use Jifty::Dispatcher -base;

before '*' => run {
    if (Jifty->web->current_user->id) {
        Jifty->web->navigation->child( logout=>label=>_( 'Logout'), url => '/logout');
    } else {
        Jifty->web->navigation->child(login=>label=>_( 'Login'), url => '/login');
    }
    if (Jifty->web->current_user->user_object->admin) {
        Jifty->web->navigation->child(admin=>label=>_( 'Admin'), url => '/admin');
   }

};

before '/admin/' => run {
    unless (Jifty->web->current_user->id) {
            tangent '/login';
    }
};

# Sign up for an account
on 'signup' => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'action' =>
        Jifty->web->new_action(
	    class => 'Signup',
	    moniker => 'signupbox'
	);

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

# Login
on 'login' => run {
    set 'action' =>
        Jifty->web->new_action(
	    class => 'Login',
	    moniker => 'loginbox'
	);
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
};

# Log out
before 'logout' => run {
    Jifty->web->request->add_action(
        class   => 'Logout',
        moniker => 'logout',
    );
};

## LetMes
before qr'^/let/(.*)' => run {
    my $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);
    redirect '/error/let_me/invalid_token' unless $let_me->validate;

    Jifty->web->temporary_current_user($let_me->validated_current_user);

    my %args = %{$let_me->args};
    set $_ => $args{$_} for keys %args;
    set let_me => $let_me;
};

on qr'^/let/' => run {
    my $let_me = get 'let_me';
    show '/let/' . $let_me->path;
};


before qr'^/admin' => run {
    my $admin =   Jifty->web->navigation->child('admin');
     $admin->child( 'repos' => label => 'Repositories', url => '/admin/repositories');
     $admin->child( 'proj' => label => 'Projects', url => '/admin/projects');


};

before qr'^/admin/project/([^/]+)(/.*|)$' => run  {
    warn "Setting nav";
    my $admin =   Jifty->web->navigation->child('admin')->child('proj');
    my $proj = $admin->child( $1 => label => $1, url => '/admin/project/'.$1.'/index.html');
    $proj->child( base => label => _('Overview'), url => '/admin/project/'.$1.'/index.html'); 
    $proj->child( people => label => _('People'), url => '/admin/project/'.$1.'/people'); 
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



on qr'^/(.*?/)?project/([^/]+)(/.*|)$' => run {
    my $prefix = $1 ||'';
    my $name    = $2;
    my $path    = $3;
    warn "Got to $1 $2 $3";

    $name = URI::Escape::uri_unescape($name);
    my $project = CommitBit::Model::Project->new();
    $project->load_by_cols( name => $name );
    unless ($project->id) {
        redirect '/__jifty/error/project/not_found';
    }

    set project => $project;
    my $url = $prefix . ($path ? '/project/' . $path : '/project/index.html' );

#    Jifty->web->navigation->child( $project->name => label => $project->name, url => $ENV{'REQUEST_URI'});

    show $url;
};

1;
