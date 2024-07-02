# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use Test::More 'tests' => 26 + 1 + ( $ENV{'AUTHOR_TESTING'} ? 0 : 1 );
use Test::NoWarnings;
use URI::Escape qw(uri_escape);
use Readonly;

use WWW::Wookie::Widget::Instance;
use WWW::Wookie::Connector::Service;

our $VERSION = v1.1.6;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $TEST_WARNINGS => $ENV{'AUTHOR_TESTING'}
## no critic (RequireCheckingReturnValueOfEval)
  && eval { require Test::NoWarnings };
Readonly::Scalar my $WIDGET_ID       => q{http://notsupported};
Readonly::Scalar my $LOGIN           => q{ Login };
Readonly::Scalar my $SCREEN          => q{ screen };
Readonly::Scalar my $API_KEY         => q{TEST};
Readonly::Scalar my $SHARED_DATA_KEY => q{localhost_dev};
Readonly::Scalar my $SERVER => $ENV{'WOOKIE_SERVER'}
  || q{http://localhost:8080/wookie/};
Readonly::Scalar my $INVALID => q{_};
Readonly::Scalar my $EMPTY   => q{};

Readonly::Scalar my $PROPERTIES      => q{properties};
Readonly::Scalar my $WIDGETINSTANCES => q{widgetinstances};
Readonly::Scalar my $PARTICIPANTS    => q{participants};
Readonly::Scalar my $SERVICES        => q{services};
Readonly::Scalar my $WIDGETS         => q{widgets};

Readonly::Scalar my $UP =>
## no critic (RequireExplicitInclusion)
  WWW::Wookie::Server::Connection->new( $SERVER, $API_KEY, $SHARED_DATA_KEY )
  ->test;

Test::More::diag(q{Messages generated while throwing exceptions:});
my $service =
  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
    $LOGIN, $SCREEN );
my $e;

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->getProperty; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->getProperty( WWW::Wookie::Widget::Instance->new() ); };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error} );

## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error},
);

$service = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->getProperty(
        WWW::Wookie::Widget::Instance->new(),
## no critic (RequireExplicitInclusion)
        WWW::Wookie::Widget::Property->new(),
    );
};
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($PROPERTIES),
    q{throwing MALFORMED_URL error},
);

$service =
  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
    $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->getProperty(
        WWW::Wookie::Widget::Instance->new(),
## no critic (RequireExplicitInclusion)
        WWW::Wookie::Widget::Property->new(),
    );
};
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');

TODO: {
    if ( !$UP ) {
        Test::More::todo_skip
          q{Need a live Wookie server for this test. Set the enviroment }
          . q{variable WOOKIE_SERVER if the server isn't in the default }
          . q{location.},
          1;
    }
    Test::More::like( $e->error, qr/\b404\b/msx, q{throw HTTP error} );
}

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->getOrCreateInstance($EMPTY); };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is( $e, q{No GUID nor widget object}, q{throw NO_WIDGET_GUID} );

$service = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
eval { $service->getOrCreateInstance($WIDGET_ID); };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($WIDGETINSTANCES),
    q{throwing MALFORMED_URL error},
);

TODO: {
    if ( !$UP ) {
        Test::More::todo_skip
          q{Need a live Wookie server for this test. Set the enviroment }
          . q{variable WOOKIE_SERVER if the server isn't in the default }
          . q{location.},
          2;

    }
    $service =
      WWW::Wookie::Connector::Service->new( $SERVER, $INVALID . $API_KEY,
        $SHARED_DATA_KEY, $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
    eval { $service->getOrCreateInstance($WIDGET_ID); };
## no critic (RequireExplicitInclusion)
    $e = Exception::Class->caught('WookieConnectorException');
    Test::More::is(
        $e->error,
        q{Invalid API key},
        q{throwing INVALID_API_KEY error},
    );

    $service =
      WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
        $LOGIN, $SCREEN );
    my $instance = $service->getOrCreateInstance($WIDGET_ID);
    $service = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
        $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
    eval { $service->getUsers($instance); };
## no critic (RequireExplicitInclusion)
    $e = Exception::Class->caught('WookieConnectorException');
    Test::More::is(
        $e->error,
        q{URL for supplied Wookie Server is malformed: }
          . $service->getConnection->getURL
          . URI::Escape::uri_escape($PARTICIPANTS),
        q{throwing MALFORMED_URL error},
    );
}

$service = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->addProperty(
        WWW::Wookie::Widget::Instance->new(),
## no critic (RequireExplicitInclusion)
        WWW::Wookie::Widget::Property->new( q{foo}, q{bar}, 0 ),
    );
};
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{Properties rest URL is incorrect: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($PROPERTIES),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error},
);

$service =
  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
    $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
eval { $service->deleteProperty; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->deleteProperty( WWW::Wookie::Widget::Instance->new() ); };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error} );
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error},
);

$service = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->deleteProperty(
        WWW::Wookie::Widget::Instance->new(),
## no critic (RequireExplicitInclusion)
        WWW::Wookie::Widget::Property->new(),
    );
};
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{Properties rest URL is incorrect: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($PROPERTIES),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->getAvailableServices; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($SERVICES),
    q{throwing MALFORMED_URL error requesting services},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->getAvailableWidgets; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($WIDGETS),
    q{throwing MALFORMED_URL error requesting widgets},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->setProperty; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error setting property},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->setProperty( WWW::Wookie::Widget::Instance->new() ); };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is( $e, undef,
    q{not throwing NO_WIDGET_INSTANCE error setting property} );
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error setting property},
);

## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->setProperty(
        WWW::Wookie::Widget::Instance->new(),
## no critic (RequireExplicitInclusion)
        WWW::Wookie::Widget::Property->new( q{foo}, q{bar}, 0 ),
    );
};
Test::More::is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error setting property},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->addParticipant; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error adding participant},
);

## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->addParticipant(
        WWW::Wookie::Widget::Instance->new(),
## no critic (RequireExplicitInclusion)
        WWW::Wookie::User->new(),
    );
};
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is( $e, undef,
    q{not throwing NO_WIDGET_INSTANCE error adding participant} );
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{Participants rest URL is incorrect: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($PARTICIPANTS),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error adding participant},
);

## no critic (RequireCheckingReturnValueOfEval)
eval { $service->deleteParticipant; };
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error deleting participant},
);

## no critic (RequireCheckingReturnValueOfEval)
eval {
    $service->deleteParticipant( WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::User->new() );
};
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieWidgetInstanceException');
Test::More::is( $e, undef,
    q{not throwing NO_WIDGET_INSTANCE error deleting participant} );
## no critic (RequireExplicitInclusion)
$e = Exception::Class->caught('WookieConnectorException');
Test::More::is(
    $e->error,
    q{Participants rest URL is incorrect: }
      . $service->getConnection->getURL
      . URI::Escape::uri_escape($PARTICIPANTS),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error deleting participant},
);

# Skipping hard to trap HTTP response code exception.

## no critic (RequireInterpolationOfMetachars)
my $msg = q{Author test. Install Test::NoWarnings and set }
  . q{$ENV{AUTHOR_TESTING} to a true value to run.};
SKIP: {
    if ( !$TEST_WARNINGS ) {
        Test::More::skip $msg, 1;
    }
}
$TEST_WARNINGS && Test::NoWarnings::had_no_warnings();
