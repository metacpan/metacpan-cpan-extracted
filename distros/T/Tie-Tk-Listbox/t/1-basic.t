# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# 
# In order to see Tk in action, you will need to perform some simple
# modifications to this script.
# - Uncomment the 'MainLoop;' line at the end of the file.
# - Make a mental note that you won't see anything unless you
#   comment out the CLEAR test which wipes all data.

#########################
use Test::More tests => 26;

use strict;
use warnings;

use lib 'lib';
use Tie::Tk::Listbox;
use Tk;
ok(1, 'Loading modules.'); # If we made it this far, we're ok.

use vars qw/
  $main
  $scrollable
  $plainlistbox
/;

$main = MainWindow->new;

$scrollable  = $main->Scrolled(qw/Listbox -height 25 -width 40 -selectmode extended
                               -scrollbars oseo/)
                  ->pack(-side => 'left');

$plainlistbox  = $main->Listbox(qw/-height 25 -width 40 -selectmode extended
                               /)
                  ->pack(-side => 'right');

$scrollable->insert('end', map {"$_: ".('x'x$_)} 1..100);
$plainlistbox->insert('end', map {"$_: ".('x'x$_)} 1..100);

ok(1, 'Create Tk window, widgets, and insert data.');

tie my @scr => 'Tie::Tk::Listbox', $scrollable;
ok(1, 'Tie array to Scrolled widget.');
tie my @list => 'Tie::Tk::Listbox', $plainlistbox;
ok(1, 'Tie array to Listbox widget.');

my $value1;
my $value2;

$value1 = $scrollable->index('end');
$value2 = scalar @scr;
ok($value1 eq $value2, 'FETCHSIZE works as underlying index("end") for Scrolled.');

$value1 = $plainlistbox->index('end');
$value2 = scalar @list;
ok($value1 eq $value2, 'FETCHSIZE works as underlying index("end") for Listbox.');

$value1 = $scrollable->get(5);
$value2 = $scr[5];
ok($value1 eq $value2, 'FETCH works as underlying get() for Scrolled.');

$value1 = $plainlistbox->get(5);
$value2 = $list[5];
ok($value1 eq $value2, 'FETCH works as underlying get() for Listbox.');

$value1 = $scrollable->get( $scrollable->index('end') - 5 );
$value2 = $scr[-5];
ok($value1 eq $value2, 'FETCH w/ negative index works for Scrolled.');

$value1 = $plainlistbox->get( $plainlistbox->index('end') - 5 );
$value2 = $list[-5];
ok($value1 eq $value2, 'FETCH w/ negative index works for Listbox.');

$value1 = join '|', $scrollable->get( 7, 10 );
$value2 = join '|', @scr[7..10];
ok($value1 eq $value2, 'Slice works for Scrolled.');

$value1 = join '|', $plainlistbox->get( 7, 10 );
$value2 = join '|', @list[7..10];
ok($value1 eq $value2, 'Slice works for Listbox.');

$value2 = $scr[140];
ok(!defined($value2) && scalar(@scr) == 100, 'Index out of range works for Scrolled.');

$value2 = $list[140];
ok(!defined($value2) && scalar(@list) == 100, 'Index out of range works for Listbox.');

$scrollable->delete(3);
$scrollable->insert(3, 'New value');
$scr[10] = 'New value';
$value1 = $scr[3];
$value2 = $scr[10];
ok(
  ($value1 eq $value2 and scalar @scr == $scrollable->index('end')),
  'STORE works as underlying methods for Scrolled.'
);

$plainlistbox->delete(3);
$plainlistbox->insert(3, 'New value');
$list[10] = 'New value';
$value1 = $list[3];
$value2 = $list[10];
ok(
  ($value1 eq $value2 and scalar @list == $plainlistbox->index('end')),
  'STORE works as underlying methods for Listbox.'
);

$value1 = $scr[-1];
$value2 = pop @scr;
ok(
  ($value1 eq $value2 and scalar @scr == 99),
  'pop() works for Scrolled.'
);

$value1 = $list[-1];
$value2 = pop @list;
ok(
  ($value1 eq $value2 and scalar @list == 99),
  'pop() works for Listbox.'
);

push @scr, $value1;
ok(
  ($scr[-1] eq $value1 and scalar @scr == 100),
  'push() works for Scrolled.'
);

push @list, $value1;
ok(
  ($list[-1] eq $value1 and scalar @list == 100),
  'push() works for Listbox.'
);


$value1 = $scr[0];
$value2 = shift @scr;
ok(
  ($value1 eq $value2 and scalar @scr == 99),
  'shift() works for Scrolled.'
);

$value1 = $list[0];
$value2 = shift @list;
ok(
  ($value1 eq $value2 and scalar @list == 99),
  'shift() works for Listbox.'
);

unshift @scr, $value1;
ok(
  ($scr[0] eq $value1 and scalar @scr == 100),
  'unshift() works for Scrolled.'
);

unshift @list, $value1;
ok(
  ($list[0] eq $value1 and scalar @list == 100),
  'unshift() works for Listbox.'
);

@scr = ();
ok(scalar @scr == 0, 'CLEAR works for Scrolled.');

@list = ();
ok(scalar @list == 0, 'CLEAR works for Listbox.');


#MainLoop;



