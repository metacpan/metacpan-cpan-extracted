package MyApp;

use Mojo::Base 'WWW::Suffit::Server';

our $VERSION = '0.01';

sub init {
    my $self = shift;
    $self->log->debug("Init handler is running");

    # Load SuffitAuth plugin
    $self->plugin('SuffitAuth' => {
            configsection   => 'suffitauth',
            expiration      => '1h',
            public_key_file => 'suffitauth_pub.key',
            userfile_format => 'user-%s.json',
        });

    # Session
    $self->sessions->cookie_name(sprintf("%s-session", $self->moniker));
    $self->sessions->default_expiration(300);

    # Defaults stash-values
    $self->defaults( # Stash defaults
        username => '', # Default username
        error    => '',
    );

    # Access to routes
    my $r = $self->routes;

    # Without login
    $r->get('/')->to('root#index')->name('index');
    $r->get('/test')->to('root#test')->name('test');

    # With login
    $r->any('/login')->to('login#login')->name('login');
    my $logged_in = $r->under('/')->to('login#logged_in');
       $logged_in->get('/private')->to('login#private');
    $r->get('/logout')->to('login#logout');

}

1;

package MyApp::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    return $self->render;
}
sub test {
    my $self = shift;
    $self->log->debug("Hello World!");
    $self->render(text => 'Hello World!');
}

1;

package MyApp::Controller::Login;

use Mojo::Base 'Mojolicious::Controller';

sub login {
    my $self = shift;
    my $username = $self->param('username') || '';
    my $password = $self->param('password') || '';

    # Redirect to private page if user is logged
    if ($self->session('logged')) {
        $self->redirect_to('private');
        return;
    }

    # Check username and return Empty form
    return $self->render unless length($username) && length($password);
    if (length($username) && !length($password)) {
        $self->stash(error => 'Wrong username or password, please try again');
        $self->log->error($self->stash('error'));
        return $self->render;
    }

    # Get the authorization object that was created when the plugin was initialized
    my $authobj = $self->suffitauth;

    # Check client init status
    if (my $err = $authobj->init->get('/error')) {
        $self->stash(error => sprintf("%s: %s", $authobj->init->get('/code'), $err));
        $self->log->error($self->stash('error'));
        return $self->render;
    }

    # Authentication
    my $auth = $authobj->authenticate({
        address     => $self->remote_ip($self->app->trustedproxies), # Default
        base_url    => $self->base_url, # Default
        method      => "ANY", # Default
        referer     => "/login",
        username    => $username,
        password    => $password,
        loginpage   => 'login', # -- To login-page!!
        expiration  => '1h',
    });
    if (my $err = $auth->get('/error')) {
        $self->stash(error => sprintf("%s: %s", $auth->get('/code'), $err));
        $self->log->error($self->stash('error'));
        if (my $location = $auth->get('/location')) { # Redirect (300+)
            # Redirect to received page with flashed message
            $self->flash(message => $self->stash('error'));
            $self->redirect_to($location); # 'login' -- To login-page!!
        } elsif ($auth->get('/status') >= 500) { # Fatal server errors (500+), no redirects, no client errors
            return $self->render;
        } else { # User errors (400+) (show on login page)
            return $self->render;
        }
        return;
    }

    # Set session
    $self->session(
            username => $username,
            logged   => time,
        );

    # Redirect to private page with flashed message
    $self->flash(message => 'Thanks for logging in');
    $self->redirect_to('private');
}
sub logged_in {
    my $self = shift;

    # Check status of session
    unless ($self->session('logged')) {
        $self->redirect_to('login'); # 301: To login-page!!
        return;
    }

    # Get username from session
    my $username = $self->session('username') // '';

    # Authorization
    my $authdata = $self->suffitauth->authorize({
        referer     => $self->req->url->to_string,
        username    => $username,
        loginpage   => 'login', # -- To login-page!!
    });
    if (my $err = $authdata->get('/error')) {
        if (my $location = $authdata->get('/location')) { # Redirect
            $self->flash(message => $err);
            $self->redirect_to($location); # 'login' -- To login-page!!
        } else { # Server or Client Error
            $self->stash(error => sprintf("%s: %s", $authdata->get('/code'), $err));
            $self->log->error($self->stash('error'));
            $self->reply->exception($self->stash('error'));
        }
        return;
    }

    # Stash user data
    $self->stash(
        username => $username,
        name     => $authdata->get('/user/name') // 'Anonymous',
        role     => $authdata->get('/user/role') // 'Regular user',
        user     => $authdata->get('/user') || {}, # User struct
    );

    # Ok
    return 1;
}
sub logout {
    my $self = shift;

    # Remove session
    $self->session(expires => 1); # Reset session

    # Unauthorize
    if (my $username = $self->session('username')) {
        my $authdata = $self->suffitauth->unauthorize(username => $username);
        if (my $err = $authdata->get('/error')) {
            $self->stash(error => sprintf("%s: %s", $authdata->get('/code'), $err));
            $self->log->error($self->stash('error'));
            $self->reply->exception($self->stash('error'));
        }
    }

    # Ok
    $self->redirect_to('login'); # To login-page!!
}

1;
