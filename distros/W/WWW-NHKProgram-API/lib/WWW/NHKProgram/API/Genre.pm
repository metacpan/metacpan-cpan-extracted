package WWW::NHKProgram::API::Genre;
use strict;
use warnings;
use utf8;
use Encode qw/decode_utf8/;
use TV::ARIB::ProgramGenre qw/get_genre_id/;
use parent qw/Exporter/;
our @EXPORT_OK = qw/fetch_genre_id/;

sub fetch_genre_id {
    my $arg = shift;

    if ($arg =~ /\A\d{4}\Z/) {
        return $arg;
    }

    eval { $arg = decode_utf8($arg) };
    my $id = get_genre_id($arg);
    return sprintf("%02d%02d", $id->[0], $id->[1]);
}

1;

