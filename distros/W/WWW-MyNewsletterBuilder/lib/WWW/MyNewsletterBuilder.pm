#
# Copyright (C) 2010 JBA Network (http://www.jbanetwork.com)
# WWW::MyNewsletterBuilder is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# WWW::MyNewsletterBuilder is an interface to the mynewsletterbuilder.com
# XML-RPC API.
#
# $Id: MyNewsletterBuilder.pm 59878 2010-05-04 22:15:50Z bo $
#

package WWW::MyNewsletterBuilder;

use strict;
use warnings;
use Frontier::Client;

our $VERSION = '0.021';

sub new {
	my $class = shift;
	my $args  = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	if (!$args->{api_key}){
		die('you must pass an api_key to WWW::MyNewsletterBuilder->new()');
	}

	my $self  = {
		api_key       => $args->{api_key},
		username      => $args->{username},
		password      => $args->{password},
		timeout       => $args->{timeout}       || 300,
		secure        => $args->{secure}        || 0,
		no_validation => $args->{no_validation} || 0,
		_api_host     => $args->{_api_host}     || 'api.mynewsletterbuilder.com',
		_api_version  => $args->{_api_version}  || '1.0',
		_debug        => $args->{_debug}        || 0,
	};

	bless($self, $class);

	# we have to bless before setting up the url and client
	my $url = $self->_buildUrl();
	if ($self->{_debug}){
		print "url: $url\n";
	}

	$self->{client} = $self->_getClient($url);
	return $self;
}

# the only config var that might need to be changed between calls is timeout
sub Timeout{
	my $self = shift;
	$self->{timeout} = shift;
	$self->{client}->{ua}->timeout($self->{timeout});
	return 1;
}

sub Campaigns{
	my $self    = shift;
	my $filters = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	$filters = $self->_validateHash(
		$filters,
		{
			status => {
				value   => 'string',
				emptyOk => 1,
			},
			archived => {
				value   => 'bool',
				emptyOk => 1,
			},
			published => {
				value   => 'bool',
				emptyOk => 1,
			},
		},
		1
	);

	return $self->_Execute('Campaigns', $filters);
}

sub CampaignDetails{
	my $self = shift;
	my $id   = $self->_intify(shift);

	return $self->_Execute('CampaignDetails', $id);
}

sub CampaignCreate{
	my $self          = shift;
	my $name          = $self->_stringify(shift);
	my $subject       = $self->_stringify(shift);
	my $from          = shift;
	my $reply         = shift;
	my $html          = $self->_stringify(shift);
	my $text          = $self->_stringify(shift || '', 1);
	my $link_tracking = $self->_boolify(shift || 1);
	my $gat           = $self->_boolify(shift || 0);

	$from = $self->_validateHash(
		$from,
		{
			name => {
				value => 'string',
			},
			email => {
				value => 'string',
			},
		},
	);
	
	$reply = $self->_validateHash(
		$reply,
		{
			name => {
				value => 'string',
				emptyOk => 1,
			},
			email => {
				value => 'string',
				emptyOk => 1,
			},
		},
		1
	);

	return $self->_Execute(
		'CampaignCreate',
		$name,
		$subject,
		$from,
		$reply,
		$html,
		$text,
		$link_tracking,
		$gat,
	);
}

sub CampaignUpdate{
	my $self          = shift;
	my $id            = $self->_intify(shift);
	my $details       = shift;

	my $signature = {};
	$signature->{name}             = {value => 'string'};
	$signature->{subject}          = {value => 'string'};
	$signature->{html}             = {value => 'string'};
	$signature->{text}             = {value => 'string', emptyOk => 1};
	$signature->{link_tracking}    = {value => 'bool',   emptyOk => 1};
	$signature->{gat}              = {value => 'bool',   emptyOk => 1};

	$signature->{from} = {
		value => {
			name => {
				value => 'string',
			},
			email => {
				value => 'string',
			},
		},
	};
	$signature->{reply} = {
		value => {
			name => {
				value => 'string',
				emptyOk => 1,
			},
			email => {
				value => 'string',
				emptyOk => 1,
			},
		},
		emptyOk => 1,
	};

	$details = $self->_validateHash($details, $signature);

	return $self->_Execute(
		'CampaignUpdate',
		$id,
		$details,
	);
}

sub CampaignCopy{
	my $self = shift;
	my $id   = $self->_intify(shift);
	my $name = $self->_stringify(shift || '', 1);

	return $self->_Execute('CampaignCopy', $id, $name);
}

sub CampaignDelete{
	my $self = shift;
	my $id   = $self->_intify(shift);

	return $self->_Execute('CampaignDelete', $id);
}

sub CampaignSchedule{
	my $self      = shift;
	my $id        = $self->_intify(shift);
	my $when      = $self->_stringify(shift);
	my $lists     = shift;
	my $smart     = $self->_boolify(shift || 0);
	my $confirmed = $self->_boolify(shift || 0);

	$lists = $self->_validateArray($lists, 'int', 1);

	return $self->_Execute(
		'CampaignSchedule',
		$id,
		$when,
		$lists,
		$smart,
		$confirmed
	);
}

sub CampaignStats{
	my $self = shift;
	my $id   = $self->_intify(shift);

	return $self->_Execute('CampaignStats', $id);
}

