use Test::More;
use Test::NoWarnings;

BEGIN {
    %MAIN::methods = (
        'WWW::Wookie::Widget' =>
          [qw(getIdentifier getTitle getDescription getIcon)],
        'WWW::Wookie::Widget::Category' => [qw(getName get put)],
        'WWW::Wookie::Widget::Instance' => [
            qw(getUrl setUrl getIdentifier setIdentifier getTitle setTitle getHeight setHeight getWidth setHeight)
        ],
        'WWW::Wookie::Widget::Instances' => [qw(put get)],
        'WWW::Wookie::Widget::Property' =>
          [qw(getName setName getValue setValue getIsPublic setIsPublic)],
        'WWW::Wookie::Connector::Service' => [
            qw(getLogger getConnection getProperty getOrCreateInstance getUsers getLocale setLocale getUser setUser addProperty deleteProperty getAvailableWidgets setProperty addParticipant deleteParticipant)
        ],
        'WWW::Wookie::Server::Connection' =>
          [qw(getURL getApiKey getSharedDataKey as_string test)],
        'WWW::Wookie::User' => [
            qw(getLoginName setLoginName getScreenName setScreenName getThumbnailUrl setThumbnailUrl)
        ],
    );
    my $total_methods = 0;
    foreach my $methods ( values %MAIN::methods ) {
        $total_methods += @$methods;
    }
    plan tests => 1 + 11 + ( 8 * 2 ) + $total_methods + 1 + 1;
    ok(1);    # If we made it this far, we're ok.
    use_ok('WWW::Wookie');
    use_ok('WWW::Wookie::Widget');
    use_ok('WWW::Wookie::Widget::Category');
    use_ok('WWW::Wookie::Widget::Instance');
    use_ok('WWW::Wookie::Widget::Instances');
    use_ok('WWW::Wookie::Widget::Property');
    use_ok('WWW::Wookie::Connector::Exceptions');
    use_ok('WWW::Wookie::Connector::Service');
    use_ok('WWW::Wookie::Connector::Service::Interface');
    use_ok('WWW::Wookie::Server::Connection');
    use_ok('WWW::Wookie::User');
}
new_ok('WWW::Wookie::Widget');
new_ok('WWW::Wookie::Widget::Category');
new_ok('WWW::Wookie::Widget::Instance');
new_ok('WWW::Wookie::Widget::Instances');
new_ok('WWW::Wookie::Widget::Property');
new_ok('WWW::Wookie::Connector::Service');
new_ok('WWW::Wookie::Server::Connection');
new_ok('WWW::Wookie::User');

my $sub;
@WWW::Wookie::Widget::Sub::ISA           = qw(WWW::Wookie::Widget);
$sub                                     = new_ok('WWW::Wookie::Widget::Sub');
@WWW::Wookie::Widget::Category::Sub::ISA = qw(WWW::Wookie::Widget::Category);
$sub = new_ok('WWW::Wookie::Widget::Category::Sub');
@WWW::Wookie::Widget::Instance::Sub::ISA = qw(WWW::Wookie::Widget::Instance);
$sub = new_ok('WWW::Wookie::Widget::Instance::Sub');
@WWW::Wookie::Widget::Instances::Sub::ISA = qw(WWW::Wookie::Widget::Instances);
$sub = new_ok('WWW::Wookie::Widget::Instances::Sub');
@WWW::Wookie::Widget::Property::Sub::ISA = qw(WWW::Wookie::Widget::Property);
$sub = new_ok('WWW::Wookie::Widget::Property::Sub');
@WWW::Wookie::Connector::Service::Sub::ISA =
  qw(WWW::Wookie::Connector::Service);
$sub = new_ok('WWW::Wookie::Connector::Service::Sub');
@WWW::Wookie::Server::Connection::Sub::ISA =
  qw(WWW::Wookie::Server::Connection);
$sub                         = new_ok('WWW::Wookie::Server::Connection::Sub');
@WWW::Wookie::User::Sub::ISA = qw(WWW::Wookie::User);
$sub                         = new_ok('WWW::Wookie::User::Sub');

foreach my $module ( keys %MAIN::methods ) {
    foreach my $method ( @{ $MAIN::methods{$module} } ) {
        can_ok( $module, $method );
    }
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
