package WWW::MobileCarrierJP::AirHPhone::CIDR;
use strict;
use warnings;
use Web::Scraper;
use URI;

sub url { 'http://www.willcom-inc.com/ja/service/contents_service/create/center_info/index.html' }

sub scrape {
    scraper {
        process q{//*[@id="wrapper"]/div[1]/div[1]/div[1]/table[1]/tr[ position() > 1 ]/td},
            'cidr[]' => [
                'TEXT',
                sub { 
                    s/\s//g
                },
                sub {
                    m{^([0-9.]+)(/[0-9]+)};
                    +{ ip => $1, subnetmask => $2 };
                }
            ];
    }->scrape(URI->new(__PACKAGE__->url))->{'cidr'};
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::MobileCarrierJP::AirHPhone::CIDR - CIDR(Willcom)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::AirHPhone::CIDR;
    WWW::MobileCarrierJP::AirHPhone::CIDR->scrape();

=head1 AUTHOR

Tokuhiro Matsuno < tokuhirom gmail com >

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

