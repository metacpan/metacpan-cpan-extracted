#!perl -w
use strict;
use Text::Clevy;
use File::Basename qw(dirname);
use Plack::Request;

my $path = dirname(__FILE__);
my $tx = Text::Clevy->new(
    path      => [$path],
    cache_dir =>  $path,
);

sub app {
    my($env) = @_;
    my $req  = Plack::Request->new($env);
    my $res  = $req->new_response(200);

    my %vars = (
        title => "Testing <Clevy>",

        ids   => [100, 101, 102],
        names => [qw(Apple Banana Strowberry)],
    );

    $res->content_type('text/html');
    my $body = $tx->render('form.tpl', \%vars, request => $req);
    utf8::encode($body);
    $res->body($body);
    return $res->finalize();
}

return \&app;
