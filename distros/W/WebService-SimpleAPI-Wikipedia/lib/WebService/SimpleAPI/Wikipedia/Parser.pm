package WebService::SimpleAPI::Wikipedia::Parser;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

my @Fileds = qw( language id url title body length redirect strict datetime );
__PACKAGE__->mk_accessors(@Fileds);

use DateTime::Format::W3CDTF;
use XML::Simple;
use WebService::SimpleAPI::Wikipedia::ResultSet;

sub parse {
    my($class, $xml) = @_;

    my $p = XML::Simple->new;
    my $data = $p->XMLin($xml, KeyAttr => []);
    $class->init($data);
}

sub init {
    my($class, $data) = @_;

    my @results;
    if ($data->{result}) {
        @results = ref $data->{result} eq 'ARRAY' ?
            map { bless $_, $class } @{ $data->{result} } : ( bless $data->{result}, $class );
    }
    for my $res (@results) {
        $res->url(URI->new($res->url));
        my $df = DateTime::Format::W3CDTF->new;

        # simpleAPI datetime format bug.
        my $dt = $res->datetime;
        $dt =~ s/(T.+)T(.+)$/$1+$2/;

        $res->datetime( $df->parse_datetime( $dt ) );
    }

    return WebService::SimpleAPI::Wikipedia::ResultSet->new({
        results => \@results,
        nums    => scalar @results,
    });
}

1;
