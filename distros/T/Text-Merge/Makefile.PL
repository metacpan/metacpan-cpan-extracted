
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Text::Merge',
	'PM' => { 'lib/Text/Merge.pm' => '$(INST_LIBDIR)/Merge.pm',
		      'lib/Text/Merge/Lists.pm' => '$(INST_LIBDIR)/Merge/Lists.pm' },
	'INC' => './blib/' 
);

print qq|

Now do:

	make
	make test
	make install

to install the package.

|;

