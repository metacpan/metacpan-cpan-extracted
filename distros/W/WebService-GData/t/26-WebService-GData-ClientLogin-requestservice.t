use Test::More;

use LWP::UserAgent;
sub skipit { plan skip_all =>shift(); };

eval("use Crypt::SSLeay;");
if ($@) {
    skipit("Crypt::SSLeay must be installed to test ClientLogin live...");
}

my $url='http://www.google.com/';
diag('Testing your internet connection...');
my $ua = LWP::UserAgent->new();
   $ua->timeout(10);
my $r = $ua->get($url);
skipit('You may not be connected to the internet...')   unless $r->code == 200;
diag('You are connected to the internet.');

use WebService::GData::ClientLogin;
use WebService::GData::Constants qw(:errors);

eval {
    $SIG{ALRM} = sub { skipit('10 seconds elapsed with no input...')};
    alarm 10;
};
if ($@) {
    skipit("unexpected error...") unless $@ eq "alarm\n";
}

diag("Do you wish to test the ClientLogin with your account? [yes] or [no]:");

my $dotest = <STDIN>;
alarm 0;
if ( $dotest && $dotest =~ m/y(es)*/ ) {
    while (1) {
        diag(
'Enter a username, a password and service name(youtube,cl,...) separated by a space.'
        );
        diag('Example:myaccount@gmail.com mypassword youtube');
        diag('Enter the above information and press Enter to continue. Press just Enter with no ohter input to abort.');

        my $account = <STDIN>;

        my ( $username, $password,$service ) = split /\s+/, $account;
        if(!$username && !$password){    
            skipit("User abortion...");
            exit 0;
        }

        diag("Trying to connect...");

        my $auth;
        eval {
            $auth = new WebService::GData::ClientLogin(
                email    => $username,
                password => $password,
                service  => $service || 'youtube'
            );
        };
        if ( my $error = $@ ) {
            diag("Could not connect to the account:". $error->code );
            diag("Enter your information again...");
            diag("...............................");
        }
        else {
             diag("Acquired an authorization key...");
            ok( $auth->authorization_key, 'got an authorization key.' );
            done_testing(1);
            exit 0;
        }
    }
}
else {
   skipit("User abortion...");
}
