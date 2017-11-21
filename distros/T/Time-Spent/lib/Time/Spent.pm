
package Time::Spent;
# ABSTRACT: Track events and calculate a rolling average of time, er, spent
$Time::Spent::VERSION = '0.02';
use strict;
use warnings;
use Carp;
use Time::HiRes qw( );
use List::Util  qw( );

sub ts { Time::HiRes::time }

sub param (\%$;$) {
  my ( $param, $name, $default ) = @_;

  croak "expected parameter '$name'"
      if !exists $param->{ $name }
      && !defined $default;

  return $default unless exists $param->{ $name };
  return $param->{ $name };
}


sub new {
  my ( $class, %param ) = @_;
  my $length = param %param, 'length', undef;

  croak "parameter 'length' expected a positive integer"
    unless $length =~ /^\d*$/
        && $length > 0;

  my $self = {
    length  => $length,
    count   => 0,
    tracked => { },
    history => [ ],
    average => undef,
  };

  return bless $self, $class;
}


sub start {
  my $self = shift;

  croak 'expected one or more identifiers'
    unless @_;

  foreach ( @_ ) {
    croak "already tracking $_"
      if $self->is_tracking( $_ )
  }

  my $ts = ts;
  $self->{ tracked }{ $_ } = $ts foreach @_;

  return @_;
}


sub stop {
  my $self = shift;

  croak 'expected one or more identifiers'
    unless @_;

  foreach ( @_ ) {
    croak "not tracking $_"
      unless $self->is_tracking( $_ )
  }

  my $ts = ts;

  foreach ( @_ ) {
    my $spent = $ts - $self->{ tracked }{ $_ };
    delete $self->{ tracked }{ $_ };

    push @{ $self->{ history } }, $spent;
    ++$self->{ count };
  }

  while ( $self->{ count } > $self->{ length } ) {
    shift @{ $self->{ history } };
    --$self->{ count };
  }

  $self->{ average } = List::Util::sum0( @{ $self->{ history } } ) / $self->{ count };

  return @_;
}


sub avg { $_[ 0 ]->{ average } }


sub is_tracking { exists $_[ 0 ]->{ tracked }{ $_[ 1 ] } ? 1 : 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Spent - Track events and calculate a rolling average of time, er, spent

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Time::Spent;

  my $tracker = Time::Spent->new( length => 3 );

  $tracker->start( 'foo' );
  sleep 3;
  $tracker->stop( 'foo' );
  $tracker->avg; # 3 = 3/1

  $tracker->start( 'bar' );
  sleep 1;
  $tracker->stop( 'bar' );
  $tracker->avg; # 2 = (3+1)/2

  $tracker->start( 'baz' );
  sleep 5;
  $tracker->stop( 'baz' );
  $tracker->avg; # 3 = (3+1+5)/3;

  $tracker->start( 'bat' );
  sleep 6;
  $tracker->stop( 'bat' );
  $tracker->avg; # 4 = (1+5+6)/3


  my $tracker = Time::Spent->new( length => 3 );

  $tracker->start( 'life' );
  sleep 35;
  $tracker->start( 'universe' );
  sleep 76;
  $tracker->start( 'everything' );
  sleep 15;

  $tracker->stop( 'life', 'universe', 'everything' );
  $tracker->avg; # 42 (GET IT?!)

=head1 DESCRIPTION

C<Time::Spent> uses a simple rolling average to track tasks by the amount of
time they take.

=head1 METHODS

=head2 new

Create a new C<Time::Spent> object. Accepts one named parameter, C<length>,
which must be a positive whole number specifying the number of historical
entries to use in the calculation of the rolling average.

  Time::Spent->new( length => 30 );

=head2 start

Begins tracking for the specified identifiers. Returns the number of new
specifiers tracked. Croaks if the identifier is already being tracked or if no
identifiers are provided.

  $tracker->start( 'ident1', 'ident2', 'ident3' ); # returns 3
  $tracker->start( 'ident1' ); # croaks because ident1 is already tracked

=head2 stop

Completes tracking for the specified identifiers. The time taken since the call
to L</start> for each identifier is then added to the historical average time.
Removes completed entries' times from tracking as needed to maintain the
expected history length. Croaks if any provided identifier is not tracked or if
no identifiers are provided.

  $tracker->stop( 'ident1' );                      # croaks because ident1 is not tracked
  $tracker->start( 'ident1' );
  $tracker->stop( 'ident1' );                      # returns 1
  $tracker->start( 'ident1', 'ident2', 'ident3' ); # ok because we stopped tracking ident1
  $tracker->stop( 'ident1' );                      # returns 1
  $tracker->stop( 'ident2', 'ident3' );            # returns 2

=head2 avg

Returns the average time taken for tracked identifiers.

=head2 is_tracking

Returns true if the identifier passed is currently being tracked (that is, it
has been L</start>ed but not L</stop>ped.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
