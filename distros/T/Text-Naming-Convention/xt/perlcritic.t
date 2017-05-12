use strict;
use warnings;

use Test::More;

# we forced use Perl::Critic is for version limit
eval "use Perl::Critic 1.090; use Test::Perl::Critic 1.01";
if ($@) {
    plan skip_all =>
"Perl::Critic 1.090 and Test::Perl::Critic 1.01 required for testing PBP compliance";
}
elsif ( !-e 'inc/.author' ) {
    plan skip_all => 'no inc/.author, will not run this test ;)';
}

Test::Perl::Critic::all_critic_ok();