sub CampaignRecipients{
	my $self  = shift;
	my $id    = $self->_intify(shift);
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignRecipients',
		$id,
		$page,
		$limit
	);
}

sub CampaignOpens{
	my $self  = shift;
	my $id    = $self->_intify(shift);
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignOpens',
		$id,
		$page,
		$limit
	);
}

sub CampaignBounces{
	my $self  = shift;
	my $id    = $self->_intify(shift);
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignBounces',
		$id,
		$page,
		$limit
	);
}

sub CampaignClicks{
	my $self   = shift;
	my $id    = $self->_intify(shift);
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignClicks',
		$id,
		$page,
		$limit
	);
}

sub CampaignClickDetails{
	my $self   = shift;
	my $id     = $self->_intify(shift);
	my $url_id = $self->_intify(shift);
	my $page   = $self->_intify(shift || 0);
	my $limit  = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignClickDetails',
		$id,
		$url_id,
		$page,
		$limit
	);
}

sub CampaignSubscribes{
    my $self  = shift;
	my $id    = $self->_intify(shift);
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignSubscribes',
		$id,
		$page,
		$limit
	);
}

sub CampaignUnsubscribes{
    my $self  = shift;
	my $id    = $self->_intify(shift);
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute(
		'CampaignUnsubscribes',
		$id,
		$page,
		$limit
	);
}

sub CampaignUrls{
    my $self = shift;
	my $id   = $self->_intify(shift);

	return $self->_Execute('CampaignUrls', $id);
}

sub Lists{
	my $self = shift;
	
	return $self->_Execute('Lists');
}

sub ListDetails{
	my $self = shift;
	my $id   = $self->_intify(shift);
	
	return $self->_Execute('ListDetails', $id);
}

sub ListCreate{
	my $self        = shift;
	my $name        = $self->_stringify(shift);
	my $description = $self->_stringify(shift || '', 1);
	my $visible     = $self->_boolify(shift || 0);
	my $default     = $self->_boolify(shift || 0);

	return $self->_Execute(
		'ListCreate',
		$name,
		$description,
		$visible,
		$default
	);
}

sub ListUpdate{
	my $self        = shift;
	my $id          = $self->_intify(shift);
	my $details     = shift;

	my $signature = {};
	$signature->{name} = {
		value   => 'string',
		emptyOk => 1,
	};
	$signature->{description} = {
		value   => 'string',
		emptyOk => 1,
	};
	$signature->{visible} = {
		value   => 'bool',
		emptyOk => 1,
	};
	$signature->{default} = {
		value   => 'bool',
		emptyOk => 1,
	};

	$details = $self->_validateHash($details, $signature);

	return $self->_Execute('ListUpdate', $id, $details);
}

sub ListDelete{
	my $self        = shift;
	my $id          = $self->_intify(shift);
	my $delete_subs = $self->_boolify(shift || 0);

	return $self->_Execute('ListDelete', $id, $delete_subs);
}

sub Subscribe{
	my $self            = shift;
	my $details         = shift;
	my $lists           = shift;
	my $skip_opt_in     = $self->_boolify(shift || 0);
	my $update_existing = $self->_boolify(shift || 1);

	my $signature = {};
	$signature->{email}        = {value => 'string'};
	$signature->{first_name}   = {value => 'string', emptyOk => 1};
	$signature->{middle_name}  = {value => 'string', emptyOk => 1};
	$signature->{last_name}    = {value => 'string', emptyOk => 1};
	$signature->{full_name}    = {value => 'string', emptyOk => 1};
	$signature->{company_name} = {value => 'string', emptyOk => 1};
	$signature->{job_title}    = {value => 'string', emptyOk => 1};
	$signature->{phone_work}   = {value => 'string', emptyOk => 1};
	$signature->{phone_home}   = {value => 'string', emptyOk => 1};
	$signature->{address_1}    = {value => 'string', emptyOk => 1};
	$signature->{address_2}    = {value => 'string', emptyOk => 1};
	$signature->{address_3}    = {value => 'string', emptyOk => 1};
	$signature->{city}         = {value => 'string', emptyOk => 1};
	$signature->{state}        = {value => 'string', emptyOk => 1};
	$signature->{zip}          = {value => 'string', emptyOk => 1};
	$signature->{country}      = {value => 'string', emptyOk => 1};

	$details = $self->_validateHash($details, $signature);

	$lists = $self->_validateArray($lists, 'int', 1);

	return $self->_Execute(
		'Subscribe',
		$details,
		$lists,
		$skip_opt_in,
		$update_existing
	);
}

