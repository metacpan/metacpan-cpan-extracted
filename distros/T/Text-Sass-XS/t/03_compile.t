use utf8;
use strict;
use warnings;
use Test::More;
use Text::Sass::XS qw(:all);

subtest 'compile with options' => sub {
    plan skip_all => "Some how \@import didn't support on Windows"
        if $^O =~ /MSWin/;

    my $sass = <<'SASS';
@import "red";
@import "green";

$blue: #3bbfce;
$margin: 16px;

.content-navigation {
  color: $red;
  border-color: $blue;
  background: image-url("apple.png");
}

.border {
  color: $green;
  padding: $margin / 2;
  margin: $margin / 2;
}
SASS

    my $options = {
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
        include_paths   => ['t/assets','t/another-assets'],
        image_path      => '/images',
    };
    my $css = sass_compile( $sass, $options );
    is $css, '.content-navigation {color:#ff1111;border-color:#3bbfce;background:url("/images/apple.png");}.border {color:#008000;padding:8px;margin:8px;}';
};

subtest 'compile with options - no import syntax' => sub {
    my $sass = <<'SASS';
$blue: #3bbfce;
$margin: 16px;

.content-navigation {
  border-color: $blue;
  background: image-url("apple.png");
}

.border {
  padding: $margin / 2;
  margin: $margin / 2;
}
SASS

    my $options = {
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
        include_paths   => [],
        image_path      => '/images',
    };
    my $css = sass_compile( $sass, $options );
    is $css, '.content-navigation {border-color:#3bbfce;background:url("/images/apple.png");}.border {padding:8px;margin:8px;}';
};


subtest 'compile without options' => sub {
    my $sass = <<'SASS';
$blue: #3bbfce;
$margin: 16px;

.content-navigation {
  border-color: $blue;
}

.border {
  padding: $margin / 2;
  margin: $margin / 2;
}
SASS

    my $css = sass_compile($sass);
    is $css, '.content-navigation {border-color:#3bbfce;}.border {padding:8px;margin:8px;}';
};

done_testing;
