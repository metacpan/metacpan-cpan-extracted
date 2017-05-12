#!perl -w
use strict;

use Test::More tests => 12;

my $debug = $ENV{PERL_MACRO_DEBUG};

use FindBin qw($Bin);
use lib "$Bin/tlib";
use Fatal qw(open unlink utime);

use File::Spec;
use File::stat;

my $pm1 = "$Bin/tlib/Foo.pm";
my $pm2 = "$Bin/tlib/Foo/Bar.pm";

unlink($pm1.'c') if -e $pm1.'c';
unlink($pm2.'c') if -e $pm2.'c';


{
	open my $save_stderr, '>&', \*STDERR;
	open *STDERR, '>', File::Spec->devnull
		unless $debug;

	is system($^X, '-c', "-I$Bin/../lib", $pm1), 0, 'compile Foo.pm';
	is system($^X, '-c', "-I$Bin/../lib", $pm2), 0, 'compile Bar.pm';

	open *STDERR, '>&', $save_stderr;

	my $mtime;

	$mtime = stat($pm1)->mtime + 1;
	utime $mtime, $mtime, $pm1;

	$mtime = stat($pm2)->mtime + 1;
	utime $mtime, $mtime, $pm2;
}

ok -e $pm1.'c', 'Foo.pmc exists';
ok -e $pm2.'c', 'Bar.pmc exists';

require Foo; # load 'Foo.pmc' and it will be reloaded
require Foo::Bar; # load 'Foo/Bar.pmc' and it will be reloaded

is Foo::f(), 'Foo::f', 'Foo::f()';
is Foo::g(), 'Foo::g', 'Foo::g()';
is Foo::Bar::f(), 'Foo::Bar::f', 'Foo::Bar::f()';
is Foo::Bar::g(), 'Foo::Bar::g', 'Foo::Bar::g()';


is Foo::h(), 'func', 'lexicality in Foo';
is Foo::Bar::h(), 'func', 'lexicality in Bar';

is Foo::Bar::g_before_defmacro(), 'func', 'true lexicality in Bar';

ok $INC{'macro.pm'}, 'macro.pm was loaded';


unless($debug){
	unlink($pm1.'c');
	unlink($pm2.'c');
}
 