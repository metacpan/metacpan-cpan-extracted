# Copyrights 2009-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package XML::Compile::RPC::Client;
use vars '$VERSION';
$VERSION = '0.17';


use XML::Compile::RPC        ();
use XML::Compile::RPC::Util  qw/fault_code/;

use Log::Report              'xml-compile-rpc', syntax => 'LONG';
use Time::HiRes              qw/gettimeofday tv_interval/;
use HTTP::Request            ();
use LWP::UserAgent           ();


sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;
    $self->{user_agent}  = $args->{user_agent} || LWP::UserAgent->new;
    $self->{xmlformat}   = $args->{xmlformat}  || 0;
    $self->{auto_under}  = $args->{autoload_underscore_is};
    $self->{destination} = $args->{destination}
        or report ERROR => __x"client requires a destination parameter";

    # convert header template into header object
    my $headers = $args->{http_header};
    $headers    = HTTP::Headers->new(@{$headers || []})
        unless UNIVERSAL::isa($headers, 'HTTP::Headers');

    # be sure we have a content-type
    $headers->content_type
        or $headers->content_type('text/xml');

    $self->{headers}     = $headers;
    $self->{schemas}     = $args->{schemas} ||= XML::Compile::RPC->new;
    $self;
}


sub headers() {shift->{headers}}


sub schemas() {shift->{schemas}}


my %trace;
sub trace() {\%trace}


sub printTrace(;$)
{   my $self = shift;
    my $fh   = shift || \*STDERR;

    $fh->print("response: ",$trace{response}->status_line, "\n");
    $fh->print("elapse:   $trace{total_elapse}\n");
}


sub call($@)
{   my $self    = shift;
    my $start   = [gettimeofday];
    my $request = $self->_request($self->_callmsg(@_));
    my $format  = [gettimeofday];
    my $response  = $self->{user_agent}->request($request);
    my $network = [gettimeofday];
    
    %trace      =
      ( request        => $request
      , response       => $response
      , start_time     => ($start->[0] + $start->[1]*10e-6)
      , format_elapse  => tv_interval($start, $format)
      , network_elapse => tv_interval($format, $network)
      );

   $response->is_success
      or return ($response->code, $response->status_line);

   my ($rc, $decoded) = $self->_respmsg($response->decoded_content);
   $trace{decode_elapse} = tv_interval $network;
   $trace{total_elapse}  = tv_interval $start;

   ($rc, $decoded);
}

sub _callmsg($@)
{   my ($self, $method) = (shift, shift);

    my @params;
    while(@_)
    {   my $type  = shift;
        my $value = UNIVERSAL::isa($type, 'HASH') ? $type : {$type => shift};
        push @params, { value => $value };
    }

    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $xml = $self->{schemas}->writer('methodCall')->($doc
      , { methodName => $method, params => { param => \@params }});
    $doc->setDocumentElement($xml);
    $doc;
}

sub _request($)
{   my ($self, $doc) = @_;
    HTTP::Request->new
      ( POST => $self->{destination}
      , $self->{headers}
      , $doc->toString($self->{xmlformat})
      );
}

sub _respmsg($)
{   my ($self, $xml) = @_;
    length $xml or return (1, "no xml received");
    my $data = $self->{schemas}->reader('methodResponse')->($xml);
    return fault_code $data->{fault}
        if $data->{fault};

    my ($type, $value) = %{$data->{params}{param}{value}};
    (0, $value);
}

sub AUTOLOAD
{   my $self  = shift;
    (my $proc = our $AUTOLOAD) =~ s/.*\:\://;
    $proc =~ s/_/$self->{auto_under}/g
        if defined $self->{auto_under};
    $self->call($proc, @_);
}

sub DESTROY {}   # avoid DESTROY to AUTOLOAD

1;

__END__

