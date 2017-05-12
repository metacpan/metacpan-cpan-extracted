use Exception::Class;
use Test::More tests => 11 + 2;
use Test::NoWarnings;
use WWW::Wookie::Connector::Service;
use WWW::Wookie::Server::Connection;

my $LOGIN               = q{ Login };
my $LOGIN_TRIMMED       = q{Login};
my $LOGIN_ALT           = q{ Alternate login };
my $LOGIN_ALT_TRIMMED   = q{Alternate login};
my $SCREEN              = q{ screen };
my $SCREEN_TRIMMED      = q{screen};
my $SCREEN_ALT          = q{ Alternate screen name };
my $SCREEN_ALT_TRIMMED  = q{Alternate screen name};
my $PROPERTY_NAME       = q{Property name};
my $PROPERTY_VALUE_ALT  = q{Alternate property value};
my $PROPERTY_NAME_ALT   = q{Alternate property name};
my $PROPERTY_VALUE      = q{Property value};
my $AVAILABLE_WIDGETS   = 16;
my $UNSUPPORTED_WIDGETS = 1;
my $PUBLIC              = 1;
my $NOT_PUBLIC          = 0;
my $UNSUPPORTED         = q{unsupported};
my $API_KEY             = q{TEST};
my $SHARED_DATA_KEY     = q{localhost_dev};
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
      11
      if !$up;

    $obj =
      WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
        $LOGIN, $SCREEN );
    my @widgets = $obj->getAvailableWidgets(q{all});
    my $widget  = $widgets[0];

    note(q{Widget Instances});
    note(q{GET {wookie}/widgetinstances});

    # Not supported
    note(q{POST {wookie}/widgetinstances {params:instance_params}});
    my $instance = $obj->getOrCreateInstance($widget);
    note(
q{PUT {wookie}/widgetinstances {params:instance_params, action, [cloneshareddatakey]}}
    );

    # TODO: Not in the framework?
    #$obj->stop($instance);
    #$obj->resume($instance);
    #$obj->clone($instance);

    note(q{Widgets});
    note(q{GET {wookie}/widgets{?all=true, locale=language_tag}});
	TODO: {
		todo_skip(q{Deprecated}, 1) if 1;
		is( 0 + @widgets, $AVAILABLE_WIDGETS, q{getAvailableWidgets} );
	}
    note(q{GET {wookie}/widgets/{service_name} {?locale=language_tag}});
    my @unsupported_widgets = $obj->getAvailableWidgets($UNSUPPORTED);
	TODO: {
		todo_skip(q{Deprecated}, 1) if 1;
		is( 0 + @unsupported_widgets, $UNSUPPORTED_WIDGETS,
			q{getAvailableWidgets} );
	}
    note(q{GET {wookie}/widgets/{id} {?locale=language_tag}});
    is( $obj->getWidget( $widget->getIdentifier )->getIdentifier,
        $widget->getIdentifier, q{getWidget} );

	TODO: {
		todo_skip(q{Deprecated}, 1) if 1;
		note(q{Services});
		note(q{GET {wookie}/services {?locale=language_tag}});
		my @services = $obj->getAvailableServices();
		is( 0 + @services, 5, q{getAvailableServices} );
		note(q{GET {wookie}/services/{service_name} {?locale=language_tag}});
		my @unsupported_services = $obj->getAvailableServices($UNSUPPORTED);
	}
    note(q{POST {wookie}/services/ {param:name}});

    # Requires widgetadmin role
    note(q{PUT {wookie}/services/{service_name} {param:name}});

    # Requires widgetadmin role
    note(q{DELETE {wookie}/services/{service_name}});

    # Requires widgetadmin role

    note(q{Participants});
    note(q{GET {wookie}/participants});

    # Not supported
    note(q{GET {wookie}/participants {params: instance_params}});
    my @participants = $obj->getUsers($instance);
    is( 0 + @participants, 1, q{getUsers} );
    note(q{GET {wookie}/participants {params:id_key, api_key}});
    @participants = $obj->getUsers( $instance->getIdentifier );
    is( 0 + @participants, 1, q{getUsers} );
  TODO: {
        todo_skip q{Multiuser is broken}, 2
          if 1;
        note(
q{POST {wookie}participants {params: instance_params, participant_id, participant_display_name, participant_thumbnail_url}}
        );
        $obj->addParticipant( $instance,
            WWW::Wookie::User->new( q{testuser}, q{testuser} ) );
        @participants = $obj->getUsers( $instance->getIdentifier );
        is( 0 + @participants, 3, q{addParticipant} );
        note(
q{DELETE {wookie}/participants {params: instance_params, participant_id}}
        );
        $obj->deleteParticipant( $instance,
            WWW::Wookie::User->new( q{testuser2}, q{testuser2} ) );
        @participants = $obj->getUsers( $instance->getIdentifier );
        is( 0 + @participants, 2, q{addParticipant} );
    }

    note(q{Properties});
    note(q{GET {wookie}/properties});

    # Not supported
    note(q{GET {wookie}/properties {params: instance_params, propertyname}});
    my $property = WWW::Wookie::Widget::Property->new( q{foo}, q{bar}, 0 );
    $obj->addProperty( $instance, $property );
    is( $obj->getProperty( $instance, $property )->getName,
        q{foo}, q{getProperty} );
    note(
q{POST {wookie}/properties {params: instance_params, propertyname, propertyvalue, [is_public=true]}}
    );
    note(
q{PUT {wookie}/properties {params: instance_params, propertyname, propertyvalue}}
    );
    $property = WWW::Wookie::Widget::Property->new( q{foo}, q{baz}, 0 );
    $obj->setProperty( $instance, $property );
    is( $obj->getProperty( $instance, $property )->getValue,
        q{baz}, q{setProperty} );

    note(q{DELETE {wookie}/properties {params: instance_params, propertyname}});

  TODO: {
        todo_skip( q{Delete is broken on server}, 1 ) if 1;
		$obj->deleteProperty( $instance, $property );
		eval { $obj->getProperty( $instance, $property ); };
		$e = Exception::Class->caught('WookieConnectorException');
		like( $e->error, qr/\b404\b/, q{deleting private property} );
	}
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
