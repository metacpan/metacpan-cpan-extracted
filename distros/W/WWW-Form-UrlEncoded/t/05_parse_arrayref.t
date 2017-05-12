use strict;
use warnings;
use Test::More;
use WWW::Form::UrlEncoded qw/parse_urlencoded_arrayref/;
use JSON;

while (<DATA>) {
    chomp;
    next unless $_;
    my ($s,$t) = split /\s+=>\s/, $_,2;
    $s =~ s/'//g;
    my $param = parse_urlencoded_arrayref($s);
    is JSON::encode_json($param), $t, $s;
}

done_testing();

__DATA__
'a=b&c=d'     => ["a","b","c","d"]
'a=b;c=d'     => ["a","b","c","d"]
'a=1&b=2;c=3' => ["a","1","b","2","c","3"]
'a==b&c==d'   => ["a","=b","c","=d"]
'a=b& c=d'    => ["a","b","c","d"]
'a=b; c=d'    => ["a","b","c","d"]
'a=b; c =d'   => ["a","b","c ","d"]
'a=b;c= d '   => ["a","b","c"," d "]
'a=b&+c=d'    => ["a","b"," c","d"]
'a=b&+c+=d'   => ["a","b"," c ","d"]
'a=b&c=+d+'   => ["a","b","c"," d "]
'a=b&%20c=d'  => ["a","b"," c","d"]
'a=b&%20c%20=d' => ["a","b"," c ","d"]
'a=b&c=%20d%20' => ["a","b","c"," d "]
'a&c=d'       => ["a","","c","d"]
'a=b&=d'      => ["a","b","","d"]
'a=b&='       => ["a","b","",""]
'&'           => ["","","",""]
'='           => ["",""]
''            => []

