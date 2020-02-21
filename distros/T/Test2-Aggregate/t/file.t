BEGIN {
    use Test2::V0;
    use File::Path;
    use Symbol ();
    no warnings 'redefine';

    *File::Path::mkpath = sub {
        my @created = mkpath($_[0]);
        return $_[0] =~ /T2A/ ? () : @created;
    };
    *CORE::GLOBAL::open = sub (*;$@) {
        if (defined $_[0]) {
            my $x = shift;
            unshift @_, Symbol::qualify($x, scalar caller);
        }
        return CORE::open($_[0]) if @_ == 1;
        return CORE::open($_[0], $_[1]) if @_ == 2;
        my $res;
        $res = CORE::open($_[0], $_[1], $_[2]) if @_ == 3 && defined $_[2];
        $res = CORE::open($_[0], $_[1], undef) if @_ == 3;
        $res = CORE::open($_[0], $_[1], @_[2..$#_]);
        return $_[2] =~ /T2A/ ? 0 : $res;
    };
}

use Test2::Aggregate;

use File::Temp;

my $root   = (grep {/^\.$/i} @INC) ? undef : './';
my $tmpdir = File::Temp->newdir;

like(
    warnings {
        Test2::Aggregate::run_tests(
            dirs         => ['xt/aggregate/check_env.t'],
            root         => $root,
            stats_output => "$tmpdir/T2A"
        );
    },
    [qr/Could not create/],
    'Single warning for failing to create dir.'
);

eval {
    Test2::Aggregate::run_tests(
        dirs         => ['xt/aggregate/check_env.t'],
        root         => $root,
        stats_output => "$tmpdir/T2A"
    );
};

like( $@, qr/Can't open/, "Got exception for open file" );


done_testing;
