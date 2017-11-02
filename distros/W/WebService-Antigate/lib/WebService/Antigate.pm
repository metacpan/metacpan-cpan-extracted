package WebService::Antigate;

use strict;
use LWP::UserAgent ();
use Carp ();

our $VERSION = '0.10';

our $DOMAIN = 'anti-captcha.com'; # service domain often changes because of the abuse
our $WAIT   = 220;                # default time that recognize() or upload() can work
our $DELAY  = 5;                  # sleep time before retry while uploading or recognizing captcha
our $FNAME  = 'captcha.jpg';      # default name of the uploaded captcha if name not specified and can't be determined

my %API_VERSIONS = (
	1 => sub { require WebService::Antigate::V1; 'WebService::Antigate::V1' },
	2 => sub { require WebService::Antigate::V2; 'WebService::Antigate::V2' },
);

sub new {
    my ($class, %args) = @_;
    
    Carp::croak "Option `key' should be specified" unless defined $args{key};
    
    my $self = {};
    $self->{key}         = $args{key};
    $self->{wait}        = $args{wait};
    $self->{attempts}    = $args{attempts};
    $self->{ua}          = $args{ua}     || LWP::UserAgent->new();
    $self->{domain}      = $args{domain} || $DOMAIN;
    $self->{delay}       = $args{delay}  || $DELAY;
	$self->{scheme}      = $args{scheme} || 'http';
	$self->{subdomain}   = $args{subdomain};
	$self->{api_version} = $args{api_version} || 1;
    
    $self->{wait} = $WAIT unless defined($self->{wait}) || defined($self->{attempts});
    
	Carp::croak "Unsupported `api_version' specified" unless exists $API_VERSIONS{ $self->{api_version} };
    bless $self, $class eq __PACKAGE__ ? $API_VERSIONS{ $self->{api_version} }->() : $class;
}

# generate sub's for get/set object properties using closure
foreach my $key (qw(key wait attempts ua scheme domain subdomain delay)) {
    no strict 'refs';
    *$key = sub {
        my $self = shift;
    
        return $self->{$key} = $_[0] if defined $_[0];
        return $self->{$key};
    }
}

sub errno {
    return $_[0]->{errno};
}

sub errstr {
    return $_[0]->{errstr};
}

sub upload {
    my ($self, %opts) = @_;
    
    my $start = time();
    my $attempts = 0;
    my $captcha_id;
    
    do {
        $attempts ++;
        $captcha_id = $self->try_upload(%opts);
    }
    while ( !$captcha_id && 
          ($self->{errno} eq 'ERROR_NO_SLOT_AVAILABLE' || $self->{errno} eq 'HTTP_ERROR') &&
          (defined($self->{wait}) ? ( time() - $start ) < $self->{wait} : 1) &&
          $attempts != $self->{attempts} &&
          sleep( $self->{delay} )
        );

    return $captcha_id;
}

sub recognize {
    my ($self, $id) = @_;
    
    my $start = time();
    my $captcha_text;
    my $attempts = 0;
    
    do
    {
        $attempts ++;
        sleep( $self->{delay} );
        $captcha_text = $self->try_recognize($id);
    }
    while ( !$captcha_text &&
          ($self->{errno} eq 'CAPCHA_NOT_READY' || $self->{errno} eq 'HTTP_ERROR') &&
          (defined($self->{wait}) ? ( time() - $start ) < $self->{wait} : 1) &&
          $attempts != $self->{attempts}
        );
          
    return $captcha_text;
}

sub upload_and_recognize {
    my ($self, %opts) = @_;
    
    my $captcha_id;
    unless($captcha_id = $self->upload(%opts))
    {
        return undef;
    }
    
    return $self->recognize($captcha_id);
}

sub last_captcha_id {
    my ($self) = @_;
    return $self->{last_captcha_id};
}

sub _name_by_signature {
    if ($_[1] =~ /^\x47\x49\x46\x38(?:\x37|\x39)\x61/)
    {
        return 'captcha.gif';
    }

    if ($_[1] =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/)
    {
        return 'captcha.png';
    }

    if ($_[1] =~ /^\xFF\xD8\xFF\xE0..\x4A\x46\x49\x46\x00/)
    {
        return 'captcha.jpg';
    }
    
    return $FNAME;
}

sub _name_by_file_signature {
    my $self = shift;
	
	open my $fh, '<:raw', $_[0] or return $self->_name_by_signature('');
    sysread($fh, my $buf, 20);
    close $fh;
    return $self->_name_by_signature($buf);
}

1;

__END__

=head1 NAME

WebService::Antigate - Recognition of captches using antigate.com service (now anti-captcha.com)

