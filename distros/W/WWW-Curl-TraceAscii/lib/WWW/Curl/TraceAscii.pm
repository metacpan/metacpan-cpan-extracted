package WWW::Curl::TraceAscii;
use strict;
use warnings;

require 5.8.8;
use Carp;
use bytes;
use WWW::Curl::Easy;
use Time::HiRes qw(gettimeofday);

use vars qw($VERSION);
$VERSION = '0.05';

=head1 NAME

WWW::Curl::TraceAscii - Perl extension interface for libcurl

=head1 SYNOPSIS

    # Just like WWW::Curl::Easy, no fancy overrides
    use WWW::Curl::TraceAscii;

    # Overrides WWW::Curl::Easy->new
    use WWW::Curl::TraceAscii qw(:new);

    # GET Example
    use WWW::Curl::TraceAscii;
    my $curl = WWW::Curl::TraceAscii->new;
    $curl->setopt(CURLOPT_URL, 'http://example.com');
    $curl->perform;
    my $response_PTR = $curl->trace_response;

    # POST Example
    use WWW::Curl::TraceAscii;
    my $response;
    my $post = "some post data";
    my $curl = WWW::Curl::TraceAscii->new;
    $curl->setopt(CURLOPT_POST, 1);
    $curl->setopt(CURLOPT_POSTFIELDS, $post);
    $curl->setopt(CURLOPT_URL,'http://example.com/');
    $curl->setopt(CURLOPT_WRITEDATA,\$response);
    $curl->perform;

    # These methods only exist in TraceAscii
    my $response_PTR = $curl->trace_response;
    my $headers_PTR = $curl->trace_headers;
    my $trace_ascii_PTR = $curl->trace_ascii;

=head1 DESCRIPTION

WWW::Curl::TraceAscii adds additional debugging helpers to WWW::Curl::Easy

=head1 DOCUMENTATION

This module uses WWW::Curl::Easy at it's base.  WWW::Curl::TraceAscii gives you the ability to record a log of your curl connection much like the --trace-ascii feature inside the curl binary.

=head2 WHY DO I NEED A TRACE?

I've been curling pages for decades.  Usually in an automatic fashion.  And while you can write code that will handle almost all failures.  You can't answer the question that will inevitably be asked for a result you didn't expect... What happened??

I've seen hundreds of different types of errors come through that without a good trace would have been impossible to get a difinitive answer as to what happened.

I've personally gotten into the practice of storing the trace data for all connections.  This allows me to review exactly what happened, even if the problem was only temporary.  Especially if the problem was fixed before I was able to review it.

=head1 ADDITIONAL METHODS

New methods added above what is normally in WWW::Curl::Easy.

=cut

sub import {
    no strict "refs"; ## no critic

    *WWW::Curl::Easy::newTraceAscii = \&WWW::Curl::Easy::new;
    for my $i (reverse 1 .. $#_) {
        if ($_[$i] eq ':new') {
            no warnings "redefine"; # We make this a few times
            *WWW::Curl::Easy::new = sub(;@) { WWW::Curl::TraceAscii->new(@_); };
        }
    }

    my $me = __PACKAGE__.'::';
    my $easy = 'WWW::Curl::Easy::';

    # Export all the CURL constants from Easy
    ${[caller]->[0].'::'}{$_} = ${__PACKAGE__."::"}{$_}
        foreach @WWW::Curl::Easy::EXPORT;

    # Make method calls for all Easy methods, redirect to the proper place
    my @curl_methods;
    push @curl_methods, $_
        foreach grep { not /^(|_.*|AUTOLOAD|EXPORT|DESTROY|VERSION|ISA|isa|BEGIN|import|Dumper|newTraceAscii)$/ } 
            keys %{"WWW::Curl::Easy::"};
    foreach my $method ( @curl_methods ) {
        my $fullme = $me.$method;
        my $fulleasy = $easy.$method;
        if (! defined *$fullme && defined *$fulleasy) {
            *$fullme = sub { my $self = shift; $self->{'curl'}->$method(@_); }
        }
    }
}

=head2 new

Create a new curl object.

=cut

sub new {
    my $class = shift;
    my $curl = WWW::Curl::Easy->newTraceAscii(@_);
    my $response;
    $curl->setopt(CURLOPT_WRITEDATA,\$response);

    my $hash = {
        curl => $curl,
        response => \$response,
        headers => &trace_headers_init($curl),
        trace_ascii => &trace_ascii_init($curl),
    };

    return bless $hash, $class;
}

