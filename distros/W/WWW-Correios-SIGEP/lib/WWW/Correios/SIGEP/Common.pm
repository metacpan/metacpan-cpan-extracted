package WWW::Correios::SIGEP::Common;
use strict;
use warnings;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;              # <-- loads the soap namespace
use XML::Compile::Transport::SOAPHTTP; # <-- sends messages over HTTP
use LWP::UserAgent;                    # <-- see "Note" on build_transport();
use File::ShareDir;

sub call {
    my ($self, $operation, $params) = @_;
    my $call = compiled_client($self, $operation);
    return process_return($self, $operation, $call->($params));
}

sub process_return {
    my ($self, $operation, $return, $trace) = @_;

    if ($self->{debug}) {
        $trace->printErrors;
        $trace->printRequest;
        $trace->printResponse;
    }
    if (exists $return->{parameters}{return}) {
        return $return->{parameters}{return};
    }
    elsif (exists $return->{parameters}{$operation}) {
        if (exists $return->{parameters}{$operation}{resultado_solicitacao}) {
            return $return->{parameters}{$operation}{resultado_solicitacao};
        }
        else {
            return $return->{parameters}{$operation};
        }
    }
    else {
        return $return;
    }
}

sub compiled_client {
    my ($self, $operation) = @_;

    my $key = '_compiled' . $operation;
    if (!$self->{$key}) {
        $self->{$key} = $self->{wsdl}->compileClient(
            operation => $operation,
            transport => $self->{transport},
        );
    }
    return $self->{$key};
}

# FIXME: (fixed in XML::Compile::SOAP 3.07)
# Use of uninitialized value $ns in hash element at XML/Compile/Cache.pm line 125.
# Use of uninitialized value $ns in hash element at XML/Compile/Cache.pm line 134.
# Use of uninitialized value $ns in concatenation (.) or string at XML/Compile/Cache.pm line 135.
# Use of uninitialized value in string eq at XML/Compile/Cache.pm line 166.
# Use of uninitialized value $ns in string eq at XML/Compile/Cache.pm line 166.
sub build_transport {
    my ($self) = @_;

    my $local_file = File::ShareDir::dist_file(
        'WWW-Correios-SIGEP',
        $self->{wsdl_local_file}
    );
    $self->{wsdl} = XML::Compile::WSDL11->new( $local_file );

    ############################################################
    ### Note:
    ### -----
    ### Of course Correios does *NOT* have a valid certificate,
    ### Otherwise we'd be able to skip all this and just do:
    ###
    ###    my $call = $wsdl->compileClient( 'method' );
    ###
    ### but if we do that we get:
    ### "Can't connect to apphom.correios.com.br:443 (certificate verify failed)"
    ###
    ### which is why we need to customize our transport here :(
    my @timeout = $self->{timeout} ? (timeout => $self->{timeout}) : ();
    my $ua = LWP::UserAgent->new(
        @timeout,
        ssl_opts => { verify_hostname => 0 },
#        $self->{usuario}, $self->{senha}
    );
    $ua->credentials( @{$self->{ua_auth}} ) if exists $self->{ua_auth};

    $self->{transport} = XML::Compile::Transport::SOAPHTTP->new(
        address    => $self->{wsdl}->endPoint,
        @timeout,
        user_agent => $ua
    )->compileClient();

    if ($self->{precompile}) {
        foreach my $operation (@{$self->{precompile}}) {
            compiled_client($self, $operation);
        }
    }
    return $self;
}

42;
