
=head1 DESCRIPTION

This tests the Zapp::Task::Request class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Loader qw( data_section );
use Mojo::DOM;

my $t = Test::Zapp->new;

# Add some test endpoints
my ( $last_request, $redirect_request );
$t->app->routes->any( '/test/success' )
  ->to( cb => sub( $c ) {
    $last_request = $c->tx->req;
    $c->res->headers->content_type( 'text/plain' );
    $c->render( text => 'Success' );
  } );
$t->app->routes->any( '/test/unauthorized' )
  ->to( cb => sub( $c ) {
    $last_request = $c->tx->req;
    $c->res->headers->content_type( 'text/plain' );
    $c->res->code( 401 );
    $c->render( text => 'You are not authorized' );
  } );
$t->app->routes->any( '/test/json' )
  ->to( cb => sub( $c ) {
    $last_request = $c->tx->req;
    $c->res->headers->content_type( 'application/json' );
    $c->render( json => { status => 'Success' } );
  } );
$t->app->routes->any( '/test/file' )
  ->to( cb => sub( $c ) {
    $last_request = $c->tx->req;
    $c->res->headers->content_type( 'application/octet-stream' );
    $c->render( data => 'Success' );
  } );
$t->app->routes->any( '/test/file/attachment' )
  ->to( cb => sub( $c ) {
    $last_request = $c->tx->req;
    $c->res->headers->content_type( 'application/octet-stream' );
    $c->res->headers->content_disposition( 'attachment; filename="test-file-filename.txt"' );
    $c->render( data => 'Success' );
  } );
$t->app->routes->any( '/test/redirect' )
  ->to( cb => sub( $c ) {
    $last_request = $redirect_request = $c->tx->req;
    $c->redirect_to( '/test/success' );
  } );

subtest 'run' => sub {
    $t->run_task(
        'Zapp::Task::Request' => {
            method => 'GET',
            url => $t->ua->server->url->path( '/test/success' ),
        },
        'Request: Success',
    );
    $t->task_info_is( state => 'finished' );
    $t->task_output_is({
        is_success => 1,
        code => 200,
        message => 'OK',
        body => 'Success',
        headers => {
            content_type => 'text/plain',
        },
    });
};

subtest 'json response' => sub {
    $t->run_task(
        'Zapp::Task::Request' => {
            method => 'GET',
            url => $t->ua->server->url->path( '/test/json' ),
        },
        'Request: JSON',
    );
    $t->task_info_is( state => 'finished' );
    $t->task_output_is({
        is_success => 1,
        code => 200,
        message => 'OK',
        json => { status => 'Success' },
        headers => {
            content_type => 'application/json',
        },
    });
};

subtest 'file response' => sub {
    $t->run_task(
        'Zapp::Task::Request' => {
            method => 'GET',
            url => $t->ua->server->url->path( '/test/file' ),
        },
        'Request: File',
    );
    my $job_id = $t->{zapp}{job}->id;
    $t->task_info_is( state => 'finished' );
    $t->task_output_is({
        is_success => 1,
        code => 200,
        message => 'OK',
        file => "/task/request/$job_id/file",
        headers => {
            content_type => 'application/octet-stream',
        },
    });

    subtest 'with content-disposition' => sub {
        $t->run_task(
            'Zapp::Task::Request' => {
                method => 'GET',
                url => $t->ua->server->url->path( '/test/file/attachment' ),
            },
            'Request: File w/ Content-Disposition',
        );
        my $job_id = $t->{zapp}{job}->id;
        $t->task_info_is( state => 'finished' );
        $t->task_output_is({
            is_success => 1,
            code => 200,
            message => 'OK',
            file => "/task/request/$job_id/test-file-filename.txt",
            headers => {
                content_type => 'application/octet-stream',
            },
        });
    };
};

subtest 'json request' => sub {
    subtest 'json string' => sub {
        $t->run_task(
            'Zapp::Task::Request' => {
                method => 'POST',
                url => $t->ua->server->url->path( '/test/json' ),
                content_type => 'application/json',
                body => {
                    json => '["foo","bar","baz"]',
                },
            },
        );
        is_deeply $last_request->json, [qw( foo bar baz )], 'request body is correct';
    };

    subtest 'json data structure' => sub {
        $t->run_task(
            'Zapp::Task::Request' => {
                method => 'POST',
                url => $t->ua->server->url->path( '/test/json' ),
                content_type => 'application/json',
                body => {
                    json => [qw( foo bar baz )],
                },
            },
        );
        is_deeply $last_request->json, [qw( foo bar baz )], 'request body is correct';
    };
};

