use ExtUtils::MakeMaker;

$VERSION = '1.00';

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install these PM files (or Emacs backups: *~)
    # Also don't install XML/Parser.pod and XML/Parser/Expat.pod because I copied
    # those from the XML::Parser distribution.
    return undef if $file =~ /(Parser.pod|Expat.pod|CmpDOM|CheckAncestors|~$)/;

    return $self->SUPER::libscan ($file);
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'libxml-enno',
    VERSION_FROM => 'Makefile.PL',
    PREREQ_PM => { 'XML::Parser' => '2.19',
		     # Maybe requiring Date::Manip 5.33 is too strict,
		     # it's what I was using. I know 5.20 doesn't work.
#		     Date::Manip => '5.33', 
#		     Parse::Yapp => '0',
		   },
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    EXE_FILES => [ 'bin/xql.pl' ],
);
