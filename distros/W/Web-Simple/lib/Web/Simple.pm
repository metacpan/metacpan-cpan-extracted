package Web::Simple;

use strictures 1;
use warnings::illegalproto ();
use Moo ();
use Web::Dispatch::Wrapper ();

our $VERSION = '0.033';

sub import {
  my ($class, $app_package) = @_;
  $app_package ||= caller;
  $class->_export_into($app_package);
  eval "package $app_package; use Web::Dispatch::Wrapper; use Moo; 1"
    or die "Failed to setup app package: $@";
  strictures->import;
  warnings::illegalproto->unimport;
}

sub _export_into {
  my ($class, $app_package) = @_;
  {
    no strict 'refs';
    *{"${app_package}::PSGI_ENV"} = sub () { -1 };
    require Web::Simple::Application;
    unshift(@{"${app_package}::ISA"}, 'Web::Simple::Application');
  }
  (my $name = $app_package) =~ s/::/\//g;
  $INC{"${name}.pm"} = 'Set by "use Web::Simple;" invocation';
}

1;

=head1 NAME

Web::Simple - A quick and easy way to build simple web applications


=head1 SYNOPSIS

  #!/usr/bin/env perl

  package HelloWorld;
  use Web::Simple;

  sub dispatch_request {
    GET => sub {
      [ 200, [ 'Content-type', 'text/plain' ], [ 'Hello world!' ] ]
    },
    '' => sub {
      [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
    }
  }

  HelloWorld->run_if_script;

If you save this file into your cgi-bin as C<hello-world.cgi> and then visit:

  http://my.server.name/cgi-bin/hello-world.cgi/

you'll get the "Hello world!" string output to your browser. At the same time
this file will also act as a class module, so you can save it as HelloWorld.pm
and use it as-is in test scripts or other deployment mechanisms.

Note that you should retain the ->run_if_script even if your app is a
module, since this additionally makes it valid as a .psgi file, which can
be extremely useful during development.

For more complex examples and non-CGI deployment, see
L<Web::Simple::Deployment>. To get help with L<Web::Simple>, please connect to
the irc.perl.org IRC network and join #web-simple.

=head1 DESCRIPTION

The philosophy of L<Web::Simple> is to keep to an absolute bare minimum for
everything. It is not designed to be used for large scale applications;
the L<Catalyst> web framework already works very nicely for that and is
a far more mature, well supported piece of software.

However, if you have an application that only does a couple of things, and
want to not have to think about complexities of deployment, then L<Web::Simple>
might be just the thing for you.

The only public interface the L<Web::Simple> module itself provides is an
C<import> based one:

  use Web::Simple 'NameOfApplication';

This sets up your package (in this case "NameOfApplication" is your package)
so that it inherits from L<Web::Simple::Application> and imports L<strictures>,
as well as installs a C<PSGI_ENV> constant for convenience, as well as some
other subroutines.

Importing L<strictures> will automatically make your code use the C<strict> and
C<warnings> pragma, so you can skip the usual:

  use strict;
  use warnings FATAL => 'all';

provided you 'use Web::Simple' at the top of the file. Note that we turn
on *fatal* warnings so if you have any warnings at any point from the file
that you did 'use Web::Simple' in, then your application will die. This is,
so far, considered a feature.

When we inherit from L<Web::Simple::Application> we also use L<Moo>, which is
the the equivalent of:

  {
    package NameOfApplication;
    use Moo;
    extends 'Web::Simple::Application';
  }

So you can use L<Moo> features in your application, such as creating attributes
using the C<has> subroutine, etc.  Please see the documentation for L<Moo> for
more information.

It also exports the following subroutines for use in dispatchers:

  response_filter { ... };

  redispatch_to '/somewhere';

Finally, import sets

  $INC{"NameOfApplication.pm"} = 'Set by "use Web::Simple;" invocation';

so that perl will not attempt to load the application again even if

  require NameOfApplication;

is encountered in other code.

One important thing to remember when using

  NameOfApplication->run_if_script;

At the end of your app is that this call will create an instance of your app
for you automatically, regardless of context. An easier way to think of this
would be if the method were more verbosely named

 NameOfApplication->run_request_if_script_else_turn_coderef_for_psgi;

=head1 DISPATCH STRATEGY

L<Web::Simple> despite being straightforward to use, has a powerful system
for matching all sorts of incoming URLs to one or more subroutines.  These
subroutines can be simple actions to take for a given URL, or something
more complicated, including entire L<Plack> applications, L<Plack::Middleware>
and nested subdispatchers.

=head2 Examples

 sub dispatch_request {
   (
     # matches: GET /user/1.htm?show_details=1
     #          GET /user/1.htm
     'GET + /user/* + ?show_details~ + .htm|.html|.xhtml' => sub {
       my ($self, $user_id, $show_details) = @_;
       ...
     },
     # matches: POST /user?username=frew
     #          POST /user?username=mst&first_name=matt&last_name=trout
     'POST + /user + ?username=&*' => sub {
        my ($self, $username, $misc_params) = @_;
       ...
     },
     # matches: DELETE /user/1/friend/2
     'DELETE + /user/*/friend/*' => sub {
       my ($self, $user_id, $friend_id) = @_;
       ...
     },
     # matches: PUT /user/1?first_name=Matt&last_name=Trout
     'PUT + /user/* + ?first_name~&last_name~' => sub {
       my ($self, $user_id, $first_name, $last_name) = @_;
       ...
     },
     '/user/*/...' => sub {
       my $user_id = $_[1];
       (
         # matches: PUT /user/1/role/1
         'PUT + /role/*' => sub {
           my $role_id = $_[1];
           ...
         },
         # matches: DELETE /user/1/role/1
         'DELETE + /role/*' => sub {
           my $role_id = $_[1];
           ...
         },
       );
     },
   );
 }

=head2 The dispatch cycle

At the beginning of a request, your app's dispatch_request method is called
with the PSGI $env as an argument. You can handle the request entirely in
here and return a PSGI response arrayref if you want:

  sub dispatch_request {
    my ($self, $env) = @_;
    [ 404, [ 'Content-type' => 'text/plain' ], [ 'Amnesia == fail' ] ]
  }

However, generally, instead of that, you return a set of route/target
pairs:

  sub dispatch_request {
    my $self = shift;
    (
      '/' => sub { redispatch_to '/index.html' },
      '/user/*' => sub { $self->show_user($_[1]) },
      'POST + %*' => 'handle_post',
      ...
    );
  }

Well, a sub is a valid PSGI response too (for ultimate streaming and async
cleverness). If you want to return a PSGI sub you have to wrap it into an
array ref.

  sub dispatch_request {
    [ sub {
        my $respond = shift;
        # This is pure PSGI here, so read perldoc PSGI
    } ]
  }

If you return a string followed by a subroutine or method name, the string is
treated as a match specification - and if the test is passed, the subroutine
is called as a method and passed any matched arguments (see below for more details).

You can also return a plain subroutine which will be called with just C<$env>
- remember that in this case if you need C<$self> you B<must> close over it.

If you return a normal object, L<Web::Simple> will simply return it upwards on
the assumption that a response_filter (or some arbitrary L<Plack::Middleware>)
somewhere will convert it to something useful.  This allows:

  sub dispatch_request {
    my $self = shift;
    (
      '.html' => sub { response_filter { $self->render_zoom($_[0]) } },
      '/user/*' => sub { $self->users->get($_[1]) },
    );
  }

An alternative to using string + suborutine to declare a route is to use
the sub prototype -

  sub dispatch_request {
    my $self = shift;
    (
      sub (.html) { response_filter { $self->render_zoom($_[0]) } },
      sub (/user/) { $self->users->get($_[1]) },
      $self->can('handle_post'), # if declared as 'sub handle_post (...) {'
    )
  }

This can be useful sugar, especially if you want to keep method-based
dispatchers' route specifications on the methods.

to render a user object to HTML, if there is an incoming URL such as:

  http://myweb.org/user/111.html

This works because as we descend down the dispachers, we first match
C<sub (.html)>, which adds a C<response_filter> (basically a specialized routine
that follows the L<Plack::Middleware> specification), and then later we also
match C<sub (/user/*)> which gets a user and returns that as the response.
This user object 'bubbles up' through all the wrapping middleware until it hits
the C<response_filter> we defined, after which the return is converted to a
true html response.

However, two types of objects are treated specially - a C<Plack::Component> object
will have its C<to_app> method called and be used as a dispatcher:

  sub dispatch_request {
    my $self = shift;
    (
      '/static/...' => sub { Plack::App::File->new(...) },
      ...
    );
  }

A L<Plack::Middleware> object will be used as a filter for the rest of the
dispatch being returned into:

  ## responds to /admin/track_usage AND /admin/delete_accounts

  sub dispatch_request {
    my $self = shift;
    (
      '/admin/**' => sub {
        Plack::Middleware::Session->new(%opts);
      },
      '/admin/track_usage' => sub {
        ## something that needs a session
      },
      '/admin/delete_accounts' => sub {
        ## something else that needs a session
      },
    );
  }

Note that this is for the dispatch being B<returned> to, so if you want to
provide it inline you need to do:

  ## ALSO responds to /admin/track_usage AND /admin/delete_accounts

  sub dispatch_request {
    my $self = shift;
    (
      '/admin/...' => sub {
        (
          sub {
            Plack::Middleware::Session->new(%opts);
          },
          '/track_usage' => sub {
            ## something that needs a session
          },
          '/delete_accounts' => sub {
            ## something else that needs a session
          },
        );
      }
    );
  }

And that's it - but remember that all this happens recursively - it's
dispatchers all the way down.  A URL incoming pattern will run all matching
dispatchers and then hit all added filters or L<Plack::Middleware>.

=head2 Web::Simple match specifications

=head3 Method matches

  'GET' => sub {

A match specification beginning with a capital letter matches HTTP requests
with that request method.

=head3 Path matches

  '/login' => sub {

A match specification beginning with a / is a path match. In the simplest
case it matches a specific path. To match a path with a wildcard part, you
can do:

  '/user/*' => sub {
    $self->handle_user($_[1])

This will match /user/<anything> where <anything> does not include a literal
/ character. The matched part becomes part of the match arguments. You can
also match more than one part:

  '/user/*/*' => sub {
    my ($self, $user_1, $user_2) = @_;

  '/domain/*/user/*' => sub {
    my ($self, $domain, $user) = @_;

and so on. To match an arbitrary number of parts, use C<**>:

  '/page/**' => sub {
    my ($self, $match) = @_;

This will result in a single element for the entire match. Note that you can do

  '/page/**/edit' => sub {

to match an arbitrary number of parts up to but not including some final
part.

Note: Since Web::Simple handles a concept of file extensions, C<*> and C<**>
matchers will not by default match things after a final dot, and this
can be modified by using C<*.*> and C<**.*> in the final position, e.g.:

  /one/*       matches /one/two.three    and captures "two"
  /one/*.*     matches /one/two.three    and captures "two.three"
  /**          matches /one/two.three    and captures "one/two"
  /**.*        matches /one/two.three    and captures "one/two.three"

Finally,

  '/foo/...' => sub {

Will match C</foo/> on the beginning of the path B<and> strip it. This is
designed to be used to construct nested dispatch structures, but can also prove
useful for having e.g. an optional language specification at the start of a
path.

Note that the '...' is a "maybe something here, maybe not" so the above
specification will match like this:

  /foo         # no match
  /foo/        # match and strip path to '/'
  /foo/bar/baz # match and strip path to '/bar/baz'

Almost the same,

  '/foo...' => sub {

Will match on C</foo/bar/baz>, but also include C</foo>.  Otherwise it
operates the same way as C</foo/...>.

  /foo         # match and strip path to ''
  /foo/        # match and strip path to '/'
  /foo/bar/baz # match and strip path to '/bar/baz'

Please note the difference between C<sub(/foo/...)> and C<sub(/foo...)>.  In
the first case, this is expecting to find something after C</foo> (and fails to
match if nothing is found), while in the second case we can match both C</foo>
and C</foo/more/to/come>.  The following are roughly the same:

  '/foo'     => sub { 'I match /foo' },
  '/foo/...' => sub {
    (
      '/bar' => sub { 'I match /foo/bar' },
      '/*'   => sub { 'I match /foo/{id}' },
    );
  }

Versus

  '/foo...' => sub {
    (
      '~'    => sub { 'I match /foo' },
      '/bar' => sub { 'I match /foo/bar' },
      '/*'   => sub { 'I match /foo/{id}' },
    );
  }

You may prefer the latter example should you wish to take advantage of
subdispatchers to scope common activities.  For example:

  '/user...' => sub {
    my $user_rs = $schema->resultset('User');
    (
      '~' => sub { $user_rs },
      '/*' => sub { $user_rs->find($_[1]) },
    );
  }

You should note the special case path match C<sub (~)> which is only meaningful
when it is contained in this type of path match. It matches to an empty path.

=head4 Naming your patch matches

Any C<*>, C<**>, C<*.*>, or C<**.*> match can be followed with C<:name> to make it into a named
match, so:

  '/*:one/*:two/*:three/*:four' => sub {
    "I match /1/2/3/4 capturing { one => 1, two =>  2, three => 3, four => 4 }"
  }
  
  '/**.*:allofit' => sub {
    "I match anything capturing { allofit => \$whole_path }"
  }

In the specific case of a simple single-* match, the * may be omitted, to
allow you to write:

  '/:one/:two/:three/:four' => sub {
    "I match /1/2/3/4 capturing { one => 1, two =>  2, three => 3, four => 4 }"
  }

=head4 C</foo> and C</foo/> are different specs

As you may have noticed with the difference between C<'/foo/...'> and
C<'/foo...'>, trailing slashes in path specs are significant. This is
intentional and necessary to retain the ability to use relative links on
websites. Let's demonstrate on this link:

  <a href="bar">bar</a>

If the user loads the url C</foo/> and clicks on this link, they will be
sent to C</foo/bar>. However when they are on the url C</foo> and click this
link, then they will be sent to C</bar>.

This makes it necessary to be explicit about the trailing slash.

=head3 Extension matches

  '.html' => sub {

will match .html from the path (assuming the subroutine itself returns
something, of course). This is normally used for rendering - e.g.:

  '.html' => sub {
    response_filter { $self->render_html($_[1]) }
  }

Additionally,

  '.*' => sub {

will match any extension and supplies the extension as a match argument.

=head3 Query and body parameter matches

Query and body parameters can be match via

  '?<param spec>' => sub { # match URI query
  '%<param spec>' => sub { # match body params

The body spec will match if the request content is either
application/x-www-form-urlencoded or multipart/form-data - the latter
of which is required for uploads - see below.

The param spec is elements of one of the following forms:

  param~        # optional parameter
  param=        # required parameter
  @param~       # optional multiple parameter
  @param=       # required multiple parameter
  :param~       # optional parameter in hashref
  :param=       # required parameter in hashref
  :@param~      # optional multiple in hashref
  :@param=      # required multiple in hashref
  *             # include all other parameters in hashref
  @*            # include all other parameters as multiple in hashref

separated by the C<&> character. The arguments added to the request are
one per non-C<:>/C<*> parameter (scalar for normal, arrayref for multiple),
plus if any C<:>/C<*> specs exist a hashref containing those values. If a
parameter has no value, i.e. appears as '?foo&', a value of 1 will be
captured.

Please note that if you specify a multiple type parameter match, you are
ensured of getting an arrayref for the value, EVEN if the current incoming
request has only one value.  However if a parameter is specified as single
and multiple values are found, the last one will be used.

For example to match a C<page> parameter with an optional C<order_by> parameter one
would write:

  '?page=&order_by~' => sub {
    my ($self, $page, $order_by) = @_;
    return unless $page =~ /^\d+$/;
    $order_by ||= 'id';
    response_filter {
      $_[1]->search_rs({}, { page => $page, order_by => $order_by });
    }
  }

to implement paging and ordering against a L<DBIx::Class::ResultSet> object.

Another Example: To get all parameters as a hashref of arrayrefs, write:

  '?@*' => sub {
    my ($self, $params) = @_;
    ...

To get two parameters as a hashref, write:

  '?:user~&:domain~' => sub {
    my ($self, $params) = @_; # params contains only 'user' and 'domain' keys

You can also mix these, so:

  '?foo=&@bar~&:coffee=&@*' => sub {
     my ($self, $foo, $bar, $params) = @_;

where $bar is an arrayref (possibly an empty one), and $params contains
arrayref values for all parameters B<not> mentioned and a scalar value for
the 'coffee' parameter.

Note, in the case where you combine arrayref, single parameter and named
hashref style, the arrayref and single parameters will appear in C<@_> in the
order you defined them in the prototype, but all hashrefs will merge into a
single C<$params>, as in the example above.

=head3 Upload matches

  '*foo=' => sub { # param specifier can be anything valid for query or body

The upload match system functions exactly like a query/body match, except
that the values returned (if any) are C<Web::Dispatch::Upload> objects.

Note that this match type will succeed in two circumstances where you might
not expect it to - first, when the field exists but is not an upload field
and second, when the field exists but the form is not an upload form (i.e.
content type "application/x-www-form-urlencoded" rather than
"multipart/form-data"). In either of these cases, what you'll get back is
a C<Web::Dispatch::NotAnUpload> object, which will C<die> with an error
pointing out the problem if you try and use it. To be sure you have a real
upload object, call

  $upload->is_upload # returns 1 on a valid upload, 0 on a non-upload field

and to get the reason why such an object is not an upload, call

  $upload->reason # returns a reason or '' on a valid upload.

Other than these two methods, the upload object provides the same interface
as L<Plack::Request::Upload> with the addition of a stringify to the temporary
filename to make copying it somewhere else easier to handle.

=head3 Combining matches

Matches may be combined with the + character - e.g.

  'GET + /user/*' => sub {

to create an AND match. They may also be combined with the | character - e.g.

  'GET|POST' => sub {

to create an OR match. Matches can be nested with () - e.g.

  '(GET|POST + /user/*)' => sub {

and negated with ! - e.g.

  '!/user/foo + /user/*' => sub {

! binds to the immediate rightmost match specification, so if you want
to negate a combination you will need to use

  '!(POST|PUT|DELETE)' => sub {

and | binds tighter than +, so

  '(GET|POST) + /user/*' => sub {

and

  'GET|POST + /user/*' => sub {

are equivalent, but

  '(GET + /admin/...) | (POST + /admin/...)' => sub {

and

  'GET + /admin/... | POST + /admin/...' => sub {

are not - the latter is equivalent to

  'GET + (/admin/...|POST) + /admin/...' => sub {

which will never match!

=head3 Whitespace

Note that for legibility you are permitted to use whitespace:

  'GET + /user/*' => sub {

but it will be ignored. This is because the perl parser strips whitespace
from subroutine prototypes, so this is equivalent to

  'GET+/user/*' => sub {

=head3 Accessing parameters via C<%_>

If your dispatch specification causes your dispatch subroutine to receive
a hash reference as its first argument, the contained named parameters
will be accessible via C<%_>.

This can be used to access your path matches, if they are named:

  'GET + /foo/:path_part' => sub {
    [ 200,
      ['Content-type' => 'text/plain'],
      ["We are in $_{path_part}"],
    ];
  }

Or, if your first argument would be a hash reference containing named
query parameters:

  'GET + /foo + ?:some_param=' => sub {
    [ 200,
      ['Content-type' => 'text/plain'],
      ["We received $_{some_param} as parameter"],
    ];
  }

Of course this also works when all you are doing is slurping the whole set
of parameters by their name:

  'GET + /foo + ?*' => sub {
    [ 200,
      ['Content-type' => 'text/plain'],
      [exists($_{foo}) ? "Received a foo: $_{foo}" : "No foo!"],
    ],
  }

Note that only the first hash reference will be available via C<%_>. If
you receive additional hash references, you will need to access them as
usual.

=head3 Accessing the PSGI env hash

In some cases you may wish to get the raw PSGI env hash - to do this,
you can either use a plain sub:

  sub {
    my ($env) = @_;
    ...
  }

or use the C<PSGI_ENV> constant exported to retrieve it from C<@_>:

  'GET + /foo + ?some_param=' => sub {
    my $param = $_[1];
    my $env = $_[PSGI_ENV];
  }

but note that if you're trying to add a middleware, you should simply use
Web::Simple's direct support for doing so.

=head1 EXPORTED SUBROUTINES

=head2 response_filter

  response_filter {
    # Hide errors from the user because we hates them, preciousss
    if (ref($_[0]) eq 'ARRAY' && $_[0]->[0] == 500) {
      $_[0] = [ 200, @{$_[0]}[1..$#{$_[0]}] ];
    }
    return $_[0];
  };

The response_filter subroutine is designed for use inside dispatch subroutines.

It creates and returns a special dispatcher that always matches, and calls
the block passed to it as a filter on the result of running the rest of the
current dispatch chain.

Thus the filter above runs further dispatch as normal, but if the result of
dispatch is a 500 (Internal Server Error) response, changes this to a 200 (OK)
response without altering the headers or body.

=head2 redispatch_to

  redispatch_to '/other/url';

The redispatch_to subroutine is designed for use inside dispatch subroutines.

It creates and returns a special dispatcher that always matches, and instead
of continuing dispatch re-delegates it to the start of the dispatch process,
but with the path of the request altered to the supplied URL.

Thus if you receive a POST to C</some/url> and return a redispatch to
C</other/url>, the dispatch behaviour will be exactly as if the same POST
request had been made to C</other/url> instead.

Note, this is not the same as returning an HTTP 3xx redirect as a response;
rather it is a much more efficient internal process.

=head1 CHANGES BETWEEN RELEASES

=head2 Changes between 0.004 and 0.005

=over 4

=item * dispatch {} replaced by declaring a dispatch_request method

dispatch {} has gone away - instead, you write:

  sub dispatch_request {
    my $self = shift;
    (
      'GET /foo/' => sub { ... },
      ...
    );
  }

Note that this method is still B<returning> the dispatch code - just like
C<dispatch> did.

Also note that you need the C<< my $self = shift >> since the magic $self
variable went away.

=item * the magic $self variable went away.

Just add C<< my $self = shift; >> while writing your C<< sub dispatch_request { >>
like a normal perl method.

=item * subdispatch deleted - all dispatchers can now subdispatch

In earlier releases you needed to write:

  subdispatch sub (/foo/...) {
    ...
    [
      sub (GET /bar/) { ... },
      ...
    ]
  }

As of 0.005, you can instead write simply:

  sub (/foo/...) {
    ...
    (
      sub (GET /bar/) { ... },
      ...
    )
  }

=back

=head2 Changes since Antiquated Perl

=over 4

=item * filter_response renamed to response_filter

This is a pure rename; a global search and replace should fix it.

=item * dispatch [] changed to dispatch {}

Simply changing

  dispatch [ sub(...) { ... }, ... ];

to

  dispatch { sub(...) { ... }, ... };

should work fine.

=back

=head1 DEVELOPMENT HISTORY

Web::Simple was originally written to form part of my Antiquated Perl talk for
Italian Perl Workshop 2009, but in writing the bloggery example I realised
that having a bare minimum system for writing web applications that doesn't
drive me insane was rather nice and decided to spend my attempt at nanowrimo
for 2009 improving and documenting it to the point where others could use it.

The Antiquated Perl talk can be found at L<http://www.shadowcat.co.uk/archive/conference-video/> and the slides are reproduced in this distribution under
L<Web::Simple::AntiquatedPerl>.

=head1 COMMUNITY AND SUPPORT

=head2 IRC channel

irc.perl.org #web-simple

=head2 No mailing list yet

Because mst's non-work email is a bombsite so he'd never read it anyway.

=head2 Git repository

Gitweb is on http://git.shadowcat.co.uk/ and the clone URL is:

  git clone git://git.shadowcat.co.uk/catagits/Web-Simple.git

=head1 AUTHOR

Matt S. Trout (mst) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

Devin Austin (dhoss) <dhoss@cpan.org>

Arthur Axel 'fREW' Schmidt <frioux@gmail.com>

gregor herrmann (gregoa) <gregoa@debian.org>

John Napiorkowski (jnap) <jjn1056@yahoo.com>

Josh McMichael <jmcmicha@linus222.gsc.wustl.edu>

Justin Hunter (arcanez) <justin.d.hunter@gmail.com>

Kjetil Kjernsmo <kjetil@kjernsmo.net>

markie <markie@nulletch64.dreamhost.com>

Christian Walde (Mithaldu) <walde.christian@googlemail.com>

nperez <nperez@cpan.org>

Robin Edwards <robin.ge@gmail.com>

Andrew Rodland (hobbs) <andrew@cleverdomain.org>

Robert Sedlacek (phaylon) <r.sedlacek@shadowcat.co.uk>

Hakim Cassimally (osfameron) <osfameron@cpan.org>

Karen Etheridge (ether) <ether@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011 the Web::Simple L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
