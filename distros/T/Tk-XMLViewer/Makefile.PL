# -*- perl -*-

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tk::XMLViewer',
    'VERSION_FROM' => 'XMLViewer.pm', # finds $VERSION
    'PREREQ_PM' => {'Tk'          => 800.013,
	            'XML::Parser' => 0,
		    ($] < 5.006 ? ('Unicode::String' => 0) : ()),
	           },
    'PM'	=> {'XMLViewer.pm'   => '$(INST_LIB)/Tk/XMLViewer.pm',
		   },
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'EXE_FILES' => ['tkxmlview'],
    ($ExtUtils::MakeMaker::VERSION >= 6.54 ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-xmlviewer.git' }, }) : ()),
);

sub MY::postamble {
    my $postamble = <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -Mblib t/module.t -demo

EOF

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.cvs.mk"

EOF
    }

    $postamble;
}
