package Tie::Hash::Check;

use strict;
use warnings;

use Error::Pure qw(err);
use Error::Pure::Utils;

our $VERSION = 0.09;

# Error level.
$Error::Pure::Utils::LEVEL = 5;

# Hash create.
sub TIEHASH {
	my ($class, $hash_hr, $stack_ar) = @_;
	if (ref $hash_hr ne 'HASH') {
		err 'Parameter isn\'t hash.';
	}
	if (! $stack_ar) {
		$stack_ar = [];
	}
	if (ref $stack_ar ne 'ARRAY') {
		err 'Stack isn\'t array.';
	}
	my $self = bless {}, $class;
	$self->{'data'} = {};
	foreach my $key (keys %{$hash_hr}) {
		_add_hash_value($self->{'data'}, $key, $hash_hr->{$key}, 
			$stack_ar);
	}
	$self->{'stack'} = $stack_ar;
	return $self;
}

# Hash clear.
sub CLEAR {
	my $self = shift;
	$self->{'data'} = {};
	return;
}

# Hash delete.
sub DELETE {
	my ($self, $key) = @_;
	delete $self->{'data'}->{$key};
	return;
}

# Hash exists.
sub EXISTS {
	my ($self, $key) = @_;
	return exists $self->{'data'}->{$key};
}

# Hash fetch.
sub FETCH {
	my ($self, $key) = @_;
	if (! exists $self->{'data'}->{$key}) {
		my @stack = (@{$self->{'stack'}}, $key);
		err 'Key \''.join('->', @stack).'\' doesn\'t exist.';
	}
	return $self->{'data'}->{$key};
}

# Hash first key.
sub FIRSTKEY {
	my $self = shift;

	# Resets each.
	my $a = scalar keys %{$self->{'data'}};

	return each %{$self->{'data'}};
}

# Hash nextkey.
sub NEXTKEY {
	my $self= shift;
	return each %{$self->{'data'}};
}

# Hash scalar.
sub SCALAR {
	my $self = shift;
	return scalar %{$self->{'data'}};
}

# Hash store.
sub STORE {
	my ($self, $key, $value) = @_;
	_add_hash_value($self->{'data'}, $key, $value, $self->{'stack'});
	return;
}

# Add hash value to storage.
sub _add_hash_value {
	my ($hash_hr, $key, $value, $stack_ar) = @_;
	if (ref $value eq 'HASH') {
		tie my %tmp, 'Tie::Hash::Check', $value,
			[@{$stack_ar}, $key];
		$hash_hr->{$key} = \%tmp;
	} else {
		$hash_hr->{$key} = $value;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tie::Hash::Check - Tied construct for hash key checking.

=head1 SYNOPSIS

 use Tie::Hash::Check;

 tie my %hash, 'Tie::Hash::Check', {
         %parameters,
 };

=head1 SUBROUTINES

=over 8

=item C<TIEHASH>

 Hash create.

=item C<CLEAR>

 Hash clear.

=item C<DELETE>

 Hash delete.

=item C<EXISTS>

 Hash exists.

=item C<FETCH>

 Hash fetch.

=item C<FIRSTKEY>

 Hash first key.

=item C<NEXTKEY>

 Hash nextkey.

=item C<SCALAR>

 Hash scalar.

=item C<STORE>

 Hash store.

=back

=head1 ERRORS

 TIEHASH():
         Parameter isn't hash.
         Stack isn't array.

 FETCH():
         Key '%s' doesn't exist.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Tie::Hash::Check;

 # Set error type.
 $ENV{'ERROR_PURE_TYPE'} = 'Print';

 # Tied hash.
 tie my %hash, 'Tie::Hash::Check', {
         'one' => 1,
         'two' => 2,  
 };

 # Turn error "Key 'three' doesn't exist.".
 print $hash{'three'};

 # Output:
 # Tie::Hash::Check: Key 'three' doesn't exist.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Error::Pure::Utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Hash-Check>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2009-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
