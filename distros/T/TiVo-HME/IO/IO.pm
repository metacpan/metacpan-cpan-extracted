package TiVo::HME::IO;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

use constant {
	MAX_CHUNK_SIZE => 65530,
	TERMINATE_CHUNK => pack('vv', 0, 0),
};

sub new {
	my($class, $io) = @_;

	my $self = {};
	$self->{io} = $io;

	bless $self, $class;
}

sub read_chunk_header {
	my($self) = @_;
	my $buf;

	my $io = $self->{io};

	my $len = $self->get_length;
    return if (!$len);

	# suck entire chunk off wire
	my $count = $io->sysread($buf, $len);
    return if (!$count || $count != $len);

	if ($len && $count) {
		$self->{current_chunk} = [ split //, $buf ];
		return $self->read_vint;
	}

	undef;
}

sub get_length {
	my($self) = @_;

	my $io = $self->{io};
	my($hi, $lo);

	# read in the 2 length bytes
	my $ret = $io->sysread($hi, 1);
    return if !$ret;

	$ret = $io->sysread($lo, 1);
    return if !$ret;

	(ord($hi) << 8) + ord($lo);
}

sub read_vint {
	my($self) = @_;

	my $data = $self->{current_chunk};

	my($buf, $value, $shift) = ('', 0, 0);
	$buf = ord(shift(@$data));

	while (($data && ($buf & 0x80)) == 0) {
		$value += ($buf << $shift);
		$shift += 7;
		if ($shift > 70) {
			die "vint it too long!\n";
		}
		$buf = ord(shift(@$data));
	}

	if (!$data) {
		die "Ran out of data!!\n";
	}

	$value += (($buf & 0x3f) << $shift);
	if (($buf & 0x40) != 0) {
		$value = -$value;
	}

	$value;
}

sub read_string {
	my($self) = @_;
	my $data = $self->{current_chunk};

	my $hi = ord(shift(@$data));
	my $lo = ord(shift(@$data));

	my $string_length = ($hi << 8) + $lo;

	join '', splice(@$data, 0, $string_length);
}

sub terminate_chunk {
	my ($self) = @_;

	my($term);

	undef $self->{current_chunk};

	# read in the 2 byte terminator
	$self->{io}->sysread($term, 2);
}

sub make_bool {
	my($self, $val) = @_;
	$val ? 1 : 0;
}

# oh, it ain't pretty
# probably not portable
sub make_float {
	my($self, $val) = @_;

	# pack it as a float & then suck out the hex string
	my $x = pack('f', $val);
	my $vv = hex(unpack('H*', $x));

	# & separate out the bytes
	my $b1 = ($vv >> 24) & 0xff;
	my $b2 = ($vv >> 16) & 0xff;
	my $b3 = ($vv >> 8) & 0xff;
	my $b4 = $vv & 0xff;

	($b1, $b2, $b3, $b4);
}

sub make_text {
	my($self, $string) = @_;
	my @ret;

	push @ret, $self->make_length(length($string));
	push @ret, map(ord, split //, $string);

	@ret;
}

sub make_vint {
	my($self, $val) = @_;

	my @buf;
	my $neg = $val < 0;
	$val = -$val if ($neg);

	while ($val > 0x3f) {
		push @buf, ($val & 0x7f);
		$val >>= 7;
	}

	if ($neg) {
		$val |= 0xc0;
	} else {
		$val |= 0x80;
	}

	push @buf, $val;

	@buf;
}

sub make_length {
	my($self, $len) = @_;

	my $hi = ($len >> 0x8) & 0xff;
	my $lo = 0xff & $len;

	($hi, $lo);
}

sub ship {
	my($self, $data, $term) = @_;
	my $io = $self->{io};

	my $length = @$data;

	while ($length > MAX_CHUNK_SIZE) {
		# peel off MAX_CHUNK_SIZE bytes & try again
		my @small_data = splice(@$data, 0, MAX_CHUNK_SIZE);
		$self->ship(\@small_data, 1);
		$length = @$data;
	}

	my @len = $self->make_length($length);

	# chunk length
	$self->{io}->syswrite(pack('v', $len[0]), 1);
	$self->{io}->syswrite(pack('v', $len[1]), 1);

	# the data
	$self->{io}->syswrite(pack('C*', @$data), $length);

	unless($term) {
		# terminate
		$self->{io}->syswrite(TERMINATE_CHUNK, 2);
	}
}

sub do {
	my($self, $format, @vals) = @_;
	my @packet;

	my @formats = split //, $format;
	my @send_format;

	if (scalar(@formats) != scalar(@vals)) {
		print "@formats vs. @vals\n";
		die "Wrong # of formats for values!!\n";
	}

	while(my $f = pop @formats) {
		my $val = pop @vals;
		if ($f eq 'v') {
			unshift @packet, $self->make_vint($val);
		} elsif ($f eq 's') {
			unshift @packet, $self->make_text($val);
		} elsif ($f eq 'f') {
			unshift @packet, $self->make_float($val);
		} elsif ($f eq 'b') {
			unshift @packet, $self->make_bool($val);
		} elsif ($f eq 'r') {
			unshift @packet, $val;
		} elsif ($f eq 'R') {
			unshift @packet, @$val;
		} else {
			die "I don't know format $f!!\n";
		}
	}

	$self->ship([@packet]);
}

1;

__END__

=head1 NAME

TiVo::HME::IO - Perl extension for 'chunked' encoding to talk to your TiVo.

=head1 SYNOPSIS

  use TiVo::HME::IO;

=head1 DESCRIPTION

There's pretty much nothing in here for you to use.  
TiVo::HME::Application handles passing data to & from this module, 
which talks to your TiVo.  Nothing to see here... move along.

=head1 SEE ALSO

TiVo::HME
TiVo::HME::Application
http://tivohme.sourceforge.net

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
