package WWW::MobileCarrierJP::Softbank::Service;
use strict;
use warnings;
use utf8;
use charnames ':full';
use WWW::MobileCarrierJP::Declare;

my $url = 'http://creation.mb.softbank.jp/mc/terminal/terminal_info/terminal_service.html';
my $xpath = '//div[@class="terminaltable"]/table/tr[ not(@bgcolor="#cccccc") and count(child::td) != 1 and position() != 1 ]';

parse_one(
    urls    => [$url],
    xpath   => $xpath,
    scraper => scraper {
        col 1 => 'model', 'TEXT';
        col 2 => 'sappli',        [ 'TEXT', \&_marubatsu ];
        col 3 => 'mobile_widget', [ 'TEXT', \&_marubatsu ];
     #  col 4 => 'flashlite' => [
     #      'TEXT',
     #      sub { s/^Flash Lite\N{TRADE MARK SIGN}// },
     #      sub { s/\s// },
     #      sub { $_ = undef if /\N{MULTIPLICATION SIGN}/ },    # `x' case.
     #  ];
        col 4 => 'gps_basic',  [ 'TEXT', \&_marubatsu ];
        col 5 => 'gps_agps',   [ 'TEXT', \&_marubatsu ];
        col 6 => 'felica',     [ 'TEXT', \&_marubatsu ];
        col 7 => 'pc_browser', [ 'TEXT', \&_marubatsu ];
    },
);

sub _marubatsu { $_ = $_ =~ /\N{WHITE CIRCLE}|\N{BULLSEYE}/ ? 1 : 0 }

1;
__END__

=encoding utf-8

=head1 NAME

WWW::MobileCarrierJP::Softbank::Service - サービス(Softbank)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::Softbank::Service;
    WWW::MobileCarrierJP::Softbank::Service->scrape();

=head1 AUTHOR

Tokuhiro Matsuno < tokuhirom gmail com >

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

