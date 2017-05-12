package WebService::Amazon::DynamoDB::Server::Item;
$WebService::Amazon::DynamoDB::Server::Item::VERSION = '0.001';
use strict;
use warnings;

use Future;
use Encode;
use List::Util qw(sum);

=pod

Attributes are each stored twice:

 attributes => [...]
 attribute_by_key => { ... }

An attribute is stored as a hashref:

 {
  key => 'attribute_name',
  type => S|SS|N|B|NULL|BOOL|M|L,
  value => '...'
 }

=cut

=head2 new

Instantiate.

=over 4

=item * attributes - arrayref of attributes

=back

=cut

sub new {
	my $class = shift;
	bless {@_}, $class
}

=head2 each_attribute

Iterates through each attribute on this item.

=cut

sub each_attribute {
	my ($self, $code) = @_;
	my $f = Future->new;
	$code->($_) for @{$self->{attributes}};
	$f->done
}

=head2 bytes_used

Resolves to the total number of bytes used by this item.

=cut

sub bytes_used {
	my ($self) = @_;
	$self->{bytes_used} //= do {
		my $total = 0;
		for my $attr (@{$self->{attributes}}) {
			$total += length Encode::encode('UTF-8', $attr->{key});
			$total += $self->bytes_for($attr->{type}, $attr->{value});
		}
		Future->done($total)
	}
}

=head2 bytes_for

Calculates how many bytes are used for the given type and value. Used for
recursive size calculations (map/list etc.).

Returns an immediate value.

=cut

sub bytes_for {
	my ($self, $type, $v) = @_;
	die 'no type' unless defined $type;
	my $total = 0;
	if($type eq 'S') { # String
		$total += length Encode::encode('UTF-8', $v);
	} elsif($type eq 'N') { # String
		$total += length $v;
	} elsif($type eq 'B') { # Binary
		$total += length $v;
	} elsif($type eq 'BOOL') { # Boolean
		++$total
	} elsif($type eq 'NULL') { # Null
		++$total
	} elsif($type eq 'SS') { # String set
		$total += 3;
		$total += length Encode::encode('UTF-8', $_) for @$v;
	} elsif($type eq 'NS') { # Number set
		$total += 3;
		$total += length Encode::encode('UTF-8', $_) for @$v;
	} elsif($type eq 'BS') { # Blob set
		$total += 3;
		$total += length $_ for @$v;
	} elsif($type eq 'M') { # Map
		# x => { key => 'x', value => 'y', type => 'z' }
		$total += 3;
		for my $attr (values %$v) {
			$total += length Encode::encode('UTF-8', $attr->{key});
			$total += $self->bytes_for($attr->{type}, $attr->{value});
		}
	} elsif($type eq 'L') { # List
		# x => { key => 'x', value => 'y', type => 'z' }
		$total += 3;
		for my $attr (@$v) {
			$total += length Encode::encode('UTF-8', $attr->{key});
			$total += $self->bytes_for($attr->{type}, $attr->{value});
		}
	} else {
		die 'invalid - ' . $type;
	}
	$total
}

=head2 attribute_by_key

Returns the given attribute via key lookup.

=cut

sub attribute_by_key {
	my ($self, $k) = @_;
	unless($self->{attribute_by_key}) {
		$self->{attribute_by_key}{$_->{key}} = $_ for @{$self->{attributes}};
	}
	$self->{attribute_by_key}{$k}
}

1;

