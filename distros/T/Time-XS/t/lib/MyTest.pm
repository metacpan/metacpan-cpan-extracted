package MyTest;
use 5.012;
use Config;
use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, 'en_US.UTF-8');
use Test::Catch;

our @import_list;

use Time::XS(@import_list = qw/
    tzset tzget tzname tzdir gmtime localtime timegm timegmn timelocal timelocaln
    available_zones use_embed_zones use_system_zones
/);

XS::Loader::load();

use_embed_zones();
tzset('Europe/Moscow');

sub import {
    no strict 'refs';
    my $caller = caller();
    *{"${caller}::$_"} = *$_ for @import_list, qw/systimelocal get_dates lt2tl get_row_tl epoch_from leap_zones_dir/;
}

sub get_dates {
    my $file = 't/data/'.shift().'.txt';
    open my $fh, '<', $file or die "Cannot open test data file '$file': $!";
    <$fh>; # skip stat line
    local $/ = undef;
    my $content = <$fh>;
    our $VAR1;
    my $ret = eval $content;
    die $@ unless $ret;
}

sub get_row_tl {
    my $row = shift;
    return lt2tl(@{$row->[1]});
}

sub lt2tl { return @_[0..5,8]; }

sub epoch_from {
    die "cant parse date" unless $_[0] =~ /^(-?\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
    my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    return timegm($sec, $min, $hour, $mday, $mon-1, $year);
}

sub leap_zones_dir { return tzdir().'/right' }

1;
