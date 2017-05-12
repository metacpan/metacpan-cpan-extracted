package WWW::MobileCarrierJP::EZWeb::Model;
use WWW::MobileCarrierJP::Declare;

parse_one(
    urls => ['http://www.au.kddi.com/ezfactory/tec/spec/new_win/ezkishu.html'],
    xpath => '//tr[@valign="middle" and @bgcolor="#ffffff"]',
    scraper => scraper {
        col 1 => 'model_long', 'TEXT';
        col 2 => 'browser_type', 'TEXT';

        col 4 => 'is_color',
            [ 'TEXT', sub { /モノクロ/ ? undef : 1 } ];
        col 7 => 'display_browsing',
            [ 'TEXT', sub { /^(\d+)×(\d+)$/; +{width => $1, height => $2 } } ];
        col 8 => 'display_wallpaper',
            [ 'TEXT', sub { /^(\d+)×(\d+)$/; +{width => $1, height => $2 } } ];
        col 9 => 'gif',
            [ 'TEXT', sub { /○/ ? 1 : undef } ];
        col 10 => 'jpeg',
            [ 'TEXT', sub { /○/ ? 1 : undef } ];
        col 11=> 'png',
            [ 'TEXT', sub { /○|△/ ? 1 : undef } ];
        col 14 =>'flash_lite',
            [ 'TEXT', sub { /^(\d\.\d).*$/; $1 } ];
    },
);

1;
__END__

=encoding utf-8

=for stopwords Model EZweb

=head1 NAME

WWW::MobileCarrierJP::EZWeb::Model - Model(EZweb)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::EZWeb::Model;
    WWW::MobileCarrierJP::EZWeb::Model->scrape();

=head1 AUTHOR

Tokuhiro Matsuno < tokuhirom gmail com >

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

