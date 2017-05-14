package Tilt::Email::BlueHornet;

# VERSION
# ABSTRACT: Client for sending email using BlueHornet (http://www.bluehornet.com/)

use Encode qw(encode_utf8);
use Function::Parameters ':strict';
use Moose;
use LWP::UserAgent;
use URI;
use XML::Simple;

has 'api_key' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'api_secret' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'ua' => (
  is      => 'ro',
  default => sub {
    return LWP::UserAgent->new(); 
  }
);

# TODO Replace XML::Simple with a better library
has '_xml' => (
  is      => 'ro',
  default => sub {
    return XML::Simple->new(
      NoAttr    => 1,
      RootName  => 'api',
      # XML::Simple escaping of HTML documents weren't accepted by BlueHornet
      NoEscape  => 1,
      KeyAttr   => []
    );
  }
);

method _call($data) {
  my $xml_data = {
    authentication => {
      api_key       => $self->api_key,
      shared_secret => $self->api_secret,
      response_type => 'xml',
      no_halt       => 0
    },
    data => {
      methodCall => $data
    }
  };

  my $response = $self->ua->post(
    'https://echo3.bluehornet.com/api/xmlrpc/index.php',
    Content         => $self->_xml->XMLout($xml_data),
    'Content-type'  => "application/xml; charset='utf8'"
  );

  die 'BlueHornet API call failed with status ' . $response->code . ' ' .
      $response->decoded_content
    unless $response->is_success;

  my $xml_response = $self->_xml->XMLin(
    $response->decoded_content,
    KeyAttr     => {},
    ForceArray  => []
  );

  die 'BlueHornet API call failed with error ' .
      $xml_response->{'item'}->{'responseText'}
    if exists($xml_response->{'item'}->{'error'});

  return $xml_response;
}

method rebuild_template(Str :$template_id) {
  return $self->_call({
    methodName  => 'transactional.rebuildTemplate',
    template_id => $template_id
  });
}

method send_test(Str :$template_id, Str :$email, %variables) {
  return $self->_call({
    email       => $email,
    methodName  => 'transactional.sendTest',
    template_id => $template_id,
    %variables
  });
}

method send_transaction(Str :$template_id, Str :$email, %variables) {
  return $self->_call({
    email       => $email,
    methodName  => 'transactional.sendTransaction',
    template_id => $template_id,
    %variables
  });
}

method update_template(
  Str :$template_id, Str :$subject, Str :$html, Str :$plain_text
) {
  return $self->_call({
    methodName    => 'transactional.updatetemplate',
    template_id   => $template_id,
    # NOTE: This is crazy as we are encoding a UTF8 string. But it works. Really
    # need to understand why XML::Simple and the API call likes double encoded
    # strings. Apparently template toolkit output is already double encoded so
    # we don't need to worry about the $htmL_email and $plain_email content.
    subject       => "<![CDATA[" . encode_utf8($subject) . "]]>",
    template_data => {
      html  => "<![CDATA[$html]]>",
      plain => "<![CDATA[$plain_text]]>",
    }
  });
}

1;
