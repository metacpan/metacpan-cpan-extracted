package main;

use 5.010;

use strict;
use warnings;

use CPAN::Meta;
use Test::More 0.88;	# Because of done_testing();
use Test::Prereq::Meta;

{
    my $rslt;

    TODO: {
	local $TODO = 'Deliberately-failing test';
	$rslt = Test::Prereq::Meta->new(
	    meta_file	=> 't/data/accept/META.json',
	    name	=> 'Unlisted prereq: %f uses %m',
	)->all_prereq_ok( 't/data/accept/lib' );
    }

    ok( ! $rslt, 'Got failure when expected' );
}

note( <<'EOD' );

The following test should actually generate a skip, but we have no way
to detect this externally. All we know for sure is whether any failing
tests were generated.
EOD

Test::Prereq::Meta->new(
    meta_file	=> 't/data/accept/META.json',
    name	=> 'Unlisted prereq: %f uses %m',
    prune	=> 't/data/accept/lib',
)->all_prereq_ok( 't/data/accept/lib' );

Test::Prereq::Meta->new(
    meta_file	=> 't/data/accept/META.json',
    name	=> 'Unlisted core prereq: %f uses %m',
    perl_version	=> 'this',
)->all_prereq_ok( 't/data/accept/lib' );

Test::Prereq::Meta->new(
    meta_file	=> CPAN::Meta->load_file( 't/data/accept/META.json' ),
    name	=> 'Prereq via CPAN::Meta object: %f uses %m',
    perl_version	=> 'this',
)->all_prereq_ok( 't/data/accept/lib' );

Test::Prereq::Meta->new(
    accept	=> [ qw{ strict } ],
    meta_file	=> 't/data/accept/META_NO_PROVIDES.json',
    name	=> 'No provides: %f uses %m',
)->all_prereq_ok( 't/data/accept/lib' );

Test::Prereq::Meta->new(
    accept	=> [ qw{ strict } ],
    meta_file	=> [ qw{
	t/data/accept/some-non-existent-file.yml
	t/data/accept/META.json
	} ],
    name	=> 'Unlisted-but-accepted prereq: %f uses %m',
)->all_prereq_ok( 't/data/accept/lib' );

Test::Prereq::Meta::file_prereq_ok( 't/data/rogue_require' );

{
    my $builder = Test::More->builder();
    my $diag;
    $builder->failure_output( \$diag );
    Test::Prereq::Meta->new(
	accept	=> [ qw{ CPAN::Meta } ],
	uses	=> [ qw{ CPAN::Meta } ],
	verbose	=> 1,
    );
    $builder->reset_outputs();
    is $diag, <<'EOD', 'Got diagnostic on duplicate accept and uses';
# The following module appears in both the prerequisites and
# the 'accept' argument: CPAN::Meta
# The following module appears in both the 'accept' argument and
# the 'uses' argument: CPAN::Meta
EOD
}

{
    my $builder = Test::More->builder();
    my $tpm = Test::Prereq::Meta->new(
	meta_file	=> 't/data/accept/META_WITH_STRICT.json',
	name		=> q<Diagnostic on 'uses'>,
	uses		=> [ qw{ strict } ],
	verbose		=> 1,
    );

    $tpm->all_prereq_ok( 't/data/accept/lib' );

    my $diag;
    $builder->failure_output( \$diag );
    $tpm->all_prereqs_used();
    $builder->reset_outputs();
    is $diag, <<'EOD', q<Got diagnostic on 'uses' of actually-used module>;
# The following module appears in both 'use' statements and
# the 'uses' argument: strict
EOD
}

{
    my $tpm = Test::Prereq::Meta->new(
	meta_file	=> 't/data/accept/META_EXTRA_PREREQ.json',
    );

    $tpm->all_prereq_ok( 't/data/accept/lib' );

    my $diag;

    TODO: {
	my $builder = Test::More->builder();
	$builder->todo_output( \$diag );
	local $TODO = 'Deliberately-failing test';
	$tpm->all_prereqs_used();
	$builder->reset_outputs();
    }

    like $diag,
	qr/^# The following prerequisite is unused: Test::More$/sm,
	'Detected unused prerequisite';
}

{
    local $@ = undef;
    my $msg;
    local $SIG{__DIE__} = sub { $msg = $_[0] };
    my $tpm = eval {
	Test::Prereq::Meta->new(
	    fubar	=> 42,
	);
    };
    ok !$tpm, 'new( fubar => 42 ) fails';
    like $msg, qr<\bUnknown argument 'fubar'>, 'Got expected exception';
}

done_testing;

1;

# ex: set textwidth=72 :
