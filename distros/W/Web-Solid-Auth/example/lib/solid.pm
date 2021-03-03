package solid;

use v5.10;
use Dancer ':syntax';
use Web::Solid::Auth;

sub session {
    state $state = {};
    $state;
}

get '/' => sub {
    my $auth = session()->{auth};

    if ($auth && $auth->has_access_token) {
          my $webid    = $auth->webid;
          my $inbox    = $webid;
          $inbox =~ s{(https://[^/]+).*}{$1/inbox/};
          my $headers  = $auth->make_authentication_headers($inbox,'GET');
          my $response = $auth->get($inbox,%$headers);

          return <<EOF;
<html>
  <body>
  <h1>You are logged in :)</h1>
  <h2>$webid</h2>
  <p>
  Here is your private $inbox
  </p>
  <pre>
  $response
  </pre>
  </body>
</html>
EOF
    }
    else {
      return <<EOF;
<html>
 <body>
 <h1>Demo Login</h1>
 Please provide your webid.<br>
 <i>E.g. https://hochstenbach.solidcommunity.net/profile/card#me</i><br>
 <form action="login">
 <input type="text" name="webid" value="" size="80"><input type="submit">
 </form>
 </body>
<html>
EOF
  }
};

get '/login' => sub {
    my $webid = params->{webid};

    redirect("/") unless $webid;

    my $auth = Web::Solid::Auth->new(
          webid => $webid ,
          redirect_uri => 'http://localhost:3000/cb'
    );

    $auth->make_clean;

    session()->{auth} = $auth;

    redirect $auth->make_authorization_request;
};

get '/cb' => sub {
    my $code  = params->{code};
    my $state = params->{state};

    my $data = session()->{auth}->make_access_token($code);

    redirect("/")
};

true;
