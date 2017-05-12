
#
# Strangely enough, the CLEAR method does not actually cause a subsequent
# FIRSTKEY to return nil.
#

package Tie::HashDefaults;

	use Carp;
	use strict;
	use vars qw( $VERSION );
	$VERSION = '0.01';


	sub TIEHASH {
		my $pkg = shift;
		my %values;
		my @defaults;

		if ( @_ == 1 && UNIVERSAL::isa($_[0],'Tie::HashDefaults') ) {
			# copy constructor
			@defaults = $_[0]->get_defaults_list;
			%values = %{ $_[0][1] };
		}
		else {
			# plain list of default sources (hashrefs)
			@defaults = map {
				is_hashref($_) or croak <<EOF;
Bad arg: '$_'\n\tExpected another Tie::HashDefaults (ref), or a list of default sources (hashrefs).
EOF
				$_
			} @_;
		}

		bless( [ undef, \%values, \@defaults ], $pkg );
	}

			sub is_hashref {
				local $_ = '' . shift;
				s/.*=//;
				/^HASH\(/
			}

	sub get_defaults_list {
		my $self = shift;
		$self->_delete_iteration_hash;
		$self->[2];
	}

	sub _get_sources_list {
		my $self = shift;
		my $deflist = $self->get_defaults_list;
		( $self->[1], @$deflist )
	}

	sub _delete_iteration_hash {
		my $self = shift;
		$self->[0] = undef;
	}

	sub EXISTS {
		my( $self, $key ) = @_;
		for ( $self->_get_sources_list ) {
			exists $_->{$key} and return(1);
		}
		return(); # not found
	}

	sub FETCH {
		my( $self, $key ) = @_;
		for ( $self->_get_sources_list ) {
			exists $_->{$key} and return( $_->{$key} );
		}
		return(); # not found
	}

	sub DELETE {
		my( $self, $key ) = @_;
		$self->_delete_iteration_hash;
		delete $self->[1]{$key};
	}

	sub STORE {
		my( $self, $key, $val ) = @_;
		$self->_delete_iteration_hash;
		$self->[1]{$key} = $val;
	}

	sub CLEAR {
		my( $self ) = @_;
		$self->_delete_iteration_hash;
		%{ $self->[1] } = ();
		$self
	}

	sub FIRSTKEY {
		my( $self ) = @_;
		$self->_delete_iteration_hash;
		my %iter;
		for ( reverse $self->_get_sources_list ) {
			while ( my($k,$v) = each %$_ ) {
				$iter{$k} = $v;
			}
		}
		$self->[0] = \%iter;
		each %{$self->[0]} 
	}

	sub NEXTKEY {
		my( $self ) = @_;
		each %{$self->[0]} 
	}

1;

__END__


=head1 NAME

Tie::HashDefaults - Let a hash have default values

=head1 SYNOPSIS

  use Tie::HashDefaults;

  tie %h, 'Tie::HashDefaults', \%defaults1, \%defaults0;

=head1 DESCRIPTION

This creates a data structure which is essentially an
array of hashes; this list contains all the hashes (passed
by ref) in the argument list; but it also contains
a new, internally created, anonymous hash.  This hash
is used to store any insertions into the tied hash.

Whenever a fetch (or an exists) is done on the tied hash, the
requested key is searched for in each hash in the list, beginning
with the internal "storage" hash; if it is not found in that hash,
the key is looked for in the first default hash, then the next,
and so on, until it is found in one of them, or there are
none left to search.

When an iteration (keys or each) is done on the tied hash, the
set of keys returned is the union of keys from all of the default
hashes, along with the storage hash.

For operations that alter a hash -- store, delete, clear --
the default hashes are never touched.  Only the storage hash
is cleared.  One effect of this is that if the tied hash is
cleared, e.g. via C<%h = ();>, and immediately following that
an iteration is started (via keys or each), it is likely that
some keys will be returned.  (Unless, of course, there is
no data in B<any> of the given default hashes.)

=head2 Manipulating the Defaults List

The list of default hashes can be manipulated directly.
To do this, a special method on the tied object returns an
array, by reference, containing the list of default hashes. 
Any changes to this array are reflected inside the
Tie::HashDefaults object.  For example, to add another
defaults source that takes precedence over the others already
on the list:

  unshift @{ tied(%h)->get_defaults_list }, \%new_default_source;

Or, to reverse the order in which the defaults are consulted:

  $ar = tied(%h)->get_defaults_list;
  @$ar = reverse @$ar;

(Once you have the array-ref "handle" on the defaults list
array, it's good for as long as the tied object stays tied.)

NOTE: calling C<get_defaults_list> also resets the iterator;
so don't call it within an C<each> loop on a hash tied to this
class.

=head1 AUTHOR

jdporter@min.net (John Porter)

=head1 COPYRIGHT

This is free software.  This software may be modified and
distributed under the same terms as Perl itself.


=cut

