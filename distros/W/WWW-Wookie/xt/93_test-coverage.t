# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use Readonly;

use Test::More;

our $VERSION = v1.1.5;
if ( !eval { require Test::TestCoverage; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{Test::TestCoverage required for testing test coverage};
}
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $BASE_TESTS => 8;
Test::More::plan 'tests' => $BASE_TESTS;
Readonly::Scalar my $TEST            => q{TEST};
Readonly::Scalar my $API_KEY         => $TEST;
Readonly::Scalar my $SHARED_DATA_KEY => q{localhost_dev};
Readonly::Scalar my $SERVER => $ENV{'WOOKIE_SERVER'}
  || q{http://localhost:8080/wookie/};
Readonly::Scalar my $LOCALE => q{en_US};
Readonly::Scalar my $MSG_NEED_SERVER =>
  q{Need a live Wookie server for this test. Set the enviroment variable }
  . q{WOOKIE_SERVER if the server isn't in the default location.};

TODO: {
    Test::More::todo_skip
      q{Fails on calling add_method on an immutable Moose object}, $BASE_TESTS;

    Test::TestCoverage::test_coverage(q{WWW::Wookie::Widget});
## no critic (RequireExplicitInclusion)
    my $widget = WWW::Wookie::Widget->new( $TEST, $TEST, $TEST, $TEST );
## use critic
    $widget->getIdentifier;
    $widget->getTitle;
    $widget->getDescription;
    $widget->getIcon;
    $widget->DESTROY();
    $widget->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::Widget});

    Test::TestCoverage::test_coverage(q{WWW::Wookie::Widget::Category});
## no critic (RequireExplicitInclusion)
    my $category = WWW::Wookie::Widget::Category->new($TEST);
## use critic
    $category->getName;
    $category->get;
## no critic (RequireExplicitInclusion)
    $category->put( WWW::Wookie::Widget->new( $TEST, $TEST, $TEST, $TEST ) );
## use critic
    $category->DESTROY();
    $category->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::Widget::Category});

    Test::TestCoverage::test_coverage(q{WWW::Wookie::Widget::Instance});
## no critic (RequireExplicitInclusion)
    my $instance =
      WWW::Wookie::Widget::Instance->new( $TEST, $TEST, $TEST, 1, 1 );
## use critic
    $instance->getUrl;
    $instance->setUrl($TEST);
    $instance->getIdentifier;
    $instance->setIdentifier($TEST);
    $instance->getTitle;
    $instance->setTitle($TEST);
    $instance->getHeight;
    $instance->setHeight(1);
    $instance->getWidth;
    $instance->setWidth(1);
    $instance->DESTROY();
    $instance->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::Widget::Instance});

    Test::TestCoverage::test_coverage(q{WWW::Wookie::Widget::Instances});
## no critic (RequireExplicitInclusion)
    my $instances = WWW::Wookie::Widget::Instances->new();
    $instances->put(
        WWW::Wookie::Widget::Instance->new( $TEST, $TEST, $TEST, 1, 1 ) );
## use critic
    $instances->get;
    $instances->DESTROY();
    $instances->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::Widget::Instances});

    Test::TestCoverage::test_coverage(q{WWW::Wookie::Widget::Property});
## no critic (RequireExplicitInclusion)
    my $property = WWW::Wookie::Widget::Property->new( $TEST, $TEST, 0 );
## use critic
    $property->getName;
    $property->setName($TEST);
    $property->getValue;
    $property->setValue($TEST);
    $property->getIsPublic;
    $property->setIsPublic(1);
    $property->DESTROY();
    $property->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::Widget::Property});

    Test::TestCoverage::test_coverage(q{WWW::Wookie::User});
## no critic (RequireExplicitInclusion)
    my $user = WWW::Wookie::User->new();
## use critic
    $user->getLoginName;
    $user->setLoginName($TEST);
    $user->getScreenName;
    $user->setScreenName($TEST);
    $user->getThumbnailUrl;
    $user->setThumbnailUrl($TEST);
    $user->DESTROY();
    $user->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::User});

    Test::TestCoverage::test_coverage(q{WWW::Wookie::Server::Connection});
## no critic (RequireExplicitInclusion)
    my $connection =
      WWW::Wookie::Server::Connection->new( $SERVER, $TEST, $TEST );
## use critic
    $connection->getURL;
    $connection->getApiKey;
    $connection->getSharedDataKey;
    $connection->as_string;
    my $string = qq{$connection};
    my $up     = $connection->test;
    $connection->DESTROY();
    $connection->meta();
    Test::TestCoverage::ok_test_coverage(q{WWW::Wookie::Server::Connection});

  TODO: {
        if ( !$up ) {
            Test::More::todo_skip
              $MSG_NEED_SERVER,
              1;
        }
        Test::TestCoverage::test_coverage(q{WWW::Wookie::Connector::Service});

        my $service =
## no critic (RequireExplicitInclusion)
          WWW::Wookie::Connector::Service->new(
            $SERVER, $API_KEY, $SHARED_DATA_KEY,
## use critic
            $TEST, $TEST,
          );
        $service->getLogger;
        $service->getConnection;
        $service->setLocale($LOCALE);
        $service->getLocale;
        my @services = $service->getAvailableServices;
        foreach my $service (@services) {
            $service->getName;
        }
        my @widgets      = $service->getAvailableWidgets;
        my $service_user = $service->getUser;
        foreach my $widget (@widgets) {
            Test::More::diag( $widget->getIdentifier );
            $service->getWidget( $widget->getIdentifier );
            my $service_instance = $service->getOrCreateInstance($widget);
            $service->getUsers($service_instance);
            $service->setUser( $TEST, $TEST );
## no critic (RequireExplicitInclusion)
            my $widget_property =
              WWW::Wookie::Widget::Property->new( $TEST, $TEST, 0 );
## use critic
            $service->WidgetInstances;
            $service->addProperty( $service_instance, $widget_property );
            $service->setProperty( $service_instance, $widget_property );
            $service->getProperty( $service_instance, $widget_property );
            $service->deleteProperty( $service_instance, $widget_property );
            $service->addParticipant( $service_instance, $service_user );
            $service->deleteParticipant( $service_instance, $service_user );
        }
        $service->DESTROY();
        $service->meta();
        Test::TestCoverage::ok_test_coverage('WWW::Wookie::Connector::Service');
    }
}