sub SubscribeBatch{
	my $self            = shift;
	my $subscribers     = shift;
	my $lists           = shift;
	my $skip_opt_in     = $self->_boolify(shift || 0);
	my $update_existing = $self->_boolify(shift || 1);

	my $signature = {};
	$signature->{email}        = {value => 'string'};
	$signature->{first_name}   = {value => 'string', emptyOk => 1};
	$signature->{middle_name}  = {value => 'string', emptyOk => 1};
	$signature->{last_name}    = {value => 'string', emptyOk => 1};
	$signature->{full_name}    = {value => 'string', emptyOk => 1};
	$signature->{company_name} = {value => 'string', emptyOk => 1};
	$signature->{job_title}    = {value => 'string', emptyOk => 1};
	$signature->{phone_work}   = {value => 'string', emptyOk => 1};
	$signature->{phone_home}   = {value => 'string', emptyOk => 1};
	$signature->{address_1}    = {value => 'string', emptyOk => 1};
	$signature->{address_2}    = {value => 'string', emptyOk => 1};
	$signature->{address_3}    = {value => 'string', emptyOk => 1};
	$signature->{city}         = {value => 'string', emptyOk => 1};
	$signature->{state}        = {value => 'string', emptyOk => 1};
	$signature->{zip}          = {value => 'string', emptyOk => 1};
	$signature->{country}      = {value => 'string', emptyOk => 1};

	$subscribers = $self->_validateArray($subscribers, $signature);

	$lists = $self->_validateArray($lists, 'int', 1);

	return $self->_Execute(
		'SubscribeBatch',
		$subscribers,
		$lists,
		$skip_opt_in,
		$update_existing
	);
}

sub Subscribers{
	my $self = shift;
	my $statuses = shift;
	my $lists = shift;
	my $page  = $self->_intify(shift || 0);
	my $limit = $self->_intify(shift || 1000);

	return $self->_Execute('Subscribers', $statuses, $lists, $page, $limit);
}

sub SubscriberDetails{
	my $self        = shift;
	my $id_or_email = $self->_stringify(shift);

	return $self->_Execute('SubscriberDetails', $id_or_email);
}

sub SubscriberUpdate{
	my $self        = shift;
	my $id_or_email = $self->_stringify(shift);
	my $details     = shift;
	my $lists       = shift;
	
	my $signature = {};
	$signature->{email}        = {value => 'string'};
	$signature->{first_name}   = {value => 'string', emptyOk => 1};
	$signature->{middle_name}  = {value => 'string', emptyOk => 1};
	$signature->{last_name}    = {value => 'string', emptyOk => 1};
	$signature->{full_name}    = {value => 'string', emptyOk => 1};
	$signature->{company_name} = {value => 'string', emptyOk => 1};
	$signature->{job_title}    = {value => 'string', emptyOk => 1};
	$signature->{phone_work}   = {value => 'string', emptyOk => 1};
	$signature->{phone_home}   = {value => 'string', emptyOk => 1};
	$signature->{address_1}    = {value => 'string', emptyOk => 1};
	$signature->{address_2}    = {value => 'string', emptyOk => 1};
	$signature->{address_3}    = {value => 'string', emptyOk => 1};
	$signature->{city}         = {value => 'string', emptyOk => 1};
	$signature->{state}        = {value => 'string', emptyOk => 1};
	$signature->{zip}          = {value => 'string', emptyOk => 1};
	$signature->{country}      = {value => 'string', emptyOk => 1};

	$details = $self->_validateHash($details, $signature);

	$lists = $self->_validateArray($lists, 'int', 1);

	return $self->_Execute(
		'SubscriberUpdate',
		$id_or_email,
		$details,
		$lists,
	);
}

sub SubscriberUnsubscribe{
	my $self        = shift;
	my $id_or_email = $self->_stringify(shift);

	return $self->_Execute('SubscriberUnsubscribe', $id_or_email);
}

sub SubscriberUnsubscribeBatch{
	my $self          = shift;
	my $ids_or_emails = shift;

	$ids_or_emails = $self->_validateArray($ids_or_emails, 'string');

	return $self->_Execute('SubscriberUnsubscribeBatch', $ids_or_emails);
}

sub SubscriberDelete{
	my $self        = shift;
	my $id_or_email = $self->_stringify(shift);

	return $self->_Execute('SubscriberDelete', $id_or_email);
}

sub SubscriberDeleteBatch{
	my $self          = shift;
	my $ids_or_emails = shift;

	$ids_or_emails = $self->_validateArray($ids_or_emails, 'string');

	return $self->_Execute('SubscriberDeleteBatch', $ids_or_emails);
}

sub AccountKeys{
	my $self     = shift;
	my $username = $self->_stringify(shift);
	my $password = $self->_stringify(shift);
	my $disabled = $self->_boolify(shift || 0);

	return $self->_Execute(
		'AccountKeys',
		$username,
		$password,
		$disabled,
	);
}

sub AccountKeyCreate{
	my $self     = shift;
	my $username = $self->_stringify(shift);
	my $password = $self->_stringify(shift);

	return $self->_Execute('AccountKeyCreate', $username, $password);
}

sub AccountKeyEnable{
	my $self      = shift;
	my $username  = $self->_stringify(shift);
	my $password  = $self->_stringify(shift);
	my $id_or_key = $self->_stringify(shift);

	return $self->_Execute(
		'AccounKeyEnable',
		$username,
		$password,
		$id_or_key
	);
}

sub AccountKeyDisable{
	my $self      = shift;
	my $username  = $self->_stringify(shift);
	my $password  = $self->_stringify(shift);
	my $id_or_key = $self->_stringify(shift);

	return $self->_Execute(
		'AccounKeyDisable',
		$username,
		$password,
		$id_or_key
	);
}

sub HelloWorld{
	my $self = shift;
	my $val  = $self->_stringify(shift || '', 1);

	return $self->_Execute('HelloWorld', $val);
}

