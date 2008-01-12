use warnings;
use strict;

package CommitBit::Action::ResetSvnPassword;

use base qw/CommitBit::Action::UpdateUser/;

sub take_action {
    my $self = shift;
    warn "HERE!!!";
    my ($val, $msg) =    $self->record->set_svn_password();
    if ($val) {
        $self->result->message(_('Your Subversion password has been changed.'));
        return 1;
        
    } else {
        $self->result->error(_($msg));
        return 0;
    }
}

1;
