use warnings;
use strict;

package CommitBit::Upgrade;

since '0.0.10' => sub { 
    Jifty->handle->simple_query('UPDATE users set subversion_password = password');
};

since '0.0.12' => sub {
    rename table => CommitBit::Model::User, column => 'nickname', to => 'name';
}

1;
