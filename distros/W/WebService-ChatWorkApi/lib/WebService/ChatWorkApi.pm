use strict;
use warnings;
package WebService::ChatWorkApi;
use WebService::ChatWorkApi::UserAgent;
use WebService::ChatWorkApi::DataSet;
use Readonly;
use String::CamelCase qw( camelize );
use Mouse;
use Smart::Args;
use Class::Load qw( try_load_class );

# ABSTRACT: A client library for ChatWork API

our $VERSION = '0.01';

Readonly my $DATASET_CLASS => "WebService::ChatWorkApi::DataSet";

has ua => ( is => "rw", isa => "WebService::ChatWorkApi::UserAgent" );

sub new {
    args my $class,
         my $api_token,
         my $base_url => { optional => 1 };

    my $self = bless {
        ua => WebService::ChatWorkApi::UserAgent->new(
            api_token => $api_token,
            ( defined $base_url ? ( base_url  => $base_url ) : ( ) ),
        ),
    }, $class;

    return $self;
}

sub ds {
    args_pos my $self,
             my $name;
    my $class_name = join q{::}, $DATASET_CLASS, camelize( $name );
    try_load_class( $class_name )
        or die "Could not load $class_name";
    return $class_name->new(
        dh => $self->ua,
        @_,
    );
}

1;

__END__
=encoding utf8

=head1 NAME

WebService::ChatWorkApi - An ORM Styled ChatWork API Client

=head1 SYNOPSIS

  use utf8;
  use WebService::ChatWorkApi;
  my $connection = WebService::ChatWorkApi->new(
      api_token => $api_token,
  );
  my $dataset = $connection->ds( "me" );
  my $me = $dataset->retrieve;
  my( $room ) = $me->rooms( name => "マイチャット" );
  my @messages = $room->new_messages;
  $room->post_message( "asdf" );

=head1 DESCRIPTION

ChatWork provides REST API to access their web chat service.

Onece API is provided, there will be perl API module.
Then ChatWork API exists too.  See `SEE ALSO` to what modules
are released before this module.

I think these modules is a user agent module, but I want to write
API client likes Object Relation Mapping.

=head1 SUB MODULES

- WebService::ChatWorkApi::UserAgent
- WebService::ChatWorkApi::Response
- WebService::ChatWorkApi::DataSet
- WebService::ChatWorkApi::Data

=head1 SEE ALSO

- L<API Document|http://developer.chatwork.com/ja/>
- L<WebService::Chatwork|https://github.com/naoto43/perl-webservice-chatwork>
- L<WWW::Chatwork::API|https://github.com/takaya1992/p5-WWW-Chatwork-API>
