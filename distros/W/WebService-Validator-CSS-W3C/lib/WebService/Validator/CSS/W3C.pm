package WebService::Validator::CSS::W3C;
use strict;
use warnings;

use SOAP::Lite 0.65;
use LWP::UserAgent qw//;
use URI qw//;
use URI::QueryParam qw//;
use Carp qw//;
use base qw/Class::Accessor/;

our $VERSION = "0.3";

# profiles currently supported by the W3C CSS Validator
our %PROFILES = map { $_ => 1 } qw/none css1 css2 css21 css3 svg svgbasic
                                   svgtiny mobile atsc-tv tv/;

# user media currently supported by the W3C CSS Validator
our %MEDIA    = map { $_ => 1 } qw/all aural braille embossed handheld
                                   print screen tty tv presentation/;

# warnings level currently supported by the W3C CSS Validator
our %WARNINGS = map { $_ => 1 } qw/0 1 2 no/;

__PACKAGE__->mk_accessors    (qw/user_agent validator_uri/);
__PACKAGE__->mk_ro_accessors (qw/response request_uri som success/);

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    my $ua = shift;
    my $uri = shift;
    
    if (defined $ua) {
        
        # check whether it really is
        Carp::croak "$ua is not a LWP::UserAgent"
          unless UNIVERSAL::isa($ua, 'LWP::UserAgent');
        
        $self->user_agent($ua);
    } else {
        my $ua = LWP::UserAgent->new(agent => __PACKAGE__."/".$VERSION);
        $self->user_agent($ua);
    }

    if (defined $uri) {
        $self->validator_uri($uri);
    } else {
        $self->validator_uri("http://jigsaw.w3.org/css-validator/validator");
    }

    return $self;
}

sub _handle_response
{
    my $self = shift;
    my $res = shift;
    
    # internal or server errors...
    return 0 unless $res->is_success;
    
    local $_ = $res->content;
    
    my $som;
    eval { $som = SOAP::Deserializer->new->deserialize($_); };

    # Deserialization might fail if the response is not a legal
    # SOAP response, e.g., if the response is ill-formed... Not
    # sure how to make the reason for failure available to the
    # application, suggestions welcome.
    if ($@) {
        # Carp::carp $@;
        return 0;
    }
    
    # memorize the SOAP object model object
    $self->{'som'} = $som;
    
    # check whether this is really the CSS Validator responding
    if ($som->match("/Envelope/Body/cssvalidationresponse")) {
        $self->{'success'} = 1;
    }
    # if the response was a SOAP fault
    elsif ($som->match("/Envelope/Body/Fault")) {
        $self->{'success'} = 0; 
    }
        
    # return whether the response was successfully processed
    return $self->{'success'};
}

sub validate
{
    my $self = shift;
    my %parm = @_;
    my $uri = URI->new($self->validator_uri);
    my $ua = $self->user_agent;

    $self->{'success'} = 0;
    
    # 
    if (defined $parm{string}) {
        $uri->query_param(text => $parm{string});
    } elsif (defined $parm{uri}) {
        $uri->query_param(uri => $parm{uri});
    } else {
        Carp::croak "you must supply a string/uri parameter\n";
    }

    if (defined $parm{medium}) {
        # check whether the medium is supported
        Carp::croak "$parm{medium} is not a legal medium\n"
          unless $MEDIA{$parm{medium}};
          
        $uri->query_param(medium => $parm{medium});
    }
    
    if (defined $parm{profile}) {
        # check whether the profile is supported
        Carp::croak "$parm{profile} is not a legal profile\n"
          unless $PROFILES{$parm{profile}};
          
        $uri->query_param(profile => $parm{profile});
    }
    
    if (defined $parm{warnings}) {
        Carp::croak "warnings must be either \"no\" or an integer from 0 to 2\n"
          unless $WARNINGS{$parm{warnings}};        
        $uri->query_param(warning => $parm{warnings});
    }
    
    # request SOAP 1.2 output
    $uri->query_param(output => "soap12");
    
    # memorize request uri
    $self->{'request_uri'} = $uri;
    
    # generate new HTTP::Request object
    my $req = HTTP::Request->new(GET => $uri);
    
    # add an Accept-Language header if desired
    if (defined $parm{language}) {
        $req->header(Accept_Language => $parm{language});
    }
    
    my $res = $ua->simple_request($req);
    
    # memorize response
    $self->{'response'} = $res;
    
    return $self->_handle_response($res);
}

sub is_valid
{
    my $self = shift;
    my $som = $self->som;
    
    # previous failure means the style sheet is invalid
    return 0 unless $self->success and defined $som;

    # fetch validity field in reponse
    my $validity = $som->valueof("/Envelope/Body/cssvalidationresponse/validity");
    
    # valid if m:validity is true
    return 1 if defined $validity and $validity eq "true";

    # else invalid
    return 0;
}

sub errors
{
    my $self = shift;
    my $som = $self->som;
    
    return () unless defined $som;
    return $som->valueof("//error");
}

sub warnings
{
    my $self = shift;
    my $som = $self->som;

    return () unless defined $som;
    return $som->valueof("//warning");
}

sub errorcount
{
    my $self = shift;
    my $som = $self->som;
    
    return () unless defined $som;
    return $som->valueof("//errorcount");
}

sub warningcount
{
    my $self = shift;
    my $som = $self->som;
    
    return () unless defined $som;
    return $som->valueof("//warningcount");
}

1;

__END__

=pod

=head1 NAME

WebService::Validator::CSS::W3C - Interface to the W3C CSS Validator

