package WebService::BR::Vindi;

use 5.010001;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';


# Preloaded methods go here.
use MIME::Base64;
use JSON::XS;
use utf8;

# Configura as URLs de destino baseado na tag raiz
$WebService::BR::Vindi::Target = {
 prod => {
  '*' => 'https://app.vindi.com.br:443/api/v1',
 },
};

# Error messages translator
$WebService::BR::Vindi::ErrorMessages = {
 # First is the id
 global => {
  invalid_parameter => {
   __look_for__         => 'parameter',
   payment_company_code => 'Número do Cartão de Crédito parece ser inválido.',
   card_expiration      => 'Data de validade do Cartão inválida: %s.',
   card_number          => 'Número do Cartão %s.',
   merchant             => 'Erro interno: %s.',
  },
 },
};

#
# @param  $type Tipo da requisição (nome do end-point)
# @return $URL URL de destino a utilizar para a requisição
#
sub _getURL {
 my $class = shift;
 if ( exists( $WebService::BR::Vindi::Target->{$class->{target}}->{$_[0]} ) ) {
  return $WebService::BR::Vindi::Target->{$class->{target}}->{$_[0]};
 } else {
  return $WebService::BR::Vindi::Target->{$class->{target}}->{'*'}."/$_[0]";
 }
}

#
# Contrutor
#
sub new {
 my $self = shift;

 my $class = $#_ == 0 && ref($_[0]) eq 'HASH' ? $_[0] : { @_ };

 require LWP::UserAgent;
 require HTTP::Request::Common;
 require IO::Socket::SSL;

 #IO::Socket::SSL::set_ctx_defaults(
 # SSL_verify_mode => 0,
 # SSL_version     => "TLSv1"
 #);

 $class->{target}      ||= 'prod';
 $class->{timeout}     ||= 120;
 $class->{charset}     ||= 'UTF-8';
 $class->{api_key}     ||= '';

 $class->{ua}          ||= LWP::UserAgent->new( agent           => 'WebService-BR-Vindi.pm',
                                                timeout         => $class->{timeout} || 120 );
 $class->{ua}->ssl_opts( verify_hostname => 0 );
 $class->{ua}->env_proxy;

 # JSON helper
 $class->{json} = JSON::XS->new->allow_nonref->utf8;


 bless( $class, $self );
}

#
# Make the next request (only the first next request) failsafe: if it fails, send it to the Message Bus.
#
sub failsafe {
 die 'You need to specify the "app" parameter to the constructor to use this feature (this is a proprietary implementation).' if !$_[0]->{app};
 $_[0]->{failsafe} = 1;
 $_[0];
}

sub ua      { shift->{ua} }
sub json    { shift->{json} }
sub app     { shift->{app} }



#
# Faz uma requisição
#
# @param $Endpoint    Tipo da Requisição (equivalente à tag raiz, exemplo: "requisicao-transacao")
#        \%Params     HASH a enviar com os dados (será convertido em JSON string).
# @param $Endpoint    Tipo da Requisição (equivalente à tag raiz, exemplo: "requisicao-transacao")
#        $Params      JSON string a enviar com os dados.
#
sub post {
 my $class    = shift;
 $class->{response} = $class->request( 'post', @_ );
}
sub get {
 my $class    = shift;
 $class->{response} = $class->request( 'get', @_ );
}
sub put {
 my $class    = shift;
 $class->{response} = $class->request( 'put', @_ );
}
sub delete {
 my $class    = shift;
 $class->{response} = $class->request( 'delete', @_ );
}


#
# Custom helpers
#

#
# Delete all objects of a given kind
#
# @param $endpoint Endpoint, optionally with a query filter specification of what objects to delete
#
sub delete_all {
 my $class    = shift;
 my $endpoint = shift;

 my ( $object, $query ) = split( /\?/, $endpoint );

 # Get objects that match the query 
 my $all = $class->get( $endpoint );

 my @deleted = ();
 
 # If we got data, delete one by one
 if ( $all && $all->{$object} && $#{$all->{$object}} > -1 ) {
  for my $row ( @{ $all->{$object} } ) {

   warn "delete( $object/$row->{id} )..." if $class->{debug};

   my $res = $class->delete( "$object/$row->{id}" );

   if ( $res && ref( $res ) && $res->{ErrorStatus} ) {
   } else {
    push( @deleted, $row->{id} );
   }
   
  }
 }

 return { deleted => [ @deleted ] }; 
}

#
# Retorna resposata da última requisição como HASHREF
#
# @return \%Response
#
sub response {
 if ( $_[0]->{response}->is_success ) {
  $_[0]->{json}->decode( $_[0]->{response}->decoded_content );
 } else {
  { ErrorStatus => $_[0]->{response}->status_line };
 }
}

