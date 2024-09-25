package WebService::Xential;
our $VERSION = '0.003';
use v5.26;
use Object::Pad;

# ABSTRACT: A Xential REST API module

class WebService::Xential;
use Carp qw(croak);
use OpenAPI::Client;
use Try::Tiny;
use Mojo::Content::Single;
use Mojo::Asset::Memory;
use JSON::XS qw(encode_json);
use Types::Serialiser qw();
use MIME::Base64 qw(encode_base64url);

field $api_key :param;
field $api_user :param;
field $api_host :param :accessor;
field $api_port :param = undef;
field $api_path :param = '/xential/modpages/next.oas/api';
field $client :accessor;


ADJUST {

    my $definition = sprintf('data://%s/xential.json', ref $self);

    $client = OpenAPI::Client->new($definition);

    my $host = Mojo::URL->new();
    $host->scheme('https');
    $host->host($api_host);
    $host->path($api_path);

    $client->base_url($host);

    $client->ua->on(
      start => sub ($ua, $tx) {

        $tx->req->headers->add("Accept" => "application/json");

        unless ($tx->req->headers->header('XSessionID')) {
          $tx->req->headers->header(
            "Authorization" =>
              join(" ", "Basic", encode_base64url("$api_user:$api_key")),
          );
        }
      }
    );

    $client->ua->transactor->add_generator(
      'createData' => \&create_ticket_data);
}

sub create_ticket_data {
  my $t  = shift;
  my $tx = shift;

  $tx->req->headers->content_type('multipart/form-data');
  my $headers = $tx->req->headers;

  my $data = shift;

  my $xml     = Mojo::Content::Single->new();
  my $options = Mojo::Content::Single->new();

  $options->asset(
    Mojo::Asset::Memory->new->add_chunk(
      encode_json($data->{options})
    )
  );

  $xml->asset(Mojo::Asset::Memory->new->add_chunk($data->{xml}));

  $options->headers->content_disposition('form-data; name="options"');
  $xml->headers->content_disposition(
    'form-data; name="ticketData"; filename="ticketData.xml"');
  $xml->headers->content_type("text/xml");

  my @parts = ($options, $xml);

  $tx->req->content(
    Mojo::Content::MultiPart->new(
      headers => $headers,
      parts   => \@parts
    )
  );
}


method has_api_host {
    return $api_host ? 1 : 0;
}



method whoami($session_id = undef) {
    return $self->api_call('op_auth_whoami',
      { $session_id ? (XSessionID => $session_id) : () });
}


method logout($session_id = undef) {
    return $self->api_call('op_auth_logout',
      { $session_id ? (XSessionID => $session_id) : () });
}


method impersonate($username = undef, $uuid = undef, $session_id = undef) {
  return $self->api_call(
    'op_auth_impersonate',
    {
      $username   ? (userName   => $username)   : (),
      $uuid       ? (userUuid   => $uuid)       : (),
      $session_id ? (XSessionID => $session_id) : (),
    }
  );
}


method create_ticket($xml, $options, $session_id = undef) {

  return $self->api_call(
    'op_createTicket',
    {
      $session_id ? (XSessionID => $session_id) : (),
    },
    {
      createData => {
        options => $options,
        xml     => $xml,
      }
    }
  );
}


method start_document($url = undef, $uuid = undef, $session_id = undef) {
  return $self->api_call(
    'op_document_startDocument',
    {
      $session_id ? (XSessionID => $session_id) : (),
      $uuid ? (ticketUuid => $uuid) : (),
      $url ? (xmldataurl => $url) : (),
    }
  );
}


method build_document($close, $uuid, $session_id = undef) {
  return $self->api_call(
    'op_document_buildDocument',
    {
      close => $close ? $Types::Serialiser::true : $Types::Serialiser::false,
      documentUuid => $uuid,
      $session_id ? (XSessionID => $session_id) : (),
    }
  );
}


method api_call($operation, $query, $content = {}) {

    my $tx = try {
      $client->call($operation => $query, %$content);
    }
    catch {
      die("Died calling Xential API with operation '$operation': $_", $/);
    };

    if ($tx->error) {

      # Not found, no result
      return if $tx->res->code == 404;

      # Any other error
      croak(
        sprintf(
          "Error calling Xential API with operation '%s': '%s' (%s)",
          $operation, $tx->result->body, $tx->error->{message}
        ),
      );
    }

    return $tx->res->json;
}



1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Xential - A Xential REST API module

=head1 VERSION

version 0.003

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 methods

=head2 new()

    my $xential = WebService::Xential->new(
      api_user => 'foo',
      api_key => 'foo',
      api_host => '127.0.0.1',
    );

=head2 has_api_host()

Tells you if you have a custom API host defined

=head2 whoami($session_id)

Implements the whoami call from Xential

=head2 logout($session_id)

Implements the logout call from Xential

=head2 impersonate($username, $user_uuid, $session_id)

Implements the impersonate call from Xential

=head2 create_ticket($xml, $options, $session_id)

Implements the create_ticket call from Xential

=head2 start_document($username, $user_uuid, $session_id)

Implements the start_document call from Xential

=head2 build_document($username, $user_uuid, $session_id)

Implements the build_document call from Xential

=head2 api_call($operation, $query, $content)

A wrapper around the L<OpenAPI::Client::call> function. Returns the JSON from
the endpoint.

=head1 ATTRIBUTES

=head1 METHODS

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

__DATA__
@@ xential.json

{"openapi":"3.0.0","servers":[{"url":"https://zaaksysteem.labs.xential.nl/xential/modpages/next.oas/api"}],"info":{"title":"interaction|next oas Api service","version":"1.0"},"components":{"securitySchemes":{"x_basic":{"type":"http","scheme":"basic"},"x_apikey":{"type":"apiKey","in":"header","name":"X-API-Key"}},"schemas":{"NameValuePair":{"type":"object","properties":{"name":{"type":"string"},"value":{"type":"string"}}},"StorableObject":{"type":"object","properties":{"uuid":{"type":"string"},"objectTypeId":{"type":"string"},"fields":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}},"Address":{"type":"object","properties":{"properties":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}},"WebHook":{"type":"object","properties":{"hooks":{"type":"array","items":{"type":"object","properties":{"event":{"type":"string","enum":["document.built","document.builtSingle","document.deleted"]},"retries":{"type":"object","properties":{"count":{"type":"integer","minimum":1,"maximum":10},"delayMs":{"type":"integer","minimum":100,"maximum":3600000}}},"request":{"type":"object","properties":{"url":{"type":"string","format":"url","example":"https://www.myApp.org/regDoc"},"method":{"type":"string","enum":["POST","GET","UPDATE","DELETE"]},"headers":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}},"query":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}},"contentType":{"type":"string","enum":["application/json","text/xml"]},"requestBody":{"type":"string","example":"{documentUuid: \"{$document.uuid}\", documentSetUuid: \"{$documentSet.uuid}\"}"},"clientCertificateId":{"type":"string"}}}}}}}},"ticketOptionsSchema":{"type":"object","properties":{"printOption":{"type":"object"},"mailOption":{"type":"object"},"documentPropertiesOption":{"type":"object"},"valuesOption":{"type":"object"},"storageOption":{"type":"object","properties":{"fixed":{"type":"boolean"},"None":{"type":"object"},"Temp":{"$ref":"#/components/schemas/StorageTempFileTarget"}}},"attachmentsOption":{"type":"object"},"ttlOption":{"type":"object"},"selectionOption":{"type":"object","properties":{"templateUuid":{"type":"string"},"templatePath":{"type":"string"}}},"mergeOption":{"type":"object","properties":{"recipients":{"type":"array","items":{"$ref":"#/components/schemas/Address"}},"mode":{"type":"string","enum":["SINGLE_DOCUMENT","MULTIPLE_DOCUMENTS"]},"modeFixed":{"type":"boolean"}}},"webhooksOption":{"$ref":"#/components/schemas/WebHook"}}},"Crud_document":{"type":"object","required":["documentUuid"],"properties":{"documentUuid":{"type":"string"},"title":{"type":"string"},"buildStatus":{"type":"string","enum":["NONE","TODO","ACTIVE","DONE","ERROR","CANCELED"]}}},"StorageTempFileTarget":{"type":"object","properties":{"mimeTypes":{"type":"array","items":{"type":"string","enum":["application/pdf","application/msword","application/vnd.ms-excel","application/vnd.ms-powerpoint","application/vnd.oasis.opendocument.text","application/vnd.oasis.opendocument.spreadsheet","application/vnd.oasis.opendocument.presentation","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","application/vnd.openxmlformats-officedocument.presentationml.presentation"]}}}},"StorageCorsaTarget":{"type":"object","properties":{"properties":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}},"StorageVerseonTarget":{"type":"object","properties":{"properties":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}},"StorageESuiteTarget":{"type":"object","properties":{"properties":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}},"StorageZaaksysteem_nlTarget":{"type":"object","properties":{"properties":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}},"StorageCMISTarget":{"type":"object","properties":{"properties":{"type":"array","items":{"$ref":"#/components/schemas/NameValuePair"}}}}}},"security":[{"x_basic":[],"x_apikey":[]}],"paths":{"/auth/impersonate":{"post":{"summary":"Impersonate a user","description":"Impersonating a user is usefull for applications who need to lookup or create objects as if they we're a certain user. Please note that this requires you to pass the XSessionId cookie or header to the next call.","tags":["auth"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"XSessionID":{"type":"string"}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"This is returned when the current user is not privileged to impersonate the passed user."},"404":{"description":"This is returned when there is no user found for the passed uuid or userName."},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_auth_impersonate","parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"userName","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"userUuid","description":"","required":false}]}},"/auth/logout":{"post":{"summary":"logout a user","description":"Logging out invalidates the session of the current user.","tags":["auth"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"XSessionID":{"type":"string"}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_auth_logout","parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false}]}},"/auth/whoami":{"post":{"summary":"whoami","description":"See which user you current are / impersonating.","tags":["auth"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"XSessionId":{"type":"string"},"user":{"type":"object","properties":{"uuid":{"type":"string"},"userName":{"type":"string"}}}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_auth_whoami","parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false}]}},"/template_utils/getUsableTemplates":{"post":{"summary":"get usable templates","description":"getUsableTemplates returns an array of objectReferences which represent a group, a link or a template which the user may use for starting a document or documentSet","tags":["template_utils"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"objects":{"type":"array","items":{"$ref":"#/components/schemas/StorableObject"}}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_template_utils_getUsableTemplates","parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"parentGroupUuid","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"fieldName","description":"","required":false}]}},"/createTicket":{"post":{"summary":"prepare a new ticket","description":"prepare a new ticket","tags":["tickets"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"ticketUuid":{"type":"string"},"startDocumentUrl":{"type":"string","format":"uri"}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_createTicket","requestBody":{"content":{"multipart/form-data":{"schema":{"type":"object","properties":{"options":{"$ref":"#/components/schemas/ticketOptionsSchema"},"ticketData":{"type":"string","format":"binary"}}}}}},"parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false}]}},"/document_actions/addRecipient":{"post":{"tags":["document_actions","document"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"addressId":{"type":"string"}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_document_actions_addRecipient","requestBody":{"content":{"application/json":{"schema":{"$ref":"#/components/schemas/Address"}}}},"parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"documentId","description":"","required":false}]}},"/document/startDocument":{"post":{"summary":"create a new document based on a ticket","description":"create a new document based on a ticket","tags":["document"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","required":["documentUuid"],"properties":{"documentUuid":{"type":"string"},"resumeUrl":{"type":"string","format":"uri"},"status":{"type":"string","enum":["VALID","INVALID"]}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_document_startDocument","parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"ticketUuid","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"xmldataurl","description":"","required":false}]}},"/document":{"post":{"summary":"Create new instance of document","description":"These are documents to be used in /xential","tags":["document","document"],"responses":{"200":{"description":"Ok"},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"requestBody":{"content":{"application/json":{"schema":{"$ref":"#/components/schemas/Crud_document"}}}},"parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false}]}},"/document/{document_id}":{"get":{"summary":"Get instance of document","description":"These are documents to be used in /xential","tags":["document","document"],"responses":{"200":{"description":"Ok"},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"path","schema":{"type":"string"},"name":"document_id","description":"","required":true}]},"delete":{"summary":"Delete instance of document","description":"These are documents to be used in /xential","tags":["document","document"],"responses":{"200":{"description":"Ok"},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"path","schema":{"type":"string"},"name":"document_id","description":"","required":true}]}},"/document/buildDocument":{"post":{"summary":"build a document","tags":["document"],"responses":{"200":{"description":"Ok","content":{"application/json":{"schema":{"type":"object","properties":{"success":{"type":"boolean"}}}}}},"400":{"description":"Bad Request"},"401":{"description":"Authentication required"},"403":{"description":"Forbidden"},"404":{"description":"Not found"},"405":{"description":"Invalid input"},"500":{"description":"Error"}},"operationId":"op_document_buildDocument","parameters":[{"in":"header","schema":{"type":"string"},"name":"XSessionID","description":"","required":false},{"in":"query","schema":{"type":"string"},"name":"documentUuid","description":"","required":true},{"in":"query","schema":{"type":"boolean"},"name":"close","description":"","required":true}]}}},"tags":[{"name":"document","description":"Documents","externalDocs":{"description":"learn more about legacy docs","url":"http://localhost/help/legacydocs"}}]}
