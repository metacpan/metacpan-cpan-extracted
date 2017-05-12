package XRI::Resolution::Lite;

use strict;
use warnings;
use parent qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/resolver ua parser/);

use Carp;
use HTTP::Request;
use LWP::UserAgent;
use URI;
use XML::LibXML;

=head1 NAME

XRI::Resolution::Lite - The Lightweight client module for XRI Resolution

=head1 VERSION

version 0.04

=cut

our $VERSION = '0.04';

my %param_map = (
    format => '_xrd_r',
    type   => '_xrd_t',
    media  => '_xrd_m',
);

=head1 SYNOPSIS

  use XML::LibXML::XPathContext;
  use XRI::Resolution::Lite;

  my $r = XRI::Resolution::Lite->new;
  my $xrds = $r->resolve('=zigorou'); ### XML::LibXML::Document
  my $ctx = XML::LibXML::XPathContext->new($xrds);
  my @services = $ctx->findnodes('//Service');

=head1 METHODS

=head2 new

=over 2

=item $args

This param must be HASH reference. Available 2 fields.

=over 2

=item ua

(Optional) L<LWP::UserAgent> object or its inheritance.

=item resolver

(Optional) URI string of XRI Proxy Resolver.
If this param is omitted, using XRI Global Proxy Resolver, "http://xri.net/", as resolver.

=back 

=back

=cut

sub new {
    my ( $class, $args ) = @_;

    $args ||= +{};
    $args = +{
        ua => $args->{ua} || LWP::UserAgent->new,
        resolver => ( $args->{resolver} )
        ? ( UNIVERSAL::isa( $args->{resolver}, 'URI' )
            ? $args->{resolver}
            : URI->new( $args->{resolver} ) )
        : URI->new('http://xri.net/'),
        parser => XML::LibXML->new,
    };

    my $self = $class->SUPER::new($args);
    return $self;
}

=head2 resolve($qxri, \%params, \%media_flags)

When type parameter is substituted "application/xrds+xml" or "application/xrd+xml", the result would be returned as L<XML::LibXML::Document> object.
Substituted "text/uri-list" to type parameter, the result would be returned as url list ARRAY or ARRAYREF.

=over 2

=item $qxri

Query XRI string. For example :

  =zigorou
  @linksafe
  @id*zigorou

=item $params

This param must be HASH reference. Available 3 fields.
See Section 3.3 of XRI Resolution 2.0.
L<http://docs.oasis-open.org/xri/xri-resolution/2.0/specs/cd03/xri-resolution-V2.0-cd-03.html#_Ref129424065>

=over 2

=item format

Resolution Output Format. This param would be '_xrd_r' query parameter.

=item type

Service Type. This param would be '_xrd_t' query parameter.

=item media

Service Media Type. This param would be '_xrd_m' query parameter.

=back

=item $media_flags

If you want to specify flag on or off, then substitute to 1 as true, 0 as false.

=over 2

=item https

Specifies use of HTTPS trusted resolution. default value is 0.

=item saml

Specifies use of SAML trusted resolution. default value is 0.

=item refs

Specifies whether Refs should be followed during resolution (by default they are followed), default value is 1.

=item sep

Specifies whether service endpoint selection should be performed. default value is 0.

=item nodefault_t

Specifies whether a default match on a Type service endpoint selection element is allowed. default value is 1.

=item nodefault_p

Specifies whether a default match on a Path service endpoint selection element is allowed. default value is 1.

=item nodefault_m

Specifies whether a default match on a MediaType service endpoint selection element is allowed. default value is 1.

=item uric

Specifies whether a resolver should automatically construct service endpoint URIs. default value is 0.

=item cid

Specifies whether automatic canonical ID verification should performed. default value is 1

=back

=back

=cut

sub resolve {
    my ( $self, $qxri, $params, $media_flags ) = @_;

    $params      ||= {};
    $media_flags ||= {};

    $qxri =~ s|^xri://||;    ### normalize

    my %query = ();
    %query = (
        _xrd_r => 'application/xrds+xml',
        map { ( $param_map{$_}, $params->{$_} ) } keys %$params
    );

    my %flags = (
        https       => 0,
        saml        => 0,
        refs        => 1,
        sep         => 0,
        nodefault_t => 1,
        nodefault_p => 1,
        nodefault_m => 1,
        uric        => 0,
        cid         => 1,
    );

    $query{'_xrd_r'} .=
      ';' . join ';' => map { $_->[0] . '=' . $_->[1] ? 'true' : 'false' }
      map { [ $_, $media_flags->{$_} || $flags{$_} ] }
      keys %flags;

    my $hxri = $self->resolver->clone;
    $hxri->path($qxri);
    $hxri->query_form(%query);

    my $req = HTTP::Request->new( GET => $hxri );
    $req->header( Accept => $params->{type} || 'application/xrds+xml' );

    my ( $res, $e );

    eval { $res = $self->ua->request($req); };
    if ( $e = $@ ) {
        $@ = undef;
        croak($e);
    }

    croak( $res->status_line ) unless ( $res->is_success );    ### HTTP error
    croak( $res->content )
      if ( $res->header('Content-Type') =~ m#^text/plain# )
      ;    ### Invalid Content-Type

    unless ( defined $params->{format} && $params->{format} eq 'text/uri-list' )
    {      ## XRDS or XRD format
        my $doc = $self->parser->parse_string( $res->content );
        return $doc;
    }
    else {    ## URL List format
        my @url_list = split "\n" => $res->content;
        wantarray ? @url_list : \@url_list;
    }
}

=head1 SEE ALSO

=over 2

=item http://docs.oasis-open.org/xri/xri-resolution/2.0/specs/cd03/xri-resolution-V2.0-cd-03.html

There are XRI Resolution spec in OASIS.

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xri-resolution-lite@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of XRI::Resolution::Lite
