package Tie::NetAddr::IP;

=pod

=head1 NAME

Tie::NetAddr::IP - Implements a Hash where the key is a subnet

=head1 SYNOPSIS

  use Tie::NetAddr::IP;

  my %WhereIs;
  
  tie %WhereIs, Tie::NetAddr::IP;

  $WhereIs{"10.0.10.0/24"} = "Lab, First Floor";
  $WhereIs{"10.0.20.0/24"} = "Datacenter, Second Floor";
  $WhereIs{"10.0.30.0/27"} = "Remote location";
  $WhereIs{"0.0.0.0/0"} = "God knows where";

  foreach $host ("10.0.10.1", "10.0.20.15", "10.0.32.17", "10.10.0.1") {
     print "Host $host is in ", $WhereIs{$host}, "\n";
  }

  foreach $subnet (keys %WhereIs) {
     print "Network ", $subnet, " is used in ", 
     $WhereIs{$subnet}, "\n";
  }

  untie %WhereIs;

=head1 DESCRIPTION

This module overloads hashes so that the key can be a subnet as in
B<NetAddr::IP>. When looking values up, an interpretation will be made
to find the given key B<within> the subnets specified in the hash.

The code sample provided on the B<SYNOPSIS> would print out the
locations of every machine in the C<foreach> loop.

Care must be taken, as only strings that can be parsed as an IP
address by B<NetAddr::IP> can be used as keys for this hash.

Iterators on the hash such as C<foreach>, C<each>, C<keys> and
C<values> will only see the actual subnets provided as keys to the
hash. When looking up a value such as in C<$hash{$ipaddress}> this IP
address will be looked up among the subnets existing as keys within
the hash. The matching subnet with the longest mask (ie, the most
specific subnet) will win and its associated value will be returned.

This code can be distributed freely according to the terms set forth
in the PERL license provided that proper credit is maintained. Please
send bug reports and feedback to the author for further improvement.

=cut

use strict;
use vars qw($VERSION);
use Carp;
use NetAddr::IP 3.00;

$VERSION = '1.51';

sub new {
    TIEHASH(shift);
}

sub TIEHASH {
    my $class = shift;
    my $self = [ ];
    bless $self, $class;
}

sub FETCH {
    my $self = shift;
    my $where = shift;
    my $ip = new NetAddr::IP $where;

    if ($ip) {
	my @fles = reverse @$self;
	for my $item (@fles) {
	    next unless ref $item;
	    for my $a (keys %{$item}) {
		if ($item->{$a}->{where}->contains($ip)) {
		    return $item->{$a}->{what};
		}
	    }
	}
    } else {
	croak "$where is not a valid NetAddr::IP specification";
    }

    return;			# None of the networks matched the spec
}

sub STORE {
    my $self = shift;
    my $where = shift;
    my $what = shift;
    my $ip = new NetAddr::IP $where;

    if ($ip) {
	$self->[$ip->masklen]->{$ip->addr} = {
	    where	=> $ip,
	    what	=> $what,
	};
    } else {
	croak "$where is not a valid IP address specification";
    }
}

sub EXISTS {
    my $self = shift;
    my $where = shift;
    my $ip = new NetAddr::IP $where;

    if ($ip) {
	return exists $self->[$ip->masklen]->{$ip->addr};
    } else {
	croak "$where is not a valid NetAddr::IP specification";
    }
    return;
}

sub DELETE {
    my $self = shift;
    my $where = shift;
    my $ip = new NetAddr::IP $where;

    if ($ip) {
	my $mask = $ip->masklen;
	my $addr = $ip->addr;

	return delete $self->[$mask]->{$addr};

    } else {
	croak "$where is not a valid NetAddr::IP specification";
    }
    return;
}

sub CLEAR {
    my $self = shift;
    splice(@$self, 0, $#{$self});
    return;
}

sub NEXTKEY {
    my $self = shift;
    my $last = shift;

    if (defined $last) {
	my $l_ip = new NetAddr::IP $last;
	return undef unless $l_ip;

	my $found = 0;

	for my $bits ($l_ip->masklen .. 128) {
	    for my $a (keys %{$self->[$bits]}) {
		if ($a eq $l_ip->addr and $bits == $l_ip->masklen) {
		    $found = 1;
		    next;
		}
		if ($found) {
		    my $r = $self->[$bits]->{$a}->{where}->cidr;
		    return wantarray ? ($r) : $r;
		}
	    }
	}
    } else {
	for my $bits (0 .. 128) {
	    for my $a (keys %{$self->[$bits]}) {
		my $r = $self->[$bits]->{$a}->{where}->cidr;
		return wantarray ? ($r) : $r;
	    }
	}
	
    }
    return;
}

sub FIRSTKEY { NEXTKEY $_[0], undef; }

1;

__END__

=pod

=head1 HISTORY

=over

=item 0.01

original version; created by h2xs 1.19

=item 1.00

Renamed to Tie::NetAddr::IP to match the modulelist name

=item 1.50

Modified to use NetAddr::IP v3.00. Added a number of new tests

=item 1.51

General update. Patch from Kazuyuki Maejima to fix bug related to
keys, next, each, etc.

=back

=head1 AUTHOR

Luis E. Muñoz (luismunoz@cpan.org)

=head1 SEE ALSO

perl(1), NetAddr::IP(3).

=cut

