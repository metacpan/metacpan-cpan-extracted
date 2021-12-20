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
    Handler         => $writer,
    KeepAspectRatio => 1,
    Width           => 80,
    Height          => 80,
);
my $parser = XML::SAX::ParserFactory->parser(
    Handler => $transformer,
);

my $comment_re   = qr/<!---40 0 150 100-->/;
my $svg_re       = qr/<(?:svg:)?svg[^>]+>/;
my $group_re     = qr/<(?:svg:)?g[^>]+>/;
my $transform_re = qr/<g[^>]+transform="[^"]+"[^>]*>/;

subtest 'first transformation' => sub {
    $parser->parse_string($svg);

    like $output => qr/$comment_re/, 'has comment';

    my (@svgs)   = $output =~ /($svg_re)/g;
    my (@groups) = $output =~ /($group_re)/g;
    is @svgs   => 2, "correct number of svgs";
    is @groups => 3, "correct number of groups";
    ok $svgs[0]   =~ /width="80"/,  "outer svg has width=80";
    ok $svgs[0]   =~ /height="80"/, "outer svg has height=80";
    ok $svgs[1]   =~ /width="80"/,  "inner svg also has width=80";
    ok $svgs[1]   !~ /height="80"/, "inner svg does not have height=80";
    ok $groups[0] =~ /transform="translate\(0 [0-9.eE]+\)"/,             "outer group has only translate";
    ok $groups[1] =~ /transform="translate\([^)]+\) scale\((\S+) \1\)"/, "second group has scale";
    ok $groups[0] !~ /id="[^"]+"/, "outer group has no id";
    ok $groups[1] !~ /id="[^"]+"/, "second group has no id";
};

subtest 'second transformation' => sub {
    $parser->parse_string($output);

    my (@svgs)   = $output =~ /($svg_re)/g;
    my (@groups) = $output =~ /($group_re)/g;
    is @svgs   => 2, "correct number of svgs";
    is @groups => 3, "correct number of groups";
    ok $svgs[0]   =~ /width="80"/,  "outer svg has width=80";
    ok $svgs[0]   =~ /height="80"/, "outer svg has height=80";
    ok $svgs[1]   =~ /width="80"/,  "inner svg also has width=80";
    ok $svgs[1]   !~ /height="80"/, "inner svg does not have height=80";
    ok $groups[0] =~ /transform="translate\(0 [0-9.eE]+\)"/,             "outer group has only translate";
    ok $groups[1] =~ /transform="translate\([^)]+\) scale\((\S+) \1\)"/, "second group has scale";
    ok $groups[0] !~ /id="[^"]+"/, "outer group has no id";
    ok $groups[1] !~ /id="[^"]+"/, "second group has no id";
};

done_testing;
