# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 19-listbox.t".
#
# Without "Build" file it could be called with "perl -I../lib 19-listbox.t"
# or "perl -Ilib t/19-listbox.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More tests => 52;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Listbox)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

#########################################################################
# minimal dummy class needed for unit tests:
package Dummy
{   sub new { my $self = {}; bless $self, 'Dummy'; }   };

####################################
# test creation errors:
warning_like
{   $_ = UI::Various::Listbox->new();   }
{   carped => qr/^mandatory parameter 'height' is missing$re_msg_tail/   },
    'missing height parameter fails';
warning_like
{   $_ = UI::Various::Listbox->new(height => '');   }
{   carped =>
	qr/^parameter 'height' must be a positive integer$re_msg_tail/   },
    'empty height parameter fails';
warning_like
{   $_ = UI::Various::Listbox->new(height => 0);   }
{   carped =>
	qr/^parameter 'height' must be a positive integer$re_msg_tail/   },
    'wrong height parameter fails';
warning_like
{   $_ = UI::Various::Listbox->new(height => 1, selection => 3);   }
{   carped =>
	qr/^parameter 'selection' must be in \[0\.\.2\]$re_msg_tail/   },
    'wrong selection parameter fails';
warning_like
{   $_ = UI::Various::Listbox->new(height => 1, texts => '');   }
{   carped =>
	qr/^'texts' attribute must be a ARRAY reference$re_msg_tail/   },
    'bad texts parameter fails';
warning_like
{   $_ = UI::Various::Listbox->new(height => 1, on_select => '');   }
{   carped =>
	qr/^'on_select' attribute must be a CODE reference$re_msg_tail/   },
    'bad on_select parameter fails';

####################################
# test other error messages:
eval {   UI::Various::Listbox::add(Dummy->new(), '');   };
like($@,
     qr/^invalid object \(Dummy\) in call to .*::Listbox::add$re_msg_tail/,
     'bad access of add fails');
eval {   UI::Various::Listbox::remove(Dummy->new(), 0);   };
like($@,
     qr/^invalid object \(Dummy\) in call to .*::Listbox::remove$re_msg_tail/,
     'bad access of remove fails');
eval {   UI::Various::Listbox::replace(Dummy->new(), 0);   };
like($@,
     qr/^invalid object \(Dummy\) in call to .*::Listbox::replace$re_msg_tail/,
     'bad access of replace fails');

my $main = UI::Various::Main->new(width => 40);

####################################
# test default creation and some more error messages:
my $lb0 = UI::Various::Listbox->new(height => 5);
is($lb0->first(), -1, 'first of empty listbox is correct');
is_deeply($lb0->{texts}, [], 'texts of empty listbox are correct');

stdout_is(sub {   $lb0->_show('<1> ');   },
	  "      0/0\n\n\n\n\n\n",
	  '_show 1 prints correct empty Listbox');
my $output_select0 = "<0>   leave listbox\nenter selection: ";
stdout_is
{   _call_with_stdin("0\n", sub { $lb0->_process(); });   }
    "      0/0\n\n\n\n\n\n" . $output_select0 . "0\n",
    '_process 1 prints correct output for empty listbox';

stderr_like(sub {   $lb0->remove('x')},
	    qr/^parameter .* integer in call to .*::Listbox::remove$re_msg_tail/,
	    'wrong call to remove fails');

####################################
# test list with longer content (can be scrolled up and down):
my @text8 = ('1st entry', '2nd entry', '3rd entry', '4th entry',
	     '5th entry', '6th entry', '7th entry', '8th entry');
my $lb8 = UI::Various::Listbox->new(texts => \@text8,
				    height => 5, width => 9999, selection => 0);
is($lb8->first(), 0, 'first of non-empty listbox is correct');

stderr_like(sub {   $lb8->texts([41, 43]);   },
	    qr/^'texts' may not be modified.* after initialisation$re_msg_tail/,
	    'modifying texts after initialisation fails');

