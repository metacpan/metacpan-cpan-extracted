#!perl -w
use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;
use Config();

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %config = (
    NAME          => 'Win32::VisualStyles',
    VERSION_FROM  => 'VisualStyles.pm',
    ABSTRACT_FROM => 'VisualStyles.pm',
    AUTHOR        => 'Robert May <robertmay@cpan.org>',

    # MIN_PERL_VERSION
    ($mm_ver >= 6.48 ? (MIN_PERL_VERSION => '5.006') : ()),

    # LICENSE
    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    PL_FILES      => {'$(BASEEXT).manifest.PL' => '$(BASEEXT).manifest',
                      '$(BASEEXT).version.PL'  => '$(BASEEXT).version' },
    depend        => {'$(BASEEXT).res' => '$(BASEEXT).manifest $(BASEEXT).version', },
    OBJECT        => '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    macro         => { RC      => 'rc.exe',
                       RCFLAGS => '',
                     },
    clean         => { FILES => '$(BASEEXT).manifest $(BASEEXT).version', },

    # META_MERGE
    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'http://rob.themayfamily.me.uk/perl/win32-visualstyles',
            bugtracker  =>      'http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-VisualStyles',
            repository  =>      'http://github.com/remay/perl-win32-visualstyles',
                     },
    })),
    
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
if($Config::Config{cc} =~ /gcc/i) {
    $config{macro}->{RC} =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
}

WriteMakefile(%config);

package MY;

# Add rule for .rc to .res conversion
sub postamble {
  return <<'__POSTAMBLE';

.rc.res:
	$(RC) $(RCFLAGS) $<

__POSTAMBLE
}
