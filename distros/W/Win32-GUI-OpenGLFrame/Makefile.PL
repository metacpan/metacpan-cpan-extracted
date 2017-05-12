#!perl -w
use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;
use Config;
use File::Find();

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my @demos;
File::Find::find(sub { push @demos, $File::Find::name unless -d $_ }, 'demos');

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %config = (
    NAME          =>  'Win32::GUI::OpenGLFrame',
    VERSION_FROM  =>  'OpenGLFrame.pm',
    ABSTRACT_FROM =>  'OpenGLFrame.pm',
    AUTHOR        =>  'Robert May <robertmay@cpan.org>',

    # MIN_PERL_VERSION
    ($mm_ver >= 6.48 ? (MIN_PERL_VERSION => '5.006') : ()),

    # LICENSE
    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    PREREQ_PM     => {'Win32::GUI' => 0,
                      'OpenGL'     => 0,},

    PL_FILES      => {'$(BASEEXT).version.PL' => '$(BASEEXT).version', },
    depend        => {'$(BASEEXT).res' => '$(BASEEXT).version', },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    LIBS          =>  '-lopengl32',
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => "@demos" },
    clean         => {FILES => '$(BASEEXT).version', },

    # META_MERGE
    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'http://rob.themayfamily.me.uk/win32-gui/win32-gui-openglframe',
            bugtracker  =>      'http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-GUI-OpenGLFrame',
            repository  =>      'http://github.com/remay/perl-win32-gui-openglframe',
                     },
    })),
    
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
if($Config{cc} =~ /gcc/i) {
    $config{macro}->{RC} =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
}

WriteMakefile(%config);

package MY;

# Add rule for .rc to .res conversion
# Add rules to install demo scripts
sub postamble {
  return <<'__POSTAMBLE';

.rc.res:
	$(RC) $(RCFLAGS) $<

pure_all :: demo_to_blib
	$(NOECHO) $(NOOP)

demo_to_blib: $(DEMOS)
	$(NOECHO) $(MKPATH) $(INST_DEMODIR)
	$(CP) $? $(INST_DEMODIR)
	$(NOECHO) $(TOUCH) demo_to_blib

clean ::
	-$(RM_F) demo_to_blib

__POSTAMBLE
}
