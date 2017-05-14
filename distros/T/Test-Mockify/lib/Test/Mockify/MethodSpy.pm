package Test::Mockify::MethodSpy;

use parent 'Test::Mockify::Method';

#---------------------------------------------------------------------
sub new {
    my $class = shift;
    my ($OriginalMethodPointer) = @_;
    my $self = $class->SUPER::new();
    $self->{'OriginalMethodPointer'} = $OriginalMethodPointer;
    return $self;
}
#---------------------------------------------------------------------
sub _addToTypeStore {
    my $self = shift;
    my ($Signature, $NewExpectedParameters) = @_;
    my $SignatureKey = join('',@$Signature);
    my $Parameter = Test::Mockify::Parameter->new($NewExpectedParameters);
    $Parameter->buildReturn()->thenCall($self->{'OriginalMethodPointer'});
    push(@{$self->{'TypeStore'}{$SignatureKey}}, $Parameter );
    return;
}

1;