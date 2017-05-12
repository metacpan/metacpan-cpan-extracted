# ABSTRACT: Diffbot Perl API
package WebService::Diffbot;
{
  $WebService::Diffbot::VERSION = '0.003';
}

use Moo;
use namespace::clean;

use JSON qw( decode_json encode_json );
use LWP::UserAgent;

has api_url => ( is => 'ro', default => sub { 'http://api.diffbot.com/v2/' } );
has automatic_api => ( is => 'rw', default => sub { 'article' } );
has $_ => ( is => 'rw', required => 1 ) for qw( token url );
has $_ => ( is => 'rw' ) for qw( fields timeout callback );
has verbose => ( is => 'rw', default => sub { 0 } );

sub article {
    my $self = shift;
    my %args = @_;

    $self->automatic_api('article');

    $self->url( $args{url} ) if $args{url};

    $self->_process;
};

sub frontpage {
    my $self = shift;
    my %args = @_;

    $self->automatic_api('frontpage');

    $self->url( $args{url} ) if $args{url};

    $self->_process;
};

sub version {
    __PACKAGE__->VERSION;
};

sub _process {
    my $self = shift;

    return if not defined $self->token or not defined $self->url;

    my $uri = URI->new($self->api_url . $self->automatic_api);

    $uri->query_form(
        token   => $self->token,
        url     => $self->url,
    );

    my $response = LWP::UserAgent->new->get($uri);

    die $response if !$response->is_success;

    my $content = decode_json $response->decoded_content;

    die $content->{error} if $content->{error};
    print STDERR $content->{warning} if $content->{warning};

    return $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Diffbot - Diffbot Perl API

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This is the (unofficial) Diffbot Perl API - see http://www.diffbot.com for
more info.

Warning, currently it supports only the Article and Frontpage API (v2).

=head1 SYNOPSYS

    use WebService::Diffbot;
    
    my $diffbot = WebService::Diffbot->new(
        token => 'mytoken',
        url => 'http://www.diffbot.com'
    );

    # Article API
    my $article = $diffbot->article;

    print "url:   $article->{url}";
    print "text:  $article->{text}";
    ...

    # Frontpage API
    my $frontpage = $diffbot->frontpage;
    ...

    # another Article API - pass new url to method
    $article = $diffbot->article( url => 'http://www.youtube.com' );

    print "url:   $article->{url}";
    print "text:  $article->{text}";
    ...

=head1 SEE ALSO

L<Net::DiffBot> for old API

=head1 AUTHOR

Cesare Gargano <garcer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cesare Gargano.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
