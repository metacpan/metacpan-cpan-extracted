# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use Exception::Class;
use Test::More 'tests' => 26 + 1 + ( $ENV{'AUTHOR_TESTING'} ? 0 : 1 );
use Test::NoWarnings;
use Readonly;
use WWW::Wookie::Connector::Service;
use WWW::Wookie::Server::Connection;

our $VERSION = v1.1.5;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $TEST_WARNINGS => $ENV{'AUTHOR_TESTING'}
## no critic (RequireCheckingReturnValueOfEval)
  && eval { require Test::NoWarnings };
Readonly::Scalar my $BASE_TESTS          => 26;
Readonly::Scalar my $BROKEN_DELETE_TESTS => 3;
Readonly::Scalar my $LOGIN               => q{ Login };
Readonly::Scalar my $LOGIN_TRIMMED       => q{Login};
Readonly::Scalar my $LOGIN_ALT           => q{ Alternate login };
Readonly::Scalar my $LOGIN_ALT_TRIMMED   => q{Alternate login};
Readonly::Scalar my $SCREEN              => q{ screen };
Readonly::Scalar my $SCREEN_TRIMMED      => q{screen};
Readonly::Scalar my $SCREEN_ALT          => q{ Alternate screen name };
Readonly::Scalar my $SCREEN_ALT_TRIMMED  => q{Alternate screen name};
Readonly::Scalar my $PROPERTY_NAME       => q{Property name};
Readonly::Scalar my $PROPERTY_VALUE_ALT  => q{Alternate property value};
Readonly::Scalar my $PROPERTY_NAME_ALT   => q{Alternate property name};
Readonly::Scalar my $PROPERTY_VALUE      => q{Property value};
Readonly::Scalar my $AVAILABLE_WIDGETS   => 16;
Readonly::Scalar my $PUBLIC              => 1;
Readonly::Scalar my $NOT_PUBLIC          => 0;
Readonly::Scalar my $API_KEY             => q{TEST};
Readonly::Scalar my $SHARED_DATA_KEY     => q{localhost_dev};
Readonly::Scalar my $SERVER => $ENV{'WOOKIE_SERVER'}
  || q{http://localhost:8080/wookie/};
Readonly::Scalar my $LOCALE => q{en_US};
Readonly::Scalar my $STRING => qq{Wookie Server Connection - URL: $SERVER}
  . qq{API Key: $API_KEY}
  . qq{Shared Data Key: $SHARED_DATA_KEY};

my $connection =
  WWW::Wookie::Server::Connection->new( $SERVER, $API_KEY, $SHARED_DATA_KEY );
my $up = $connection->test;

TODO: {
    if ( !$up ) {
        Test::More::todo_skip
          q{Need a live Wookie server for this test. Set the enviroment }
          . q{variable WOOKIE_SERVER if the server isn't in the default }
          . q{location.},
          $BASE_TESTS;
    }

    my $service =
      WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
        $LOGIN, $SCREEN );
    my @widgets = $service->getAvailableWidgets(q{all});
    Test::More::is( 0 + @widgets, $AVAILABLE_WIDGETS, q{getAvailableWidgets} );
    my $widget   = shift @widgets;
    my $instance = $service->getOrCreateInstance($widget);
    Test::More::is( $service->getConnection->getURL, $SERVER, q{getURL} );
    Test::More::is( $service->getConnection->getApiKey, $API_KEY,
        q{getApiKey} );
    Test::More::is( $service->getConnection->getSharedDataKey,
        $SHARED_DATA_KEY, q{getSharedDataKey} );
    Test::More::is( $service->getConnection->as_string, $STRING, q{as_string} );

  TODO: {
        Test::More::todo_skip q{Stringification overload is broken somehow}, 1;
        Test::More::is( "@{[$service->getConnection]}",
            $STRING, q{as_string overloaded} );
    }
    Test::More::is( $service->getConnection->test, 1, q{test} );
    Test::More::is( $service->getUser->getLoginName,
        $LOGIN_TRIMMED, q{getLoginName} );
    Test::More::is( $service->getUser->getScreenName,
        $SCREEN_TRIMMED, q{getScreenName} );
    Test::More::is( $service->getLocale, undef, q{getLocale} );
    $service->setLocale($LOCALE);
    Test::More::is( $service->getLocale, $LOCALE, q{getLocale} );
    my $user = $service->getUser;

    my $users_amount = $service->getUsers($instance);

  TODO: {
        Test::More::todo_skip q{Multiuser is broken}, 2;
        $service->setUser( $LOGIN_ALT, $SCREEN_ALT );
        Test::More::is( $service->getUser->getLoginName,
            $LOGIN_ALT_TRIMMED, q{getLoginName after change} );
        Test::More::is( $service->getUser->getScreenName,
            $SCREEN_ALT_TRIMMED, q{getScreenName after change} );
    }

    my $property =
## no critic (RequireExplicitInclusion)
      WWW::Wookie::Widget::Property->new( $PROPERTY_NAME, $PROPERTY_VALUE,
        $NOT_PUBLIC );
    Test::More::is( $property->getName, $PROPERTY_NAME,
        q{getName of property} );
    Test::More::is( $property->getValue, $PROPERTY_VALUE,
        q{getValue of property} );
    Test::More::is( $property->getIsPublic, $NOT_PUBLIC,
        q{getIsPublic of property} );
    $property->setName($PROPERTY_NAME_ALT);
    Test::More::is( $property->getName, $PROPERTY_NAME_ALT,
        q{setName of property} );
    $property->setValue($PROPERTY_VALUE_ALT);
    Test::More::is( $property->getValue, $PROPERTY_VALUE_ALT,
        q{setValue of property} );
    $property->setIsPublic($PUBLIC);
    Test::More::is( $property->getIsPublic, $PUBLIC, q{setPublic of property} );

    # Delete public property has issues:
    $property->setIsPublic($NOT_PUBLIC);

    $service->addProperty( $instance, $property );
    Test::More::is( $service->getProperty( $instance, $property )->getValue,
        $PROPERTY_VALUE_ALT, q{addProperty} );
    $property->setValue($PROPERTY_VALUE);
    $service->setProperty( $instance, $property );
    Test::More::is( $service->getProperty( $instance, $property )->getValue,
        $PROPERTY_VALUE, q{setProperty} );
  TODO: {
        Test::More::todo_skip( q{Delete is broken on server},
            $BROKEN_DELETE_TESTS );
        Test::More::is( $service->deleteProperty( $instance, $property ),
            1, q{deleteProperty on existing property} );
        Test::More::is( $service->deleteProperty( $instance, $property ),
            0, q{deleteProperty on non-existing property} );
## no critic (RequireCheckingReturnValueOfEval)
        eval { $service->getProperty( $instance, $property ); };
        my $e = Exception::Class->caught('WookieConnectorException');
        Test::More::like( $e->error, qr/\b404\b/msx,
            q{deleting private property} );
    }

## no critic (RequireExplicitInclusion)
    $property = WWW::Wookie::Widget::Property->new( $PROPERTY_NAME_ALT,
        $PROPERTY_VALUE_ALT, $PUBLIC );

    $users_amount = $service->getUsers($instance);
## no critic (RequireExplicitInclusion)
    $user = WWW::Wookie::User->new( $LOGIN_ALT, $SCREEN_ALT );
  TODO: {
        Test::More::todo_skip q{Participant management via REST is broken}, 2;
        $service->addParticipant( $instance, $user );
        Test::More::is(
            $service->getUsers($instance),
            $users_amount + 1,
            q{addParticipant},
        );
        $service->deleteParticipant( $instance, $user );
        Test::More::is( $service->getUsers($instance),
            $users_amount, q{addParticipant} );
    }
}

## no critic (RequireInterpolationOfMetachars)
my $msg = q{Author test. Install Test::NoWarnings and set }
  . q{$ENV{AUTHOR_TESTING} to a true value to run.};
SKIP: {
    if ( !$TEST_WARNINGS ) {
        Test::More::skip $msg, 1;
    }
}
$TEST_WARNINGS && Test::NoWarnings::had_no_warnings();
