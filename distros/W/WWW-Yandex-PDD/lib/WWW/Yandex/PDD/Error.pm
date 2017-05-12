package WWW::Yandex::PDD::Error;

use strict;
use warnings;

use base "Exporter";

use constant {
	HTTP_ERROR          => 'HTTP_ERROR',

	NOT_AUTHENTICATED   => 'NOT_AUTHENTICATED',
	INVALID_RESPONSE    => 'INVALID_RESPONSE',
	REQUEST_FAILED      => 'REQUEST_FAILED',

	USER_NOT_FOUND      => 'USER_NOT_FOUND',
	LOGIN_OCCUPIED      => 'LOGIN_OCCUPIED',
	LOGIN_TOO_SHORT     => 'LOGIN_TOO_SHORT',
	LOGIN_TOO_LONG      => 'LOGIN_TOO_LONG',
	INVALID_LOGIN       => 'INVALID_LOGIN',

	INVALID_PASSWORD    => 'INVALID_PASSWORD',
	PASSWORD_TOO_SHORT  => 'PASSWORD_TOO_SHORT',
	PASSWORD_TOO_LONG   => 'PASSWORD_TOO_LONG',

	CANT_CREATE_ACCOUNT => 'CANT_CREATE_ACCOUNT',
	USER_LIMIT_EXCEEDED => 'USER_LIMIT_EXCEEDED',

	NO_IMPORT_SETTINGS  => 'NO_IMPORT_SETTINGS',
	SERVICE_ERROR       => 'SERVICE_ERROR',
	UNKNOWN_ERROR       => 'UNKNOWN_ERROR',
};

my @ERR = qw(   
		NOT_AUTHENTICATED
		INVALID_RESPONSE
		REQUEST_FAILED
                                                  
		USER_NOT_FOUND
		LOGIN_OCCUPIED
		LOGIN_TOO_SHORT
		LOGIN_TOO_LONG

		PASSWORD_TOO_SHORT
		PASSWORD_TOO_LONG

		CANT_CREATE_ACCOUNT

		USER_LIMIT_EXCEEDED

		NO_IMPORT_SETTINGS
		NO_IMPORT_INFO

		SERVICE_ERROR
		UNKNOWN_ERROR
);

my %ERR_R = (   
		'not authenticated'           => NOT_AUTHENTICATED,
		'not_authorized'              => NOT_AUTHENTICATED,
		'no_login'                    => INVALID_LOGIN,
		'bad_login'                   => INVALID_LOGIN,
		'no_user'                     => USER_NOT_FOUND,
		'not_found'                   => USER_NOT_FOUND,
		'user_not_found'              => USER_NOT_FOUND,
		'no such user registered'     => USER_NOT_FOUND,
		'occupied'                    => LOGIN_OCCUPIED,
		'login_short'                 => LOGIN_TOO_SHORT,
		'badlogin_length'             => LOGIN_TOO_LONG,
		'passwd-badpasswd'            => INVALID_PASSWORD,
		'passwd-tooshort'             => PASSWORD_TOO_SHORT,
		'passwd-toolong'              => PASSWORD_TOO_LONG,
		'hundred_users_limit'         => USER_LIMIT_EXCEEDED,

		'no-passwd_cryptpasswd'       => INVALID_PASSWORD,
		'cant_create_account'         => CANT_CREATE_ACCOUNT,

		'no_import_settings'          => NO_IMPORT_SETTINGS,
		'no import info on this user' => USER_NOT_FOUND,
      	'unknown'                     => REQUEST_FAILED,
);

our @EXPORT_OK   = ( @ERR );
our %EXPORT_TAGS = ( errors => [ @ERR ] );

sub identify
{
	return $ERR_R{ [split(/,/, $_[0], 2)] -> [0] } || &REQUEST_FAILED; 
}

=encoding utf8

=head1 NAME

WWW::Yandex::PDD::Error - error messages handling for L<WWW::Yandex::PDD>


=head1 SYNOPSIS

Normally there is no need to mess with this package.

Unfortunately, Yandex API does not provide any description of error messages or even a list of possible messages. Please contact me at L<< <aluck@cpan.org> >> if you happen to stumble upon any messages that are not handled here.


=head1 METHODS

=head2 identify
	my $error = WWW::Yandex::PDD::identify($error_message)

	Takes Yandex error message, returns its type.

=cut

1;
