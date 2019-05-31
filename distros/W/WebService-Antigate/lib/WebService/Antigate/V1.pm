package WebService::Antigate::V1;

use strict;
use parent 'WebService::Antigate';

my %MESSAGES = (
    'ERROR_KEY_DOES_NOT_EXIST'       => 'wrong service key used',
    'ERROR_WRONG_USER_KEY'           => 'wrong service key used',
    'ERROR_NO_SLOT_AVAILABLE'        => 'all recognizers are busy, try later',
    'ERROR_ZERO_CAPTCHA_FILESIZE'    => 'uploaded captcha size is zero',
    'ERROR_TOO_BIG_CAPTCHA_FILESIZE' => 'uploaded captcha size is grater than 90 Kb',
    'ERROR_WRONG_FILE_EXTENSION'     => 'wrong extension of the uploaded captcha, allowed extensions are gif, jpg, png',
    'ERROR_IP_NOT_ALLOWED'           => 'this ip not allowed to use this account',
    'ERROR_WRONG_ID_FORMAT'          => 'captcha id should be number',
    'ERROR_NO_SUCH_CAPCHA_ID'        => 'no such captcha id in the database',
    'ERROR_URL_METHOD_FORBIDDEN'     => 'this upload method is already not supported',
    'ERROR_IMAGE_IS_NOT_PNG'         => 'captcha is not correct png file',
    'ERROR_IMAGE_IS_NOT_JPEG'        => 'captcha is not correct jpeg file',
    'ERROR_IMAGE_IS_NOT_GIF'         => 'captcha is not correct gif file',
    'ERROR_ZERO_BALANCE'             => 'you have a zero balance',
    'CAPCHA_NOT_READY'               => 'captcha is not recognized yet',
    'OK_REPORT_RECORDED'             => 'your abuse recorded',
    'ERROR_CAPTCHA_UNSOLVABLE'       => 'captcha can\'t be recognized',
    'ERROR_BAD_DUPLICATES'           => 'captcha duplicates limit reached'
);

sub try_upload {
    my ($self, %opts) = @_;
    
    Carp::croak "Specified captcha file doesn't exist"
        if defined($opts{file}) && ! -e $opts{file};
    
    my $file;
    my $response = $self->{ua}->post
        (
            "$self->{scheme}://$self->{subdomain}$self->{domain}/in.php",
            defined $opts{file} || defined $opts{content}
                ? (
                    Content_Type => "form-data",
                    Content    =>
                    [
                        key    => $self->{key},
                        method => 'post',
                        file   =>
                        [
                            defined($opts{file}) ?
                                (
                                    $file = delete $opts{file},
                                    defined($opts{name}) ?
                                        delete $opts{name}
                                        :
                                        $file !~ /\..{1,5}$/ ? # filename without extension
                                            $self->_name_by_file_signature($file)
                                            :
                                            undef
                                )
                                :
                                (
                                    undef,
                                    defined($opts{name}) ?
                                        delete $opts{name}
                                        :
                                        $self->_name_by_signature($opts{content}),
                                    Content => delete $opts{content}
                                )
                        ],
                        %opts
                    ]
                  )
                : { key => $self->{key}, %opts }
        );
    
    unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
    
    my $captcha_id;
    unless(($captcha_id) = $response->content =~ /OK\|(\d+)/) {
        $self->{errno}  = $response->content;
        $self->{errstr} = $MESSAGES{ $self->{errno} };
        return undef;
    }
    
    return $self->{last_captcha_id} = $captcha_id;
}

sub try_recognize {
    my ($self, $id) = @_;
    
    Carp::croak "Captcha id should be specified" unless defined $id;
    
    my $response = $self->{ua}->get("$self->{scheme}://$self->{subdomain}$self->{domain}/res.php?key=$self->{key}&action=get&id=$id");
    
    unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
    
    my $captcha_text;
    unless(($captcha_text) = $response->content =~ /OK\|(.+)/) {
        $self->{errno}  = $response->content;
        $self->{errstr} = $MESSAGES{ $self->{errno} };
        return undef;
    }
    
    return $captcha_text;
}

sub abuse {
    my ($self, $id) = @_;
    
    Carp::croak "Captcha id should be specified" unless defined $id;
    
    my $response = $self->{ua}->get("$self->{scheme}://$self->{subdomain}$self->{domain}/res.php?key=$self->{key}&action=reportbad&id=$id");
    
    unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
    
    unless($response->content eq 'OK_REPORT_RECORDED') {
        $self->{errno}  = $response->content;
        $self->{errstr} = $MESSAGES{ $self->{errno} };
        return undef;
    }
    
    return 1;
}


sub balance {
    my $self = shift;
    
    my $response = $self->{ua}->get("$self->{scheme}://$self->{subdomain}$self->{domain}/res.php?key=$self->{key}&action=getbalance");
    
    unless($response->is_success) {
        $self->{errno}  = 'HTTP_ERROR';
        $self->{errstr} = $response->status_line;
        return undef;
    }
    
    if($response->content =~ /^ERROR_/) {
        $self->{errno}  = $response->content;
        $self->{errstr} = $MESSAGES{ $self->{errno} };
        return undef;
    }
    
    return $response->content;
}

1;

__END__

=head1 NAME

WebService::Antigate::V1 - Recognition of captches using antigate.com service (now anti-captcha.com) through API v1

=head1 SYNOPSIS

	# you can use it directly
	use WebService::Antigate::V1;
	
	my $recognizer = WebService::Antigate::V1->new(key => "...");
	$recognizer->upload_and_recognize(...);

	# or via base class
	use WebService::Antigate;
	
	my $recognizer = WebService::Antigate->new(key => "...", api_version => 1);
	$recognizer->upload_and_recognize(...);

=head1 DESCRIPTION

This is subclass of L<WebService::Antigate> which implements version 1 of API.

=head1 METHODS

This class has all methods described in L<WebService::Antigate>. Specific changes listed below.

=over

=item $recognizer->try_upload(%options)

Tries to upload captcha to the service. Accepts this options:

   KEY            DEFAULT       DESCRIPTION
   ----------     ----------    ------------
   file            undef        path to the file with captcha
   content         undef        captcha content
   name            undef        represented name of the file with captcha
   phrase          0            1 if captcha text has 2-4 words
   regsense        0            1 if that captcha text is case sensitive
   numeric         0            1 if that captcha text contains only digits, 2 if captcha text has no digits
   calc            0            1 if that digits on the captcha should be summed up
   min_len         0            minimum length of the captcha text (0..20)
   max_len         0            maximum length of the captcha text (0..20), 0 - no limits
   is_russian      0            1 - russian text only, 2 - russian or english, 0 - does not matter
   soft_id         undef        id of your application to earn money
   header_acao     0            1 if server should return "Access-Control-Allow-Origin: *" header
   
For image related captchas you must specify either `file' option or `content'. Other options are facultative. If you want to
upload captcha from variable (`content' option) instead from file, you must specify the name of the file with `name' option.
Antigate webservice determines file format by extension, so it is important to specify proper extension in file name. If `file'
option used and file name has no extension and `name' was not specified or if `content' option used and `name' was not specified,
this module will try to specify proper name by file signature. If file has unknown signature $WebService::Antigate::FNAME will be
used as file name. On success captcha id is returned. On failure returns undef and sets errno and errstr.

This list of settings supported by the service may be outdated. But you can specify any other options supported by the service
here without any changes of the module.

=back

=head1 SEE ALSO

L<WebService::Antigate>, L<WebService::Antigate::V2>

=head1 COPYRIGHT

Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
