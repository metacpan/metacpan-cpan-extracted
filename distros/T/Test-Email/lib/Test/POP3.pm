package Test::POP3;
use strict;
use warnings;

use Test::Builder;
use Mail::POP3Client;
use Test::Email;
use MIME::Parser;
use Carp 'croak';

our $VERSION = '0.05';

my $TEST = Test::Builder->new();

my $DEBUG = 0;

sub new {
    my ($class, $params_href) = @_;

    my $self = bless {
	_connected	=>	0,
	_host		=>	$params_href->{host},
	_user		=>	$params_href->{user},
	_pass		=>	$params_href->{pass},
	_emails_href	=>	{},
	_email_id	=>	1,
    }, $class;

    return unless $self->_connect();
    return $self;
}

sub ok {
    my ($self, $test_href, $desc) = @_;

    my $pass = $self->_run_tests($test_href);
    
    my $ok = $TEST->ok($pass, $desc);

    return $ok;
}

# return the number of emails deleted
sub delete_all {
    my $self = shift;
    
    # download the messages from the server
    $self->_download_messages();

    # count the number of emails
    my $count = keys %{$self->{_emails_href}};

    # delete the messages
    $self->{_emails_href} = {};

    return $count;
}

# this deletes email from the cache
sub get_email {
    my $self = shift;

    my @email = values %{ $self->{_emails_href} };

    $self->{_emails_href} = {};

    return @email;
}

# arg: should we check the server? default: no
sub get_email_count {
    my $self = shift;
    my $check_server = shift;

    if ($check_server) {
    	$self->_download_messages();
    }

    return scalar keys %{ $self->{_emails_href} };
}

# return the number of messages found
sub wait_for_email_count {
    my ($self, $looking_for_count, $timeout) = @_;
    $timeout ||= 30;

    my $start = time;
    _debug("start: $start");

    my $i = 0;
    while ($start + $timeout > time) {
	_debug('in loop');

	my $email_count = $self->get_email_count(1); # check the server
	_debug("email count: '$email_count'");

	if ($email_count >= $looking_for_count) {
	    _debug('returning');
	    return $email_count;
	}

	if ($start + $timeout > time) {
	    _debug('sleeping');
	    sleep 1;
	}
    }

    _debug("after loop($start + $timeout): @{[time]}");

    return $self->get_email_count(0); # don't check the server again
}

# run all tests against all emails, return success
sub _run_tests {
    my ($self, $test_href) = @_;
    
    # only check already-downloaded messages
    for my $email_id (keys %{ $self->{_emails_href} }) {
	my $email = $self->{_emails_href}->{$email_id};

        my $passed = $email->_run_tests($test_href);
        next unless $passed;

	# this email passed the tests, delete it
	my $subject = $email->head()->get('subject');
	_debug("Deleting passed email message: $subject");

	delete $self->{_emails_href}->{$email_id};
	return 1;
    }

    return; # no emails passed all tests
}

sub _debug {
    my ($msg) = @_;
    warn $msg."\n" if $DEBUG;
}

sub _connect {
    my $self = shift;

    _debug("about to connect");

    return if $self->{_connected};

    _debug("connecting");

    my $host = $self->{_host}  || croak "I need a host";
    my $user = $self->{_user}  || croak "I need a user";
    my $pass = $self->{_pass}  || croak "I need a pass";

    $self->{_pop3} = Mail::POP3Client->new(
	HOST		=>	$host,
	USER		=>	$user,
	PASSWORD	=>	$pass,
	DEBUG		=>	$DEBUG,
	AUTH_MODE	=>	'PASS',
    )	or warn "failed to connect to '$host'"
	and return;

    return $self->{_connected} = 1;
}

sub _disconnect {
    my $self = shift;

    _debug("disconnecting");

    if ($self->{_connected}) {
	$self->_pop3()->Close();
    }

    $self->{_connected} = 0;

    return 1;
}

sub DESTROY {
    shift()->_disconnect();
}

sub _pop3 {
    return shift()->{_pop3};
}

