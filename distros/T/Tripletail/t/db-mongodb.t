#!perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib '.';
use constant MAX_RETRIES => 5;
use t::make_ini {
    ini => {
        TL => {
            trap => 'none',
        },
        MongoDB => {
            host_uri           => $ENV{MONGODB_HOST_URI} || 'mongodb://localhost',
            max_retries        => MAX_RETRIES,
            min_retry_interval => 100,
            max_retry_interval => 150,
        },
    },
};
use Tripletail $t::make_ini::INI_FILE;

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

# Can we connect to the server?
eval {
    local $SIG{__DIE__} = 'DEFAULT';
    $TL->trapError(
        -MongoDB => 'MongoDB',
        -main    => sub {
            my $db = $TL->getMongoDB->getClient->get_database('test');
            $db->run_command([ ping => 1 ]);
        }
       );
};
if ($@) {
    plan skip_all => "Failed to connect to database: $@";
}

plan tests => 3;

subtest 'getMongoDB' => sub {
    plan tests => 3;

    dies_ok {
        $TL->getMongoDB;
    } '$TL->getMongoDB without startCgi / trapError';

    $TL->trapError(
        -MongoDB => 'MongoDB',
        -main    => sub {
            lives_and {
                isa_ok $TL->getMongoDB, 'Tripletail::MongoDB';
            } 'getMongoDB in trapError';
        });

    $TL->startCgi(
        -MongoDB => 'MongoDB',
        -main    => sub {
            isa_ok $TL->getMongoDB, 'Tripletail::MongoDB', 'getMongoDB in startCgi';
            $TL->setContentFilter('t::filter_null');
            $TL->print('dummy');
        });
};

subtest 'getClient' => sub {
    plan tests => 1;

    $TL->trapError(
        -MongoDB => 'MongoDB',
        -main    => sub {
            my $DB = $TL->getMongoDB;

            lives_and {
                isa_ok $DB->getClient, 'MongoDB::MongoClient',
                  'getClient returns the client object';
            };
        });
};

subtest 'do' => sub {
    plan tests => 4;

    $TL->trapError(
        -MongoDB => 'MongoDB',
        -main    => sub {
            my $DB = $TL->getMongoDB;

            lives_and {
                my $ret = $DB->do(
                    sub {
                        my $client = shift;
                        $client->get_database('test')->run_command([ ping => 1 ]);
                    });
                is $ret->{ok}, 1;
            } 'successful ping';

            lives_ok {
                my $n = 3;
                $DB->do(
                    sub {
                        if ($n == 0) {
                            return;
                        }
                        else {
                            $n--;
                            MongoDB::NetworkError->throw;
                        }
                    });
            } 'success after 3 retries';

            subtest 'immediate failure' => sub {
                plan tests => 3;

                my $n = 0;
                dies_ok {
                    $DB->do(
                        sub {
                            $n++;
                            MongoDB::UsageError->throw();
                        });
                } 'usage error';
                isa_ok $@, 'MongoDB::UsageError';
                is $n, 1, 'it was indeed immediate';
            };

            subtest 'too many retries' => sub {
                plan tests => 3;

                my $n = 0;
                dies_ok {
                    $DB->do(
                        sub {
                            $n++;
                            MongoDB::NetworkError->throw();
                        });
                } 'network error';
                isa_ok $@, 'MongoDB::NetworkError';
                is $n, MAX_RETRIES + 1, 'it was indeed too many';
            };
        });
};
