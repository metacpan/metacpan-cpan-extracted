package WWW::Ohloh::API::Kudo;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use WWW::Ohloh::API::KudoScore;

our $VERSION = '0.3.2';

my @api_fields = qw/
  created_at
  sender_account_id
  sender_account_name
  receiver_account_name
  receiver_account_id
  project_id
  project_name
  contributor_id
  contributor_name
  /;

my @created_at_of : Field : Set(_set_created_at) : Get(created_at);
my @sender_account_id_of : Field : Set(_set_sender_account_id) :
  Get(sender_account_id);
my @sender_account_name_of : Field : Set(_set_sender_account_name) :
  Get(sender_account_name);
my @receiver_account_name_of : Field : Set(_set_receiver_account_name) :
  Get(receiver_account_name);
my @receiver_account_id_of : Field : Set(_set_receiver_account_id) :
  Get(receiver_account_id);
my @project_id_of : Field : Set(_set_project_id) : Get(project_id);
my @project_name_of : Field : Set(_set_project_name) : Get(project_name);
my @contributor_id_of : Field : Set(_set_contributor_id) :
  Get(contributor_id);
my @contributor_name_of : Field : Set(_set_contributor_name) :
  Get(contributor_name);

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);
my @ohloh_of : Field : Arg(ohloh) : Get(_ohloh);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_created_at( $dom->findvalue("created_at/text()") );
    $self->_set_sender_account_id(
        $dom->findvalue("sender_account_id/text()") );
    $self->_set_sender_account_name(
        $dom->findvalue("sender_account_name/text()") );
    $self->_set_receiver_account_name(
        $dom->findvalue("receiver_account_name/text()") );
    $self->_set_receiver_account_id(
        $dom->findvalue("receiver_account_id/text()") );
    $self->_set_project_id( $dom->findvalue("project_id/text()") );
    $self->_set_project_name( $dom->findvalue("project_name/text()") );
    $self->_set_contributor_id( $dom->findvalue("contributor_id/text()") );
    $self->_set_contributor_name(
        $dom->findvalue("contributor_name/text()") );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub recipient_type {
    my $self = shift;

    return $self->receiver_account_id ? 'account' : 'contributor';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub sender {
    my $self = shift;

    return $self->_ohloh->get_account( id => $self->sender_account_id );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub receiver {
    my $self = shift;

    if ( my $id = $self->receiver_account_id ) {
        return $self->_ohloh->get_account( id => $id );
    }

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('kudo');
    for my $e (@api_fields) {
        $w->dataElement( $e => $self->$e ) if $self->$e;
    }

    $w->endTag;

    return $xml;
}

'end of WWW::Ohloh::API::Kudo';
__END__

=head1 NAME

WWW::Ohloh::API::Kudo - an Ohloh kudo

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh    = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $account  = $ohloh->get_account( id => 12933 );
    my @received = $account->received_kudos;

    # or, from $ohloh directly
    my @sent = $ohloh->get_kudos( id => 12933 )->sent;

=head1 DESCRIPTION

W::O::A::Kudo contains the information associated with an Ohloh 
kudo as defined at http://www.ohloh.net/api/reference/kudo. 
To be properly populated, it must be created via
the C<get_kudos> method of a L<WWW::Ohloh::API> object,
or via the C<received_kudos>/C<sent_kudos> methods of a 
L<WWW::Ohloh::API::Account> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 created_at

Return the kudo's creation time.

=head3 sender_account_id, sender_account_name

Return the id/name of the account sending the kudo.

=head3 receiver_account_id, receiver_account_name

Return the id/name associated with the account that received
the kudo, or an empty string if the kudo couldn't be linked
to an account.

=head3 project_id, project_name

Return the project id/name if the kudo was sent to a project 
contributor instead than an account, or an empty string otherwise.

=head3 contributor_id, contributor_name

Return the cotnributor's id/name if the kudo was sent to a project 
contributor instead than an account, or an empty string otherwise.

=head2 Other Methods

=head3 as_xml

Return the kudo information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::Kudos>,
L<WWW::Ohloh::API::KudoScore>.

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