$main->add($lb8);			# now we have a maximum width
stdout_is(sub {   $lb8->_show('<1> ');   },
	  "<1>   1-5/8\n      1st entry\n      2nd entry\n" .
	  "      3rd entry\n      4th entry\n      5th entry\n",
	  '_show 2 prints correct listbox 8-0');

my $output_select1 = "<0>   leave listbox\nenter selection (+/- scrolls): ";
combined_is
{   _call_with_stdin("+\n+\n-\n-\nx\n0\n", sub { $lb8->_process(); });   }
    "<+/-> 1-5/8\n1st entry\n2nd entry\n3rd entry\n4th entry\n5th entry\n" .
    $output_select1 . "+\n" .
    "<+/-> 4-8/8\n4th entry\n5th entry\n6th entry\n7th entry\n8th entry\n" .
    $output_select1 . "+\n" .
    "<+/-> 4-8/8\n4th entry\n5th entry\n6th entry\n7th entry\n8th entry\n" .
    $output_select1 . "-\n" .
    "<+/-> 1-5/8\n1st entry\n2nd entry\n3rd entry\n4th entry\n5th entry\n" .
    $output_select1 . "-\n" .
    "<+/-> 1-5/8\n1st entry\n2nd entry\n3rd entry\n4th entry\n5th entry\n" .
    $output_select1 . "x\ninvalid selection\nenter selection (+/- scrolls): 0\n",
    '_process 2 prints correct output for listbox 8-0';

warning_like
{   $_ = $lb8->selected;   }
{   carped => qr/^invalid call to UI::.*::Listbox::selected$re_msg_tail/   },
    'call to selected for selection => 0 fails correctly';
is($_, undef, 'failed call to selected returns nothing');

$lb8->height(4);
combined_is
{   _call_with_stdin("+\n-\n0\n", sub { $lb8->_process(); });   }
    "<+/-> 1-4/8\n1st entry\n2nd entry\n3rd entry\n4th entry\n" .
    $output_select1 . "+\n" .
    "<+/-> 5-8/8\n5th entry\n6th entry\n7th entry\n8th entry\n" .
    $output_select1 . "-\n" .
    "<+/-> 1-4/8\n1st entry\n2nd entry\n3rd entry\n4th entry\n" .
    $output_select1 . "0\n",
    '_process 3 prints correct output for listbox 8-0';
$lb8->height(5);

####################################
# test list with single selection:
$lb8->selection(1);
$_ = $lb8->selected;
is($_, undef, 'checking empty selection also returns nothing');
stdout_is
{   _call_with_stdin("4\n2\n+\n5\n0\n", sub { $lb8->_process(); });   }
    "<+/-> 1-5/8\n<1>   1st entry\n<2>   2nd entry\n" .
    "<3>   3rd entry\n<4>   4th entry\n<5>   5th entry\n" .
    $output_select1 . "4\n" .
    "<+/-> 1-5/8\n<1>   1st entry\n<2>   2nd entry\n" .
    "<3>   3rd entry\n<4> * 4th entry\n<5>   5th entry\n" .
    $output_select1 . "2\n" .
    "<+/-> 1-5/8\n<1>   1st entry\n<2> * 2nd entry\n" .
    "<3>   3rd entry\n<4>   4th entry\n<5>   5th entry\n" .
    $output_select1 . "+\n" .
    "<+/-> 4-8/8\n<1>   4th entry\n<2>   5th entry\n" .
    "<3>   6th entry\n<4>   7th entry\n<5>   8th entry\n" .
    $output_select1 . "5\n" .
    "<+/-> 4-8/8\n<1>   4th entry\n<2>   5th entry\n" .
    "<3>   6th entry\n<4>   7th entry\n<5> * 8th entry\n" .
    $output_select1 . "0\n",
    '_process 4 prints correct output for listbox 8-1';
$_ = $lb8->selected;
is($_, 7,
   'call to selected after processing listbox 8-1 returns last selection');

