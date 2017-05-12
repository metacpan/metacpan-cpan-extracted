use utf8;
use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use Text::Sass::XS qw(:const);
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);

subtest 'compile' => sub {
    subtest 'no options' => sub {
        my $source = <<'EOM';
$red: #ff1111;

.something {
  color: $red;
}
EOM
        my $compiled = ".something {color:#ff1111;}";

        my $sass = new_ok 'Text::Sass::XS';
        my $css  = $sass->compile($source);
        is $css, $compiled;
    };

    subtest 'with options' => sub {
        plan skip_all => "Some how \@import didn't support on Windows"
            if $^O =~ /MSWin/;

        my $source = <<'EOM';
@import "red";

.something {
  color: $red;
  background: image-url("apple.png");
}
EOM
        my $sass = new_ok 'Text::Sass::XS',
            [
            include_paths => [
                catdir( $Bin, 'assets' ), catdir( $Bin, 'another-assets' )
            ],
            image_path      => '/images',
            output_style    => SASS_STYLE_COMPRESSED,
            source_comments => SASS_SOURCE_COMMENTS_NONE,
            dont_die        => 1,
            ];

        my $css = $sass->compile($source);
        is $css,
            ".something {color:#ff1111;background:url(\"/images/apple.png\");}";
    };
};

subtest 'compile_file' => sub {
    my $sass_file = catfile( $Bin, qw/assets foo.scss/ );

    subtest 'no options' => sub {
        my $sass = new_ok 'Text::Sass::XS';
        my $css  = $sass->compile_file($sass_file);
        my $output
            = '.content-navigation {border-color:#3bbfce;}.border {padding:8px;margin:8px;}';
        is $css, $output, 'compile_file with options';
    };

    subtest 'with options' => sub {
        my $sass = new_ok 'Text::Sass::XS',
            [
            output_style    => SASS_STYLE_COMPRESSED,
            source_comments => SASS_SOURCE_COMMENTS_NONE,
            include_paths   => undef,
            image_path      => undef,
            ];

        my $css = $sass->compile_file($sass_file);
        my $output
            = '.content-navigation {border-color:#3bbfce;}.border {padding:8px;margin:8px;}';
        is $css, $output, 'compile_file with options';
    };

};

done_testing;
