use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::PSGI;
use Plack::Builder;

my $user;
my $email;

{
    package My::Register;
    use parent 'WebPrototypes::Registration';

    sub find_user {
        my( $self, $name ) = @_;
        return 1 if $name eq 'used_name';
        return;
    }

    sub create_user {
        my( $self, %fields ) = @_;
        $user = \%fields;
    }

    sub send_mail {
        my( $self, $email_ ) = @_;
        $email = $email_;
    }

}

my $app = My::Register->new;

my $mounted_app = builder {
    mount "/register" => builder {
        $app->to_app;
    };
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $mounted_app );

$mech->get_ok( '/register' );

$mech->submit_form_ok( {
        with_fields => {
            username => 'used_name',
            email => 'not really email',
        }
    },
    'Register user duplicate name and wrong email'
);
$mech->content_contains( 'This username is already registered', );
$mech->content_contains( 'Wrong format of email', );

$mech->submit_form_ok( {
        with_fields => {
            username => 'new_user',
            email => 'test@example.com',
        }
    },
    'Register user'
);
$mech->content_contains( 'Email sent', );
is( $user->{username}, 'new_user', 'User created' );
is( $user->{email}, 'test@example.com', 'User created' );

is( scalar( $email->header( 'To' ) ), 'test@example.com', 'Confirmation email recepient' );
like( $email->body, qr{reset/new_user/}, 'Confirmation email link' );

done_testing;
