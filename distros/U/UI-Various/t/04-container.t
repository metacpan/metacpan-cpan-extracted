# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 04-container.t".
#
# Without "Build" file it could be called with "perl -I../lib 04-container.t"
# or "perl -Ilib t/04-container.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 47;
use Test::Warn;

# define fixed environment for unit tests:
use UI::Various({use => [], log => 'WARN', include => 'none'});

use UI::Various::container;

#########################################################################
# minimal dummy classes needed for unit tests:
package UI::Various::Leaf
{   use UI::Various::widget; our @ISA = qw(UI::Various::widget);   };
package UI::Various::PoorTerm::Leaf
{   use UI::Various::widget; our @ISA = qw(UI::Various::Leaf);   };
package UI::Various::Box
{   use UI::Various::widget; our @ISA = qw(UI::Various::container);   };
package UI::Various::PoorTerm::Box
{   use UI::Various::widget; our @ISA = qw(UI::Various::Box);   };
package Dummy
{   sub new { my $self = {}; bless $self, 'Dummy'; }   };

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

my $dummy = Dummy->new();
eval {   $_ = UI::Various::container::add($dummy);   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::.*::add$re_msg_tail/,
     'bad call to add creates error');
eval {   $_ = UI::Various::container::remove($dummy);   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::.*::remove$re_msg_tail/,
     'bad call to remove creates error');
eval {   $_ = UI::Various::container::child($dummy);   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::.*::child$re_msg_tail/,
     'bad call to child creates error');

my $b1 = UI::Various::Box->new();
eval {   $_ = $b1->add($dummy);   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::.*::add$re_msg_tail/,
     'adding bad object creates error');
eval {   $_ = $b1->remove($dummy);   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::.*::remove$re_msg_tail/,
     'removing bad object creates error');

# construction and first assembling:
my $b2 = UI::Various::Box->new();
$_ = $b1->add($b2);
is($_, 1, 'test Box 2 has been correctly added to test Box 1');
is($b2->parent(), $b1, 'test Box 2 has correct parent');

warning_like
{   $_ = $b1->child('x');   }
{   carped => qr/^invalid parameter 'x' in call to .*::child$re_msg_tail/   },
    'bad index triggers error';
is($_, undef, 'bad index returns undef');

$_ = $b1->child(0);
is($_, $b2, 'Box 2 is 1st child of Box 1');
$_ = $b1->child(-1);
is($_, $b2, 'Box 2 is last child of Box 1');

warning_like
{   $_ = $b1->child(1);   }
{   carped => qr/^no element found for index 1$re_msg_tail/   },
    'Box 2 is only child of Box 1';
is($_, undef, 'Box 1 has no other child');

my $l1 = UI::Various::Leaf->new();
my $l2 = UI::Various::Leaf->new();
$_ = $b2->add($l1, $l2);
is($_, 2, 'test Leaf 1 and 2 have been correctly added to test Box 2');
my $l3 = UI::Various::Leaf->new();
$_ = $b1->add($l3);
is($_, 1, 'test Leaf 3 has been correctly added to test Box 1');

# full iteration:
is($b2->children(), 2, 'Box 2 for iteration 1 has 2 children');
$_ = $b2->child();
is($_, $l1, 'iteration 1.1 through Box 2 finds Leaf 1');
$_ = $b2->child();
is($_, $l2, 'iteration 1.2 through Box 2 finds Leaf 2');
$_ = $b2->child();
is($_, undef, 'iteration 1.3 through Box 2 finds end');

# "move" element between containers:
$_ = $b2->add($l3);
is($_, 1, 'test Leaf 3 has been correctly moved to test Box 2');

warning_like
{   $_ = $b1->remove($l3);   }
{   carped => qr/^can't remove .*:Leaf: no such node in .*::Box$re_msg_tail/   },
    'removing non-existent element triggers error';
is($_, undef, 'removing non-existent element correctly returned undef');

# full iteration with resets:
is($b2->children(), 3, 'Box 2 for iteration 2/3 has 3 children');
$_ = $b2->child();
is($_, $l1, 'iteration 2.1 through Box 2 finds Leaf 1');
if ($^V lt 'v5.20')		# workaround for Perl bugs #7508 / #109726
{   $_ = $b2->child('');   }
else
{   $_ = $b2->child(undef);   }
is($_, undef, 'aborting iteration 2 through Box 2 returns undef');
$_ = $b2->child();
is($_, $l1, 'iteration 3.1 through Box 2 finds Leaf 1');
$_ = $b2->child();
is($_, $l2, 'iteration 3.2 through Box 2 finds Leaf 2');
$_ = $b2->child();
is($_, $l3, 'iteration 3.3 through Box 2 finds Leaf 3');
$_ = $b2->child();
is($_, undef, 'iteration 3.4 through Box 2 finds end');
$_ = $b2->child('');
is($_, undef, 'aborting after iteration 3 through Box 2 returns undef');

# remove in the middle:
$_ = $b2->remove($l2);
is($_, $l2, 'removing Leaf 2 returns it');
$_ = $b2->child();
is($_, $l1, 'iteration 4.1 through Box 2 finds Leaf 1');
$_ = $b2->child();
is($_, $l3, 'iteration 4.2 through Box 2 finds Leaf 3');
$_ = $b2->child();
is($_, undef, 'iteration 4.3 through Box 2 finds end');

# remove last while iterating:
$_ = $b2->child();
is($_, $l1, 'iteration 5.1 through Box 2 finds Leaf 1');
$_ = $b2->remove($l3);
is($_, $l3, 'removing Leaf 3 returns it');
$_ = $b2->child();
is($_, undef, 'iteration 5.2 through Box 2 finds end');

# remove first while iterating:
$b2->add($l2, $l3);
$_ = $b2->child();
is($_, $l1, 'iteration 6.1 through Box 2 finds Leaf 1');
$_ = $b2->remove($l1);
is($_, $l1, 'removing Leaf 1 returns it');
$_ = $b2->child();
is($_, $l2, 'iteration 6.2 through Box 2 finds Leaf 2');
$_ = $b2->child();
is($_, $l3, 'iteration 6.3 through Box 2 finds Leaf 3');
$_ = $b2->child();
is($_, undef, 'iteration 6.4 through Box 2 finds end');
$b2->remove($l2, $l3);

# remove middle while iterating:
$_ = $b2->add($l1, $l2, $l3);
is($_, 3, 'all Leaf elements have been correctly added to test Box 2 again');
$_ = $b2->child();
is($_, $l1, 'iteration 7.1 through Box 2 finds Leaf 1');
$b2->remove($l2);
$_ = $b2->child();
is($_, $l3, 'iteration 7.2 through Box 2 finds Leaf 3');
$_ = $b2->child();
is($_, undef, 'iteration 7.3 through Box 2 finds end');

################################################
# destructive test (must be last in test file!):
$l2->parent($b2);		# $l2 does not become a child of $b2 here!
warnings_like
{   $_ = $b1->add($l2);   }
    [ { carped =>
	qr/^can't remove .*::Leaf: no such node in .*::Box$re_msg_tail/ },
      { carped =>
	qr/^can't remove '.*HASH.*' from old parent '.*HASH.*'$re_msg_tail/ } ],
    'moving illegitimate child causes errors';
