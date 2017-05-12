package Zabbix::ServerScript::API;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use LWP::UserAgent;
use Log::Log4perl;
use Carp;

our $AUTOLOAD;
our $logger;
our $ua;

BEGIN {
	eval {
		require Zabbix::ServerScript::Config;
		1;
	} or die q(Zabbix::ServerScript::Config must be present and filled with proper Zabbix credentials);
}

sub AUTOLOAD {
	my ($self, $params) = @_;
	my $method_name = $AUTOLOAD;
	$logger->debug(qq(Autoloading method $method_name));
	$method_name =~ s/^.*:://;
	$method_name =~ s/_/./;
	return $self->_request($method_name, $params);
}

sub DESTROY {}

sub new {
	my ($url) = @_;
	my $self = {
		url => $url,
		auth => undef,
	};
	bless $self;
	return $self;
}

sub init {
	my ($api) = @_;
	my $log_category = defined $ENV{LOG_CATEGORY} ? $ENV{LOG_CATEGORY} : __PACKAGE__;
	$logger = Log::Log4perl::get_logger($log_category);

	my $api_config;
	croak(q(Missing API configuration)) unless defined ($api_config = $Zabbix::ServerScript::Config->{api});
	croak(q(API URL is not defined in config)) unless defined $api_config->{url};
	croak(qq(User credentials are not defined in config for API '$api')) unless (defined $api_config->{$api}->{login} and defined $api_config->{$api}->{password});

	$ua = LWP::UserAgent->new;
	$ua->timeout($api_config->{timeout});
	my $self = new($api_config->{url});

	$self->{auth} = $self->user_login({
		user => $api_config->{$api}->{login},
		password => $api_config->{$api}->{password},
	});
	return $self;
}

sub _request {
	my ($self, $method_name, $params) = @_;
	$params = {} unless defined $params;
	my $request_hashref = {
		jsonrpc => q(2.0),
		method => $method_name,
		params => $params,
		auth => $self->{auth},
		id => 1,
	};
	my $request_json = encode_json($request_hashref);
	$logger->debug(qq(API request: $request_json));
	my $res = $ua->post(
		$self->{url},
		q(Content-Type) => q(application/json-rpc),
		q(Content) => $request_json,
	); 
	croak(qq(Cannot make request "$method_name": ) . $res->status_line) if $res->is_error;
	my $response_json = $res->content;
	$logger->debug(qq(API response: $response_json));
	my $response_hashref = decode_json($response_json);
	if (defined $response_hashref->{error}){
		croak(qq(Zabbix API error: $response_hashref->{error}->{message}. $response_hashref->{error}->{data}));
	}
	return $response_hashref->{result};
}

1;

__END__

=encoding utf-8

=head1 NAME

Zabbix::ServerScript::API - Implementation of Zabbix JSON-RPC 2.0 API.

=head1 SYNOPSIS

    #!/usr/bin/perl
    
    use strict;
    use warnings;
    use utf8;
    use Getopt::Long qw(:config bundling);
    use Zabbix::ServerScript;
    
    my $opt = {
    	unique => 1,
	api => q(rw),
    };
    
    my @opt_specs = qw(
    	verbose|v+
    	debug
    	console
    );
    
    sub main {
    	GetOptions($opt, @opt_specs);
    	Zabbix::ServerScript::init($opt);
	my $host = $zx_api->host_get({
		filter => {
			host => q(Zabbix server),
		},
	});
	Zabbix::ServerScript::return_value($host->[0]->{hostid});
    }

    main();

=head1 DESCRIPTION

Zabbix::ServerScript::API is a pure-perl implementation of Zabbix JSON-RPC 2.0 API. It is meant to be used as a part of Zabbix::ServerScript module.

=head1 SUBROUTINES

=head2 init($config_credential_section_name)

Performs login to Zabbix with choosen credentials and returns an object of Zabbix::ServerScript::API.

Any "foo_bar" method of this object will be transformed to "foo.bar" request to Zabbix API and return result of this request as a Perl structure.

=head1 LICENSE

Copyright (C) Anton Alekseyev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Alekseyev E<lt>akint.wr+github@gmail.comE<gt>

=cut
