#!perl
use warnings;
use strict;
use t::Utils;

for my $mod (qw(DBD::Pg TAP::Harness IO::String)) {
    eval "require $mod";
    plan skip_all => "this test requires $mod" if $@;
}

$ENV{TSM_TEST_PG} = 1;

test_setup: {
    eval {
        run_test { 
            my $dbh = shift;
            die "can't ping" unless $dbh->ping;
            diag "Connected to postgres ".$dbh->pg_server_version;
        };
    };
    if ($@) {
        if ($@ =~ /^SETUP:/) {
            diag $@;
            plan skip_all => 'cannot set-up postgres database';
        }
        else {
            die $@;
        }
    }
}

my @tests;
read_tests: {
    opendir my $dir, 't' or plan skip_all => "can't open test dir: $!";
    for my $t (<t/*.t>) {
        next if $t eq 't/999_postgres.t';
        next unless $t =~ /\d/; # skips POD, boilerplate, etc.
        push @tests, $t;
    }
    closedir $dir;
}

plan tests => scalar @tests;

my $th = TAP::Harness->new({
    formatter_class => 'TAP::Formatter::NULL',
    verbosity => 1,
    callbacks => {
        after_test => sub { 
            my ($job_as_array, $parser) = @_;
            ok(!$parser->has_problems, "Pg re-test for $job_as_array->[1]");
            if ($parser->has_problems) {
                diag "Try running $job_as_array->[0] with TSM_TEST_PG=1";
            }
        },
    },
});
$th->runtests(@tests);

{
    package TAP::Formatter::NULL;
    use base 'TAP::Formatter::Console';

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->stdout(IO::String->new);
        return $self;
    }
}

