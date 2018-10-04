package WWW::Google::Login;

use strict;
use Moo 2;
use WWW::Mechanize::Chrome;
use Log::Log4perl ':easy';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use WWW::Google::Login::Status;

our $VERSION = '0.01';

=head1 NAME

WWW::Google::Login - log a mechanize object into Google

=head1 SYNOPSIS

    my $mech = WWW::Mechanize::Chrome->new(
        headless => 1,
        data_directory => tempdir(CLEANUP => 1),
        user_agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.39 Safari/537.36+',
    );
    $mech->viewport_size({ width => 480, height => 640 });

    $mech->get('https://keep.google.com');

    my $login = WWW::Google::Login->new(
        mech => $mech,
    );

    if( $login->is_login_page()) {
        my $res = $login->login(
            user => 'a.u.thor@gmail.com',
            password => 'my-secret-password',
            headless => 1
        );

        if( $res->wrong_password ) {
            # ?
        } elsif( $res->logged_in ) {
            # yay
        } else {
            # some other error
        }
    };

=head1 DESCRIPTION

This module automates logging in a (Javascript capable) WWW::Mechanize
object into Google. This is useful for scraping information from Google
applications.

Currently, this module only works in conjunction with L<WWW::Mechanize::Chrome>,
but ideally it will evolve to not requiring Javascript or Chrome at all.

=cut

has 'logger' => (
    is => 'ro',
    default => sub {
        get_logger(__PACKAGE__),
    },
);

has 'mech' => (
    is => 'ro',
    is_weak => 1,
);

has 'console' => (
    is => 'rw',
);

