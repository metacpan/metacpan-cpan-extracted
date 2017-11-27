# NAME

Test::WWW::Mechanize::PSGI - Test PSGI programs using WWW::Mechanize

# VERSION

version 0.38

# SYNOPSIS

    # We're in a t/*.t test script...
    use Test::WWW::Mechanize::PSGI;

    my $mech = Test::WWW::Mechanize::PSGI->new(
        app => sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/html' ],
                [ '<html><head><title>Hi</title></head><body>Hello World</body></html>'
                ]
            ];
        },
    );
    $mech->get_ok('/');
    is( $mech->ct, 'text/html', 'Is text/html' );
    $mech->title_is('Hi');
    $mech->content_contains('Hello World');
    # ... and all other Test::WWW::Mechanize methods

# DESCRIPTION

[PSGI](https://metacpan.org/pod/PSGI) is a specification to decouple web server environments from
web application framework code. [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) is a subclass
of [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) that incorporates features for web application
testing. The [Test::WWW::Mechanize::PSGI](https://metacpan.org/pod/Test::WWW::Mechanize::PSGI) module meshes the two to
allow easy testing of [PSGI](https://metacpan.org/pod/PSGI) applications.

Testing web applications has always been a bit tricky, normally
requiring starting a web server for your application and making real HTTP
requests to it. This module allows you to test [PSGI](https://metacpan.org/pod/PSGI) web
applications but does not require a server or issue HTTP
requests. Instead, it passes the HTTP request object directly to
[PSGI](https://metacpan.org/pod/PSGI). Thus you do not need to use a real hostname:
"http://localhost/" will do. However, this is optional. The following
two lines of code do exactly the same thing:

    $mech->get_ok('/action');
    $mech->get_ok('http://localhost/action');

This makes testing fast and easy. [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) provides
functions for common web testing scenarios. For example:

    $mech->get_ok( $page );
    $mech->title_is( "Invoice Status", "Make sure we're on the invoice page" );
    $mech->content_contains( "Andy Lester", "My name somewhere" );
    $mech->content_like( qr/(cpan|perl)\.org/, "Link to perl.org or CPAN" );

An alternative to this module is [Plack::Test](https://metacpan.org/pod/Plack::Test).

# CONSTRUCTOR

## new

Behaves like, and calls, [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize)'s `new` method. You should pass
in your application:

    my $mech = Test::WWW::Mechanize::PSGI->new(
        app => sub {
            my $env = shift;
            return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello World'] ],;
        },
    );

# METHODS: HTTP VERBS

## $mech->get\_ok($url, \[ \\%LWP\_options ,\] $desc)

A wrapper around WWW::Mechanize's get(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved `*_ok()` functions, it returns true if the test passed,
or false if not.

A default description of "GET $url" is used if none if provided.

## $mech->head\_ok($url, \[ \\%LWP\_options ,\] $desc)

A wrapper around WWW::Mechanize's head(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved `*_ok()` functions, it returns true if the test passed,
or false if not.

A default description of "HEAD $url" is used if none if provided.

## $mech->post\_ok( $url, \[ \\%LWP\_options ,\] $desc )

A wrapper around WWW::Mechanize's post(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved `*_ok()` functions, it returns true if the test passed,
or false if not.

A default description of "POST to $url" is used if none if provided.

## $mech->put\_ok( $url, \[ \\%LWP\_options ,\] $desc )

A wrapper around WWW::Mechanize's put(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved `*_ok()` functions, it returns true if the test passed,
or false if not.

A default description of "PUT to $url" is used if none if provided.

## $mech->submit\_form\_ok( \\%params \[, $desc\] )

Makes a `submit_form()` call and executes tests on the results.
The form must be found, and then submitted successfully.  Otherwise,
this test fails.

_%params_ is a hashref containing the params to pass to `submit_form()`.
Note that the params to `submit_form()` are a hash whereas the params to
this function are a hashref.  You have to call this function like:

    $agent->submit_form_ok({
        form_number => 3,
        fields      => {
            username    => 'mungo',
            password    => 'lost-and-alone',
        }
    }, "looking for 3rd form" );

As with other test functions, `$desc` is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns true value if the specified link was found and followed
successfully.  The [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object returned by submit\_form()
is not available.

## $mech->follow\_link\_ok( \\%params \[, $desc\] )

Makes a `follow_link()` call and executes tests on the results.
The link must be found, and then followed successfully.  Otherwise,
this test fails.

_%params_ is a hashref containing the params to pass to `follow_link()`.
Note that the params to `follow_link()` are a hash whereas the params to
this function are a hashref.  You have to call this function like:

    $mech->follow_link_ok( {n=>3}, "looking for 3rd link" );

As with other test functions, `$desc` is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns a true value if the specified link was found and followed
successfully.  The [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object returned by follow\_link()
is not available.

## click\_ok( $button\[, $desc\] )

Clicks the button named by `$button`.  An optional `$desc` can
be given for the test.

# METHODS: CONTENT CHECKING

## $mech->html\_lint\_ok( \[$desc\] )

Checks the validity of the HTML on the current page.  If the page is not
HTML, then it fails.  The URI is automatically appended to the _$desc_.

Note that HTML::Lint must be installed for this to work.  Otherwise,
it will blow up.

## $mech->title\_is( $str \[, $desc \] )

Tells if the title of the page is the given string.

    $mech->title_is( "Invoice Summary" );

## $mech->title\_like( $regex \[, $desc \] )

Tells if the title of the page matches the given regex.

    $mech->title_like( qr/Invoices for (.+)/

## $mech->title\_unlike( $regex \[, $desc \] )

Tells if the title of the page matches the given regex.

    $mech->title_unlike( qr/Invoices for (.+)/

## $mech->base\_is( $str \[, $desc \] )

Tells if the base of the page is the given string.

    $mech->base_is( "http://example.com/" );

## $mech->base\_like( $regex \[, $desc \] )

Tells if the base of the page matches the given regex.

    $mech->base_like( qr{http://example.com/index.php?PHPSESSID=(.+)});

## $mech->base\_unlike( $regex \[, $desc \] )

Tells if the base of the page matches the given regex.

    $mech->base_unlike( qr{http://example.com/index.php?PHPSESSID=(.+)});

## $mech->content\_is( $str \[, $desc \] )

Tells if the content of the page matches the given string

## $mech->content\_contains( $str \[, $desc \] )

Tells if the content of the page contains _$str_.

## $mech->content\_lacks( $str \[, $desc \] )

Tells if the content of the page lacks _$str_.

## $mech->content\_like( $regex \[, $desc \] )

Tells if the content of the page matches _$regex_.

## $mech->content\_unlike( $regex \[, $desc \] )

Tells if the content of the page does NOT match _$regex_.

## $mech->has\_tag( $tag, $text \[, $desc \] )

Tells if the page has a `$tag` tag with the given content in its text.

## $mech->has\_tag\_like( $tag, $regex \[, $desc \] )

Tells if the page has a `$tag` tag with the given content in its text.

## $mech->followable\_links()

Returns a list of links that [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) can follow.  This is only http
and https links.

## $mech->page\_links\_ok( \[ $desc \] )

Follow all links on the current page and test for HTTP status 200

    $mech->page_links_ok('Check all links');

## $mech->page\_links\_content\_like( $regex \[, $desc \] )

Follow all links on the current page and test their contents for _$regex_.

    $mech->page_links_content_like( qr/foo/,
      'Check all links contain "foo"' );

## $mech->links\_ok( $links \[, $desc \] )

Follow specified links on the current page and test for HTTP status
200\.  The links may be specified as a reference to an array containing
[WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) objects, an array of URLs, or a scalar URL
name.

    my @links = $mech->find_all_links( url_regex => qr/cnn\.com$/ );
    $mech->links_ok( \@links, 'Check all links for cnn.com' );

    my @links = qw( index.html search.html about.html );
    $mech->links_ok( \@links, 'Check main links' );

    $mech->links_ok( 'index.html', 'Check link to index' );

## $mech->link\_status\_is( $links, $status \[, $desc \] )

Follow specified links on the current page and test for HTTP status
passed.  The links may be specified as a reference to an array
containing [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) objects, an array of URLs, or a
scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_status_is( \@links, 403,
      'Check all links are restricted' );

## $mech->link\_status\_isnt( $links, $status \[, $desc \] )

Follow specified links on the current page and test for HTTP status
passed.  The links may be specified as a reference to an array
containing [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) objects, an array of URLs, or a
scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_status_isnt( \@links, 404,
      'Check all links are not 404' );

## $mech->link\_content\_like( $links, $regex \[, $desc \] )

Follow specified links on the current page and test the resulting
content of each against _$regex_.  The links may be specified as a
reference to an array containing [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) objects, an
array of URLs, or a scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_content_like( \@links, qr/Restricted/,
        'Check all links are restricted' );

## $mech->link\_content\_unlike( $links, $regex \[, $desc \] )

Follow specified links on the current page and test that the resulting
content of each does not match _$regex_.  The links may be specified as a
reference to an array containing [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) objects, an array
of URLs, or a scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_content_unlike( \@links, qr/Restricted/,
      'No restricted links' );

## $mech->stuff\_inputs( \[\\%options\] )

Finds all free-text input fields (text, textarea, and password) in the
current form and fills them to their maximum length in hopes of finding
application code that can't handle it.  Fields with no maximum length
and all textarea fields are set to 66000 bytes, which will often be
enough to overflow the data's eventual receptacle.

There is no return value.

If there is no current form then nothing is done.

The hashref $options can contain the following keys:

- ignore

    hash value is arrayref of field names to not touch, e.g.:

        $mech->stuff_inputs( {
            ignore => [qw( specialfield1 specialfield2 )],
        } );

- fill

    hash value is default string to use when stuffing fields.  Copies
    of the string are repeated up to the max length of each field.  E.g.:

        $mech->stuff_inputs( {
            fill => '@'  # stuff all fields with something easy to recognize
        } );

- specs

    hash value is arrayref of hashrefs with which you can pass detailed
    instructions about how to stuff a given field.  E.g.:

        $mech->stuff_inputs( {
            specs=>{
                # Some fields are datatype-constrained.  It's most common to
                # want the field stuffed with valid data.
                widget_quantity => { fill=>'9' },
                notes => { maxlength=>2000 },
            }
        } );

    The specs allowed are _fill_ (use this fill for the field rather than
    the default) and _maxlength_ (use this as the field's maxlength instead
    of any maxlength specified in the HTML).

# AUTHOR

Leon Brocard <acme@astray.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
