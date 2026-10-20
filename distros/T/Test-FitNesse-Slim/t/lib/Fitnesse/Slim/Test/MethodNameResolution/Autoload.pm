package Fitnesse::Slim::Test::MethodNameResolution::Autoload;

use strict;
use warnings;

our $AUTOLOAD;

sub new { bless {}, $_[0] }

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['Integer'], return => 'String' }
    if $method eq 'dynamicHTTPCall';
  return;
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  (my $method = $AUTOLOAD) =~ s/.*:://;
  die "message:<<NO_METHOD_IN_CLASS $method>>\n"
    unless $method eq 'dynamicHTTPCall';
  return "$method:$args[0]";
}

sub DESTROY { }

1;
