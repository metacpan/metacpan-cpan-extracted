#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Test::More;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/lib};
    use Zucchini::TestConfig;
}

BEGIN {
    use File::Temp qw(tempdir);
    use_ok 'Zucchini::Rsync';
}

can_ok(
    'Zucchini::Rsync',
    qw(
        new
        get_config
        set_config
        remote_sync
    )
);

# evil globals
my ($zucchini_rsync, $test_config);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});

# just create a ::Rsync object
$zucchini_rsync = Zucchini::Rsync->new(
    {
        config => $test_config->get_config,
    }
);
isa_ok($zucchini_rsync, q{Zucchini::Rsync});
ok(defined($zucchini_rsync->get_config), q{object has configuration data});

$zucchini_rsync->get_config->set_options(
    {
        verbose => 3,
    }
);

=for future testing

# only do the rsync if we don't (appear to) require a password
eval {
    local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
    alarm 5;
    $zucchini_rsync->remote_sync();
    alarm 0;
};

SKIP: {
    skip
        q{remote_sync() taking too long; assuming stuck at password prompt}, 1
            if (my $e = $@);

    TODO: {
        local $TODO = q{Write directory comparison test};
        ok(0, q{compare directories});
    };
};

# it would be nice to reset the terminal/STDOUT if we triggered the alarm

=cut

done_testing;
