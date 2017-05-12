use ExtUtils::MakeMaker;

my $pm = q/RotCanvas/;

open MF, ">MANIFEST" or die "Can't create MANIFEST: $!\n";
print MF <<EOM;
MANIFEST
Makefile.PL
$pm.pm
test.pl
EOM
    ;

close MF or die $!;

open TEST, ">test.pl" or die "Can't create test.pl: $!\n";
print TEST $_ while <DATA>;
close TEST or die $!;

WriteMakefile(
	      NAME         => "Tk::$pm",
	      DISTNAME     => "Tk-$pm",
	      VERSION_FROM => "$pm.pm",
	      dist         => {
			       COMPRESS => 'gzip',
			       SUFFIX   => 'gz',
			      },
	      ($] >= 5 ? (
			  ABSTRACT => 'Canvas with rotatable objects',
			  AUTHOR   => 'Ala Qumsieh (qumsieh@cim.mcgill.ca)',
			 ) : (),
	      ),
	     );


__DATA__
#!perl -w

use strict;
use Test;

BEGIN { plan tests => 12 }

eval { require Tk };
ok($@, '', 'loading Tk module');

my $mw;
eval { $mw = Tk::MainWindow->new };
ok($@, '', "Can't create MainWindow");
ok(Tk::Exists($mw), 1, "MainWindow creation failed");
eval { $mw->geometry('+10+10') };

my $w;
my $class = 'RotCanvas';

print "Testing $class\n";
undef $w;

eval "require Tk::$class";
ok($@, '', "Error loading Tk::$class");

eval { $w = $mw->$class() };
ok($@, '', "can't create $class widget");
skip($@, Tk::Exists($w), 1, "$class instance does not exist");

if (Tk::Exists($w)) {
    eval { $w->pack };
    ok($@, '', "Can't pack a $class widget");

    eval { $mw->update };
    ok($@, '', "Error during 'update' for $class widget");

    eval { my @dummy = $w->configure };
    ok($@, '', "Error: configure list for $class");

    eval { $mw->update };
    ok($@, '', "Error: 'update' after configure for $class widget");

    eval { $w->destroy };
    ok($@, '', "can't destroy $class widget");
    ok(!Tk::Exists($w), 1, "$class: widget not really destroyed");
} else {
    for (1..5) {
	skip(1, 1, 1, "skipped because widget couldn't be created");
    }
}


