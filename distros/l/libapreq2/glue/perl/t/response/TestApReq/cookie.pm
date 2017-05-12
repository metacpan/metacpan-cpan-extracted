package TestApReq::cookie;

use strict;
use warnings FATAL => 'all';

use Apache2::RequestIO ();
use Apache2::RequestRec ();

use Apache2::Const -compile => qw(OK);

use Apache2::Cookie ();
use Apache2::Request ();

sub handler {
    my $r = shift;
    my $req = Apache2::Request->new($r);
    my %cookies = eval { Apache2::Cookie->fetch($r) };

    $r->content_type('text/plain');
    my $test = $req->APR::Request::args('test');
    my $key  = $req->APR::Request::args('key');

    if ($test eq 'cookies') {
        my $jar = Apache2::Cookie::Jar->new($r);

        if ($key eq 'first') {
            my $cookie = $jar->cookies('one');
            $r->print($cookie->as_string());
        }
        elsif ($key eq 'all') {
            my @cookies = $jar->cookies('two');
            $r->print(join ' ', map { $_->as_string() } @cookies);
        }
        else {
            my @names = $jar->cookies();
            $r->print(join ' ', map { $_ } @names);
        }
    }
    elsif ($test eq 'overload') {
        $r->print($cookies{one});
    }
    elsif ($test eq 'wordpress') {
        $r->print("ok") if $@;
    }
    elsif ($key and $cookies{$key}) {
        if ($test eq "bake") {
            $cookies{$key}->bake($r);
        }
        elsif ($test eq "bake2") {
            $cookies{$key}->bake2($r);
        }
        $r->print($cookies{$key}->value);
    }
    else {
        my @expires;
        @expires = ("expires", $req->APR::Request::args('expires'))
            if $req->APR::Request::args('expires');
        my $cookie = Apache2::Cookie->new($r, name => "foo",
                                             value => $test,
                                            domain => "example.com",
                                              path => "/quux",
                                          @expires);

        if ($test eq "bake" or $test eq "") {
            $cookie->bake($req);
        }
        elsif ($test eq "bake2") {
            $cookie->version(1);
            $cookie->bake2($req);
        }
        elsif ($test eq 'httponly'){
            $cookie->httponly(1);
            $cookie->bake($req);
        }
        $r->print($cookie->value);
    }


    return Apache2::Const::OK;
}

1;

__END__
