package WWW::WorldLingo;
use base qw( Class::Accessor::Fast );
use strict;
use warnings;
use Carp;

our $VERSION  = "0.03";

__PACKAGE__->mk_accessors(qw( server
                              response
                              mimetype encoding
                              scheme
                              subscription password 
                              srclang trglang srcenc trgenc
                              dictno gloss
                              data
                              result
                              ));

use HTTP::Request::Common;
use HTTP::Response;
use LWP::UserAgent;

use constant ERROR_CODE_HEADER => "X-WL-ERRORCODE";
use constant API_MODE_HEADER   => "X-WL-API-MODE";

my %Errors = (
              0    => "Successful", # no error
              6    => "Subscription expired or suspended", # guessing here
              26   => "Incorrect password",
              28   => "Source language not in subscription",
              29   => "Target language not in subscription",
              176  => "Invalid language pair",
              177  => "No input data",
              502  => "Invalid Mime-type",
              1176 => "Translation timed out",
              );


sub new : method {
    my ( $class, $arg_hashref ) = @_;
    my $self = $class->SUPER::new({
                                   subscription =>"S000.1",
                                   password => "secret",
                                   server => "www.worldlingo.com",
                                   scheme => "http",
                                   %{$arg_hashref || {}},
                                  });
    $self;
}

sub agent : method {
    my ( $self, $agent ) = @_;
    $self->{_agent} = $agent;
    unless ( $self->{_agent} )
    {
        eval { require LWPx::ParanoidAgent; };
        my $agent_class = $@ ? "LWP::UserAgent" : "LWPx::ParanoidAgent";
        my $ua = $agent_class->new(agent => __PACKAGE__ ."/". $VERSION);
        $self->{_agent} = $ua;
    }
    return $self->{_agent};
}

sub request : method {
    my ( $self, $request ) = @_;
    $self->{_request} = $request if $request;
    $self->{_request} ||= POST $self->api, scalar $self->_arguments;
    return $self->{_request};
}

sub parse : method {
    my ( $class, $response ) = @_;
    my $self = $class->new();
    unless ( ref $response and $response->isa("HTTP::Response") )
    {
        $response = HTTP::Response->parse($response);
        carp "This " . ref($self) . " object has no memory of its original request";
    }
    $self->_handle_response($response);
    # responses remade from strings have *no* memory of a request in them
    $self->request( $self->response->request ) if $self->response->request;
    return $self;
}

sub api : method {
    my ( $self ) = @_;
    return join("://",
                $self->scheme,
                join("/",
                     $self->server,
                     $self->subscription,
                     "api")
                );
}

sub translate : method {
    my ( $self, $data ) = @_;
    $self->{_api_mode} = $self->{_error} = $self->{_error_code} = undef;
    $self->data($data) if $data;
    my $response = $self->agent->request($self->request);
#    use Data::Dumper;    warn Dumper $response;
    $self->_handle_response($response);
    return $self->result;
}

sub _handle_response {
    my ( $self, $response ) = @_;
    $self->response($response);
    $self->{_error_code} = $response->header(ERROR_CODE_HEADER);
    $self->{_api_mode} = $response->header(API_MODE_HEADER);

    if ( $response->is_success
         and $Errors{$self->{_error_code}} eq "Successful" )
    {
        eval  {
            $self->result( $response->decoded_content );
        };
        if ( $@ )
        {
            carp "Couldn't decode content with LWP library";
            $self->result( $response->content );
        }
        $self->result;
    }
    elsif ( $self->{_error_code} ) # API error
    {
        $self->{_error} = $Errors{$self->{_error_code}} || "Unknown error!";
    }
    elsif ( not $response->is_success  ) # Agent error
    {

        $self->{_error} = $response->status_line || "Unknown error!";
        $self->{_error_code} = $response->code;
    }
    else # this is logically impossible to reach
    {
        confess "Unhandled error";
    }
    return undef;
}

sub api_mode : method {
    return $_[0]->{_api_mode};
}

sub error : method {
    return $_[0]->{_error};
}

sub error_code : method {
    return $_[0]->{_error_code};
}

sub _arguments : method {
    my $self = shift;
    my @uri = ( "wl_errorstyle", 1 );

    croak "No data given to translate" unless $self->data =~ /\w/;
    croak "No srclang set" unless $self->srclang;
    croak "No trglang set" unless $self->trglang;

    for my $arg ( qw( password srclang trglang mimetype srcenc trgenc
                      data dictno gloss) )
    {
        next unless $self->$arg;
        push @uri, "wl_$arg", $self->$arg(); # arg pairs for HRC::POST
    }
    return wantarray ? @uri : \@uri; # HRC::POST handles encoding args
}


