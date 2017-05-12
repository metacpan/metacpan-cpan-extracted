package WWW::Honeypot::httpBL;

use 5.008008;
use strict;
use warnings;

use Carp;
use Net::hostent;
use Socket;

use constant 'LOOKUP_DOMAIN' => 'dnsbl.httpbl.org';

our $VERSION = '0.01';

my $search_engines = {
  '0' => 'Undocumented',
  '1' => 'Alta Vista',
  '2' => 'Ask',
  '3' => 'Baidu',
  '4' => 'Excite',
  '5' => 'Google',
  '6' => 'Looksmart',
  '7' => 'Lycos',
  '8' => 'MSN',
  '9' => 'Yahoo',
  '10' => 'InfoSeek',
  '11' => 'Miscellaneous'
};

sub new {
  my $pkg = shift;

  my $self = {};
  bless $self, $pkg;

  if (! $self->_init(@_)) {
    return undef;
  }

  return $self;
}

sub _init {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  $self->{'_debug'}      = $args->{'debug'};
  $self->{'_key'}        = $args->{'access_key'};
  $self->{'_current_ip'}              = '';
  $self->{'_current_response'}        = '';
  $self->{'_current_response_octets'} = [];

  return 1;
}

sub access_key {
  my $self = shift;
  my $key  = shift;

  if ($key) {
    $self->{'_key'} = $key;
  }

  return $self->{'_key'};
}

sub fetch {
  my $self = shift;
  my $ip   = shift;

  $self->_reset();

  carp("No Access Key!") && return unless $self->access_key();
  carp("Nothing to fetch!") && return unless $ip;

  unless ($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
     my $err_str = "That doesn't look like an IP address!";
     carp($err_str) && return $err_str; 
  }

  $self->_lookup($self->_reverse_IP($ip)); 
  
  return $self->{_current_response} ? ($self->_parse_response()) : undef;
}

sub threat_score {
  my $self = shift;

  return ( $self->{_current_response} && !$self->is_search_engine() ) ? 
           ${$self->{_current_response_octets}}[2] : undef;
}

sub days_since_last_actvity {
  my $self = shift;

  return ( $self->{_current_response} && !$self->is_search_engine() ) ? 
           ${$self->{_current_response_octets}}[1] : undef;
}

sub is_search_engine {
  my $self = shift;

  return undef unless $self->{_current_response};

  if ( ${$self->{_current_response_octets}}[3] == 0 ) {
    my $serial_number = ${$self->{_current_response_octets}}[2];
    return $search_engines->{$serial_number};
  } else {
    return;
  }
}

sub is_suspicious {
  my $self = shift;

  return undef unless $self->{_current_response};

  my $c = ${$self->{_current_response_octets}}[3];
  if ($c == 1 || $c == 3 || $c == 5 || $c == 7) {
    return 1;
  } else {
    return undef;
  }
}

sub is_harvester {
  my $self = shift;

  return undef unless $self->{_current_response};

  my $c = ${$self->{_current_response_octets}}[3];
  if ($c == 2 || $c == 3 || $c == 6 || $c == 7) {
    return 1;
  } else {
    return undef;
  } 
}

sub is_comment_spammer {
  my $self = shift;

  return undef unless $self->{_current_response};

  my $c = ${$self->{_current_response_octets}}[3];

  if ($c == 4 || $c == 5 || $c == 6 || $c == 7) {
    return 1;
  } else {
    return undef;
  } 
}

# Internal methods below

sub _lookup {
  my $self        = shift;
  my $reversed_ip = shift;

  my $str = join('.', $self->access_key(), $reversed_ip, LOOKUP_DOMAIN);

  my $h   = gethost($str);

  return unless $h;

  $self->{_current_response} = inet_ntoa($h->addr);
}

sub _reverse_IP {
  my $self = shift;
  my $ip   = shift;

  my @parts = split(/\./, $ip);
  return join('.', reverse(@parts));
}

sub _parse_response {
  my $self = shift;

  my @octets = split(/\./, $self->{_current_response});
  push(@{$self->{_current_response_octets}}, @octets);
  return @octets; 
}

sub _reset {
  my $self = shift;

  $self->{'_current_ip'}              = '';
  $self->{'_current_response'}        = '';
  $self->{'_current_response_octets'} = [];
}

1;
__END__

=head1 NAME

WWW::Honeypot::httpBL - Perl interface to Project Honeypot's Http:BL Service 

=head1 SYNOPSIS

  use WWW::Honeypot::httpBL;

  my $h = WWW::Honeypot::httpBL->new( { access_key => $ENV{'HTTPBL_ACCESS_KEY'} });
  $h->fetch('127.1.1.6');

  # Is this IP associated with email harvesting?
  $h->is_harvester();

  # How about comment spamming?
  $h->is_comment_spammer();

  # Is it a search engine?  
  $h->is_search_engine();

  # Is this IP just suspicious, as opposed to known evil?
  $h->is_suspicious();

  # What is the threat score?
  $h->threat_score();

  # How many days since the last actvity?
  $h->days_since_last_activity();


=head1 DESCRIPTION

You will need an API key to get started, they are available here: 

http://www.projecthoneypot.org/

Once you have that, you can use this to determine whether a particular IP falls into one or more of these categories:

=over 2

=item * Search Engine

=item * Suspected Comment Spammer

=item * Suspected Email Harvester

=item * Known Comment Spammer

=item * Known Email Harvester 

=back

=head1 METHODS

=over

=item $h->fetch();

When given a valid IP, this method executes a lookup against Project Honeypot's http:BL service.  Does not accept a domain name, IP addr only.

=item $h->is_harvester();

Returns 1 if the IP in question is associated with email harvesting, otherwise returns undef.

=item $h->is_comment_spammer();

Returns 1 if the IP in question is associated with comment spamming, otherwise returns undef.

=item $h->is_search_engine();

Returns the search engine name if the IP in question is a known search engine, otherwise returns undef.  Supported search engines at this point are:

=item * Undocumented

=item * Alta Vista

=item * Ask

=item * Baidu

=item * Excite

=item * Google

=item * Looksmart

=item * Lycos

=item * MSN

=item * Yahoo 

=item * InfoSeek

=item * Miscellaneous

=item

=item $h->is_suspicious();

Returns 1 if the IP in question is deemed suspicious, otherwise returns undef.  "Suspicious" means observed acting like a malicious bot, but so far not observed being malicious -- for example, caught harvesting emails but not yet caught spamming those addresses.

An important nuance is that once an IP is actually observed to be malicious, it is no longer considered "suspicious" which means this method will return undef. Put another way, undef sometimes indicates a higher grade of evil than the 1 this method will often return.

=item $h->threat_score();

Returns an integer between 0-255 representing the threat score for this IP.  This is an indicator of how dangerous an IP is, based on it's observed activity to date.  The scale is logarithmic, which means high numbers are extremely rare (and evil).  See the Project Honeypot documentation for more info. 

=item $h->days_since_last_actvity();

Returns an integer between 0-255 representing the number of days since the IP was last observed on the project's network.  This is an indicator of how active the IP currently is. 

=back

=head1 SEE ALSO

API keys and more detail on Project Honeypot are available at http://www.projecthoneypot.org/.

Spam sucks.  Please support Project Honeypot.

=head1 AUTHOR

Chris Mills, E<lt>cmills@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Chris Mills

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
