use v5.26;
use warnings;

package Twitter::ID;
# ABSTRACT: Parse the date from a Twitter Snowflake ID
$Twitter::ID::VERSION = '1.00';

use Carp qw(croak);


my $TW_EPOCH = 1288834974657;
my $WORKER_BITS = 10;
my $SEQUENCE_BITS = 12;

my $TIMESTAMP_SHIFT = $WORKER_BITS + $SEQUENCE_BITS;
my $WORKER_MASK = (-1 ^ (-1 << $WORKER_BITS)) << $SEQUENCE_BITS;
my $SEQUENCE_MASK = -1 ^ (-1 << $SEQUENCE_BITS);
my $MAX_WORKER = 1 << $WORKER_BITS;
my $MAX_SEQUENCE = 1 << $SEQUENCE_BITS;

my $LAST_PRE_SNOWFLAKE_ID = 29700859247;


sub new {
	my ($class, $id) = @_;
	
	if (ref $id eq 'HASH') {
		my $self = bless \(my $o = 0), $class;
		$self->_set( $id->{timestamp}, $id->{worker}, $id->{sequence} );
		return $self;
	}
	
	if (! $id) {
		return bless \(my $o = 0), $class;
	}
	
	bless \$id, $class;
}


sub _set {
	my ($self, $timestamp, $worker, $sequence) = @_;
	$timestamp //= $TW_EPOCH;
	$worker //= 0;
	$sequence //= 0;
	
	croak "Twitter timestamps before $TW_EPOCH unsupported" if $timestamp < $TW_EPOCH;
	croak "Twitter ID components must be positive" if $worker < 0 || $sequence < 0;
	croak "Worker ID $worker too large (max $MAX_WORKER)" if $worker >= $MAX_WORKER;
	croak "Sequence number $sequence too large (max $MAX_SEQUENCE)" if $sequence >= $MAX_SEQUENCE;
	
	$$self = ($timestamp - $TW_EPOCH) << $TIMESTAMP_SHIFT
		| $worker << $SEQUENCE_BITS
		| $sequence;
}


sub timestamp {
	my ($self, $timestamp) = @_;
	
	if (defined $timestamp) {
		$self->_set( $timestamp, $self->worker, $self->sequence );
		return;
	}
	
	return if $$self <= $LAST_PRE_SNOWFLAKE_ID;
	
	return ($$self >> $TIMESTAMP_SHIFT) + $TW_EPOCH;
}


sub worker {
	my ($self, $worker) = @_;
	
	if (defined $worker) {
		$self->_set( $self->timestamp, $worker, $self->sequence );
		return;
	}
	
	return if $$self <= $LAST_PRE_SNOWFLAKE_ID;
	
	return ($$self & $WORKER_MASK) >> $SEQUENCE_BITS;
}


sub sequence {
	my ($self, $sequence) = @_;
	
	if (defined $sequence) {
		$self->_set( $self->timestamp, $self->worker, $sequence );
		return;
	}
	
	return if $$self <= $LAST_PRE_SNOWFLAKE_ID;
	
	return $$self & $SEQUENCE_MASK;
}


sub epoch {
	my ($self, $epoch) = @_;
	
	croak "epoch() is read-only" if defined $epoch;
	
	my $timestamp = $self->timestamp;
	return unless defined $timestamp;
	return $timestamp / 1000;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::ID - Parse the date from a Twitter Snowflake ID

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 # https://twitter.com/Twitter/status/1445078208190291973
 my $tid = Twitter::ID->new( 1445078208190291973 );
 
 use Time::Piece;
 say Time::Piece->new( $tid->epoch );
 # Mon Oct  4 19:27:47 2021

=head1 DESCRIPTION

This Perl module allows calculating the date from a "Snowflake"
Twitter ID. Does not use the Twitter API.

=head1 METHODS

=head2 epoch

 $posix_seconds = $tid->epoch;

Convenience method to retrieve the seconds since the POSIX epoch.
Suitable to be directly passed on to S<e. g.> L<Time::Piece> or
L<DateTime> for further processing.

For Twitter IDs from before the introduction of "Snowflake" IDs,
this method currently returns an undefined value.

=head2 new

 $tid = Twitter::ID->new( 474971393852182528 );
 $tid = Twitter::ID->new({
   sequence => 0,
   timestamp => 1402076979493,
   worker => 129,
 });

Creates a new Twitter ID object. Accepts either the scalar
S<Twitter ID> or a hash reference with the ID components
(millisecond POSIX timestamp, worker ID, sequence number).

=head2 sequence

 $sequence = $tid->sequence; $tid->sequence( $sequence );

Reads or writes the ID's sequence number component. The sequence
number is a positive integer ranging from 0 to 4095.

For Twitter IDs from before the introduction of "Snowflake" IDs,
this method returns an undefined value.

=head2 timestamp

 $posix_milliseconds = $tid->timestamp;
 $tid->timestamp( $posix_milliseconds );

Reads or writes the ID's timestamp component. The timestamp is in
milliseconds since the POSIX epoch. Timestamps from before the
introduction of "Snowflake" IDs in late 2010 are unsupported.

For Twitter IDs from before the introduction of "Snowflake" IDs,
this method returns an undefined value.

=head2 worker

 $worker = $tid->worker; $tid->worker( $worker );

Reads or writes the ID's worker ident component. The worker ident
is a positive integer ranging from 0 to 1023. Its five most
significant bits represent the encoded Twitter datacenter number.

For Twitter IDs from before the introduction of "Snowflake" IDs,
this method returns an undefined value.

=head1 BUGS AND LIMITATIONS

This module currently requires and expects a Perl that is compiled
with 64-bit integer support.

Twitter IDs from before the introduction of "Snowflake" IDs in late
2010 are not currently supported by this software. The creation time
of such IDs may be estimated with the (unrelated) web service
L<TweetedAt|https://oduwsdl.github.io/tweetedat/>. I myself have no
need to parse Twitter IDs from 2010 or earlier and likely won't be
able to justify spending time on adding such a feature to this
module, but I'd be happy to accept patches or grant co-maintainer
status.

=head1 SEE ALSO

L<https://developer.twitter.com/en/docs/twitter-ids>

L<https://github.com/twitter-archive/snowflake/blob/b3f6a3c6ca/src/main/scala/com/twitter/service/snowflake/IdWorker.scala>

L<https://ws-dl.blogspot.com/2019/08/2019-08-03-tweetedat-finding-tweet.html>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
