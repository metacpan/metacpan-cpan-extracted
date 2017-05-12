package WWW::Ohloh::API::Kudos;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/ any /;
use WWW::Ohloh::API::Kudo;

our $VERSION = '0.3.2';

my @ohloh_of : Field : Arg(ohloh);
my @account_id_of : Field : Arg(id) : Get(_id);
my @sent_kudos_of : Field;
my @received_kudos_of : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('kudos');

    if ( my @k = @{ $sent_kudos_of[$$self] } ) {
        $w->startTag('kudos_sent');
        $xml .= $_->as_xml for @k;
        $w->endTag;
    }

    if ( my @k = @{ $received_kudos_of[$$self] } ) {
        $w->startTag('kudos_received');
        $xml .= $_->as_xml for @k;
        $w->endTag;
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub all {
    my $self = shift;

    my %kudos;

    $kudos{received} = [ $self->received ];
    $kudos{sent}     = [ $self->sent ];

    return %kudos;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub received {
    my $self = shift;

    unless ( $received_kudos_of[$$self] ) {
        my ( $url, $xml ) =
          $ohloh_of[$$self]
          ->_query_server( 'accounts/' . $self->_id . '/kudos.xml' );

        my @kudos;
        for my $n ( $xml->findnodes('kudo') ) {
            push @kudos,
              WWW::Ohloh::API::Kudo->new(
                ohloh => $ohloh_of[$$self],
                xml   => $n,
              );
        }
        $received_kudos_of[$$self] = \@kudos;
    }

    return @{ $received_kudos_of[$$self] };
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub sent {
    my $self = shift;

    unless ( $sent_kudos_of[$$self] ) {
        my ( $url, $xml ) =
          $ohloh_of[$$self]
          ->_query_server( 'accounts/' . $self->_id . '/kudos/sent.xml' );

        my @kudos;
        for my $n ( $xml->findnodes('kudo') ) {
            push @kudos,
              WWW::Ohloh::API::Kudo->new(
                ohloh => $ohloh_of[$$self],
                xml   => $n,
              );
        }
        $sent_kudos_of[$$self] = \@kudos;
    }

    return @{ $sent_kudos_of[$$self] };
}

'end of WWW::Ohloh::API::Kudos';
__END__

=head1 NAME

WWW::Ohloh::API::Kudos - Ohloh kudos sent and received by an account

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $kudos = $ohloh->get_kudos( id => $account_id );

    my @received = $kudos->received;
    my @sent     = $kudos->sent;

=head1 DESCRIPTION

W::O::A::Kudos returns the kudos received and given by
an Ohloh account.
To be properly populated, it must be created via
the C<get_kudos> method of a L<WWW::Ohloh::API> object. 

=head1 METHODS 

=head2 all

Return the retrieved languages' information as
L<WWW::Ohloh::API::Kudos> objects.

=head3 as_xml

Return the kudos  as an XML string.  
Note that this is not the same xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::Kudo>, 
L<WWW::Ohloh::API::Language>, 
L<WWW::Ohloh::API::Project>,
L<WWW::Ohloh::API::Analysis>, 
L<WWW::Ohloh::API::Account>.


=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/kudo

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
