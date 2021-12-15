# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 01-use.t".
#
# Without "Build" file it could be called with "perl -I../lib 01-use.t" or
# "perl -Ilib t/01-use.t".  This is also the command needed to find out what
# specific tests failed in a "./Build test" as the later only gives you a
# number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.12.1;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More tests => 33;

use File::Basename;

my $test = basename($0);
$test =~ s|\.|\\.|;

require_ok 'UI::Various';
require_ok 'UI::Various::core';

# define fixed environment for unit tests:
$ENV{DISPLAY}  or  $ENV{DISPLAY} = ':0';

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do T_PATH . '/functions/sub_perl.pl';

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

eval {   UI::Various::import({});   };
like($@, qr/^bad usage of UI::Various, \$pkg is 'HASH'$re_msg_tail/,
     'bad import #1 should fail');

eval {   UI::Various::import('UI');   };
like($@, qr/^bad usage of UI::Various as UI$re_msg_tail/,
     'bad import #2 should fail');

eval {   UI::Various::core::import([]);   };
like($@, qr/^bad usage of UI::Various::core, \$pkg is 'ARRAY'$re_msg_tail/,
     'bad import #3 should fail');

eval {   UI::Various::core::import('UI::Various');   };
like($@, qr/^bad usage of UI::Various::core as UI::Various$re_msg_tail/,
     'bad import #4 should fail');

eval {   UI::Various::core->import();   };
like($@, qr/^UI::Various::core must be 1st used from UI::Various$re_msg_tail/,
     'bad import #5 should fail');

eval {
    UI::Various->import();
    UI::Various::core->import();
};
is($@, '', '2nd import is OK');

eval {   UI::Various->import(debug => 1);   };
like($@, qr/^options must be specified as \{hash\}$re_msg_tail/,
     'bad import #6 should fail');

eval {   UI::Various->import({use => 'Curses::UI'});   };
like($@, qr/^'use' option must be an ARRAY reference$re_msg_tail/,
     'bad import #7 should fail');

eval {   UI::Various->import({use => ['Not::Supported']});   };
like($@, qr/^unsupported UI package 'Not::Supported'$re_msg_tail/,
     'bad import #8 should fail');

eval {   UI::Various->import({use => ['RichTerm']});   };
is($@, '', 'good use list is OK');

eval {   UI::Various->import({log => 'NEVER'});   };
like($@, qr/^undefined logging level 'NEVER'$re_msg_tail/,
     'bad import #9 should fail');

eval {   UI::Various->import({log => 'ERROR'});   };
is($@, '', 'good logging level is OK');

eval {   UI::Various->import({language => 1});   };
like($@, qr/^unsupported language '1'$re_msg_tail/,
     'bad import #10 should fail');

eval {   UI::Various->import({language => 'en'});   };
is($@, '', 'good language value is OK');

eval {   UI::Various->import({unknown => 1});   };
like($@, qr/^unknown option 'unknown'$re_msg_tail/,
     'bad import #11 should fail');

eval {   UI::Various->import({stderr => 'x'});   };
like($@, qr/^stderr not 0, 1, 2 or 3$re_msg_tail/,
     'bad import #12 should fail');

eval {   UI::Various->import({stderr => 1});   };
is($@, '', 'good STDERR value is OK');

$_ = UI::Various::stderr();
is($_, 0, 'STDERR 1 with GUI is 0');

my $using = '';
eval {
    $ENV{UI} = 'PoorTerm';
    UI::Various->import();
    $using = UI::Various::using();
    delete $ENV{UI};
};
is($@, '', 'import with environment variable UI is OK');
is($using, 'PoorTerm', 'environment variable UI overrides default');

my $display = $ENV{DISPLAY};
eval {
    delete $ENV{DISPLAY};
    UI::Various->import({use => [qw(Tk RichTerm)], stderr => 1});
    $using = UI::Various::using();
};
is($@, '', 'import without DISPLAY is OK');
is($using, 'RichTerm', 'import without DISPLAY gives correct result');
$_ = UI::Various::stderr();
is($_, 2, 'STDERR 1 without GUI is 2');

$ENV{DISPLAY} = $display;
SKIP:
{
    eval {   require Tk;   };
    skip 'no Perl/Tk', 2  if  $@;
    $using = '';
    eval {
	UI::Various->import({use => [qw(Tk RichTerm)]});
	$using = UI::Various::using();
    };
    is($@, '', 'import with DISPLAY is OK');
    is($using, 'Tk', 'import with DISPLAY gives correct result');
};

$using = '';
eval {
    UI::Various->import({use => [qw(_Zz_Unit_Test)]});
    $using = UI::Various::using();
};
is($@, '', 'import of missing package is OK');
is($using, 'PoorTerm', 'import of missing package gives correct result');

eval {   UI::Various->import({include => {Main => 1}});   };
like($@,
     qr/^'include' option must be an ARRAY reference or a scalar$re_msg_tail/,
     'bad indirect import fails');

eval {   UI::Various->import({include => 'X'});   };
like($@, qr/^unsupported UI element 'UI::Various::X'$re_msg_tail/,
     "indirect import of 'X' fails");

$_ = _sub_perl(	<<~'CODE');
		use UI::Various({include => [qw(Main)]});
		# check with introspection:
		defined $UI::Various::Main::{new}  and  print "OK\n";
		defined $UI::Various::Text::{new}  or  print "OK\n";
		CODE
is($?, 0, "indirect import of ['Main'] did not fail");
is($_, "OK\nOK\n", "indirect import of ['Main'] is OK");
