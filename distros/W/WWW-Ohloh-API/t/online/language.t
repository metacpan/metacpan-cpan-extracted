use strict;
use warnings;

use Test::More;

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set the environment variable OHLOH_KEY to your api key to enable these tests
END_MSG

plan tests => 18;

my $ohloh = WWW::Ohloh::API->new( api_key => $ENV{OHLOH_KEY} );

my $languages = $ohloh->get_languages( sort => 'code' );

ok $languages->isa('WWW::Ohloh::API::Languages'),
  'get_languages returns W:O:A:Languages';

ok $languages->total_entries > 10, 'total_entries() > 10';

my @l = $languages->all;

ok scalar(@l), "all() returns something";

ok !grep( { !$_->isa('WWW::Ohloh::API::Language') } @l ),
  "all() returns W:O:A:Language";

my ($perl) = grep { $_->nice_name eq 'Perl' } @l;

ok $perl, "we found Perl!";

is $perl->id       => 8,      'Perl id number is 8';
is $perl->name     => 'perl', 'name()';
is $perl->category => 'code', 'category()';
ok $perl->code > 0,     'code()';
ok $perl->comments > 0, 'comments()';
ok $perl->blanks > 0,   'blanks()';
ok( ( $perl->comment_ratio > 0 and $perl->comment_ratio < 1 ),
    'comment_ratio()' );
ok $perl->projects > 0,     'projects()';
ok $perl->contributors > 0, 'contributors()';
ok $perl->commits > 0,      'commits()';

ok $perl->is_code, 'is_code()';
ok !$perl->is_markup, 'is_markup()';

like $perl->as_xml, qr#<language>.*</language>#, 'language->as_xml';
