package WebService::Slack::WebApi::Files;
use strict;
use warnings;
use utf8;
use feature qw/state/;
use Data::Dumper qw/Dumper/;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    delete => {
        file => 'Str',
    },
    info => {
        file  => 'Str',
        count => { isa => 'Int', optional => 1 },
        page  => { isa => 'Int', optional => 1 },
    },
    list => {
        channel => { isa => 'Str', optional => 1 },
        count   => { isa => 'Int', optional => 1 },
        page    => { isa => 'Int', optional => 1 },
        ts_from => { isa => 'Str', optional => 1 },
        ts_to   => { isa => 'Str', optional => 1 },
        types   => { isa => 'Str', optional => 1 },
        user    => { isa => 'Str', optional => 1 },
    },
);

sub revoke_public_url {
    state $rule = Data::Validator->new(
        file => 'Str',
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    return $self->request('revokePublicURL', {%$args, %extra});
}

sub shared_public_url {
    state $rule = Data::Validator->new(
        file => 'Str',
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    return $self->request('sharedPublicURL', {%$args, %extra});
}

sub get_upload_url_external {
    state $rule = Data::Validator->new(
        filename => 'Str',
        length   => 'Int',
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    return $self->request('getUploadURLExternal', {%$args, %extra});
}

sub send_file_to_external_url {
    my ($self, $url, $params) = @_;

    my %headers;
    if( $self->client->token && $params->{'http_auth'} ) {
        my $msg = 'Illegal parameters. You have defined \'token\' but the '
                . ' method you are using defines its own HTTP Authorization header.';
        WebService::Slack::WebApi::Exception::IllegalParameters->throw(
            message  => $msg,
        );
    }
    if (exists $params->{file_type}) {
  		$headers{'Content-type'} = $params->{file_type};
  	} else {
  		$headers{'Content-type'} = 'application/octet-stream';
  	}

    if( $self->client->token ) {
        $headers{'Authorization'} = 'Bearer ' . $self->client->token;
    } elsif( $params->{'http_auth'} ) {
        $headers{'Authorization'} = $params->{'http_auth'};
    }
    
    my %options = (
      headers => \%headers,
      content => $params->{file},
    );
		  
    my $response = $self->client->ua->request(
      'POST',
      $url,
      \%options
    );
    return if $response->{success};

    WebService::Slack::WebApi::Exception::FailureResponse->throw(
        message  => 'file upload failed.',
        response => $response,
    );
}

sub complete_upload_external {
    state $rule = Data::Validator->new(
        files           => 'ArrayRef[HashRef]',
        channels        => { isa => 'ArrayRef[Str]', optional => 1 },
        channel_id      => { isa => 'Str', optional => 1 },
        initial_comment => { isa => 'Str', optional => 1 },
        thread_ts       => { isa => 'Str', optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{channels} = join ',', @{$args->{channels}} if exists $args->{channels};

    return $self->request_json('completeUploadExternal', {%$args, %extra});
}

# FIXME: maybe be broken... https://github.com/mihyaeru21/p5-WebService-Slack-WebApi/issues/15
# Will STOP Working by Slack on 2025-03-11
sub upload {
    state $rule = Data::Validator->new(
        channels        => { isa => 'ArrayRef[Str]', optional => 1 },
        content         => { isa => 'Str', optional => 1 },
        file            => { isa => 'Str', optional => 1 },
        filename        => { isa => 'Str', optional => 1 },
        filetype        => { isa => 'Str', optional => 1 },
        initial_comment => { isa => 'Str', optional => 1 },
        title           => { isa => 'Str', optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{file} = [$args->{file}] if exists $args->{file};
    $args->{channels} = join ',', @{$args->{channels}} if exists $args->{channels};

    return $self->request('upload', {%$args, %extra});
}

=item $ _check_response(response =>, to =>, from =>, text =>, channel_not_found =>)

Internal method.

Checks the response from slack for the ok value and looks for error and warning values.

It will die if it's an error or ok not found.

The to, from and optional text values are included in the output to help troubleshoot.

If the error is 'channel_not_found' we call the 'channel_not_found' provided subroutine so the 
caller can handle sending to their custom error slack channel, etc.
  
Returns the following status code:
0 - okay
1 - warning found
2 - channel_not_found encountered and message was sent to the error channel successfully

=cut
sub _check_response
{
  my $self              = shift;
  my %args              = ( @_ );
  my $response          = $args{response};
  my $to                = $args{to};
  my $from              = $args{from};
  my $text              = $args{text};  # can be undef.
  my $channel_not_found = $args{channel_not_found};
  
  die "ERROR: channel_not_found must be a CODE ref!" if (!defined $channel_not_found || (defined $channel_not_found && ref($channel_not_found) ne "CODE"));
  
  if (! exists $response->{ok})
  {
    die "ERROR: _check_response(): ok field not found in slack response hash!  to='$to', from='$from'\n" . Dumper($response);
  }
  else
  {
    if ($response->{ok})
    {
      if (exists $response->{warning})
      {
        return 1;
      }
      else
      {
        return 0;
      }
    }
    else
    {
      if ($response->{error} eq 'channel_not_found')
      {
        my $code = $channel_not_found->(
          $self,
          response => $response,
          to       => $to,
          from     => $from,
          text     => $text
        );
        
        return 2 if ($code == 0);
        return $code; # default to pass through the error returned from $channel_not_found
      }
      else
      {
        die "ERROR: _check_response(): ok is false and error='$response->{error}'!  to='$to', from='$from'\n" . Dumper($response);
      }
    }
  }
}

# This is a helper method that wraps get_upload_url_external(), post_file_to_external_url()
# and complete_upload_external() calls for the caller.  They have to provide everything necessary
# though.
# Returns an array with $code and $response.
#   $code = 0, 1 or 2 to indicate if it succeeded or 'channel_not_found' handler was called.
#   $response = last response message returned in the process
sub upload_v2 {
    my $self          = shift;
    my $args          = { error_handler => \&_check_response, @_ };
    my $channel       = $args->{channel};    # slack channel name
    my $channel_id    = $args->{channel_id}; # internal slack channel id
    my $file_contents = $args->{file_contents}; # contents of the file to upload
    my $file_type     = $args->{file_type}; # type of the file
    my $file_length   = $args->{file_length}; # length of the file in bytes
    my $filename      = $args->{filename}; # what you want the file to be named in Slack
    my $from          = $args->{from};     # who we say this message is from
    my $message       = $args->{message}; # the message you want associated with the file in slack.
    my $callingObj    = $args->{callingObj}; # instance of the caller that $error_handler and
                                             # $channel_not_found need passed in as $self.
    my $error_handler = $args->{error_handler}; # sub you should call to validate the returned info
                            #is valid.  Takes the following parameters:
                            # response =>, to, from, message, channel_not_found
                            # and returns 0 if ok, 1 otherwise.  Can die if a fatal error is encountered.
    my $channel_not_found = $args->{channel_not_found};
    my $code; # tracks the error_handler result.
    
    if (!defined $error_handler) {
        die "upload_v2(): error_handler must be defined!";
    }
    if (defined $error_handler && ref($error_handler) ne 'CODE') {
        die "upload_v2(): error_handler is not a CODE ref!  You provided: " . ref($error_handler);
    }
    
    if (!defined $channel_not_found) {
        die "upload_v2(): channel_not_found must be defined!";
    }
    if (defined $channel_not_found && ref($channel_not_found) ne 'CODE') {
        die "upload_v2(): channel_not_found is not a CODE ref!  You provided: " . ref($channel_not_found);
    }

    my $external_url_response = $self->get_upload_url_external(
        filename => $filename,
        length   => $file_length
    );
    $code = $error_handler->(
        $callingObj,
        response          => $external_url_response,
        to                => $channel,
        from              => $from,
        text              => $message,
        channel_not_found => $channel_not_found,
    );
    
    if ($code == 0) {
        # we got a valid response and can proceed.
        my $url     = $external_url_response->{upload_url};
        my $file_id = $external_url_response->{file_id};
        
        $self->send_file_to_external_url($url, 
            {
                file      => $file_contents,
                file_type => $file_type
            }
        );
        
        my $complete_upload_response = $self->complete_upload_external(
            files           => [
                                   {
                                       id    => $file_id,
                                       title => $filename
                                   },
                               ],
            channel_id      => $channel_id,
            initial_comment => $message,
        );
        $code = $error_handler->(
            $callingObj,
            response          => $complete_upload_response,
            to                => $channel,
            from              => $from,
            text              => $message,
            channel_not_found => $channel_not_found,
        );
        
        return ($code, $complete_upload_response);
    }
    
    return ($code, $external_url_response);
}

1;

