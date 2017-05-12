#!perl
use strict;
use Test::More;

BEGIN { use_ok("Text::AutoLink") }

subtest "Parsing twitter-style urls should work" => sub {
    my $auto = Text::AutoLink->new;
    my $text = $auto->parse_string( "http://www.facebook.com/groups/loctouch/#!/groups/loctouch/236227373098903/" );
    my $expected = q|<a href="http://www.facebook.com/groups/loctouch/#!/groups/loctouch/236227373098903/">http://www.facebook.com/groups/loctouch/#!/groups/loctouch/236227373098903/</a>|;
    is $text, $expected;
};

subtest "Parsing a linked text should not produce a new link" => sub {
    my $original = q|<html><body><a href="http://search.cpan.org">http://search.cpan.org</a></body></html>|;
    my $auto = Text::AutoLink->new;
    my $text = $auto->parse_string($original);
    is($original, $text);
};

subtest "Parsing a text with non-beginning link should linkify" => sub {
    my $original = <<EOS;
<html><body>http://search.cpan.org</a></body></html>
EOS

    my $auto = Text::AutoLink->new;
    my $text = $auto->parse_string($original);
    my $expected = q|<html><body><a href="http://search.cpan.org">http://search.cpan.org</a></body></html>|;

    is($text, $expected);
};

done_testing;


