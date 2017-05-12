package WWW::GoKGS::Scraper::Filters;
use strict;
use warnings FATAL => 'all';
use Exporter qw/import/;

our @EXPORT_OK = qw(
    datetime
    game_result
);

sub datetime {
    my $time = shift;
    my ( $mon, $mday, $year, $hour, $min, $ampm )
        = $time =~ m{^(\d\d?)/(\d\d?)/(\d\d) (\d\d?):(\d\d) (AM|PM)$};

    $year += 2000;
    $hour -= 12 if $ampm eq 'AM' and $hour == 12;
    $hour += 12 if $ampm eq 'PM' and $hour != 12;

    sprintf '%04d-%02d-%02dT%02d:%02d',
            $year, $mon, $mday,
            $hour, $min;
}

sub game_result {
    my $result = shift;

    return 'W+Resign' if $result eq 'W+Res.';
    return 'B+Resign' if $result eq 'B+Res.';
    return 'W+Forfeit' if $result eq 'W+Forf.';
    return 'B+Forfeit' if $result eq 'B+Forf.';
    return 'Draw' if $result eq 'Jigo';

    $result;
}

1;
