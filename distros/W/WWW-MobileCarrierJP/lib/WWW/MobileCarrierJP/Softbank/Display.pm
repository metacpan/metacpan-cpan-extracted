package WWW::MobileCarrierJP::Softbank::Display;

use utf8;
use charnames ':full';
use List::Util qw/first/;
use WWW::MobileCarrierJP::Declare;

parse_one(
    urls    => ['http://creation.mb.softbank.jp/mc/terminal/terminal_info/terminal_display.html'],
    xpath   => q(//div[@class='terminaltable']/table/tr[ not(@bgcolor="#cccccc") and count(child::td) != 1 and position() >= 3 ]),
    scraper => scraper {
        col 1 => 'model'              => 'TEXT';
        col 2 => 'browser_pixels'     => [ 'TEXT', \&_parse_pixels_table ];
        col 3 => 'browser_characters' => [ 'TEXT', \&_parse_characters_table ];
        col 4 => 'appli_pixels'       => [ 'TEXT', \&_parse_appli_pixels_table ];
        col 5 => 'appli_fontsize'     => [ 'TEXT', \&_parse_appli_pixels_table ];
        col 6 => 'widget'             => [ 'TEXT', \&_parse_pixels_table ];
        col 7 => 'widget_homescreen'  => [ 'TEXT', \&_parse_pixels_table ];
        col 8 => 'flash'              => [
            'TEXT',
            sub {
                /(\d+)\s*x\s*(\d+)/ or return undef;
                +{ width => $1, height => $2 };
              }
        ];
    },
);

# [{orientation}]\nwidth x height
sub _parse_pixels_table {
    my $text = shift;
    my @result;
    $text =~ s/\s//g;
    return if ($text eq "\N{MULTIPLICATION SIGN}");
    while ( $text =~ s/\[([^\]])+\](\d+)x(\d+)// ) {
        push @result,
          {
            orientation => $1,
            width       => $2,
            height      => $3,
          };
    }
    \@result;
}

# [{orientation}]\n({size}:{width}x{height}\n)+
sub _parse_characters_table {
    my $text = shift;
    my @result;
    $text =~ s/\s//g;
    while ( $text =~ s/\[([^\]]+)\]((?:(?:[^:\[]+:)?\d+x\d+(?:\([^)]+\))?)+)// ) {
        my $mode  = $1;
        my $table = $2;
        my @fontsize_table;
        while ( $table =~ s/(?:([^:]+):)?(\d+)x(\d+)(?:\(([^)]+)\))?// ) {
            push @fontsize_table,
              {
                size_label => $1,
                cols       => $2,
                rows       => $3,
                extra      => $4,
              };
        }
        push @result,
          {
            orientation => $mode,
            size_table => \@fontsize_table,
          };
    }
    \@result;
}

# [{orientation}]\n({width}x{height}\n)+
sub _parse_appli_pixels_table {
    my $text = shift;
    my @result;
    $text =~ s/\s//g;
    while ( $text =~ s/\[([^\]]+)\]((?:[^\d\[]+\d+x\d+)+)// ) {
        my $mode  = $1;
        my $table = $2;
        my @size_table;
        while ( $table =~ s/(\D+)(\d+)x(\d+)?// ) {
            push @size_table,
              {
                resolution => $1,
                width      => $2,
                height     => $3,
              };
        }
        push @result,
          {
            orientation => $mode,
            size_table => \@size_table,
          };
    }
    \@result;
}

1;

__END__

=encoding utf-8

=for stopwords tnj

=head1 NAME

WWW::MobileCarrierJP::Softbank::Display - ディスプレイ(Softbank)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::Softbank::Display;
    my $table = WWW::MobileCarrierJP::Softbank::Display->scrape();

    my $example = shift @$table;

    my $modelname = $example->{model};

    my ($browser_resolution) = List::Util::first @{ $example->{browser_pixels} };
    printf "browser resolution of %s is %d x %d\n", $modelname,
        $browser_resolution->{width}, $browser_resolution->{height};

=head1 OUTPUT

Arrayref of hashes, structured as follows.

    {
        # Model Name
        model          => '941SH',

        # Browser Dimensions (Array) :
        # Some terminal supports multiple screen modes so this property
        # may have several items. The order is same as on the table.
        browser_pixels => [
            {
                orientation => '縦',
                width       => 480,
                height      => 824,
            }, ...
        ],

        # Maximum Displayable Characters in the Browser (Array)
        # Same as above, in addition, the maximum number is vary
        # depends on the font size setting.
        browser_characters => [
            {
                orientation => '縦',
                size_table  => [
                    {
                        size_label => '大',
                        cols       => 19,
                        rows       => 14,

                        # indicate whether default or not on some model
                        extra      => '',
                    }, ...
                ],
            }, ...
        ],

        # Supported Screen Size on S! Appli (Array)
        appli_pixels => [
            {
                orientation => '縦',
                size_table => [
                    {
                        # sometimes contains "(独自ｻｲｽﾞ)" (uncommon size)
                        resolution => 'QQVGA',
                        width      => 120,
                        height     => 130,
                    }, ...
                ],
            }, ...
        ],

        # Default Font Size on S! Appli (Array)
        appli_fontsize => [
            {
                orientation => '縦',
                size_table => [
                    {
                        # sometimes contains "(独自ｻｲｽﾞ)" (uncommon size)
                        resolution => 'QQVGA',
                        width      => 12,
                        height     => 12,
                    }, ...
                ],
            }, ...
        ],

        # Widget Dimensions, run independently (Array)
        widget => [
            {
                orientation => '縦',
                width       => 480,
                height      => 824,
            }, ...
        ],

        # Widget Dimensions, run from homescreen (Array)
        widget_homescreen => [
            {
                orientation => '縦',
                width       => 480,
                height      => 824,
            }, ...
        ],

        # Flash Dimensions (Hash)
        flash => {
            width  => 480,
            height => 824,
        },
    },


=head1 AUTHOR

tnj / Yuki Fujisaki <tanji@nothing.sh>

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

