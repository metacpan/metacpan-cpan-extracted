package WebService::StreetMapLink::Google;

use strict;

use Geography::States;

use base 'WebService::StreetMapLink';
__PACKAGE__->RegisterSubclass(99);


my @Accents = ( [ qr/[\xE0-\xE2]/ => 'a' ],
                [ qr/[\xE8-\xEA]/ => 'e' ],
                [ qr/\xE7/        => 'c' ],
                [ qr/\xF4/        => 'o' ],
              );

sub Countries
{
    return ( qw( australia austria belgium
                 canada denmark
                 france germany hungary
                 italy netherlands
                 singapore spain
                 sweden switzerland
                 uk usa
              ),
             'czech republic',
             'puerto rico'
           );
}

sub Priority { 99 }

sub new
{
    my $class = shift;
    my %p = @_;

    local $_;
    # remove accents from state names like Quebec or google gets upset
    for ( grep { defined } values %p )
    {
        foreach my $p (@Accents)
        {
            s/$p->[0]/$p->[1]/g;
        }
    }

    return
        unless ( defined $p{address}
                 &&
                 ( ( defined $p{city}
                     && ( defined $p{state} || $p{country} ne 'usa' )
                   )
                   ||
                   defined $p{postal_code}
                 )
               );

    return if $p{address} =~ /p\.?o\.\s+box/i;

    $p{postal_code} =~ s/-\d{4}$//
        if defined $p{postal_code};

    my $q =
        ( join ',',
          grep { defined }
          map { $p{$_} } qw( address city state postal_code country )
        );

    return bless { host  => 'maps.google.com',
                   path  => '/maps',
                   query => { q => $q }
                 }, $class;
}

sub service_name { 'Google Maps' }


1;

__END__

=head1 NAME

WebService::StreetMapLink::Google - A WebService::StreetMapLink subclass for Google Maps

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

This subclass generates links to Google Maps.

=head1 COUNTRIES

This subclass handles the USA and UK.  It's priority (99), is higher
than the MapQuest subclass, so it is preferred for addresses in the
USA.  For the UK, the country should be given as "uk" or "united
kingdom".

=head1 new() PARAMETERS

This subclass requires that you provide an "address" parameter.  You
also must require B<either> "city" and "state", or "postal_code".

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

