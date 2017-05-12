package builder::MyBuilder;
use strict;
use warnings;
use parent qw/Module::Build::XSUtil/;

use Cwd::Guard ();
use File::Spec;
use File::Which;

sub new {
    my ($self, %args) = @_;

    if ( $^O =~ m!(?:MSWin32|cygwin)! ) {
        print "This module does not support Windows.\n";
        exit 0;
    }

    unless (which 'ruby') {
        print "This module require ruby.\n";
        exit 0;
    }

    $args{extra_compiler_flags} = ['-std=c99', '-fPIC', '-I' . File::Spec->rel2abs('vendor/mruby/include')];
    $args{extra_linker_flags}   = ['-L' . File::Spec->rel2abs('vendor/mruby/build/host/lib'), '-lmruby'];

    return $self->SUPER::new(%args);
}

sub ACTION_code {
    my $self = shift;

    my @libs = <vendor/mruby/build/*>;
    if (@libs <= 0) {
        my $guard = Cwd::Guard::cwd_guard('vendor/mruby/');
        system(q{make CFLAGS="-std=gnu99 -g -fPIC"}) == 0
            or die;
    }

    return $self->SUPER::ACTION_code(@_);
}

1;
