package Fitnesse::Slim::Test::MethodNameResolution;

use strict;
use warnings;

sub new {
  bless {
    system_under_test => bless({}, 'Fitnesse::Slim::Test::MethodNameResolution::Sut'),
    value => undef,
  } => $_[0];
}

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['Integer'], return => 'Integer' }
    if $method eq 'get_http_response_code';
  return { parameters => ['Boolean'], return => 'Boolean' }
    if $method eq 'is_ipv6_enabled';
  return { parameters => ['String'], return => 'String' }
    if $method eq 'set_value';
  return { parameters => ['Integer'], return => 'String' }
    if $method eq 'echo_user_id';
  return;
}

sub get_url { 'snake URL' }
sub getURL { 'exact URL' }
sub fetch_url { 'snake URL' }
sub parse_xml_document { 'parsed XML' }
sub get_http_response_code { $_[1] }
sub is_ipv6_enabled { $_[1] }
sub echo_user_id { "user $_[1]" }
sub set_value { $_[0]{value} = $_[1]; 'stored' }
sub get_value { $_[0]{value} }
sub make_a_test_page { 'created test page' }
sub reset { 'reset' }
sub direct_snake_case { 'camel boundary' }
sub actor_and_sut { 'actor wins' }

package Fitnesse::Slim::Test::MethodNameResolution::Sut;

use strict;
use warnings;

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => [], return => 'String' }
    if $method eq 'get_sut_status';
  return;
}

sub get_sut_status { 'SUT status' }

1;
