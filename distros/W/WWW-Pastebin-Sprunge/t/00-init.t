use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('WWW::Pastebin::Sprunge::Retrieve');
    use_ok('WWW::Pastebin::Sprunge::Create');
}

my $writer = new_ok('WWW::Pastebin::Sprunge::Create');
my $reader = new_ok('WWW::Pastebin::Sprunge::Retrieve');

can_ok($writer, qw(
    new
    paste
    paste_uri
    ua
    _set_error
) );


can_ok($reader, qw(
    new
    retrieve
    error
    content
    results
    ua
    uri
    id
    _make_uri_and_id
    _parse
    _get_was_successful
    _set_error
) );
