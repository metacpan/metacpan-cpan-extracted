package WebService::OurWorldInData;
# ABSTRACT: Perl library to connect with the Our World in Data API
# https://ourworldindata.org

our $VERSION = '0.01';

use v5.12;
use Moo;
use Carp;

my $DEBUG = 0;

has ua    => (
    is => 'ro',
    default => sub {
        require HTTP::Tiny;
        require IO::Socket::SSL;
        HTTP::Tiny->new;
    },
);

has base_url => (
    is      => 'ro',
    default => sub { 'https://ourworldindata.org' },
);

sub get_response {
    my ($self, $url) = @_;

    my $res = $self->ua->get( $url );

    if    ($res->{success})  { warn $res->{content} if $DEBUG > 1 }
    elsif ($res->{redirects}) { carp 'Redirected: ', $res->headers->location if $DEBUG }
    else  { carp 'HTTP Error: ', $res->{status}, $res->{reason}; }

    return $res->{content};
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

This is a base class for Our World in Data APIs. You probably should be
using the L<WebService::OurWorldInData::Chart> class.

=head2 Getting Started

Documentation for L<Chart API|https://docs.owid.io/projects/etl/api/chart-api/>

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