sub _Execute{
	my $self   = shift;
	my $method = shift;

	$self->{errno}  = '';
	$self->{errstr} = '';

	my $data;
	eval{
		$data = $self->{client}->call($method, $self->{api_key}, @_);	
	};

	if ($self->{_debug}){
		use Data::Dumper;
		print "returned data\n";
		print Dumper $data;
	}

	if ($@){
		$self->{errno}  = 2;
		$self->{errstr} = $@;

		if ($self->{_debug}){
			print 'errors: '. $self->{errno} .'--'. $self->{errstr} ."\n";
		}

		return 0;
	}
	elsif (!$data){
		$self->{errno}  = 2;
		$self->{errstr} = 'Empty response from API server';

		if ($self->{_debug}){
			print 'errors: '. $self->{errno} .'--'. $self->{errstr} ."\n";
		}

		return 0;
	}

	if (ref($data) eq 'HASH' && $data->{'errno'}){
		$self->{errno}  = $data->{'errno'};
		$self->{errstr} = $data->{'errstr'};
		return 0;
	}

	return $self->_unBoolify($data);
}

sub _buildUrl{
	my $self = shift;
	my $url;
	if ($self->{secure}){
		$url = 'https://';
	}
	else{
		$url = 'http://';	
	}

	return $url . $self->{_api_host} . '/' . $self->{_api_version};
}

sub _getClient{
	my $self = shift;
	my $url  = shift;

	my $client = Frontier::Client->new(
		url   => $url,
		debug => 0,
	);

	# we have to modify Frontier's LWP instance a little bit.
	$client->{ua}->agent('MNB_API Perl ' . $self->{_api_version} . '/' . $VERSION . '-' . '$Rev: 59878 $');
	$client->{ua}->requests_redirectable(['GET', 'HEAD', 'POST' ]);
	$client->{ua}->timeout($self->{timeout});

	return $client;
}

sub _error{
	my $self = shift;
	my $msg  = shift;
	my $warn = shift || 0;

	if ($self->{no_validation} || $warn){
		warn($msg);
	}
	else{
		die($msg);
	}
}

sub _validateArray{
	my $self      = shift;
	my $array     = shift;
	my $signature = shift;
	my $emptyOk   = shift || 0;

	my $isHash = 0;
	if (ref($signature) eq 'HASH'){
		$isHash = 1;
	}

	if (!$array and !$emptyOk){
		$self->_error('invalid param passed to '. (caller(1))[3] .':'. (caller(0))[2] .' from '. (caller(1))[1]  .':'. (caller(1))[2] .' expected array got '. $array);
	}

	foreach (@$array){
		if ($isHash){
			$_ = validateHash($_, $signature, $emptyOk);
		}
		else{
			my $function = '_' . $signature . 'ify';
			$_ = $self->$function($_, $emptyOk);
		}
	}
	return $array;
}

##
#
# takes a hash and a signature for that hash and validates the hash's
# values then makes sure they are the proper xml-rpc types.
#
##
sub _validateHash{
	my $self      = shift;
	my $hash      = shift;
	my $signature = shift;
	my $emptyOk   = shift || 0;

	if (!$hash and !$emptyOk){
		$self->_error('invalid param passed to '. (caller(1))[3] .':'. (caller(0))[2] .' from '. (caller(1))[1]  .':'. (caller(1))[2] .' expected hash got '. $hash);
	}

	##
	#
	# we loop through the signature keys.  if the value is a hash
	# we need recursively call this function.  if it is a string
	# we validate it based on the type.
	#
	##
	foreach (keys(%$signature)){
		if (ref($signature->{$_}->{value}) eq 'HASH'){
			$hash->{$_} = $self->_validateHash($hash->{$_}, $signature->{$_}->{value}, $signature->{$_}->{emptyOk}) if (defined($hash->{$_}));
		}
		else{
			my $function = '_' . $signature->{$_}->{value} . 'ify';
			$hash->{$_} = $self->$function($hash->{$_}, $signature->{$_}->{emptyOk}) if (defined($hash->{$_}));
		}
	}

	return $hash;
}

##
#
# $self->_intify( int $var, bool $require)
# validates value of $var as an int... throws error if it isn't
# converts to Frontier int data type if test passed (or we aren't validating data))
#
##
sub _intify{
	my $self    = shift;
	my $var     = shift;
	my $emptyOk = shift || 0;

	my $check = '\d+';
	$check = '\d*' if ($emptyOk);

	$self->_error('invalid param passed to '. (caller(1))[3] .':'. (caller(0))[2] .' from '. (caller(1))[1]  .':'. (caller(1))[2] .' expected int got '. $var) unless ($var =~ /^($check)$/);

	return $self->{client}->int($var);
}

##
#
# $self->_stringify( string $var, bool $require)
# validates value of $var as an string... throws error if it isn't
# converts to Frontier string data type if test passed (or we aren't validating data))
#
##
sub _stringify{
	my $self    = shift;
	my $var     = shift;
	my $emptyOk = shift || 0;

	my $check = '.+';
	$check = '.*' if ($emptyOk);

	$self->_error('invalid param passed to '. (caller(1))[3] .':'. (caller(0))[2] .' from '. (caller(1))[1] .':'. (caller(1))[2] .' expected string got '. $var) unless ($var =~ /^($check)$/);

	return $self->{client}->string($var);
}

