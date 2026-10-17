#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }

# Bytes a value costs: the growth of the process over many values, each made
# in its own fresh process. Devel::Size is reported too where it is
# installed; it is not the mark, because it counts DateTime's locale and zone
# objects, which its values share, in every value.
my $N = $ENV{TK_BENCH_VALUES} // 200_000;
my %make = (
    'Time::Keeper' => 'Time::Keeper->from_epoch(1760000000 + $_, zone => q{America/New_York})',
    'Time::Piece'  => 'Time::Piece::localtime(1760000000 + $_)',
    'DateTime'     => 'DateTime->from_epoch(epoch => 1760000000 + $_, time_zone => $tz)',
);
my %bytes;
for my $m (sort keys %make) {
    my $prog = "use $m; " . ($m eq 'DateTime' ? 'my $tz = DateTime::TimeZone->new(name => q{America/New_York}); ' : '')
             . "my \@warm = map { $make{$m} } 1 .. 100; "
             . 'sub rss { my $r = `ps -o rss= -p $$`; $r =~ s/\s//g; $r * 1024 } '
             . "my \$before = rss(); my \@v = map { $make{$m} } 1 .. $N; print +(rss() - \$before) / $N";
    local $ENV{TZ} = 'America/New_York';
    $bytes{$m} = `"$^X" -Mblib -e '$prog'`;
}
printf "info bytes per value, by RSS over %d: Time::Keeper %.0f, Time::Piece %.0f, DateTime %.0f\n",
    $N, @bytes{qw(Time::Keeper Time::Piece DateTime)};
if (eval { require Devel::Size; require Time::Keeper; require Time::Piece; require DateTime; 1 }) {
    printf "info Devel::Size::total_size: Time::Keeper %d, Time::Piece %d, DateTime %d (with its shared locale and zone)\n",
        Devel::Size::total_size(Time::Keeper->from_epoch(1760000000)), Devel::Size::total_size(scalar Time::Piece::gmtime(1760000000)),
        Devel::Size::total_size(DateTime->from_epoch(epoch => 1760000000));
}
$_ = sprintf('%.0f', $_) for values %bytes;
mark_less('bytes per value', $bytes{'Time::Keeper'}, $bytes{'Time::Piece'}, 1, 'Time::Piece', 'B');
mark_less('bytes per value', $bytes{'Time::Keeper'}, $bytes{DateTime}, 4, 'DateTime', 'B');
done();
