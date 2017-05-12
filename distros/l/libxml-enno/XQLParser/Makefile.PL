use ExtUtils::MakeMaker;

WriteMakefile(
              NAME	=> 'XML::XQL::Parser',
              PREREQ_PM => { Parse::Yapp => '0' },

	      PM => { 'Parser.pm' => '$(INST_LIBDIR)/Parser.pm' },

	      # Is this cheating or this this the only way to do it?
	      # Note: yapp.pl comes with Parse::Yapp
	      depend => { 'Parser.pm' => "Parser.yp\n\t\@\$(FULLPERL) \$(INSTALLBIN)/yapp.pl -m XML::XQL::Parser Parser.yp > Parser.pm"  },
             );

