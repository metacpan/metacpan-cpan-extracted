#!/usr/bin/env perl

use WebService::GoogleAPI::Client;

use Data::Dumper qw (Dumper);
use WebService::GoogleAPI::Client::Discovery;

require Email::Simple;    ## RFC2822 formatted messages
use MIME::Base64;
use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
use feature 'say';
use JSON;
use Carp;
use strict;
use warnings;


#require Email::Sender::Simple;

#### for instructions including use of boundaries see this ..
####    https://www.techwalla.com/articles/how-to-decode-an-email-in-mime-format

### NB - gmail parts body data needs pre-processing to replace a couple of characters as per https://stackoverflow.com/questions/24745006/gmail-api-parse-message-content-base64-decoding-with-javascript

##


=pod

'description' => 'Access Gmail mailboxes including sending user email.',
            'version' => 'v1'
            'rootUrl' => 'https://www.googleapis.com/',
            'servicePath' => '/gmail/v1/users/',
                     {
                       'id' => 'gmail:v1',
                       'title' => 'Gmail API',
                       'description' => 'Access Gmail mailboxes including sending user email.',
                       'icons' => {
                                  'x16' => 'https://www.google.com/images/icons/product/googlemail-16.png',
                                  'x32' => 'https://www.google.com/images/icons/product/googlemail-32.png'
                                },
                       'name' => 'gmail',
                       'preferred' => true,
                       'discoveryRestUrl' => 'https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest',
                       'version' => 'v1',
                       'documentationLink' => 'https://developers.google.com/gmail/api/',
                       'kind' => 'discovery#directoryItem',
                       'discoveryLink' => './apis/gmail/v1/rest'
                     },
## SEE ALSO - https://github.com/APIs-guru/openapi-directory/blob/master/APIs/googleapis.com/gmail/v1/swagger.yaml 

=head2 GOALS

  - show summary details pulled from discovery docs 
  - show all methods in HTML table with description including code snippets for worked examples
  - describe helper functions the simplify data handling
  - inform improvements to core Modules ( param parsing / validation / feature evolution etc )
  - idenitfy opportunities for use in full working applications 


=head2 LIST 

 SCOPES TO access messages->list->
        'https://mail.google.com/',
        'https://www.googleapis.com/auth/gmail.metadata',
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/gmail.readonly'

 
=head2 GET {userId}/messages/{id}

  {
      format => [ ... 'full', ],

  }
        'https://mail.google.com/',
        'https://www.googleapis.com/auth/gmail.metadata',
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/gmail.readonly'

=head2 send

    'httpMethod' => 'POST'
    path' => '{userId}/messages/send',
    'mediaUpload' => { accept =>'message/rfc822', maxSize => 35MB, protocols=> {simple=> resumable => }

        'https://mail.google.com/',
        'https://www.googleapis.com/auth/gmail.compose',
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/gmail.send'



=cut

my $DEBUG = 001;


##    BASIC CLIENT CONFIGURATION

if   ( -e './gapi.json' ) { say "auth file exists" }
else                      { croak( 'I only work if gapi.json is here' ); }
;    ## prolly better to fail on setup ?
my $gapi_agent        = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json => './gapi.json' );
my $aref_token_emails = $gapi_agent->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_agent->user( $user );

say "Running tests with default user email = $user";
say 'Root cache folder: ' . $gapi_agent->discovery->chi->root_dir();                                         ## cached content temporary directory
say "User Agent Name = " . $gapi_agent->ua->transactor->name();

