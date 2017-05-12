package Tie::Filter::Hash;

use 5.008;
use strict;
use warnings;

use Tie::Filter;

our $VERSION = '1.02';

=head1 NAME

Tie::Filter::Hash - Tie a facade around a hash

=head1 DESCRIPTION

Don't use this class directly. Instead, use L<Tie::Filter>.

=cut

sub TIEHASH {
	my ($class, $hash, %args) = @_;
	$args{WRAP} = $hash;
	return bless \%args, $class;
}

sub FETCH {
	my ($self, $key) = @_;
	Tie::Filter::_filter($$self{FETCHVALUE}, 
		$$self{WRAP}{Tie::Filter::_filter($$self{STOREKEY}, $key)});
}

sub STORE {
	my ($self, $key, $value) = @_;
	$$self{WRAP}{Tie::Filter::_filter($$self{STOREKEY}, $key)} = 
		Tie::Filter::_filter($$self{STOREVALUE}, $value);
}

sub DELETE {
	my ($self, $key) = @_;
	delete $$self{WRAP}{Tie::Filter::_filter($$self{STOREKEY}, $key)};
}

sub CLEAR {
	my $self = shift;
	%{$$self{WRAP}} = ();
}

sub EXISTS {
	my ($self, $key) = @_;
	exists $$self{WRAP}{Tie::Filter::_filter($$self{STOREKEY}, $key)};
}

sub FIRSTKEY {
	my $self = shift;
	my $a = keys %{$$self{WRAP}};
	if (my ($k) = each %{$$self{WRAP}}) {
		return (Tie::Filter::_filter($$self{FETCHKEY}, $k));
	} else {
		return ();
	}
}

sub NEXTKEY {
	my $self = shift;
	if (my ($k) = each %{$$self{WRAP}}) {
		return (Tie::Filter::_filter($$self{FETCHKEY}, $k));
	} else {
		return ();
	}
}

sub UNTIE { }

sub DESTROY { }

=head1 SEE ALSO

L<perltie>, L<Tie::Filter>

=head1 AUTHOR

  Andrew Sterling Hanenkamp, <sterling@hanenkamp.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Andrew Sterling Hanenkamp. All Rights Reserved. This library is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1
