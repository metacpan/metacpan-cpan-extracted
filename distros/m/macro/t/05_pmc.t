#!perl -w
use strict;

use Test::More tests => 14;

my $debug = $ENV{PERL_MACRO_DEBUG};

use FindBin qw($Bin);
use lib "$Bin/tlib";
use Fatal qw(open unlink);


my $pm1 = "$Bin/tlib/Foo.pm";
my $pm2 = "$Bin/tlib/Foo/Bar.pm";

unlink($pm1.'c') if -e $pm1.'c';
unlink($pm2.'c') if -e $pm2.'c';


{
	use File::Spec;

	open my $save_stderr, '>&', \*STDERR;
	open *STDERR, '>', File::Spec->devnull
		unless $debug;

	is system($^X, '-c', "-I$Bin/../lib", $pm1), 0, 'compile Foo.pm';
	is system($^X, '-c', "-I$Bin/../lib", $pm2), 0, 'compile Bar.pm';

	open *STDERR, '>&', $save_stderr;
}

ok -e $pm1.'c', 'Foo.pmc exists';
ok -e $pm2.'c', 'Bar.pmc exists';

require Foo; # load 'Foo.pmc';
require Foo::Bar; # load 'Foo/Bar.pmc';

is Foo::f(), 'Foo::f', 'Foo::f()';
is Foo::g(), 'Foo::g', 'Foo::g()';
is Foo::Bar::f(), 'Foo::Bar::f', 'Foo::Bar::f()';
is Foo::Bar::g(), 'Foo::Bar::g', 'Foo::Bar::g()';


is Foo::h(), 'func', 'lexicality in Foo';
is Foo::Bar::h(), 'func', 'lexicality in Bar';

is Foo::Bar::g_before_defmacro(), 'func', 'true lexicality in Bar';

{
	local $TODO = 'Line adjustment not yet implemented';

	is Foo::line(), Foo::correct_line(), 'Foo: correct lineno';
	is Foo::Bar::line(), Foo::Bar::correct_line(), 'Bar: correct lineno';
}

ok !$INC{'macro.pm'}, 'macro.pm was not loaded';


unless($debug){
	unlink($pm1.'c');
	unlink($pm2.'c');
}
 