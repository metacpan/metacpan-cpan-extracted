package VS::RuleEngine::Data;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(refaddr);

my %Locked;

sub lock {
	my $self = shift;
	$Locked{refaddr $self} = 1;
}

sub unlock {
	my $self = shift;
	delete $Locked{refaddr $self};
}

sub new {
	my $pkg = shift;
	my $self = bless { @_ }, $pkg;
	return $self;
}

sub set {
	my ($self, $key, $value) = @_;
	croak "Can't modify locked object" if $Locked{refaddr $self};	
	$self->{$key} = $value;
}

*put = \&set;

sub delete {
	my ($self, $key) = @_;
	croak "Can't modify locked object" if $Locked{refaddr $self};
	CORE::delete $self->{$key};
}

sub clear {
    my $self = shift;
	croak "Can't modify locked object" if $Locked{refaddr $self};
    delete $self->{$_} for keys %{$self};
}

sub get {
	my ($self, $key) = @_;
	return $self->{$key};
}

sub keys {
	my $self = shift;
	return CORE::keys %$self;
}

sub values {
	my $self = shift;
	return CORE::values %$self;
}

sub exists {
	my ($self, $key) = @_;
	return CORE::exists $self->{$key};
}

sub DESTROY {
    my $self = shift;
    delete $Locked{refaddr $self};
}

1;
__END__

=head1 NAME

VS::RuleEngine::Data - Data

=head1 INTERFACE

=head1 CLASS METHODS

=over 4

=item new ( @key_value_pairs )

Creates a new hash with starting values.

=back

=head2 INSTANCE METHODS

=over 4

=item lock

Locks the data so that modification isn't possible

=item unlock

Unlocks the data so modification is possible again

=item clear

Removes all keys and their associated data.

=item delete ( $key ) 

Deletes the key I<$key> and its data.

=item exists ( $key )

Checks if the key exists.

=item get ( $key)

Retrieves the value for I<$key>.

=item keys

Returns a list of all keys.

=item set ( $key )
=item put ( $key => $value )

Sets the value for I<$key> to I<$value>.

=item values

Returns a list of all values.

=back

=cut
