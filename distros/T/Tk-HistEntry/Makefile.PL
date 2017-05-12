# -*- perl -*-
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tk::HistEntry',
    'VERSION_FROM' => 'HistEntry.pm', # finds $VERSION
    'dist'      => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PREREQ_PM' => {
		    'Tk' => 0,
		    'Test::More' => 0,
		   },
    ($] >= 5.005 ?
        (
            ABSTRACT_FROM => 'HistEntry.pm',
            AUTHOR => 'Slaven Rezic <srezic@cpan.org>',
        ) : () ),
    ($ExtUtils::MakeMaker::VERSION >= 6.54 ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-histentry.git' },
		   }) : ()),
);

sub MY::postamble {
    my $postamble = <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -Mblib examples/1.pl
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -Mblib examples/newclass.pl

EOF

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
