use strict;
use warnings;

BEGIN { *CORE::GLOBAL::gmtime = sub(;$) { CORE::gmtime(1440938160) } }

use HTTP::Request;
use Test::More;
use WebService::S3::Tiny;

{
    no warnings 'redefine';

    *HTTP::Tiny::request = sub { $_[3]{headers}{authorization} };
}

sub slurp($) { local ( @ARGV, $/ ) = @_; scalar <> }

my $s3 = WebService::S3::Tiny->new(
    access_key => 'AKIDEXAMPLE',
    host       => 'example.amazonaws.com',
    region     => 'us-east-1',
    secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
    service    => 'service',
);

chdir 't/aws';

for (<{get,post}-*>) {
    utf8::decode my $foo = slurp "$_/$_.req";

    my ( $method, $path, $headers ) =
        $foo =~ m(^(GET|POST) (.+) HTTP/1.1\n(.+))s;

    ( $path, my $query ) = split /\?/, $path;

    my %query;

    for ( split /&/, $query // '' ) {
        my ( $k, $v ) = split /=/;

        push @{ $query{$k} }, $v;
    }

    ( $headers, my $content ) = split /\n\n/, $headers;

    my $req = HTTP::Request->parse( slurp "$_/$_.req" );

    my %headers = %{ $req->headers };

    delete $headers{'::std_case'};

    is +$s3->request(
        $req->method,
        $path,
        undef,
        $req->content,
        \%headers,
        \%query,
    ) => slurp "$_/$_.authz", $_;
}

done_testing;
