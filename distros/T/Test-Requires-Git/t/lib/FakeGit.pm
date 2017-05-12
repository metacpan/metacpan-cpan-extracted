package FakeGit;

use strict;
use warnings;

# Test::Requires::Git must have been loaded already
BEGIN {
    require Test::Requires::Git
      if !$INC{'Test/Requires/Git.pm'};
}

# import to build one fake git at compile time
sub import {
    my $package = shift;
    my $caller  = caller(0);
    no strict 'refs';
    *{"$caller\::fake_git"} = \&fake_git;
    fake_git(shift) if @_;
}

# helper routine to build a fake fit binary
sub fake_git {
    my ($version) = @_;
    $version =~ s/^(?=[0-9])/git version /;

    # monkey patch the code that returns git version
    no strict 'refs';
    no warnings 'redefine';
    *{'Test::Requires::Git::_git_version'} = sub { "$version\n" };
}

1;
