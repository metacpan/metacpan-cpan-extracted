use Test::More tests => 3;

BEGIN {
    use_ok( 'XML::Atom::App' );
}

diag( "Testing XML::Atom::App $XML::Atom::App::VERSION" );

my $feed = XML::Atom::App->new();
diag "Here comes a \"Can't locate object method\" carp():";
$feed->alert_cant( 'this is a test', bless({},'this should be a thrown warning') );

{
    eval 'use CGI::Carp';
    plan skip_all => 'CGI::Carp required for testing default alert_cant() return' if $@;
    no warnings;
    local $CGI::Carp::WARN = 0;
    local $CGI::Carp::EMIT_WARNINGS = 0;

    eval q(sub CGI::Carp::realwarn {my $mess = shift; return $mess});
    like($feed->alert_cant('meth', bless({},'NS')), qr/Can't locate object method "meth" via package "NS"/, "default alert_cant() return ok");
}

$feed->{'alert_cant'} = sub {
    shift;
    return join(',', @_);
};

ok($feed->alert_cant( 'a', 'b' ) eq 'a,b', 'custom alert_cant()')