subtest 'auth' => sub {
    subtest 'bearer' => sub {
        subtest 'success' => sub {
            $t->run_task(
                'Zapp::Task::Request' => {
                    auth => {
                        type => 'bearer',
                        token => 'AUTHBEARERTOKEN',
                    },
                    method => 'GET',
                    url => $t->ua->server->url->path( '/test/success' ),
                },
                'Test: Bearer Auth - Success',
            );
            $t->task_info_is( state => 'finished', 'job finished' );
            $t->task_output_is({
                is_success => 1,
                code => 200,
                message => 'OK',
                body => 'Success',
                headers => {
                    content_type => 'text/plain',
                },
            });

            is $last_request->headers->authorization,
                'Bearer AUTHBEARERTOKEN',
                'Authorization HTTP header is correct';
        };

        subtest 'unauthorized' => sub {
            $t->run_task(
                'Zapp::Task::Request' => {
                    auth => {
                        type => 'bearer',
                        token => 'AUTHBEARERTOKEN',
                    },
                    method => 'GET',
                    url => $t->ua->server->url->path( '/test/unauthorized' ),
                },
                'Test: Bearer Auth - Unauthorized',
            );
            $t->task_info_is( state => 'failed', 'job failed' );
            $t->task_output_is({
                is_success => '',
                code => 401,
                message => 'Unauthorized',
                body => 'You are not authorized',
                headers => {
                    content_type => 'text/plain',
                },
            });

            is $last_request->headers->authorization,
                'Bearer AUTHBEARERTOKEN',
                'Authorization HTTP header is correct';
        };
    };

};

subtest 'follow_redirects' => sub {
    subtest 'follow: yes' => sub {
        $t->run_task(
            'Zapp::Task::Request' => {
                method => 'GET',
                url => $t->ua->server->url->path( '/test/redirect' ),
                max_redirects => 10,
            },
            'Follow redirects: yes',
        );
        $t->task_info_is( state => 'finished', 'job finished' );
        $t->task_output_is({
            is_success => 1,
            code => 200,
            message => 'OK',
            body => 'Success',
            headers => {
                content_type => 'text/plain',
            },
        });
    };

    subtest 'follow: no' => sub {
        $t->run_task(
            'Zapp::Task::Request' => {
                method => 'GET',
                url => $t->ua->server->url->path( '/test/redirect' ),
                max_redirects => 0,
            },
            'Follow redirects: no',
        );
        $t->task_info_is( state => 'finished', 'job finished' );
        $t->task_output_is({
            is_success => 1,
            code => 302,
            message => 'Found',
            headers => {
                location => '/test/success',
            },
        });
    };
};

