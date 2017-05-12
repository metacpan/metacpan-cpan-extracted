package WWW::MobileCarrierJP::EZWeb::CIDR;
use strict;
use warnings;
use URI;
use WWW::MobileCarrierJP::Declare;

sub url { 'http://www.au.kddi.com/ezfactory/tec/spec/ezsava_ip.html'; }

sub scrape {
    my $uri = URI->new(__PACKAGE__->url);
    my $content = get($uri);
    my $body = "";
    my $skip_flag = 0;
    for my $line ( split /\n/, $content ) {
        next if $skip_flag;

        if ( $line =~ m{id="PcsvSummer"} ) {
            $skip_flag++;
        } else {
            $body .= $line;
        }
    }
    my $rows = scraper {
        process '//table[@cellspacing="1"]/tr', 'ip[]', scraper {
            process '//td[position()=1]/div', 'num',        'TEXT';
            process '//td[position()=2]/div', 'ip',         'TEXT';
            process '//td[position()=3]/div', 'subnetmask', 'TEXT';
            process '//td[position()=4]/div', 'deprecated', 'TEXT';
        };
    }->scrape(\$body)->{ip};
    for my $row ( @$rows ) {
        if ( $row->{num} && $row->{num} =~ /^\d+$/) {
            delete $row->{deprecated};
        }
        else {
            $row->{deprecated} = 1;
        }
    }
    return [ grep { !$_->{deprecated} } @$rows ];
}

1;

__END__

=encoding utf-8

=for stopwords EZweb CIDR

=head1 NAME

WWW::MobileCarrierJP::EZWeb::CIDR - CIDR(EZweb)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::EZWeb::CIDR;
    WWW::MobileCarrierJP::EZWeb::CIDR->scrape();

=head1 AUTHOR

Tokuhiro Matsuno < tokuhirom gmail com >

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

