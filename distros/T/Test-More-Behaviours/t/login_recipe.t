use strict; 
use warnings;

use lib qw(./lib) ;

use Test::More::Behaviours tests => 9 ;

{
	package My::Login ;

	sub new{
		bless({},shift) ;
	}

	sub valid_email {
		my $self = shift;
		my $email = shift ;
		return $email =~ /[a-z0-9-_]+@[a-z0-9-_.]+/?1:0 ;
	}

	sub valid_password {
		my $self = shift;
		my $password = shift ;	
		return $password =~ /[a-z0-9]{8}/?1:0 ;
	}

	sub authenticate{
		my $self = shift;
		return 1;
	}

	sub authenticate_fgrprt{
		my $self = shift;
	}

	sub reset_password{
		my $self = shift;
	}

}

our $l ;

sub set_up{
	$l = My::Login->new() ;
}

test "Validating email entered during signup" => sub {

	is $l->valid_email("") => 0, "should return 0 for empty email"  ;
	is $l->valid_email("tot,\@l") => 0, "should return 0 for invalid email tot,\@l" ;
	ok $l->valid_email("hello\@world"), "should return 1 for valid email hello\@world.com" ;

};

test "Validating entered password during signup" => sub {

	isnt $l->valid_password("") => 1, "should return 0 for empty password"  ;
	isnt $l->valid_password("12345") => 1, "should return 0 for password  < 8 characters" ;
	is $l->valid_password("abracada") => 1, "should return 1 for valid password abracada" ;

};

test "Authenticating user during signin" => sub{
	is $l->authenticate("john\@test.com","12345678") =>1, "should return 1 denoting valid login" ;
	SKIP:{
		skip "because fingerprint reader not connected",1 unless $ENV{'HAS_FINGERPRT_READER_DEV'} ;
		is $l->authenticate_fgrprt("john\@test.com","12345678") =>1, "should return 1 denoting valid login" ;
	}
};

test "Resetting a user's password during password recovery" => sub{
	local $TODO = "Not implemented yet" ;
	is $l->reset_password() => 1, "should return 1 denoting password reset" ;
};

