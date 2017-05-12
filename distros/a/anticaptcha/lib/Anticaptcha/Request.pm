package Anticaptcha::Request;

use strict;
use vars qw(@ISA $VERSION);
require Exporter;
use Exporter;
@ISA = ('Exporter');

$VERSION = "1.02";
require 5.010;

use JSON ();
use LWP ();

use Anticaptcha ();

use Carp ();

sub new
{
	# Check for common user mistake
	Carp::croak("Options to Anticaptcha::Request should be key/value pairs, not hash reference") 
		if ref($_[1]) eq 'HASH';

	my($class, %config) = @_;

	my $clientKey = delete $config{clientKey} || undef;
	Carp::croak("clientKey option is required") 
		if !$clientKey;

	my $self = bless {
		clientKey => $clientKey,
		responce => delete $config{responce} || 'hash'
	}, $class;
	$self->{BROWSER} = LWP::UserAgent->new(
		ssl_opts => {
			SSL_verify_mode => 0,
			verify_hostname => 0
		}
	);

	return $self;
}

sub createTask{
	my($self, $request) = @_;
	my $req = $request;
	$req->{clientKey} = $self->{clientKey};
	my $json = JSON::encode_json($req);

	my $res = $self->request({
		task => 'createTask',
		data => $json
	});
	if($self->{responce} eq 'json'){
		return $res;
	}else{
		return JSON::decode_json($res);
	}
}

sub getBalance{
	my($self) = @_;
	my $json = JSON::encode_json({clientKey => $self->{clientKey}});

	my $res = $self->request({
		task => 'getBalance',
		data => $json
	});
	if($self->{responce} eq 'json'){
		return $res;
	}else{
		return JSON::decode_json($res);
	}
}

sub getQueueStats{
	my($self, $request) = @_;

	my $res = $self->request({
		task => 'getQueueStats',
		data => JSON::encode_json({queueId => ($request->{queueId} || 1)})
	});
	if($self->{responce} eq 'json'){
		return $res;
	}else{
		return JSON::decode_json($res);
	}
}

sub getTaskResult{
	my($self, $request) = @_;
	my $req;
	$req->{clientKey} = $self->{clientKey};
	$req->{taskId} = $request->{taskId};
	my $json = JSON::encode_json($req);

	my $res = $self->request({
		task => 'getTaskResult',
		data => $json
	});
	if($self->{responce} eq 'json'){
		return $res;
	}else{
		return JSON::decode_json($res);
	}
}

sub request{
	my($self, $request) = @_;

	my $req = HTTP::Request->new(POST => 'https://api.anti-captcha.com/'.$request->{task});
	$req->content_type('application/json');
	$req->content($request->{data});
	my $res = $self->{BROWSER}->request($req);
	if($res->is_success){
		return $res->content;
	}else{
		return '{"errorId":999,"status":"HTTP ERROR '.$res->status_line.'"}';
	}
}

1;

__END__

=head1 NAME

Anticaptcha::Request - API requests

=head1 SYNOPSIS

  use Anticaptcha::Request;
  my $Anticaptcha = Anticaptcha::Request->new(
    clientKey => '123abc123abc123abc112abc123abc123',
    responce => 'json'
  );

  my $balance_json = $Anticaptcha->getBalance();
  print $balance_json,"\n";

  my $stat_json = $Anticaptcha->getQueueStats({queueId => 1});
  print $stat_json,"\n";

or

  use Anticaptcha::Request;
  my $Anticaptcha = Anticaptcha::Request->new(
    clientKey => '123abc123abc123abc112abc123abc123'
  );

  my $balance = $Anticaptcha->getBalance();
  if($balance->{errorId} == 0){
    print $balance->{balance},"\n";
  }else{
    print "Error gettting balance: ",$balance->{errorDescription},"\n";
  }

=head1 CONSTRUCTOR METHOD

=over 3

=item $Anticaptcha = Anticaptcha::Request->new( %options )

The following options correspond to attribute methods described below:

  KEY                   DEFAULT               REQUIRED
  -----------           -----------           -----------
  clientKey             undef                 YES
  responce              'hash'

=item C<clientKey> - string with client key.
 
=item C<responce> - string with type of methods responce. Valid values:

  'json' - methods returns string in JSON format,

  'hash' - methods returns JSON decoded hash structure.

=back

=head1 METHODS

=over

=item $Anticaptcha->createTask( %options )

Method for creating a task. See API documentation: https://anticaptcha.atlassian.net/wiki/display/API/createTask+%3A+captcha+task+creating

Options:

  KEY                   DEFAULT               REQUIRED
  -----------           -----------           -----------
  task                  undef                 YES
  softId                undef
  languagePool          undef

=item C<task> - hash structure with task data.
 
=item C<softId>, C<languagePool> - additional parameters.

Example:

  my $task = $Anticaptcha->createTask({
    task => {
      type => 'NoCaptchaTask',
      websiteURL => 'https://SiteWithCaptcha.com/page.html',
      websiteKey => 'See API documentation',
      proxyType => 'http',
      proxyAddress => '192.168.1.1',
      proxyPort => 1212,
      userAgent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6)'
    },
    languagePool => 'en'
  });

=item $Anticaptcha->getBalance()

Method for retrieve account balance. See API documentation: https://anticaptcha.atlassian.net/wiki/display/API/getBalance+%3A+retrieve+account+balance

No options available for this method.

Example:

  my $balance = $Anticaptcha->getBalance();

=item $Anticaptcha->getQueueStats( %options )

Method for obtain queue load statistics. See API documentation: https://anticaptcha.atlassian.net/wiki/display/API/getQueueStats+%3A+obtain+queue+load+statistics

Options:

  KEY                   DEFAULT               REQUIRED
  -----------           -----------           -----------
  queueId               1                     YES

=item C<queueId> - Id of the queue. Valid values: 1, 2, 3, 4, 5

Example:

  my $stat = $Anticaptcha->getQueueStats({queueId => 2});
  print $stat,"\n";

=item $Anticaptcha->getTaskResult( %options )

Method for request task result. See API documentation: https://anticaptcha.atlassian.net/wiki/display/API/getTaskResult+%3A+request+task+result

Options:

  KEY                   DEFAULT               REQUIRED
  -----------           -----------           -----------
  taskId                undef                 YES

=item C<taskId> - ID which was obtained in createTask method.

Example:

  my $result = $Anticaptcha->getTaskResult({taskId => $taskId});
  print $result,"\n";

=back

=head1 COPYRIGHT

  Copyright 2016, Alexander Mironov

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
