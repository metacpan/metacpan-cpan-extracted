use Test::Lib;
use Test::WebService::ValidSign;

use File::Temp;
use HTTP::Response;
use WebService::ValidSign::Object::Document;
use WebService::ValidSign::Object::DocumentPackage;

my $vs = WebService::ValidSign->new(
    secret => 'foo'
);

my $api = $vs->package;


sub lwp_response {
    my %params = (
        code    => 200,
        msg     => 'OK',
        content => '',
        uhh     => [],
        @_
    );

    return HTTP::Response->new(
        $params{code},
        $params{msg},
        $params{uhh},
        $params{content}
    );

}

{
    note "Testing create";

    my $request;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            my $self = shift;
            $request = shift;
            return lwp_response(content => '{"id":42}');
        }
    );

    my $package = WebService::ValidSign::Object::DocumentPackage->new(
        name => "Package foo"
    );

    my $result = $api->create($package);

    is($package->id, 42, "Our package now has an ID");

    is($request->method, 'POST', "We have a post method");
    is(
        $request->uri,
        'https://try.validsign.nl/api/packages',
        ".. with a correct endpoint"
    );
    is(
        $request->headers->header('Content-type'),
        'application/json',
        ".. and content type is correct"
    );
    is($request->headers->header('accept'),
        'application/json', ".. and we only accept JSON");

    throws_ok(sub {
            $api->create($package);
        },
        qr/Package is already created, it has an ID/,
    );

    my $document = WebService::ValidSign::Object::Document->new(
        name => "Document foo",
    );

}

{
    note "Testing create_with_document";

    my $request;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            my $self = shift;
            $request = shift;
            return lwp_response(content => '{"id":42}');
        }
    );

    my $fh = File::Temp->new();
    print $fh "Some content";
    close($fh);
    $fh->seek(0,0);

    my $document = WebService::ValidSign::Object::Document->new(
        name => "Document foo",
        path => $fh,
    );

    my $package = WebService::ValidSign::Object::DocumentPackage->new(
        name => "Package foo"
    );

    $package->add_document($document);
    my $result = $api->create_with_documents($package);

    is($package->id, 42, "Our package now has an ID");

    is($request->method, 'POST', "We have a post method");
    is(
        $request->uri,
        'https://try.validsign.nl/api/packages',
        ".. with a correct endpoint"
    );
    is(
        $request->headers->header('Content-type'),
        'multipart/form-data; boundary=xYzZY',
        ".. and content type is correct"
    );
    is($request->headers->header('accept'),
        'application/json', ".. and we only accept JSON");

    throws_ok(sub {
            $api->create_with_documents($package);
        },
        qr/Package is already created, it has an ID/,
    );
}

{   note "Testing find + download documents";


    use JSON::XS;
    my $request;
    my $jsonxs = JSON::XS->new();

    my $data = {
        id   => 42,
        name => "Mocked package",
        documents => [
            {
                id => 13,
                name => "Foo",
            }
        ],
    };

    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            my $self = shift;
            $request = shift;
            return lwp_response(content => $jsonxs->encode($data));
        }
    );

    my $pkg = $api->find("some");
    isa_ok($pkg, "WebService::ValidSign::Object::DocumentPackage");
    ok($pkg->has_id, ".. and has an ID");
    is($pkg->id, 42, ".. which is 42");
    ok($pkg->has_documents, ".. and has documents");
    is($pkg->count_documents, 1,  "... well, only one");

    # TODO: Coerce json answer in proper document objects, should be tested
    # within the document package unit.

    my $rv = $api->download_document($pkg);
    isa_ok($rv, "File::Temp");
    is($request->method, 'GET', "Download document has correct HTTP method");
    is(
        $request->uri,
        'https://try.validsign.nl/api/packages/42/documents/13/pdf',
        ".. and points to the correct URI"
    );

    $rv = $api->download_documents($pkg);
    isa_ok($rv, "File::Temp");
    is($request->method, 'GET',
        "Download documents (zip) has correct HTTP method");
    is(
        $request->uri,
        'https://try.validsign.nl/api/packages/42/documents/zip',
        ".. and points to the correct URI"
    );

}

done_testing();
