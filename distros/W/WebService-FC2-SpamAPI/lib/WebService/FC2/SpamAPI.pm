package WebService::FC2::SpamAPI;

use warnings;
use strict;
use base qw/ Class::Accessor::Fast /;
use URI::Fetch;
use URI;
use URI::QueryParam;
use Carp;
use WebService::FC2::SpamAPI::Response;

our $API_uri = 'http://seo.fc2.com/spam/spamapi.php';

__PACKAGE__->mk_accessors( qw/ cache / );

=head1 NAME

WebService::FC2::SpamAPI - FC2 blog spam API client

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

Clinet for FC2 spam API.

http://seo.fc2.com/spam/

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WebService::FC2::SpamAPI;

    my $api = WebService::FC2::SpamAPI->new();

    $res = $api->check_url('http://spam.example.com');
    if ( $res->is_spam ) { ....

    @res = $api->get_url_list();

    @res = $api->get_domain_list({ dm => 'foo.example.com' });

=head1 FUNCTIONS

=head2 new

Constructor.

  my $api = WebService::FC2::SpamAPI->new();

  # use Cache ( see URI::Fetch )
  my $api = WebService::FC2::SpamAPI->new({ cache => $cache_object });

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    return $self;
}

=head2 check_url

Check URL for FC2 spam list.
Returns WebService::FC2::SpamAPI::Response object.

  # simple check
  $res = $api->check_url('http://xxx.example.com');
  if ( $res->is_spam ) { ....

  # returns detailed data
  # see also http://seo.fc2.com/spam/spamapi.php?m=h
  $res = $api->check_url({ url => 'http://xxx.exampl.com',
                           usid => 0000,
                           data => 1, });
  $res->is_spam;
  $res->usid;     # fc2 userid
  $res->name;     # site name
  $res->comment;  # comment
  # see WebService::FC2::SpamAPI::Response

=cut

sub check_url {
    my ( $self, $args ) = @_;

    my $uri = URI->new( $API_uri );
    if ( !ref $args  ) {
        $uri->query_param( url => $args );
    }
    elsif ( ref $args eq 'HASH' ) {
        for my $n ( qw/ url data usid / ) {
            $uri->query_param( $n => $args->{$n} )
                if defined $args->{$n};
        }
    }
    else {
        croak('check_url() requires SCALAR or HASH ref arguments.');
    }

    my $res = $self->_fetch( $uri );
    return unless $res;

    return WebService::FC2::SpamAPI::Response->parse( $res->content );
}

=head2 get_url_list

Get registered spam URL list.
Returns WebService::FC2::SpamAPI::Response list.

  @res = $api->get_url_list();

  @res = $api->get_url_list({ usid => 0000 }); # grep by userid

=cut

sub get_url_list {
    my ( $self, $args ) = @_;

    if( $args && ref $args ne 'HASH' ) {
        croak('get_url_list() requires HASH ref arguments.');
    }
    my $uri = URI->new( $API_uri );
    $uri->query_param( m    => 'ul' ); # url list mode.
    $uri->query_param( usid => $args->{usid} ) if $args && $args->{usid};

    my $res = $self->_fetch( $uri );
    return unless $res;

    return WebService::FC2::SpamAPI::Response->parse_list( $res->content );
}

=head2 get_domain_list

Get registered spam URL list in domain.
Returns WebService::FC2::SpamAPI::Response list.

  @res = $api->get_domain_list({ dm => 'example.com' }); # dm is required.

  @res = $api->get_domain_list({
     dm   => 'example.com',
     usid => 0000,    # grep by userid
  });

=cut

sub get_domain_list {
    my ( $self, $args ) = @_;

    if ( ref $args ne 'HASH' ) {
        croak('get_domain_list() requires HASH ref arguments.');
    }
    if ( !(defined $args->{dm} ) ) {
        croak('get_domain_list() requires dm (domain) arguments.');
    }
    my $uri = URI->new( $API_uri );
    $uri->query_param( m    => 'dl' ); # domain list mode.
    $uri->query_param( dm   => $args->{dm} );
    $uri->query_param( usid => $args->{usid} ) if $args && $args->{usid};

    my $res = $self->_fetch( $uri );
    return unless $res;

    return WebService::FC2::SpamAPI::Response->parse_list( $res->content );
}

sub _fetch {
    my ( $self, $uri ) = @_;

    my %options;
    $options{Cache} = $self->cache if $self->cache;
    $uri = ( ref $uri && $uri->isa('URI') ) ? $uri->as_string : $uri;

    return URI::Fetch->fetch( $uri, %options );
}

=head1 SEE ALSO

L<URI::Fetch>, L<WebService::FC2::SpamAPI::Response>, http://seo.fc2.com/spam/

=head1 AUTHOR

FUJIWARA Shunichiro, C<< <fujiwara at topicmaker.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 FUJIWARA Shunichiro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::FC2::SpamAPI
