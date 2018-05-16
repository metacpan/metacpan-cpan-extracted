# Copyrights 2007-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP-Daemon.  Meta-POD
# processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::SOAP::Daemon;
use vars '$VERSION';
$VERSION = '3.14';


use warnings;
use strict;

use Log::Report 'xml-compile-soap-daemon';

use XML::LibXML        ();
use XML::Compile::Util qw/type_of_node/;
use XML::Compile::SOAP ();

# We use HTTP status definitions for each soap protocol, but HTTP::Status
# may not be installed.
use constant
  { RC_SEE_OTHER            => 303
  , RC_FORBIDDEN            => 403
  , RC_NOT_FOUND            => 404
  , RC_UNPROCESSABLE_ENTITY => 422
  , RC_NOT_IMPLEMENTED      => 501
  };

my $parser        = XML::LibXML->new;


sub new(@)
{   my $class = shift;
    $class ne __PACKAGE__
        or error __x"you can only use extensions of {pkg}", pkg => __PACKAGE__;
    (bless {}, $class)->init( {@_} );
}

sub init($)
{   my ($self, $args) = @_;
    $self->{accept_slow_select}
      = exists $args->{accept_slow_select} ? $args->{accept_slow_select} : 1; 

    $self->addWsaTable(INPUT  => $args->{wsa_action_input});
    $self->addWsaTable(OUTPUT => $args->{wsa_action_output});
    $self->addSoapAction($args->{soap_action_input});

    if(my $support = delete $args->{support_soap})
    {   # simply only load the protocol versions you want to accept.
        error __x"new(support_soap} removed in 2.00";
    }

    my @classes = XML::Compile::SOAP->registered;
    @classes   # explicit load required since 2.00
        or warning "No protocol modules loaded.  Need XML::Compile::SOAP11?";

    $self->{output_charset} = delete $args->{output_charset} || 'UTF-8';
    $self->{handler}        = {};
    $self;
}

#-----------

sub outputCharset() {shift->{output_charset}}


sub addWsaTable($@)
{   my ($self, $dir) = (shift, shift);
    my $h = @_==1 ? shift : { @_ };
    my $t = $dir eq 'INPUT'  ? ($self->{wsa_input}  ||= {})
          : $dir eq 'OUTPUT' ? ($self->{wsa_output} ||= {})
          : error __x("addWsaTable requires 'INPUT' or 'OUTPUT', not {got}"
              , got => $dir);

    while(my($op, $action) = each %$h) { $t->{$op} ||= $action }
    $t;
}


sub addSoapAction(@)
{   my $self = shift;
    my $h = @_==1 ? shift : { @_ };
    my $t = $self->{sa_input}     ||= {};
    my $r = $self->{sa_input_rev} ||= {};
    while(my($op, $action) = each %$h)
    {   $t->{$op}     ||= $action;
        $r->{$action} ||= $op;
    }
    $t;
}

#------------------

sub run(@)
{   my ($self, %args) = @_;
    notice __x"WSA module loaded, but not used"
        if XML::Compile::SOAP::WSA->can('new') && !keys %{$self->{wsa_input}};

    $self->{wsa_input_rev}  = +{ reverse %{$self->{wsa_input}} };
    $self->_run(\%args);
}


# defined by Net::Server
sub process_request(@) { panic "must be extended" }

sub process($)
{   my ($self, $input, $req, $soapaction) = @_;

    my $xmlin;
    if(! defined $input)
    {  return $self->faultNotSoapMessage('No input');
    }
    elsif(ref $input eq 'SCALAR')
    {   $xmlin = try { $parser->parse_string($$input) };
        return $self->faultInvalidXML($@->wasFatal) if $@;
    }
    else
    {   $xmlin = $input;
    }
    
    $xmlin     = $xmlin->documentElement
        if $xmlin->isa('XML::LibXML::Document');

    my $local  = $xmlin->localName;
    $local eq 'Envelope'
        or return $self->faultNotSoapMessage(type_of_node $xmlin);

    my $envns  = $xmlin->namespaceURI || '';
    my $proto  = XML::Compile::SOAP->fromEnvelope($envns)
        or return $self->faultUnsupportedSoapVersion($envns);
    # proto is a XML::Compile::SOAP*::Operation
    my $server = $proto->serverClass;

    my $info   = XML::Compile::SOAP->messageStructure($xmlin);
    my $version  = $info->{soap_version} = $proto->version;
    my $handlers = $self->{handler}{$version} || {};

    # Try to resolve operation via WSA
    my $wsa_in   = $self->{wsa_input_rev};
    if(my $wsa_action = $info->{wsa_action})
    {   if(my $name = $wsa_in->{$wsa_action})
        {   my $handler = $handlers->{$name};
            local $info->{selected_by} = 'wsa-action';
            my ($rc, $msg, $xmlout) = $handler->($name, $xmlin, $info, $req);
            if($xmlout)
            {   trace "data ready for $version $name, via wsa $wsa_action";
                return ($rc, $msg, $xmlout);
            }
        }
    }

    # Try to resolve operation via soapAction
    my $sa = $self->{sa_input_rev};
    if(defined $soapaction)
    {   if(my $name = $sa->{$soapaction})
        {   my $handler = $handlers->{$name};
            local $info->{selected_by} = 'soap-action';
            my ($rc, $msg, $xmlout) = $handler->($name, $xmlin, $info, $req);
            if($xmlout)
            {   trace "data ready for $version $name, via sa '$soapaction'";
                return ($rc, $msg, $xmlout);
            }
        }
    }

    # Last resort, try each of the operations for the first which
    # can be parsed correctly.
    if($self->{accept_slow_select})
    {   keys %$handlers;  # reset each()
        $info->{selected_by} = 'attempt all';
        while(my ($name, $handler) = each %$handlers)
        {   my ($rc, $msg, $xmlout) = $handler->($name, $xmlin, $info, $req);
            defined $xmlout or next;

            trace "data ready for $version $name";
            return ($rc, $msg, $xmlout);
        }
    }

    my $bodyel = $info->{body}[0] || '(none)';
    my @other  = sort grep {$_ ne $version && keys %{$self->{$_}}}
        $self->soapVersions;

    return (RC_SEE_OTHER, 'SOAP protocol not in use'
      , $server->faultTryOtherProtocol($bodyel, \@other))
        if @other;

    # we do not have the names of the request body elements here :(
    my @ports = sort keys %$handlers;

      ( RC_NOT_FOUND, 'message not recognized'
      , $server->faultMessageNotRecognized($bodyel, $soapaction, \@ports)
      );
}