if ( 1 == 0 )
{
  #my $api_spec = $gapi_agent->get_api_discovery_for_api_id('gmail:v1');
  #my $api_spec = $gapi_agent->get_api_discovery_for_api_id('gmail.users.messages.list');
  #my $api_spec = $gapi_agent->get_api_discovery_for_api_id('gmail:v1.users.messages.list');
  my $api_spec = $gapi_agent->get_api_discovery_for_api_id( 'gmail' );
  ## keys = auth, basePath, baseUrl, batchPath, description, discoveryVersion, documentationLink, etag, icons, id, kind, name, ownerDomain, ownerName, parameters, protocol, resources, revision, rootUrl, schemas, servicePath, title, version
  say join( ', ', sort keys %{ $api_spec } );
  foreach my $k ( qw/schemas resources auth / ) { $api_spec->{ $k } = 'removed to simplify'; }    ## SIMPLIFY OUTPUT
  say Dumper $api_spec;

  my $meths_by_id = $gapi_agent->methods_available_for_google_api_id( 'gmail' );
  foreach my $meth ( keys %{ $meths_by_id } )
  {
    say "$meth";
  }

  # say $gapi_agent->api_query( api_endpoint_id => 'gmail.users.getProfile')->to_string;
  # say $gapi_agent->api_query( api_endpoint_id => 'gmail.users.messages.list')->to_string;
  foreach my $meth ( qw/ gmail.users.messages.list gmail:v1.users.messages.list /
    ) ##  gmail.users.settings.getVacation  gmail.users.settings.getImap gmail.users.settings.filters.list    -- FAILERS - gmail.users.messages.get gmail.users.settings.sendAs.smimeInfo.get gmail.users.threads.get
  {
    say "Testing endpoint '$meth' with no additional options";
    my $r = $gapi_agent->api_query( api_endpoint_id => $meth, options => {} );
    say $r->to_string;
    say $r->body;
  }
  exit;

}


if ( 1 == 1 )    ## Simplified use Cases
{
  say $gapi_agent->api_query(
    api_endpoint_id => 'gmail.users.messages.send',
    options         => {
      raw => encode_base64(
        Email::Simple->create( header => [To => $user, From => $user, Subject => "Test email from $user",], body => "This is the body of email from $user to $user", )->as_string
      ),
    },
  )->to_string;    ##

  print $gapi_agent->api_query(
    api_endpoint_id => 'gmail.users.messages.list',    ## auto sets method to GET, path to
  )->to_string;

  #print Dumper $r;
  exit;

}


#exit;
#say Dumper $gapi_agent->Gmail->Users->getProfile( { userId => 'me' } )->json;    # if ( );
#print Dumper $gapi_agent->discovery->list_of_methods;

#exit;
#say Dumper $gapi_agent->Gmail->Users->Messages->list( { userId => 'me'  } )->json; ## NB This doesn't work - assuming too deep
#print Dumper $x;

#croak('croak exiting early because DEBUG set') if $DEBUG;
## Comment out / Uncomment to enable/disable test the Gmail API functions
send_email_to_self_using_client( $gapi_agent );

#review_emails_from_last_month_using_agent( $gapi_agent );


#######################################################

=pod

=head2 review_emails_from_last_month_using_agent( $gapi )

A simple email send example. Creates an encoded RFC

TODO: 
* handle pagination where results list exceeds single query response maximimum - indicated by tokens in reponse

REFERENCES:
  construct 'q' query filters as per https://support.google.com/mail/answer/7190?hl=en

=cut

#######################################################
sub review_emails_from_last_month_using_agent
{
  my ( $gapi ) = @_;
  my $ret      = [];                   ##
  my $cl       = $gapi->api_query( {
    httpMethod => 'get',
    path       => "https://www.googleapis.com/gmail/v1/users/me/messages?q=newer_than:1d;to:$user",

  } );
  if ( $cl->code eq '200' )            ## Mojo::Message::Response
  {
    say $cl->to_string;
    say "resultSizeEstimate = " . $cl->json->{ resultSizeEstimate };
    foreach my $msg ( @{ $cl->json->{ messages } } )
    {
      # print qq{$msg->{id} :: $msg->{threadId}\n};
      ## GET THE MESSAGE CONTENT
      push @$ret, get_email_content_from_id_using_agent( $msg->{ id }, $gapi );
    }
  }
  else
  {
    croak Dumper $cl;
  }
  return $ret;
}
#######################################################


=pod

=head2 get_email_content_from_id_using_agent( $id, $gapi )

Get a single email and extract content


TODO: extract the attachments

=cut

