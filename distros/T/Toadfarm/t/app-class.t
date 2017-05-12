use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Toadfarm;
use lib Cwd::abs_path;

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };
$ENV{MOJO_CONFIG} = Cwd::abs_path('t/app-class.conf');
chdir File::Spec->tmpdir;    # make sure we cannot read t/lib/App.pm

my $t = Test::Mojo->new('Toadfarm');

$t->get_ok('/')->status_is(404);
$t->get_ok('/dummy', {Host => 'te.st'})->status_is(200)->content_is("Dummy\n");
$t->get_ok('/dummy', {Host => 'whatever.te.st'})->status_is(200)->content_is("Dummy\n");

is_deeply \@warn, [], 'no warnings';

done_testing;
