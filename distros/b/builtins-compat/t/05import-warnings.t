use strict;
use warnings;
use Test::More;
use Test::Warnings qw( :all );

use builtins::compat ();

if ( builtins::compat::LEGACY_PERL ) {
	my $w = warning {
		'builtins::compat'->import( 'foobar' );
	};
	like $w, qr/^"foobar" is not exported by the builtins::compat module/;
}
else {
	pass "skipped test: Perl too new";
}

if ( builtins::compat::LEGACY_PERL ) {
	my $w = warning {
		'builtins::compat'->import( ':foobar' );
	};
	like $w, qr/^"foobar" is not defined in builtins::compat::EXPORT_TAGS/;
}
else {
	pass "skipped test: Perl too new";
}

done_testing;
