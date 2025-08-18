#!perl
use 5.020;
use Test2::V0 '-no_srand';
use XML::LibXML;
use File::Basename;
use Text::HTML::Turndown;
use JSON::Tiny 'decode_json';

open my $fh, '<:encoding(UTF-8)', dirname($0) . "/entities.html"
    or die "Couldn't read 'entities.html': $!";
my $input = do { local $/; <$fh> };
my $p = XML::LibXML->new;
my $dom = $p->parse_html_string( $input, { recover => 2, encoding => 'UTF-8' });

my @tests = $dom->findnodes('//*[@class="case"]');

for my $t (@tests) {
    my $name = $t->getAttribute('data-name');
    my @input = $t->findnodes('./*[@class="input"]');
    my $input = join "", map { $_->toString } $input[0]->childNodes;
    my $expected = "" . $t->findnodes('./*[@class="expected"]')->to_literal;
    #next if $input !~ /~~~/;
    #next if $name !~ /code block with multiple/;

    my $options = decode_json( $t->getAttribute('data-options') // '{}' );
    my $turndown = Text::HTML::Turndown->new(%$options);

    if(! is( $turndown->turndown( $input ), $expected, $name )) {
        diag $input;
    }
}

done_testing();
