use ExtUtils::MakeMaker qw( WriteMakefile prompt );
use File::Spec;
use FindBin qw($Bin);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::Palm::Install',
    'VERSION_FROM'	=> 'Install.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Test::More' => 0
	},
	'CONFIGURE' => \&configure
);

sub configure {
	my $palmuser = prompt("What's your hotsync user name?");
	my $cfg_file = File::Spec->catfile(
			$Bin, "Install", "Testconfig.pm"
		);	
	open OUT, ">$cfg_file" or die "$!: $cfg_file";
	print OUT <<EOT;
package Win32::Palm::Install::Testconfig;

\$palmuser = '$palmuser';

1;
EOT
	close OUT;
}
