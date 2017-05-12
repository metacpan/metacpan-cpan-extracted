# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Client;
use vars '$VERSION';
$VERSION = '3.21';


use Log::Report 'xml-compile-soap', syntax => 'SHORT';

use XML::Compile::Util qw/unpack_type/;
use XML::Compile::SOAP::Trace;
use Time::HiRes        qw/time/;


sub new(@) { panic __PACKAGE__." only secundary in multiple inheritance" }
sub init($) { shift }

#--------------

my $rr = 'request-response';

sub compileClient(@)
{   my ($self, %args) = @_;

    my $name = $args{name};
    my $kind = $args{kind} || $rr;
    $kind eq $rr || $kind eq 'one-way'
        or error __x"operation direction `{kind}' not supported for {name}"
             , rr => $rr, kind => $kind, name => $name;

    my $encode = $args{encode}
        or error __x"encode for client {name} required", name => $name;

    my $decode = $args{decode}
        or error __x"decode for client {name} required", name => $name;

    my $transport = $args{transport}
        or error __x"transport for client {name} required", name => $name;

    if(ref $transport eq 'CODE') { ; }
    elsif(UNIVERSAL::isa($transport, 'XML::Compile::Transport::SOAPHTTP'))
    {   $transport = $transport->compileClient(soap => $args{soap});
    }
    else
    {   error __x"transport for client {name} is code ref or {type} object, not {is}"
          , name => $name, type => 'XML::Compile::Transport::SOAPHTTP'
          , is => (ref $transport || $transport);
    }

    my $output_handler = sub {
        my ($ans, $trace, $xops) = @_;
        wantarray or return
            UNIVERSAL::isa($ans, 'XML::LibXML::Node') ? $decode->($ans) : $ans;

        if(UNIVERSAL::isa($ans, 'XML::LibXML::Node'))
        {   $ans = try { $decode->($ans) };
            if($@)
            {   $trace->{decode_errors} = $@;
                my $fatal = $@->wasFatal;
                $trace->{errors} = [$fatal];
                $fatal->message($fatal->message->concat('decode error: ', 1));
            }

            my $end = time;
            $trace->{decode_elapse} = $end - $trace->{transport_end};
            $trace->{elapse} = $end - $trace->{start};
        }
        else
        {   $trace->{elapse} = $trace->{transport_end} - $trace->{start}
                if defined $trace->{transport_end};
        }
        ($ans, XML::Compile::SOAP::Trace->new($trace), $xops);
    };

    $args{async}
    ? sub  # Asynchronous call, f.i. X::C::Transfer::SOAPHTTP::AnyEvent
      { my ($data, $charset)
          = UNIVERSAL::isa($_[0], 'HASH') ? @_
          : @_%2==0 ? ({@_}, undef)
          : error __x"operation `{name}' called with odd length parameter list"
              , name => $name;

        my $callback = delete $data->{_callback}
            or error __x"operation `{name}' is async, so requires _callback";

        my $trace = {start => time};
        my ($req, $mtom) = $encode->($data, $charset);
        $trace->{encode_elapse} = time - $trace->{start};

        $transport->($req, $trace, $mtom
          , sub { $callback->($output_handler->(@_)) }
          );
      }
    : sub # Synchronous call, f.i. XML::Compile::Transfer::SOAPHTTP
      { my ($data, $charset)
          = UNIVERSAL::isa($_[0], 'HASH') ? @_
          : @_%2==0 ? ({@_}, undef)
          : panic(__x"operation `{name}' called with odd length parameter list"
              , name => $name);

        $data->{_callback}
            and error __x"operation `{name}' called with _callback, but "
                  . "compiled without async flag", name => $name;

        my $trace = {start => time};
        my ($req, $mtom) = $encode->($data, $charset);
        my ($ans, $xops) = $transport->($req, $trace, $mtom);
        wantarray || !$xops || ! keys %$xops
            or warning "loosing received XOPs";

        $trace->{encode_elapse} = $trace->{transport_start} - $trace->{start};
        $output_handler->($ans, $trace, $xops);
      };
}

#------------------------------------------------


1;
