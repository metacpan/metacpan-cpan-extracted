use strict;
use warnings;
use Test::More;
use XML::SAX::Writer;
use XML::SAX::SVGTransformer;
use XML::SAX::ParserFactory;

my $svg = <<'SVG';
<svg viewBox="-40 0 150 100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <g fill="grey"
     transform="rotate(-10 50 100)
                translate(-36 45.5)
                skewX(40)
                scale(1 0.5)">
    <path id="heart" d="M 10,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 90,30 Q 90,60 50,90 Q 10,60 10,30 z" />
  </g>

  <use xlink:href="#heart" fill="none" stroke="red"/>
</svg>
SVG

my $output = '';
my $writer = XML::SAX::Writer->new(
    Output         => \$output,
    QuoteCharacter => '"',
);
my $transformer = XML::SAX::SVGTransformer->new(
    Transform => 'rotate(90)',
    Handler   => $writer,
);
my $parser = XML::SAX::ParserFactory->parser(
    Handler => $transformer,
);

my $comment_re = qr/<!---40 0 150 100-->/;
my $group_re   = qr/<g[^>]*id="SVGTransformer"[^>]*>/;

subtest 'first transformation' => sub {
    $parser->parse_string($svg);

    like $output => qr/$comment_re/, 'has comment';
    like $output => qr/$group_re/,   'has group';

    my ($group) = $output =~ /($group_re)/;
    like $group => qr/transform="translate\(100 40\) rotate\(90\)"/, 'has transform';
};

subtest 'second transformation' => sub {
    $parser->parse_string($output);

    my $comment_ct = $output =~ /$comment_re/g;
    is $comment_ct => 1, 'has only one comment';
    my $group_ct = $output =~ /$group_re/g;
    is $group_ct => 1, 'has only one group';

    my ($group) = $output =~ /($group_re)/;
    like $group => qr/transform="translate\(150 100\) rotate\(180\)"/, 'has transform';
};

done_testing;
