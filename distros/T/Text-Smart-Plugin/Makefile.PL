# $Id: Makefile.PL,v 1.1 2004/05/12 16:45:12 dan Exp $
# -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => "Text::Smart::Plugin",
	      VERSION_FROM => 'lib/Text/Smart/Plugin.pm',

	      PREREQ_PM => {
		  "Template" => "2.06",
		  "Text::Smart" => "1.0.0",
	      },
	      
	      dist =>
	      {
	       COMPRESS => 'gzip --force --best',
	      },

	      clean =>
	      {
	       FILES => '*.bak *~',
	      },
	      
	      depend => {
	        Makefile => '$(VERSION_FROM)',
	      },
	      
	      realclean => {
	       FILES => 'Text-Smart-*.tar.gz',
	      },
	     );

package MY;

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
  }

__END__
