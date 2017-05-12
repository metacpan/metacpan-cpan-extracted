package WWW::NHKProgram::API::Service;
use strict;
use warnings;
use utf8;
use Carp;
use Encode qw/encode_utf8 decode_utf8/;
use parent qw/Exporter/;
our @EXPORT_OK = qw/fetch_service_id/;

use constant SERVICES => {
    g1       => 'ＮＨＫ総合１',
    g2       => 'ＮＨＫ総合２',
    e1       => 'ＮＨＫＥテレ１',
    e2       => 'ＮＨＫＥテレ２',
    e3       => 'ＮＨＫＥテレ３',
    e4       => 'ＮＨＫワンセグ２',
    s1       => 'ＮＨＫＢＳ１',
    s2       => 'ＮＨＫＢＳ１(１０２ｃｈ)',
    s3       => 'ＮＨＫＢＳプレミアム',
    s4       => 'ＮＨＫＢＳプレミアム(１０４ｃｈ)',
    r1       => 'ＮＨＫラジオ第１',
    r2       => 'ＮＨＫラジオ第２',
    r3       => 'ＮＨＫＦＭ',
    n1       => 'ＮＨＫネットラジオ第１',
    n2       => 'ＮＨＫネットラジオ第２',
    n3       => 'ＮＨＫネットラジオＦＭ',
    tv       => 'テレビ全て',
    radio    => 'ラジオ全て',
    netradio => 'ネットラジオ全て',
};

sub fetch_service_id {
    my $arg = shift;

    if ($arg =~ /\A([a-zA-Z0-9]+)\Z/) {
        croak "No such service code: $1" unless SERVICES->{$1};
        return $1;
    }
    return _retrieve_id_by_name($arg);
}

sub _retrieve_id_by_name {
    my $name = shift;

    eval { $name = decode_utf8($name) };
    for my $key (keys %{+SERVICES}) {
        return $key if SERVICES->{$key} eq $name;
    }

    croak encode_utf8("No such service: $name");
}

1;

