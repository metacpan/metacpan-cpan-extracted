use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
use Capture::Tiny 'capture';
use Test::Fatal;
use URI;
use version;

use WebService::Plotly;

eval "use PDL";

run();
done_testing;
exit;

sub run {
    my %user = (
        un       => "api_test",
        key      => "api_key",
        password => "password",
        email    => 'api@test.com',
    );

    # comment and fill this in to run real network tests
    # $user{un}  = '';
    # $user{key} = '';

    {
        no warnings 'redefine';
        *LWP::UserAgent::send_request = fake_responses( \&LWP::UserAgent::send_request, \%user );
    }

    ok my $login = WebService::Plotly->signup( $user{un}, $user{email} ), "signup request returned a response";
    is $login->{api_key}, $user{key},      "response contains the expected api key";
    is $login->{tmp_pw},  $user{password}, "response contains the expected temp password";

    # comment this in to run real network tests
    # $ENV{PLOTLY_TEST_REAL} = 1;

    ok my $py = WebService::Plotly->new( un => $user{un}, key => $user{key} ), "can instantiate plotly object";

    {
        my $url  = "https://plot.ly/~$user{un}/0";
        my $name = "plot from API";

        my $x0 = [ 1,  2,  3,  4 ];
        my $y0 = [ 10, 15, 13, 17 ];
        my $x1 = [ 2,  3,  4,  5 ];
        my $y1 = [ 16, 5,  11, 9 ];
        my ( $out, $err, $response ) = capture {
            $py->plot( $x0, $y0, $x1, $y1 );
        };
        is $out,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err, "", "no error output";
        ok $response, "plot request returned a response";
        is $response->{url},      $url,  "received correct url";
        is $response->{filename}, $name, "received correct filename";
    }

  SKIP: {
        skip "no PDL", 15 if version->parse( PDL->VERSION ) < 2.006;
        my $url  = "https://plot.ly/~$user{un}/1";
        my $name = "plot from API (1)";
        my $box  = {
            y         => ones( 50 ),
            type      => 'box',
            boxpoints => 'all',
            jitter    => 0.3,
            pointpos  => -1.8
        };
        my ( $out, $err, $response ) = capture {
            $py->plot( $box );
        };
        is $out,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err, "", "no error output";
        ok $response, "plot request returned a response";
        is $response->{url},      $url,  "received correct url";
        is $response->{filename}, $name, "received correct filename";
    }

  SKIP: {
        skip "no PDL", 15 if version->parse( PDL->VERSION ) < 2.006;
        require PDL::Constants;
        require Storable;
        require PDL::IO::Storable;

        my $url  = "https://plot.ly/~$user{un}/2";
        my $name = "plot from API (2)";

        my $pdl_data = "t/pdl_data";
        if ( !-f $pdl_data ) {
            my $x1 = zeroes( 50 )->xlinvals( 0, 20 * PDL::Constants::PI() );
            my $y1 = ( sin( $x1 ) * exp( -0.1 * $x1 ) );

            # restrict PDL data to integers to avoid platform porting issues
            Storable::nstore [ ( $x1 * 100 )->long, ( $y1 * 10000 )->long ], $pdl_data;
        }

        my ( $x1, $y1 ) = @{ Storable::retrieve( $pdl_data ) };

        my ( $out, $err, $response ) = capture {
            $py->plot( $x1, $y1 );
        };
        is $out,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err, "", "no error output";
        ok $response, "plot request returned a response";
        is $response->{url},      $url,  "received correct url";
        is $response->{filename}, $name, "received correct filename";

        # Minimal styling of data
        my $datastyle = { 'line' => { 'color' => 'rgb(84, 39, 143)', 'width' => 4 } };

        my ( $out2, $err2, $response2 ) = capture {
            $py->style( $datastyle );
        };
        is $out2,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err2, "", "no error output";
        ok $response2, "plot request returned a response";
        is $response2->{url},      $url,  "received correct url";
        is $response2->{filename}, $name, "received correct filename";

        # Style the Layout
        my $fontlist = qq["Avant Garde", Avantgarde, "Century Gothic", CenturyGothic, "AppleGothic", sans-serif];

        my $layout = {
            'title'         => 'Damped Sinusoid',
            'titlefont'     => { 'family' => $fontlist, 'size' => 25, 'color' => 'rgb(84, 39, 143)' },
            'autosize'      => undef,
            'width'         => 600,
            'height'        => 600,
            'margin'        => { 'l' => 70, 'r' => 40, 't' => 60, 'b' => 60, 'pad' => 2 },
            'paper_bgcolor' => 'rgb(188, 189, 220)',
            'plot_bgcolor'  => 'rgb(158, 154, 200)',
            'font'       => { 'family' => $fontlist, 'size' => 20, 'color' => 'rgb(84, 39, 143)' },
            'showlegend' => undef
        };

        my ( $out3, $err3, $response3 ) = capture {
            $py->layout( $layout );
        };
        is $out3,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err3, "", "no error output";
        ok $response3, "plot request returned a response";
        is $response3->{url},      $url,  "received correct url";
        is $response3->{filename}, $name, "received correct filename";

    }

    {
        my $url    = "https://plot.ly/~$user{un}/2";
        my $name   = "plot from API (2)";
        my $layout = {};
        $py->filename( $name );

        my ( $out3, $err3, $exception ) = capture {
            exception {
                $py->layout( $layout );
            };
        };
        is $out3,        "",                                              "no normal output";
        is $err3,        "",                                              "no error output";
        like $exception, qr/grph = \{'layout': args\[0\]\}\nKeyError: 0/, "proper exception";
    }

    return;
}

