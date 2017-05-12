package Ruby::Collections::OrderedHash;
use Tie::Hash;
our @ISA = 'Tie::StdHash';
use strict;
use v5.10;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Ruby::Collections;

my %keys_table;

sub TIEHASH {
	my $class = shift;

	my %hash;

	bless \%hash, $class;
}

sub STORE {
	my ( $self, $key, $val ) = @_;

	if ( exists $self->{ p_obj($key) } ) {
		$self->{ p_obj($key) } = $val;
	}
	else {
		if ( defined $keys_table{$self} ) {
			$keys_table{$self}->push( p_obj($key) );
		}
		else {
			$keys_table{$self} = ra;
			$keys_table{$self}->push( p_obj($key) );
		}
		$self->{ p_obj($key) } = $val;
	}

	return $val;
}

sub FETCH {
	my ( $self, $key ) = @_;

	return $self->{ p_obj($key) };
}

sub FIRSTKEY {
	my ($self) = @_;

	if ( defined $keys_table{$self} ) {
		return $keys_table{$self}->first;
	}

	return undef;
}

sub NEXTKEY {
	my ( $self, $lastkey ) = @_;

	if ( defined $keys_table{$self} ) {
		my $last_index = $keys_table{$self}->index($lastkey);
		return $keys_table{$self}->at( $last_index + 1 );
	}

	return undef;
}

sub EXISTS {
	my ( $self, $key ) = @_;

	return defined $self->{ p_obj($key) };
}

sub DELETE {
	my ( $self, $key ) = @_;

	if ( exists $self->{$key} ) {
		$keys_table{$self}->delete($key);
		my $ret = $self->{$key};
		$self->{$key} = undef;
		return $ret;
	}

	return undef;
}

sub CLEAR {
	my ($self) = @_;

	%$self = ();
	if ( defined $keys_table{$self} ) {
		$keys_table{$self}->clear;
	}

	return $self;
}

1;
__END__;
