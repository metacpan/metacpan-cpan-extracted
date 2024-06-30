# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use Test::NoWarnings;
use Readonly;

our $VERSION = v1.1.5;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $TEST_WARNINGS => $ENV{'AUTHOR_TESTING'}
## no critic (RequireCheckingReturnValueOfEval)
  && eval { require Test::NoWarnings };

BEGIN {
    Readonly::Scalar my $BASE_TESTS => 11;
## no critic (RequireExplicitInclusion)
    %MAIN::METHODS = (
## use critic
        'WWW::Wookie::Widget' =>
          [qw(getIdentifier getTitle getDescription getIcon)],
        'WWW::Wookie::Widget::Category' => [qw(getName get put)],
        'WWW::Wookie::Widget::Instance' => [
            qw(getUrl setUrl getIdentifier setIdentifier getTitle setTitle
              getHeight setHeight getWidth setHeight),
        ],
        'WWW::Wookie::Widget::Instances' => [qw(put get)],
        'WWW::Wookie::Widget::Property'  =>
          [qw(getName setName getValue setValue getIsPublic setIsPublic)],
        'WWW::Wookie::Connector::Service' => [
            qw(getConnection getProperty getOrCreateInstance getUsers getLocale
              setLocale getUser setUser addProperty deleteProperty
              getAvailableWidgets setProperty addParticipant deleteParticipant),
        ],
        'WWW::Wookie::Server::Connection' =>
          [qw(getURL getApiKey getSharedDataKey as_string test)],
        'WWW::Wookie::User' => [
            qw(getLoginName setLoginName getScreenName setScreenName
              getThumbnailUrl setThumbnailUrl),
        ],
    );
    my $total_methods = 0;
## no critic (RequireExplicitInclusion)
    foreach my $methods ( values %MAIN::METHODS ) {
## use critic
        $total_methods += @{$methods};
    }
    Test::More::plan 'tests' => 1 +
      $BASE_TESTS +
      ( keys(%MAIN::METHODS) * 2 ) +
      $total_methods + 1 +
      ( $ENV{'AUTHOR_TESTING'} ? 0 : 1 );
    Test::More::ok(1);    # If we made it this far, we're ok.
    Test::More::use_ok('WWW::Wookie');
    Test::More::use_ok('WWW::Wookie::Widget');
    Test::More::use_ok('WWW::Wookie::Widget::Category');
    Test::More::use_ok('WWW::Wookie::Widget::Instance');
    Test::More::use_ok('WWW::Wookie::Widget::Instances');
    Test::More::use_ok('WWW::Wookie::Widget::Property');
    Test::More::use_ok('WWW::Wookie::Connector::Exceptions');
    Test::More::use_ok('WWW::Wookie::Connector::Service');
    Test::More::use_ok('WWW::Wookie::Connector::Service::Interface');
    Test::More::use_ok('WWW::Wookie::Server::Connection');
    Test::More::use_ok('WWW::Wookie::User');
}
Test::More::new_ok('WWW::Wookie::Widget');
Test::More::new_ok('WWW::Wookie::Widget::Category');
Test::More::new_ok('WWW::Wookie::Widget::Instance');
Test::More::new_ok('WWW::Wookie::Widget::Instances');
Test::More::new_ok('WWW::Wookie::Widget::Property');
Test::More::new_ok('WWW::Wookie::Connector::Service');
Test::More::new_ok('WWW::Wookie::Server::Connection');
Test::More::new_ok('WWW::Wookie::User');

my $sub;
## no critic (RequireExplicitInclusion)
@WWW::Wookie::Widget::Sub::ISA = qw(WWW::Wookie::Widget);
$sub                           = Test::More::new_ok('WWW::Wookie::Widget::Sub');
@WWW::Wookie::Widget::Category::Sub::ISA = qw(WWW::Wookie::Widget::Category);
$sub = Test::More::new_ok('WWW::Wookie::Widget::Category::Sub');
@WWW::Wookie::Widget::Instance::Sub::ISA = qw(WWW::Wookie::Widget::Instance);
$sub = Test::More::new_ok('WWW::Wookie::Widget::Instance::Sub');
@WWW::Wookie::Widget::Instances::Sub::ISA = qw(WWW::Wookie::Widget::Instances);
$sub = Test::More::new_ok('WWW::Wookie::Widget::Instances::Sub');
@WWW::Wookie::Widget::Property::Sub::ISA = qw(WWW::Wookie::Widget::Property);
$sub = Test::More::new_ok('WWW::Wookie::Widget::Property::Sub');
@WWW::Wookie::Connector::Service::Sub::ISA =
  qw(WWW::Wookie::Connector::Service);
$sub = Test::More::new_ok('WWW::Wookie::Connector::Service::Sub');
@WWW::Wookie::Server::Connection::Sub::ISA =
  qw(WWW::Wookie::Server::Connection);
$sub = Test::More::new_ok('WWW::Wookie::Server::Connection::Sub');
@WWW::Wookie::User::Sub::ISA = qw(WWW::Wookie::User);
$sub                         = Test::More::new_ok('WWW::Wookie::User::Sub');

foreach my $module ( keys %MAIN::METHODS ) {
    foreach my $method ( @{ $MAIN::METHODS{$module} } ) {
        Test::More::can_ok( $module, $method );
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
