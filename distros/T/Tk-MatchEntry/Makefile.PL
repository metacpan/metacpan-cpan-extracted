
# A generic Makefile.PL file for any pure Perl/Tk mega-widget. Set
# $pm to the name of the Perl module, and update %widinfo.  Leave
# $widtrib undefined unless you have an addition for widget's User
# Contributed Demonstrations section.
#
# This program creates the MANIFEST and test.pl files, then invokes
# MakeMaker to create the Makefile.  sol0@Lehigh.EDU, 2001/01/01

use Tk::MMutil;
use vars qw/$pm $widinfo $widtrib %widtrib/;

$pm = 'MatchEntry';		# widget Class name
%widinfo = (			# PPM widget information
    ABSTRACT => 'Entry widget with auto-completion capability',
    AUTHOR   => 'Wolfgang Hommel (wolf@code-wizards.com)',
);
# $widtrib = 'metest.pl';	# widtrib demo file name

print "Writing MANIFEST for Tk::$pm\n";
open MANIFEST, ">MANIFEST" or die "Cannot open MANIFEST: $!";
print MANIFEST <<"end-of-manifest";
MANIFEST
Makefile.PL
$pm.pm
test.pl
ChangeLog
README
end-of-manifest
print MANIFEST "$widtrib\n" if $widtrib;
close MANIFEST or die $!;

print "Writing test.pl for Tk::$pm\n";
open TEST, ">test.pl" or die "Cannot open test.pl: $!";
while (<DATA>) {
    s/NavListbox/$pm/o;
    print TEST;
}
close TEST or die $!;

%widtrib = 
  ($widtrib => "\$(INST_ARCHLIB)/Tk/demos/widtrib/$widtrib") if $widtrib;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::$pm",
    DISTNAME      => "Tk-$pm",
    VERSION_FROM  => "$pm.pm",
    PM            => {"$pm.pm" => "\$(INST_LIBDIR)/$pm.pm", %widtrib},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ($] >= 5.005 ? %widinfo  : ()),
);
__DATA__
#!perl -w
use Test;
use strict;

BEGIN { plan tests => 12 };

eval { require Tk; };
ok($@, "", "loading Tk module");

my $mw;
eval {$mw = Tk::MainWindow->new();};
ok($@, "", "can't create MainWindow");
ok(Tk::Exists($mw), 1, "MainWindow creation failed");
eval { $mw->geometry('+10+10'); };

my $w;
my $class = 'NavListbox';

print "Testing $class\n";

eval "require Tk::$class;";
ok($@, "", "Error loading Tk::$class");

eval { $w = $mw->$class(); };
ok($@, "", "can't create $class widget");
skip($@, Tk::Exists($w), 1, "$class instance does not exist");

if (Tk::Exists($w)) {
    eval { $w->pack; };

    ok ($@, "", "Can't pack a $class widget");
    eval { $mw->update; };
    ok ($@, "", "Error during 'update' for $class widget");

    eval { my @dummy = $w->configure; };
    ok ($@, "", "Error: configure list for $class");
    eval { $mw->update; };
    ok ($@, "", "Error: 'update' after configure for $class widget");

    eval { $w->destroy; };
    ok($@, "", "can't destroy $class widget");
    ok(!Tk::Exists($w), 1, "$class: widget not really destroyed");
} else  { 
    for (1..5) { skip (1,1,1, "skipped because widget couldn't be created"); }
}

1;
