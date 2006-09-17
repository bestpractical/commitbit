use warnings;
use strict;

package CommitBit::Notification::InviteToProject;
use base qw/CommitBit::Notification/;


__PACKAGE__->mk_accessors(qw/project sender access_level/);

=head1 NAME

CommitBit::InviteToProject

=head1 ARGUMENTS

C<to>, a L<Jifty::Plugin::Login::Model::User> whose address we are confirming.

=cut

=head2 setup

Sets up the fields of the message.

=cut

sub setup {
    my $self = shift;

    my $project =  $self->project;
    my $access_level = $self->access_level;
    my $user = $self->to;

    my $letme = Jifty::LetMe->new();
    $letme->email($self->to->email);
    $letme->path('confirm_email'); 
    my $confirm_url = $letme->as_url;
    my $appname = Jifty->config->framework('ApplicationName');

    $self->subject( "Welcome to ".$project->name."!" );
    $self->from( Jifty->config->framework('AdminEmail') );



    $self->body(<<"END_BODY");

Hi!

We'd like you to join us as a $access_level for @{[$project->name]}. 

The project uses Subversion to manage its codebase. To check code, in
or out of subversion point your client at:

    @{[$project->svn_url_auth]}

Your subversion username is: @{[$user->email]}
Your password is @{[$user->__value('password')]}

We know that sending your password in plaintext email is insecure 
and we're actively working to improve matters.

For more details about @{[$project->name]}, please visit:

@{[Jifty->config->framework('Web')->{'BaseURL'}]}/project/@{[$project->name]}


END_BODY
}

1;
