use strict;
use warnings;

package Webservice::Judobase;
$Webservice::Judobase::VERSION = '0.09';
# ABSTRACT: This module wraps the www.judobase.org website API.
# VERSION

use Moo;
require HTTP::Request;
require LWP::UserAgent;

use Webservice::Judobase::Competitor;
use Webservice::Judobase::Contests;
use Webservice::Judobase::Country;
use Webservice::Judobase::General;

use namespace::clean;

my $url = 'http://data.ijf.org/api/get_json';
my $ua  = LWP::UserAgent->new;
$ua->agent("WebServiceJudobase/0.1 ");

has 'competitor' => (
    is      => 'ro',
    default => sub {
        return Webservice::Judobase::Competitor->new(
            ua  => $ua,
            url => $url,
        );
    },
);

has 'contests' => (
    is      => 'ro',
    default => sub {
        return Webservice::Judobase::Contests->new(
            ua  => $ua,
            url => $url,
        );
    },
);

has 'country' => (
    is      => 'ro',
    default => sub {
        return Webservice::Judobase::Country->new(
            ua  => $ua,
            url => $url,
        );
    },
);

has 'general' => (
    is      => 'ro',
    default => sub {
        return Webservice::Judobase::General->new(
            ua  => $ua,
            url => $url,
        );
    },
);

sub status {
    my ($self)  = @_;
    my $ua      = LWP::UserAgent->new;
    my $request = HTTP::Request->new( GET => $url );

    my $response = $ua->request($request);

    return $response->code == 200 ? 1 : 0;
}

1;
