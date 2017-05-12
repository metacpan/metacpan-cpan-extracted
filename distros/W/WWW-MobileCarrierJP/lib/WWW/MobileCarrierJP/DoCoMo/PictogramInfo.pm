package WWW::MobileCarrierJP::DoCoMo::PictogramInfo;
use strict;
use warnings;
use WWW::MobileCarrierJP::Declare;

my @url =
    map { URI->new($_) } (
    "http://www.nttdocomo.co.jp/service/developer/make/content/pictograph/basic/index.html",
    "http://www.nttdocomo.co.jp/english/service/imode/make/content/pictograph/basic/index.html",
    "http://www.nttdocomo.co.jp/service/developer/make/content/pictograph/extention/index.html",
    "http://www.nttdocomo.co.jp/english/service/imode/make/content/pictograph/extention/index.html",
);
sub url { \@url }

sub scrape {
    my $res;
    my $i;
    my @prev;
    for my $uri (@url) {
        my @chars = @{
            scraper {
                process 'tr', 'characters[]', scraper {
                    col 3, 'sjis',    'TEXT';
                    col 5, 'unicode', 'TEXT';
                    col 6, 'name',    'TEXT';
                    col 7, 'color',   'TEXT';
                };
            }->scrape($uri)->{characters}
        };

        # remove headers
        shift @chars; shift @chars;

        if (++$i % 2) {
            @prev = @chars;
        } else {
            @prev == @chars or die "ja/en count doesn't match";
            for my $c (0..$#prev) {
                for my $column (qw/color name/) {
                    $prev[$c]->{"en_$column"} = $chars[$c]->{$column};
                    $prev[$c]->{"jp_$column"} = delete $prev[$c]->{$column};
                }
            }
            push @$res, @prev;
        }
    }

    $res;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::MobileCarrierJP::DoCoMo::PictogramInfo - 絵文字(DoCoMo)

=head1 SYNOPSIS

    use WWW::MobileCarrierJP::DoCoMo::PictogramInfo;
    WWW::MobileCarrierJP::DoCoMo::PictogramInfo->scrape();

=head1 AUTHOR

Tokuhiro Matsuno < tokuhirom gmail com >

=head1 THANKS

This code is copied from Encode-JP-Mobile.

miyagawa++

=head1 SEE ALSO

L<WWW::MobileCarrierJP>