=head2 setopt

Same as setopt in WWW::Curl::Easy

=cut

sub setopt {
    my $self = shift;
    if ($_[0] eq CURLOPT_WRITEDATA && ref $_[1] eq 'SCALAR') {
        $self->{'response'} = $_[1];
    }
    $self->{'curl'}->setopt(@_);
}

=head2 trace_response

This can get rather lengthy.  So to save memory it returns a pointer to the response data.

NOTE: You can still set CURLOPT_WRITEDATA yourself if you pefer.

=cut

sub trace_response {
    my $self = shift;
    $self->{'response'};
}

=head2 trace_ascii

Mimic the curl binary when you enable the --trace-ascii and --trace-time command line options.  Minus the SSL negotiation data.

This can get rather lengthy.  So to save memory it returns a pointer to the trace data.

=cut

sub trace_ascii {
    my $self = shift;
    $self->{'trace_ascii'};
}

=head2 trace_ascii_init

The actual method used to produce the trace_ascii output.

In WWW::Curl::Easy you would initialize this like so:
  my $trace_ascii = &trace_ascii_init($curl);

=cut

sub trace_ascii_init {
    my ($curl) = @_;
    my $trace = '';
    $curl->setopt(CURLOPT_DEBUGFUNCTION,\&_make_trace_ascii);
    $curl->setopt(CURLOPT_DEBUGDATA,\$trace);
    $curl->setopt(CURLOPT_HEADERDATA,\$trace);
    $curl->setopt(CURLOPT_VERBOSE, 1);
    return \$trace;
}

=head2 trace_headers

Returns an array of headers from your curl call.

=cut

sub trace_headers {
    my $self = shift;
    $self->{'headers'};
}

=head2 trace_headers_init

The actual method used to produce the trace_headers output.

In WWW::Curl::Easy you would initialize this like so:
  $headers = &trace_headers_init($curl);

=cut

sub trace_headers_init {
    my ($curl) = @_;
    my @headers;
    my $header_func = sub {
        my ($header) = @_;
        $header =~ s/[\r\n]?[\r\n]$//g;
        push @headers, $header if $header ne '';
        return length($_[0]);
    };
    $curl->setopt(CURLOPT_HEADERFUNCTION,$header_func);
    return \@headers;
}

sub _make_trace_ascii {
    my ($data,$tracePTR,$data_type) =@_;
    my ($seconds, $microseconds) = gettimeofday;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday)=localtime($seconds);

    $$tracePTR .= sprintf('%02d:%02d:%02d.%d ',$hour,$min,$sec,$microseconds);
    my $l = length($data);

    if ($data_type == 0) {
        $$tracePTR .= "== Info: ".$data;
    } elsif ($data_type == 1) {
        $data =~ s/\r?\n$//;
        $$tracePTR .= sprintf("<= Recv header, %d bytes (0x%x)\n",$l,$l)._format_debug_data($data);
    } elsif ($data_type == 2) {
           $data =~ s/\r?\n$//;
        $$tracePTR .= sprintf("=> Send header, %d bytes (0x%x)\n",$l,$l)._format_debug_data($data);
    } elsif ($data_type == 3) {
        $$tracePTR .= sprintf("<= Recv data, %d bytes (0x%x)\n",$l,$l)._format_debug_data($data,1);
    } elsif ($data_type == 4) {
        $$tracePTR .= sprintf("=> Send data, %d bytes (0x%x)\n",$l,$l)._format_debug_data($data,1);
    } else {
        # not sure what any of these values would be, but just in case
        $$tracePTR .= "== Unknown $data_type: ".$data;
    }
    return 0;
}

sub _format_debug_data {
    my ($data,$mask_returns) = @_;
    my $c = 0;
    my $a = $mask_returns ? [$data] : [split /\r\n/, $data, -1];
    $a->[0] = '' unless scalar(@$a);
    my $text = '';
    foreach my $bit ( @$a ) {
        my @array = unpack '(a64)*', $bit;
        $array[0] = '' unless scalar(@array);
        foreach my $line ( @array ) {
            $line =~ s/[^\ -\~]/./ig;
            my $len = bytes::length($line);
            $line = sprintf('%04x: ',$c).$line;
            $c+=2 unless $mask_returns; # add they \r\n back in
            $c+=$len;
        }
        $text .= (join "\n",@array)."\n";
    }
    $text;
}

1;
