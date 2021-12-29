# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 03-widget-essential.t".
#
# Without 'Build' file it could be called with "perl -I../lib
# 03-widget-essential.t" or "perl -Ilib t/03-widget-essential.t".  This is
# also the command needed to find out what specific tests failed in a
# "./Build test" as the later only gives you a number and not the
# description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 28;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({log => 'WARN', include => 'none'});
use UI::Various::widget;

#########################################################################
# minimal dummy classes needed for unit tests:
package UI::Various::Leaf
{   use UI::Various::widget; our @ISA = qw(UI::Various::widget);   };
package UI::Various::container
{   use UI::Various::widget; our @ISA = qw(UI::Various::widget);   };
package UI::Various::Box
{   use UI::Various::widget; our @ISA = qw(UI::Various::container);   };
package Dummy
{   sub new { my $self = {}; bless $self, 'Dummy'; }   };

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

#####################################
# checks of parent():
my $b1 = UI::Various::Box->new();
ok($b1, 'created orphan test Box 1');
is(ref($b1), 'UI::Various::Box', 'orphan test Box 1 has correct type');
is($b1->parent(), undef, 'orphaned test Box 1 has no parent');

my $l1 = UI::Various::Leaf->new();
ok($l1, 'created orphan test Leaf 1');
is(ref($l1), 'UI::Various::Leaf', 'orphan test Leaf 1 has correct type');

eval {   my $b2 = UI::Various::Box->new(parent => $l1);   };
like($@,
     qr/^invalid parent 'UI::Various::Leaf' .*$re_msg_tail/,
     'creating test Box with Leaf as parent is not allowed');

my $b2 = UI::Various::Box->new(parent => $b1);
ok($b2, 'created test Box 2 with parent');
is(ref($b2), 'UI::Various::Box', 'test Box 2 with parent has correct type');
is($b2->parent(), $b1, 'test Box 2 has correct parent');

my $l2 = UI::Various::Leaf->new({parent => $b2});
ok($l2, 'created test Leaf with parent');
is(ref($l2), 'UI::Various::Leaf', 'test Leaf 2 with parent has correct type');
is($l2->parent(), $b2, 'test Leaf 2 has correct parent Box 2');

my $b3 = UI::Various::Box->new();
ok($b3, 'created orphan test Box 3');
is(ref($b3), 'UI::Various::Box', 'orphan test Box 3 has correct type');
is($b3->parent(), undef, 'orphaned test Box 3 has no parent');
$b3->parent($b2);
is($b3->parent(), $b2, 'test Box 3 now has parent Box 2');

$l2->parent($b3);
is($l2->parent(), $b3, 'test Leaf 2 has new parent Box 3');

#####################################
# checks of top():
eval {   $_ = UI::Various::widget::top(Dummy->new());   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::.*::top$re_msg_tail/,
     'bad call to top creates error');

$_ = $l2->top();
is($_, $b1, 'test Leaf 2 has correct top Box 1');

$b1->parent($b3);
is($b1->parent(), $b3, 'test Box 1 now has parent Box 1');
warning_like
{   $_ = $l2->top();   }
{   carped => qr/^cyclic .* detected 1 levels above.*$re_msg_tail/   },
    'parent cycles are detected correctly in top';
is($_, undef, 'parent cycles return undefined top');

if ($^V lt 'v5.20')		# workaround for Perl bugs #7508 / #109726
{
    warn("WARNING: Perl version ", $^V,
	 " (prior to 5.20) can't handle 'undef' parameters correctly\n");
    $b1->{parent} = undef;
}
else
{   $b1->parent(undef);   }
is($b1->parent(), undef, 'Box 1 again has no parent');
$_ = $l2->top();
is($_, $b1, 'test Leaf 2 again has correct top Box 1');

#####################################
# checks of other attributes unless already checked by proper widgets):
$_ = $b1->width(42);
is($_, 42, 'Box 1 got width 42');
$_ = $b1->width();
is($_, 42, 'Box 1 still has width 42');
$_ = $l2->width();
is($_, 42, 'Leaf 2 also returns width 42');
$_ = $l2->height();
is($_, undef, 'Leaf 2 returns no height');