#------------------

sub operationsFromWSDL($@)
{   my ($self, $wsdl, %args) = @_;
    my %callbacks  = $args{callbacks} ? %{$args{callbacks}} : ();
    my %names;

    my $default_cb = $args{default_callback};
    my $wsa_input  = $self->{wsa_input};
    my $wsa_output = $self->{wsa_output};

    my $ops = $args{operations};
    my @ops = $ops ? @$ops : $wsdl->operations(%args);
    @ops or return;   # none selected

    foreach my $op (@ops)
    {   my $name = $op->name;
        warning __x"multiple operations with name `{name}'", name => $name
            if $names{$name}++;

        my $code;
        if(my $callback = $callbacks{$name})
        {   UNIVERSAL::isa($callback, 'CODE')
               or error __x"callback {name} must provide a CODE ref"
                    , name => $name;

            trace __x"add handler for operation `{name}'", name => $name;
            $code = $op->compileHandler(callback => $callback);
        }
        else
        {   trace __x"add stub handler for operation `{name}'", name => $name;
            my $handler = $default_cb
              || sub { $_[0]->faultNotImplemented($name) };

            $code = $op->compileHandler(callback => $handler);
        }

        $self->addHandler($name, $op, $code);

        if($op->can('wsaAction'))
        {   my $in  = $op->wsaAction('INPUT');
            $wsa_input->{$name}  = $in if defined $in;
            my $out = $op->wsaAction('OUTPUT');
            $wsa_output->{$name} = $out if defined $out;
        }
        $self->addSoapAction($name, $op->soapAction);
    }

    info __x"added {nr} operations from WSDL", nr => (scalar @ops);

    if(keys %names != keys %callbacks)
    {   $names{$_}
            or warning __x"no operation for callback handler `{name}'",name=>$_
                for sort keys %callbacks;
    }

    $self;
}


sub addHandler($$$)
{   my ($self, $name, $soap, $code) = @_;

    my $version = ref $soap ? $soap->version : $soap;
    $self->{handler}{$version}{$name} = $code;
}


sub setWsdlResponse($;$)
{   my ($self, $filename, $type) = @_;
    panic "not implemented by backend {pkg}", pkg => (ref $self || $self);
}

#------------------

sub handlers($)
{   my ($self, $soap) = @_;
    my $version = ref $soap ? $soap->version : $soap;
    my $table   = $self->{handler}{$version} || {};
    keys %$table;
}


sub soapVersions() { sort keys %{shift->{handler}} }


sub printIndex(;$)
{   my $self = shift;
    my $fh   = shift || \*STDOUT;

    foreach my $version ($self->soapVersions)
    {   my @handlers = $self->handlers($version);
        @handlers or next;

        local $" = "\n   ";
        $fh->print("$version:\n   @handlers\n");
    }
}


sub faultInvalidXML($)
{   my ($self, $error) = @_;
    ( RC_UNPROCESSABLE_ENTITY, 'XML syntax error'
    , __x("The XML cannot be parsed: {error}", error => $error));
}


sub faultNotSoapMessage($)
{   my ($self, $type) = @_;
    ( RC_FORBIDDEN, 'message not SOAP'
    , __x( "The message was XML, but not SOAP; not an Envelope but `{type}'"
         , type => $type));
}


sub faultUnsupportedSoapVersion($)
{   my ($self, $envns) = @_;
    ( RC_NOT_IMPLEMENTED, 'SOAP version not supported'
    , __x("The soap version `{envns}' is not supported", envns => $envns));
}

#------------------

1;