####################################
# test list with 10 visible lines, also test late initialisation and
# multiple selection:
my @text12 = ('1st entry', '2nd entry', '3rd entry', '4th entry',
	      '5th entry', '6th entry', '7th entry', '8th entry',
	      '9th entry', '10th entry', '11th entry', '12th entry');
my $counter = 0;
my $lb12 = UI::Various::Listbox->new(texts => [], height => 10, selection => 2,
				     on_select => sub { $counter++; });
$lb12->texts(\@text12);		# reassigning an empty array is allowed!

$main->add($lb12);			# now we have a maximum width
stdout_is(sub {   $lb12->_show('<1> ');   },
	  "<1>   1-10/12\n      1st entry\n      2nd entry\n" .
	  "      3rd entry\n      4th entry\n      5th entry\n" .
	  "      6th entry\n      7th entry\n      8th entry\n" .
	  "      9th entry\n      10th entry\n",
	  '_show 5 prints correct listbox 12-2');

my $output_select2 = "< 0>   leave listbox\nenter selection (+/- scrolls): ";
stdout_is
{   _call_with_stdin("2 \n6, 8\n+\n10\n0\n", sub { $lb12->_process(); });   }
    "<+/->  1-10/12\n< 1>   1st entry\n< 2>   2nd entry\n< 3>   3rd entry\n" .
    "< 4>   4th entry\n< 5>   5th entry\n< 6>   6th entry\n< 7>   7th entry\n" .
    "< 8>   8th entry\n< 9>   9th entry\n<10>   10th entry\n" .
    $output_select2 . "2 \n" .
    "<+/->  1-10/12\n< 1>   1st entry\n< 2> * 2nd entry\n< 3>   3rd entry\n" .
    "< 4>   4th entry\n< 5>   5th entry\n< 6>   6th entry\n< 7>   7th entry\n" .
    "< 8>   8th entry\n< 9>   9th entry\n<10>   10th entry\n" .
    $output_select2 . "6, 8\n" .
    "<+/->  1-10/12\n< 1>   1st entry\n< 2> * 2nd entry\n< 3>   3rd entry\n" .
    "< 4>   4th entry\n< 5>   5th entry\n< 6> * 6th entry\n< 7>   7th entry\n" .
    "< 8> * 8th entry\n< 9>   9th entry\n<10>   10th entry\n" .
    $output_select2 . "+\n" .
    "<+/->  3-12/12\n< 1>   3rd entry\n< 2>   4th entry\n< 3>   5th entry\n" .
    "< 4> * 6th entry\n< 5>   7th entry\n< 6> * 8th entry\n< 7>   9th entry\n" .
    "< 8>   10th entry\n< 9>   11th entry\n<10>   12th entry\n" .
    $output_select2 . "10\n" .
    "<+/->  3-12/12\n< 1>   3rd entry\n< 2>   4th entry\n< 3>   5th entry\n" .
    "< 4> * 6th entry\n< 5>   7th entry\n< 6> * 8th entry\n< 7>   9th entry\n" .
    "< 8>   10th entry\n< 9>   11th entry\n<10> * 12th entry\n" .
    $output_select2 . "0\n",
    '_process 5 prints correct output for listbox 12-2';
my @result = $lb12->selected;
is_deeply(\@result, [1, 5, 7, 11],
	  'selected after processing listbox 12-2 returns correct selection');
is($counter, 3, 'counter for listbox 12-2 has correct 1st value');

####################################
# test add and remove as well as some errors not covered before:
$lb8->remove(6);
$_ = $lb8->selected;
is($_, 6,
   'call to selected after remove in listbox 8-1 returns correct selection');
