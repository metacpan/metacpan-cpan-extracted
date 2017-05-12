package WWW::Ohloh::API::Message::Tag;

use strict;
use warnings;

use Object::InsideOut qw/
  WWW::Ohloh::API::Role::Fetchable
  WWW::Ohloh::API::Role::LoadXML
  /;

use Carp;
use XML::LibXML;

use List::MoreUtils qw/ any /;

our $VERSION = '0.3.2';

my @type_of : Field : Set(set_type) : Get(type);
my @uri_of : Field : Set(set_uri) : Get(uri);
my @content_of : Field : Set(set_content) : Get(content);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub load_xml {
    my $self = shift;
    my $dom  = shift;

    my $type = $dom->nodeName;
    die "tag is of type $type, should be 'project' or 'account'"
      unless any { $_ eq $type } qw/ project account /;

    $self->set_type($type);
    $self->set_uri( $dom->getAttribute('uri') );
    $self->set_content( $dom->findvalue('text()') );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->dataElement( $self->type, $self->content, uri => $self->uri );

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_project {
    return $_[0]->type eq 'project';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_account {
    return $_[0]->type eq 'account';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'end of WWW::Ohloh::API::Message::Tag';

__END__

=head1 NAME

WWW::Ohloh::API::Message::Tag - a tag associated to an Ohloh message 

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $messages =  $ohloh->fetch_messages( account => $account );

    while ( my $msg = $messages->next ) {
        print $msg->body, "\n";
        for my $tag ( $msg->tags ) {
            print "\t", $tag->content, "\n";
        }
    }

=head1 DESCRIPTION

W::O::A::Message::Tag contains the information of a tag associated with a 
message.

=head1 METHODS 

=head2 API Data Accessors

=head3 type

Returns the tag type, which can be 'account' or 'project'.

=head3 set_type( $type )

Sets the tag type.  Must be either 'account' or 'project'.

=head3 uri

Returns the tag uri.

=head3 set_uri( I<$uri> )

Sets the tag uri.

=head3 content

Returns the content of the tag, which will either be the name of the
tagged project or account.

=head3 set_content( I<$name> )

Sets the content of the tag to I<$name>.


=head2 Other Methods

=head3 as_xml

Returns the tag information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::Message>.

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


