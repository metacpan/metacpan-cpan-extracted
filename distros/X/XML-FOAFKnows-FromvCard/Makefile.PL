use 5.007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME              => 'XML::FOAFKnows::FromvCard',
	      VERSION_FROM      => 'lib/XML/FOAFKnows/FromvCard.pm', # finds $VERSION
	      PREREQ_PM         => {
				    Text::vCard => 1.96, # Older segfaults
				    Digest::SHA1 => 0,
				    IDNA::Punycode => 0,
				    Encode => 0,
				   },
	      ABSTRACT_FROM  => 'lib/XML/FOAFKnows/FromvCard.pm', # retrieve abstract from module
	      AUTHOR         => 'Kjetil Kjernsmo <kjetilk@cpan.org>',
	      EXE_FILES           => [qw(bin/foafvcard)],
	     );
