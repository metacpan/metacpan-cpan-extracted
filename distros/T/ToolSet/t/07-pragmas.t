use strict;
use lib 't/lib';
use lib '.';
use Test::More;

if ( $] >= 5.009 ) {
    plan tests => 5;
}
else {
    plan skip_all => 'user-pragma tests require Perl 5.010';
}

my %pragmas;

my $in_effect = eval "use t::ToolSet::Pragmas; return bogopragma::in_effect()";

is( $@, '', "no error in eval" );
ok( $in_effect, "bogus pragma set" );

$in_effect = eval
  "use t::ToolSet::Pragmas; use t::ToolSet::NoPragmas; return bogopragma::in_effect()";

is( $@, '', "no error in eval" );
ok( !$in_effect, "bogus pragma not set" );

eval "use t::Sample::NoStrictRefs";
like(
    $@,
    qr/Global symbol "\$pi" requires explicit package name/,
    "use_pragma + no_pragma"
);
