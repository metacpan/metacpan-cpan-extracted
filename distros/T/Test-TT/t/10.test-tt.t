#!perl -Tw

use strict;
use warnings;
use Test::More tests => 7;
use Test::TT;

BEGIN {
    use_ok('Test::TT');
}

TODO: {    # Failing tests
    local $TODO = "These test should NOT succeed";
    tt_ok(undef);
    tt_ok('unknown_file.tt');
	my $td = '[% IF 1 %]Test';
	tt_ok(\$td);
}

my $td = '[% ok %]Test';
tt_ok(\$td);

my $data;
$td = '[% IF 1 %]Ok[% END %]';
tt_ok(\$td,'output test',{},\$data);
is($data,'Ok','output sent back ok');
