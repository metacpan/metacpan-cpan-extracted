package WebService::Tuya::IoT::API;
use strict;
use warnings;
require Data::Dumper;
require Time::HiRes;
require Digest::SHA;
require Data::UUID;
require JSON::XS;
require HTTP::Tiny;
use List::Util qw{first}; #import required

our $VERSION = '0.03';
our $PACKAGE = __PACKAGE__;

=head1 NAME

WebService::Tuya::IoT::API - Perl library to access the Tuya IoT API

=head1 SYNOPSIS

  use WebService::Tuya::IoT::API;
  my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
  my $access_token   = $ws->access_token;
  my $device_status  = $ws->device_status($deviceid);
  my $response       = $ws->device_commands($deviceid, {code=>'switch_1', value=>$boolean ? \1 : \0});

=head1 DESCRIPTION

Perl library to access the Tuya IoT API to control and read the state of Tuya compatible smart devices.

Tuya compatible smart devices include outlets, switches, lights, window covers, etc.

=head2 SETUP

Other projects have documented device setup, so I will not go into details here.  The L<TinyTuya|https://github.com/jasonacox/tinytuya#setup-wizard---getting-local-keys> setup documentation is the best that I have found. Please note some setup instructions step through the process of creating an app inside the Tuya IoT project, but I was able to use the Smart Life app for device discovery and pair the app with the API by scanning the QR code.

=over

