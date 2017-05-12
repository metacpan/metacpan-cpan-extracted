package WebService::KakakuCom::Parser;
use strict;
use warnings;
use XML::Simple;
use WebService::KakakuCom::Product;
use WebService::KakakuCom::ResultSet;

sub _parse {
    my ($class, $xml, @parse_opt) = @_;
    my $p = XML::Simple->new;
    my $data = $p->XMLin($xml, @parse_opt);
    if (WebService::KakakuCom->debug) {
        require Data::Dumper;
        warn Data::Dumper::Dumper($data);
    }
    $data;
}

sub parse_for_search {
    my ($class, $xml) = @_;
    my $data = $class->_parse($xml, ForceArray => [qw/Item/]);
    my @results = map WebService::KakakuCom::Product->new($_), @{$data->{Item}};
    WebService::KakakuCom::ResultSet->new({
        results     => \@results,
        NumOfResult => $data->{NumOfResult} || 0,
    });
}

sub parse_for_product {
    my ($class, $xml) = @_;
    my $data = $class->_parse($xml);
    $data->{Item} ? WebService::KakakuCom::Product->new($data->{Item}) : return;
}

1;
