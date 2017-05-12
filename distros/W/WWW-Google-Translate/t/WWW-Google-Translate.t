use strict;
use warnings;
use Test::More 'no_plan';

my $Uri;

BEGIN {
    use_ok('WWW::Google::Translate');

    no warnings qw( redefine );

    *Mock::Response::is_success  = sub { return 1; };
    *Mock::Response::content     = sub { return "{}"; };
    *Mock::Response::code        = sub { return 200; };
    *Mock::Response::header      = sub { 'no-cache'; };
    *Mock::Response::status_line = sub { 'OK'; };

    *LWP::UserAgent::get = sub {
        $Uri = $_[1];
        my $response = 'Mock::Response';
        return bless \$response, $response;
    };
}

# translate
{
    my %arg = (
        source      => 'en',
        target      => 'ja',
        format      => 'text',
        q           => 'hello',
        prettyprint => 1,
    );
    rest_ok( 'translate', \%arg );
}

# languages
{
    my %arg = ( target => 'ja', );
    rest_ok( 'languages', \%arg );
}

# detect
{
    my %arg = ( q => 'hello', );
    rest_ok( 'detect', \%arg );
}

sub rest_ok {
    my ( $method, $arg_rh ) = @_;

    my %expect = (
        key => 'mock API key',
        %{$arg_rh},
    );

    my $comment = "correct $method REST call";

    my $gt = WWW::Google::Translate->new( { key => $expect{key} } );

    $Uri = undef;

    $gt->$method($arg_rh);

    die "failed to call LWP::UserAgent::get"
        if !$Uri;

    my %got = $Uri->query_form();

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return is_deeply( \%got, \%expect, $comment );
}

__END__
