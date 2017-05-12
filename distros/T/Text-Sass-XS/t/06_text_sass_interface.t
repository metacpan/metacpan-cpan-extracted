use utf8;
use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use Text::Sass::XS;

my $has_pp = eval 'require Text::Sass; 1;';

subtest 'scss' => sub {
    my $source = <<'SCSS';
$red: #ff1111;
.body {
    color: $red;
}
SCSS

    my $sass = Text::Sass::XS->new;
    my $css  = $sass->scss2css($source);
    is $css, ".body {color:#ff1111;}";
};

subtest 'sass' => sub {
    plan skip_all => "Text::Sass not found."
        unless $has_pp;

    my $source = <<'SCSS';
$red: #ff1111
.body
  color: $red
SCSS

    my $sass = Text::Sass::XS->new;
    my $css  = $sass->sass2css($source);
    is $css, <<'CSS'
.body {
  color: #ff1111;
}
CSS
};

subtest 'css' => sub {
    plan skip_all => "Text::Sass not found."
        unless $has_pp;

    my $source = <<'CSS';
.body {
  color: #ff1111;
}
CSS

    my $sass = Text::Sass::XS->new;
    my $out  = $sass->css2sass($source);
    is $out, <<'SASS'
.body
  color: #ff1111
SASS
};

done_testing;
