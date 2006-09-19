#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Makes sure that all of the modules that are 'use'd are listed in the
Makefile.PL as dependencies.

=cut

use Test::More qw(no_plan);
use File::Find;
use Module::CoreList;

my %used;
find( \&wanted, qw/ lib bin t /);

sub wanted {
    return unless -f $_;
    return if $File::Find::dir =~ m!/.svn($|/)!;
    return if $File::Find::name =~ /~$/;
    return if $File::Find::name =~ /\.pod$/;
    
    # read in the file from disk
    my $filename = $_;
    local $/;
    open(FILE, $filename) or return;
    my $data = <FILE>;
    close(FILE);

    # strip pod, in a really idiotic way.  Good enough though
    $data =~ s/^=head.+?(^=cut|\Z)//gms;

    # look for use and use base statements
    $used{$1}{$filename}++ while $data =~ /^\s*use\s+([\w:]+)/gm;
    while ($data =~ m|^\s*use base qw.([\w\s:]+)|gm) {
        $used{$_}{$filename}++ for split ' ', $1;
    }
}

my %required;
{ 
    local $/;
    ok(open(MAKEFILE,"Makefile.PL"), "Opened Makefile");
    my $data = <MAKEFILE>;
    close(FILE);
    while ($data =~ /^\s*?(?:requires|recommends)\('([\w:]+)'(?:\s*=>\s*['"]?([\d\.]+)['"]?)?.*?(?:#(.*))?$/gm) {
        $required{$1} = $2;
        if (defined $3 and length $3) {
            $required{$_} = undef for split ' ', $3;
        }
    }
}

for (sort keys %used) {
    my $first_in = Module::CoreList->first_release($_);
    next if defined $first_in and $first_in <= 5.00803;
    next if /^(CommitBit|Jifty|Jifty::DBI|inc|t|TestApp|Application)(::|$)/;
    ok(exists $required{$_}, "$_ in Makefile.PL")
      or diag("used in ", join ", ", sort keys %{ $used{$_ } });
    delete $used{$_};
    delete $required{$_};
}

for (sort keys %required) {
    my $first_in = Module::CoreList->first_release($_, $required{$_});
    fail("Required module $_ is already in core") if defined $first_in and $first_in <= 5.00803;
}

1;

