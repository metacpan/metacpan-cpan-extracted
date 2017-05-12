package WebService::Validator::HTML::W3C::Fast;

use strict;
use warnings;
use WebService::Validator::HTML::W3C();
use HTTP::Daemon();
use Fcntl();
use File::Temp();
use Symbol();
use LWP::UserAgent();
use MIME::Base64();
use POSIX();
use base qw(WebService::Validator::HTML::W3C);

our $VERSION = '0.02';
our ($maximum_fork_attempts) = 4;

=head1 NAME

WebService::Validator::HTML::W3C::Fast - Access the W3Cs online HTML validator in a local persistent daemon

=head1 SYNOPSIS

    use WebService::Validator::HTML::W3C::Fast;

    my $v = WebService::Validator::HTML::W3C::Fast->new(
                validator_path         => '/path/to/validator/check',
		user                   => $username,
		password               => $password,
		auto_launder_validator => 1,
            );

    if ( $v->validate_markup(<<_HTML_) ) {
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head><title></title></head><body></body></html>
_HTML_
        if ( $v->is_valid ) {
            printf ("%s is valid\n", $v->uri);
        } else {
            printf ("%s is not valid\n", $v->uri);
            foreach my $error ( @{$v->errors} ) {
                printf("%s at line %d\n", $error->msg,
                                          $error->line);
            }
        }
    } else {
        printf ("Failed to validate the supplied markup: %s\n", $v->validator_error);
    }

=head1 DESCRIPTION

WebService::Validator::HTML::W3C::Fast provides access a local version of 
the W3C's Markup validator, via WebService::Validator::HTML::W3C.  It loads up
a small HTTP::Daemon daemon, listening on a random high port on 127.0.0.1 and 
loads the check cgi script into a mod_perl type persistent environment for speedy 
checking of lots of documents.

When running under taint-mode you will need to provide the auto_launder_validator
argument, otherwise taint will refuse to allow the module to string eval the cgi script.

To discourage denial of service attacks, the local web server is protected via http 
basic auth.  You can specify the desired user name and password for the server, or it
will use srand and rand to generate a simple password.

if validator_path is not supplied, the validator will attempt to guess at where the script 
is, first looking at '/usr/share/w3c-markup-validator/cgi-bin/check', which is the location of 
the cgi script used by fedora's w3c-markup-validator package.  If this fails and no-one 
supplies defaults that other operating systems use, the validator will croak().

NOTE for debian.  At the moment, debian's version of the check script depends on using the
open3 function for /usr/bin/onsgmls.  I'm done a quick check on this and am not intending
to port to debian, rather, i intend to wait for debian to upgrade their source.  If anyone
would like to fix this, i would be happy to apply supplied patches.

The local HTTP::Daemon will occansionally check that the parent program is still present.
If the parent ever exits, the HTTP::Daemon will terminate as well. This is to prevent a
build up of HTTP::Daemons listening on high ports b/c a test script was aborted.

=head1 SEE ALSO

=head1 AUTHOR

David Dick, E<lt>ddick@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Dick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

sub default_script_paths {
	return ('/usr/share/w3c-markup-validator/cgi-bin/check');
}

sub new {
	my ($class, %params) = @_;
	if ($params{validator_uri}) {
		Carp::croak("The validator uri cannot be used here");
	}
	my (@default_script_paths) = default_script_paths();
	my ($validator_path) = $params{validator_path} || shift @default_script_paths;
	my ($handle) = Symbol::gensym();
	while (not(sysopen($handle, $validator_path, Fcntl::O_RDONLY()))) {
		if (($^E == POSIX::ENOENT()) && (not($params{validator_path})) && (@default_script_paths)) {
			$validator_path = shift @default_script_paths;
		} elsif ($params{validator_path}) {
			Carp::croak("Failed to open '$params{validator_path}' for reading:$^E")
		} elsif (($^E == POSIX::ENOENT()) && (not($params{validator_path}))) {
			Carp::croak("Please specify the location of the w3c markup validator on the filesystem")
		} else {
			Carp::croak("Failed to open '$validator_path' for reading:$^E");
		}
	}
	delete $params{validator_path};
	my ($validator_source);
	my ($result, $buffer);
	while($result = read($handle, $buffer, 4096)) {
		$validator_source .= $buffer;
	}
	unless (defined $result) {
		Carp::croak("Failed to read from '$validator_path':$^E");
	}
	unless (close($handle)) {
		Carp::croak("Failed to close '$validator_path':$^E");
	}
	$validator_source =~ s/exit/return/g;
	if ($params{auto_launder_validator}) {
		if ($validator_source =~ /^(.*)$/s) {
			($validator_source) = ($1);
		}
	}
	eval <<_HANDLER_;
sub handler {
	my (\$connection) = \@_;
	\$connection->send_status_line();
$validator_source
}
_HANDLER_
	if ($@) {
		die($@);
	}
	my ($daemon) = HTTP::Daemon->new( 'LocalAddr' => '127.0.0.1', 'Blocking' => 0 );
	my ($self) = WebService::Validator::HTML::W3C->new( 'validator_uri' => $daemon->url(), %params );
	bless $self, $class;
	my ($user, $password) = $self->_set_user_password(\%params);
	my ($parent_pid) = $$;
	my ($number_of_fork_attempts) = 0;
	FORK: {
		if (my $pid = fork()) {
			$self->{_internal_http_server_pid} = $pid;
			return $self;
		} elsif (defined $pid) {
			my ($terminated) = 0;
			eval {
				$self = undef;
				local $SIG{TERM} = sub { $terminated = 1; die("Caught a terminate signal\n"); };
				local $SIG{INT} = sub { die("Caught an interrupt signal\n"); };
				CHECKING: {
					while(my $connection = $daemon->accept()) {
						my $request = $connection->get_request(1);
						unless (check_authorisation($request, $user, $password)) {
							die("Client did not authorise correctly\n");
						}
						local %ENV = setup_environment_hash($request);
						local *STDIN = setup_stdin($connection);
						local *STDOUT = *{$connection};
						CGI::initialize_globals();
						handler($connection);
						unless (close($connection)) {
							die("Failed to close client socket:$^E");
						}
					}
					if ($^E == POSIX::EWOULDBLOCK()) {
						if (kill(0, $parent_pid)) {
							my ($rin) = '';
							vec($rin,fileno($daemon),1) = 1;
							select($rin, undef, undef, 5); # wait for 5 seconds before checking parent is still alive or for input
							redo CHECKING;
						}
					} else {
						die("Failed to accept a new connection:$^E");
					}
				}
			};
			if ($terminated) {
				CORE::exit(0);
			} elsif ($@) {
				print STDERR $@;
				CORE::exit(1);
			} else {
				CORE::exit(0);
			}
		} elsif (($^E == POSIX::EAGAIN()) && ($number_of_fork_attempts < $maximum_fork_attempts)) {
			$number_of_fork_attempts += 1;
			sleep 5;
			redo FORK;
		} else {
			die("Failed to fork:$^E");
		}
	}
}

