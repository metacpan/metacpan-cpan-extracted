use Exception::Class;
use Test::More tests => 26 + 2;
use Test::NoWarnings;
use WWW::Wookie::Connector::Service;
use WWW::Wookie::Server::Connection;

my $LOGIN              = q{ Login };
my $LOGIN_TRIMMED      = q{Login};
my $LOGIN_ALT          = q{ Alternate login };
my $LOGIN_ALT_TRIMMED  = q{Alternate login};
my $SCREEN             = q{ screen };
my $SCREEN_TRIMMED     = q{screen};
my $SCREEN_ALT         = q{ Alternate screen name };
my $SCREEN_ALT_TRIMMED = q{Alternate screen name};
my $PROPERTY_NAME      = q{Property name};
my $PROPERTY_VALUE_ALT = q{Alternate property value};
my $PROPERTY_NAME_ALT  = q{Alternate property name};
my $PROPERTY_VALUE     = q{Property value};
my $AVAILABLE_WIDGETS  = 16;
my $PUBLIC             = 1;
my $NOT_PUBLIC         = 0;
my $API_KEY            = q{TEST};
my $SHARED_DATA_KEY    = q{localhost_dev};
my $SERVER = $ENV{WOOKIE_SERVER} || q{http://localhost:8080/wookie/};
my $LOCALE = q{en_US};
my $STRING =
    qq{Wookie Server Connection - URL: $SERVER}
  . qq{API Key: $API_KEY}
  . qq{Shared Data Key: $SHARED_DATA_KEY};

$obj =
  WWW::Wookie::Server::Connection->new( $SERVER, $API_KEY, $SHARED_DATA_KEY );
my $up = $obj->test;

TODO: {
    todo_skip
q{Need a live Wookie server for this test. Set the enviroment variable WOOKIE_SERVER if the server isn't in the default location.},
      26
      if !$up;

    $obj =
      WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
        $LOGIN, $SCREEN );
    my @widgets = $obj->getAvailableWidgets(q{all});
    is( 0 + @widgets, $AVAILABLE_WIDGETS, q{getAvailableWidgets} );
    my $widget   = shift @widgets;
    my $instance = $obj->getOrCreateInstance($widget);
    is( $obj->getConnection->getURL,    $SERVER,  q{getURL} );
    is( $obj->getConnection->getApiKey, $API_KEY, q{getApiKey} );
    is( $obj->getConnection->getSharedDataKey,
        $SHARED_DATA_KEY, q{getSharedDataKey} );
    is( $obj->getConnection->as_string, $STRING, q{as_string} );

  TODO: {
        todo_skip q{Stringification overload is broken somehow}, 1
          if 1;
        is( "@{[$obj->getConnection]}", $STRING, q{as_string overloaded} );
    }
    is( $obj->getConnection->test,    1,               q{test} );
    is( $obj->getUser->getLoginName,  $LOGIN_TRIMMED,  q{getLoginName} );
    is( $obj->getUser->getScreenName, $SCREEN_TRIMMED, q{getScreenName} );
    is( $obj->getLocale,              undef,           q{getLocale} );
    $obj->setLocale($LOCALE);
    is( $obj->getLocale, $LOCALE, q{getLocale} );
    my $user = $obj->getUser;

    my $users_amount = $obj->getUsers($instance);

  TODO: {
        todo_skip q{Multiuser is broken}, 2
          if 1;
        $obj->setUser( $LOGIN_ALT, $SCREEN_ALT );
        is( $obj->getUser->getLoginName,
            $LOGIN_ALT_TRIMMED, q{getLoginName after change} );
        is( $obj->getUser->getScreenName,
            $SCREEN_ALT_TRIMMED, q{getScreenName after change} );
    }

    my $property =
      WWW::Wookie::Widget::Property->new( $PROPERTY_NAME, $PROPERTY_VALUE,
        $NOT_PUBLIC );
    is( $property->getName,     $PROPERTY_NAME,  q{getName of property} );
    is( $property->getValue,    $PROPERTY_VALUE, q{getValue of property} );
    is( $property->getIsPublic, $NOT_PUBLIC,     q{getIsPublic of property} );
    $property->setName($PROPERTY_NAME_ALT);
    is( $property->getName, $PROPERTY_NAME_ALT, q{setName of property} );
    $property->setValue($PROPERTY_VALUE_ALT);
    is( $property->getValue, $PROPERTY_VALUE_ALT, q{setValue of property} );
    $property->setIsPublic($PUBLIC);
    is( $property->getIsPublic, $PUBLIC, q{setPublic of property} );

    # Delete public property has issues:
    $property->setIsPublic($NOT_PUBLIC);

    $obj->addProperty( $instance, $property );
    is( $obj->getProperty( $instance, $property )->getValue,
        $PROPERTY_VALUE_ALT, q{addProperty} );
    $property->setValue($PROPERTY_VALUE);
    $obj->setProperty( $instance, $property );
    is( $obj->getProperty( $instance, $property )->getValue,
        $PROPERTY_VALUE, q{setProperty} );
  TODO: {
        todo_skip( q{Delete is broken on server}, 3 ) if 1;
        is( $obj->deleteProperty( $instance, $property ),
            1, q{deleteProperty on existing property} );
        is( $obj->deleteProperty( $instance, $property ),
            0, q{deleteProperty on non-existing property} );
        eval { $obj->getProperty( $instance, $property ); };
        $e = Exception::Class->caught('WookieConnectorException');
        like( $e->error, qr/\b404\b/, q{deleting private property} );
    }

    $property = WWW::Wookie::Widget::Property->new( $PROPERTY_NAME_ALT,
        $PROPERTY_VALUE_ALT, $PUBLIC );

    $users_amount = $obj->getUsers($instance);
    $user = WWW::Wookie::User->new( $LOGIN_ALT, $SCREEN_ALT );
  TODO: {
        todo_skip q{Participant management via REST is broken}, 2
          if 1;
        $obj->addParticipant( $instance, $user );
        is( $obj->getUsers($instance), $users_amount + 1, q{addParticipant} );
        $obj->deleteParticipant( $instance, $user );
        is( $obj->getUsers($instance), $users_amount, q{addParticipant} );
    }
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
