# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 12-text.t".
#
# Without "Build" file it could be called with "perl -I../lib 12-text.t"
# or "perl -Ilib t/12-text.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 13;
use Test::Output;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }
$ENV{PATH} = '';		# for fixed TTY size of 24*80

use UI::Various({use => [], include => [qw(Main Text)]});

#########################################################################

my $main = UI::Various::Main->new(width => 20);

$_ = UI::Various::Text->new();
is(ref($_), 'UI::Various::PoorTerm::Text', 'Text is concrete class');
is($_->text(), '', 'empty constructor creates empty text');

$_ = UI::Various::Text->new(text => 'Hello');
is($_->text(), 'Hello', 'constructor sets text');
is($_->text('Hello World!'), 'Hello World!', 'text can be modified');
is($_->text(), 'Hello World!', 'text has been modified');

$main->add($_);			# now we have a maximum width

stdout_is(sub {   $_->_show(' ');   },
	  " Hello World!\n", '_show prints correct text');

$_ = UI::Various::Text->new(text => 'Hello World !', width => 5);
$main->add($_);
stdout_is(sub {   $_->_show('  ');   },
	  "  Hello\n  World\n  !\n", '_show prints correct text with width 5');

$_ = UI::Various::Text->new(text => 'Hello World!', width => 5);
$main->add($_);
stdout_is(sub {   $_->_show('  ');   },
	  "  Hello\n  World!\n", "_show prints correct text with width 5/'!'");

$_ = UI::Various::Text->new(text => 'Hello World!');
$main->add($_);
my $prefix = '1234567890' x 7 . ' ';
stdout_is(sub {   $_->_show($prefix);   },
	  $prefix . "Hello\n" . (' ' x 71) . "World!\n",
	  '_show prints correct text with long prefix');
$prefix = '1234567890' x 8 . ' ';
stdout_is(sub {   $_->_show($prefix);   },
	  $prefix . "Hello World!\n",
	  '_show prints correct text with overlong prefix');

my $var = 'text reference';
$_ = UI::Various::Text->new(text => \$var);
is($_->text(), $var, 'text reference is handled correctly');
$main->add($_);
stdout_is(sub {   $_->_show('  ');   },
	  "  text reference\n", "_show prints correct referenced text");
$var = 'referenced text';
stdout_is(sub {   $_->_show('  ');   },
	  "  referenced text\n",
	  "_show prints correct modified referenced text");