# download the messages and store them locally
# try once
# return the number downloaded
sub _download_messages {
    my $self = shift;
    
    _debug('downloading');

    $self->_connect();

    my $pop3   = $self->_pop3();
    my $parser = $self->get_parser();

    my $msg_count = $self->_pop3()->Count();
    for my $msgnum (1..$msg_count) {
        # create local unique id
	my $id = $self->{_email_id}++;

        # get the message as a string, create Test::Email
	my $msg = $pop3->HeadAndBody($msgnum);
	my $entity = $parser->parse_data($msg);

        # store in $self
        $self->{_emails_href}->{$id} = $entity;

        # delete from server
        $pop3->Delete($msgnum);
    }

    $self->_disconnect();

    _debug("returning found msg count: '$msg_count'");
    return $msg_count;
}

sub get_parser {
    my $self = shift;

    if (! exists $self->{_parser}) {
        my $parser = MIME::Parser->new();
        $parser->interface(ENTITY_CLASS => 'Test::Email');
	$self->{_parser} = $parser;
    }

    return $self->{_parser};
}

1;
__END__

=head1 NAME

Test::POP3 - Automate Email Delivery Tests

=head1 SYNOPSIS

  use Test::POP3;

  my $pop = Test::POP3->new({
  	host => $host,
  	user => $user,
  	pass => $pass,
  });
  
  # this will delete all messages from the server!
  ok($count == $pop->wait_for_email_count($count,$timeout),"got $count");

  # find and delete a single email message which matches these rules
  # see Test::Email for more information
  $pop->ok({
    # optional search parameters
    to         => ($is or qr/is like/),
    from       => ($is or qr/is like/),
    subject    => ($is or qr/is like/),
    body       => ($is or qr/is like/),
    headername => ($is or qr/is like/),
  }, "got message");

  ok($pop->get_email_count() == $count, "$count emails in cache");

  # get the Test::Email object
  my @email = $pop->get_email();

  ok($pop->delete_all() == 2, "deleted 2 messages");

  # tweak MIME::Parser settings
  my $parser = $pop->get_parser();

=head1 DESCRIPTION

Please note that this is ALPHA CODE. As such, the interface is likely to
change.

This module can help you to create automated tests of email 
delivered to a POP3 account.

Messages retrieved from the server but not yet matched by a test will
be cached until either that message is the first to pass a test, or is
returned by C<$pop3-E<gt>get_email()>. Messages returned are L<Test::Email>
objects.

=head1 METHODS

=over

=item C<my $pop = Test::Email-E<gt>new($href);>

The arguments passed in the href are host, user, and pass.

=item C<my $count = $pop-E<gt>wait_for_email_count($count, $timeout_seconds?);>

B<Calling this method will result in all messages being deleted from the server.>
This will wait up to $timeout seconds for there to be $count unprocessed
messages found on the server. After $count or more messages are found,
or after $timeout seconds, the current email count will be returned. $timeout_seconds
defaults to 30. B<All messages will be deleted from the server.>

=item C<my @email = $pop-E<gt>get_email();>

Get all of the email messages currently in local cache. You should call
C<$pop3-E<gt>wait_for_email_count($count)> before calling this method if
you think that there may be messages on the server yet to be retrieved.
Calling this method will cause the local cache to be emptied. Email messages
returned will be L<Test::Email> objects.

=item C<my $count = $pop-E<gt>get_email_count($check_server);>

This will return the number of email messages in the cache. If C<$check_server>
is true, then the server will be checked once before the count is determined.
If you would like to wait for messages to arrive on the server, and then be
downloaded prior to counting, use C<$pop3-E<gt>wait_for_email_count()>.

=item C<my $ok = $pop-E<gt>ok($test_href, $description);>

Calling this method will cause the email in the local cache to be tested,
according to the contents of C<$test_href>. The first email which passes
all tests will be deleted from the local cache. Since this method only checks
the local cache, you will want to call C<$pop3-E<gt>wait_for_email_count()>
before calling this method. C<ok> will produce TAP output, identical to
C<Test::Simple::ok> and C<Test::More::ok>.

=item C<my $parser = $pop-E<gt>get_parser();>

L<Test::POP3> uses L<MIME::Parser> to process the messages. (MIME is not yet
handled by C<Test::Email>, it will be soon.) Use this method if you want to
manage the parser.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<Test::Builder>, L<Test::Simple>, L<Test::More>, L<MIME::Parser>

=head1 AUTHOR

James Tolley, L<E<lt>james@cpan.orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by James Tolley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
