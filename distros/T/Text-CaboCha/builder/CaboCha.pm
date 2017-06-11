package builder::CaboCha;
use strict;
use warnings;
use parent qw/Module::Build::XSUtil/;

use builder::CaboCha::Config;
use builder::CaboCha::Const;

use Cwd::Guard ();
use File::Spec;
use File::Which;
use Data::Dumper;

sub new {
    my ($class, %args) = @_;

    my $config = $class->run_prove;
    require Devel::CheckLib;
    Devel::CheckLib::check_lib_or_exit(
        lib  => 'cabocha',
        LIBS => $config->{libs}
    );

    $class->define_symbols($config);
    $class->gen_const;

    $args{include_dirs}         = $config->{include};
    $args{extra_compiler_flags} = $config->{cflags};
    $args{extra_linker_flags}   = $config->{libs};
    
    return $class->SUPER::new(%args);
}

sub run_prove {
    my $class = shift;
    my $config = builder::CaboCha::Config->prove_config;

    if (exists $ENV{DEBUG}) {
        $config->{debugging} = 1;
    }

    return $config;
}

sub gen_const { builder::CaboCha::Const->write_files }

sub define_symbols {
    my $class = shift;
    my $config = shift;
    my @define;

    if ($^O =~ m/(?:MSWin2|cygwin)/) { # save us, the Win32 puppies
        # See also https://github.com/lestrrat/Text-MeCab/blob/master/Makefile.PL#L119-L125
        @define = (
            qq(-DTEXT_CABOCHA_ENCODING=\\"$config->{encoding}\\"),
            qq(-DTEXT_CABOCHA_CONFIG=\\"$config->{config}\\"),
        );
    } else {
        @define = (
            "-DTEXT_CABOCHA_ENCODING='\"$config->{encoding}\"'",
            "-DTEXT_CABOCHA_CONFIG='\"$config->{config}\"'",
        );
    }

    if ($config->{debugging}) {
        push @define, "-DTEXT_CABOCHA_DEBUG=1";
    }
    $config->{cflags} = join ' ', ($config->{cflags}, @define);
}

1;