=item * You must configure your devices with the Smart Life (L<iOS|https://apps.apple.com/us/app/smart-life-smart-living/id1115101477>,L<Android|https://play.google.com/store/apps/details?id=com.tuya.smartlife>) app.

=item * You must create an account and project on the L<Tuya IoT Platform|https://iot.tuya.com/>.

=item * You must link the Smart Life app to the project with the QR code.

=item * You must configure the correct project data center to see your devices in the project (Note: My devices call the Western America Data Center even though I'm located in Eastern America).

=item * You must use the host associated to your data center. The default host is the Americas which is set as openapi.tuyaus.com.

=back

=head1 CONSTRUCTORS

=head2 new

  my $ws = WebService::Tuya::IoT::API->new;

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {};
  bless $self, $class;
  %$self    = @_ if @_;
  return $self;
}

=head1 PROPERTIES

=head2 http_hostname

Sets and returns the host name for the API service endpoint.

  $ws->http_hostname("openapi.tuyaus.com"); #Americas
  $ws->http_hostname("openapi.tuyacn.com"); #China
  $ws->http_hostname("openapi.tuyaeu.com"); #Europe
  $ws->http_hostname("openapi.tuyain.com"); #India

default: openapi.tuyaus.com

=cut

sub http_hostname {
  my $self                 = shift;
  $self->{'http_hostname'} = shift if @_;
  $self->{'http_hostname'} = 'openapi.tuyaus.com' unless defined $self->{'http_hostname'};
  return $self->{'http_hostname'};
}

=head2 client_id

Sets and returns the Client ID found on L<https://iot.tuya.com/> project overview page.

=cut

sub client_id {
  my $self             = shift;
  $self->{'client_id'} = shift if @_;
  $self->{'client_id'} = die("Error: property client_id required") unless $self->{'client_id'};
  return $self->{'client_id'};
}

=head2 client_secret

Sets and returns the Client Secret found on L<https://iot.tuya.com/> project overview page.

=cut

sub client_secret {
  my $self                 = shift;
  $self->{'client_secret'} = shift if @_;
  $self->{'client_secret'} = die("Error: property client_secret required") unless $self->{'client_secret'};
  return $self->{'client_secret'};
}

sub _debug {
  my $self          = shift;
  $self->{'_debug'} = shift if @_;
  $self->{'_debug'} = 0 unless $self->{'_debug'};
  return $self->{'_debug'};
}

=head1 METHODS

=head2 api

Calls the Tuya IoT API and returns the parsed JSON data structure.  This method automatically handles access token and web request signatures.

  my $response = $ws->api(GET  => 'v1.0/token?grant_type=1');                                                             #get access token
  my $response = $ws->api(GET  => "v1.0/iot-03/devices/$deviceid/status");                                                #get status of $deviceid
  my $response = $ws->api(POST => "v1.0/iot-03/devices/$deviceid/commands", {commands=>[{code=>'switch_1', value=>\0}]}); #set switch_1 off on $deviceid

References:

=over

=item * L<https://developer.tuya.com/en/docs/iot/new-singnature?id=Kbw0q34cs2e5g>

=item * L<https://github.com/jasonacox/tinytuya/blob/ffcec471a9c4bba38d5bf224608e20bc148f1b86/tinytuya/Cloud.py#L130>

=item * L<https://bestlab-platform.readthedocs.io/en/latest/bestlab_platform.tuya.html>

=back

=cut

# Thanks to Jason Cox at https://github.com/jasonacox/tinytuya
# Copyright (c) 2022 Jason Cox - MIT License

sub api {
  my $self             = shift;
  my $http_method      = shift;                                                                                    #TODO: die on bad http methods
  my $api_destination  = shift;                                                                                    #TODO: sort query parameters alphabetically
  my $input            = shift; #or undef
  my $content          = defined($input) ? JSON::XS::encode_json($input) : '';                                     #Note: empty string stringifies to "" in JSON
  my $is_token         = $api_destination =~ m{v[0-9\.]+/token\b} ? 1 : 0;
  my $http_path        = '/' . $api_destination;
  my $url              = sprintf('https://%s%s', $self->http_hostname, $http_path);                                #e.g. "https://openapi.tuyaus.com/v1.0/token?grant_type=1"
  my $nonce            = Data::UUID->new->create_str;                                                              #Field description - nonce: the universally unique identifier (UUID) generated for each API request.
  my $t                = int(Time::HiRes::time() * 1000);                                                          #Field description - t: the 13-digit standard timestamp.
  my $content_sha256   = Digest::SHA::sha256_hex($content);                                                        #Content-SHA256 represents the SHA256 value of a request body
  my $headers          = '';                                                                                       #signature headers
  my @access_token     = ();
  if ($is_token) {
    $headers           = sprintf("secret:%s\n",  $self->client_secret);                                            #TODO: add support for area_id and request_id
  } else {
    $access_token[0]   = $self->access_token;                                                                      #Note: recursive call
  }
  my $stringToSign     = join("\n", $http_method, $content_sha256, $headers, $http_path);
  my $str              = join('',  $self->client_id, @access_token, $t, $nonce, $stringToSign); #Signature algorithm - str = client_id + @access_token + t + nonce + stringToSign
  my $sign             = uc(Digest::SHA::hmac_sha256_hex($str, $self->client_secret));                             #Signature algorithm - sign = HMAC-SHA256(str, secret).toUpperCase()
  my $options          = {
                          headers => {
                                      'Content-Type' => 'application/json',
                                      'client_id'    => $self->client_id,
                                      'sign'         => $sign,
                                      'sign_method'  => 'HMAC-SHA256',
                                      't'            => $t,
                                      'nonce'        => $nonce,
                                     },
                          content => $content,
                         };
  if ($is_token) {
    $options->{'headers'}->{'Signature-Headers'} = 'secret';
    $options->{'headers'}->{'secret'}            = $self->client_secret;
  } else {
    $options->{'headers'}->{'access_token'}      = $access_token[0];
  }

  local $Data::Dumper::Indent  = 1; #smaller index
  local $Data::Dumper::Terse   = 1; #remove $VAR1 header

  print Data::Dumper::Dumper({http_method => $http_method, url => $url, options => $options}) if $self->_debug > 1;
  my $response         = $self->ua->request($http_method, $url, $options);
  print Data::Dumper::Dumper({response => $response}) if $self->_debug;
  my $status           = $response->{'status'};
  die("Error: Web service request unsuccessful - dest: $api_destination, status: $status\n") unless $status eq '200';                     #TODO: better error handeling
  my $response_content = $response->{'content'};
  local $@;
  my $response_decoded = eval{JSON::XS::decode_json($response_content)};
  my $error            = $@;
  die("Error: API returned invalid JSON - dest: $api_destination, content: $response_content\n") if $error;
  print Data::Dumper::Dumper({response_decoded => $response_decoded}) if $self->_debug > 2;
  die("Error: API returned unsuccessful - dest: $api_destination, content: $response_content\n") unless $response_decoded->{'success'};
  return $response_decoded
}

=head2 api_get, api_post, api_put, api_delete

Wrappers around the C<api> method with hard coded HTTP methods.

=cut

sub api_get    {my $self = shift; return $self->api(GET    => @_)};
sub api_post   {my $self = shift; return $self->api(POST   => @_)};
sub api_put    {my $self = shift; return $self->api(PUT    => @_)};
sub api_delete {my $self = shift; return $self->api(DELETE => @_)};

=head2 access_token

Wrapper around C<api> method which calls and caches the token web service for a temporary access token to be used for subsequent web service calls.

  my $access_token = $ws->access_token; #requires client_id and client_secret

=cut

sub access_token {
  my $self = shift;
  if (defined $self->{'_access_token_data'}) {
    #clear expired access_token
    delete($self->{'_access_token_data'}) if Time::HiRes::time() > $self->{'_access_token_data'}->{'expire_time'};
  }
  unless (defined $self->{'_access_token_data'}) {
    #get access_token and calculate expire_time epoch
    my $api_destination           = 'v1.0/token?grant_type=1';
    my $output                    = $self->api_get($api_destination);

#{
#  "success":true,
#  "t":1678245450431,
#  "tid":"c2ad0c4abd5f11edb116XXXXXXXXXXXX"
#  "result":{
#    "access_token":"34c47fab3f10beb59790XXXXXXXXXXXX",
#    "expire_time":7200,
#    "refresh_token":"ba0b6ddc18d0c2eXXXXXXXXXXXXXXXXX",
#    "uid":"bay16149755RXXXXXXXX"
#  },
#}

    my $response_time             = $output->{'t'};                       #UOM: milliseconds from epoch
    my $expire_time               = $output->{'result'}->{'expire_time'}; #UOM: seconds ref https://bestlab-platform.readthedocs.io/en/latest/bestlab_platform.tuya.html
    $output->{'expire_time'}      = $response_time/1000 + $expire_time;   #TODO: Account for margin of error
    $self->{'_access_token_data'} = $output;
  }
  my $access_token = $self->{'_access_token_data'}->{'result'}->{'access_token'} or die("Error: access_token not set");
  return $access_token;
}

=head2 device_status

Wrapper around C<api> method to access the device status API destination.

  my $device_status = $ws->device_status($deviceid);

=cut

sub device_status {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.0/iot-03/devices/$deviceid/status";
  return $self->api_get($api_destination);
}

=head2 device_status_code_value

Wrapper around C<api> method to access the device status API destination and return the value for the given switch code.

  my $value = $ws->device_status_code_value($deviceid, $code); #isa JSON Boolean

default: code => switch_1

=cut

sub device_status_code_value {
  my $self     = shift;
  my $deviceid = shift;
  my $code     = shift; $code = 'switch_1' unless defined $code; #5.8 syntax
  my $response = $self->device_status($deviceid);
  my $result   = $response->{'result'};
  my $obj      = first {$_->{'code'} eq $code} @$result;
  my $value    = $obj->{'value'};
  return $value;
}

=head2 device_information

Wrapper around C<api> method to access the device information API destination.

  my $device_information = $ws->device_information($deviceid);

=cut

sub device_information {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.1/iot-03/devices/$deviceid";
  return $self->api_get($api_destination);
}

=head2 device_freeze_state

Wrapper around C<api> method to access the device freeze-state API destination.

  my $device_freeze_state = $ws->device_freeze_state($deviceid);

=cut

sub device_freeze_state {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.0/iot-03/devices/$deviceid/freeze-state";
  return $self->api_get($api_destination);
}

=head2 device_factory_infos

Wrapper around C<api> method to access the device factory-infos API destination.

  my $device_factory_infos = $ws->device_factory_infos($deviceid);

=cut

sub device_factory_infos {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.0/iot-03/devices/factory-infos?device_ids=$deviceid";

  return $self->api_get($api_destination);
}

=head2 device_specification

Wrapper around C<api> method to access the device specification API destination.

  my $device_specification = $ws->device_specification($deviceid);

=cut

sub device_specification {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.2/iot-03/devices/$deviceid/specification";
  return $self->api_get($api_destination);
}

=head2 device_protocol

Wrapper around C<api> method to access the device protocol API destination.

  my $device_protocol = $ws->device_protocol($deviceid);

=cut

sub device_protocol {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.0/iot-03/devices/protocol?device_ids=$deviceid";
  return $self->api_get($api_destination);
}

=head2 device_properties

Wrapper around C<api> method to access the device properties API destination.

  my $device_properties = $ws->device_properties($deviceid);

=cut

sub device_properties {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "v1.0/iot-03/devices/$deviceid/properties";
  return $self->api_get($api_destination);
}

=head2 device_commands

Wrapper around C<api> method to access the device commands API destination.

  my $switch   = 'switch_1';
  my $value    = $boolean ? \1 : \0;
  my $response = $ws->device_commands($deviceid, {code=>$switch, value=>$value});

=cut

sub device_commands {
  my $self            = shift;
  my $deviceid        = shift;
  my @commands        = @_; #each command must be a hash reference
  my $api_destination = "v1.0/iot-03/devices/$deviceid/commands";
  return $self->api_post($api_destination, {commands=>\@commands});
}

=head2 device_command_code_value

Wrapper around C<device_commands> for one command with code and value keys;

  my $response = $ws->device_command_code_value($deviceid, $code, $value);

=cut

sub device_command_code_value {
  my $self     = shift;
  my $deviceid = shift or die('Error: method syntax device_command_code_value($deviceid, $code, $value);');
  my $code     = shift; #undef ok?
  my $value    = shift; #undef ok?
  return $self->device_commands($deviceid, {code=>$code, value=>$value});
}

=head1 ACCESSORS

=head2 ua

Returns an L<HTTP::Tiny> web client user agent

=cut

sub ua {
  my $self = shift;
  unless ($self->{'ua'}) {
    my %settinges = (
                     keep_alive => 0,
                     agent      => "Mozilla/5.0 (compatible; $PACKAGE/$VERSION; See rt.cpan.org 35173)",
                    );
    $self->{'ua'} = HTTP::Tiny->new(%settinges);
  }
  return $self->{'ua'};
}

=head1 SEE ALSO

=over

=item * L<Tuya IoT Platform|https://iot.tuya.com/>

=item * L<TinyTuya - Python|https://github.com/jasonacox/tinytuya>

=item * L<Smart Life - iOS|https://apps.apple.com/us/app/smart-life-smart-living/id1115101477>

=item * L<Smart Life - Android|https://play.google.com/store/apps/details?id=com.tuya.smartlife>

=back

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis

=cut

1;
