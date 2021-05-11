#! perl -I. -w
use t::Test::abeltje;

require_ok( 'V' );

my @modules = map {
    s{/}{::}g; s{\.pm$}{};
    $_
} grep { /\.pm$/ && ! /^Config\.pm$/ } keys %INC;


my $versions = eval {
    join ", ", map { "$_: " . V::get_version( $_ ) } qw/ Cwd /;
};

is( $@, "", "readonly bug" );

abeltje_done_testing();
