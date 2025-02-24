use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

package main;

use WebService::Postex;
use LWP::UserAgent;
use JSON::XS qw(encode_json decode_json);

my $ua = LWP::UserAgent->new(
    agent => "testsuite",
);

my $postex = PostexInjection->new(
    base_uri     => 'https://demo.example.com/foo',
    generator_id => 123456789,
    secret       => 'verysecret',
    ua           => $ua,
);

is($postex->ua->agent, "testsuite",
    "Injecting custom LWP object yields correct agent");

my $headers = $postex->ua->default_headers;
is(
    $headers->header('authorization'),
    'Bearer verysecret',
    ".. and still sets the auth header"
);

is($headers->header('accept'), 'application/json', '.. and the accept header');

done_testing;

package PostexInjection;
use v5.26;
use Object::Pad;

class PostexInjection :isa(WebService::Postex);

method ua {
    return $ua;
}

1;

__END__

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 ATTRIBUTES

=head1 METHODS


done_testing;