$lb8->add('9th entry', '10th entry');
stdout_is
{   _call_with_stdin("+\n3\n0\n", sub { $lb8->_process(); });   }
    "<+/-> 4-8/9\n<1>   4th entry\n<2>   5th entry\n" .
    "<3>   6th entry\n<4> * 8th entry\n<5>   9th entry\n" .
    $output_select1 . "+\n" .
    "<+/-> 5-9/9\n<1>   5th entry\n<2>   6th entry\n" .
    "<3> * 8th entry\n<4>   9th entry\n<5>   10th entry\n" .
    $output_select1 . "3\n" .
    "<+/-> 5-9/9\n<1>   5th entry\n<2>   6th entry\n" .
    "<3>   8th entry\n<4>   9th entry\n<5>   10th entry\n" .
    $output_select1 . "0\n",
    '_process 6 prints correct modified output for listbox 8-1';
$_ = $lb8->selected;
is($_, undef, 'switching off selection in listbox 8-1 works');

$lb8->remove(0);
$_ = @{$lb8->texts()};
is($_, 8,
   'number of elements is correct after removing 1st element');
$lb8->remove(8);
$_ = @{$lb8->texts()};
is($_, 8,
   'number of elements has not changed after removing out of bounds element');
$lb8->remove(7);
$_ = @{$lb8->texts()};
is($_, 7,
   'number of elements is correct after removing last element');

stdout_is(sub {   $lb8->_show('<1> ');   },
	  "<1>   5-7/7\n      6th entry\n      8th entry\n      9th entry\n\n\n",
	  '_show 7 prints correct modified listbox 8-1');
stdout_is
{   _call_with_stdin("1\n-\n0\n", sub { $lb8->_process(); });   }
    "<+/-> 5-7/7\n<1>   6th entry\n<2>   8th entry\n<3>   9th entry\n\n\n" .
    $output_select1 . "1\n" .
    "<+/-> 5-7/7\n<1> * 6th entry\n<2>   8th entry\n<3>   9th entry\n\n\n" .
    $output_select1 . "-\n" .
    "<+/-> 1-5/7\n<1>   2nd entry\n<2>   3rd entry\n<3>   4th entry\n" .
    "<4>   5th entry\n<5> * 6th entry\n" .
    $output_select1 . "0\n",
    '_process 7 prints correct modified output for listbox 8-1';

$lb8->remove(1);
$lb8->remove(1);
$lb8->remove(1);

combined_is
{   _call_with_stdin("+\n\n7\n0\n", sub { $lb8->_process(); });   }
    "      1-4/4\n<1>   2nd entry\n<2> * 6th entry\n<3>   8th entry\n" .
    "<4>   9th entry\n\n" .
    $output_select0 . "+\n" .
    "invalid selection\nenter selection: \n" .
    "invalid selection\nenter selection: 7\n" .
    "invalid selection\nenter selection: 0\n",
    '_process 8 prints correct shortened output for listbox 8-1';
$_ = $lb8->selected;
is($_, 1,
   'call to selected after lots of modifications in listbox 8-1 is correct');
$lb8->remove(0);
$lb8->remove(0);
$_ = $lb8->selected;
is($_, undef, 'removing selected items in listbox 8-1 works correctly');
$lb8->remove(0);
$lb8->remove(0);
is($lb8->first(), -1, 'first of emptied listbox is correct');

$main->remove($lb8);

$lb12->remove(5);
@result = $lb12->selected;
is_deeply(\@result, [1, 6, 10],
   'call to selected after remove in listbox 12-2 returns correct selection');
