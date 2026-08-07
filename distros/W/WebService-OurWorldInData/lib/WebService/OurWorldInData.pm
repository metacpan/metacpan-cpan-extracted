package WebService::OurWorldInData;
# ABSTRACT: Perl library to connect with the Our World in Data API
# https://ourworldindata.org

our $VERSION = '0.06';

use v5.8;
use Moo;
use Carp;

my $DEBUG = 0;

has ua    => (
    is => 'ro',
    default => sub {
        require HTTP::Tiny;
        require IO::Socket::SSL;
        HTTP::Tiny->new(
            agent => "WebService-OurWorldInData/$VERSION ",
        );
    },
);

has base_url => (
    is      => 'ro',
    default => sub { 'https://ourworldindata.org' },
);

sub get_response {
#TODO Needs to be re-written to handle different UAs gracefully ####
    my ($self, $url, $query) = @_;

    my $res;
    if ( ref $self->ua eq 'HTTP::Tiny' ) {
        my $params = $self->ua->www_form_urlencode( $query );
        $res = $self->ua->get( join('?', $url, $params) );
        _report_status_tiny($res);
    }
    elsif ( ref $self->ua eq 'LWP::UserAgent' ) {
        require URI;
        my $uri = URI->new( $url );
        $uri->query_form( $query ) if $query;
        $res = $self->ua->get( $uri->as_string );
        _report_status_full($res);
    }
    else {
        carp 'No url_encoding for ', ref $self->ua;
        $res = $self->ua->get( $url );
        _report_status_full($res);
    }

    return ref $self->ua eq 'HTTP::Tiny' ? $res->{content} : $res->content;
}

sub _report_status_tiny {
    my $res = shift;

    if    ($res->{success})  { warn $res->{content} if $DEBUG > 1 }
    elsif ($res->{redirects}) { carp 'Redirected: ', $res->headers->location if $DEBUG }
    else  { carp 'HTTP Error: ', $res->{status}, $res->{reason}; }
}

sub _report_status_full {
    my $res = shift;

    if    ($res->is_success)  { warn $res->content if $DEBUG > 1 }
    elsif ($res->is_redirect) { carp 'Redirected: ', $res->headers->location if $DEBUG }
    else  { carp join q{ }, 'HTTP Error:', $res->code, $res->message; }
}

sub post_response {
    my ($self, $url) = @_;

    my $res = $self->ua->post( $url );

    return $res->{content};
}

1; # Perl is my Igor

=head1 SYNOPSIS

    my $owid = WebService::OurWorldInData->new({
        proxy => '...', # your web proxy
    });

    my $search = $owid->search( q => 'star', fl => 'bibcode' );

=head1 DESCRIPTION

This is a base class for Our World in Data APIs. You will want the modules
for each endpoint:

=over 4

=item * L<WebService::OurWorldInData::Chart>

=item * L<WebService::OurWorldInData::Tables>

=item * L<WebService::OurWorldInData::Indicators>

=item * L<WebService::OurWorldInData::Search>

=back

B<WARNING>: from the OWID dev page, I<These APIs are under active development>.
For that reason, I will start by only providing the JSON responses from their
server. As the API design crystalizes, I will add convenience handling classes
for the Results so that you can iterate through them for specific bits of data.

=head2 Getting Started

OWID's L<Technical Documentation|https://docs.owid.io/projects/etl/api/>

=head2 Proxies

The UA gets the proxy from your environment variable
_or_
create a HTTP::Tiny object with the {all_proxy => "proxy url"} attribute
and pass that to the C<ua> attribute of the API constructor

    $tiny_ua = HTTP::Tiny->new({all_proxy => "http://proxy.url"});
    $client = WebService::OurWorldInData->new({ ua => $tiny_ua });

=head1 ACKNOWLEDGMENTS

I am stealing from Neil Bowers' L<WebService::HackerNews> to learn how he does
APIs with L<HTTP::Tiny>. This is a re-write from my first version in Mojo.
Any mistakes, of course, are mine.

=head1 REPOSITORY

L<https://github.com/duffee/perl-OurWorldInData>

=head1 AUTHOR

Boyd Duffee E<lt>duffee@cpan.orgE<gt>

=head1 LICENSE

MIT License

Copyright (c) 2025 Boyd Duffee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