sub mask_headless( $self, $mech ) {
    my $console = $mech->add_listener('Runtime.consoleAPICalled', sub {
      warn "[] " . join ", ",
          map { $_->{value} // $_->{description} }
          @{ $_[0]->{params}->{args} };
    });
    $self->console($console);

    $mech->block_urls(
        'https://fonts.gstatic.com/*',
    );

    my $id = $mech->driver->send_message('Page.addScriptToEvaluateOnNewDocument', source => <<'JS' )->get;
Object.defineProperty(navigator, 'webdriver', {
    get: () => false
});

Object.defineProperty(navigator, 'plugins', {
    get: () => [1,2,3,4,5]
});
Object.defineProperty(navigator, 'languages', {
    get: () => ['en-US', 'en'],
});

const myChrome = {
    "app":{"isInstalled":false},
    "webstore":{"onInstallStageChanged":{},"onDownloadProgress":{}},
    "runtime": {}
};
Object.defineProperty(navigator, 'chrome', {
    get: () => { console.log("chrome property accessed"); myChrome }
});

const connection = { rtt: 100, downlink: 1.6, effectiveType: "4g", downlinkMax: null };
Object.defineProperty(navigator, 'connection', {
    get: () => (connection),
});

const originalQuery = window.navigator.permissions.query;
window.navigator.permissions.query = (parameters) => {
    console.log("permission query for " + parameters.name);
    parameters.name === 'notifications' ?
      Promise.resolve({ state: Notification.permission }) :
      originalQuery(parameters)
};

console.log("Page " + window.location);
JS

    #$mech->agent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.39 Safari/537.36+');
    $mech->get('about:blank');
}

sub login_headfull( $self, %options ) {
    my $l = $options{ logger } || $self->logger;
    my $mech = $options{ mech } || $self->mech;
    my $user = $options{ user };
    my $password = $options{ password };
    my $logger = $self->logger;
    if( ! $self->is_password_page_headfull ) {
        my @email = $mech->wait_until_visible( selector => '//input[@type="email"]' );

        my $username = $email[0]; # $mech->xpath('//input[@type="email"]', single => 1 );
        $username->set_attribute('value', $user);
        $mech->click({ xpath => '//*[@id="identifierNext"]' });
    };

    # Give time for password page to load
    $mech->wait_until_visible( selector => '//input[@type="password"]' );
    my $field = $mech->selector( '//input[@type="password"]', one => 1 );
    #print $field->get_attribute('id'), "\n";
    #print $field->get_attribute('name'), "\n";
    #print $field->get_attribute('outerHTML'), "\n";
    my $password_field =
      $mech->xpath( '//input[@type="password"]', single => 1 );

    my $password_html = $mech->selector('#password', single => 1 );
    $mech->click( $password_html ); # html "field" to enable the real field
    $mech->sendkeys( string => $password );
    $logger->info("Password entered into field");

    # Might want to uncheck 'save password' box for future
    $logger->info("Clicking Sign in button");

    $mech->click({ selector => '#passwordNext', single => 1 }); # for headful

    my $error = $mech->xpath( '//*[@aria="assertive"]', maybe => 1 );
    if( $error ) {
        return WWW::Google::Login::Status->new(
            wrong_password => 1
        );
    };

    WWW::Google::Login::Status->new(
        logged_in => 1
    );
}

sub login_headless( $self, %options ) {
    my $l = $options{ logger } || $self->logger;
    my $mech = $options{ mech } || $self->mech;
    my $user = $options{ user };
    my $password = $options{ password };
    my $logger = $self->logger;

    if( ! $self->is_password_page_headless ) {
        # Click in Login Email form field
        warn "Waiting for email entry field";
        $mech->wait_until_visible( selector => '//input[@type="email"]' );
        my $email = $mech->selector( '//input[@type="email"]', single => 1 );
        $logger->info("Clicking and setting value on Email form field");

        $mech->field( Email => $user );
        $mech->sleep(1);
        $logger->info("Clicking Next button");
        my $signIn_button = $mech->xpath( '//*[@name = "signIn"]', single => 1 );
        my $signIn_class = $signIn_button->get_attribute('class');
        #warn "Button class name is '$signIn_class'";
        $mech->click_button( name => 'signIn' );
    };

    # Give time for password page to load
    #warn "Waiting for password field";
    $mech->wait_until_visible( selector => '//input[@type="password"]' );
    $logger->info("Clicking on Password form field");

    my $password_field =
        $mech->xpath( '//input[@type="password"]', single => 1 );

    $mech->click($password_field);    # when headless
    #$mech->sleep(10);
    $logger->info("Entering password one character at a time");
    $mech->sendkeys( string => $password );
    $logger->info("Password entered into field");

    # Might want to uncheck 'save password' box for future
    $logger->info("Clicking Sign in button");
    $mech->dump_forms;
    #for ($mech->xpath('//form//*[@id]')) {
    #    warn $_->get_attribute('id');
    #};

    # We should propably wait until a lot of the scripts have loaded...

    $mech->click({ xpath => '//*[@id = "signIn"]', single => 1 });    # for headless

    $mech->sleep(15);
    $mech->wait_until_invisible(xpath => '//*[contains(text(),"Loading...")]');

    WWW::Google::Login::Status->new(
        logged_in => 1
    );
}

=head2 C<< ->is_password_page >>

    if( $login->is_password_page ) {
        $login->login( user => $user, password => $password );
    };

=cut

sub is_password_page( $self ) {
       $self->is_password_page_headless
    || $self->is_password_page_headfull
}

sub is_password_page_headfull( $self ) {
    #() = $self->mech->selector( '#passwordNext', maybe => 1 )
    $self->mech->selector( '#hiddenEmail', maybe => 1 )
}

sub is_password_page_headless( $self ) {
    $self->mech->xpath( '//input[@id="signIn"]', maybe => 1 )
}

=head2 C<< ->is_login_page >>

    if( $login->is_login_page ) {
        $login->login( user => $user, password => $password );
    };

=cut

sub is_login_page( $self ) {

    #my @elements = $self->mech->xpath('//*[@id]');
    #for (@elements) {
    #    warn join "\t", $_->get_attribute('id'), $_->get_attribute('type');
    #};

       $self->is_login_page_headless
    || $self->is_login_page_headfull
    || $self->is_password_page_headfull
    || $self->is_password_page_headless
}

=head2 C<< ->is_login_page_headless >>

=cut

sub is_login_page_headless( $self ) {
    $self->mech->xpath( '//*[@name = "signIn"]', maybe => 1 )
}

=head2 C<< ->is_login_page_headfull >>

=cut

sub is_login_page_headfull( $self ) {
    $self->mech->xpath( '//*[@id="identifierNext"]', maybe => 1 )
}

=head2 C<< ->login >>

    my $res = $login->login(
        user => 'example@gmail.com',
        password => 'supersecret',
    );
    if( $res->logged_in ) {
        # yay
    }

=cut

# https://accounts.google.com/signin/v2/sl/pwd
sub login( $self, %options ) {
    my $res;
    if( $self->is_login_page_headless ) {
        $res = $self->login_headless( %options )
    } elsif( $self->is_login_page_headfull ) {
        $res = $self->login_headfull( %options )
    } else {
        $res = $self->login_headfull( %options )
    }
    $res
}

1;

=head1 FUTURE IMPROVEMENTS

=head2 API usage

Ideally, this module would switch away from screen scraping to directly
automating the API below L<https://accounts.google.com/signin/v2/sl/pwd>.
This would make it possible to switch away from L<WWW::Mechanize::Chrome>
to a plain HTTP client like L<HTTP::Tiny> or L<WWW::Mechanize>.

=head2 Two-factor authentication

Two-factor authentication is not supported at all.

=head1 SEE ALSO

L<https://developers.google.com/my-business/reference/rest/> - Google Business API

This allows a more direct administration of (business) accounts without screen
scraping.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/WWW-Google-Login>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
