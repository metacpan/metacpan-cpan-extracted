# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use Exception::Class;
use Test::More 'tests' => 11 + 1 + ( $ENV{'AUTHOR_TESTING'} ? 0 : 1 );
use Test::NoWarnings;
use Readonly;
use WWW::Wookie::Connector::Service;
use WWW::Wookie::Server::Connection;

our $VERSION = v1.1.5;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $TEST_WARNINGS => $ENV{'AUTHOR_TESTING'}
## no critic (RequireCheckingReturnValueOfEval)
  && eval { require Test::NoWarnings };
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
Readonly::Scalar my $PARTICIPANTS        => 3;
Readonly::Scalar my $BASE_TESTS          => 11;
Readonly::Scalar my $AVAILABLE_WIDGETS   => 16;
Readonly::Scalar my $AVAILABLE_SERVICES  => 5;
Readonly::Scalar my $UNSUPPORTED_WIDGETS => 1;
Readonly::Scalar my $PUBLIC              => 1;
Readonly::Scalar my $NOT_PUBLIC          => 0;
Readonly::Scalar my $UNSUPPORTED         => q{unsupported};
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
Readonly::Scalar my $UP => $connection->test;
Readonly::Hash my %MSG => (
    'NEED_LIVE_SERVER' =>
      q<Need a live Wookie server for this test. Set the enviroment >
      . q<variable WOOKIE_SERVER if the server isn't in the default >
      . q<location.>,
    'CLONED_DATA_KEY' =>
      q<PUT {wookie}/widgetinstances {params:instance_params, action, >
      . q<[cloneshareddatakey]}>,
    'PUT_PROPERTIES' =>
      q<PUT {wookie}/properties {params: instance_params, propertyname, >
      . q<propertyvalue}>,
    'POST_PROPERTIES' =>
      q<POST {wookie}/properties {params: instance_params, propertyname, >
      . q<propertyvalue, [is_public=true]}>,
    'POST_PARTICIPANTS' =>
      q<POST {wookie}participants {params: instance_params, >
      . q<participant_id, participant_display_name, >
      . q<participant_thumbnail_url}>,
);

TODO: {
    if ( !$UP ) {
        Test::More::todo_skip $MSG{'NEED_LIVE_SERVER'}, $BASE_TESTS;
    }

    my $service =
      WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
        $LOGIN, $SCREEN );
    my @widgets = $service->getAvailableWidgets(q{all});
    my $widget  = $widgets[0];

    Test::More::note(q{Widget Instances});
    Test::More::note(q{GET {wookie}/widgetinstances});

    # Not supported
    Test::More::note(q{POST {wookie}/widgetinstances {params:instance_params}});
    my $instance = $service->getOrCreateInstance($widget);
    Test::More::note $MSG{'CLONED_DATA_KEY'};

    # Not in the framework:
    #$service->stop($instance);
    #$service->resume($instance);
    #$service->clone($instance);

    Test::More::note(q{Widgets});
    Test::More::note(q{GET {wookie}/widgets{?all=true, locale=language_tag}});
  TODO: {
        Test::More::todo_skip( q{Deprecated}, 1 );
        Test::More::is( 0 + @widgets,
            $AVAILABLE_WIDGETS, q{getAvailableWidgets} );
    }
    Test::More::note(
        q{GET {wookie}/widgets/{service_name} {?locale=language_tag}});
    my @unsupported_widgets = $service->getAvailableWidgets($UNSUPPORTED);
  TODO: {
        Test::More::todo_skip( q{Deprecated}, 1 );
        Test::More::is( 0 + @unsupported_widgets,
            $UNSUPPORTED_WIDGETS, q{getAvailableWidgets} );
    }
    Test::More::note(q{GET {wookie}/widgets/{id} {?locale=language_tag}});
    Test::More::is(
        $service->getWidget( $widget->getIdentifier )->getIdentifier,
        $widget->getIdentifier, q{getWidget} );

  TODO: {
        Test::More::todo_skip( q{Deprecated}, 1 );
        Test::More::note(q{Services});
        Test::More::note(q{GET {wookie}/services {?locale=language_tag}});
        my @services = $service->getAvailableServices();
        Test::More::is( 0 + @services,
            $AVAILABLE_SERVICES, q{getAvailableServices} );
        Test::More::note(
            q{GET {wookie}/services/{service_name} {?locale=language_tag}});
        my @unsupported_services = $service->getAvailableServices($UNSUPPORTED);
    }
    Test::More::note(q{POST {wookie}/services/ {param:name}});

    # Requires widgetadmin role
    Test::More::note(q{PUT {wookie}/services/{service_name} {param:name}});

    # Requires widgetadmin role
    Test::More::note(q{DELETE {wookie}/services/{service_name}});

    # Requires widgetadmin role

    Test::More::note(q{Participants});
    Test::More::note(q{GET {wookie}/participants});

    # Not supported
    Test::More::note(q{GET {wookie}/participants {params: instance_params}});
    my @participants = $service->getUsers($instance);
    Test::More::is( 0 + @participants, 1, q{getUsers} );
    Test::More::note(q{GET {wookie}/participants {params:id_key, api_key}});
    @participants = $service->getUsers( $instance->getIdentifier );
    Test::More::is( 0 + @participants, 1, q{getUsers} );
  TODO: {
        Test::More::todo_skip q{Multiuser is broken}, 2;
        Test::More::note $MSG{'POST_PARTICIPANTS'};
        $service->addParticipant(
            $instance,
## no critic (RequireExplicitInclusion)
            WWW::Wookie::User->new( q{testuser}, q{testuser} ),
        );
        @participants = $service->getUsers( $instance->getIdentifier );
        Test::More::is( 0 + @participants, $PARTICIPANTS, q{addParticipant} );
        Test::More::note(
q{DELETE {wookie}/participants {params: instance_params, participant_id}},
        );
        $service->deleteParticipant(
            $instance,
## no critic (RequireExplicitInclusion)
            WWW::Wookie::User->new( q{testuser2}, q{testuser2} ),
        );
        @participants = $service->getUsers( $instance->getIdentifier );
        Test::More::is( 0 + @participants, 2, q{addParticipant} );
    }

    Test::More::note(q{Properties});
    Test::More::note(q{GET {wookie}/properties});

    # Not supported
    Test::More::note(
        q{GET {wookie}/properties {params: instance_params, propertyname}});
## no critic (RequireExplicitInclusion)
    my $property = WWW::Wookie::Widget::Property->new( q{foo}, q{bar}, 0 );
    $service->addProperty( $instance, $property );
    Test::More::is( $service->getProperty( $instance, $property )->getName,
        q{foo}, q{getProperty} );
    Test::More::note $MSG{'POST_PROPERTIES'};
    Test::More::note $MSG{'PUT_PROPERTIES'};
## no critic (RequireExplicitInclusion)
    $property = WWW::Wookie::Widget::Property->new( q{foo}, q{baz}, 0 );
    $service->setProperty( $instance, $property );
    Test::More::is( $service->getProperty( $instance, $property )->getValue,
        q{baz}, q{setProperty} );

    Test::More::note(
        q{DELETE {wookie}/properties {params: instance_params, propertyname}});

  TODO: {
        Test::More::todo_skip( q{Delete is broken on server}, 1 );
        $service->deleteProperty( $instance, $property );
## no critic (RequireCheckingReturnValueOfEval)
        eval { $service->getProperty( $instance, $property ); };
        my $e = Exception::Class->caught('WookieConnectorException');
        Test::More::like( $e->error, qr/\b404\b/msx,
            q{deleting private property} );
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
