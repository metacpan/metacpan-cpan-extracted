use strict;
use warnings;
use Test::More;
plan tests => 2;

use URI::Find::UTF8::ExtraCharacters;

my @url;
my $finder_sub = sub {
        my ( $uri_obj, $url ) = @_;
        push(@url,$uri_obj);
        return "$uri_obj";
};

my $finder1 =
  URI::Find::UTF8::ExtraCharacters->new( $finder_sub,
    extra_characters => ['|'], );

my $pipe_url =
  "link to zombo: http://zombo.com/flipout|flapout?queryparam=queryval";

#copy the scalar then ref it cause URI::Find edits in place
  
$finder1->find( \"$pipe_url" );

is $url[0], "http://zombo.com/flipout%7Cflapout?queryparam=queryval",
  "escaped the pipe";

my $finder_no_extra_chars =
  URI::Find::UTF8::ExtraCharacters->new( $finder_sub, );

$finder_no_extra_chars->find(\$pipe_url);

is $url[1], "http://zombo.com/flipout", "without extra chars, stops at the pipe";
