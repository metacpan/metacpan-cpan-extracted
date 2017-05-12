use strict;
use warnings;
use Test::More;
use X11::WindowHierarchy;

plan skip_all => 'Set $ENV{DISPLAY} to run this test' unless length $ENV{DISPLAY};

plan tests => 6;

# This is all pretty basic, maybe we should try starting up a few things with known
# names / pids so we can check in more detail?
ok(my $tree = x11_hierarchy(), 'can get hierarchy');
is(ref $tree, 'HASH', 'is a hashref');
ok(exists $tree->{children}, 'has arrayref of children');

is(x11_filter_hierarchy(filter => sub { 0 }), 0, 'no windows with false coderef filter');
ok(eval { x11_filter_hierarchy(filter => sub { 1 }); 1 }, 'no exception raised with true coderef filter');
ok(eval { x11_filter_hierarchy(filter => qr/\w/); 1 }, 'no exception raised with regex filter');