sub fake_responses {
    my ( $old, $user ) = @_;
    my $email    = $user->{email};
    my $version  = WebService::Plotly->version || '';
    my @req_vals = ( $user->{key}, $user->{un}, $version );
    my %pairs    = (
        sprintf( q|/apimkacct / {"email":"%s","platform":"Perl","un":"%s","version":"%s"}|,
            $user->{email}, $user->{un}, $version ) =>
qq[{"api_key": "$user->{key}", "message": "", "un": "$user->{un}", "tmp_pw": "$user->{password}", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[[1,2,3,4],[10,15,13,17],[2,3,4,5],[16,5,11,9]]","key":"%s","kwargs":"{\"filename\":null,\"fileopt\":null}","origin":"plot","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/0", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/0 or inside your plot.ly account where it is named 'plot from API'", "warning": "", "filename": "plot from API", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{\"boxpoints\":\"all\",\"jitter\":0.3,\"pointpos\":-1.8,\"type\":\"box\",\"y\":[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]}]","key":"%s","kwargs":"{\"filename\":\"plot from API\",\"fileopt\":null}","origin":"plot","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/1", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/1 or inside your plot.ly account where it is named 'plot from API (1)'", "warning": "", "filename": "plot from API (1)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[[0,128,256,384,512,641,769,897,1025,1154,1282,1410,1538,1666,1795,1923,2051,2179,2308,2436,2564,2692,2821,2949,3077,3205,3333,3462,3590,3718,3846,3975,4103,4231,4359,4487,4616,4744,4872,5000,5129,5257,5385,5513,5642,5770,5898,6026,6154,6283],[0,8432,4221,-4412,-5475,673,4573,1768,-2653,-2696,703,2438,676,-1548,-1298,548,1279,216,-881,-608,377,659,38,-491,-275,242,334,-20,-268,-119,148,166,-31,-144,-47,87,81,-27,-76,-17,50,38,-19,-39,-4,28,17,-13,-20,0]]","key":"%s","kwargs":"{\"filename\":\"plot from API (1)\",\"fileopt\":null}","origin":"plot","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{\"line\":{\"color\":\"rgb(84, 39, 143)\",\"width\":4}}]","key":"%s","kwargs":"{\"filename\":\"plot from API (2)\",\"fileopt\":null}","origin":"style","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{\"autosize\":null,\"font\":{\"color\":\"rgb(84, 39, 143)\",\"family\":\"\\\\\"Avant Garde\\\\\", Avantgarde, \\\\\"Century Gothic\\\\\", CenturyGothic, \\\\\"AppleGothic\\\\\", sans-serif\",\"size\":20},\"height\":600,\"margin\":{\"b\":60,\"l\":70,\"pad\":2,\"r\":40,\"t\":60},\"paper_bgcolor\":\"rgb(188, 189, 220)\",\"plot_bgcolor\":\"rgb(158, 154, 200)\",\"showlegend\":null,\"title\":\"Damped Sinusoid\",\"titlefont\":{\"color\":\"rgb(84, 39, 143)\",\"family\":\"\\\\\"Avant Garde\\\\\", Avantgarde, \\\\\"Century Gothic\\\\\", CenturyGothic, \\\\\"AppleGothic\\\\\", sans-serif\",\"size\":25},\"width\":600}]","key":"%s","kwargs":"{\"filename\":\"plot from API (2)\",\"fileopt\":null}","origin":"layout","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{}]","key":"%s","kwargs":"{\"filename\":\"plot from API (2)\",\"fileopt\":null}","origin":"layout","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "", "message": "", "warning": "", "filename": "", "error": "Traceback (most recent call last):\\n  File \\"/home/jp/dj/shelly/remote/remoteviews.py\\", line 311, in clientresp\\n    grph = {'layout': args[0]}\\nKeyError: 0\\n"}],
    );
    return sub {
        my ( $self, $request ) = @_;

        my $url = URI->new( 'http:' );
        $url->query( $request->content );
        my %form    = $url->query_form;
        my $content = JSON->new->utf8->convert_blessed( 1 )->canonical( 1 )->encode( \%form );

        my $req_string = $request->uri->path . " / " . $content;

        die "unknown request: " . $req_string if !$pairs{$req_string};

        if ( $pairs{$req_string} eq "make" ) {
            my $res = $self->$old( $request );
            return $res if $ENV{PLOTLY_TEST_REAL};
            $DB::single = $DB::single = 1;
            exit;
        }

        my $res = HTTP::Response->new( 200, "OK", undef, $pairs{$req_string} );

        return $res;
    };
}
