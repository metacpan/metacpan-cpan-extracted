use strict;
use warnings;

# Pass --verbose to confirm Getopt::Long pass_through forwards arbitrary
# App::cpm flags through lazy. -g is uninformative here because GetOptions
# operates on a local @ARGV, so even the pre-fix 'g|global' spec did not
# strip -g from the forwarded args (see GH #19).
use lazy ('--verbose');

use Test::More import => [qw( done_testing is ok )];

my @captured_args;
{
    require App::cpm::CLI;
    no warnings 'redefine';
    *App::cpm::CLI::run = sub {
        shift;
        push @captured_args, [@_];
        return 1;
    };
}

my ($cb) = grep { ref $_ eq 'CODE' } @INC;
$cb->( undef, 'Some::Fake::Module' );

is( scalar @captured_args, 1, 'App::cpm::CLI::run was called once' );

my @forwarded = @{ $captured_args[0] };

ok(
    ( grep { $_ eq '--verbose' } @forwarded ),
    '--verbose forwarded to App::cpm via pass_through'
);

done_testing();
