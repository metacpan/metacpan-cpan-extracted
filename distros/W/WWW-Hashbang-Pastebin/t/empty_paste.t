use strict;
use warnings;
use Test::More tests => 1;

# the order is important
use WWW::Hashbang::Pastebin;
use Dancer::Plugin::DBIC;
use Dancer::Test;

schema->deploy;

response_status_is  [POST => '/'], 400, 'HTTP 400 for empty POST';
