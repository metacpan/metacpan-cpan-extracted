package WebService::Annict::Episodes;
use 5.008001;
use strict;
use warnings;

use URI;

sub new {
  my ($class, $ua) = @_;

  bless {
    ua => $ua,
  }, $class;
}

sub get {
  my ($self, %args) = @_;
  my $url = URI->new("https://api.annict.com/v1/");

  $url->query_form(\%args);
  $self->{ua}->get($url->as_string);
}

1;