##
#
# $self->boolfy( int $var, bool $require)
# validates value of $var as a bool... throws error if it isn't
# converts to Frontier bool data type if test passed (or we aren't validating data))
#
##
sub _boolify{
	my $self    = shift;
	my $var     = shift;

	$self->_error('invalid param passed to '. (caller(1))[3] .':'. (caller(0))[2] .' from '. (caller(1))[1]  .':'. (caller(1))[2] .' expected bool(0 or 1) got '. $var) unless ($var =~ /^(0|1)$/);

	return $self->{client}->boolean($var);
}

sub _unBoolify{
	my $self    = shift;
	my $var     = shift;

	if (ref($var) eq 'ARRAY'){
		foreach my $v (@$var){
			$v = $self->_unBoolify($v);
		}
	}

	if (ref($var) eq 'HASH'){
		foreach (keys(%$var)){
			$var->{$_} = $self->_unBoolify($var->{$_});
		}
	}

	if (ref($var) ne 'Frontier::RPC2::Boolean'){
		return $var;
	}
	return $var->value;
}

1;
__END__

=head1 Name

WWW::MyNewsletterBuilder - Perl implementation of the mynewsletterbuilder.com API

=head1 Synopsis

instantiate the module

	use WWW::MyNewsletterBuilder;
	my $mnb = WWW::MyNewsletterBuilder->new(
		api_key     => , # your key here
	);

quick test of server connection

	print $mnb->HelloWorld('Perl Test');
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

get a list of campaigns and display their names

	my $campaigns = $mnb->Campaigns( status => 'all' );
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}	
	foreach my $c (@$campaigns){
		print $c->{name} . "\n";
	}

create a new campaign

	my $cam_id = $mnb->CampaignCreate(
		'perl test',
		'perl test subject',
		{
			name  => 'perl test from name',
			email => 'robert@jbanetwork.com'
		},
		{
			name  => 'perl test reply name',
			email => 'robert@jbanetwork.com'
		},
		'<a href="mynewsletterbuilder.com">html content</a>',
		'text content',
	);
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

create a new subscriber list

	my $list_id = $mnb->ListCreate(
		'perl test',
		'perl test list',
	);
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

add a subscriber

	my $sub = $mnb->Subscribe(
		{
			email            => 'robert@jbanetwork.com',
			first_name       => 'Robert',
			last_name        => 'Davis',
			company_name     => 'JBA Network',
			phone_work       => '8282320016,',
			address_1        => '311 Montford Ave',
			city             => 'Asheville',
			state            => 'NC',
			zip              => '28801',
			country          => 'US',
			'blah blah balh' => 'perl goes blah.',
		},
		[ $list_id ]
	);
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

schedule a campaign send

	$mnb->CampaignSchedule(
		$cam_id,
		time(), # send it NOW
		[ $list_id ],
	);
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

delete a subscriber

	$mnb->SubscriberDelete($sub->{id});
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

delete a list

	$mnb->ListDelete($list_id);
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

delete a campaign

	$mnb->CampaignDelete($cam_id);
	if ($mnb->{errno}){
		warn($mnb->{errstr});
		#oh no there was an error i should do something about it
	}

=head1 Description

=head2 Methods

=head3 Instantiation And Setup

=over 4

=item $mnb = WWW::MyNewsletterBuilder->new( %options )

This method constructs a new C<WWW::MyNewsletterBuilder> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

   KEY                     DEFAULT
   -----------             --------------------
   api_key                 undef (REQUIRED)
   username                undef
   password                undef
   timeout                 300
   secure                  0 (1 will use ssl)
   no_validation           0 (1 will warn instead of die on invalid argument !!WARNING!!)
   #############################################
   ### dev options... use at your own risk...### 
   #############################################   
   _api_host                'api.mynewsletterbuilder.com'
   _api_version             '1.0'
   _debug                   0 (1 will print all kinds of stuff)

=item $mnb->Timeout( int $timeout )

sets timeout for results

=back

=head3 Campaigns (Emails)

=over 4

=item $mnb->Campaigns( %filters )

returns an arrayref of hashrefs listing campaigns.  Optional key/value pair argument allows you to filter results:

   KEY                     OPTIONS
   ___________             ____________________
   status                  draft, sent, scheduled, all(default)
   archived                1, 0
   published               1, 0

returns an arrayref of hashrefs in the following format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id for campaign
   name                    campaign's name
   description             campaign's description
   published               1 if campaign published 0 if not
   archived                1 if campaign archied 0 if not
   status                  status will be draft, sent or scheduled

=item $mnb->CampaignDetails( int $id )

requires a campaign id and returns a hashref containing the campaign's details with the following keys:

   KEY                     DESCRIPTION
   ___________             ____________________
   id
   name                    name for reply to
   reply_name              name for reply to
   reply_email             email address for reply to
   from_name               name for from
   from_email              email address for from
   subject                 email subject
   html                    email html body
   text                    email text body

=item $mnb->CampaignCreate( string $name, string $subject, \%from, \%reply, string $html, string $text, bool $link_tracking, bool $gat )

requires a whole bunch of stuff and returns the id of the newly created campaign. arguments:

    string $name -- Internal campaign name
    string $subject -- Campaign subject line
    hashref $from -- keys are 'name' and 'email'
    hashref $reply -- keys are 'name' and 'email' (if empty $from is used)
    string $html -- HTML content for the campaign.
    string $text -- the text content for the campaign. (defaults to a stripped version of $html)
    bool $link_tracking -- 0 turn off link tracking 1(default) turns it on
    bool $gat -- 0(default) turns off Google Analytics Tracking 1 turns it on

