package Fitnesse::Slim::Test::SystemUnderTestDriver;

use strict;
use warnings;

sub new {
  my($class) = @_;
  bless { system_under_test => Fitnesse::Slim::Test::SystemUnderTestService->new }, $class;
}

sub shared { 'actor' }
sub make_token { bless {}, 'Fitnesse::Slim::Test::SystemUnderTestToken' }

package Fitnesse::Slim::Test::SystemUnderTestService;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

sub new { bless { calls => 0 }, $_[0] }
sub shared { 'sut' }
sub sut_only { 'sut' }
sub same_token {
  my($self, $token) = @_;
  ref($token) && refaddr($token) == refaddr($self->{token}) ? 'true' : 'false';
}
sub keep_token { $_[0]->{token} = $_[1]; 'stored' }
sub fail { die "java.lang.IllegalStateException: SUT failed\n" }
sub throw_ignore_all { die "fitnesse.slim.SlimIgnoreAllTestsException: ignored\n" }
sub sut_calls { $_[0]->{calls} }

1;
