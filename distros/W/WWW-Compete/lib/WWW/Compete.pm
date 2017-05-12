package WWW::Compete;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.03';

use Carp;
use LWP::UserAgent;
use XML::Simple;

use constant COMPETE_VERSION => '3';  


# Preloaded methods go here.

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

  $self->{'_ver'}        = $args->{'ver'} || COMPETE_VERSION;
  $self->{'_debug'}      = $args->{'debug'};
  $self->{'_key'}        = $args->{'api_key'};
  $self->{'_return_int'} = $args->{'return_int'} || 0;
  $self->{'_ua'}         = LWP::UserAgent->new();

  return 1;
}

sub api_key {
  my $self = shift;
  my $key  = shift;

  if ($key) {
    $self->{'_key'} = $key;
  }

  return $self->{'_key'};
}

sub api_ver {
  my $self = shift;
  my $ver  = shift;

  if ($ver) {
    $self->{'_ver'} = $ver;
  }

  return $self->{'_ver'};
}

sub ua {
  my $self = shift;
  my $ua   = shift;

  if ($ua) {
    $self->{'_ua'}->agent($ua);
  }

  $self->{'_ua'}->agent();
}

sub fetch {
  my $self   = shift;
  my $domain = shift;

  $self->_reset();

  carp("No API key!") && return unless $self->api_key();
  carp("Nothing to fetch!") && return unless $domain;

  $self->{'_current_domain'} = $domain;

  $self->{'_response'} =
    $self->{'_ua'}->get($self->_build_url($domain));

  $self->{'_response_data'} = XMLin($self->{'_response'}->content(),
                                    NormalizeSpace => 2,
                                    SuppressEmpty  => "" );
}

sub get_measurement_yr {
  my $self = shift;

  return $self->{'_response_data'}->{dmn}->{metrics}->{val}->{yr} || "";
}

sub get_measurement_mon {
  my $self = shift;

  return $self->{'_response_data'}->{dmn}->{metrics}->{val}->{mth} || "";
}

sub get_domain {
  my $self = shift;

  return $self->{'_current_domain'} || "";
}

sub get_visitors {
  my $self = shift;

  my $visitors = $self->{'_response_data'}->{dmn}->{metrics}->{val}->{uv}->{count} || "";

  if ($self->{'_return_int'}) {
    $visitors =~ s/[^\d]//g;
    return $visitors;
  } else {
    return $visitors;
  }

}

sub get_rank {
  my $self = shift;

  my $ranking = $self->{'_response_data'}->{dmn}->{metrics}->{val}->{uv}->{ranking} || "";

  if ($self->{'_return_int'}) {
    $ranking =~ s/[^\d]//g;
    return $ranking;
  } else {
    return $ranking;
  }
}

sub get_trust {
  my $self = shift;

  return $self->{'_response_data'}->{dmn}->{trust}->{val} || "";
}

sub get_summary_link {
  my $self = shift;

  $self->{'_response_data'}->{dmn}->{metrics}->{link};
}

sub _build_url {
  my $self   = shift;
  my $domain = shift;

  my $url = 'http://api.compete.com/fast-cgi/MI?d=' . $domain .
            '&ver=' . $self->{'_ver'} .
            '&apikey=' . $self->{'_key'};

  return $url;
}

sub _reset {
  my $self = shift;

  $self->{'_current_domain'} = undef;
  $self->{'_response'}       = undef;
  $self->{'_response_data'}  = undef;
}

1;
__END__


=head1 NAME

WWW::Compete - Simple OO interface for retrieving site rank, traffic stats, and trust rating from www.compete.com

=head1 SYNOPSIS

  use WWW::Compete;

  use constant COMPETE_API_KEY => 'XXXXX'; 

  my $c = WWW::Compete->new({api_key => COMPETE_API_KEY}); 
  $c->fetch("cpan.org");

  $c->get_measurement_yr(); 
  $c->get_measurement_mon();
  $c->get_trust();         
  $c->get_visitors();     
  $c->get_rank();        
  $c->get_summary_link();       

=head1 DESCRIPTION

This module is a simple wrapper around the Site Analytics API offered by www.compete.com.  You can use this to basic traffic-related statistics for your favorite, or even your least favorite, domain.

=head1 METHODS 

=over 

=item WWW::Compete->new(\%args)

Valid arguments:

=over 4

=item * 

B<api_key>

I<string>. Compete API key

=item *

B<api_ver>

I<string>  Version of the Compete API you wish to use.  Defaults to 3.

=item *

B<return_int>

I<boolean>  If value evaluates to true, formatting will be removed from visitor counts an rank.  For example, you'll get '4321567' instead of '4,321,567.' Defaults to false.

=back

=item $c->api_key();

=item $c->api_key( COMPETE_API_KEY );

Get/set the Compete API key to be used.  

=item $c->api_ver();

=item $c->api_ver( $api_version );

Get/set the Compete API version you want to interact with.  Default is 3.

=item $c->ua();

=item $c->ua( $user_agent );

Get/set the User-Agent header sent with your API requests.  By default this is "libwwww-perl/#.##".  Depending on what you're doing you may want to pass something else.

=item $c->fetch( $domain );

Send a request to the Compete API asking for stats on $domain.

=item $c->get_measurement_yr()

Returns the year for the measurement.

=item $c->get_measurement_mon()

Returns the month for the measurement.

=item $c->get_domain()

Returns the current domain.

=item $c->get_visitors()

Returns the unique visitor estimate for measurement year and month.

=item $c->get_rank()

Returns ranking for the domain, based on unique visitor estimates.

=item $c->get_trust()

Returns trust rating for the domain. 

=item $c->get_summary_link()

Returns a link to Compete's traffic summary page for the domain.

=back

=head1 SEE ALSO

This module is a wrapper around the Compete Site Analytics API.  Additional detail on the API, and also on how to get a developer key, is available here. 

http://developer.compete.com/

=head1 AUTHOR

Chris Mills, E<lt>cmills@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Chris Mills

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
