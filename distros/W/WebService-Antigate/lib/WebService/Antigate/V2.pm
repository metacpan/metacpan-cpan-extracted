package WebService::Antigate::V2;

use strict;
use JSON::PP;
use MIME::Base64;
use parent 'WebService::Antigate';

sub new {
	my ($class, %args) = @_;
	
	# change some defaults
	$args{scheme} = 'https'   unless defined $args{scheme};
	$args{subdomain} = 'api.' unless defined $args{subdomain};
	
	$class->SUPER::new(%args);
}

sub try_upload {
	my ($self, %opts) = @_;
	
	if ( defined $opts{file} ) {
		$opts{content} = do {
			local $/;
			open my $fh, '<:raw', $opts{file}
				or Carp::croak "open `$opts{file}': ", $!;
			<$fh>;
		};
	}
	
	if ( defined $opts{content} ) {
		$opts{body} = encode_base64( $opts{content}, '' );
	}
	
	if ( defined $opts{body} && !defined $opts{type} ) {
		$opts{type} = 'ImageToTextTask';
	}
	
	my $response = $self->{ua}->post(
		"$self->{scheme}://$self->{subdomain}$self->{domain}/createTask",
		Content => encode_json {
			clientKey => $self->{key},
			exists $opts{softId} ? ( softId => delete $opts{softId} ) : (),
			exists $opts{languagePool} ? ( languagePool => delete $opts{languagePool} ) : (),
			task => {
				%opts
			}
		}
	);
	
	unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
	
	my $result = decode_json $response->decoded_content;
	if ($result->{errorId}) {
		$self->{errno} = $result->{errorCode};
		$self->{errstr} = $result->{errorDescription};
		return undef;
	}
	
	return $self->{last_captcha_id} = $result->{taskId};
}

sub try_recognize {
	my ($self, $id) = @_;
    
    Carp::croak "Captcha id should be specified" unless defined $id;
	
	my $response = $self->{ua}->post(
		"$self->{scheme}://$self->{subdomain}$self->{domain}/getTaskResult",
		Content => encode_json {
			clientKey => $self->{key},
			taskId    => $id
		}
	);
	
	unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
	
	my $result = decode_json $response->decoded_content;
	if ($result->{errorId}) {
		$self->{errno} = $result->{errorCode};
		$self->{errstr} = $result->{errorDescription};
		return undef;
	}
	
	if ($result->{status} ne 'ready') {
		$self->{errno}  = 'CAPCHA_NOT_READY';
		$self->{errstr} = 'captcha is not recognized yet';
		return undef;
	}
	
	for my $key ( qw/text gRecaptchaResponse token/ ) {
		return $result->{solution}{$key} if exists $result->{solution}{$key};
	}
	
	return $result->{solution};
}

sub abuse {
    my ($self, $id) = @_;
    
    Carp::croak "Captcha id should be specified" unless defined $id;
	
	my $response = $self->{ua}->post(
		"$self->{scheme}://$self->{subdomain}$self->{domain}/reportIncorrectImageCaptcha",
		Content => encode_json {
			clientKey => $self->{key},
			taskId    => $id
		}
	);
	
	unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
	
	my $result = decode_json $response->decoded_content;
	if ($result->{errorId}) {
		if ($result->{errorCode}) {
			$self->{errno} = $result->{errorCode};
			$self->{errstr} = $result->{errorDescription};
		}
		else {
			$self->{errno} = 'ERROR_NO_SUCH_CAPCHA_ID';
			$self->{errstr} = 'no such captcha id in the database';
		}
		return undef;
	}
	
	return $result->{status};
}

sub balance {
	my $self = shift;
	
	my $response = $self->{ua}->post(
		"$self->{scheme}://$self->{subdomain}$self->{domain}/getBalance",
		Content => encode_json {
			clientKey => $self->{key},
		}
	);
	
	unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
	
	my $result = decode_json $response->decoded_content;
	if ($result->{errorId}) {
		$self->{errno} = $result->{errorCode};
		$self->{errstr} = $result->{errorDescription};
		return undef;
	}
	
	return $result->{balance};
}

1;

__END__

=head1 NAME

WebService::Antigate::V2 - Recognition of captches using antigate.com service (now anti-captcha.com) through API v2

=head1 SYNOPSIS

	# you can use it directly
	use WebService::Antigate::V2;
	
	my $recognizer = WebService::Antigate::V2->new(key => "...");
	$recognizer->upload_and_recognize(...);

	# or via base class
	use WebService::Antigate;
	
	my $recognizer = WebService::Antigate->new(key => "...", api_version => 2);
	$recognizer->upload_and_recognize(...);

=head1 DESCRIPTION

This is subclass of L<WebService::Antigate> which implements version 2 of API.
API documentation available at L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/196635/Documentation+in+English>

=head1 METHODS

This class has all methods described in L<WebService::Antigate>. Specific changes listed below.

=over

=item WebService::Antigate::V2->new( %options )

Constructor changes some options defaults:

   KEY                  DEFAULT                                                OPTIONAL
   -----------          --------------------                                 ---------------
   scheme                https                                                  yes
   subdomain             api.                                                   yes

For other options see L<WebService::Antigate>

=item $recognizer->try_upload(%options)

API v2 accepts several types of captcha. For now it is: captcha image, recaptcha, funcaptcha.
Each type has specific options which may be passed to this method: L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/5079084/Captcha+Task+Types>

Also some common options available, like C<softId> and C<languagePool>, which also may be passed: L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/5079073/createTask+captcha+task+creating>

How to upload normal captcha from image:

	print $recognizer->try_upload(
		file => "/tmp/captcha.jpeg" # or content => "binary data",
		# and any options supported by this type you need
		languagePool => "en",
		numeric => 1,
		minLength => 10
		# type => 'ImageToTextTask' # you may specify it or not, because when `file' or `content' options detected it will be added automatically
	);

How to upload recaptcha:

	print $recognizer->try_upload(
		type         => 'NoCaptchaTaskProxyless', # here you need to specify type
		websiteURL   => "https://www.google.com/",
		websiteKey   => "6LeZhwoTAAAAAP51ukBEOocjtdKGRDei9wFxFSpm",
		languagePool => "rn"
	);

And so on for other types

=back

=head1 SEE ALSO

L<WebService::Antigate>, L<WebService::Antigate::V1>

=head1 COPYRIGHT

Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
