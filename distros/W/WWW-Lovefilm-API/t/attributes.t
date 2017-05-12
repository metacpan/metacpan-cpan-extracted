#!perl -T

use strict;
use warnings;
use Test::More tests => 96;
use WWW::Lovefilm::API;
$|=1;

my $lovefilm = WWW::Lovefilm::API->new({});

foreach my $k ( qw/
	consumer_key
	consumer_secret
	content_filter
	access_token
	access_secret
	user_id
	_levels
	rest_url
	_url
	_params

	content_ref
	_filtered_content
	content_error
/ ){
  my $label = "[$k]";
  SKIP: {
    ok( $lovefilm->can($k), "$label can" )
	or skip "'$k' attribute missing", 3;
    is( $lovefilm->$k(), undef, "$label default" );
    is( $lovefilm->$k(123), 123, "$label set" );
    is( $lovefilm->$k, 123, "$label get" );
  };
}


# content
my $fn = sub { uc '='.$_[0].'=' };
my $s = 'foo';
my $s2 = '=FOO=';

is( $lovefilm->content_filter(undef), undef, '[clear content-] unset filter' );
is( $lovefilm->_set_content(undef),   undef, '[clear content-] clear content' );
#
is( $lovefilm->content_ref,           undef, '[clear content-] check content_ref');
is( $lovefilm->_filtered_content,     undef, '[clear content-] check _filtered_content');
is( $lovefilm->content,               undef, '[clear content-] check content');
is( $lovefilm->_filtered_content,     undef, '[clear content-] check _filtered_content');
is( $lovefilm->original_content,      undef, '[clear content-] check original_content' );
is( $lovefilm->content_error,         undef, '[clear content-] check content_error' );

is( $lovefilm->content_filter($fn),   $fn,   '[clear content+] unset filter' );
is( $lovefilm->_set_content(undef),   undef, '[clear content+] clear content' );
#
is( $lovefilm->content_ref,           undef, '[clear content+] check content_ref');
is( $lovefilm->_filtered_content,     undef, '[clear content+] check _filtered_content');
is( $lovefilm->content,               undef, '[clear content+] check content');
is( $lovefilm->_filtered_content,     undef, '[clear content+] check _filtered_content');
is( $lovefilm->original_content,      undef, '[clear content+] check original_content' );
is( $lovefilm->content_error,         undef, '[clear content+] check content_error' );


is( $lovefilm->content_filter(undef), undef, '[set content-] unset filter' );
is( $lovefilm->_set_content(\$s),     \$s,   '[set content-] set content' );
#
is( $lovefilm->content_ref,           \$s,   '[set content-] check content_ref');
is( $lovefilm->_filtered_content,     undef, '[set content-] check _filtered_content');
is( $lovefilm->content,               $s,    '[set content-] check content');
is( $lovefilm->_filtered_content,     undef, '[set content-] check _filtered_content');
is( $lovefilm->original_content,      $s,    '[set content-] check original_content' );
is( $lovefilm->content_error,         undef, '[set content-] check content_error' );

is( $lovefilm->content_filter($fn),   $fn,   '[set content+] unset filter' );
is( $lovefilm->_set_content(\$s),     \$s,   '[set content+] set content' );
#
is( $lovefilm->content_ref,           \$s,   '[set content+] check content_ref');
is( $lovefilm->_filtered_content,     undef, '[set content+] check _filtered_content');
is( $lovefilm->content,               $s2,   '[set content+] check content');
is( $lovefilm->_filtered_content,     $s2,   '[set content+] check _filtered_content');
is( $lovefilm->original_content,      $s,    '[set content+] check original_content' );
is( $lovefilm->content_error,         undef, '[set content+] check content_error' );


# url
is( $lovefilm->_url('foo'), 'foo',         '[url;+-] set _url    +'  );
is( $lovefilm->_levels(undef), undef,      '[url;+-] set _levels -'  );
is( $lovefilm->url, 'foo',                 '[url;+-] check url()'    );

is( $lovefilm->_url(''), '',               '[url;--] set _url    -'  );
is( $lovefilm->_levels(undef), undef,      '[url;--] set _levels -'  );
is( $lovefilm->url, 'http://openapi.lovefilm.com',
                                          '[url;--] check url()'    );

my $arr = [123,456];
is( $lovefilm->_url('foo'), 'foo',         '[url;++] set _url    +'  );
is_deeply( $lovefilm->_levels($arr), $arr, '[url;++] set _levels +'  );
is( $lovefilm->url, 'foo',                 '[url;++] check url()'    );

is( $lovefilm->_url(''), '',               '[url;-+] set _url    -'  );
is_deeply( $lovefilm->_levels($arr), $arr, '[url;-+] set _levels +'  );
is( $lovefilm->url, 'http://openapi.lovefilm.com/123/456',
                                          '[url;-+] check url()'    );

