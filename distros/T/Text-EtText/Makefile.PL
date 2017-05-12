require 5.005;
use ExtUtils::MakeMaker;

sub MY::libscan {
  my($self,$path) = @_;

  return '' if ($path =~ /windows_install/
  		|| $path =~ /fixpath/
                );

  $path;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Text::EtText',
    'VERSION_FROM' => 'lib/Text/EtText.pm', # finds $VERSION

    'EXE_FILES'	=> [ 'ethtml2text', 'ettext2html'],

    'PL_FILES' => '',

    'PMLIBDIRS' => [ 'lib' ],

    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
	      DIST_DEFAULT => 'tardist' },

    'clean' => { FILES =>
	't/log pod2html* '.
	'examples/*html EtText.spec doc/pod2html* ethtml2text '.
	'ettext2html'
    },

    'AUTHOR' => 'Justin Mason <jm@jmason.org>',
    'ABSTRACT' => 'A plain-text markup format for HTML'

);

package MY;

sub postamble {
  q{

pm_to_blib: ettext2html ethtml2text

ettext2html: ettext2html.raw
	$(PERL) fixpath.pl ettext2html.raw $@
	$(CHMOD) $(PERM_RWX) $@

ethtml2text: ethtml2text.raw
	$(PERL) fixpath.pl ethtml2text.raw $@
	$(CHMOD) $(PERM_RWX) $@

  };
}

