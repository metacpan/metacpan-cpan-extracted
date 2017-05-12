# $Id: Makefile.PL,v 1.1 2004/08/01 21:19:09 kstephens Exp $

use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'UMMF',
    VERSION_FROM      => 'lib/UMMF.pm', # finds $VERSION
    EXE_FILES         => [
			  map(($_, "$_.pl"),
			      map("bin/$_",
				  qw(
				    argo2xmi
				     files2dirs
				     uml2xmi
				     ummf
				     )
				  )
			      )
			  ],
    PREREQ_PM         =>
 {
			  # Required by UMMF itself.
			  Parse::RecDescent   => 1.94,
			  XML::RegExp         => 0.02,
			  XML::Parser         => 2.29, #2.34,
			  #use XML::SAX2Perl,
			  XML::DOM            => 1.43, 
                          # lib-net-1.18, libwww-perl-5.76
			  #use Devel::StackTrace,
			  Template            => 2.10,
			  Archive::Zip        => 1.06,
			  YAML                => 0.35,

			  # Required by generated Perl code.
			  # Carp qw(confess),
			  Set::Object         => 1.05,
			  Scalar::Util        => 1.13,
			  Class::Multimethods => 1.70,
			 }, # e.g., Module::Name => 1.1
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/UMMF.pm', # retrieve abstract from module
       AUTHOR         => 'Kurt Stephens <kstephens@users.sourceforge.net>') : ()),
);
