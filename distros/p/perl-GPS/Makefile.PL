use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use 5.005; # 4-argument substr

$AUTHOR       = 'Joao Pedro Goncalves <joaop@co.sapo.pt>';

my $has_weakref_module;
if (eval { require Scalar::Util; 1} ||
    eval { require WeakRef; 1}) {
    $has_weakref_module = 1;
}

WriteMakefile(
    'NAME'	=> "GPS::Garmin",
    'DISTNAME'  => "perl-GPS",
    'VERSION'   => '0.17',
    'PREREQ_PM' => {
	$^O eq 'MSWin32' ?
		('Win32::SerialPort' => 0.07) :
		('Device::SerialPort' => 0.07) # This is only a "COREQ"
	,
	!$has_weakref_module && $] >= 5.006 ?
		('Scalar::Util' => 0) :	       # This is only a "COREQ"
		()
	,
	},
    'PMLIBDIRS' => [qw(Garmin NMEA)],
    'AUTHOR'    => $AUTHOR,
    'NO_META'   => 1,
    'ABSTRACT'  => 'Interface to GPS receiver protocols'
);

sub MY::postamble {
    my $postamble = "";
    if ($^O ne 'MSWin32') {
	$postamble .= <<'EOF';
release: sf-release cpan-release

# Does not work for me (eserte)
sf-release:
	[ -e $(DISTVNAME).tar$(SUFFIX) ]
	sf-upload -pr perl-gps -p perl-gps -f $(DISTVNAME).tar$(SUFFIX)

cpan-release:
	[ -e $(DISTVNAME).tar$(SUFFIX) ]
	cpan-upload $(DISTVNAME).tar$(SUFFIX)

cvs-release-tag:
	@echo "Release create cvs tag RELEASE_$(VERSION_SYM) ?"
	@read yn
	cvs tag RELEASE_$(VERSION_SYM)

EOF
    }
    $postamble;
}
