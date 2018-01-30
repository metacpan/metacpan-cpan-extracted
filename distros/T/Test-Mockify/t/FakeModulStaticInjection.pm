package FakeModulStaticInjection;

use strict;
use FakeStaticTools qw ( ReturnHelloWorld HelloSpy HappyOverride);

sub overrideMethod {
    my $self = shift;
    return 'original Value';
}
sub overrideMethod_spy {
    my $self = shift;
    return 'original Value';
}

sub methodStaticHappyOverride {
    my $self = shift;
    return FakeStaticTools::HappyOverride();
}
sub methodImportedHappyOverride {
    my $self = shift;
    return HappyOverride();
}
sub HappyOverride{ #This overrides the imported Function use FakeStaticTools qw ( HappyOverride );
    return 'original in FakeModulStaticInjection';
}

sub useStaticFunctionSpy {
    my $self = shift;
    my ($PreFix) = @_;
    return $PreFix . ': '.FakeStaticTools::HelloSpy(@_);
}
sub useImportedStaticFunctionSpy {
    my $self = shift;
    my ($PreFix) = @_;
    return $PreFix . ': '.HelloSpy(@_);
}

sub useStaticFunction {
    my $self = shift;
    my ($PreFix) = @_;
    return $PreFix . ': '.FakeStaticTools::ReturnHelloWorld(@_);
}

sub useImportedStaticFunction {
    my $self = shift;
    my ($PreFix) = @_;
    return $PreFix . ': '.ReturnHelloWorld(@_);

}
1;