subtest 'input form' => sub {
    my $tmpl = data_section 'Zapp::Task::Request', 'input.html.ep';

    subtest 'defaults' => sub {
        $t->render_ok( inline => $tmpl )
            ->element_exists(
                '[name="method"]',
                'method input exists',
            )
            ->attr_is(
                '[name="method"] [selected]',
                value => 'GET',
                'GET method selected by default',
            )
            ->element_exists(
                '[name="url"]',
                'url input exists',
            )
            ->attr_is(
                '[name="url"]',
                value => '',
                'url correct value',
            )
            ->element_exists(
                '[name="max_redirects"][value=10]',
                'max_redirects input exists (yes: 10)',
            )
            ->element_exists(
                '[name="max_redirects"][value=10][checked]',
                'max_redirects yes is checked by default',
            )
            ->element_exists(
                '[name="max_redirects"][value=0]',
                'max_redirects input exists (no: 0)',
            )
            ->element_exists_not(
                '[name="max_redirects"][value=0][checked]',
                'max_redirects no is not checked by default',
            )
            ->element_exists(
                '[name="auth.type"]',
                'auth type input exists',
            )
            ->attr_is(
                '[name="auth.type"] [selected]',
                value => '',
                'auth type correct option selected',
            )
            ->element_exists(
                '[name="auth.token"]',
                'auth token input exists',
            )
            ->element_exists_not(
                '.zapp-visible [name="auth.token"]',
                'auth token input is not visible',
            )
            ;
    };

    subtest 'with bearer auth' => sub {
        my $input = {
            method => 'POST',
            url => '/foo/bar',
            auth => {
                type => 'bearer',
                token => 'AUTHTOKEN',
            },
        };

        $t->render_ok( inline => $tmpl, input => $input )
            ->element_exists(
                '[name="method"]',
                'method input exists',
            )
            ->attr_is(
                '[name="method"] [selected]',
                value => 'POST',
                'method correct option selected',
            )
            ->element_exists(
                '[name="url"]',
                'url input exists',
            )
            ->attr_is(
                '[name="url"]',
                value => '/foo/bar',
                'url correct value',
            )
            ->element_exists(
                '[name="auth.type"]',
                'auth type input exists',
            )
            ->attr_is(
                '[name="auth.type"] [selected]',
                value => 'bearer',
                'auth type correct option selected',
            )
            ->element_exists(
                '[name="auth.token"]',
                'auth token input exists',
            )
            ->element_exists(
                '.zapp-visible [name="auth.token"]',
                'auth token input is visible',
            )
            ->attr_is(
                '[name="auth.token"]',
                value => 'AUTHTOKEN',
                'auth token input value is correct',
            )
            ;
    };

    subtest 'follow redirects: no' => sub {
        my $input = {
            method => 'POST',
            url => '/foo/bar',
            max_redirects => 0,
        };

        $t->render_ok( inline => $tmpl, input => $input )
            ->element_exists(
                '[name="max_redirects"][value=10]',
                'max_redirects input exists (yes: 10)',
            )
            ->element_exists_not(
                '[name="max_redirects"][value=10][checked]',
                'max_redirects yes is not checked',
            )
            ->element_exists(
                '[name="max_redirects"][value=0]',
                'max_redirects input exists (no: 0)',
            )
            ->element_exists(
                '[name="max_redirects"][value=0][checked]',
                'max_redirects no is checked',
            )
            ;
    };
};

subtest 'output view' => sub {
    my $tmpl = data_section 'Zapp::Task::Request', 'output.html.ep';

    subtest 'before run' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    method => 'GET',
                    url => 'http://example.com',
                },
            },
        );
        $t->text_like(
            'pre[data-input]',
            qr{GET http://example\.com}ms,
            "input display is correct",
        );
        $t->element_exists_not( '[data-output]', 'output not showing' );
        $t->element_exists_not( '[data-error]', 'error not showing' );
    };

    subtest 'success: json' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    method => 'GET',
                    url => 'http://example.com',
                },
                output => {
                    code => 200,
                    message => 'Ok',
                    body => '{"hello":"world"}',
                    json => { hello => 'world' },
                },
            },
        );
        $t->text_like(
            'pre[data-input]',
            qr{GET http://example\.com}ms,
            "input display is correct",
        );
        $t->text_like(
            'pre[data-output]',
            qr{\s*{\s*"hello"\s*=>\s*"world",?\s*}\s*}ms,
            "json dumper output is correct",
        );
        $t->element_exists_not( '[data-error]', 'error not showing' );
    };

    subtest 'success: file' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    method => 'GET',
                    url => 'http://example.com',
                },
                output => {
                    code => 200,
                    message => 'Ok',
                    body => '{"hello":"world"}',
                    file => "/output.txt",
                    headers => {
                        content_type => 'application/octet-stream',
                    },
                },
            },
        );
        $t->text_like(
            'pre[data-input]',
            qr{GET http://example\.com}ms,
            "input display is correct",
        );
        $t->attr_is(
            'a[href]',
            href => '/output.txt',
            "file download link is correct",
        );
        $t->element_exists_not( '[data-error]', 'error not showing' );
    };

    subtest 'exception' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    method => 'GET',
                    url => 'http://example.com',
                },
                output => q{Can't call method "res" on an undefined value},
            },
        );
        $t->text_like(
            'pre[data-input]',
            qr{GET http://example\.com}ms,
            "input display is correct",
        );
        $t->element_exists_not( '[data-output]', 'output not showing' );
        $t->text_like( '[data-error]', qr{Can't call method "res"}, 'error is correct' );
    };

};

done_testing;

