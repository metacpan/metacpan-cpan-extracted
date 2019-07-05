package Internal::Fixture::HTTPList;
use 5.010001;
use strict;
use warnings;
use parent 'Test::FITesque::Fixture';
use Test::More ;
use Test::Deep ;

sub http_req_res_list_unauthenticated : Test : Plan(7) {
  my ($self, $args) = @_;
  note($args->{description});
  # TODO: Doesn't seem that hard to use Test::Deep for this after all
  is(scalar @{$args->{'http-requests'}}, 2, 'There are two requests');
  is(${$args->{'http-requests'}}[0]->method, 'PUT', 'First method is PUT');
  is(${$args->{'http-requests'}}[1]->method, 'GET', 'Second method is GET');
  is(scalar @{$args->{'http-responses'}}, 2, 'There are two responses');
  is(${$args->{'http-responses'}}[0]->code, '201', 'First code is 201');
  is(${$args->{'http-responses'}}[1]->content_type, 'text/turtle', 'Second ctype is turtle');
  cmp_deeply([${$args->{'http-responses'}}[1]->header('Accept-Post')], bag("text/turtle", "application/ld+json"), 'Response header field value bag comparison');

}

1;

# # TODO: This should really mock an HTTP server, then it would be something like
# sub http_req_res_list_unauthenticated : Test : Plan(2) {
#   my ($self, $args) = @_;
#   for (my $i=0; $i <= $#{$args->{'http-requests'}}; $i++) {
# 	 subtest "Request-response #" . $i+1 => sub {
# 		my $ua = LWP::UserAgent->new;
# 		my $response = $ua->request( ${$args->{'http-requests'}}[$i] );
# 		## Here, compare $response and $ua->request( ${$args->{'http-responses'}}[$i] to see that they match
# 	 };
#   }
# };
