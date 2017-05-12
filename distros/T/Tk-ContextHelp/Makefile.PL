use strict;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";

if ($^O eq 'MSWin32') {
    die <<EOF;
No support for OS.
Tk::InputO is not available for $^O
EOF
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	=> 'Tk::ContextHelp',
   'VERSION_FROM' => 'ContextHelp.pm', # finds $VERSION
   'PM'         => 
   {'ContextHelp.pm'   => '$(INST_LIBDIR)/ContextHelp.pm',
    'context_help.xbm' => '$(INST_LIBDIR)/context_help.xbm',
    'context_help_mask.xbm' => '$(INST_LIBDIR)/context_help_mask.xbm',
    'context_nohelp.xbm' => '$(INST_LIBDIR)/context_nohelp.xbm',
    'context_nohelp_mask.xbm' => '$(INST_LIBDIR)/context_nohelp_mask.xbm',
   },
   'PREREQ_PM'  => {'Tk'             => 402.002,
		    'Tk::Pod'        => 4, # really only optional
		    'Tk::InputO'     => 0,
		   },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/eserte/tk-contexthelp.git',
                web  => 'https://github.com/eserte/tk-contexthelp',
            },
        }})
     : ()
    ),
  );

sub MY::postamble {
    my $postamble = "";

    if ($is_devel_host) {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
