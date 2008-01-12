use warnings;
use strict;

package CommitBit::View;
use Jifty::View::Declare -base;

template 'index.html' => page { title =>
        _( 'Welcome to CommitBit for %1', Jifty->config->app('site_name') ) }
    content {
    my $projects = CommitBit::Model::ProjectCollection->new;
    $projects->order_by( { column => 'name', order => 'asc' } );
    $projects->limit(
        column   => 'publicly_visible',
        operator => '=',
        value    => '1'
    );
    my $featured = CommitBit::Model::ProjectCollection->new;
    $featured->limit( column => 'featured', operator => '=', value => '1' );
    $featured->limit(
        column   => 'publicly_visible',
        operator => '=',
        value    => '1'
    );
    $featured->order_by( { column => 'name', order => 'asc' } );

    div {
        { class is "featured" };
        h2 { _('Featured projects') };
        dl {
            while ( my $p = $featured->next ) {
                dt {
                    if ( $p->logo_url ) {
                        img {
                            { src is $p->logo_url }
                        };
                    }
                    hyperlink(
                        url   => '/project/' . $p->name,
                        label => $p->name
                    );
                };
                dd { $p->blurb };
            }
        };
    };

    h2 { _('All locally hosted projects') };
    dl {
        while ( my $p = $projects->next ) {
            dt {
                hyperlink( url => '/project/' . $p->name, label => $p->name );
            };
            dd { $p->description };
        }
    };

    };

template 'admin/index.html' => page { title => _('Manage projects and repositories') }
    content {

    p {
        _(  'From this administrative interface, you can manage projects and repositories,'
                . " (assuming that you've got the permissions)" );
    }
    };

template 'admin/projects' => page { title => 'Manage projects' } content {
    dl {
        my $projects = CommitBit::Model::ProjectCollection->new;
        $projects->unlimit();
        while ( my $p = $projects->next ) {
            dt {
                hyperlink(
                    url   => '/admin/project/' . $p->name,
                    label => $p->name
                );
            };
            dd { $p->description };
        }
    };
};

template 'admin/repository/index.html' =>
    page { title => get('repository')->name } content {

    my $repository = get('repository');
    my $update     = Jifty->web->new_action(
        class  => 'UpdateRepository',
        record => $repository
    );

    h1 { $repository->name };
    form {
        foreach my $arg ( $update->argument_names ) {
            render_param( $update => $arg );
        }
        form_submit();
    }

    hyperlink(
        label => 'Projects',
        url   => '/admin/repository/' . $repository->name . '/projects'
        )

    };

template 'admin/repository/projects' =>
    page { title => _( 'Projects in %1', get('repository')->name ) } content {
    my $repository  = get('repository');
    my $projects    = $repository->projects;
    my $new_project = Jifty->web->new_action(
        class     => 'CreateProject',
        arguments => { repository => $repository->id }
    );
    form {
        ul {
            while ( my $project = $projects->next ) {
                my $del = Jifty->web->new_action(
                    class   => 'DeleteProject',
                    record  => $project,
                    moniker => 'delete-project-' . $project->id
                );
                li {
                    hyperlink(
                        label => $project->name,
                        url   => '/admin/project/' . $project->name
                    );
                    render_param( $del => 'id' );
                    $del->button(
                        label => 'Delete project',
                        class => 'delete',
                        onclick =>
                            qq|return confirm('Really delete this project?');|
                    );

                };
            }
        };
        h2 { _('Add a new project') };
        foreach my $arg ( $new_project->argument_names ) {
            render_param( $new_project => $arg );
        }
        form_submit( submit => $new_project, label => 'Create project' );
    };
    };

template 'admin/create_repository' =>
    page { title => 'Create a new repository' } content {
    my $create = Jifty->web->new_action(
        class   => 'CreateRepository',
        moniker => 'newrepo'
    );
    h1 {'Create a repository'};
    h2 {'(Are you sure you want to do this?)'};
    form {
        render_action($create);
    form_submit( label => 'Go' );
    }
    };

template 'admin/project/index.html' =>
    page { title => _( 'Overview of %1', get('project')->name ) } content {
    my $project = get('project');
    my $edit    = Jifty->web->new_action(
        class  => 'UpdateProject',
        record => $project
    );
    form {
        render_action($edit);
        form_submit( label => 'Save changes' );
    }
    };

