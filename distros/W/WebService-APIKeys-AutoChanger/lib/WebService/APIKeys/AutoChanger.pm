package WebService::APIKeys::AutoChanger;

use strict;
use warnings;
use Carp;
use List::Util qw(first);
use Data::Valve;
use UNIVERSAL::require;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.00002';

__PACKAGE__->mk_accessors($_)
  for qw(api_keys throttle throttle_class throttle_config);

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    if($self->throttle_class || $self->throttle_config){
        $self->set_throttle(@_);
    }
    return $self;
}

sub set {
    my $self = shift;
    my %args = @_;
    $self->set_api_keys( $args{api_keys} );
    unless ( $self->throttle ) {
        $self->set_throttle(
            throttle_class  => $args{throttle_class},
            throttle_config => $args{throttle_config},
        );
    }
}

sub set_api_keys {
    my $self     = shift;
    my $api_keys = shift;
    if ( ref $api_keys ne 'ARRAY' ) {
        carp("Set an array reference as API-Keys.");
        return;
    }
    else {
        $self->api_keys($api_keys);
    }
}

sub set_throttle {
    my $self           = shift;
    my %args           = @_;
    my $throttle_class = $args{throttle_class} || 'Data::Valve';
    $throttle_class->require;
    $self->throttle(
        $throttle_class->new(
            max_items => 50000,
            interval  => 86400,
            %{ $args{throttle_config} },
        )
    );
}

sub get_available {
    my $self    = shift;
    my $n       = 0;
    my $api_key = first {
        if ( $self->throttle->try_push( key => $_ ) ) {
            1;
        }
        else {
            $n++;
            undef;
        }
    }
    @{ $self->api_keys };
    $self->_rotate_api_keys($n) if ($n);
    if ($api_key) {
        return $api_key;
    }
    else {
        carp("You have run out of your api-key limit.");
		return undef;
    }
}

sub _rotate_api_keys {
    my $self     = shift;
    my $n        = shift;
    my @api_keys = @{ $self->api_keys };
    for ( 1 .. $n ) {
        my $api_key = shift @api_keys;
        push @api_keys, $api_key;
    }
    $self->api_keys( \@api_keys );
}

1;
__END__

=head1 NAME

WebService::APIKeys::AutoChanger - Throttler and auto-changer for Web-API's restriction.

=head1 SYNOPSIS

For example, use it with WebService::Simple for YahooJapan Web-API.

  use WebService::Simple;
  use WebService::APIKeys::AutoChanger;
  use Data::Dumper;
  
  my $changer = WebService::APIKeys::AutoChanger->new;
  
  $changer->set(
      api_keys => [
          'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
          'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
          'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
      ],
      ## you don't have to set below explicitly
      throttle_class   => 'Data::Valve', # backend throttler class. (default: Data::Valve)
      throttle_config  => { 
          max_items  => 50000,         # default: 50000
          interval   => 86400,         # default: 86400
      },
  );
  
  my $yahooJapan = WebService::Simple->new(
      base_url => 'http://search.yahooapis.jp/WebSearchService/V1/webSearch',
  );
  
  my @query = qw( foo bar baz ... );
  for my $query(@query){
      # available APIKey(appid) will be changed automatically
      my $available_key = $changer->get_available;
      # you can use it
      my $response = $yahooJapan->get( {
          appid => $available_key,
          query => $query } );
      do_something($response);
  }

=head1 DESCRIPTION

WebService::APIKeys::AutoChanger is a throttler and auto-changer for Web API's restriction.

For example, YahooJapan sets a restriction 50,000 times per day as an API-key.
You can use it over the limitation if you set plural APIKey beforehand. 

This module provides available-key, seamlessly.

=head1 METHODS

=over 4

=item new(I<[%args]>)

    my $changer = WebService::APIKeys::AutoChanger->new(
        api_keys => \@api_keys,
        throttle_class => 'Data::Valve',
        throttle_config => {
            max_items  => 50000,
            interval   => 86400,
        } 
    );

Create and return new WebService::APIKeys::AutoChanger object.
You can set api-keys and throttle information as option parameters.

=item set(I<%api_keys, [%throttle_class], [%throttle_config]>);

    $changer->set(
        api_keys => \@api_keys,
        throttle_class => 'Data::Valve',
        throttle_config => {
            max_items  => 50000,
            interval   => 86400,
        } 
    );

If your circumstance does not allow use Moose, 
set 'Data::Throttler' instead of 'Data::Valve' for throttle_class.
(But Data::Throttler is slower than Data::Valve)

=item get_available

Returns an available API Key at that point.

=item set_api_keys(I<\@api_keys>)

=item set_throttle(I<%args>)

=back

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
