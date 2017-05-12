package builder::MyBuilder;
use strict;
use warnings;
use utf8;
use 5.008_001;

use parent qw(Module::Build);
use File::pushd;

sub new {
    my $class = shift;
    $class->SUPER::new(
        @_,
        c_source => [qw(hoedown/src/)],
        ($^O eq 'MSWin32' ? (extra_compiler_flags => ['-D__USE_MINGW_ANSI_STDIO=1']) : ()),
    );
}

sub ACTION_code {
    my $self = shift;

    if (-d '.git') {
#       system($^X, 'author/generate.pl');
    }

    $self->SUPER::ACTION_code();
}

1;

