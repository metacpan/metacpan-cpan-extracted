=pod

=head1 Name

Test::Mockify::ReturnValue - To define return values

=head1 DESCRIPTION

Use L<Test::Modify::ReturnValue|Test::Modify::ReturnValue> to define different types of return values. See method description for more details.

=head1 METHODS

=cut
package Test::Mockify::ReturnValue;
use strict;
use warnings;
use Test::Mockify::Tools qw (Error);
sub new {
    my $class = shift;
    my $self  = bless {
    }, $class;
    return $self;
}
=pod

=head2 thenReturn

The C<thenReturn> method set the return value of C<call>.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenReturn('Hello World');
  my $Result = $ReturnValue->call();
  is($Result, 'Hello World');

=cut
sub thenReturn {
    my $self = shift;
    my ($Value) = @_;
    Error('Return value undefined. Use "thenReturnUndef" if you need to return undef.') unless(defined $Value);
    $self->{'Value'} = $Value;
}
=pod

=head2 thenReturnArray

The C<thenReturnArray> method sets the return value of C<call> in the way that it will return an Array.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenReturnArray([1,23]);
  my @Result = $ReturnValue->call();
  is_deeply(\@Result, [1,23]);

=cut
sub thenReturnArray {
    my $self = shift;
    my ($Value) = @_;
    Error('NoAnArrayRef') unless(ref($Value) eq 'ARRAY');
    $self->{'ArrayValue'} = $Value;
}
=pod

=head2 thenReturnHash

The C<thenReturnArray> method sets the return value of C<call> in the way that it will return a Hash.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenReturnHash({1 => 23});
  my %Result = $ReturnValue->call();
  is_deeply(\%Result, {1 => 23});

=cut
sub thenReturnHash {
    my $self = shift;
    my ($Value) = @_;
    Error('NoAHashRef') unless(ref($Value) eq 'HASH');
    $self->{'HashValue'} = $Value;
}
=pod

=head2 thenReturnUndef

The C<thenReturnArray> method sets the return value of C<call> in the way that it will return undef.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenReturnUndef();
  my $Result = $ReturnValue->call();
  is($Result, undef);

=cut
sub thenReturnUndef {
    my $self = shift;
    $self->{'UndefValue'} = 1;
}
=pod

=head2 thenThrowError

The C<thenReturnArray> method sets the return value of C<call> in the way that it will create an error.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenThrowError('ErrorType');
  throws_ok( sub { $ReturnValue->call() }, qr/ErrorType/, );

=cut
sub thenThrowError {
    my $self = shift;
    my ($ErrorCode) = @_;
    Error('NoErrorCode') unless($ErrorCode);
    $self->{'ErrorType'} = $ErrorCode;
    return;
}
=pod

=head2 thenCall

The C<thenCall> method change the C<call> Function in a way that it will trigger the function and pass in the parameters.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenCall(sub{return join('-', @_);});
  my $Result = $ReturnValue->call('hello','world');
  is($Result, 'hello-world');

=cut
sub thenCall{
    my $self = shift;
    my ($FunctionPointer) = @_;
    Error('NoAnCodeRef') unless(ref($FunctionPointer) eq 'CODE');
    $self->{'FunctionPointer'} = $FunctionPointer;
    return;
}
=pod

=head2 call

The C<call> method will return the return value which was set with one of the setter methods likeC<thenReturn>.
In case of C<thenCall> it will also forward the parameters.
It will throw an error if one of the setter methods was not called at least once.

  my $ReturnValue = Test::Mockify::ReturnValue->new();
  $ReturnValue->thenReturn('Hello World');
  my $Result = $ReturnValue->call();
  is($Result, 'Hello World');

=cut
sub call {
    my $self = shift;
    my @Params = @_;
    if($self->{'ErrorType'}){
        Error($self->{'ErrorType'});

    }elsif($self->{'ArrayValue'}){
        return @{$self->{'ArrayValue'}};

    }elsif($self->{'HashValue'}){
        return %{$self->{'HashValue'}};

    }elsif($self->{'UndefValue'}){
        return;

    }elsif($self->{'FunctionPointer'}){
        return $self->{'FunctionPointer'}->(@Params);

    }elsif(defined $self->{'Value'}){
        return $self->{'Value'};

    }else{
        Error('NoReturnValue');
    }
}
1;
__END__

=head1 LICENSE

Copyright (C) 2017 ePages GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Christian Breitkreutz E<lt>christianbreitkreutz@gmx.deE<gt>

=cut
