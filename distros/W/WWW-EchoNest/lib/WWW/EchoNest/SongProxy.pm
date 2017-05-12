
package WWW::EchoNest::SongProxy;

BEGIN {
    our @EXPORT    = ();
    our @EXPORT_OK = ();
}
use parent qw{ WWW::EchoNest::Proxy Exporter };

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw( first );

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

use WWW::EchoNest::Id qw( is_id );
use WWW::EchoNest::Functional qw( update all );
use WWW::EchoNest::Util qw(  );


sub new {
    my($class, $args_ref)   = @_;
    my $object_type         = 'song';  # For the web API
    
    my $id      = $args_ref->{id};
    my $buckets = $args_ref->{buckets};

    croak 'Invalid id' if defined($id) && (! is_id($id));

    # Create the new instance
    $args_ref->{object}  = $object_type;
    my $instance         = $class->SUPER::new( $args_ref );
    
    my @core_attrs     = qw( title artist_name artist_id );
    my %arg_map        = map { $_ => 1 } (keys %$args_ref);
    my @provided_attrs = @arg_map{ @core_attrs };
    
    # Get the profile if any of the core_attrs were left out
    if (! all(@provided_attrs)) {
    	my $profile =
            $instance->SUPER::get_attribute(
                                            {
                                             method => 'profile',
                                             id     => $id,
                                             bucket => $buckets,
                                            }
                                           );
    	my $song_info_ref = $profile->{'songs'}[0];

        for my $k (keys %$song_info_ref) {
            $instance->{$k} = $song_info_ref->{$k};
        }
    }
    
    return $instance;
}

sub get_attribute {
    my $self        = $_[0];
    my $args_ref    = $_[1];
    $args_ref->{id} = $self->{id};
    
    return $self->SUPER::get_attribute( $args_ref );
}

1;

__END__



=head1 NAME

WWW::EchoNest::SongProxy
For internal use only!

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
