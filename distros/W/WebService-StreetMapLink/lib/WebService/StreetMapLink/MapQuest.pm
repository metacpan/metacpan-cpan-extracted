package WebService::StreetMapLink::MapQuest;

use strict;

use Geography::States;

use base 'WebService::StreetMapLink';
__PACKAGE__->RegisterSubclass();


my %Query = ( usa    => { countryid => 'US',
                          country   => 'US',
                        },
              canada => { countryid => 41,
                          country   => 'CA',
                        },
            );

my @Accents = ( [ qr/[\xE0-\xE2]/ => 'a' ],
                [ qr/[\xE8-\xEA]/ => 'e' ],
                [ qr/\xE7/        => 'c' ],
                [ qr/\xF4/        => 'o' ],
              );

sub Countries { keys %Query }

sub new
{
    my $class = shift;
    my %p = @_;

    local $_;
    # remove accents from state names like Quebec or mapquest gets upset
    for ( grep { defined } values %p )
    {
        foreach my $p (@Accents)
        {
            s/$p->[0]/$p->[1]/g;
        }
    }

    if ( defined $p{state} )
    {
        if ( length $p{state} > 2 )
        {
            $p{state} = Geography::States->new( $p{country} )->state( $p{state} );
        }
    }

    return
        unless ( defined $p{address}
                 &&
                 ( ( defined $p{city} && defined $p{state} )
                   ||
                   defined $p{postal_code}
                 )
               );

    return if $p{address} =~ /p\.?o\.\s+box/i;

    my %query = %{ $Query{ $p{country} } };

    foreach my $k ( qw( address city state ) )
    {
        $query{$k} = $p{$k}
            if defined $p{$k};
    }

    $query{zip} = $p{postal_code}
        if defined $p{postal_code};

    $query{zoom} = $p{zoom} || 8;

    return bless { host  => 'www.mapquest.com',
                   path  => '/maps/map.adp',
                   query => \%query,
                 }, $class;
}


1;

__END__

=head1 NAME

WebService::StreetMapLink::MapQuest - A WebService::StreetMapLink subclass for MapQuest

=head1 SYNOPSIS

    use WebService::StreetMapLink;

    my $map =
        WebService::StreetMapLink->new
            ( country => 'usa',
              address => '100 Some Street',
              city    => 'Testville',
              state   => 'MN',
              postal_code => '12345',
            );

    my $uri = $map->uri;

=head1 DESCRIPTION

This subclass generates links to MapQuest.

=head1 COUNTRIES

This subclass handles USA and Canada.

=head1 new() PARAMETERS

This subclass requires that you provide an "address" parameter.  You
also must require B<either> "city" and "state", or "postal_code".

It also accept an additional parameter, "zoom", which can be a numbe
from 1-9.  This determines the zoom level on the map.  It defaults to
8.

=head1 AUTHOR

David Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-streetmaplink@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2007 David Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut

