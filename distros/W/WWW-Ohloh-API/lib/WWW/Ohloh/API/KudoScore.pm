package WWW::Ohloh::API::KudoScore;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use XML::Writer;

our $VERSION = '0.3.2';

my @xml_of : Field : Arg(xml);

my @creation_time_of : Field : Get(created_at) : Set(_set_created_at);
my @kudo_rank_of : Field : Get(kudo_rank) : Set(_set_kudo_rank);
my @position_of : Field : Get(position) : Set(_set_position);
my @max_position_of : Field : Get(max_position) : Set(_set_max_position);
my @position_delta_of : Field : Get(position_delta) :
  Set(_set_position_delta);

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_created_at( $dom->findvalue('created_at/text()') );
    $self->_set_kudo_rank( $dom->findvalue('kudo_rank/text()') );
    $self->_set_position( $dom->findvalue('position/text()') );
    $self->_set_max_position( $dom->findvalue('max_position/text()') );
    $self->_set_position_delta( $dom->findvalue('position_delta/text()') );
}

# aliases
*rank = *kudo_rank;

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('kudo_score');
    $w->dataElement( 'created_at',     $self->created_at );
    $w->dataElement( 'kudo_rank',      $self->kudo_rank );
    $w->dataElement( 'position',       $self->position );
    $w->dataElement( 'max_position',   $self->max_position );
    $w->dataElement( 'position_delta', $self->position_delta );
    $w->endTag;

    return $xml;
}

'end of WWW::Ohloh::API::KudoScore';
__END__


=head1 NAME

WWW::Ohloh::API::KudoScore - an Ohloh kudo score

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $account $ohloh->get_account( id => 12933 );
    my $kudo = $account->kudo_score;

    print $kudo->rank;

=head1 DESCRIPTION

W::O::A::KudoScore contains the kudo information associated with an Ohloh 
account as defined at http://www.ohloh.net/api/reference/kudo_score. 
To be properly populated, it must be retrieved via
the C<kudo_score> method of a L<WWW::Ohloh::API::Account> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 created_at

Return the time at which this KudoScore was calculated.

=head3 rank, kudo_rank

Return the KudoRank, which is an integer from 1 to 10.

=head3 position

Return an integer which orders all participants. 
The person with `position` equals 1 is the highest-ranked person on Ohloh.

=head3 max_position

Return the total number of partcipants in the most recent KudoScore calculations. The person whose `position` equals `max_position` is the lowest-ranked person on Ohloh.


=head3 position_delta

Return the change in this person's position since the previous kudo score calculations. Here, a negative number represents an improvement, since lower positions are better.

=head2 Other Methods

=head3 as_xml

Return the kudo information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server: due to the current XML parsing module used
by W::O::A (to wit: L<XML::Simple>), the ordering of the nodes can differ.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, L<WWW::Ohloh::API::KudoScore>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/kudo_score

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

The C<as_xml()> method returns a re-encoding of the account data, which
can differ of the original xml document sent by the Ohloh server.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

