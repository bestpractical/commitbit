use strict;
use warnings;

package CommitBit::Model::User;
use Text::Password::Pronounceable;
use Jifty::DBI::Schema;

use CommitBit::Record schema {
    column 'name' => type is 'text';
    column 'email' => type is 'text', is distinct, is immutable, is mandatory;
    column 'password' => type is 'text', render_as 'password';
    column 'created' => type is 'timestamp', is immutable;
    column admin => type is 'boolean', default is '0';
    column email_confirmed => type is 'boolean', default is '0';

column auth_token =>
  since '0.0.10',
  render as 'unrendered',
  type is 'varchar',
  default is '',
  label is _('Authentication token');



column svn_password =>
  is mandatory,
  since '0.0.10',
  label is _('Subversion Password'),
  type is 'varchar',
  default is defer { Text::Password::Pronounceable->generate( 6 => 10) },
  hints is _('This password should be at least six characters'),
  render as 'password';

column password =>
  is mandatory,
  is unreadable,
  since '0.0.10',
  label is _('CommitBit Password'),
  type is 'varchar',
  hints is _('Your password should be at least six characters'),
  render as 'password',
  filters are 'Jifty::DBI::Filter::SaltHash';



};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;



# Your model-specific methods go here.
sub _brief_description {
    'name_and_email';

}


our $PASSWORD_GEN = Text::Password::Pronounceable->new(8,10);

sub create {
    my $self = shift;
    my $args = { @_ };
    unless (length $args->{password}) {
	$args->{password} = $PASSWORD_GEN->generate;
    }
    # XXX TODO, confirm email addresses always
    return $self->SUPER::create(%$args);
}

sub name_and_email {
    my $self = shift;
    return join(' ', ($self->name ||''), "<".$self->email.">");
}
  

=head2 current_user_can

=cut

sub current_user_can {
    my $self = shift;
    my $right = shift;
    my %args = (@_); 
    if ($right eq 'read') { 
            
        if ($args{'column'} && $args{'column'} eq 'password') {
                return 0;
        }
        return 1;

         }
    elsif (($right eq 'create' or $right eq 'update' or $right eq 'delete') and ($self->current_user->user_object && $self->current_user->user_object->admin)) {
        return 1;
    }

    if ($right eq 'update' and ($self->current_user->user_object && ($self->current_user->user_object->id == $self->id))) {
        if ($args{'column'} =~ /^(?:name|password)$/) {
            return 1;
        }


    }

    return $self->SUPER::current_user_can(@_);
}
1;

