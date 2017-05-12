package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->c_source('vendor/ux-trie/src');
    my @extra_compiler_flags = qw(
        -x c++ -I. -Ivendor/ux-trie/src
        -Wall -Wextra -Wno-duplicate-decl-specifier -Wno-parentheses
        -Wno-unused -Wno-unused-parameter
    );
    my @extra_linker_flags = qw(-lstdc++);
    my $ld = $self->config('ld');
    if ($ld =~ s/^\s*env MACOSX_DEPLOYMENT_TARGET=[^\s]+ //) {
        $self->config(ld => $ld);
    }
    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
    }
    $self->extra_compiler_flags(@extra_compiler_flags);
    $self->extra_linker_flags(@extra_linker_flags);
    $self;
}

sub compile_xs {
    my ($self, $file, %args) = @_;
    require ExtUtils::ParseXS;
    $self->log_verbose("$file -> $args{outfile}\n");
    ExtUtils::ParseXS::process_file(
        filename   => $file,
        prototypes => 0,
        output     => $args{outfile},
        'C++'      => 1,
        hiertype   => 1,
    );
}

sub is_debug {
    -d '.git';
}

sub ACTION_build {
    my $self = shift;
    $self->ACTION_ppport_h() unless -e 'ppport.h';
    $self->SUPER::ACTION_build();
}

sub ACTION_ppport_h {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('ppport.h');
}

1;
__END__
