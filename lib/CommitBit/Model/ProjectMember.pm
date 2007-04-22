use strict;
use warnings;

package CommitBit::Model::ProjectMember;
use Jifty::DBI::Schema;
use Jifty::RightsFrom column => 'project';

use CommitBit::Model::User;
use CommitBit::Model::Project;
use CommitBit::Notification::InviteToProject;

use CommitBit::Record schema {
    column person =>
        refers_to CommitBit::Model::User;
    column project =>
        refers_to CommitBit::Model::Project;
    column name =>
        type is 'text',
        label is 'Username',
        since '0.0.4';
    column access_level =>
        type is 'text',
        valid_values are qw(observer author administrator),
        default is 'observer';

};

# Your model-specific methods go here.

sub create {
    my $self = shift;
    my %args = (@_);
   
    $args{'person'} = $self->_email_to_id($args{'person'});
    
    my $obj = CommitBit::Model::ProjectMember->new();
    $obj->load_by_cols( project => $args{'project'}, name => $args{'name'});
    if ($obj->id && $obj->person->id != $args{'person'}) {
            return( undef, "That name is in use. Sorry about that.");
    }

    my (@result) = $self->SUPER::create(%args);
    if ($self->id) {
        my $invite = CommitBit::Notification::InviteToProject->new( project => $self->project, to => $self->person, sender =>$self->current_user->user_object, access_level => $self->access_level, name => $self->name)->send;

    }
    return (@result);

}

sub validate_person {
    my $self = shift;
    my $val = shift;
    return (1) if ($val =~ /^\d+$/ || $val =~ /@/);
    return undef;

}

sub validate_name  {
    my $self = shift;
    my $nick = shift;
    my $obj = CommitBit::Model::ProjectMember->new();
    $obj->load_by_cols( project => $self->project->id, name => $nick);
    if ($obj->id && $obj->person->id != $self->person->id) {
            return undef;
    }
    return 1;
}


sub set_person {
    my $self = shift;
    my $val = shift;
    $val = $self->_email_to_id($val);
    $self->_set(column => 'person', value => $val);
}

sub _email_to_id {
    my $self = shift;
    my $value = shift;
    return $value if (ref $value || $value =~ /^\d+$/);

    my $u = CommitBit::Model::User->new();
    $u->load_or_create( email => $value);
    return $u->id();
}

sub current_user_can {
    my $self      = shift;
    my $rightname = shift;
    if ( $rightname eq 'update' ) { return undef }
    if ( $rightname eq 'read' )   { return 1 }
    if (   $rightname eq 'delete'
        && $self->person->id == $self->current_user->id )
    {
        return 1;
    }
    return $self->delegate_current_user_can( $rightname => @_ );

}

1;