=head1 SYNOPSIS

  use WebService::Validator::CSS::W3C;

  my $css = "p { color: not-a-color }";
  my $val = WebService::Validator::CSS::W3C->new;
  my $ok = $val->validate(string => $css);

  if ($ok and !$val->is_valid) {
      print "Errors:\n";
      printf "  * %s\n", $_->{message}
        foreach $val->errors
  }

=head1 DESCRIPTION

This module is an  interface to the W3C CSS Validation online service 
L<http://jigsaw.w3.org/css-validator/>, based on its SOAP 1.2 support. 
It helps to find errors in Cascading Style Sheets.

The following methods are available:

=over 4

=item my $val = WebService::Validator::CSS::W3C->new

=item my $val = WebService::Validator::CSS::W3C->new($ua)

=item my $val = WebService::Validator::CSS::W3C->new($ua, $url)

Creates a new WebService::Validator::CSS::W3C object. A custom
L<LWP::UserAgent> object can be supplied which is then used for HTTP
communication with the CSS Validator. $url is the URL of the CSS
Validator, C<http://jigsaw.w3.org/css-validator/validator> by default.

=item my $success = $val->validate(%params)

Validate a style sheet, takes C<%params> as defined below. Either C<string>
or C<uri> must be supplied. Returns a true value if the validation succeeded
(regardless of whether the style sheet contains errors).

=over 4

=item string => $css

A style sheet as a string. It is currently unlikely that validation will work
if the string is not a legal UTF-8 string. If a string is specified, the C<uri>
parameter will be ignored. Note that C<GET> will be used to pass the string
to the Validator, it might not work with overly long strings.

=item uri => $uri

The location of a style sheet or a HTML/XHTML/SVG document containing or
referencing style sheets.

=item medium => "print"

The medium for which the style sheet should apply, one of C<aural>, C<braille>,
C<embossed>, C<handheld>, C<print>, C<screen>, C<tty>, C<tv>, and C<presentation>.
A special value C<all> can also be specified. The default is C<undef> in which
case the CSS Validator determines a value; this would currently be as if C<all>
had been specified.

=item profile => "css3"

The CSS Version or profile to validate against, legal values are C<css1>, C<css2>, C<css21>,
C<css3>, C<svg>, C<svgbasic>, C<svgtiny>, C<mobile>, C<atsc-tv>, and C<tv>. A special
value C<none> can also be used. The default is C<undef> in which case the CSS Validator
determines a default.

=item warnings => 2

Either "no" or an integer C<0> - C<2> that determines how many warning messages you want to get
back from the CSS Validator. "no" means no warning, C<0> means only the most serious warnings, 
and C<2> will give all warnings, including low level ones. The defaut is C<undef> in which case
the CSS Validator determines a default value; this is expected to be as if C<1> had
been specified.

=item language => "de"

The desired language of the supposedly human-readable messages. The string will
passed as an C<Accept-Language> header in the HTTP request. The CSS Validator
currently supports C<en>, C<de>, C<fr>, C<ja>, C<nl>, C<zh>, and C<zh-cn>.

=back

=item my $success = $val->success

Same as the return value of C<validate()>.

=item my $is_valid = $val->is_valid

Returns a true value if the last attempt to C<validate()> succeeded and the
validator reported no errors in the style sheet.

=item my $num_errors = $val->errorcount

returns the number of errors found for the checked style sheet. 
Get the details of the errors with $val->errors (see below).

=item my @errors = $val->errors

Returns a list with information about the errors found for the
style sheet. An error is a hash reference; the example in the
synopsis would currently return something like

  ( {
    context    => 'p',
    property   => 'color',
    expression => { start => '', end => 'not-a-color' }
    errortype  => 'parse-error',
    message    => 'not-a-color is not a color value',
    line       => 0,
  } )

=item my $num_warnings = $val->warningcount

returns the number of warnings found for the checked style sheet. 
Get the details of each warning with $val->warnings (see below).


=item my @warnings = $val->warnings

Returns a list with information about the warnings found for the
style sheet. 

=item my $ua = $val->user_agent

=item my $ua = $val->user_agent($new_ua)

The L<LWP::UserAgent> object you supplied to the constructor or a
custom object created at construction time you can manipulate.

  # set timeout to 30 seconds
  $val->user_agent->timeout(30);
  
You can also supply a new object to replace the old one.

=item my $uri = $val->validator_uri

=item my $uri = $val->validator_uri($validator_uri)

Gets or sets the URI of the validator. If you did not specify a
custom URI, C<http://jigsaw.w3.org/css-validator/validator> by
default.

=item my $response = $val->response

The L<HTTP::Response> object returned from the last request. This is
useful to determine why validation might have failed.

  if (!$val->validate(string => $css)) {
    if (!$val->response->is_success) {
      print $val->response->message, "\n"
    }
  }

=item my $uri = $val->request_uri

The L<URI> object used for the last request.

=item my $som = $val->som

The L<SOAP::SOM> object for the last successful deserialization, check the
return value of C<validate()> or C<success()> before using the object.

=back

=head1 BUGS

This module uses the SOAP interface for the W3C CSS validatom, which still 
has a number of bugs, tracked via W3C's Bugzilla, L<http://www.w3.org/Bugs/Public/>.

Please report bugs in the W3C CSS Validator to L<www-validator-css@w3.org> or
enter them directly in Bugzilla (see above). Please report bugs in this module
via RT, L<http://rt.cpan.org/>.

=head1 NOTE

This module is not directly associated with the W3C. Please remember
that the CSS Validator is a shared resource so do not abuse it: you should
sleep between requests, and consider installing the Validator locally, see
L<http://jigsaw.w3.org/css-validator/DOWNLOAD.html>.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright 2004-2013 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
