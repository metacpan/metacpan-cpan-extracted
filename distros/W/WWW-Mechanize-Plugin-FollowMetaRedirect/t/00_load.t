use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok( 'WWW::Mechanize::Plugin::FollowMetaRedirect' );
}

diag( "Testing WWW::Mechanize::Plugin::FollowMetaRedirect $WWW::Mechanize::Plugin::FollowMetaRedirect::VERSION, Perl $], $^X" );

done_testing;

__END__