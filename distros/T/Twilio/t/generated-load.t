use 5.016;
use warnings;

use File::Find qw(find);
use Test::More;

# Resources are only loaded when they are reached, so a module that does not compile would
# otherwise stay hidden until someone used it.
my @modules;
find(
  sub {
    return if !/[.]pm\z/;
    my $module = $File::Find::name =~ s{\Alib/}{}r =~ s{[.]pm\z}{}r =~ s{/}{::}gr;
    push @modules, $module;
  },
  'lib/Twilio/Rest',
  'lib/Twilio/TwiML'
);

ok(@modules > 140, 'the generated modules are there');

for my $module (sort @modules) {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $loaded = eval "require $module; 1";    ## no critic (ProhibitStringyEval)
  ok($loaded, "$module loads") or diag($@);
  is_deeply(\@warnings, [], "$module has no warnings");
}

done_testing;
