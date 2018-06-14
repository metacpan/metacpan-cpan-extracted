package TestML1;

use TestML1::Base;
our $VERSION = '0.55';

has runtime => ();
has compiler => ();
has bridge => ();
has library => ();
has testml => ();

sub run {
    my ($self) = @_;
    $self->set_default_classes;
    $self->runtime->new(
        compiler => $self->compiler,
        bridge => $self->bridge,
        library => $self->library,
        testml => $self->testml,
    )->run;
}

sub set_default_classes {
    my ($self) = @_;
    if (not $self->runtime) {
        require TestML1::Runtime::TAP;
        $self->{runtime} = 'TestML1::Runtime::TAP';
    }
    if (not $self->compiler) {
        require TestML1::Compiler::Pegex;
        $self->{compiler} = 'TestML1::Compiler::Pegex';
    }
    if (not $self->bridge) {
        require TestML1::Bridge;
        $self->{bridge} = 'TestML1::Bridge';
    }
    if (not $self->library) {
        require TestML1::Library::Standard;
        require TestML1::Library::Debug;
        $self->{library} = [
            'TestML1::Library::Standard',
            'TestML1::Library::Debug',
        ];
    }
}

1;
