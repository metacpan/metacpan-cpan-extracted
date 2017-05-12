package WWW::Ohloh::API::Message;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;

use WWW::Ohloh::API::Message::Tag;

our $VERSION = '0.3.2';

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @ohloh_of : Field : Arg(ohloh);

my @api_fields = qw/ id account avatar created_at body /;

my @id_of : Field : Set(_set_id) : Get(id);
my @account_of : Field : Set(_set_account) : Get(account);
my @avatar_of : Field : Set(_set_avatar) : Get(avatar);
my @creation_time_of : Field : Set(_set_creation_time) : Get(creation_time);
my @body_of : Field : Set(_set_body) : Get(body);
my @tags_of : Field;

my %init_args : InitArgs = ( 'xml' => '', );

sub _init : Init {
    my ( $self, $args ) = @_;

    $self->load_xml( $args->{xml} ) if $args->{xml};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub load_xml {
    my $self = shift;
    my $dom  = shift;

    $self->_set_id( $dom->findvalue("id/text()") );
    $self->_set_account( $dom->findvalue("account/text()") );
    $self->_set_avatar( $dom->findvalue('avatar/@uri') );
    $self->_set_creation_time( $dom->findvalue("created_at/text()") );
    $self->_set_body( $dom->findvalue("body/text()") );

    for ( $dom->findnodes('tags/*') ) {
        $self->insert_tag(
            WWW::Ohloh::API::Message::Tag->new(
                ohloh => $ohloh_of[$$self],
                xml   => $_,
            ) );
    }

}

sub tags {
    my $self = shift;
    return $tags_of[$$self] ? @{ $tags_of[$$self] } : ();
}

sub insert_tag {
    my $self = shift;
    push @{ $tags_of[$$self] }, @_;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('language');

    for my $e (@api_fields) {
        $w->dataElement( $e => $self->$e );
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_code {
    my $self = shift;

    return $self->category eq 'code';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_markup {
    my $self = shift;

    return $self->category eq 'markup';
}

'end of WWW::Ohloh::API::Language';

__END__

=head1 NAME

WWW::Ohloh::API::Message - a Ohloh message

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $messages =  $ohloh->fetch_messages( account => $id );

    while( my $msg = $messages->next ) {
        print $msg->body, "\n";
    }


=head1 DESCRIPTION

W::O::A::Message contains the information associated with an Ohloh message.

=head1 METHODS 

=head2 API Data Accessors

=head3 id

Returns the message's id.

=head3 account

Returns the author of the message (as a string). 

=head3 avatar

Returns (if available) the url pointing to the message author's avatar.

=head3 creation_time

Returns the time at which the message has been written.

=head3 body

Returns the body of the message.

=head3 tags

Returns the tags associated to the message as an array of
L<WWW::Ohloh::API::Message::Tag> objects.

=head2 Other Methods

=head3 as_xml

Return the message's information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::Messages>,
L<WWW::Ohloh::API::Message::Tag>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/message

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

=cut

