# $Id: Makefile.PL,v 1.0 1998/04/09 14:44:00
require 5.002;
use ExtUtils::MakeMaker;

# Taken from Randy Ray's Makefile.PL for X11::Fvwm which was taken almost varbatim from Graham Barr's MailTools package

sub chk_version {

	my ($pkg, $wanted) = @_;
	$| = 1;
	print "Checking for $pkg...";

	eval { my $p; ($p = $pkg . ".pm") =~ s!::!/!g; require $p; };

	my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"} : "not found";

	my $vnum = ${"${pkg}::VERSION"} || 0;

	print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";
	$vnum >= $wanted;

	}

WriteMakefile(
    'NAME'	=> 'Text::ConvertPlatform',
    'VERSION_FROM' => 'ConvertPlatform.pm', # finds $VERSION
);
