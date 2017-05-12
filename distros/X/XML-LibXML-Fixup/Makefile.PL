use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'          => 'XML::LibXML::Fixup',
	      'VERSION_FROM'  => 'Fixup.pm',
	      'PREREQ_PM'     => {
		  Carp => undef,
		  Test::More => undef,
		  XML::LibXML => undef
		  },
	      ($] >= 5.005 ? (
			      ABSTRACT_FROM => 'Fixup.pm',
			      AUTHOR        => 'Nigel Wetters <nwetters@cpan.org>'
			      ) : ()
	       )
	      );
