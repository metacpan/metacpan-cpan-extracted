package WebService::SendGrid;
$WebService::SendGrid::VERSION = '1.03';
# ABSTRACT: An interface to the SendGrid email service
use Moose;
use MooseX::Method::Signatures;

use Carp;
use JSON::XS;
use WWW::Curl::Simple;
use HTTP::Request;

has 'user_agent' => (
  is => 'ro',
  isa => 'WWW::Curl::Simple',
  required => 1,
  default => sub {
    return WWW::Curl::Simple->new();
  }
);

has 'test_mode' => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
);

has 'api_user' => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

has 'api_key' => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

method _generate_request (Str $path, HashRef $data) {
  
  # add the api_user and api_key to the query string
  $data->{$_} = $self->$_ for qw(api_user api_key);
  
  my $uri = URI->new('https:');
	$uri->query_form(%$data);
	
	my $req = HTTP::Request->new;
	$req->method('POST');
	$req->uri('https://sendgrid.com' . $path);
	$req->content($uri->query);
	return $req;
	
}

method _process_error (Object $res) {
  croak 'Response is not an HTTP::Response object' if ref $res ne 'HTTP::Response';
  
  print Data::Dumper::Dumper($res);
  
}

method _dispatch_test_request (Object $req) {
  
  my $content;
  if ($req->uri->path eq '/api/profile.get.json') {
    my %profile = (
      username => 'jlloyd',
      email => 'jlloyd@cpan.org',
      website_access => 'true',
      active => 'true',
    );
    $content = encode_json( [ \%profile ]);
  }
  else {
    $content = encode_json( { message => 'success' });
  }
  
  my $res = HTTP::Response->new;
  $res->code(100);
  $res->content( $content );
  return $res;
}

method _dispatch_request (Object $req) {
  croak 'Request is not an HTTP::Request object' if ref $req ne 'HTTP::Request';
  
  # if the module is being called from a test file
	# always send a successful response
	return $self->_dispatch_test_request($req) if $self->test_mode == 1;


  #$self->log->info('Sending request');
  my $res = $self->user_agent->request($req);
  return $res;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid - An interface to the SendGrid email service

=head1 VERSION

version 1.03

=head1 DESCRIPTION

This module is the parent class for an interface to the SendGrid Web API.  To use it, refer to the individual classes below.

=head1 SEE ALSO

=for :list * L<WebService::SendGrid::Mail>
* L<WebService::SendGrid::Profile>

=head1 AUTHOR

Jonathan Lloyd <webmaster@lifegames.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Lloyd <webmaster@lifegames.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
