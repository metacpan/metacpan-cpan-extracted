package WebService::BR::AceitaFacil;

use strict;
use MIME::Base64;
use JSON::XS;
use utf8;

# Configura as URLs de destino baseado na tag raiz
$WebService::BR::AceitaFacil::Target = {
 sandbox => {
  '*' => 'https://sandbox.api.aceitafacil.com',
 },
 api => {
  '*' => 'https://api.aceitafacil.com',
 },
};

#
# @param  $type Tipo da requisição (nome do end-point)
# @return $URL URL de destino a utilizar para a requisição
#
sub _getURL {
 my $class = shift;
 if ( exists( $WebService::BR::AceitaFacil::Target->{$class->{target}}->{$_[0]} ) ) {
  return $WebService::BR::AceitaFacil::Target->{$class->{target}}->{$_[0]};
 } else {
  return $WebService::BR::AceitaFacil::Target->{$class->{target}}->{'*'}."/$_[0]";
 }
}

#
# Contrutor
#
# @define $target  Define o destino do WS: "test" (padrão) ou "prod" (para produção)
#         $timeout Timeout em segundos para a requisição
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

 $class->{target}      ||= 'api';
 $class->{timeout}     ||= 120;
 $class->{charset}     ||= 'UTF-8';
 $class->{api_key}     ||= '';

 $class->{ua}          ||= LWP::UserAgent->new( agent           => __PACKAGE__,
                                                timeout         => $class->{timeout} || 120 );
 $class->{ua}->ssl_opts( verify_hostname => 0 );
 $class->{ua}->env_proxy;

 # JSON helper
 $class->{json} = JSON::XS->new->allow_nonref->utf8;


 bless( $class, $self );
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
 my $Content = ref( $Content ) ?
  $class->{json}->encode( $Content ) :
  $Content;


 ( $Endpoint, my $QueryStr ) = split( /\?/, $Endpoint );
 my $URL = $class->_getURL( $Endpoint ).( $QueryStr ? "?$QueryStr" : '' );

 warn "REQUEST [$URL]: ".$Content     if $class->{debug};
 
 my $res;

 # POST
 $res = $class->{ua}->$Method(
  $URL,
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

  my $err = { ErrorStatus => $res->status_line };
  eval {
   my $json = $class->{json}->decode( $res->decoded_content );
   $err = $class->translateErrors( $json ) if $json->{errors} && $json->{errors}->[0];
  };
  
  return $err;
 }

}

#
# Translete AceitaFacil error messages into human friendly messages
#
sub translateErrors {
 my $class = shift;
 my $json  = shift;

 # Internal/unknown error?
 if ( !ref( $json ) ) {
  warn $json;
  return { ErrorStatus => 'Erro ao comunicar com a operadora de Cobrança. Por favor verifique os dados passados e tente novamente mais tarde.' };

 # Translate it
 } elsif ( $json->{errors} && ref( $json->{errors} ) eq 'ARRAY' ) {
 
  my $errstr = join( ';', @{$json->{error}->[0]->{message}} );

  return { ErrorStatus => $errstr || undef, errors => $json->{errors} };
 
 # No errors, pass it on.  
 } else {
  return $json;
 }
 
}

1;

__END__

=head1 NAME

WebService::BR::AceitaFacil - Perl low level implementation of the https://aceitafacil.com.br brazilian payment gateway.

=head1 SYNOPSIS

  use WebService::BR::AceitaFacil;

  my $gateway = new WebService::BR::AceitaFacil( api_key => 'YOUR SECRET KEY' );

  # Or, if you want to use the sandbox:
  my $gateway = new WebService::BR::AceitaFacil( api_key => 'YOUR SECRET KEY', target => 'sandbox' );

  # Create a new bankslip and the the PDF download URL of the document.
  my $response = $gateway->post(
   'operation',
   { buyer => {
      id => "..."
     },
     items => [{
       vendor      => { id => "..." },
       amount      => 123.45,
       description => 'My cool product'
     }],
     payment_method => "BOLETO_UNREGISTERED"
   }
  );

  # Error
  if ( !$response || $response->{ErrorStatus} || !$response->{boleto_url} ) {

   print $response->{ErrorStatus} || 'UNKNOWN ERROR';  

  # OK
  } else {

   print $response->{boleto_url};

  }


  # Check if a previously created bankslip was is paid or not.
  my $invoice = $gateway->get( 'invoice/< INVOICE ID HERE >' );

  print $invoice->{paid_amount};
  print $invoice->{total_amount};

=head1 DESCRIPTION

This is a straight brindge to the AceitaFacil.com.br payment gateway API.

=head1 SEE ALSO

Please check AceitaFacil's full API docs at http://www.aceitafacil.com.br/ (you will need an API key to access this page).

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
