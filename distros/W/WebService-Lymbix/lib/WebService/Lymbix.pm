package WebService::Lymbix;

use strict;
use warnings;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

use Carp;
use Encode;
use Mouse;
use Mouse::Util::TypeConstraints;
use LWP::UserAgent;
use HTTP::Request;

=head1 NAME

WebService::Lymbix - API wrapper of Lymbix.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

An API wrapper of Lymbix. See L<http://lymbix.com> for more details.

Perhaps a little code snippet.

    use WebService::Lymbix;

    my $auth_key = '<YOURAUTHKEY>';
    my $lymbix = WebService::Lymbix->new($auth_key);
    print $lymbix->tonalize("if you had to launch your business in two weeks, what would you cut")
    ...

=head1 ATTRIBUTES

=head2 api_url

=head2 auth_key

=head2 accept_type

=head2 api_version

=cut

has api_url => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://api.lymbix.com'
);
has auth_key => ( is => 'rw', isa => 'Str', required => 1 );

enum 'AcceptType' => qw(application/json application/xml);
has accept_type   => (
    is      => 'rw',
    isa     => 'AcceptType',
    default => 'application/json',
);

has api_version => ( is => 'rw', isa => 'Str', default => '2.2' );

has ua  => ( is => 'rw', isa => 'LWP::UserAgent' );
has req => ( is => 'rw', isa => 'HTTP::Request' );

has tonalize_uri          => ( is => 'ro', default => '/tonalize' );
has tonalize_detailed_uri => ( is => 'ro', default => '/tonalize_detailed' );
has tonalize_multiple_uri => ( is => 'ro', default => '/tonalize_multiple' );
has flag_response_uri     => ( is => 'ro', default => '/flag_response' );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( auth_key => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;

    $self->ua( LWP::UserAgent->new );
    $self->req( HTTP::Request->new('POST') );
    $self->req->header( AUTHENTICATION => $self->auth_key );
    $self->req->header( ACCEPT         => $self->accept_type );
    $self->req->header( VERSION        => $self->api_version );
}

=head1 METHODS

=head2 tonalize(article, [return_fields, accept_type, article_reference_id])

The tonalize method provides article-level Lymbix sentiment data for a single article.

=cut

sub tonalize {
    my $self = shift;

    my $article       = shift;
    my $return_fields = shift || ' ';    # CSV format
    my $reference_id  = shift || '';

    my $content = qq(article=$article);
    $content .= qq(&return_fields=[$return_fields]);
    $content .= qq(&reference_id=$reference_id);

    return $self->_request( $content, $self->tonalize_uri );
}

=head2 tonalize_detailed(article, [return_fields, accept_type, article_reference_id])

The tonalize_detailed method provides article-level Lymbix sentiment data along with a sentence by sentence sentiment data for a single article.

=cut

sub tonalize_detailed {
    my $self = shift;

    my $article       = shift;
    my $return_fields = shift || ' ';    # CSV format
    my $reference_id  = shift || '';

    my $content = qq(article=$article);
    $content .= qq(&return_fields=[$return_fields]);
    $content .= qq(&reference_id=$reference_id);

    return $self->_request( $content, $self->tonalize_detailed_uri );
}

=head2 PARAMS

=head3 article (string)

=head3 return_fields (csv)

=head3 article_reference_id (string)

=head2 tonalize_multiple(articles, [return_fields, article_reference_ids])

The tonalize_multiple method provides article-level Lymbix sentiment data for multiple articles.

articles (csv), return_fields (csv), article_reference_ids (csv)

=cut

sub tonalize_multiple {
    my $self = shift;

    my $articles      = shift;
    my $return_fields = shift || ' ';    # CSV format
    my $reference_ids = shift || ' ';    # CSV format

    my $content = qq(articles=[$articles]);
    $content .= qq(&return_fields=[$return_fields]);
    $content .= qq(&reference_ids=[$reference_ids]);

    return $self->_request( $content, $self->tonalize_multiple_uri );
}

=head2 flag_response (reference_id, phrase, api_method_requested, [api_version, callback_url])

Flags a phrase to be re-evaluated.

=cut

sub flag_response {
    my $self = shift;

    my $reference_id = shift;    # || croak 'Required to pass reference_id';
    my $phrase       = shift;
    my $api_method_requested = shift;
    my $api_version          = shift || $self->api_version;
    my $callback_url         = shift || '';

    croak "Invalid api_method_requested [$api_method_requested]"
      unless grep( /^$api_method_requested$/,
        qw(tonalize tonalize_detailed tonalize_multiple) );

    my $content = qq(phrase=$phrase);
    $content .= qq(&reference_id=$reference_id);
    $content .= qq(&api_method_requested=$api_method_requested);
    $content .= qq(&api_version=$api_version);
    $content .= qq(&callback_url=$callback_url);

    return $self->_request( $content, $self->flag_response_uri );
}

sub _request {
    my $self    = shift;
    my $content = shift;
    my $uri     = shift;

    $self->req->uri( $self->api_url . $uri );
    $self->req->content( encode( "UTF8", $content ) );

    my $res = $self->ua->request( $self->req );
    if ( $res->is_success ) {
        return $res->content;
    }
    else {
        return $res->status_line;
    }
}

=head1 AUTHOR

Omid Houshyar, C<< <ohoushyar at gmail.com> >>

=head1 BUGS


Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/ohoushyar/webservice-lymbix/issues>.


=head1 ACKNOWLEDGEMENTS

Pavel Shaydo for helping me to release this module.


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Omid Houshyar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable();
1;
