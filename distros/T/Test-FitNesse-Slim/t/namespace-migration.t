use strict;
use warnings;

use File::Find qw(find);
use Test::More;
use lib 'lib';

use Test::FitNesse::Slim;

my $root = 'lib';
my @modules;
my @stale;
find({
  wanted => sub {
    return unless -f $_ && /\.pm\z/;
    push @modules, $File::Find::name;
    open my $fh, '<', $_ or die "read $File::Find::name: $!";
    local $/;
    my $source = <$fh>;
    close $fh or die "close $File::Find::name: $!";
    push @stale, $File::Find::name if $source =~ /\bTest::Slim(?:::|\b)/;
  },
  no_chdir => 1,
}, $root);

is($Test::FitNesse::Slim::VERSION, '1.00', 'new primary module keeps distribution version 1.00');
is(scalar @modules, 9, 'all nine production modules are present');
ok(-f 'lib/Test/FitNesse/Slim.pm', 'primary module uses the official FitNesse capitalization');
ok(!-e 'lib/Test/Slim.pm', 'old primary module path is absent');
ok(!-d 'lib/Test/Slim', 'old production module directory is absent');
is_deeply(\@stale, [], 'production modules contain no old Test::Slim package references');

done_testing;
