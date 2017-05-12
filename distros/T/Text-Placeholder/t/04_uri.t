#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 1;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $uri = '::URI');
$placeholder->compile('Host: [=uri_host=]');

$uri->subject('http://www.perl.org/');
my $result = ${$placeholder->execute()};
ok($result eq 'Host: www.perl.org', 'T001: extracted host from URI.');

exit(0);
