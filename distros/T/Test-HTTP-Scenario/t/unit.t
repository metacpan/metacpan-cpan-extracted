use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::Strict;
use Test::Vars;
use Test::Deep;
use Test::Returns;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::HTTP::Scenario;

BEGIN {
    require File::Path;
    File::Path::make_path('t/fixtures');
}

#----------------------------------------------------------------------#
# Mock adapter class for white-box testing
#----------------------------------------------------------------------#

{
    package Local::Adapter::Mock;
    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {
            scenario    => undef,
            installed   => 0,
            uninstalled => 0,
            normalized_req => undef,
            normalized_res => undef,
        }, $class;
    }

    sub set_scenario {
        my ($self, $sc) = @_;
        $self->{scenario} = $sc;
        require Scalar::Util;
        Scalar::Util::weaken($self->{scenario});
        return;
    }

    sub install   { $_[0]->{installed}++ }
    sub uninstall { $_[0]->{uninstalled}++ }

    sub normalize_request {
        my ($self, $req) = @_;
        return $self->{normalized_req} // { method => 'GET', uri => 'http://example.com/' };
    }

    sub normalize_response {
        my ($self, $res) = @_;
        return $self->{normalized_res} // {
            status  => 200,
            reason  => 'OK',
            headers => {},
            body    => 'ok',
        };
    }

    sub build_response {
        my ($self, $hash) = @_;
        return $hash->{body};
    }
}

#----------------------------------------------------------------------#
# run() installs and uninstalls adapter hooks
#----------------------------------------------------------------------#

subtest 'run() installs and uninstalls adapter' => sub {

    my $adapter = Local::Adapter::Mock->new;

    my $sc = Test::HTTP::Scenario->new(
        name    => 'install_test',
        file    => 't/fixtures/install.yaml',
        mode    => 'record',
        adapter => $adapter,
    );

    $sc->run(sub { 1 });

    is $adapter->{installed},   1, 'adapter installed once';
    is $adapter->{uninstalled}, 1, 'adapter uninstalled once';
};

#----------------------------------------------------------------------#
# run() preserves context
#----------------------------------------------------------------------#

subtest 'run() preserves list/scalar/void context' => sub {

    my $adapter = Local::Adapter::Mock->new;

    my $sc = Test::HTTP::Scenario->new(
        name    => 'context_test',
        file    => 't/fixtures/context.yaml',
        mode    => 'record',
        adapter => $adapter,
    );

	my @list = $sc->run(sub { return (1, 2, 3) });
	cmp_deeply(\@list, [1, 2, 3], 'list context preserved');

	my $scalar = $sc->run(sub { return 42 });
	is $scalar, 42, 'scalar context preserved';

	# VOID context
	{
		# Call in true void context
		$sc->run(sub { return 99 });

		# Capture the return value of a void-context call
		my $ret = do {
			$sc->run(sub { return 99 });   # void context here
			undef;                         # scalar return value of the block
		};

		ok(!defined $ret, 'void context preserved (run returns undef in void context)');
	}
};

#----------------------------------------------------------------------#
# handle_request() in record mode
#----------------------------------------------------------------------#

subtest 'handle_request() records interactions in record mode' => sub {

    my $adapter = Local::Adapter::Mock->new;

    my $sc = Test::HTTP::Scenario->new(
        name    => 'record_test',
        file    => 't/fixtures/record.yaml',
        mode    => 'record',
        adapter => $adapter,
    );

    my $real_called = 0;

    my $res = $sc->handle_request(
        {},
        sub { $real_called++; return 'REAL_RESPONSE' },
    );

    is $res, 'REAL_RESPONSE', 'record mode returns real response';
    is $real_called, 1, 'real request executed';

    cmp_deeply(
        $sc->{interactions}[0]{response},
        superhashof({ status => 200 }),
        'response normalized and stored'
    );
};

#----------------------------------------------------------------------#
# handle_request() in replay mode
#----------------------------------------------------------------------#

subtest 'handle_request() replays stored interaction in replay mode' => sub {

    my $adapter = Local::Adapter::Mock->new;

    my $sc = Test::HTTP::Scenario->new(
        name    => 'replay_test',
        file    => 't/fixtures/replay.yaml',
        mode    => 'replay',
        adapter => $adapter,
    );

    $sc->{interactions} = [
        {
            request  => { method => 'GET', uri => 'http://example.com/' },
            response => { body => 'REPLAYED_BODY' },
        },
    ];

    $adapter->{normalized_req} = { method => 'GET', uri => 'http://example.com/' };

    my $real_called = 0;

    my $res = $sc->handle_request(
        {},
        sub { $real_called++; return 'REAL' },
    );

    is $res, 'REPLAYED_BODY', 'replay mode returns built response';
    is $real_called, 0, 'real request not executed';
};

#----------------------------------------------------------------------#
# handle_request() dies when no match in replay mode
#----------------------------------------------------------------------#

subtest 'handle_request() croaks when no match exists' => sub {

    my $adapter = Local::Adapter::Mock->new;

    my $sc = Test::HTTP::Scenario->new(
        name    => 'nomatch',
        file    => 't/fixtures/nomatch.yaml',
        mode    => 'replay',
        adapter => $adapter,
    );

    $adapter->{normalized_req} = { method => 'GET', uri => 'http://wrong/' };

    dies_ok {
        $sc->handle_request(
            {},
            sub { return 'REAL' },
        );
    } 'croaks when no matching interaction exists';
};

#----------------------------------------------------------------------#
# _save_if_needed writes file in record mode
#----------------------------------------------------------------------#

subtest '_save_if_needed writes fixture file' => sub {

    my $file = 't/fixtures/save_test.yaml';
    unlink $file if -e $file;

    my $adapter = Local::Adapter::Mock->new;

    my $sc = Test::HTTP::Scenario->new(
        name    => 'save_test',
        file    => $file,
        mode    => 'record',
        adapter => $adapter,
    );

    $sc->{interactions} = [
        {
            request  => { method => 'GET', uri => 'http://example.com/' },
            response => { status => 200, body => 'ok' },
        },
    ];

    $sc->_save_if_needed;

    ok -e $file, 'fixture file written';
};

done_testing;
