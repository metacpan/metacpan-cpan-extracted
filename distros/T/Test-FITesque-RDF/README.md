# NAME

Test::FITesque::RDF - Formulate Test::FITesque fixture tables in RDF

# SYNOPSIS

    my $suite = Test::FITesque::RDF->new(source => $file)->suite;
    $suite->run_tests;

See `t/integration-basic.t` for a full test script example.

# DESCRIPTION

This module enables the use of Resource Description Framework to
describe fixture tables. It will take the filename of an RDF file and
return a [Test::FITesque::Suite](https://metacpan.org/pod/Test::FITesque::Suite) object that can be used to run
tests.

The RDF serves to identify the implementation of certain fixtures, and
can also supply parameters that can be used by the tests, e.g. input
parameters or expectations. See [Test::FITesque](https://metacpan.org/pod/Test::FITesque) for more on how the
fixtures are implemented.

## ATTRIBUTES AND METHODS

This module implements the following attributes and methods:

- `source`

    Required attribute to the constructor. Takes a [Path::Tiny](https://metacpan.org/pod/Path::Tiny) object
    pointing to the RDF file containing the fixture tables. The value will
    be converted into an appropriate object, so a string can also be
    supplied.

- `suite`

    Will return a [Test::FITesque::Suite](https://metacpan.org/pod/Test::FITesque::Suite) object, based on the RDF data supplied to the constructor.

- `transform_rdf`

    Will return an arrayref containing tests in the structure used by
    [Test::FITesque::Test](https://metacpan.org/pod/Test::FITesque::Test). Most users will rather call the `suite`
    method than to call this method directly.

- `base_uri`

    A [IRI](https://metacpan.org/pod/IRI) to use in parsing the RDF fixture tables to resolve any relative URIs.

## REQUIRED RDF

The following must exist in the test description (see below for an example and prefix expansions):

- `test:fixtures`

    The object(s) of this predicate lists the test fixtures that will run
    for this test suite. May take an RDF List. Links to the test
    descriptions, which follow below.

- `test:test_script`

    The object of this predicate points to information on how the actual
    test will be run. That is formulated in a separate resource which
    requires two predicates, `deps:test-requirement` predicate, whose
    object contains the class name of the implementation of the tests; and
    `nfo:definesFunction` whose object is a string which matches the
    actual function name within that class.

- `test:purpose`

    The object of this predicate provides a literal description of the test.

- `test:params`

    The object of this predicate links to the parameters, which may have
    many different shapes. See below for examples.

## PARAMETERIZATION

This module seeks to parameterize the tests, and does so using mostly
the `test:params` predicate above. This is passed on as a hashref to
the test scripts.

There are two main ways currently implemented, one creates key-value
pairs, and uses predicates and objects for that respectively, in
vocabularies chosen by the test writer. The other main way is create
lists of HTTP requests and responses.

If the object of a test parameter is a literal, it will be passed as a
plain string, if it is a [Attean::IRI](https://metacpan.org/pod/Attean::IRI), it will be passed as a [URI](https://metacpan.org/pod/URI)
object.

Additionally, a special parameter `-special` is passed on for
internal framework use. The leading dash is not allowed as the start
character of a local name, and therefore chosen to avoid conflicts
with other parameters.

The literal given in `test:purpose` above is passed on as with the
`description` key in this hashref.

## RDF EXAMPLE

The below example starts with prefix declarations. Then, the
tests in the fixture table are listed explicitly. Only tests mentioned
using the `test:fixtures` predicate will be used. Tests may be an RDF
List, in which case, the tests will run in the specified sequence, if
not, no sequence may be assumed.

Then, two test fixtures are declared. The actual implementation is
referenced through `test:test_script` for both functions.

The `test:params` predicate is used to link the parameters that will
be sent as a hashref into the function. The &lt;test:purpose> predicate
is required to exist outside of the parameters, but will be included
as a parameter as well, named `description` in the `-special`
hashref.

There are two mechanisms for passing parameters to the test scripts,
one is simply to pass arbitrary key-value pairs, the other is to pass
lists of HTTP request-response objects. Both mechanisms may be used.

### Key-value parameters

The key of the hashref passed as arguments will be the local part of
the predicate used in the description (i.e. the part after the colon
in e.g. `my:all`). It is up to the test writer to mint the URIs of
the parameters.

The test writer may optionally use a `param_base` to indicate the
namespace, in which case the the local part is resolved by the
framework, using [URI::NamespaceMap](https://metacpan.org/pod/URI::NamespaceMap). If `param_base` is not given,
the full URI will be passed to the test script.

    @prefix test: <http://ontologi.es/doap-tests#> .
    @prefix deps: <http://ontologi.es/doap-deps#>.
    @prefix dc:   <http://purl.org/dc/terms/> .
    @prefix my:   <http://example.org/my-parameters#> .
    @prefix nfo:  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .
    @prefix :     <http://example.org/test#> .


    :test_list a test:FixtureTable ;
       test:fixtures :test1, :test2 .

    :test1 a test:AutomatedTest ;
       test:param_base <http://example.org/my-parameters#> ;
       test:purpose "Echo a string"@en ;
       test:test_script <http://example.org/simple#string_found> ;
       test:params [ my:all "counter-clockwise dahut" ] .

    :test2 a test:AutomatedTest ;
       test:param_base <http://example.org/my-parameters#> ;
       test:purpose "Multiply two numbers"@en ;
       test:test_script <http://example.org/multi#multiplication> ;
       test:params [
           my:factor1 6 ;
           my:factor2 7 ;
           my:product 42
       ] .

    <http://example.org/simple#string_found> a nfo:SoftwareItem ;
       nfo:definesFunction "string_found" ;
       deps:test-requirement "Internal::Fixture::Simple"^^deps:CpanId .

    <http://example.org/multi#multiplication> a nfo:SoftwareItem ;
       nfo:definesFunction "multiplication" ;
       deps:test-requirement "Internal::Fixture::Multi"^^deps:CpanId .

### HTTP request-response lists

To allow testing HTTP-based interfaces, this module also allows the
construction of an ordered list of HTTP requests and response pairs.
With those, the framework will construct [HTTP::Request](https://metacpan.org/pod/HTTP::Request) and
[HTTP::Response](https://metacpan.org/pod/HTTP::Response) objects. In tests scripts, the request
objects will typically be passed to the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) as input,
and then the response from the remote server will be compared with the
asserted [HTTP::Response](https://metacpan.org/pod/HTTP::Response)s made by the test fixture.

We will go through an example in chunks:

    @prefix test: <http://ontologi.es/doap-tests#> .
    @prefix deps: <http://ontologi.es/doap-deps#>.
    @prefix httph:<http://www.w3.org/2007/ont/httph#> .
    @prefix http: <http://www.w3.org/2007/ont/http#> .
    @prefix nfo:  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .
    @prefix :     <http://example.org/test#> .

    :test_list a test:FixtureTable ;
       test:fixtures :public_writeread_unauthn_alt .

    :public_writeread_unauthn_alt a test:AutomatedTest ;
       test:purpose "To test if we can write first using HTTP PUT then read with GET"@en ;
       test:test_script <http://example.org/httplist#http_req_res_list_unauthenticated> ;
       test:params [
           test:steps (
               [
                   test:request :public_writeread_unauthn_alt_put_req ;
                   test:response_assertion :public_writeread_unauthn_alt_put_res
               ]
               [
                   test:request :public_writeread_unauthn_alt_get_req ;
                   test:response_assertion :public_writeread_unauthn_alt_get_res
               ]
           )
       ] .

    <http://example.org/httplist#http_req_res_list_unauthenticated> a nfo:SoftwareItem ;
       deps:test-requirement "Example::Fixture::HTTPList"^^deps:CpanId ;
       nfo:definesFunction "http_req_res_list_unauthenticated" .

In the above, after the prefixes, a single test is declared using the
`test:fixtures` predicate, linking to a description of the test. The
test is then described as an &lt;test:AutomatedTest>, and it's purpose is
declared. It then links to its concrete implementation, which is given
in the last three triples in the above.

Then, the parameterization is started. In this example, there are two
HTTP request-response pairs, which are given as a list object to the
`test:steps` predicate.

To link the request, the `test:request` predicate is used, to link
the asserted response, the `test:response_assertion` predicate is
used.

Next, we look into the actual request and response messages linked from the above:

    :public_writeread_unauthn_alt_put_req a http:RequestMessage ;
       http:method "PUT" ;
       httph:content_type "text/turtle" ;
       http:content "</public/foobar.ttl#dahut> a <http://example.org/Cryptid> ." ;
       http:requestURI </public/foobar.ttl> .

    :public_writeread_unauthn_alt_put_res a http:ResponseMessage ;
       http:status 201 .

    :public_writeread_unauthn_alt_get_req a http:RequestMessage ;
       http:method "GET" ;
       http:requestURI </public/foobar.ttl> .

    :public_writeread_unauthn_alt_get_res a http:ResponseMessage ;
       httph:accept_post  "text/turtle", "application/ld+json" ;
       httph:content_type "text/turtle" .

These should be self-explanatory, but note that headers are given with
lower-case names and underscores. They will be transformed to headers
by replacing underscores with dashes and upcase the first letters.

This module will transform the above to data structures that are
suitable to be passed to [Test::Fitesque](https://metacpan.org/pod/Test::Fitesque), and the above will appear as

    {
           '-special' => {
                                                   'http-pairs' => [
                                      {
                                                                                         'request'  => ... ,
                                                                                         'response' => ... ,
                                      },
                                      { ... }
                                     ]
                                                                                    },
                                                   'description' => 'To test if we can write first using HTTP PUT then read with GET'
                                             },
    }

Note that there are more examples in this module's test suite in the
`t/data/` directory.

You may maintain client state in a test script (i.e. for one
`test:AutomatedTest`, as it is simply one script, so the result of
one request may be used to influence the next. Server state can be
relied on between different tests by using an `rdf:List` of test
fixtures if it writes something into the server, there is nothing in
the framework that changes that.

To use data from one response to influence subsequent requests, the
framework supports datatyping literals with the `dqm:regex` datatype,
for example:

    :check_acl_location_res a http:ResponseMessage ;
       httph:link '<(.*?)>;\\s+rel="acl"'^^dqm:regex ;
       http:status 200 .

This makes it possible to use a Perl regular expression, which can be
executed in a test script if desired. If present, it will supply
another hashref to the `http-pairs` key with the key `regex-fields`
containing hashrefs with the header field that had a correspondiing
object datatyped regex as key and simply `1` as value.

# TODO

Separate the implementation-specific details (such as `deps:test-requirement`)
from the actual fixture tables.

# BUGS

Please report any bugs to
[https://github.com/kjetilk/p5-test-fitesque-rdf/issues](https://github.com/kjetilk/p5-test-fitesque-rdf/issues).

# SEE ALSO

# AUTHOR

Kjetil Kjernsmo <kjetilk@cpan.org>.

# COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

    The MIT (X11) License

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
