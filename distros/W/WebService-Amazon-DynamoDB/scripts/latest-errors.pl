#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async;
use Net::Async::HTTP;
use HTML::TreeBuilder qw(-weak);
use JSON::MaybeXS;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $ua = Net::Async::HTTP->new(
		fail_on_error => 1,
		decode_content => 1,
	)
);

$ua->GET(
	'http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html'
)->then(sub {
	my $html = HTML::TreeBuilder->new_from_content(shift->decoded_content);
	my ($ddb) = map $_->look_up(class => 'section'), $html->look_down(id => 'APIError');
	my @rows = map $_->look_down('_tag' => 'tr'), map $_->look_down('_tag' => 'tbody'), $ddb;

	binmode STDOUT, ':encoding(UTF-8)';
	my $json = JSON::MaybeXS->new(
		pretty    => 1,
		canonical => 1,
	);
	print $json->encode({
		errors => [
			map {;
				my @cols = map $_->as_text, $_->look_down('_tag' => 'td');
				s/^\s+//, s/\.?\s*$// for @cols;
				+{
					http_code => $cols[0],
					exception => $cols[1],
					message   => $cols[2],
					cause     => $cols[3],
					retry     => $cols[4] eq 'Y' ? JSON->true : JSON->false,
				}
			} @rows
		]
	});
	Future->wrap;
})->get;