=item $mnb->CampaignUpdate( int $id, \%details )

requires an int id and hashref details returns 1 if successful and 0 on failure. hashref format:

   KEY                     DESCRIPTION
   ___________             ____________________
   name                    Internal campaign name
   subject                 Campaign subject line
   from                    hashref with keys 'name' and 'email'
   reply                   hashref with keys are 'name' and 'email' (if empty $from is used)
   html                    HTML content for the campaign.
   text                    the text content for the campaign.
   link_tracking           0 turn off link tracking 1(default) turns it on
   gat                     0(default) turns off Google Analytics Tracking 1 turns it on

=item $mnb->CampaignCopy( int $id, string $name )

takes an id and name copies an existing campaign identified by id and returns the new id.  original name will be reused if name is ommitted.

=item $mnb->CampaignDelete( int $id )

takes an id and deletes campaign idenified by that id. returns 1 on success and 0 on failure.

=item $mnb->CampaignSchedule( int $id, string $when, \@lists, bool $smart, bool $confirmed )

schedules a Campaign for sending based on arguments:

    int $id -- campaign id to send
    datetime $when -- date/time to send this can be in any format readable by PHP's strtotime() function and will be EST.
    array @lists -- flat array of list id's the campaign should go out to
    bool $smart -- 0(default) disables smart send 1 enables it. see http://help.mynewsletterbuilder.com/Help_Pop-up_for_Newsletter_Scheduler
    bool $confirmed -- 0(default) sends to all subscribers 1 sends to only confirmed

returns 0 on failure and 1 on success.

=item $mnb->CampaignStats( int $id )

takes a campaign id and returns stats for that campaign. returned hahsref has the following keys:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id for campaign
   clicks                  number of clicks
   clicks_unique           number of unique clicks
   forwards                number of forwards
   forwards_unique         number of unique forwards
   opens                   number of opens
   opens_unique            number of unique opens
   recipients              number of recipients
   bounces                 number of bounces
   delivered               number delivered
   complaints              number of complaints
   subscribes              number of subscribes
   unsubscribes            number of unsubscribes
   sent_on                 date and time campaign sent ('2010-03-04 01:30:47' EST)
   first_open              date and time of first open ('2010-03-04 01:30:47' EST)
   last_open               date and time of last open ('2010-03-04 01:30:47' EST)
   archived                1 if archived 0 if not

=item $mnb->CampaignRecipients( int $id, int $page, int $limit)

takes a campaign id, an optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber
   processed               when campaign was sent to subscriber ('2010-03-04 01:30:47' EST)

=item $mnb->CampaignOpens( int $id, int $page, int $limit)

takes a campaign id, an optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers who have opened the campaign in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber
   count                   number of opens
   first_open              date and time subscriber first opened campaign ('2010-03-04 01:30:47' EST)
   last_open               date and time subscriber last opened campaign ('2010-03-04 01:30:47' EST)

=item $mnb->CampaignBounces( int $id, int $page, int $limit)

takes a campaign id, an optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers who bounced in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber
   processed               when mnb processed bounce from subscriber ('2010-03-04 01:30:47' EST)

=item $mnb->CampaignClicks( int $id, int $page, int $limit)

takes a campaign id, an optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers who clicked links in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber

=item $mnb->CampaignClickDetails( int $id, int $url_id, int $page, int $limit)

takes a campaign id, url id and optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers who clicked links in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber
   count                   number of times subscriber clicked link
   url_id                  url id of link clicked

=item $mnb->CampaignSubscribes( int $id, int $page, int $limit)

takes a campaign id, an optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers who subscribed based on this campaign in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber
   processed               when subscriber was processed

=item $mnb->CampaignUnsubscribes( int $id, int $page, int $limit)

takes a campaign id, an optional page number and limit (for paging systems on large data sets) and returns an arrayref of hashrefs containing data about subscribers who unsubscribed in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of subscriber
   email                   email address of subscriber
   processed               when subscriber was processed

=item $mnb->CampaignUrls( int $id )

takes a campaign id and returns an arrayref of hashrefs with link related data in the format:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id of url
   link                    FQDN for link
   unique                  number of unique clicks
   total                   number of total clicks
   title                   text within link (can include html including img tags)

=back

=head3 Subscriber Lists

=over 4

=item $mnb->Lists()

returns an arrayref of hasrefs of subscriber lists with the following keys:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      numeric id for list
   name                    list name
   description             list description
   visible                 1 if visible 0 if not
   default                 1 if default 0 if not
   subscribers             number of subscribers in list

=item $mnb->ListDetails( int $id )

takes a list id and returns details about that list in a hashref with the following keys:

   KEY                     DESCRIPTION
   ___________             ____________________
   id                      list id
   name                    list name
   description             list description
   visible                 1 if list is visible 0 if not
   default                 1 if list is a default selection on your subscription form
   subscribers             total number of subscribers in the list

=item $mnb->ListCreate( string $name, string $description, bool $visible, bool $default )