template 'admin/project/people' =>
    page { title => _( 'People involved with %1', get('project')->name ) }
    content {
    my $project       = get('project');
    my $new_committer = Jifty->web->new_action(
        class     => 'CreateProjectMember',
        arguments => { project => $project->id }
    );
    form {
        h2 { _('Add a new committer') };
        render_param( $new_committer => 'person' );
        render_param( $new_committer => 'name' );
        render_param( $new_committer => 'access_level' );
        render_param( $new_committer => 'project', render_as => 'Hidden' );
        form_submit( submit => $new_committer, label => 'Invite em!' );

        h2 { _('Current committers') };
        my $committers = $project->people;
        ul {
            while ( my $committer = $committers->next ) {
                my $member = CommitBit::Model::ProjectMember->new();
                $member->load_by_cols(
                    project => $project,
                    person  => $committer
                );
                my $del = Jifty->web->new_action(
                    class   => 'DeleteProjectMember',
                    record  => $member,
                    moniker => 'delete-member-' . $member->id
                );
                li {
                    outs( ( $member->name || $committer->email ) . ":  "
                            . $committer->name_and_email );
                    if ( $committer->email_confirmed ) {
                        outs( "(" . $member->access_level . ")" );
                    } else {
                        em { $member->access_level . " (pending)" };
                    }
                    $del->button(
                        label     => 'Delete',
                        class     => 'delete',
                        arguments => { id => $member->id },
                        onclick   => {
                            confirm =>
                                q{Really revoke this person's project access?}
                        }
                    );

                };
            }
        }
    }
    };

template 'admin/repositories' => page {
    title => 'Manage repositories';
}
content {

    dl {
        my $repositorys = CommitBit::Model::RepositoryCollection->new;
        $repositorys->find_all_rows();
        while ( my $p = $repositorys->next ) {
            dt {
                hyperlink(
                    url   => '/admin/repository/' . $p->name,
                    label => $p->name
                );
            };
            dd { $p->description };
        }
    };
    if ( Jifty->web->current_user->user_object->admin ) {
        hyperlink(
            label => 'Create another repository',
            url   => '/admin/create_repository'
        );
    }

};

template 'project/index.html' => page { title => get('project')->name }
    content {
    my $project = get('project');
    my %people = (
        observers      => $project->observers,
        authors        => $project->members,
        administrators => $project->administrators
    );
    my $edit    = Jifty->web->new_action(
        class  => 'UpdateProject',
        record => $project
    );
    div {
        { class is "yui-gc" };
        div {
            { class is "yui-u first" };
            if ( $project->logo_url ) {
                img {
                    { src is $project->logo_url }
                };
            }
            h1 { $project->name };
            blockquote {
                $project->description;
            };

            if ( $project->lists_url ) {
                h2 {'Mailing lists'};
                hyperlink(
                    url   => $project->lists_url,
                    label => $project->lists_url
                );
            }

            if ( $project->wiki_url ) {
                h2 {'Wiki'};

                hyperlink(
                    url   => $project->wiki_url,
                    label => $project->wiki_url
                );
            }

            if ( $project->bugtracker_url ) {
                h2 {'Bug tracking'};

                hyperlink(
                    url   => $project->bugtracker_url,
                    label => $project->bugtracker_url
                );
            }

            h2 {'Version control'};

            if ( $project->svnweb_url ) {
                h3 {'Repository browser'};
                hyperlink(
                    url   => $project->svnweb_url,
                    label => $project->svnweb_url
                );
            }

            if ( $project->svn_url_anon ) {
                h3 {'Anonymous access'};
                hyperlink(
                    url   => $project->svn_url_anon,
                    label => $project->svn_url_anon
                );

            }
            if ( $project->svn_url_auth ) {
                h3 {'Committer access'};
                hyperlink(
                    url   => $project->svn_url_auth,
                    label => $project->svn_url_auth
                );
            }
            h2   {'License'};
            span { $project->license };
        };
        div {
            { class is "yui-u" };
            div {
                { id is "people" };
                h2 {'People'};

                foreach my $type ( sort keys %people ) {

                    h3 { _( ucfirst($type) ) };
                    ul {
                        while ( my $u = $people{$type}->next ) {
                            li { $u->name_and_email };
                        }
                    }
                }
                if ( Jifty->web->current_user->user_object ) {
                    if ($project->is_project_admin(
                            Jifty->web->current_user
                        )
                        || Jifty->web->current_user->user_object->admin
                        )
                    {
                        hyperlink(
                            label => _('Invite someone'),
                            url   => '/admin/project/'
                                . $project->name
                                . '/people'
                        );
                    }
                }
            };
        };
    };
    };

template 'let/set_password' => page { title => 'Preferences' } content {
    Jifty->web->new_action(
        moniker => 'confirm_email',
        class   => 'ConfirmEmail',
    )->run;
    my $action = Jifty->web->new_action(
        class   => 'UpdateUser',
        moniker => 'prefsbox',
        record  => Jifty->web->current_user->user_object
    );

    my $next = Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

    p {
        _('Please set a password and nickname.')
            . _("(For now, you can't touch your email address)");
    };
    with( call => $next, name => "prefbox" ), form {
        render_param( $action => 'email', render_mode => 'read' );
        render_param( $action => 'nickname' );
        render_param( $action => 'password' );
        render_param( $action => 'password_confirm' );
        form_submit( label => 'Save', submit => $action );
    };

};

template prefs => page { title => 'Preferences' } content {
    my ( $action, $next ) = get( 'action', 'next' );

    div {
        { class is "svn_password" };
        h2 {'Subversion Password'};
        my $reset_svn_pw = Jifty->web->new_action(
            class  => 'UpdateUser',
            record => $action->record
        );
        span {
            { class is "svn_password" };
            $action->record->svn_password();
        };
        with( call => $next, name => "resetpw" ), form {
            form_submit(
                label  => 'Reset SVN Password',
                submit => $reset_svn_pw
            );
        };
    };
    h2 {'Preferences'};
    p {
        _(  "Update your password or name. (For now, you can't touch your email address)"
        );
    };
    form {
        render_param( $action => 'email', render_mode => 'read' );
        render_param( $action => 'name' );
        render_param( $action => 'password' );
        render_param( $action => 'password_confirm' );
        form_submit( label => 'Save', submit => $action );
    }
};

1;
