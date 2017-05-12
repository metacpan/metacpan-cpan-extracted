#!perl
use strict;
use warnings;
use Data::Dumper ();
use Digest::SHA qw(sha256);
use MIME::Base64 qw(decode_base64);
use Test::Exception;
use Test::More tests => 5;
use constant {
      CORRECT_CRYPTO_KEY => '(」・ω・)」うー！(／・ω・)／にゃー！',
      WRONG_CTYPTO_KEY   => '(「・ω・)「'
  };
use t::make_ini {
    ini => {
        Cookie => {
            format    => 'modern',
            cryptokey => CORRECT_CRYPTO_KEY
           }
       }
  };
use Tripletail $t::make_ini::INI_FILE;

do {
    my $legacy = $TL->newSerializer({-type => 'legacy'});
    my $modern = $TL->newSerializer({-type => 'compat'})
                    ->setCryptoKey(sha256(CORRECT_CRYPTO_KEY));
    my $wrong  = $TL->newSerializer({-type => 'compat'})
                    ->setCryptoKey(sha256(WRONG_CTYPTO_KEY));
    my $plain  = $TL->newSerializer({-type => 'compat'});
    my %cookies = (
        # Legacy
        foo => $legacy->serialize({aaa => [111]}),
        # Modern (encrypted)
        bar => $modern->serialize({aaa => [333]}),
        # Modern (encrypted with a wrong key)
        baz => $wrong->serialize({aaa => [555]}),
        # Modern (plain)
        qux => $plain->serialize({aaa => [777]})
       );
    $ENV{HTTP_COOKIE} = join('; ', map {"$_=$cookies{$_}"} keys %cookies);
};

$TL->startCgi(
    -main => sub {
        my $c = $TL->getCookie;

        subtest 'reading legacy cookies' => sub {
            plan tests => 2;

            lives_and {
                my $f = $c->get('foo');
                is $f->get('aaa'), '111';
            };

            lives_ok {
                $c->set(foo => $c->get('foo')->set(aaa => 333));
            };
        };

        subtest 'reading encrypted modern cookies' => sub {
            plan tests => 2;

            lives_and {
                my $f = $c->get('bar');
                is $f->get('aaa'), '333';
            };

            lives_ok {
                $c->set(bar => $c->get('bar')->set(aaa => 444));
            };
        };

        subtest 'reading encrypted modern cookies with a wrong key' => sub {
            plan tests => 1;

            lives_and {
                is_deeply $c->get('baz')->toHash, {};
            } 'raises no error';
        };

        subtest 'reading plain modern cookies with a key' => sub {
            plan tests => 1;

            lives_and {
                is_deeply $c->get('qux')->toHash, {};
            } 'raises no error';
        };

        subtest 'writing modern cookies' => sub {
            plan tests => 6;

            my @set;
            lives_ok {
                @set = reverse sort $c->_makeSetCookies;
            };

            is scalar(@set), 2;
            like $set[0], qr{\Afoo=[A-Za-z0-9+/!=]+\z};
            like $set[1], qr{\Abar=[A-Za-z0-9+/!=]+\z};

            my $modern = $TL->newSerializer
                            ->setCryptoKey(sha256(CORRECT_CRYPTO_KEY));
            lives_and {
                is_deeply(
                    $modern->deserialize(decode_base64((split /=/, $set[0], 2)[1])),
                    {aaa => [333]}
                   );
            };
            lives_and {
                is_deeply(
                    $modern->deserialize(decode_base64((split /=/, $set[1], 2)[1])),
                    {aaa => [444]}
                   );
            };
        };
    });
