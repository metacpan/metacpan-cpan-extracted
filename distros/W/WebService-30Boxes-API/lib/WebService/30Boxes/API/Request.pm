package WebService::30Boxes::API::Request;

use strict;
use HTTP::Request;
use URI;

our $VERSION = '1.05';
our @ISA = qw/HTTP::Request/;

sub new {
   my ($class, $meth, $args) = @_;

   my $self = new HTTP::Request;
      $self->{'_api_meth'} = $meth if($meth);
      $self->{'_api_args'} = $args if($args);

   bless $self, $class;

   $self->method('POST');
   $self->uri('http://30boxes.com/api/api.php');

   return $self;
}

sub encode_args {
   my $self = shift;

   my $url = URI->new('http:');
   $url->query_form(
      method => $self->{'_api_meth'}, 
      %{$self->{'_api_args'}});
   my $content = $url->query;

   $self->header('Content-Type' => 'application/x-www-form-urlencoded');
   if (defined($content)) {
      $self->header('Content-Length' => length($content));
      $self->content($content);
   }
}

1;
