package Valiant::Util::Exception;

use Moo;
use Devel::StackTrace 2.03;
 
has 'trace' => (
  is => 'ro',
  builder => '_build_trace',
  lazy => 1,
);

  sub _build_trace {
    my $self = shift;
    my $skip = 0;
    while (my @c = caller(++$skip)) {
      last if ($c[3] =~ /^(.*)::new$/ || $c[3] =~ /^\S+ (.*)::new \(defined at /)
        && $self->isa($1);
    }
    $skip++;

    Devel::StackTrace->new(
      message => $self->message,
      indent  => 1,
      skip_frames => $skip,
      no_refs => 1,
    );
  }

has 'message' => (
  is => 'ro',
  builder => '_build_message',
  lazy => 1,
  required => 1,
);

  sub _build_message { "Error" }

 
use overload(
  q{""}    => 'as_string',
  bool     => sub () { 1 },
  fallback => 1,
);
 
 
  
sub BUILD { shift->trace }
 
sub as_string {
  my $self = shift;

  if ( $ENV{VALIANT_FULL_EXCEPTION} ) {
    return $self->trace->as_string;
  }

  my @frames;
  my $last_frame;
  my $in_moose = 1;
  for my $frame ( $self->trace->frames ) {
      if ( $in_moose && $frame->package =~ /^(?:Valiant)(?::|$)/ )
      {
          $last_frame = $frame;
          next;
      }
      elsif ($last_frame) {
          push @frames, $last_frame;
          undef $last_frame;
      }

      $in_moose = 0;
      push @frames, $frame;
  }

  # This would be a somewhat pathological case, but who knows
  return $self->trace->as_string unless @frames;

  my $message = ( shift @frames )->as_string( 1, {} ) . "\n";
  $message .= join q{}, map { $_->as_string( 0, {} ) . "\n" } @frames;

  return $message;
} 
sub rethrow { die shift }

1;

=head1 NAME

Valiant::Exception - Base exceptions class;

=head1 SYNOPSIS

    # Nothing for end users here

=head1 DESCRIPTION

I just copied this from L<Moose::Exception> since I trust the authors.  You shouldn't
really use this unless you add doing L<Valiant> extensions and need to create a new
exception type.

You won't use any of this unless you are doing L<Valiant> extensions or validators.

=head1 ATTRIBUTES

=head2 trace

Full stack trace if you need it

=head2 message

The actual exception message

=head1 METHODS

This class does the following methods

=head2 as_string

Exception stringy-fied.  Used as an overloading target.

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
