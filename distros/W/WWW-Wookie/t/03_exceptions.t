use Test::More tests => 26 + 2;
use Test::NoWarnings;
use URI::Escape qw(uri_escape);

use WWW::Wookie::Widget::Instance;
use WWW::Wookie::Connector::Service;

my $WIDGET_ID       = q{http://notsupported};
my $LOGIN           = q{ Login };
my $SCREEN          = q{ screen };
my $API_KEY         = q{TEST};
my $SHARED_DATA_KEY = q{localhost_dev};
my $SERVER          = $ENV{WOOKIE_SERVER} || q{http://localhost:8080/wookie/};
my $INVALID         = q{_};
my $EMPTY           = q{};

my $PROPERTIES      = q{properties};
my $WIDGETINSTANCES = q{widgetinstances};
my $PARTICIPANTS    = q{participants};
my $SERVICES        = q{services};
my $WIDGETS         = q{widgets};

diag(q{Messages generated while throwing exceptions:});
my $obj =
  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
    $LOGIN, $SCREEN );
my $e;

eval { $obj->getProperty; };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e->error, q{No Widget instance}, q{throwing NO_WIDGET_INSTANCE error} );

eval { $obj->getProperty( WWW::Wookie::Widget::Instance->new() ); };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error} );

$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error}
);

$obj = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
eval {
    $obj->getProperty(
        WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::Widget::Property->new()
    );
};
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($PROPERTIES),
    q{throwing MALFORMED_URL error}
);

$obj =
  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
    $LOGIN, $SCREEN );
eval {
    $obj->getProperty(
        WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::Widget::Property->new()
    );
};
$e = Exception::Class->caught('WookieConnectorException');

my $up =
  WWW::Wookie::Server::Connection->new( $SERVER, $API_KEY, $SHARED_DATA_KEY )
  ->test;

TODO: {
    todo_skip
q{Need a live Wookie server for this test. Set the enviroment variable WOOKIE_SERVER if the server isn't in the default location.},
      1
      if !$up;
    like( $e->error, qr/\b404\b/, q{throw HTTP error} );
}

eval { $obj->getOrCreateInstance($EMPTY); };
$e = Exception::Class->caught('WookieConnectorException');
is( $e, q{No GUID nor widget object}, q{throw NO_WIDGET_GUID} );

$obj = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
eval { $obj->getOrCreateInstance($WIDGET_ID); };
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($WIDGETINSTANCES),
    q{throwing MALFORMED_URL error}
);

TODO: {
    todo_skip
q{Need a live Wookie server for this test. Set the enviroment variable WOOKIE_SERVER if the server isn't in the default location.},
      2
      if !$up;
    $obj = WWW::Wookie::Connector::Service->new( $SERVER, $INVALID . $API_KEY,
        $SHARED_DATA_KEY, $LOGIN, $SCREEN );
    eval { $obj->getOrCreateInstance($WIDGET_ID); };
    $e = Exception::Class->caught('WookieConnectorException');
    is( $e->error, q{Invalid API key}, q{throwing INVALID_API_KEY error} );

    $obj =
      WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
        $LOGIN, $SCREEN );
    my $instance = $obj->getOrCreateInstance($WIDGET_ID);
    $obj = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
        $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
    eval { $obj->getUsers($instance); };
    $e = Exception::Class->caught('WookieConnectorException');
    is(
        $e->error,
        q{URL for supplied Wookie Server is malformed: }
          . $obj->getConnection->getURL
          . URI::Escape::uri_escape($PARTICIPANTS),
        q{throwing MALFORMED_URL error}
    );
}

# TODO: Skipping hard to trap HTTP 404 response code exception.
#eval {
#    $obj->getUsers($instance);
#};
#$e = Exception::Class->caught('WookieConnectorException');
#like(
#    $e->error,
#    qr/\b404\b/,
#    q{throw HTTP error}
#);

$obj = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
eval {
    $obj->addProperty(
        WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::Widget::Property->new(q{foo}, q{bar}, 0)
    );
};
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{Properties rest URL is incorrect: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($PROPERTIES),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error}
);

$obj =
  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
    $LOGIN, $SCREEN );
eval { $obj->deleteProperty; };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e->error, q{No Widget instance}, q{throwing NO_WIDGET_INSTANCE error} );

eval { $obj->deleteProperty( WWW::Wookie::Widget::Instance->new() ); };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error} );
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error}
);

$obj = WWW::Wookie::Connector::Service->new( $INVALID . $SERVER,
    $API_KEY, $SHARED_DATA_KEY, $LOGIN, $SCREEN );
eval {
    $obj->deleteProperty(
        WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::Widget::Property->new()
    );
};
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{Properties rest URL is incorrect: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($PROPERTIES),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error}
);

eval { $obj->getAvailableServices; };
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($SERVICES),
    q{throwing MALFORMED_URL error requesting services}
);

eval { $obj->getAvailableWidgets; };
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{URL for supplied Wookie Server is malformed: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($WIDGETS),
    q{throwing MALFORMED_URL error requesting widgets}
);

eval { $obj->setProperty; };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error setting property}
);

eval { $obj->setProperty( WWW::Wookie::Widget::Instance->new() ); };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error setting property} );
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error setting property}
);

eval {
    $obj->setProperty(
        WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::Widget::Property->new(q{foo}, q{bar}, 0)
    );
};
is(
    $e->error,
    q{No properties instance},
    q{throwing NO_PROPERTY_INSTANCE error setting property}
);

# TODO: Skipping hard to trap HTTP response code exception.

eval { $obj->addParticipant; };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error adding participant}
);

eval {
    $obj->addParticipant( WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::User->new() );
};
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error adding participant} );
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{Participants rest URL is incorrect: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($PARTICIPANTS),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error adding participant}
);

eval { $obj->deleteParticipant; };
$e = Exception::Class->caught('WookieWidgetInstanceException');
is(
    $e->error,
    q{No Widget instance},
    q{throwing NO_WIDGET_INSTANCE error deleting participant}
);

eval {
    $obj->deleteParticipant( WWW::Wookie::Widget::Instance->new(),
        WWW::Wookie::User->new() );
};
$e = Exception::Class->caught('WookieWidgetInstanceException');
is( $e, undef, q{not throwing NO_WIDGET_INSTANCE error deleting participant} );
$e = Exception::Class->caught('WookieConnectorException');
is(
    $e->error,
    q{Participants rest URL is incorrect: }
      . $obj->getConnection->getURL
      . URI::Escape::uri_escape($PARTICIPANTS),
    q{throwing INCORRECT_PARTICIPANTS_REST_URL error deleting participant}
);

# Skipping hard to trap HTTP response code exception.

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
