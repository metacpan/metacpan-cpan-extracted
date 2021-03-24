use Test2::V0 0.000121 -no_srand => 1;
use Test2::Tools::URL;

imported_ok $_ for qw(
  url
  url_base
  url_component
  url_scheme
  url_host
  url_secure
  url_insecure
  url_mail_to
);

subtest 'as string' => sub {

  is(
    'http://example.com',
    url {},
  );

};

subtest 'as URI' => sub {

  skip_all 'test requires URI' unless eval q{ require URI };

  is(
    URI->new('http://example.com'),
    url {},
  );

};

subtest 'as Mojo::URL' => sub {

  skip_all 'test requires URI' unless eval q{ require Mojo::URL };

  is(
    Mojo::URL->new('http://example.com'),
    url {},
  );

};

subtest 'non object references' => sub {

  my $e;

  is(
    $e = intercept { is( undef, url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given undef',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

  is(
    $e = intercept { is( [], url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given []',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

  is(
    $e = intercept { is( {}, url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given {}',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

  is(
    $e = intercept { is( sub {}, url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given sub {}',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

  is(
    $e = intercept { is( \'', url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given \\\'\'',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

  is(
    $e = intercept { is( qr{}, url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given qr{}',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;
};

subtest 'bogus scheme' => sub {

  my $e;

  is(
    $e = intercept { is( "bogus://example.com", url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given bogus scheme',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

};

subtest 'relative url' => sub {

  my $e;

  is(
    $e = intercept { is( "./foo/bar", url {} ) },
    array {
      event 'Fail';
      etc;
    },
    'fails when given relative URL',
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

};

subtest 'component' => sub {

  is(
    'http://foo:bar@example.com:1234/some/path?baz=1#fragment',
    url {
      url_component scheme    => 'http';
      url_component authority => 'foo:bar@example.com:1234';
      url_component userinfo  => 'foo:bar';
      url_component hostport  => 'example.com:1234';
      url_component host      => 'example.com';
      url_component port      => 1234;
      url_component path      => '/some/path';
      url_component query     => { baz => 1 };
      url_component fragment  => 'fragment';
    },
  );

  is(
    'http://foo:bar@example.com:1234/some/path?baz=1#fragment',
    url {
      url_component query     => [ baz => 1 ];
    },
  );

  is(
    'http://foo:bar@example.com:1234/some/path?baz=1#fragment',
    url {
      url_component query     => "baz=1";
    },
  );

  foreach my $name (qw( scheme authority userinfo hostport host port path fragment ))
  {
    my $e;

    is(
      $e = intercept {
        is(
          'http://foo:bar@example.com:1234/some/path?baz=1#fragment',
          url {
            url_component $name    => 'x';
          },
        )
      },
      array {
        event 'Fail';
        etc;
      },
      "$name does not match",
    );

    note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;
  }

  my $e;

  is(
    $e = intercept {
      is(
        'http://foo:bar@example.com:1234/some/path?baz=1#fragment',
        url {
          url_component query    => {foo=>1};
        },
      )
    },
    array {
      event 'Fail';
      etc;
    },
    "query does not match hashref",
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;

  is(
    $e = intercept {
      is(
        'http://foo:bar@example.com:1234/some/path?baz=1#fragment',
        url {
          url_component query    => [foo=>1];
        },
      )
    },
    array {
      event 'Fail';
      etc;
    },
    "query does not match array",
  );

  note $_->message for grep { $_->isa('Test2::Event::Diag') } @$e;
};

subtest 'url_base' => sub {

  is(
    '../foo',
    url {
      url_base 'http://example.com/a/b/c/';
      url_component host => 'example.com';
      url_component path => '/a/b/foo';
      url_component port => 80;
    },
  );

};

subtest 'url_base' => sub {

  url_base 'http://example.com/a/b/c/';

  is(
    '../foo',
    url {
      url_component host => 'example.com';
      url_component path => '/a/b/foo';
      url_component port => 80;
    },
  );

  url_base undef;

};

subtest 'windows absolute' => sub {
  skip_all 'windows only' unless $^O eq 'MSWin32';

  is(
    'file://localhost/C:/foo',
    url {
      url_component path => 'C:/foo';
    },
  );

};

subtest 'query as hash with repeated keys' => sub {

  is(
    "http://example.com/page?foo=bar&lorem=ipsum",
    url {
      url_component query => { foo => "bar", lorem => "ipsum" };
    },
    "expected query for hashref without repeated keys"
  );

  is(
    "http://example.com/page?foo=bar&foo=baz&lorem=ipsum",
    url {
      url_component query => { foo => [qw( bar baz )], lorem => "ipsum" };
    },
    "expected query for hashref with repeated keys"
  );
};

subtest 'url_scheme' => sub {

  is(
    "htTp://foo.bar/",
    url {
      url_scheme 'http';
    },
    "test scheme in mixed case",
  );

  is(
    intercept { is("http:://foo", url { url_scheme 'ftp' }) },
    array {
      event 'Fail';
      end;
    },
    'test schme fail',
  );

};

subtest 'url_host' => sub {

  is(
    "http://fOo.bar/",
    url {
      url_host 'foo.bar';
    },
    "test host in mixed case",
  );

  is(
    intercept { is("http:://foo", url { url_host 'baz' }) },
    array {
      event 'Fail';
      end;
    },
    'test schme fail',
  );

};

subtest 'url_secure / url_insecure' => sub {

  is(
    "https://foo.bar",
    url {
      url_secure();
    },
    'secure pass',
  );

  is(
    intercept { is("https://foo.bar", url { url_insecure() }) },
    array {
      event 'Fail';
      end;
    },
    'insecure fail',
  );

  is(
    "http://foo.bar",
    url {
      url_insecure();
    },
    'insecure pass',
  );

  is(
    intercept { is("http://foo.bar", url { url_secure() }) },
    array {
      event 'Fail';
      end;
    },
    'secure fail',
  );

};

subtest 'url_mail_to' => sub {

  is(
    'mailto:plicease@foo.test',
    url {
      url_mail_to 'plicease@foo.test';
    },
    'matches good',
  );

  is(
    intercept { is('mailto:plicease@foo.test', url { url_mail_to "baz" }) },
    array {
      event 'Fail';
      end;
    },
    'mail to fail',
  );

  is(
    intercept { is('http://foo.test', url { url_mail_to "baz" }) },
    array {
      event 'Fail';
      end;
    },
    'mail to fail with non-mailto URL',
  );

};

subtest 'ftp URLs' => sub {

  is(
    'ftp://plicease:pass@foo.test/',
    url {
      url_component 'user' => 'plicease';
      url_component 'password' => 'pass';
    },
    'url user + password test pass',
  );

  is(
    intercept { is('ftp://plicease:pass@foo.test/', url { url_component 'user' => 'bad' } ) },
    array {
      event 'Fail';
      end;
    },
    'url user test fail',
  );

  is(
    intercept { is('ftp://plicease:pass@foo.test/', url { url_component 'password' => 'bad' } ) },
    array {
      event 'Fail';
      end;
    },
    'url user test fail',
  );

  is(
    intercept { is("http://foo.test/", url { url_component 'user' => 'bad'; url_component 'password' => 'bad'; }) },
    array {
      event 'Fail';
      end;
    },
    'url user + password test fail on non-FTP URL',
  );

};

subtest 'data URLs' => sub {

  my $url = URI->new('data:');
  $url->media_type('text/plain');
  $url->data('Hello, World!');
  $url = "$url";

  note "url = $url";

  is(
    $url,
    url {
      url_component 'media_type' => 'text/plain';
      url_component 'data'       => 'Hello, World!';
    },
    'url media type + data test pass',
  );

  is(
    intercept { is($url, url { url_component 'media_type' => 'foo' }) },
    array {
      event 'Fail';
      end;
    },
    'url media type fail',
  );

  is(
    intercept { is($url, url { url_component 'data' => 'foo' }) },
    array {
      event 'Fail';
      end;
    },
    'url data fail',
  );

  is(
    intercept { is("http://foo.test", url { url_component 'media_type' => 'foo'; url_component 'data' => 'foo' }) },
    array {
      event 'Fail';
      end;
    },
    'url media_type + data fail on non-data URL',
  );


};

done_testing
