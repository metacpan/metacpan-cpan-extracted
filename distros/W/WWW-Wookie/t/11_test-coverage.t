use Test::More;
eval "use Test::TestCoverage 0.08";
plan skip_all => "Test::TestCoverage 0.08 required for testing test coverage"
  if $@;

plan tests => 8;
my $TEST            = q{TEST};
my $API_KEY         = $TEST;
my $SHARED_DATA_KEY = q{localhost_dev};
my $SERVER          = $ENV{WOOKIE_SERVER} || q{http://localhost:8080/wookie/};
my $LOCALE          = q{en_US};

my $obj;

	TODO: {
		todo_skip
	q{Fails on calling add_method on an immutable Moose object},
		  8
		  if 1;

	test_coverage("WWW::Wookie::Widget");
	$obj = WWW::Wookie::Widget->new( $TEST, $TEST, $TEST, $TEST );
	$obj->getIdentifier;
	$obj->getTitle;
	$obj->getDescription;
	$obj->getIcon;
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::Widget');

	test_coverage("WWW::Wookie::Widget::Category");
	$obj = WWW::Wookie::Widget::Category->new($TEST);
	$obj->getName;
	$obj->get;
	$obj->put(WWW::Wookie::Widget->new( $TEST, $TEST, $TEST, $TEST ));
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::Widget::Category');

	test_coverage("WWW::Wookie::Widget::Instance");
	$obj = WWW::Wookie::Widget::Instance->new( $TEST, $TEST, $TEST, 1, 1 );
	$obj->getUrl;
	$obj->setUrl($TEST);
	$obj->getIdentifier;
	$obj->setIdentifier($TEST);
	$obj->getTitle;
	$obj->setTitle($TEST);
	$obj->getHeight;
	$obj->setHeight(1);
	$obj->getWidth;
	$obj->setWidth(1);
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::Widget::Instance');

	test_coverage("WWW::Wookie::Widget::Instances");
	$obj = WWW::Wookie::Widget::Instances->new();
	$obj->put( WWW::Wookie::Widget::Instance->new( $TEST, $TEST, $TEST, 1, 1 ) );
	$obj->get;
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::Widget::Instances');

	test_coverage("WWW::Wookie::Widget::Property");
	$obj = WWW::Wookie::Widget::Property->new( $TEST, $TEST, 0 );
	$obj->getName;
	$obj->setName($TEST);
	$obj->getValue;
	$obj->setValue($TEST);
	$obj->getIsPublic;
	$obj->setIsPublic(1);
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::Widget::Property');

	test_coverage("WWW::Wookie::User");
	$obj = WWW::Wookie::User->new();
	$obj->getLoginName;
	$obj->setLoginName($TEST);
	$obj->getScreenName;
	$obj->setScreenName($TEST);
	$obj->getThumbnailUrl;
	$obj->setThumbnailUrl($TEST);
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::User');

	test_coverage("WWW::Wookie::Server::Connection");
	$obj = WWW::Wookie::Server::Connection->new( $SERVER, $TEST, $TEST );
	$obj->getURL;
	$obj->getApiKey;
	$obj->getSharedDataKey;
	$obj->as_string;
	my $string = "$obj";
	my $up = $obj->test;
	$obj->DESTROY();
	$obj->meta();
	ok_test_coverage('WWW::Wookie::Server::Connection');

	TODO: {
		todo_skip
	q{Need a live Wookie server for this test. Set the enviroment variable WOOKIE_SERVER if the server isn't in the default location.},
		  1
		  if !$up;
		test_coverage("WWW::Wookie::Connector::Service");

		$obj =
		  WWW::Wookie::Connector::Service->new( $SERVER, $API_KEY, $SHARED_DATA_KEY,
			$TEST, $TEST );
		$obj->getLogger;
		$obj->getConnection;
		$obj->setLocale($LOCALE);
		$obj->getLocale;
		my @services = $obj->getAvailableServices;
		foreach my $service (@services) {
			$service->getName;
		}
		my @widgets = $obj->getAvailableWidgets;
		my $user    = $obj->getUser;
		foreach my $widget (@widgets) {
			diag( $widget->getIdentifier );
			$obj->getWidget($widget->getIdentifier);
			my $instance = $obj->getOrCreateInstance($widget);
			$obj->getUsers($instance);
			$obj->setUser( $TEST, $TEST );
			my $property = WWW::Wookie::Widget::Property->new( $TEST, $TEST, 0 );
			$obj->WidgetInstances;
			$obj->addProperty( $instance, $property );
			$obj->setProperty( $instance, $property );
			$obj->getProperty( $instance, $property );
			$obj->deleteProperty( $instance, $property );
			$obj->addParticipant( $instance, $user );
			$obj->deleteParticipant( $instance, $user );
		}
		$obj->DESTROY();
		$obj->meta();
		ok_test_coverage('WWW::Wookie::Connector::Service');
	}
}