#
# Retorna resposata da última requisição como HASHREF
#
# @return \%Response
#
sub responseAsJSON {
 if ( $_[0]->{response}->is_success ) {
  $_[0]->{response}->decoded_content;
 } else {
  $_[0]->{json}->encode( { ErrorStatus => $_[0]->{response}->status_line } );
 }
}

#
# Realiza uma requisição de dados. Uso interno.
#
# @see   #get #post #put #delete
# @param $Method   get post etc
#        $Endpoint script name, relative      
#        $Data     Dados a enviar (em geral o JSON)
#        \%Headers Cabeçalhos a enviar (nenhum necessário em geral)
#
sub request {
 my $class    = shift;
 my $Method   = shift || 'get';
 my $Endpoint = shift;
 my $Content  = shift;
 my $Headers  = shift || {};

 
 # Encode $Content in to JSON string if needed
 $Content = ref( $Content ) ?
  $class->{json}->encode( $Content ) :
  $Content;


 ( $Endpoint, my $QueryStr ) = split( /\?/, $Endpoint );
 my $URL = $class->_getURL( $Endpoint ).( $QueryStr ? "?$QueryStr" : '' );

 warn "REQUEST [$URL]: ".$Content     if $class->{debug};
 
 my $res;

 # POST
 $res = $class->{ua}->$Method(
  $URL,
#  Content_Type    => 'application/x-www-form-urlencoded',
  Content_Type    => 'application/json',
  Content_Charset => 'text/json;charset=UTF-8',
  Authorization   => "Basic ".MIME::Base64::encode_base64( $class->{api_key} ),
  %{$Headers},
  Content         => $Content,
 );

 # Debug only
 warn "RESPONSE CODE: ".$res->status_line     if $class->{debug};
 warn "RESPOSSE DATA: ".$res->decoded_content if $class->{debug};

# return $res;




 # Sucesso
 if ( $res->is_success ) {
  $class->{failsafe} = 0;

  return $class->translateErrors( $class->{json}->decode( $res->decoded_content ) );

 # Erro
 } else {

  # Send it to Message Queue if on failsafe mode
  if ( $class->{failsafe} ) {
   $class->app->message->post(
    'Vindi',
    { METHOD => $Method,
      PATH   => $Endpoint.( $QueryStr ? "?$QueryStr" : '' ),
      DATA   => $Content || undef,
      LOG    => $res->decoded_content || '',
    });
  }

  my $err = { ErrorStatus => $res->status_line };
  eval {
   my $json = $class->{json}->decode( $res->decoded_content );
   $err = $class->translateErrors( $json ) if $json->{errors} && $json->{errors}->[0];
  };
  
  $class->{failsafe} = 0;
  return $err;
 }

}


#
# Translete Vindi error messages into human friendly messages
#
sub translateErrors {
 my $class = shift;
 my $json  = shift;

 # Internal/unknown error?
 if ( !ref( $json ) ) {
  warn $json if $class->{debug};
  return { ErrorStatus => 'Erro ao comunicar com a operadora de Cobrança. Por favor verifique os dados passados e tente novamente mais tarde.' };

 # Translate it
 } elsif ( $json->{errors} ) {
  my $map = $WebService::BR::Vindi::ErrorMessages->{global};
  my $errors = {};

  # Translate error by error
  for my $error ( @{ $json->{errors} } ) {
   # By "id"
   if ( # Error id found on error map
        $map->{ $error->{id} } &&
        # Error object has the parameter it looks for
        $error->{ $map->{ $error->{id} }->{__look_for__} } &&
        # The value of the parameter of the error has an entry on the map to translate it
        $map->{ $error->{id} }->{ $error->{ $map->{ $error->{id} }->{__look_for__} } } ) {

    my $uid = $error->{id}.':'.$error->{ $map->{ $error->{id} }->{__look_for__} };
    $errors->{ $uid } ||= { messages => [], error => $map->{ $error->{id} }->{ $error->{ $map->{ $error->{id} }->{__look_for__} } } };
    push( @{ $errors->{ $uid }->{messages} }, $error->{message} ) if $#{$errors->{ $uid }->{messages}} == -1 || $errors->{ $uid }->{messages}->[-1] ne $error->{message};
   }  
  }

  # We have a translation
  if ( $#{ [ keys %{$errors} ] } > -1 ) {
   return { ErrorStatus => join( '; ', map { sprintf( $_->{error}, join( ', ', @{$_->{messages}} ) ) } values( %{$errors} ) ),
            errors => $json->{errors} };

  # No error found on ErrorMessage map
  } else {
   return { ErrorStatus => "Erro ao comunicar com a operadora de Cobrança ($json->{errors}->[0]->{id}: $json->{errors}->[0]->{parameter}: $json->{errors}->[0]->{message}). Por favor verifique os dados passados e tente novamente mais tarde.",
            errors      => $json->{errors} };
  }  
 
 # No errors, pass it on.  
 } else {
  return $json;
 }
 
}

