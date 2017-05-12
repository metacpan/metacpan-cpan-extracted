use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::PSGI;
use Plack::Builder;

my $email;
my $pass_token;
my $password;

{
    package My::ResetPass;
    use parent 'WebPrototypes::ResetPass';

    sub find_user {
        my( $self, $name ) = @_;
        return 1, 'test@example.com', 'a' if $name eq 'right_name';
        return;
    }

    sub send_mail {
        my( $self, $email_ ) = @_;
        $email = $email_;
    }

    sub update_user {
        my( $self, $user, $params ) = @_;
        $pass_token = $params->{pass_token};
        $password   = $params->{password};
    }

}

my $app = My::ResetPass->new;

my $mounted_app = builder {
    mount "/forgotten_pass" => builder {
        $app->to_app;
    };
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $mounted_app );

$mech->get_ok( '/forgotten_pass', 'index page' );
$mech->submit_form_ok( {
        with_fields => {
            'username' => 'wrong',
        }
    },
    'wrong name'
);
$mech->content_contains( 'User not found', 'user not found' );

$mech->get_ok( '/forgotten_pass', 'index page' );
$mech->submit_form_ok( {
        with_fields => {
            'username' => 'right_name',
        }
    },
    'right name'
);
$mech->content_contains( 'Email sent', 'email sent' );

is( scalar( $email->header( 'To' ) ), 'test@example.com', 'Confirmation email recepient' );
like( $email->body, qr/\btoken=$pass_token/, 'Email contains link with the right token' );

$mech->get_ok( '/forgotten_pass/reset?name=right_name&token=aaaa', 'reset token' );
$mech->content_contains( 'Token invalid', 'invalid reset token' );
$mech->get_ok( '/forgotten_pass/reset?name=right_name&token=a', 'reset token' );
$mech->content_contains( 'New password:<input', 'reset token verified' );
$mech->submit_form_ok( {
        with_fields => {
            'password' => 'new password',
        }
    },
    'ResetPass for test'
);

is( $password, 'new password', 'Password reset' );

done_testing;
