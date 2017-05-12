#!perl -T

use strict;
use warnings;
use Test::More tests => 96;
use WWW::Netflix::API;
$|=1;

my $netflix = WWW::Netflix::API->new({});
my $base_url = $netflix->{base_url};

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
    ok( $netflix->can($k), "$label can" )
	or skip "'$k' attribute missing", 3;
    is( $netflix->$k(), undef, "$label default" );
    is( $netflix->$k(123), 123, "$label set" );
    is( $netflix->$k, 123, "$label get" );
  };
}


# content
my $fn = sub { uc '='.$_[0].'=' };
my $s = 'foo';
my $s2 = '=FOO=';

is( $netflix->content_filter(undef), undef, '[clear content-] unset filter' );
is( $netflix->_set_content(undef),   undef, '[clear content-] clear content' );
#
is( $netflix->content_ref,           undef, '[clear content-] check content_ref');
is( $netflix->_filtered_content,     undef, '[clear content-] check _filtered_content');
is( $netflix->content,               undef, '[clear content-] check content');
is( $netflix->_filtered_content,     undef, '[clear content-] check _filtered_content');
is( $netflix->original_content,      undef, '[clear content-] check original_content' );
is( $netflix->content_error,         undef, '[clear content-] check content_error' );

is( $netflix->content_filter($fn),   $fn,   '[clear content+] unset filter' );
is( $netflix->_set_content(undef),   undef, '[clear content+] clear content' );
#
is( $netflix->content_ref,           undef, '[clear content+] check content_ref');
is( $netflix->_filtered_content,     undef, '[clear content+] check _filtered_content');
is( $netflix->content,               undef, '[clear content+] check content');
is( $netflix->_filtered_content,     undef, '[clear content+] check _filtered_content');
is( $netflix->original_content,      undef, '[clear content+] check original_content' );
is( $netflix->content_error,         undef, '[clear content+] check content_error' );


is( $netflix->content_filter(undef), undef, '[set content-] unset filter' );
is( $netflix->_set_content(\$s),     \$s,   '[set content-] set content' );
#
is( $netflix->content_ref,           \$s,   '[set content-] check content_ref');
is( $netflix->_filtered_content,     undef, '[set content-] check _filtered_content');
is( $netflix->content,               $s,    '[set content-] check content');
is( $netflix->_filtered_content,     undef, '[set content-] check _filtered_content');
is( $netflix->original_content,      $s,    '[set content-] check original_content' );
is( $netflix->content_error,         undef, '[set content-] check content_error' );

is( $netflix->content_filter($fn),   $fn,   '[set content+] unset filter' );
is( $netflix->_set_content(\$s),     \$s,   '[set content+] set content' );
#
is( $netflix->content_ref,           \$s,   '[set content+] check content_ref');
is( $netflix->_filtered_content,     undef, '[set content+] check _filtered_content');
is( $netflix->content,               $s2,   '[set content+] check content');
is( $netflix->_filtered_content,     $s2,   '[set content+] check _filtered_content');
is( $netflix->original_content,      $s,    '[set content+] check original_content' );
is( $netflix->content_error,         undef, '[set content+] check content_error' );


# url
is( $netflix->_url('foo'), 'foo',         '[url;+-] set _url    +'  );
is( $netflix->_levels(undef), undef,      '[url;+-] set _levels -'  );
is( $netflix->url, 'foo',                 '[url;+-] check url()'    );

is( $netflix->_url(''), '',               '[url;--] set _url    -'  );
is( $netflix->_levels(undef), undef,      '[url;--] set _levels -'  );
is( $netflix->url, 'http://' . $base_url,
                                          '[url;--] check url()'    );

my $arr = [123,456];
is( $netflix->_url('foo'), 'foo',         '[url;++] set _url    +'  );
is_deeply( $netflix->_levels($arr), $arr, '[url;++] set _levels +'  );
is( $netflix->url, 'foo',                 '[url;++] check url()'    );

is( $netflix->_url(''), '',               '[url;-+] set _url    -'  );
is_deeply( $netflix->_levels($arr), $arr, '[url;-+] set _levels +'  );
is( $netflix->url, 'http://' . $base_url . '/123/456',
                                          '[url;-+] check url()'    );

