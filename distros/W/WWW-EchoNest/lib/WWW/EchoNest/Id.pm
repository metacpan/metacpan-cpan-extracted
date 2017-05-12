
package WWW::EchoNest::Id;

use 5.010;
use strict;
use warnings;
use Carp;
use Memoize;

memoize( qw( is_id ) );

use WWW::EchoNest;
BEGIN {
    our $VERSION     = $WWW::EchoNest::VERSION;
    our @EXPORT      = ();
    our @EXPORT_OK   = qw( is_id );
}
use parent qw( Exporter );



# Typenames that appear in Echonest identifier codes
my %typenames =
    (
     AR => 'artist',
     SO => 'song',
     RE => 'release',
     TR => 'track',
     PE => 'person',
     DE => 'device',
     LI => 'listener',
     ED => 'editor',
     TW => 'tweditor',
     CA => 'catalog',
    );

my $short_type   = join ('|', keys %typenames);
my $long_type    = join ('|', values %typenames);
    
# These regexes need better names!
my %id_regex_for =
    (
     # foreign regex example...
     # musicbrainz:artist:a74b1b7f-71a5-4011-9441-d0b5e4122711
     foreign => qr<
                      \A
                      .+? :             # musicbrainz, 7digital
                      (?:$long_type) :
                      (?:[^^]+) \^?
                      (?:[0-9\.]+)?
                      \z
                  >xms,
	
     # short regex example...
     # ARH6W4X1187B99274F
     short   => qr<
                      \A
                      (?:$short_type)
                      (?:[0-9A-Z]{16})
                      \^? (?:[0-9\.]+)?
                      \z
                  >xms,
	
     # long regex example...
     # music://id.echonest.com/RE/ARH6W4X1187B99274F
     # I just pulled this example out of a hat.
     #
     # [bps 5.28.2011]
     long    => qr<
                      \A
                  music://id\.echonest\.com/
                  .+?/
                  (?:$short_type) /
                  (?:$short_type)
                  [0-9A-Z]{16}
                  \^? (?:[0-9\.]+)?
                  \z
                  >xms,
    );
    
sub is_id {
    my($identifier) = @_;

    return if ! defined($identifier);
    
    for my $id_regex (values %id_regex_for) {
        return 1 if $identifier =~ /$id_regex/;
    }
    
    return;
}

1;

__END__

=head1 NAME

  WWW::EchoNest::Functional
  This module is for internal use only!

=head1 VERSION

Version 0.0.1

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