=head1 SYNOPSIS

=over

=item Simplest variant

 use WebService::Antigate;

 my $recognizer = WebService::Antigate->new(key => 'd41d8cd98f00b204e9800998ecf8427e');
 
 my $captcha = $recognizer->upload_and_recognize(file => "/tmp/Captcha.jpeg")
       or die $recognizer->errstr;

 print "Recognized captcha is: ", $captcha, "\n";

=item More control

 use WebService::Antigate;

 my $recognizer = WebService::Antigate->new(key => 'd41d8cd98f00b204e9800998ecf8427e', attempts => 25);

 my $id = $recognizer->upload(file => '/tmp/Captcha.jpeg');
 unless($id)
 {
       die "Error while uploading captcha: ", $recognizer->errno, " (", $recognizer->errstr, ")";
 }

 my $captcha = $recognizer->recognize($id);
 unless($captcha)
 {
       die "Error while recognizing captcha: ", $recognizer->errno, " (", $recognizer->errstr, ")";
 }

 print "Recognized captcha is: ", $captcha, "\n";

=item Control all operations yourself

 use WebService::Antigate;

 my $recognizer = WebService::Antigate->new(key => 'd41d8cd98f00b204e9800998ecf8427e');

 # will use captcha from variable, not from file for this example
 my $captcha_img = $recognizer->ua->get('http://some-site.com/captcha.php?id=4')->content;

 my $id;
 until($id = $recognizer->try_upload(content => $captcha_img))
 {
       warn "not uploaded yet: ", $recognizer->errno;
       sleep 5;
 }

 my $captcha;
 until($captcha = $recognizer->try_recognize($id))
 {
       warn "not recognized yet: ", $recognizer->errno;
       sleep 5;
 }

 print "Recognized captcha is: ", $captcha, "\n";

=item Using API v2 to recognize recaptcha

  use WebService::Antigate;
  
  my $recognizer = WebService::Antigate->new(key => 'd41d8cd98f00b204e9800998ecf8427e', api_version => 2);
  my $recaptcha_token = $recognizer->upload_and_recognize(
	type       => 'NoCaptchaTaskProxyless',
	websiteURL => "https://www.google.com/",
	websiteKey => "6LeZhwoTAAAAAP51ukBEOocjtdKGRDei9wFxFSpm"
  );
  
  warn $recaptcha_token;

=back

=head1 DESCRIPTION

The C<WebService::Antigate>  is a class for captcha text recognition. It uses the API of anti-captcha.com
service (versions 1 and 2 of API supported). You have to register with anti-captcha.com to obtain you private key. Thereafter you can upload
captcha image to this service using this class and receive captcha text already recognized. Be aware
not to use this service for any illegal activities.

=head1 METHODS

=over

=item WebService::Antigate->new( %options )

This method constructs new object of L<WebService::Antigate::V1> or L<WebService::Antigate::V2> depending on C<api_version> specified.
Key / value pairs can be passed as an argument to specify the initial state. The following options correspond to attribute methods described below:

   KEY                  DEFAULT                                                OPTIONAL
   -----------          --------------------                                 ---------------
   key                   undef                                                 NO
   api_version           1                                                     yes
   ua                    LWP::UserAgent->new                                   yes
   scheme                http                                                  yes
   domain                $WebService::Antigate::DOMAIN = 'anti-captcha.com'    yes
   subdomain             undef                                                 yes
   wait                  $WebService::Antigate::WAIT = 220                     yes
   attempts              undef                                                 yes
   delay                 $WebService::Antigate::DELAY = 5                      yes

Options description:

   key         - your service private key
   api_version - version of API to use: 1 or 2
   ua          - LWP::UserAgent object used to upload captcha and receive the result (captcha recognition)
   scheme      - http or https, default value may be different in subclasses
   domain      - current domain of the service, can be changed in the future
   subdomain   - current subdomain of domain of the service (with dot at the end), default value may be different in subclasses
   wait        - maximum waiting time until captcha will be accepted  ( upload() ) or recognized ( recognize() ) by the service
   delay       - delay time before next attempt of captcha uploading or recognition after previous failure
   attempts    - maximum number of attempts that we can try_upload() or try_recognize()
   
If you specify `wait' and `attempts' options at the same time, than class will try to upload/recognize until time or attempts
will over (which first).
If you do not specify neither `wait', nor `attempts', than default value of `wait' will be used.

=item $recognizer->key

=item $recognizer->key($key)

This method gets or sets your service private key.

=item $recognizer->ua

=item $recognizer->ua($ua)

This method gets or sets an C<LWP::UserAgent> object associated with class. Thus we can configure this object:
set proxy, etc. See L<LWP::UserAgent> for details.

