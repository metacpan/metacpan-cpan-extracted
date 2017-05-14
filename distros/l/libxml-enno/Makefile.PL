use ExtUtils::MakeMaker;

$VERSION = '1.02';

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install these PM files (or Emacs or other backups: *~ *.bak)
    # Also don't install XML/Parser.pod and XML/Parser/Expat.pod because I copied
    # those from the XML::Parser distribution.
    return undef if $file =~ /(XML.Parser\.pod|Expat\.pod|CmpDOM|CheckAncestors|~$|\.bak$)/;

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
		   # I also know that 5.36 works.
		   'Date::Manip' => '5.33', 
		   'Parse::Yapp' => '0',
		   # LWP::UserAgent is used when parsing XML from URLs
		   # It's part of libwww-perl, and you don't strictly need it
		   # (some test cases may fail)
		   'LWP::UserAgent' => '0',
		   # XML::Parser::PerlSAX is part of libxml-perl.
		   # It's used by some test cases in t/chk_batch.t and you 
		   # don't strictly need it. Version 0.05 causes errors in the
		   # test cases in t/chk_batch.t.
		   'XML::Parser::PerlSAX' => '0.07',
		   },
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    EXE_FILES => [ 'bin/xql.pl' ],
);
