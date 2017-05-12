
package WWW::EchoNest::PlaylistProxy;

BEGIN {
    our @EXPORT       = ();
    our @EXPORT_OK    = ();
}
use parent qw[ WWW::EchoNest::Proxy Exporter ];

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw( first );

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

use WWW::EchoNest::Util qw();
use WWW::EchoNest::Functional qw(
                                    all
                                    update
                                    make_stupid_accessor
                               );

sub new {
    my($class, $args_ref) = @_;

    # Create the new instance
    $args_ref->{object} = 'playlist';
    my $instance = $class->SUPER::new( $args_ref );

    my @core_attrs = qw( session_id );
    my %args = map { $_ => 1 } (keys %{ $args_ref });
    my @provided_attrs = @args{ @core_attrs };
    
    # Get the profile if any of the core_attrs were left out
    if (! all( @provided_attrs )) {
    	my $profile = $instance->get_attribute( { method => 'dynamic' } );
        update( $args_ref, $profile );
    }
    $instance->{$_} = $args_ref->{$_} for (keys %$args_ref);
    return $instance;
}

make_stupid_accessor( qw[ session_id ] );

sub get_attribute {
    my($self, $args_ref) = @_;
    return $self->SUPER::get_attribute( $self->_get_request_for($args_ref) );
}

# Argument-processing functions for use with 'get_attribute'
#
# Each of the playlist method requires certain parameters to be present for
# the Web API request. I use a hash of subroutine refs to handle the argument
# processing for each method.
# Each arg-processing subroutine will be passed the playlist instance and
# the args HASH-ref that get_attribute was passed.
my $playlist_creation = sub {
    my($self, $args_ref) = @_;
    my $request_ref =
        {
         method => $args_ref->{'method'},
         type => $self->{'type'},
        };
        
    my @need_one_of =
        (
         'artist',
         'artist_id',
         'song_id',
         'style',
         'mood',
         'description',
         'seed_catalog',
         'source_catalog',
        );
    for (@need_one_of) {
        my $val = $self->{$_};
        $request_ref->{$_} = $val if defined($val);
    }
    return $request_ref;
};

my $playlist_info = sub {
    my($self, $args_ref) = @_;
    my $request_ref =
        {
         method         => $args_ref->{method},
         session_id     => $self->get_session_id(),
        };
    return $request_ref;
};
    
my %make_args_for =
    (
     static          => $playlist_creation,
     dynamic         => $playlist_creation,
     session_info    => $playlist_info,
    );
    
sub _get_request_for {
    # First arguement should be a hash ref
    my($self, $args_ref) = @_;
    my $method = $args_ref->{method};
    return $make_args_for{$method}->($self, $args_ref);
}

1;

__END__

=head1 NAME

WWW::EchoNest::PlaylistProxy
For internal use only!

=head1 METHODS

=head2 new

  Returns a new WWW::EchoNest::PlaylistProxy instance.

  ARGUMENTS:
    object         => the type of object this proxy will be acting on behalf of

  RETURNS:
    A new WWW::EchoNest::PlaylistProxy instance.
  
  EXAMPLE:
    # Insert helpful example here!

=head2 get_attribute

  Calls the Web API with an HTTP GET Request
  on behalf of an object.

  ARGUMENTS:
    method     => A string of the form <object_type>/<method_name>.
                  e.g. - 'song/search'

  RETURNS:
    A hash ref containing the information sent back
    from The Echo Nest.
  
  EXAMPLE:
    # Insert helpful example here!

=head2 post_attribute

  Calls the Web API with an HTTP POST Request
  on behalf of an object.

  ARGUMENTS:
    method     => A string of the form <object_type>/<method_name>.
                  e.g. - 'song/search'

  RETURNS:
    A hash ref containing the information sent back
    from The Echo Nest.
  
  EXAMPLE:
    # Insert helpful example here!

=head2 get_id

  Get an Artist's id.

  ARGUMENTS:
    none

  RETURNS:
    A string representing the artist's id.
  
  EXAMPLE:
    # Insert helpful example here!

=head2 get_name

  Get an Artist's name.

  ARGUMENTS:
    none

  RETURNS:
    A string representing the artist's name.
  
  EXAMPLE:
    # Insert helpful example here!



=head1 FUNCTIONS



=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-echonest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW::EchoNest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
