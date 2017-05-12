# -*- perl -*-

require 5.008;
use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#######################################
EOD

print "\nConfiguring Thread::Apartment ...\n
";

my %prereqs = (
	'Thread::Queue::Duplex' => '0.92',
	'Class::ISA' => '0.32',
	'Class::Inspector' => '1.08',
	'Storable' => '2.15'
);

my %opts =
    ('NAME' => 'Thread::Apartment',
     'VERSION_FROM' => 'lib/Thread/Apartment.pm',
     'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' }
     );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Dean Arnold, Presicient Corp. (darnold@presicient.com)';
    $opts{'ABSTRACT'} = 'Apartment threading wrapper for Perl objects';
    $opts{'PREREQ_PM'} = \%prereqs;
}

my $ok = 1;
$ok &= CheckModule($_, $prereqs{$_})
	foreach (keys %prereqs);

print "
Missing modules are available from CPAN (search.cpan.org).

"
	unless $ok;

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereqs{$module} = $version || 0;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
		if ($@) {
		    print("\nYou don't have the $package package",
			  " version $version or later, installed.\n");
		    return 0;
		}
    } else {
		print "Checking for $package ... ";
		eval "use $module";
		if ($@) {
		    print("\nYou don't have the $package package installed.\n");
		    return 0;
		}
    }
    print "ok\n";
    return 1;
}
