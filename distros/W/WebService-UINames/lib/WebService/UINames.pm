package WebService::UINames;
# ABSTRACT: WebService::UINames - uinames.com API interface for Perl

# pragmas
use utf8;
use 5.10.0;

#imports 
use Moo;
use Carp;
use JSON;
use Try::Tiny;
use LWP::UserAgent;

# version
our $VERSION = 0.01;


# attributes
has '_ua' => ( 
  is => 'ro', default => sub {
    my $ua = LWP::UserAgent->new;
    $ua->agent('WebService-UINames/0.01 Perl API Client');
    return $ua;
  }
);


# methods
sub get_name {
  my ($self, $args) = (shift, {@_});

  # sending data
  my $res = $self->_ua->get(
    'http://uinames.com/api/', form => $args
  );

  my $json = {};
  try {
    $json = JSON::decode_json($res->decoded_content)
  }
  catch {
    warn "JSON Decode Exception: $_";
  };

  return $json;
}

1;
__END__

=encoding utf8

=head1 NAME

WebService::UINames - Perl module for uinames.com API

=head1 SYNOPSIS

  use WebService::UINames;

  my $uinames = WebService::UINames->new;
  my $random_user = $uinames->get_name;

  $uinames->get_name( 
    gender => 'female', region => 'brazil' 
  );

=head1 DESCRIPTION

UINames.com is a simple tool to generate names for use in designs and mockups.

=head1 METHODS

This is a list of methods that are implemented.

=head2 get_name

  my $random_user = $uinames->get_name;

  $uinames->get_name( 
    amount => 500, gender => 'female', region => 'brazil' 
  );

Get a name or list of random people names.

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2016 by Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

