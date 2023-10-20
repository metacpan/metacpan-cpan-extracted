use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# named Win32:: for a good reason. Recommendation from FAQ
# die "No support for OS\n" unless ($^O eq 'MSWin32');

my $version = "0.21";	# for nomake versions

my @SERIALS;

# Scan for argument we know about
my @passargs;
if (@ARGV) {
	foreach my $arg (@ARGV) {
		my ($key,$value)=split /=/, $arg, 2;
		if ($key eq "TESTPORT") {
			push(@SERIALS,$value);
		}
		else {
			push(@passargs,$arg);
		}
	}
}
@ARGV=@passargs;

my $file = "COM1";
if (@SERIALS) {
    # only first one is relevant
    $file = shift @SERIALS;
}
# confirm a test device seems to exist (presumes passed Win32 test above)
# tested with cmd and bash shells
if (system('echo', 'test', '>', $file)) {
	warn "Device $file does not appear to exist. Testing impossible\n";
	exit (0);
} else {
	warn "found result=$?, file=$file\n";
}

print <<COMMENTS;
            Win::SerialPort and WinAPI::CommPort
                        VERSION $version

A 'Makefile' created for those with 'make' or CPAN.pm users.
It will test using PORT = $file. To test using a different PORT,
run again specifying: 'perl Makefile.PL TESTPORT=<PORT>'
The normal 'Mantra' would then apply:
        make
        make test
        make install

For those without 'make' or an equivalent like 'nmake' or 'dmake' there
are perl-only scripts which do the same things:
        Test with:    perl nomake_test
        Install with: perl nomake_install

Test with nothing connected to $file.
PORT is not verified present and accessible until tests run.
Timeout tests can take up to 30 seconds per test.
COMMENTS

my $dfile = "t/DefaultPort.pm";
unlink $dfile;
print "\nCreating new $dfile\n";
open my $default, '>', $dfile or die "Can't create $dfile: $!\n";
print {$default} <<EOF;
package SerialJunk;
# Created by Makefile.PL

\$Makefile_Test_Port = "$file";
EOF

close $default;


$dfile = "nomake_test";
unlink $dfile;
print "Creating new $dfile\n";
open $default, '>', $dfile or die "Can't create $dfile: $!\n";

print {$default} <<"TEST4";
# Created by Makefile.PL
# VERSION $version

use Test::Harness;
runtests ("t/test1.t", "t/test2.t", "t/test3.t", "t/test4.t",
	  "t/test5.t", "t/test6.t", "t/test7.t");

# To run individual tests, type:
#     C:\\> perl t/test1.t [ $file ]
# Continue with 'perl t/test2.t' through 'perl t/test7.t'
# See README and other documentation for additional information.
TEST4

close $default;

$dfile = "nomake_install";
unlink $dfile;
print "Creating new $dfile\n";
open $default, '>', $dfile or die "Can't create $dfile: $!\n";

print {$default} <<"INST4";
# Created by Makefile.PL
# VERSION $version

use 5.006;

use Config;
use strict;
use warnings;
use ExtUtils::Install qw( install );

my \$FULLEXT = "Win/SerialPort";
my \$INST_LIB = "./lib";
my \$HTML_LIB = "./html";

my \$html_dest = "";	# edit real html base here if autodetect fails

if (exists \$Config{installhtmldir} ) {
    \$html_dest = "\$Config{installhtmldir}";
}
elsif (exists \$Config{installprivlib} ) {
    \$html_dest = "\$Config{installprivlib}";
    \$html_dest =~ s%\\\\lib%\\\\html%;
}

if ( length (\$html_dest) ) {
    \$html_dest .= '\\lib\\site';
    install({
	   read => "\$Config{sitearchexp}/auto/\$FULLEXT/.packlist",
	   write => "\$Config{installsitearch}/auto/\$FULLEXT/.packlist",
	   \$INST_LIB => "\$Config{installsitelib}",
	   \$HTML_LIB => "\$html_dest"
	  },1,0,0);
}
else {
    warn "Can't find html base directory. Skipping doc install\\n";
    install({
	   read => "\$Config{sitearchexp}/auto/\$FULLEXT/.packlist",
	   write => "\$Config{installsitearch}/auto/\$FULLEXT/.packlist",
	   \$INST_LIB => "\$Config{installsitelib}",
	  },1,0,0);
}

__END__
INST4

close $default;
my %mm_args=(
    'NAME'          => 'Win::SerialPort',
    'VERSION_FROM' => 'lib/Win/SerialPort.pm', # finds $VERSION
    'PREREQ_PM'     =>	{ 'Test::More' => 0,
			  'Win32::API' => 0,
			  'Win32' => 0
			}, # e.g., Module::Name => 1.1
    'ABSTRACT_FROM' => 'lib/Win/SerialPort.pm', # retrieve abstract from module
    'AUTHOR'        => 'Bill Birthisel <wcbirthisel@alum.mit.edu>',
    'LIBS'          => [''], # e.g., '-lm'
    'DEFINE'        => '', # e.g., '-DHAVE_SOMETHING'
    'INC'           => '-I.', # e.g., '-I. -I/usr/include/other'
    'clean'         => { 'FILES' => "t/DefaultPort.pm *.cfg t/*.cfg" },
    'realclean'     => { 'FILES' => "nomake_test nomake_install" },
    
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type		=> 'git',
				url			=> 'https://github.com/Azq2/perl-win32-serialport-fork',
				web			=> 'https://github.com/Azq2/perl-win32-serialport-fork'
			},
			bugtracker => {
				'web'	=> 'https://github.com/Azq2/perl-win32-serialport-fork/issues'
			}
		}}) : ()
	),
);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(%mm_args);