#
# Retorna o nome da badeira do cartão baseado no número
#
# @param  $numero   Numero do cartao
# @return $bandeira Badeira do cartão, já no formato Vindi a ser enviado no JSON.
#
sub cardtype {
  my $number = $_[1];

  my $type = 'unknown';

  if ( $number =~ /^4[0-9]{12}(?:[0-9]{3})/ ) {
   $type = 'visa';

  } elsif ( $number =~ /^5[1-5][0-9]{14}/ ) {
   $type = 'mastercard';

  } elsif ( $number =~ /^3[47][0-9]{13}/ ) {
   $type = 'amex';

  } elsif ( $number =~ /^3(?:0[0-5]|[68][0-9])[0-9]{11}/ ) {
   $type = 'diners';

  } elsif ( $number =~ /^6(?:011|5[0-9]{2})[0-9]{12}/ ) {
   $type = 'discover';

  } elsif ( $number =~ /^(?:2131|1800|35\d{3})\d{11}/ ) {
   $type = 'jcb';
  }

  # TODO: "elo" e "aura"
  
  return $type;    
}

1;

__END__

=head1 NAME

WebService::BR::Vindi - Perl low level implementation of the https://vindi.com.br brazilian payment gateway.

=head1 SYNOPSIS

  use WebService::BR::Vindi;

  # Contruct the object
  my $vindi = WebService::BR::Vindi->new(
   api_key => "You API key",
   timeout => 120, # HTTP timeout
   debug   => 1 );

  # Conect to vindi REST API and get the result
  # post/get/put/delete methods always returns a perl HASHREF with the resulting data
  my $subscription = $vindi->get( 'subscriptions/1234' );

  if ( $subscription->{subscription}->{status} eq 'active' ) {
   # Do whatever you need
  }


  # A post method example with error handling
  # First parameter is the URL endpoint name - /customer
  # Second parameter is the POST DATA - which will be automatically JSON encoded and sent to the gateway
  my $customer = $vindi->post(
   'customers',
   {
     "name"          => 'Customer's name',
     "email"         => 'his@email.com',
     "registry_code" => '', 
     "code"          => 'XYZ',
   }
  );


  # Wops! Something went wrong!
  if ( $payment_profile->{ErrorStatus} ) {

   # "ErrorStatus" key try to translate the error to an human readable format whenever possible, or send whatever si possible back.
   warn "Something went terribly wrong while creating the customer: ".$customer->{ErrorStatus};

   # "error" if the vindi's plain error recieved
   warn Data::Dumper::Dumper( $customer->{error} );

  # You will probably want to keep this and INSERT in your database
  } else {
   $customer->{customer}->{id};
  }


  # A little more elaborated example - create a new payment_profile object
  my $payment_profile = $vindi->post(
   'payment_profiles',
   { "holder_name"          => 'Holder Name',
     "card_expiration"      => '12/2012',
     "card_number"          => 'XXXXXXXXXXXXXXXX',
     "card_cvv"             => 'XXX',
     "payment_method_code"  => "credit_card",
     "customer_id"          => $customer->{customer}->{id} # This is the vindi's customer ID we just created before
   }
  );

   
  # Wops! Something went wrong!
  if ( $payment_profile->{ErrorStatus} ) {
   warn "Something went terribly wrong while creating your payment profile: ".$payment_profile->{ErrorStatus};

  # All fine!
  } else {
   # Do whatever you need
   $payment_profile->{payment_profile};
  }



=head1 DESCRIPTION

This is a straight brindge to the Vindi.com.br payment gateway API.

=head1 METHDOS

=head2 new

Creates the client object.

=over

=item api_key

You secret Vindi API key. Required.

=over

=back

=item debug

Boolean, optional.

=over

=back

=item timeout

Integer, optional, defaults to 120s

=over

=back

=back

=head2 get

Make a GET request to Vindi API.

    my $customer = $vindi->get( '/customer/123' )

=over

=item endpoint

URI PATH. Required.

*** You don't need the "/v1" prefix.

=over

=back

=back

=head2 delete

Make a DELETE request to Vindi API.

    my $customer = $vindi->delete( '/customer/123' )

=over

=item endpoint

URI PATH. Required. Example: /customer/123

=over

=back

=back

=head2 put

Make a PUT request to Vindi API.

=over

=item endpoint

URI PATH. Required.

=over

=back

=back

=head2 post

Make a POST request to Vindi API. You must specify endpoint as first parameter, and a hashref as the second.

    my $customer = $vindi->post( 'customer', { name => '...', ... } )

=over

=item endpoint

URL endpoint. Required.

=over

=back

=item data

A hash to be sent.

=over

=back

=back

=head1 SEE ALSO

Please check Vindi's full v1 API docs at http://www.vindi.com.br/

=head1 AUTHOR

Diego de Lima, E<lt>diego_de_lima@hotmail.comE<gt>

=head1 SPECIAL THANKS

This module was kindly made available by the https://modeloinicial.com.br/ team.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Diego de Lima

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
