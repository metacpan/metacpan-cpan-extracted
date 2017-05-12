
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ( $app ) = @_;
        my $r = $app->routes;
        $r->get( '/data.html' )
          ->to( cb => sub {
            $_[0]->render(
                text => join( '',
                    '<div id="foo" class="item">foo<span>!</span></div>',
                    '<div id="bar" class="item">bar<span>!</span></div>',
                    '<div id="baz" class="item">baz<span>!</span></div>',
                ),
            );
          } );
        $r->get( '/data.json' )
          ->to( cb => sub {
            $_[0]->render(
                json => {
                    foo => [ 1, 2, 3 ],
                    bar => {
                        baz => [ 7, 8, 9 ]
                    }
                }
            );
        } );
    }
}

use Test::Mojo::WithRoles 'TestDeep';
use Test::Deep;
use Scalar::Util qw( refaddr );
my $t = Test::Mojo::WithRoles->new( 'MyApp' );

subtest 'json_deeply' => sub {
    ok $t->can( 'json_deeply' ), 'the method was installed';

    subtest 'one-arg: test only' => sub {
        my $test = {
            foo => bag( 3, 2, 1 ),
            bar => superhashof({
                baz => bag( 9, 8, 7 ),
            }),
        };

        my $retval = $t->get_ok( '/data.json' )->json_deeply( $test );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'two-arg with reference first: test with description' => sub {
        my $test = {
            foo => bag( 3, 2, 1 ),
            bar => superhashof({
                baz => bag( 9, 8, 7 ),
            }),
        };

        my $retval = $t->get_ok( '/data.json' )->json_deeply( $test, 'description' );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'two-arg with reference second: json pointer' => sub {
        my $test = bag( 3, 2, 1 );
        my $retval = $t->get_ok( '/data.json' )->json_deeply( '/foo' => $test );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'two-arg without reference: error, ambiguous' => sub {
        throws_ok { $t->get_ok( '/data.json' )->json_deeply( '/foo/0' => 1 ) }
            qr{\Qexpected value should be a data structure or Test::Deep test object, not a simple scalar (did you mean to use json_is()?)};
    };

    subtest 'three-arg: json pointer and desc' => sub {
        my $test = bag( 3, 2, 1 );
        my $retval = $t->get_ok( '/data.json' )->json_deeply( '/foo' => $test, 'description' );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };
};

subtest 'text_deeply' => sub {
    subtest 'with description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->text_deeply( 'div', [qw( foo bar baz )], 'items are correct' );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'without description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->text_deeply( 'div', [qw( foo bar baz )] );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };
};

subtest 'all_text_deeply' => sub {
    subtest 'with description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->all_text_deeply( 'div', [qw( foo! bar! baz! )], 'items are correct' );
        is refaddr $retval, refaddr $t, 'return value is test object';
        ok $t->success, 'last test was successful';
    };

    subtest 'without description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->all_text_deeply( 'div', [qw( foo! bar! baz! )] );
        is refaddr $retval, refaddr $t, 'return value is test object';
        ok $t->success, 'last test was successful';
    };
};

subtest 'attr_deeply' => sub {
    subtest 'one test with description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->attr_deeply(
              '[id]',
              id => [qw( foo bar baz )],
              'ids are correct',
          );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'two tests with description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->attr_deeply(
              'div',
              id => [qw( foo bar baz )],
              class => array_each( 'item' ),
              'div attributes are correct',
          );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'one test without description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->attr_deeply(
              '[id]',
              id => [qw( foo bar baz )],
          );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };

    subtest 'two tests without description' => sub {
        my $retval = $t->get_ok( '/data.html' )
          ->attr_deeply(
              'div',
              id => [qw( foo bar baz )],
              class => array_each( 'item' ),
          );
        is refaddr $retval, refaddr $t;
        ok $t->success, 'last test was successful';
    };
};

done_testing;