takes several arguments, creates a new subscriber list and returns it's unique id. arguments:

    string $name -- name for new list
    string $description -- description for new list
    bool $visible -- 1 if list is visible 0(default) if not
    bool $default -- 1 if list is default 0(default) if not

=item $mnb->ListUpdate( int $id, \%details )

takes an id and a hashref of details (only id is required though we won't actually do anything without something in the details hashref), updates the subscriber list identified by id and returns 1 on success and 0 on failure.

details hashref format:

   KEY                     DESCRIPTION
   ___________             ____________________
   name                    new name for list
   description             new description for list
   visible                 1 if list is visible 0(default) if not
   default                 1 if list is default 0(default) if not

=item $mnb->ListDelete( int $id, bool $delete_subs )

deletes the list identified by id.  if $delete_subs is 1 all subscribers in list are deleted as well.  if delete_subs is 0(default) we don't touch subscribers.  returns 1 on success and 0 on failure.

=back

=head3 Subscribers

=over 4

=item $mnb->Subscribe( \%details, \@lists, bool $skip_opt_in, bool $update_existing )

sets up a single subscriber based on %details. if @lists is populated it OVERRIDES a current users current set of lists.  if it is empty no changes are made to existing users.  skip_opt_in is used to enable confirmation email (default is 0). update_existing is used to specify that you want %details to overrid an existing user's info.  it will NOT be applied to lists.  if lists is populated an existing user's lists WILL be overridden even with the update_existing flag set. it defaults to true.

%details is a hashref with the following format:

   KEY                             DESCRIPTION
   ___________                     ____________________
   email                           subscriber email address(required)
   first_name                      subscriber first name
   middle_name                     subscriber middle name
   last_name                       subscriber last name
   full_name                       subscriber full name (yes this is a distinct field)
   company_name                    subscriber company name
   job_title                       subscribers job title
   phone_work                      subscriber work phone
   phone_home                      subscriber home phone
   address_1                       first line of address
   address_2                       second line of address
   address_3                       third line of address
   city                            city of address
   state                           state of address
   zip                             postal code
   country                         country part of address

   custom field names              custom field values

custom fields can be set by using their full name as the key and their value as the value... again this can lead to keys with spaces.

Subscribe() returns a hashref with the following keys:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              subscriber's unique id
   email                           subscriber's uniqe email
   status                          status of subscription.  possible values are new, updated, error, ignored
   status_msg                      contains text message about update... usually only used for errors

=item $mnb->SubscribeBatch( \@subscribers, \@lists, bool $skip_opt_in, bool $update_existing )

sets up multiple subscriber based on @subscribers which is an array of hashrefs. if @lists is populated it OVERRIDES any current users set of lists.  if it is empty no changes are made to existing users.  skip_opt_in is used to enable confirmation email (default is 0). update_existing is used to specify that you want %details to overrid an existing user's info.  it will NOT be applied to lists.  if lists is populated an existing user's lists WILL be overridden even with the update_existing flag set. it defaults to true.

@subscribers is an array of hashrefs with the following format:

   KEY                             DESCRIPTION
   ___________                     ____________________
   email                           subscriber email address
   first_name                      subscriber first name
   middle_name                     subscriber middle name
   last_name                       subscriber last name
   company_name                    subscriber company name
   job_title                       subscribers job title
   phone_work                      subscriber work phone
   phone_home                      subscriber home phone
   address_1                       first line of address
   address_2                       second line of address
   address_3                       third line of address
   city                            city of address
   state                           state of address
   zip                             postal code
   country                         country part of address

   custom field names              custom field values

custom fields can be set by using their full name as the key and their value as the value... again this can lead to keys with spaces.

SubscribeBatch() returns a hashref with the following keys:

	KEY                             DESCRIPTION
   ___________                     ____________________
   meta                            contains a hashref with overview info described below
   subscribers                     contains an array of hashrefs described below. this will match the order of the @subscribers array you submitted

the meta key of the return from SubscribeBatch() contains a hashref with the following keys:

   KEY                             DESCRIPTION
   ___________                     ____________________
   total                           total count of attempted subscribes
   success                         total count of successful subscribes
   errors                          total count of subscribes with errors

the subscribers key of the return from SubscribeBatch() contains an array of hashrefs with the following keys:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              subscriber's unique id
   email                           subscriber's uniqe email
   status                          status of subscription.  possible values are new, updated, error, ignored
   status_msg                      contains text message about update... usually only used for errors

=item $mnb->Subscribers( @statuses, @lists, int $page, int $limit )

takes arrays of statuses and list ids to filter by, an optional page number and limit (for paging systems on large data sets). returns an array of subscriber data.

options for statuses are active, unsubscribed, deleted.

return is a keyed array with the following keys:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              subscriber's unique id
   email                           subscriber's uniqe email
   status                          status of subscriber.  possible values are active, unsubscribed or deleted

=item $mnb->SubscriberDetails( string $id_or_email )

takes an argument that can be either the unique id for the subscriber or an email address and returns a hashref of subscriber data in the following format:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              numeric id for subscriber
   email                           subscriber email address
   full_name                       subscriber full name
   first_name                      subscriber first name
   middle_name                     subscriber middle name
   last_name                       subscriber last name
   company_name                    subscriber company name
   job_title                       subscribers job title
   phone_work                      subscriber work phone
   phone_home                      subscriber home phone
   address_1                       first line of address
   address_2                       second line of address
   address_3                       third line of address
   city                            city of address
   state                           state of address
   zip                             postal code
   country                         country part of address (may be improperly formatted)
   campaign_id                     if subscriber subscribed from a campaign it's id is here
   lists                           contains a flat array containing the lists the user is in
   last_confirmation_request       last time we sent a confirmation to the user
   confirmed_date                  date subscriber confirmed
   confirmed_from                  ip address user confirmed from
   add_remove_date                 date subscriber status changed
   status                          current status possible values: active, unsubscribed, deleted, list_too_small
   add_method                      who last updated the user possible values: U - user added, S - added self, A - Admin added, C - added by complaint system, B - added by bounce management system
   confirmed                       status of confirmation (confirmed, unconfirmed, pending)

   custom field names              custom field values

custom fields will come back in this hashref with their names as keys and their values as the value.  this means there is a possiblity that keys will have spaces in them.  sorry.

=item $mnb->SubscriberUpdate( string $id_or_email, \%details, \@lists )

takes an argument that can be either the unique id for the subscriber or an email address and updates a subscribers info and lists based on details hashref and lists arrayref. if @lists is empty NO CHANGES ARE MADE TO A USERS LISTS.  use SubscriberDelete or SubscriberUnsubscribe to remove a subscriber from all lists.

%details is a hashref with the following format:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              numeric id for subscriber
   email                           subscriber email address
   full_name                       subscriber full name
   first_name                      subscriber first name
   middle_name                     subscriber middle name
   last_name                       subscriber last name
   company_name                    subscriber company name
   job_title                       subscribers job title
   phone_work                      subscriber work phone
   phone_home                      subscriber home phone
   address_1                       first line of address
   address_2                       second line of address
   address_3                       third line of address
   city                            city of address
   state                           state of address
   zip                             postal code
   country                         country part of address

   custom field names              custom field values

custom fields can be set by using their full name as the key and their value as the value... again this can lead to keys with spaces.

=item $mnb->SubscriberUnsubscribe( string $id_or_email )

takes an argument that can be either the unique id for the subscriber or an email address and permanantly removes that subscriber for the user identified by your api_key.  this subscribers will NOT be able to be readded by SubscribeBatch().

returns 1 on success and 0 on failure.

=item $mnb->SubscriberUnsubscribeBatch( \@ids_or_emails )

takes an argument that is an array containing either the unique ids for the subscriber or an email address and permanantly removes those subscribesr for the user identified by your api_key.  these subscribers will NOT be able to be readded by SubscribeBatch().

returns 1 on success and 0 on failure.

=item $mnb->SubscriberDelete( string $id_or_email )

takes an argument that can be either the unique id for the subscriber or an email address and removes that subscriber for the user identified by your api_key.  this subscriber WILL be readded if their email address is re-submitted to Subscribe() or SubscribeBatch().

returns 1 on success and 0 on failure.

=item $mnb->SubscriberDeleteBatch( \@ids_or_emails )

takes an argument that is an array containing either the unique id for subscribers or an email addresss and removes the subscribers for the user identified by your api_key. these subscribers WILL be readded if their email addresses are re-submitted to Subscribe() or SubscribeBatch().

returns 1 on success and 0 on failure.

=back

=head3 Account Administration

=over 4

=item $mnb->AccountKeys( string $username, string $password, bool $disabled)

takes the user's username and password and returns data on available api keys.  if $disabled(default 0) is 1 list will include disabled keys.

return is an array of hashrefs with the following keys:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              unique numeric id of key
   key                             unique key string
   created                         date key created
   expired                         date key expired or was disabled (null for valid key)

=item $mnb->AccountKeyCreate( string $username, string $password )

takes the user's username and password creates a key and returns data about created key.  return is a hashref with the following keys:

   KEY                             DESCRIPTION
   ___________                     ____________________
   id                              unique numeric id of key
   key                             unique key string
   create                          date key created
   expired                         date key expired or was disabled (null for valid key)

=item $mnb->AccountKeyEnable( string $username, string $password, string $id_or_key )

takes the user's username and password and an id or existing key it enables the referenced key and returns 1 on success and an error on failure.

=item $mnb->AccountKeyDisable( string $username, string $password, string $id_or_key )

takes the user's username and password and an id or existing key it disables the referenced key and returns 1 on success and an error on failure.

=back

=head3 Testing

=over 4

=item $mnb->HelloWorld( string $value )

takes a value and echos it back from the API server.

=back

=head2 Errors

By default we validate your data before sending to the server.  If validation fails we issue die() with a relevant error message.  You can force us to warn instead of dying by passing no_validation => 1 to new().

Server side errors will cause functions to return 0.  They will also populate $mnb->{errno} and $mnb->{errstr}.  You should probably check $mnb->{errno} after calling any function.  Fatal errors within the underlying Frontier::Client module may be caught by the same mechinism that catches server side exceptions.  You REALLY need to check for errors after ever call.

=head2 Requirements

Frontier::Client
Data::Dumper

=head1 See Also

http://api.mynewsletterbuilder.com

=head1 Author

Robert Davis, robert@jbanetwork.com

=head1 Copyright And License

Copyright (C) 2010 by JBA Network (http://www.jbanetwork.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
