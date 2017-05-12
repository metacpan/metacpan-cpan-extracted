
package WWW::EchoNest::TrackProxy;

BEGIN {
    our @EXPORT    = qw(  );
    our @EXPORT_OK = qw(  );
}
use parent qw( WWW::EchoNest::Proxy Exporter );

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw( first );

use WWW::EchoNest;
BEGIN { our $VERSION = $WWW::EchoNest::VERSION; }

use WWW::EchoNest::Util  qw( call_api );



# You should not call this constructor directly, rather use the
# convenience functions that are in WWW::EchoNest::Track.
# For example, call track.track_from_filename.
# Let's always get the bucket 'audio_summary'.
sub new {
    my($class, $args_ref, %args)      = @_;
    $args_ref->{object}               = 'track';

    my $instance = $class->SUPER::new( $args_ref );
    $instance->{$_} = $args{$_} for (keys %args);
    return $instance;
}

sub get_attribute {
    my($self, $args_ref) = @_;
    return $self->SUPER::get_attribute( $args_ref);
}

sub post_attribute {
    use Params::Check qw( check allow );
    my($self, $args_hash_ref) = @_;
    my $template =
        {
         post => { default => 1 },
         method  => { required => 1, defined => 1 },
        };
    
    my $parsed_args_ref = check( $template, $args_hash_ref )
        or croak 'Could not parse arguments';
    
    my $result = call_api($parsed_args_ref);
    return $result->{'response'};
}



1;

__END__



=head1 NAME

WWW::EchoNest::TrackProxy
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
