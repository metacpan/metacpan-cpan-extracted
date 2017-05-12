use strict;
use warnings;
use Amon2::Lite;
use WebService::Dropbox;

__PACKAGE__->load_plugins('Web::JSON');

my $key = $ENV{DROPBOX_APP_KEY};
my $secret = $ENV{DROPBOX_APP_SECRET};
my $dropbox = WebService::Dropbox->new({ key => $key, secret => $secret });

my $redirect_uri = 'http://localhost:5000/callback';

get '/' => sub {
    my ($c) = @_;

    my $url = $dropbox->authorize({ redirect_uri => $redirect_uri });

    return $c->redirect($url);
};

get '/callback' => sub {
    my ($c) = @_;

    my $code = $c->req->param('code');

    my $token = $dropbox->token($code, $redirect_uri);

    my $account = $dropbox->get_current_account || { error => $dropbox->error };

    return $c->render_json({ token => $token, account => $account });
};

__PACKAGE__->to_app();

__DATA__

@@ index.tt
<!doctype html>
<html>
    <body>
        <h1>Hello</h1>
        [% res %]
    </body>
</html>
