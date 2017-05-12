# $Id: Makefile.PL,v 1.1 2004/05/12 16:44:57 dan Exp $
# -*- perl -*-


use ExtUtils::MakeMaker;
use warnings;
use strict;

WriteMakefile(
	      NAME => "Text::Smart",
	      VERSION_FROM => 'lib/Text/Smart.pm',

	      dist =>
	      {
	       COMPRESS => 'gzip --force --best',
	      },
              EXE_FILES => ['bin/text-smart'],
	      clean =>
	      {
	       FILES => '*.bak *~',
	      },
              'NO_META' => 1,
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
