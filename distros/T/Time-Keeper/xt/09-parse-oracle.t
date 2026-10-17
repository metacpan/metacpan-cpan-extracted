#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Piece ();

# Parsing against the parsers that are installed. Author only.
use Time::Keeper;

my $K = 'Time::Keeper';
srand(909);

# Time::Piece's strptime, on strings written in eight patterns.
{
    my @pats = ('%Y-%m-%d %H:%M:%S', '%d/%m/%Y %H:%M', '%a, %d %b %Y %H:%M:%S', '%Y%m%d%H%M%S',
                '%j %Y %T', '%b %e %Y %I:%M:%S %p', '%D %R', '%s');
    my ($n, $bad) = (0, 0);
    for (1 .. 3000) {
        my $s = int(rand(3_000_000_000)) + 100_000_000;
        my $gm = Time::Piece::gmtime($s);
        for my $p (@pats) {
            my $str = $gm->strftime($p);
            my $tp = eval { Time::Piece->strptime($str, $p) } or next;
            my $mine = eval { $K->strptime($str, $p) };
            $n++;
            next if $mine && $mine->epoch == $tp->epoch;
            diag("'$str' as '$p': Time::Piece " . $tp->epoch . ', here ' . ($mine ? $mine->epoch : "died: $@")) if $bad < 5;
            $bad++;
        }
    }
    is($bad, 0, "$n strings read as Time::Piece's strptime reads them");
}

SKIP: {
    skip 'DateTime::Format::Mail is not installed', 1 unless eval { require DateTime::Format::Mail; 1 };
    my $mail = DateTime::Format::Mail->new(loose => 1);
    my @zones = qw(+0000 -0500 +0530 -0330 +1245 GMT UT EST EDT CST CDT MST MDT PST PDT);
    my ($n, $bad) = (0, 0);
    for (1 .. 5000) {
        my $s = int(rand(3_000_000_000)) + 100_000_000;
        my $gm = Time::Piece::gmtime($s);
        my $z = $zones[int rand @zones];
        my $str = $gm->strftime('%a, %d %b %Y %H:%M:%S ') . $z;
        $str =~ s/^\w+, // if rand() < .3;
        my $dt = eval { $mail->parse_datetime($str) } or next;
        my $mine = eval { $K->parse($str) };
        $n++;
        next if $mine && $mine->epoch == $dt->epoch && $mine->offset == $dt->offset;
        diag("'$str': DateTime::Format::Mail " . $dt->epoch . ' ' . $dt->offset . ', here ' . ($mine ? $mine->epoch . ' ' . $mine->offset : "died: $@")) if $bad < 5;
        $bad++;
    }
    is($bad, 0, "$n mail dates read as DateTime::Format::Mail $DateTime::Format::Mail::VERSION reads them");
}

done_testing;
