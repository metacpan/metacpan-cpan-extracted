package WebGPU::Direct::Error
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use Scalar::Util qw/blessed/;
  use Exporter 'import';
  use Carp qw/croak/;

  use overload
      '""'     => \&as_string,
      bool     => sub {1},
      fallback => 1;

  our @EXPORT_OK = (qw/webgpu_die/);

  sub webgpu_die (
    $type,
    $message,
      )
  {
    __PACKAGE__->new( type => $type, message => $message )->throw;
  }

  state $has_devel_stacktrace = eval { require Devel::StackTrace };

  # No prototype to capture previous $@
  sub new
  {
    my $prev_excp = $@;
    my $class     = shift;
    my $ref       = { ref( $_[0] ) eq ref {} ? %{ $_[0] } : @_ };

    if ( blessed $ref->{message} && $ref->{message}->isa('WebGPU::Direct::StringView') )
    {
      $ref->{message} = $ref->{message}->as_string;
    }

    my $result = {
      $ref->%{qw/type message/},
      previous_exception => $prev_excp,
      longmess           => Carp::longmess( $ref->{message} ),
    };

    if ($has_devel_stacktrace)
    {
      $result->{trace} = Devel::StackTrace->new(
        ignore_class => __PACKAGE__,
      );
    }

    return bless( $result, $class );
  }

  sub type($self)
  {
    return $self->{type};
  }

  sub message($self)
  {
    return $self->{message};
  }

  sub previous_exception($self)
  {
    return $self->{previous_exception};
  }

  sub trace($self)
  {
    return $self->{trace};
  }

  sub longmess($self)
  {
    return $self->{longmess};
  }

  sub throw ($self)
  {
    die $self;
  }

  sub as_string ( $self, @ )
  {
    return $self->message;
  }
};

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::Error - Error objects produced by WebGPU::Direct

=head1 DESCRIPTION

Errors produced by WebGPU::Direct will be wrapped in a WebGPU::Direct::Error object. This contains the WebGPU error type and message as well as the previous perl exception. If L<Devel::StackTrace> is available, the stack trace will be recorded.

=head2 Functions

=head3 webgpu_die($type, $message)

Convenience function to automate creation of and throwing L<WebGPU::Direct::Error> objects.

=over

=item * Arguments

=over

=item * type

The WebGPU type of the error

=item * message

The WebGPU message of the error

=back

=back

=head2 Constructor

=head3 new(type => $type, message => $message)

=over

=item * Arguments

=over

=item * type

The WebGPU type of the error

=item * message

The WebGPU message of the error

=back

=back

=head2 Attributes

=head3 type

The WebGPU error type that was thrown.

=head3 message

The WebGPU error message that was thrown

=head3 previous_exception

The exception that was in C<$@> when the L<WebGPU::Direct::Error> object was constructed.

=head3 trace

If L<Devel::StackTrace> is installed, trace will have the L<Devel::StackTrace> object of the stack when the object was constructed.

=head3 longmess

The C<longmess> stack information from L<Carp> generated when the object was constructed.

=head3 throw

C<die> with this object. Equivalent to C<die $self>.

=head3 as_string

The stringified version of this error.
