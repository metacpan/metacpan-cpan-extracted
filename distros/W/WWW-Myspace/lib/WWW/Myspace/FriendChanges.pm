package WWW::Myspace::FriendChanges;

use warnings;
use strict;
use Carp;
use File::Spec::Functions;

=head1 NAME

WWW::Myspace::FriendChanges - Track additions/deletions to your friends list

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Returns a list of friends that have been added or deleted since the last
run.

	use WWW::Myspace;
    use WWW::Myspace::FriendChanges;

	my $myspace = new WWW::Myspace;

    my $foo = WWW::Myspace::FriendChanges->new( $myspace );

	OR
	
	my $foo = WWW::Myspace::FriendChanges->new( $myspace, $cache_file )

	# Get the list of deleted friends.
	@deleted_friends = $foo->deleted_friends;
	
	# Get the list of new friends
	@added_friends = $foo->added_friends;
	
	# Write the current friend list into the cache file.
	$foo->write_cache;

=head1 METHODS

=head2 new

The new method requires 1 argument (a WWW::Myspace object), and takes an
optional second argument, a filename for the cache file. The cache file
defaults to "friendcache" in the WWW::Myspace cache_dir. You can set it
using the "new" method or using the "cache_file" method.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
 	my $self  = {};
	bless ($self, $class);
 	$self->{myspace} = shift if @_;
 	$self->{cache_file} = shift if @_;
	return $self;
}

# _last_friends
# Internal method that reads the cache file into an internal hash.
# Sets $self->{last_friends} to a reference to a hash, the keys of which
# are friendIDs.
sub _last_friends {
	my $self = shift;
	
	my %last_friends = ();

	if ( -f $self->cache_file ) {
		open( CACHE, "<", $self->cache_file ) or croak "Can't open cache file.\n";
	} else {
		$self->{last_friends} = {};
		return;
	}
	
	foreach my $id ( <CACHE> ) {
		chomp $id;
		$last_friends{"$id"}++;
	}
	
	close CACHE;
	
	$self->{last_friends} = \%last_friends;

}

# _current_friends
# Internal convenience method to set the list of current friends.
# Sets $self->{current_friends} to a reference to a hash, the keys
# of which are friendIDs. (This makes comparisons easy and fast).
sub _current_friends {
	my $self = shift;

	my %friends = ();

	my @friends = $self->{myspace}->get_friends;
	die $self->{myspace}->error . "\n" if ( $self->{myspace}->error );

	foreach my $id ( @friends ) {
		$friends{"$id"}++;
	}

	$self->{current_friends} = \%friends;
}

=head2 set_cache_file( filename )

Sets the cache file.  You should use "cache_file" instead. This method
is only for backwards compatibility.

=cut

sub set_cache_file {
	my $self = shift;

	$self->cache_file( @_ );

}

=head2 cache_file

Sets or returns the current cache filename.

	my $cache_file = $friend_changes->cache_file;

	print $cache_file;

"filename" is used as the file from/to which we read/write the list
of friends. Setting the cache filename also clears the internal
last_friends list.

=cut

sub cache_file {
	my $self = shift;

	if ( @_ ) {
		$self->{cache_file} = shift;
		# Clear out the last_friends list
		$self->{last_friends} = undef;
	} elsif (! defined $self->{cache_file} ) {
		# Make the cache dir if it doesn't exist.
		$self->{myspace}->make_cache_dir;
		$self->{cache_file} = catfile( $self->{myspace}->cache_dir,
			'friend_cache' );
	}

	return $self->{cache_file};

}

=head2 write_cache

Writes out the current list of friends to the cache file.

=cut

sub write_cache {

	my $self = shift;

	open( CACHE, ">", $self->cache_file ) or croak "Can't open cache file.\n";
	
	foreach my $id ( keys( %{ $self->{current_friends} } ) ) {
		print CACHE "$id\n";
	}
	
	close CACHE;

}

=head2 deleted_friends

Returns a list of the IDs of friends that have
disappeared since the last cache list was saved. The first time it's called
it searches the friends lists and caches the list of deleted friends
within the object data.

	Usage:
	
	use WWW::Myspace;
	use WWW::Myspace::FriendChanges;
	
	my $myspace = new WWW::Myspace;
	my $friend_changes = new FriendChanges( $myspace );

	my @deleted_friends = $friend_changes->deleted_friends;

=cut

sub deleted_friends {

	my $self = shift;

	my @deleted_friends = ();

	# Loop through the list of friends loaded from the cache file.
	# If theyre in that list, but not the current list, they deleted
	# themselves.
	unless ( defined $self->{deleted_friends} ) {
	
		unless ( defined $self->{last_friends} ) { $self->_last_friends }
		unless ( defined $self->{current_friends} ) { $self->_current_friends }
		
		# If they're in last_friends, but not in current friends, they deleted us.
		foreach my $id ( keys( %{ $self->{last_friends} } ) ) {
			unless ( ${ $self->{current_friends} }{"$id"} ) {
				push( @deleted_friends, $id );
			}
		}
		
		$self->{deleted_friends} = \@deleted_friends;
	}
	
	return ( @{ $self->{deleted_friends} } );
	
}

=head2 added_friends

Returns a list of the IDs of friends that have been
added since the last cache list was saved.

=cut

sub added_friends {
	my $self = shift;

	my @added_friends = ();
	
	# Loop through the list of current friends. If the friend is in
	# the current list but not the last list, they're a new add.
	unless ( defined $self->{added_friends} ) {
	
		unless ( defined $self->{last_friends} ) { $self->_last_friends }
		unless ( defined $self->{current_friends} ) { $self->_current_friends }

		# If they're in last_friends, but not in current friends, they deleted us.
		foreach my $id ( keys( %{ $self->{current_friends} } ) ) {
			unless ( ${ $self->{last_friends} }{"$id"} ) {
				push( @added_friends, $id );
			}
		}
		
		$self->{added_friends} = \@added_friends;
	}
	
	return ( @{ $self->{added_friends} } );

}

=head1 AUTHOR

Grant Grueninger, C<< <grant at cscorp.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-myspace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myspace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myspace::FriendChanges

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Myspace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Myspace>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Myspace>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Myspace>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Myspace::FriendChanges