#######################################################
sub get_email_content_from_id_using_agent
{
  my ( $id, $gapi ) = @_;

  my $retval = { id => $id, Subject => undef, From => undef, 'Delivered-To' => undef, snippet => undef, decoded_parts_by_mimetype => { 'text/html' => [] } };

  my $cl = $gapi->api_query( { httpMethod => 'get', path => 'https://www.googleapis.com/gmail/v1/users/me/messages/' . $id, } );
  ## TODO - what is the simplified version ?
  #   my $cl = $gapi->api_query( api_endpoint_id => 'gmail.users.messages' , options => { id => $id } )


  if ( $cl->code eq '200' )    ## Mojo::Message::Response
  {
    #say $cl->to_string;
    my $boundary = '';         ## get boundary to use as glue between multiparts - haven't finished this - more testing required
    my $headers  = {};         ## payload provides as an array - wrapping into a hash for interested header names
    foreach my $header ( @{ $cl->json->{ payload }{ headers } } )
    {

      #print qq{$header->{name}\n};
      if ( $header->{ name } eq 'Content-Type' )
      {

        if ( $header->{ value } =~ /multipart\/alternative; boundary="(.*?)"/mx )
        {
          #print "Got $header->{value} with $1\n";
          $boundary = $1;
        }
      }
      elsif ( $header->{ name } =~ /Subject|From|Delivered-To/mx )
      {
        $headers->{ $header->{ name } } = $header->{ value };
        print "$header->{ name }  = $header->{ value }\n";
      }
    }
    print $cl->json->{ snippet } . "\n";    # if $DEBUG;
    print Dumper $headers if $DEBUG;

    ## process each of the email MIME multiparts
    ## TODO: connect togeteher the multi-part components for attachments etc - some debugging info prints are included to guide this
    foreach my $p ( @{ $cl->json->{ payload }{ parts } } )
    {
      if ( defined $p->{ body }{ data } and defined $boundary )
      {
        print "\n --- match found in raw body data ----\n" if $p->{ body }{ data } =~ /$boundary/mx;
        ## A GOOGLE SPECIFIC HACK REQUIRED AS PER https://stackoverflow.com/questions/24745006/gmail-api-parse-message-content-base64-decoding-with-javascript
        $p->{ body }{ data } =~ s/-/+/xsmg;
        $p->{ body }{ data } =~ s/_/\//xsmg;
        print "\n --- match found after subs ----\n" if $p->{ body }{ data } =~ /$boundary/mx;
        my $decoded_part = decode_base64( $p->{ body }{ data } );
        print "\n --- match found after decoding ----\n" if $decoded_part =~ /$boundary/mx;

        if ( $p->{ mimeType } =~ /text/m )
        {

          #print $decoded_part if $DEBUG;
        }
      }
    }
  }
  else
  {
    croak Dumper $cl;
  }

  #print 'x' x 80 . "\n" if $DEBUG;
  return $retval;
}
#######################################################

=pod

=head2 send_email_to_self_using_client( $gapi )

A simple email send example. Creates an encoded RFC

TODO: 
* refactor to use email address from config file

=cut

#######################################################
sub send_email_to_self_using_client
{
  my ( $gapi ) = @_;
  my $cl = $gapi->api_query( {
    httpMethod => 'post',                                                                                                                ## method as key should also work fine
    path       => 'https://www.googleapis.com/gmail/v1/users/me/messages/send',
    options    => { raw => construct_base64_email( $user, "Test email from $user", "This is the body of email from $user to $user" ) }
  } );
  if ( $cl->code eq '200' )                                                                                                              ## Mojo::Message::Response
  {
    say $cl->to_string;
  }
  else
  {
    croak Dumper $cl;
  }
  return $cl;
}
#######################################################

#######################################################
sub construct_base64_email
{
  my ( $address, $subject, $body ) = @_;

  my $email = Email::Simple->create( header => [To => $user, From => $user, Subject => $subject,], body => $body, );
  return encode_base64( $email->as_string );
}
#######################################################


=pod

=encoding UTF-8

=head1 NAME

gmail_example.pl - gmail service examples

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    gmail_example.pl [gapi.json] 

=head2 Assumptions

* scope within gapi.json authorises read access to Gmail APIs

=head1 AUTHOR

Peter Scott <peter@pscott.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Peter Scott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
