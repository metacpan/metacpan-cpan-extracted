package WebService::Prismatic::InterestGraph;
$WebService::Prismatic::InterestGraph::VERSION = '0.04';
use 5.006;
use Moo;
use JSON qw(decode_json);
use Carp qw/ croak /;
use WebService::Prismatic::InterestGraph::Tag;

has api_token => (
    is       => 'ro',
    required => 1,
);

# Really not sure it's worth having this as an attribute
# because the usage is pretty tied to HTTP::Tiny.
# But if I don't do this, Olaf will just bug me about it.
has ua => (
    is      => 'ro',
    default => sub {
                   require HTTP::Tiny;
                   require IO::Socket::SSL;
                   return HTTP::Tiny->new;
               },
);

has base_url => (
    is      => 'ro',
    default => sub { 'https://interest-graph.getprismatic.com' },
);

sub tag_url
{
    my ($self, $url) = @_;
    return $self->_post_tag_request('url/topic', { url => $url });
}

sub tag_text
{
    my ($self, $text, $title) = @_;
    my $params = { body => $text };

    $params->{title} = defined($title) ? $title :'';
    return $self->_post_tag_request('text/topic', $params);
}

sub _post_tag_request
{
    my ($self, $path, $params) = @_;
    my $full_url = $self->base_url.'/'.$path;
    my $headers  = { 'X-API-TOKEN' => $self->api_token,
                            Accept => 'application/json',
                   };
    my $response = $self->ua->post_form($full_url, $params,
                                        { headers => $headers });

    if (!$response->{success}) {
        croak "failed to make request: $response->{status} $response->{reason}";
    }
    my $ref = decode_json($response->{content});
    return unless exists($ref->{topics});

    return map { WebService::Prismatic::InterestGraph::Tag->new($_) }
               @{ $ref->{topics} };
}

1;

=head1 NAME

WebService::Prismatic::InterestGraph - identify topics in web page or text

=head1 SYNOPSIS

 use WebService::Prismatic::InterestGraph;
 my $ig = WebService::Prismatic::InterestGraph->new( api_token => $key );
 my @tags = $ig->tag_url('http://perl.org');

 foreach my $tag (@tags) {
   printf " %s [score: %f]\n", $tag->topic, $tag->score;
 }

=head1 DESCRIPTION

This module provides a simple interface to the Prismatic Interface Graph API,
which is an alpha service provided by L<getprismatic.com|http://getprismatic.com>.
It takes a piece of text and returns a number of tags, each of which
identifies a topic and a score for how likely the text includes that topic.
The text can either be specified via a URL, or passed as a scalar.

Before you can use the API, you must register with Prismatic to
get an I<api key>. One you've got that, you're ready to go.

Please note: because the service is in alpha,
you're currently restricted to 20 calls per minute.

Prismatic is a service which suggests things on the web that
you might be interested in reading.

=head1 METHODS

=head2 new

The constructor takes an C<api_token>:

 use WebService::Prismatic::InterestGraph;

 my $ig = WebService::Prismatic::InterestGraph->new( api_token => $key );

You can also pass an HTTP user agent with the C<ua> parameter,
but it pretty much has to be an instance of L<HTTP::Tiny>.

=head2 tag_url( $URL )

Takes a URL and analyses the text of the referenced page.
Returns a list of zero or more tags:

 @tags = $ig->tag_url('http://perl.org');

The tags are instances of L<WebService::Prismatic::InterestGraph::Tag>,
data objects with the following methods:

=over 4

=item * topic: short text giving the label for a topic, such as "open source"

=item * score: a number between 0 and 1 which says how likely it is that the text is actually about that topic.

=item * id: a unique integer identifier for the topic.

=back

=head2 tag_text( $TEXT [,$TITLE] )

Takes some text and an optional title string and returns a list of tags,
as for C<tag_url()> above:

 @tags = $ig->tag_url($body, $title);

=head1 SEE ALSO

L<Announcing the Interest Graph API|http://blog.getprismatic.com/interest-graph-api/> - the Prismatic blog post where they announced the API.

L<https://github.com/Prismatic/interest-graph> - the github
repo which has details of the API.

L<getprismatic.com|http://getprismatic.com/home> - the Prismatic home page.

=head1 REPOSITORY

L<https://github.com/neilbowers/WebService-Prismatic-InterestGraph>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
