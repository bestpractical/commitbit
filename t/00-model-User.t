#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use Jifty::Test;
plan skip_all => 'the developers suck';

# Make sure we can load the model
use_ok('CommitBit::Model::User');

# Grab a system user
my $system_user = CommitBit::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = CommitBit::Model::User->new(current_user => $system_user);
my ($id) = $o->create();
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create();
ok($o->id, "User create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  CommitBit::Model::UserCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