sub setup_stdin {
	my ($connection) = @_;
	my $temp_input = File::Temp::tempfile();
	unless ($temp_input) {
		die("Failed to open a temporary file for writing:$^E");
	}
	my ($buffer) = $connection->read_buffer();
	my ($remaining_length) = $ENV{CONTENT_LENGTH} - length($buffer);
	unless ($temp_input->print($buffer)) {
		die("Failed to write to temporary file:$^E");
	}
	while ($remaining_length > 0) {
		my ($result) = $connection->sysread($buffer, 32*1024);
		if (defined $result) {
			$remaining_length -= $result;
			if ($result == 0) {
				die("Client did not provide enough data");
			} else {
				unless ($temp_input->print($buffer)) {
					die("Failed to write to temporary file:$^E");
				}
			}
		} else {
			die("Client closed connection:$^E");
		}
	}
	unless ($temp_input->seek(0, Fcntl::SEEK_SET())) {
		die("Failed to seek to start of temporary file:$^E");
	}
	return *{$temp_input};
}

sub check_authorisation {
	my ($request, $user, $password) = @_;
	my ($authorised) = 0;
	my ($auth) = $request->header('Authorization');
	if ($auth =~ s/^Basic //) {
		my ($decoded) = MIME::Base64::decode_base64($auth);
		if ($decoded =~ s/^$user://) {	
			if ($decoded eq $password) {
				$authorised = 1;
			}
		}
	}
	return $authorised;
}

sub setup_environment_hash {
	my ($request) = @_;
	my (%local_env); 
	$local_env{REQUEST_METHOD} = $request->method();
	$local_env{REQUEST_URI} = $request->uri()->as_string();
	$local_env{HTTP_USER_AGENT} = $request->header('User_Agent');
	my ($length) = $request->header('Content_Length');
	if ($length) {
		$local_env{CONTENT_LENGTH} = $length;
	}
	my ($contentType) = $request->header('Content_Type');
	if ($contentType) {
		$local_env{CONTENT_TYPE} = $contentType;
	}
	return (%local_env);
}

sub _set_user_password {
	my ($self, $params) = @_;
	my ($ua) = $self->ua(); # Allow SUPER to create a ua if desired
	unless ($ua) {
		$ua = LWP::UserAgent->new( 'agent' => __PACKAGE__ . "/$VERSION" );
	}
	my ($headers) = $ua->default_headers() || HTTP::Headers->new();
	$headers->header('User_Agent' => $ua->agent());
	my ($header_user, $header_pass) = $headers->authorization_basic();
	my ($user) = $params->{user} || $header_user || 'Validator';
	my ($password) = $params->{password} || $header_pass || '';
	unless ($password) {
		srand();
		while(length($password) < 45) {
			$password .= chr(int(rand(57)) + 65);
		}
	}
	$headers->authorization_basic($user, $password);
	$ua->default_headers($headers);
	$self->ua($ua);
	return ($user, $password);
}

sub DESTROY {
	my ($self) = @_;
	if ((exists $self->{_internal_http_server_pid}) && ($self->{_internal_http_server_pid})) {
		kill("TERM", $self->{_internal_http_server_pid});
	}
}

1;
