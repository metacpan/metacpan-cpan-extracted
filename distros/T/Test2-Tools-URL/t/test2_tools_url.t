use Test2::V0 0.000121 -no_srand => 1;
use Test2::Tools::URL;

imported_ok $_ for qw(
  url
  url_base
  url_component
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

done_testing
