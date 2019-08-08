package TestAllZones;
use 5.012;
use MyTest;
use Test::More;

plan skip_all => 'set TEST_FULL=1 to enable real test coverage' unless $ENV{TEST_FULL};

use_system_zones();

# this OS have bugs in localtime/timelocal implementations which prevent them from working correctly with listed time zones
# in our time periods
my %buggy_zones = map {$_ => 1} qw#
    America/Anchorage Australia/Lord_Howe America/Scoresbysund America/Nome Asia/Choibalsan Asia/Ust-Nera Asia/Tehran posix/Iran posix/Asia/Tehran Iran 
#;

my @dias;
# check past
push @dias, [3599, "1980-01-01 00:00:00", "1986-01-01 00:00:00"];
# check transitions
push @dias, [3599, "2000-01-01 00:00:00", "2006-01-01 00:00:00"];
# check near future
push @dias, [3599, "2016-01-01 00:00:00", "2022-01-01 10:00:00"];
# check far future
push @dias, [3599, "2060-01-01 00:00:00", "2066-01-01 10:00:00"];

sub go {
    my $curt = $0;
    $curt =~ /zones-(\d+)\.t/ or die "should not happen";
    my $initial = $1;
    
    my $dir = $curt;
    $dir =~ s#[^\\/]+$##;
    my @files = glob($dir.'zones-*.t');
    my $numt = @files;
    
    my @zones = sort {$a cmp $b} grep { !/^posix/ && !$buggy_zones{$_} } available_zones();

    $DB::single=1;
    
    for (my $i = $initial - 1; $i < @zones; $i += $numt) {
        my $zone = $zones[$i];
        $ENV{TZ} = $zone;
        tzset();
        POSIX::tzset();
        say "CHECKING $zone" unless $ENV{HARNESS_ACTIVE};
        
        foreach my $fname (qw/test_localtime test_timelocal/) {
            no strict 'refs';
            say "  CHECKING $fname" unless $ENV{HARNESS_ACTIVE};
            my $func = MyTest->can($fname);
            foreach my $dia (@dias) {
                my ($step, $from, $till) = @$dia;
                my $from_epoch = epoch_from($from);
                my $till_epoch = epoch_from($till);
                next if $zone =~ /^right/ and $till_epoch > 2100000000; # skip testing future in leap second zones (OS has bugs)
                my $ok = $func->($step, $from_epoch, $till_epoch);
                ok($ok);
            }
        }
    }
}

1;