1;

__END__

=head1 NAME

WWW::WorldLingo - Tie into WorldLingo's subscription based translation service.


=head1 VERSION

0.03


=head1 SYNOPSIS

 use WWW::WorldLingo;
 my $wl = WWW::WorldLingo->new();
 $wl->srclang("en");
 $wl->trglang("it");
 my $italian = $wl->translate("Hello world")
    or die $wl->error;
 print $italian, "\n";


=head1 DESCRIPTION

This module makes using WorldLingo's translation API simple. The
service is subscription based. They do not do free translations except
as randomly chosen test translations; e.g., you might get back
Spanish, German, Italian, etc but you won't know which till it's
returned. Maximum of 25 words for tests.

If you are not a subscriber, this module is mostly useless.


=head1 INTERFACE 

See the WorldLingo API docs for clarification and more information:
http://www.worldlingo.com/

=over 4

=item $wl = WWW::WorldLingo->new(\%opt)

Create a WWW::WorldLingo object. Can accept any of its attributes as
arguments. Defaults to the test account WorldLingo provides.

=item $wl->data($what_to_translate)

Set/get the string (src) to be translated. You can use the
C<translate> method to feed the object its src data too.

=item $wl->request

If you want to bypass L<WWW::WorldLingo> manually making an HTTP
request and take the L<HTTP::Request> object and do something with it
yourself.

=item $wl->parse

Likewise if you want have bypassed a C<translate> call or stored a
response, you can reconstitute--to a degree--the L<WWW::WorldLingo>
object by using C<parse> on the L<HTTP::Response>.

Returns a L<WWW::WorldLingo> object which attempts to represent one
which would create an identical response if sent back to the
WorldLingo server.

=item $wl->translate([$data])

Perform the translation of the data and return the result (trg).
Accepts new data so the object can be reused easily.

If nothing is returned, there was an error. Errors can either be set
by the API -- you did something wrong in your call or they have a
problem -- or the requesting agent -- you have some sort of connection
issues.

=item $wl->result

What C<translate> returns.

=item $wl->error

A text string of the error.

=item $wl->error_code

The code of the error. If it's from WorldLingo, it's a proprietary
number. If it's from the user agent, it's the HTTP status code.

=item $wl->api

The URI for service calls.

=item $wl->scheme

"http" [default] or "https."

=item $wl->agent

The web agent. You can set your own or WWW::WorldLingo Tries to use
L<LWPx::ParanoidAgent> and falls back to L<LWP::UserAgent> if it must.
You can provide your own as long as it's a subclass of
L<LWP::UserAgent> (like L<WWW::Mechanize>) or a class which offers the
same hooks into the L<HTTP::Request>s and L<HTTP::Response>s.

You can override or change agents at any time.

=item $wl->mimetype

=item $wl->encoding

=item $wl->subscription

Your WorldLingo subscription ID. The default is their test account,
C<S000.1>.

=item $wl->password

Your WorldLingo password. The default is for their test account,
C<secret>.

=item $wl->srclang

The language your original data is in.

=item $wl->trglang

The language you want returned as translated.

=item $wl->srcenc

The encoding of your original language.

=item $wl->trgenc

The encoding you want back for your translated text.

=item $wl->dictno

WorldLingo allows paid users to build their own dictionaries to
deal with custom terminology and filtering.

=item $wl->gloss

WorldLingo has special glossaries to try to improve translation
quality.

=item $wl->api_mode

Should come back "TEST MODE ONLY - Random Target Languages" for tests.

=back


=head1 DIAGNOSTICS

See L<HTTP::Status> for error codes thrown by the agent. Here is a
short list of WorldLingo diagnostics.

 Error code   Error
      0       Successful
     26       Incorrect password
     28       Source language not in subscription
     29       Target language not in subscription
    176       Invalid language pair
    177       No input data
    502       Invalid Mime-type
   1176       Translation timed out

Access this information after a failed C<translation> request with
C<error_code> and C<error>.


=head1 DEPENDENCIES

L<HTTP::Request::Common>, L<LWP::UserAgent>, L<Carp>, an Internet
connection.


=head1 TO DO

Better tests. Very little of the real object is being looked at by the
tests right now.

Get the API from WorldLingo that comes with a subscription account to
fill in the blanks.

Support for multiple requests at once, partitioned in XHTML so they
can be separated back out on return.

Docs for the Mime stuff.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-worldlingo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Ashley Pond V, C<< <ashley@cpan.org> >>.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Ashley Pond V.

This module is free software; you can redistribute it and modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

