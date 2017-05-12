# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-InheritanceTree.t'

#########################


use Test::More tests => 9;
use_ok    ('Tk');
require_ok('Tk::PerlInheritanceTree') ;


use strict;
use warnings;
my $mw = tkinit();
my $w;
eval{$w = $mw->PerlInheritanceTree};
ok( !$@,"instance creation: $@");

eval{$w->classname('NotExisting')};
ok( !$@,"Set classname to 'NotExisting': $@");
like( $w->{status},
      qr/Error.*'NotExisting'/,
      "Display Statusline for 'NotExisting'");

eval{$w->classname('Tk')};
ok( !$@,"Set classname to 'Tk': $@");
like( $w->{status}, qr/Showing.*'Tk'/, "Display Statusline for 'Tk'");

my $rows = $w->{nodes};
my $tknode = $rows->[0][0];
is ($tknode->text, 'Tk', "Display node for 'Tk'");

$w->node_clicked($tknode);
ok ($w->{m_list}, 'm_list is set')

