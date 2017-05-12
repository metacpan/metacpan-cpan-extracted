use 5.005;
use ExtUtils::MakeMaker;

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     'NAME'	=> 'Tk::Getopt',
     'VERSION_FROM' => 'Getopt.pm', # finds $VERSION
     # in fact everything is optional, but usually everyone wants the
     # gui features of Tk::Getopt
     'PREREQ_PM'         => { 'Tk'             => 804,
			      'Tk::FontDialog' => 0,
			      'Data::Dumper'   => 0,
			      'Test::More'     => 0,
			      'File::Spec'     => 0,
			    },
     'LICENSE'  => 'perl',
     ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ('ABSTRACT_FROM' => 'Getopt.pm',
       'AUTHOR'        => 'Slaven Rezic <srezic@cpan.org>',
       'LICENSE'       => 'perl',
      ) : ()
     ),
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository =>
				    'git://github.com/eserte/tk-getopt.git'
				  },
		   }) : ()),
    );

sub MY::postamble {
    my $postamble = "";

    $postamble .= '
demo :: pure_all
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -I$(SITEARCHEXP)/Tk/demos/widget_lib -I$(VENDORARCHEXP)/Tk/demos/widget_lib -Mblib demos/tk-getopt.pl

';

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