Example:

   $recognizer->ua->proxy(http => 'http://localhost:8080');

=item $recognizer->scheme

=item $recognizer->scheme($scheme)

This method gets or sets API url scheme.

=item $recognizer->domain

=item $recognizer->domain($domain)

This method gets or sets the domain of the service.

=item $recognizer->subdomain

=item $recognizer->subdomain($domain)

This method gets or sets subdomain of the service (with dot at the end).

=item $recognizer->wait

=item $recognizer->wait($time)

This method gets or sets maximum waiting time. See above.

=item $recognizer->delay

=item $recognizer->delay($time)

This method gets or sets delay time before next attempt. See above.

=item $recognizer->attempts

=item $recognizer->attempts($attempts)

This method gets or sets maximum number of attempts. See above.

=item $recognizer->errno

This method gets an error from previous unsuccessful operation. The Error is returned as a string constant
associated with this error type. For example:

  'ERROR_KEY_DOES_NOT_EXIST'
  'ERROR_WRONG_USER_KEY'
  'ERROR_NO_SLOT_AVAILABLE'
  'ERROR_ZERO_CAPTCHA_FILESIZE'
  'ERROR_TOO_BIG_CAPTCHA_FILESIZE'
  'ERROR_WRONG_FILE_EXTENSION'
  'ERROR_IP_NOT_ALLOWED'
  'ERROR_WRONG_ID_FORMAT'
  'ERROR_NO_SUCH_CAPCHA_ID'
  'ERROR_URL_METHOD_FORBIDDEN'
  'ERROR_IMAGE_IS_NOT_PNG'
  'ERROR_IMAGE_IS_NOT_JPEG'
  'ERROR_IMAGE_IS_NOT_GIF'
  'ERROR_ZERO_BALANCE'
  'ERROR_CAPTCHA_UNSOLVABLE'
  'ERROR_BAD_DUPLICATES'
  'HTTP_ERROR'

For complete list of errors see API documentation

=item $recognizer->errstr

This method gets an error from previous unsuccessful operation. The Error is returned as a string which
describes the problem.

=item $recognizer->try_upload(%options)

This method tries to upload captcha image (if captcha is image related) to the service or just creates task (if not) on the service.
For available options see speecific API version: L<WebService::Antigate::V1/"try_upload"> or L<WebService::Antigate::V2/"try_upload">.
On success will return captcha id. On failure returns undef and sets errno and errstr.

=item $recognizer->upload(%options)

This method attempts to upload a captcha image to the service until exceeds allotted time limit or attempts or a captcha
will not be uploaded. The parameter %options is identical with the one in method try_upload(). On success will return
captcha id. On failure returns undef and sets errno and errstr.

=item $recognizer->try_recognize($captcha_id)

This method tries to recognize captcha (get result for previously uploaded captcha) with id $captcha_id  - value returned by method
upload() or try_upload(). On success will return recognized captcha text. On failure returns undef and sets errno and errstr.

=item $recognizer->recognize($captcha_id)

This method tries to recognize captcha as it does method try_recognize() but will make attempts until time limit or
attempts exceeds or captcha will be recognized. On success will return recognized captcha text. On failure returns
undef and sets errno and errstr.

=item $recognizer->upload_and_recognize(%options)

This method uploads and recognizes captcha in one step. It is easier but less flexible. Parameter %options is identical
with the one in method try_upload(). On success will return recognized captcha text. On failure returns undef and sets
errno and errstr.

=item $recognizer->last_captcha_id

This method returns id of the last successfully uploaded captcha. This can be useful when you used upload_and_recognize()
and then want to use some method that accepts captcha id as argument (abuse() for example).

=item $recognizer->abuse($captcha_id)

This method sends a message to the service that captcha with $captcha_id was recognized incorrectly. On success will return
a true value. On failure returns undef and sets errno and errstr.

=item $recognizer->balance()

This method gets user balance. On success will return user balance as a float number. On failure returns undef and sets errno
and errstr.

=back

=head1 PACKAGE VARIABLES

$WebService::Antigate::DOMAIN   = 'anti-captcha.com'; # service domain often changes because of the abuse

$WebService::Antigate::WAIT     = 220;                # default time that recognize() or upload() can work

$WebService::Antigate::DELAY    = 5;                  # sleep time before retry while uploading or recognizing captcha

$WebService::Antigate::FNAME    = 'captcha.jpg';      # default name of the uploaded captcha if name not specified and can't be determined

=head1 SEE ALSO

L<WebService::Antigate::V1>, L<WebService::Antigate::V2>

=head1 COPYRIGHT

Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