$lb12->add('13th entry', '14th entry which is also a very long entry');
combined_is
{   _call_with_stdin("10,5,8\n+\n\n13\n0\n", sub { $lb12->_process(); });   }
    "<+/->  3-12/13\n< 1>   3rd entry\n< 2>   4th entry\n< 3>   5th entry\n" .
    "< 4>   7th entry\n< 5> * 8th entry\n< 6>   9th entry\n< 7>   10th entry\n" .
    "< 8>   11th entry\n< 9> * 12th entry\n<10>   13th entry\n" .
    $output_select2 . "10,5,8\n" .
    "<+/->  3-12/13\n< 1>   3rd entry\n< 2>   4th entry\n< 3>   5th entry\n" .
    "< 4>   7th entry\n< 5>   8th entry\n< 6>   9th entry\n< 7>   10th entry\n" .
    "< 8> * 11th entry\n< 9> * 12th entry\n<10> * 13th entry\n" .
    $output_select2 . "+\n" .
    "<+/->  4-13/13\n< 1>   4th entry\n< 2>   5th entry\n< 3>   7th entry\n" .
    "< 4>   8th entry\n< 5>   9th entry\n< 6>   10th entry\n" .
    "< 7> * 11th entry\n< 8> * 12th entry\n< 9> * 13th entry\n" .
#    1234567890123456789012345678901234567890
    "<10>   14th entry which is also a very l\n" .
    $output_select2 . "\n" .
    "invalid selection\nenter selection (+/- scrolls): 13\n" .
    "invalid selection\nenter selection (+/- scrolls): 0\n",
    '_process 9 prints correct output for listbox 12-2';
@result = $lb12->selected;
is_deeply(\@result, [1, 9, 10, 11],
	  'selected after processing listbox 12-2 returns correct selection');
is($counter, 4, 'counter for listbox 12-2 has correct 2nd value');

$main->remove($lb12);

####################################
# testing replacement of content:
my @text_r_a = ('entry #1', 'entry #2');
my @text_r_b = ('1st entry', '2nd entry', '3rd entry', 'on next page and long');
my @text_r_c = ();
my $next = 1;
my $lb_r;
$lb_r = UI::Various::Listbox->new(texts => \@text_r_a,
				  height => 3, selection => 1,
				  on_select => sub{
				      if ($next == 1)
				      {   $lb_r->replace(@text_r_b);   }
				      elsif ($next == 2)
				      {   $lb_r->replace(@text_r_c);   }
				      $next++;
				  });

$main->add($lb_r);			# now we have a maximum width
$main->width(undef);			# trigger different width computation

stdout_is
{   _call_with_stdin("1\n1\n0\n", sub { $lb_r->_process(); });   }
    "      1-2/2\n<1>   entry #1\n<2>   entry #2\n\n" .
    $output_select0 . "1\n" .
    "<+/-> 1-3/4\n<1>   1st entry\n<2>   2nd entry\n<3>   3rd entry\n" .
    $output_select1 . "1\n" .
    "      0/0\n\n\n\n" .
    $output_select0 . "0\n",
    '_process 10 prints correct output for listbox R';

is_deeply(\@text_r_a, ['entry #1', 'entry #2'],
	  'original external array is not modified by replace');

####################################
# triggering remaining missing coverage in base::_cut:
my @text2 = ('1st entry', '2nd entry');
$lb_r->replace(@text2);
stdout_is(sub {   $lb_r->_show('<1> ');   },
	  "<1>   1-2/2\n      1st entry\n      2nd entry\n\n",
	  '_show 11 prints correct listbox 2-0');
$lb_r->add();
$lb_r->add('3rd entry', '4th entry');
$lb_r->{first} = 1;
stdout_is(sub {   $lb_r->_show('<1> ');   },
	  "<1>   2-4/4\n      2nd entry\n      3rd entry\n      4th entry\n",
	  '_show 12 prints correct listbox 2-0');
$lb_r->remove(0);
$lb_r->remove(0);
$lb_r->remove(0);
stdout_is(sub {   $lb_r->_show('<1> ');   },
	  "<1>   1-1/1\n      4th entry\n\n\n",
	  '_show 13 prints correct listbox 2-0');
is($lb_r->first, 0, 'first after _show 14 is correct');
$lb_r->remove(0);
stdout_is(sub {   $lb_r->_show('<1> ');   },
	  "      0/0\n\n\n\n",
	  '_show 14 prints correct listbox 2-0');
is($lb_r->first, -1, 'first after _show 15 is correct');
$main->remove($lb_r);
