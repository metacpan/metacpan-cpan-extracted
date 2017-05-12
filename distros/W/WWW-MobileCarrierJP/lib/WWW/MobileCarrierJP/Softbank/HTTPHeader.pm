package WWW::MobileCarrierJP::Softbank::HTTPHeader;
use strict;
use warnings;
use utf8;
use WWW::MobileCarrierJP::Declare;

my $url = 'http://creation.mb.softbank.jp/mc/terminal/terminal_info/terminal_httphedder.html';

parse_one(
    urls  => [$url],
    xpath => '//div[@class="terminaltable"]/table/tr[position() > 3]/td[not(@colspan=8)]/..',
    scraper => scraper {
        process 'td:nth-child(1)', 'model', 'TEXT';

        process 'td:nth-child(2)', 'x-jphone-name',    'TEXT';
        process 'td:nth-child(3)', 'x-jphone-display', [ 'TEXT', \&_asterisk ];
        process 'td:nth-child(4)', 'x-jphone-color',   'TEXT';
        process 'td:nth-child(5)', 'x-jphone-smaf',  [ 'TEXT', \&_undefine ];

        # maybe, no person needs x-s-* information.
        # and, I don't want to maintenance this header related things :P
        #   process 'td:nth-child(6)', 'x-s-display-info', [ 'TEXT', \&_undefine, ];
        #   process 'td:nth-child(7)', 'x-s-unique-id',    [ 'TEXT', \&_undefine, ];
    },
);

sub _asterisk { s/ x /*/ }

sub _undefine {
    my $x = shift;
    $x =~ s/\s+$//;
    $x =~ /^(?:−|-|\x{d7})$/ ? undef : $x;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::MobileCarrierJP::Softbank::HTTPHeader - HTTPヘッダ(Softbank)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::Softbank::HTTPHeader;
    WWW::MobileCarrierJP::Softbank::HTTPHeader->scrape();

=head1 AUTHOR

Tokuhiro Matsuno < tokuhirom gmail com >

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

