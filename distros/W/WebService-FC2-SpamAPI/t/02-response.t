#!perl -T

use Test::More 'no_plan';
use Data::Dumper;
use strict;
BEGIN {
    use_ok( 'WebService::FC2::SpamAPI::Response' );
}
my $class = 'WebService::FC2::SpamAPI::Response';
my ( $input, $res );

$input = "False";
$res = $class->parse($input);
isa_ok( $res, $class );
ok( $res->is_spam );

$input = "True";
$res = $class->parse($input);
isa_ok( $res, $class );
ok( !$res->is_spam );

$input =<<_INPUT_
12345
SiteName
http://spam.example.com
Comment
C1,C2
2007/02/26 12:34:56
2007/02/26 13:25:44
_INPUT_
;

$res = $class->parse($input);
isa_ok( $res, $class );
ok( $res->is_spam );
is( $res->usid, 12345 );
is( $res->name, 'SiteName' );
is( $res->url, 'http://spam.example.com' );
is( $res->comment, 'Comment' );
is( $res->category, 'C1,C2' );
is( $res->registered_date, '2007/02/26 12:34:56' );
is( $res->updated_date, '2007/02/26 13:25:44' );

$input =<<"_INPUT_"
NAME1\thttp://spam1.example.com\t2007/03/03 11:22:33
NAME2\thttp://spam2.example.com\t2007/04/04 12:34:56
_INPUT_
;

my @res = $class->parse_list($input);
is( scalar @res, 2 );
isa_ok( $res[0], $class );
isa_ok( $res[1], $class );
ok( $res[0]->is_spam );
is( $res[0]->name, 'NAME1' );
is( $res[0]->url, 'http://spam1.example.com' );
is( $res[0]->registered_date, '2007/03/03 11:22:33' );
ok( $res[1]->is_spam );
is( $res[1]->name, 'NAME2' );
is( $res[1]->url, 'http://spam2.example.com' );
is( $res[1]->registered_date, '2007/04/04 12:34:56' );
