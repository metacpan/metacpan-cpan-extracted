#! perl -w

use strict;
use warnings;
use Test::More;

use Unix::Statgrab;

my $have_test_leak_trace = eval { require Test::LeakTrace; 1 };
$have_test_leak_trace or plan skip_all => "Need Test::LeakTrace";

Test::LeakTrace->import;

my %funcs = (
    get_host_info           => [],
    get_cpu_stats           => [qw/get_cpu_stats_diff get_cpu_percents/],
    get_disk_io_stats       => [qw/get_disk_io_stats_diff/],
    get_fs_stats            => [qw/get_fs_stats_diff/],
    get_load_stats          => [],
    get_mem_stats           => [],
    get_swap_stats          => [],
    get_network_io_stats    => [qw/get_network_io_stats_diff/],
    get_network_iface_stats => [],
    get_page_stats          => [qw/get_page_stats_diff/],
    get_process_stats       => [],
    get_user_stats          => [],
);

my %errs = (
    get_error => [qw/error error_name error_value error_arg strperror/],
);

sub check_accessors
{
    my ( $func, $stat ) = @_;
    Test::LeakTrace::no_leaks_ok(
        sub {
            eval { my $colnames = $stat->colnames(); };
            $@ and warn "$func: " . $@;
        },
        "Unix::Statgrab::${func} doesn't leak"
    );
    my @colnames = @{ $stat->colnames };
    foreach my $cn (@colnames)
    {
        Test::LeakTrace::no_leaks_ok(
            sub {
                eval { my $d = $stat->$cn(); };
            },
            "Unix::Statgrab::${func}::${cn} doesn't leak"
        );
    }
}

sub check_cumulative
{
    my ( $func, $stat ) = @_;
    foreach my $cum (qw(fetchrow_arrayref fetchall_arrayref fetchrow_hashref fetchall_hashref))
    {
        Test::LeakTrace::no_leaks_ok(
            sub {
                eval { my $d = $stat->$cum(); };
            },
            "Unix::Statgrab::${func}::${cum} doesn't leak"
        );
    }
    foreach my $cum (qw(fetchall_hash fetchall_array fetchall_table))
    {
        Test::LeakTrace::no_leaks_ok(
            sub {
                eval { my @d = $stat->$cum(); };
            },
            "Unix::Statgrab::${func}::${cum} doesn't leak"
        );
    }
}

sub check_func
{
    my $func = shift;
  SKIP:
    {
        my $sub = Unix::Statgrab->can($func);
        $sub or skip( "Unix::Statgrab cannot $func", 2 );
        Test::LeakTrace::no_leaks_ok(
            sub {
                eval {
                    my $current = $sub->();
                    $current or do { my $e = get_error(); diag( $e->strperror() ); croak( $e->strperror() ); } while (0);
                };
                $@ and warn "$func: " . $@;
            },
            "Unix::Statgrab::${func} doesn't leak"
        );
        my $stat = eval { $sub->(); };
        $@ and skip "$func: " . $@, 1;
        $stat or do { my $e = get_error(); skip "$func: " . $e->strperror(), 1 } while (0);
        check_accessors( $func, $stat );
        check_cumulative( $func, $stat );
      SKIP:
        foreach my $below ( @{ $funcs{$func} } )
        {
            my @args;
            $below =~ m/_diff$/ and push @args, $sub->();
            my $bs = eval { $stat->$below(@args); };
            $@ and skip "$below: $@", 1;
            $bs or do { my $e = get_error(); skip "$func: " . $e->strperror(), 1 } while (0);
            ok( $bs, "Unix::Statgrab::${func}::${bs}" );
            check_accessors( $below, $bs );
            check_cumulative( $below, $bs );
        }
    }
}

foreach my $func ( sort keys %funcs )
{
    check_func($func);
}

# XXX check get_error

done_testing;
