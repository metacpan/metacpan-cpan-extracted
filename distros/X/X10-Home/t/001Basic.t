######################################################################
# Test suite for X10::Home
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Test::More;
use X10::Home;

plan tests => 1;

SKIP: {
  my $eg = "eg";
  $eg = "../eg" unless -d $eg;

  my $x10 = X10::Home->new(
      conf_file => "$eg/x10.conf",
      probe     => 0,
  );
  
  is($x10->{receivers}->{'office_lights'}->{code}, "K10", "Receiver Code");
}
