package builder::MyBuilder;
use strict;
use warnings;
use base qw(Module::Build);
use Devel::PPPort;
use File::Spec;

sub new {
    my ( $self, %args ) = @_;

    print "Writing ppport.h\n";
    Devel::PPPort::WriteFile(
        File::Spec->catfile(qw/lib Text Sass ppport.h/) );

    $self->SUPER::new(
        %args,
        c_source             => ['libsass'],
        extra_compiler_flags => [ '-x', 'c++' ],
        extra_linker_flags   => ['-lstdc++'],
    );
}

sub ACTION_code {
    my ($self) = @_;

    # libsass@7779ab5 includes lots of files that are not required.

    my $p = $self->{properties};

    my ($dir) = @{delete $p->{c_source}};
    push @{$p->{include_dirs}}, $dir;

    foreach my $file (glob("$dir/*.cpp")) {
        push @{$p->{objects}}, $self->compile_c($file);
    }

    $self->SUPER::ACTION_code();
}

sub compile_c {
    my $self = shift;

    # This logic is copied from M::B::Pluggable::XSUtil
    unless ($self->cbuilder->have_cplusplus) {
        warn
            "This environment does not have a C++ compiler(OS unsupported)\n";
        exit 0;
    };

    $self->SUPER::compile_c(@_);
}
1;
