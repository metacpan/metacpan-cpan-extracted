#!perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib '.';
use t::test_server;

if (defined (my $msg = t::test_server::check_requires())) {
    plan skip_all => $msg;
}

# Do we have MongoDB module installed?
eval qq{
    use MongoDB;
};
if ($@) {
    plan skip_all => 'MongoDB.pm not installed';
}
else {
    diag 'MongoDB (lib) ' . MongoDB->VERSION;
}

# Do we have Time::Moment installed?
eval qq{
    use Time::Moment;
};
if ($@) {
    plan skip_all => 'Time::Moment not installed';
}
else {
    diag 'Time::Moment ' . Time::Moment->VERSION;
}

t::test_server::start_server();

my $ini = {
    MongoDB => {
        host_uri => $ENV{MONGODB_HOST_URI} || 'mongodb://localhost',
    },
    Session => {
        mode           => 'http',
        dbgroup        => 'MongoDB',
        session_ns     => 'test.TripletaiL_Session_Test',
        csrfkey        => 'TripletaiL_Key',
        updateinterval => '0sec'
    },
};

# Do we actually have a connection? If not skip all the tests.
my $buildInfo = eval {
    my $script = q{
        my $client = $TL->getMongoDB->getClient;
        my $db     = $client->get_database('test');

        return $db->run_command([ buildInfo => 1 ]);
    };
    t::test_server::request_get(
        ini     => $ini,
        mongodb => 'MongoDB',
        script  => $script
       );
};
if ($@) {
    plan skip_all => $@;
}
else {
    diag 'MongoDB (server) v' . $buildInfo->{version};
    plan tests => 3;
}

sub rget ($) {
    return t::test_server::request_get(
        script  => shift,
        mongodb => 'MongoDB',
        session => 'Session',
       );
}

subtest 'basic' => sub {
    plan tests => 8;

    lives_ok  { rget q{ $TL->getSession }              } '$TL->getSession';
    lives_and { ok !rget q{ $TL->getSession->isHttps } } '!isHttps';

    lives_and {
        my ($fst, $snd) = @{
            rget q{
                my $s   = $TL->getSession;
                my $fst = $s->get;
                my $snd = $s->get;
                return [$fst, $snd];
            };
        };
        note "sid = $fst";
        is $fst, $snd;
    } 'session ID is persistent';

    lives_and {
        my ($fst, $snd) = @{
            rget q{
                my $s   = $TL->getSession;
                my $fst = $s->get;
                my $snd = $s->renew;
                return [$fst, $snd];
            };
        };
        isnt $fst, $snd;
    } 'session ID changes after renewing it';

    lives_and {
        my ($fst, $snd) = @{
            rget q{
                my $s   = $TL->getSession;
                my $fst = $s->get;
                $s->discard;
                my $snd = $s->get;
                return [$fst, $snd];
            };
        };
        isnt $fst, $snd;
    } 'session ID changes after discarding it';

    lives_and {
        my $val = rget q{
            my $s = $TL->getSession;
            return $s->getValue;
        };
        is $val, undef;
    } 'session value is initially undef';

    my $OID = MongoDB::OID->new->to_string;
    lives_and {
        my $val = rget qq{
            my \$s = \$TL->getSession;
            \$s->setValue('$OID');
            return \$s->getValue;
        };
        is $val, $OID;
    } 'setValue followed by getValue';

    lives_and {
        my $val = rget q{
            my $s = $TL->getSession;
            return $s->getValue;
        };
        is $val, $OID;
    } 'session value is persistent';
};

subtest 'form' => sub {
    plan tests => 1;

    lives_and {
        my $val = rget q{
            my $t = $TL->newTemplate->setTemplate(q{
                <form name="TEST" method="post">
                </form>
            });
            $t->addSessionCheck('Session', 'TEST');

            my $form = $t->getForm('TEST');
            $form->haveSessionCheck('Session');
        };
        ok $val;
    } 'addSessionCheck/haveSessionCheck w/ form name';
};

subtest 'misc' => sub {
    plan tests => 1;

    lives_ok {
        rget q{
            my $s = $TL->getSession;
            [$s->getSessionInfo];
        };
    } 'getSessionInfo';
};
