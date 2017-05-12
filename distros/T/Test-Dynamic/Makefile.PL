use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Test::Dynamic',
    VERSION_FROM => 'Dynamic.pm',
    PREREQ_PM    => {
					 Test::Simple  => 0.30,
					 Test::More    => 0.61,
					 Test::Harness => 2.03,
				 },
	ABSTRACT     => 'Advanced automatic test counting for Test::More',
    AUTHOR       => 'Greg Sabino Mullane <greg@endpoint.com>',
    NO_META      => 1,
    clean        => { FILES => '*~ *.tmp' },
);

package MY;
sub manifypods {
	my $after = "\t \$(NOECHO) pod2html Dynamic.pm > Dynamic.pm.html\n\t\$(NOECHO) \$(RM_F) pod*.tmp pm_to_blib\n";
	$after .= qq{\t\$(NOECHO) \$(PERL) -pi -e "s/<link.*?>//" Dynamic.pm.html\n};
	$after .= qq{\t\$(NOECHO) \$(ECHO) Created Dynamic.pm.html\n};
	return shift->SUPER::manifypods(@_) . $after;
}
