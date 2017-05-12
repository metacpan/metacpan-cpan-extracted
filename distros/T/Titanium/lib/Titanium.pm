package Titanium;
use base 'CGI::Application';

use vars '$VERSION';
$VERSION = '1.04';

# Just load a few recommended plugins by default. 
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::ValidateRM; 
use CGI::Application::Plugin::ConfigAuto 'cfg';
use CGI::Application::Plugin::FillInForm 'fill_form';
use CGI::Application::Plugin::ErrorPage  'error';
use CGI::Application::Plugin::Stream     'stream_file';
use CGI::Application::Plugin::DBH 		  qw(dbh_config dbh); 
use CGI::Application::Plugin::LogDispatch;

# For development, need to activated with an ENV variable. 
use CGI::Application::Plugin::DebugScreen;
use CGI::Application::Plugin::DevPopup;
use CGI::Application::Standard::Config;



=head1 NAME

Titanium - A strong, lightweight web application framework

=head1 SYNOPSIS

=head2 Coding 

  # In "WebApp.pm"...
  package WebApp;
  use base 'Titanium';

  sub setup {
	my $c = shift;

	$c->start_mode('form_display');
	$c->run_modes([qw/
        form_display
        form_process
	/]);
  }
  sub form_display { 
        my $c = shift;
        my $errs = shift;

        my $t = $c->load_tmpl;
        $t->param($errs) if $errs;
        return $t->output;
  }
  sub form_process {
       my $c = shift;

       # Validate the form against a profile. If it fails validation, re-display
       # the form for the user with their data pre-filled and the errors highlighted. 
       my ($results, $err_page) = $c->check_rm('form_display','_form_profile');
       return $err_page if $err_page; 

       return $c->forward('form_success');   
  }

  # Return a Data::FormValidator profile
  sub _form_profile {
    my $c = shift;
    return {
        required => 'email',
    };
  }

  sub form_success { ... } 

  1;

  ### In "webapp.cgi"...
  use WebApp;
  my $c = WebApp->new();
  $c->run();

Inside the run modes, the following methods are available:

    $c->query;                               # A query object. CGI.pm by default.
    $c->redirect('http://othersite.com');    # Basic redirection
    $c->dbh;                                 # DBI database handle
    $c->session();                           # A CGI::Session object
    $c->check_rm;                            # Form validation with Data::FormValidator
    $c->cfg('root_uri');                     # Config file access (YAML, Perl or INI formats)
    $c->fill_form;                           # Form filling with HTML::FillInForm
    $c->error( title => '..', msg => '..' ); # Easy error page generation
    $c->stream_file($file);                  # file streaming
    $c->log;                                 # A Log::Dispatch object

=head2 Development and Testing

Easily setup the project skeleton using the bundled L<cgiapp-starter> script. 

In development you can turn on a debugging screen and a developer pop-up to quickly catch
code, html and performance issues, thanks to L<CGI::Application::Plugin::DebugScreen|CGI::Application::Plugin::DebugScreen> and 
L<CGI::Application::Plugin::DevPopup|CGI::Application::Plugin::DevPopup>.  

For automated testing, L<Test::WWW::Mechanize::CGIApp|Test::WWW::Mechanize::CGIApp> is bundled, allowing you
to functionally test your web application without involving a full web server. 
If you'd rather test against full web server, L<Test::WWW::Mechanize|Test::WWW::Mechanize> is there, too.  

=head2 Dispatching with Clean URIs

Modern web frameworks dispense with cruft in URIs. Instead of: 

 /cgi-bin/item.cgi?rm=view&id=15

A clean URI to describe the same resource might be:

 /item/15/view

The process of mapping these URIs to run modes is called dispatching and is
handled by L<CGI::Application::Dispatch|CGI::Application::Dispatch>. It comes
with a default dispatch table that automatically creates URLs in this pattern
for you:

 /app/module_name/run_mode

There's plenty of flexibility to design your own URIs if you'd like. 

=head1 Elements of Titanium

* B<Titanium is solid and mature>. While it has a new name, the reality is that
Titanium is simply a more user-friendly packaging of the mature
CGI::Application framework and some useful plugins. These packages have already
been refined and vetted.  The seed framework was first released in 2000 and by
2005 was mature.  Titanium contains no real code of its own, and there is no
intention to do so in the future. Instead, we may select other mature plugins
to include in the future.  Other "Titanium alloys" in the "Titanium::Alloy::"
name space may also come to exist, following the same philosophy, but choosing
to bundle a different combination of plugins. 

* B<Titanium is lightweight>. Titanium has a very light core and the plugins it
uses employ lazy-loading whenever possible. That means that while we have
built-in database plugin, we don't have to load DBI or make a database
connection until you actually use the database connection. Titanium runs well
in a plain CGI environment and provides excellent performance in a persistent
environment such as FastCGI or mod_perl. Titanium apps are compatible with the
dozens of published plugins for L<CGI::Application|CGI::Application>, so you
can add additional features as your needs evolve. 

=head1 DESCRIPTION

It is intended that your Application Module will be implemented as a sub-class
of Titanium. This is done simply as follows:

    package My::App; 
    use base 'Titanium';

B<Notation and Conventions>

For the purpose of this document, we will refer to the
following conventions:

  WebApp.pm  : The Perl module which implements your Application Module class.
  WebApp     : Your Application Module class; a sub-class of Titanium.
  webapp.cgi : The Instance Script which implements your Application Module.
  $c         : Used in instance methods to pass around the
               current object. (Sometimes referred as "$self" in other projects.)
               Think of the "$c" as short for "controller". 


=head2 Script/Dispatching Methods

By inheriting from Titanium you have access to a number of built-in methods.
The following are those which are expected to be called from your Instance
Script or through your L<CGI::Application::Dispatch|CGI::Application::Dispatch>
dispatcher.

=head3 new()

The new() method is the constructor for a Titanium.  It returns
a blessed reference to your Application Module class.  Optionally,
new() may take a set of parameters as key => value pairs:

    my $c = WebApp->new(
		TMPL_PATH => 'App/',
		PARAMS => {
			'custom_thing_1' => 'some val',
			'another_custom_thing' => [qw/123 456/]
		}
    );

This method may take some specific parameters:

B<TMPL_PATH> - This optional parameter defines a path to a directory of templates.
This is used by the load_tmpl() method (specified below), and may also be used
for the same purpose by other template plugins.  This run-time parameter allows
you to further encapsulate instantiating templates, providing potential for
more re-usability.  It can be either a scalar or an array reference of multiple
paths.

B<QUERY> - This optional parameter allows you to specify an already-created CGI
query object.  Under normal use, Titanium will instantiate its own
L<CGI.pm|CGI.pm> query object.  Under certain conditions, it might be useful to
be able to use one which has already been created.

B<PARAMS> - This parameter, if used, allows you to set a number
of custom parameters at run-time.  By passing in different
values in different instance scripts which use the same application
module you can achieve a higher level of re-usability.  For instance,
imagine an application module, "Mailform.pm".  The application takes
the contents of a HTML form and emails it to a specified recipient.
You could have multiple instance scripts throughout your site which
all use this "Mailform.pm" module, but which set different recipients
or different forms.

One common use of instance scripts is to provide a path to a config file.  This
design allows you to define project wide configuration objects used by many
several instance scripts. There are several plugins which simplify the syntax
for this and provide lazy loading. Here's an example using
L<CGI::Application::Plugin::ConfigAuto|CGI::Application::Plugin::ConfigAuto>,
which uses L<Config::Auto|Config::Auto> to support many configuration file
formats. 

 my $app = WebApp->new(PARAMS => { cfg_file => 'config.pl' });

 # Later in your app:
 my %cfg = $c->cfg()
 # or ... $c->cfg('HTML_ROOT_DIR');

See the list of of plugins below for more config file integration solutions.

=head3 run()

The run() method is called upon your Application Module object, from
your Instance Script.  When called, it executes the functionality
in your Application Module.

    my $c = WebApp->new;
    $c->run;

This method determines the application state by looking at the dispatch table,
as described in L<CGI::Application::Dispatch|CGI::Application::Dispatch>. 

Once the mode has been determined, run() looks at the hash stored in
run_modes() and finds the subroutine which is tied to a specific hash key.  If
found, the function is called and the data returned is print()'ed to STDOUT and
to the browser.  If the specified mode is not found in the run_modes() table,
run() will croak(). This 'death' can possibly be captured and handled using C<error_mode()>,
described below. 

=head2 Essential Method to Override 

Titanium implements some methods which are expected to be overridden
by implementing them in your sub-class module.  One of these is essential to do:

=head3 setup()

This method is called by the inherited new() constructor method.  The
setup() method should be used to define the following property/methods:

    start_mode() - string containing the default run mode.
    run_modes()  - hash table containing mode => function mappings.

    error_mode() - string containing the error mode.
    tmpl_path()  - string or array reference containing path(s) to template directories.

Your setup() method may call any of the instance methods of your application.
This function is a good place to define properties specific to your application
via the $c->param() method.

Your setup() method might be implemented something like this:

	sub setup {
		my $c = shift;
		$c->start_mode('putform');
		$c->run_modes([qw/
                form
                form_process
		/]);
	}

=head2 Essential Application Methods

The following methods are inherited from Titanium, and are
available to be called by your application within your Application
Module. They are called essential because you will use all are most
of them to get any application up and running.  These functions are listed in alphabetical order.

=head3 load_tmpl()

    my $tmpl_obj = $c->load_tmpl;
    my $tmpl_obj = $c->load_tmpl('some.html');
    my $tmpl_obj = $c->load_tmpl( \$template_content );
    my $tmpl_obj = $c->load_tmpl( FILEHANDLE );

This method takes the name of a template file, a reference to template data
or a FILEHANDLE and returns an HTML::Template object. If the filename is undefined or missing, Titanium will default to trying to use the current run mode name, plus the extension ".html". 

If you use the default template naming system, you should also use
L<CGI::Application::Plugin::Forward>, which simply helps to keep the current
name accurate when you pass control from one run mode to another.

( For integration with other template systems
and automated template names, see "Alternatives to load_tmpl() below. )

When you pass in a filename, the HTML::Template->new_file() constructor
is used for create the object.  When you pass in a reference to the template
content, the HTML::Template->new_scalar_ref() constructor is used and
when you pass in a filehandle, the HTML::Template->new_filehandle()
constructor is used.

Refer to L<HTML::Template> for specific usage of HTML::Template.

If tmpl_path() has been specified, load_tmpl() will set the
HTML::Template C<path> option to the path(s) provided.  This further
assists in encapsulating template usage.

The load_tmpl() method will pass any extra parameters sent to it directly to
HTML::Template->new_file() (or new_scalar_ref() or new_filehandle()).
This will allow the HTML::Template object to be further customized:

    my $tmpl_obj = $c->load_tmpl('some_other.html',
         die_on_bad_params => 0,
         cache => 1
    );

Note that if you want to pass extra arguments but use the default template
name, you still need to provide a name of C<undef>:

    my $tmpl_obj = $c->load_tmpl(undef',
         die_on_bad_params => 0,
         cache => 1
    );

B<Alternatives to load_tmpl()>

If your application requires more specialized behavior than this, you can
always replace it by overriding load_tmpl() by implementing your own
load_tmpl() in your Titanium sub-class application module.

First, you may want to check out the template related plugins. 

L<CGI::Application::Plugin::TT> focuses just on Template Toolkit integration,
and features pre-and-post features, singleton support and more.

=head3 param()

    $c->param('pname', $somevalue);

The param() method provides a facility through which you may set
application instance properties which are accessible throughout
your application.

The param() method may be used in two basic ways.  First, you may use it
to get or set the value of a parameter:

    $c->param('scalar_param', '123');
    my $scalar_param_values = $c->param('some_param');

Second, when called in the context of an array, with no parameter name
specified, param() returns an array containing all the parameters which
currently exist:

    my @all_params = $c->param();

The param() method also allows you to set a bunch of parameters at once
by passing in a hash (or hashref):

    $c->param(
        'key1' => 'val1',
        'key2' => 'val2',
        'key3' => 'val3',
    );

The param() method enables a very valuable system for customizing your
applications on a per-instance basis.  One Application Module might be
instantiated by different Instance Scripts.  Each Instance Script might set
different values for a set of parameters.  This allows similar applications to
share a common code-base, but behave differently.  For example, imagine a mail
form application with a single Application Module, but multiple Instance
Scripts.  Each Instance Script might specify a different recipient.  Another
example would be a web bulletin boards system.  There could be multiple boards,
each with a different topic and set of administrators.

The new() method provides a shortcut for specifying a number of run-time
parameters at once.  Internally, Titanium calls the param()
method to set these properties.  The param() method is a powerful tool for
greatly increasing your application's re-usability.

=head3 query()

    my $q = $c->query();
    my $remote_user = $q->remote_user();

This method retrieves the CGI.pm query object which has been created
by instantiating your Application Module.  For details on usage of this
query object, refer to L<CGI>.  Titanium is built on the CGI
module.  Generally speaking, you will want to become very familiar
with CGI.pm, as you will use the query object whenever you want to
interact with form data.

When the new() method is called, a CGI query object is automatically created.
If, for some reason, you want to use your own CGI query object, the new()
method supports passing in your existing query object on construction using
the QUERY attribute.


=head3 run_modes()

    # The common usage: an arrayref of run mode names that exactly match subroutine names
    $c->run_modes([qw/
        form_display
        form_process
    /]);

   # With a hashref, use a different name or a code ref
   $c->run_modes(
           'mode1' => 'some_sub_by_name', 
           'mode2' => \&some_other_sub_by_ref
    );

This accessor/mutator specifies a lookup table for the application states,
using the syntax examples above. It returns the dispatch table as a hash. 

The run_modes() method may be called more than once.  Additional values passed
into run_modes() will be added to the run modes table.  In the case that an
existing run mode is re-defined, the new value will override the existing value.
This behavior might be useful for applications which are created via inheritance
from another application, or some advanced application which modifies its
own capabilities based on user input.

The run() method uses the data in this table to send the application to the
correct function as determined by the dispatcher, as described in
L<CGI::Application::Dispatch|CGI::Application::Dispatch>.  These functions are
referred to as "run mode methods".

The hash table set by this method is expected to contain the mode
name as a key.  The value should be either a hard reference (a subref)
to the run mode method which you want to be called when the application enters
the specified run mode, or the name of the run mode method to be called:

    'mode_name_by_ref'  => \&mode_function
    'mode_name_by_name' => 'mode_function'

The run mode method specified is expected to return a block of text (e.g.:
HTML) which will eventually be sent back to the web browser.  The run mode
method may return its block of text as a scalar or a scalar-ref.

An advantage of specifying your run mode methods by name instead of
by reference is that you can more easily create derivative applications
using inheritance.  For instance, if you have a new application which is
exactly the same as an existing application with the exception of one
run mode, you could simply inherit from that other application and override
the run mode method which is different.  If you specified your run mode
method by reference, your child class would still use the function
from the parent class.

An advantage of specifying your run mode methods by reference instead of by name
is performance.  Dereferencing a subref is faster than eval()-ing
a code block.  If run-time performance is a critical issue, specify
your run mode methods by reference and not by name.  The speed differences
are generally small, however, so specifying by name is preferred.

Specifying the run modes by array reference:

    $c->run_modes([ 'mode1', 'mode2', 'mode3' ]);

Is is the same as using a hash, with keys equal to values

    $c->run_modes(
        'mode1' => 'mode1',
        'mode2' => 'mode2',
        'mode3' => 'mode3'
    );

Often, it makes good organizational sense to have your run modes map to
methods of the same name.  The array-ref interface provides a shortcut
to that behavior while reducing verbosity of your code.

Note that another importance of specifying your run modes in either a
hash or array-ref is to assure that only those Perl methods which are
specifically designated may be called via your application.  Application
environments which don't specify allowed methods and disallow all others
are insecure, potentially opening the door to allowing execution of
arbitrary code.  Titanium maintains a strict "default-deny" stance
on all method invocation, thereby allowing secure applications
to be built upon it.

B<IMPORTANT NOTE ABOUT RUN MODE METHODS>

Your application should *NEVER* print() to STDOUT.
Using print() to send output to STDOUT (including HTTP headers) is
exclusively the domain of the inherited run() method.  Breaking this
rule is a common source of errors.  If your program is erroneously
sending content before your HTTP header, you are probably breaking this rule.


B<THE RUN MODE OF LAST RESORT: "AUTOLOAD">

If Titanium is asked to go to a run mode which doesn't exist,
by default it will return an error page to the user, implemented
like this:

  return $c->error(
    title => 'The requested page was not found.',
    msg => "(The page tried was: ".$c->get_current_runmode.")"
  );

See L<CGI::Application::Plugin::ErrorPage> for more details on the built-in
error page system.  If this is not your desired behavior for handling unknown
run mode requests, implement your own run mode with the reserved name
"AUTOLOAD":

  $c->run_modes(
	"AUTOLOAD" => \&catch_my_exception
  );

Before Titanium invokes its own error page handling it will check for the
existence of a run mode called "AUTOLOAD".  If specified, this run mode will in
invoked just like a regular run mode, with one exception:  It will receive, as
an argument, the name of the run mode which invoked it:

  sub catch_my_exception {
	my $c = shift;
	my $intended_runmode = shift;

	my $output = "Looking for '$intended_runmode', but found 'AUTOLOAD' instead";
	return $output;
  }

This functionality could be for more sophisticated application behaviors.

=head3 start_mode()

    $c->start_mode('mode1');

The start_mode contains the name of the mode as specified in the run_modes()
table.  Default mode is "start".  The mode key specified here will be used
whenever the value of the CGI form parameter specified by mode_param() is
not defined.  Generally, this is the first time your application is executed.

=head3 tmpl_path()

    $c->tmpl_path('/path/to/some/templates/');

This access/mutator method sets the file path to the directory (or directories)
where the templates are stored.  It is used by load_tmpl() to find the template
files, using HTML::Template's C<path> option. To set the path you can either
pass in a text scalar or an array reference of multiple paths.




=head2 More Methods to override

Several more non-essential methods are useful to declare in your application
class, or in a project "super class" that inherits from your Titanium only to
serve in turn as a base class for project modules. These additional methods are
as follows:

=head3 teardown()

If implemented, this method is called automatically after your application
runs.  It can be used to clean up after your operations.  A typical use of the
teardown() function is to disconnect a database connection which was
established in the setup() function, or flush open session data.  You could
also use the teardown() method to store state information about the application
to the server.

=head3 cgiapp_init()

If implemented, this method is called automatically right before the setup()
method is called.  The cgiapp_init() method receives, as its parameters, all
the arguments which were sent to the new() method.

An example of the benefits provided by utilizing this hook is
creating a custom "application super-class" from which which all
your web applications would inherit, instead of directly from Titanium.

Consider the following:

  # In MySuperclass.pm:
  package MySuperclass;
  use base 'Titanium';
  sub cgiapp_init {
	my $c = shift;
	# Perform some project-specific init behavior
	# such as to load settings from a database or file.
  }


  # In MyApplication.pm:
  package MyApplication;
  use base 'MySuperclass';
  sub setup { ... }
  sub teardown { ... }
  # The rest of your Titanium-based follows...


By using Titanium and the cgiapp_init() method as illustrated,
a suite of applications could be designed to share certain
characteristics, creating cleaner code.

=head3 cgiapp_prerun()

If implemented, this method is called automatically right before the selected
run mode method is called.  This method provides an optional pre-runmode hook,
which permits functionality to be added at the point right before the run mode
method is called.  The value of the run mode is passed into cgiapp_prerun().

This could be used by a custom "application super-class" from which all your
web applications would inherit, instead of Titanium.

Consider the following:

  # In MySuperclass.pm:
  package MySuperclass;
  use base 'Titanium';
  sub cgiapp_prerun {
	my $c = shift;
	# Perform some project-specific init behavior
	# such as to implement run mode specific
	# authorization functions.
  }


  # In MyApplication.pm:
  package MyApplication;
  use base 'MySuperclass';
  sub setup { ... }
  sub teardown { ... }
  # The rest of your Titanium-based follows...

It is also possible, within your cgiapp_prerun() method, to change the
run mode of your application.  This can be done via the prerun_mode()
method, which is discussed elsewhere.

=head3 cgiapp_postrun()

If implemented, this hook will be called after the run mode method
has returned its output, but before HTTP headers are generated.  This
will give you an opportunity to modify the body and headers before they
are returned to the web browser.

A typical use for this hook is pipelining the output of a CGI-Application
through a series of "filter" processors.  For example:

  * You want to enclose the output of all your CGI-Applications in
    an HTML table in a larger page.

  * Your run modes return structured data (such as XML), which you
    want to transform using a standard mechanism (such as XSLT).

  * You want to post-process CGI-App output through another system,
    such as HTML::Mason.

  * You want to modify HTTP headers in a particular way across all
    run modes, based on particular criteria.

The cgiapp_postrun() hook receives a reference to the output from
your run mode method, in addition to the CGI-App object.  A typical
cgiapp_postrun() method might be implemented as follows:

  sub cgiapp_postrun {
    my $c = shift;
    my $output_ref = shift;

    # Enclose output HTML table
    my $new_output = "<table border=1>";
    $new_output .= "<tr><td> Hello, World! </td></tr>";
    $new_output .= "<tr><td>". $$output_ref ."</td></tr>";
    $new_output .= "</table>";

    # Replace old output with new output
    $$output_ref = $new_output;
  }

Obviously, with access to the CGI-App object you have full access to use all
the methods normally available in a run mode.  You could, for example, use
C<load_tmpl()> to replace the static HTML in this example with
L<HTML::Template>.  You could change the HTTP headers (via C<header_add()> ).
You could also use the objects properties to apply changes only under certain
circumstance, such as a in only certain run modes, and when a C<param()> is a
particular value.

=head3 cgiapp_get_query()

 my $q = $c->cgiapp_get_query;

Override this method to retrieve the query object if you wish to use a
different query interface instead of CGI.pm.  

CGI.pm is only loaded to provided query object is only loaded if it used on a given request.

If you can use an alternative to CGI.pm, it needs to have some compatibility
with the CGI.pm API. For normal use, just having a compatible C<param> method
should be sufficient. 

If use the C<path_info> option to the mode_param() method, then we will call
the C<path_info()> method on the query object.

If you use the C<Dump> method in Titanium, we will call the C<Dump> and
C<escapeHTML> methods on the query object. 

=head2 More Application Methods

You can skip this section if you are just getting started. 

The following additional methods are inherited from Titanium, and are
available to be called by your application within your Application Module.
These functions are listed in alphabetical order.

=head3 error_mode()

    $c->error_mode('my_error_rm');

If the runmode dies for whatever reason, C<run() will> see if you have set a
value for C<error_mode()>. If you have, C<run()> will call that method
as a run mode, passing $@ as the only parameter.

No C<error_mode> is defined by default.  The death of your C<error_mode()> run
mode is not trapped, so you can also use it to die in your own special way.

For a complete integrated logging solution, check out L<CGI::Application::Plugin::LogDispatch>.

=head3 header_add()

    # add or replace the 'type' header
    $c->header_add( -type => 'image/png' );

    - or -

    # add an additional cookie
    $c->header_add(-cookie=>[$extra_cookie]);

The C<header_add()> method is used to add one or more headers to the outgoing
response headers.  The parameters will eventually be passed on to the CGI.pm
header() method, so refer to the L<CGI> docs for exact usage details.

Unlike calling C<header_props()>, C<header_add()> will preserve any existing
headers. If a scalar value is passed to C<header_add()> it will replace
the existing value for that key.

If an array reference is passed as a value to C<header_add()>, values in
that array ref will be appended to any existing values values for that key.
This is primarily useful for setting an additional cookie after one has already
been set.

=head3 header_props()

    $c->header_props(-type=>'image/gif',-expires=>'+3d');

The C<header_props()> method expects a hash of CGI.pm-compatible
HTTP header properties.  These properties will be passed directly
to CGI.pm's C<header()> or C<redirect()> methods.  Refer to L<CGI>
for exact usage details.

Calling header_props any arguments will clobber any existing headers that have
previously set.

C<header_props()> return a hash of all the headers that have currently been
set. It can be called with no arguments just to get the hash current headers
back.

To add additional headers later without clobbering the old ones,
see C<header_add()>.

B<IMPORTANT NOTE REGARDING HTTP HEADERS>

It is through the C<header_props()> and C<header_add()> method that you may
modify the outgoing HTTP headers.  This is necessary when you want to set a
cookie, set the mime type to something other than "text/html", or perform a
redirect.  Understanding this relationship is important if you wish to
manipulate the HTTP header properly.

=head3 redirect()

  return $c->redirect('http://www.example.com/');

Redirect to another URL. 

=head3 forward() 

  return $c->forward('rm_name');

Pass control to another run mode and return its output.  This is equivalent to
calling $self->$other_runmode, except that the internal value of the current
run mode is updated. This bookkeeping is important to load_tmpl() when called
with no arguments and some other plugins.

=head3 dbh()

  sub cgiapp_init  {
      my $c = shift;
  
      # use the same args as DBI->connect();
      $c->dbh_config($data_source, $username, $auth, \%attr);
  
  }

 sub form_process {
    my $c = shift;

    my $dbh = $c->dbh;
 } 

Easy access to a DBI database handle. The database connection is not created
until the first call to C<dbh()>. See L<CGI::Application::Plugin::DBH|CGI::Application::Plugin::DBH> for more
features and details.

=head3 session()

 # in cgiapp_init()
 $c->session_config(
          CGI_SESSION_OPTIONS => [ "driver:PostgreSQL;serializer:Storable", $self->query, {Handle=>$dbh} ],
 );

 # in a run mode 
 my $ses = $c->session->param('foo');

Easy access to a L<CGI::Session|CGI::Session> object, so you can store user
data between requests. The session is not accessed or created until the first
call to session() in a given request. See
L<CGI::Application::Plugin::Session|CGI::Application::Plugin::Session> for more
features and details.

=head3 cfg()
 
    $c->cfg('root_uri'); 

Easy access to parameters loaded from a config file, which can be stored in one
of several formats, including YAML and Pure Perl. For more features and details
see
L<CGI::Application::Plugin::ConfigAuto|CGI::Application::Plugin::ConfigAuto>.

=head3 log()

   $c->log->info('Information message');
   $c->log->debug('Debug message');

Easy access to a L<Log::Dispatch|Log::Dispatch> logging object, allowing you to log to different
locations with different locations of severity. By adjusting the logging level 
for your application, you make "debug" messages appear or disappear from your logs
without making pervasive code changes. See 
L<CGI::Application::Plugin::LogDispatch|CGI::Application::Plugin::LogDispatch>
for more features and details. 

=head3 check_rm()

  my ($results, $err_page) = $c->check_rm('form_display','_form_profile');
  return $err_page if $err_page; 

Easy form validation with L<Data::FormValidator|Data::FormValidator>. If the
validation fails, we'll re-display the form for the user with their data
pre-filled and the errors highlighted. You'll have full control over the design
of the errors with HTML and CSS in your templates, although we provide some
intelligent defaults. See L<CGI::Application::Plugin::ValidateRM|CGI::Application::Plugin::ValidateRM> for features and details. 

=head3 fill_form()

 # fill an HTML form with data in a hashref or from an object with with a param() method
 my $filled_html = $self->fill_form($html, $data);

 # ...or default to getting data from $self->query()
 my $filled_html = $self->fill_form($html);

HTML::FillInForm is a useful when you want to fill in a web form with default
values from a database table. Like many CPAN modules, you can use directly from
CGI::Application without any special plugin. The value of this plugin is that
it defaults to finding values through $self->query(). Besides that, it is just
a bit of synatic sugar that was mostly created work-around weaknesses in the
HTML::FillInForm 1.x interface, which were fixed with HTML::FillInForm 2.0
release. See L<CGI::Application::Plugin::FillInForm|CGI::Application::Plugin::FillInForm>
for details.

=head3 error()

  $c->error( title => '..', msg => '..' ); 

Provide quick error messages back to the user for exceptional cases. You can
provide your own custom designed template or use the default one built-in.  See
L<CGI::Application::Plugin::ErrorPage|CGI::Application::Plugin::ErrorPage>.

=head3 stream_file()

 $c->stream_file($file);                  
 
If your run mode is outputing an image or a spreadsheet instead of an HTML
page, you may want to stream the output. This method takes care of the boring
details of buffering, headers and MIME types. See
L<CGI::Application::Plugin::Stream|CGI::Application::Plugin::Stream> for
details.

=head3 prerun_mode()

    $c->prerun_mode('new_run_mode');

The prerun_mode() method is an accessor/mutator which can be used within
your cgiapp_prerun() method to change the run mode which is about to be executed.
For example, consider:

  # In WebApp.pm:
  package WebApp;
  use base 'Titanium';
  sub cgiapp_prerun {
	my $c = shift;

	# Get the web user name, if any
	my $q = $c->query();
	my $user = $q->remote_user();

	# Redirect to login, if necessary
	unless ($user) {
		$c->prerun_mode('login');
	}
  }

In this example, the web user will be forced into the "login" run mode
unless they have already logged in.  The prerun_mode() method permits
a scalar text string to be set which overrides whatever the run mode
would otherwise be.

The prerun_mode() method should be used in cases where you want to use
Titanium's normal run mode switching facility, but you want to make selective
changes to the mode under specific conditions.

B<Note:>  The prerun_mode() method may ONLY be called in the context of
a cgiapp_prerun() method.  Your application will die() if you call
prerun_mode() elsewhere, such as in setup() or a run mode method.

=head2 Dispatching Clean URIs to run modes

Modern web frameworks dispense with cruft in URIs, providing in clean
URIs instead. Instead of: 

 /cgi-bin/item.cgi?rm=view&id=15

A clean URI to describe the same resource might be:

 /item/15/view

The process of mapping these URIs to run modes is called dispatching and is
handled by L<CGI::Application::Dispatch|CGI::Application::Dispatch>.
Dispatching is not required and is a layer you can fairly easily add to an
application later.

=head2 Offline website development

You can work on your Titanium project on your desktop or laptop without
installing a full-featured web-server like Apache. Instead, install
L<CGI::Application::Server|CGI::Application::Server> from CPAN. After a few
minutes of setup, you'll have your own private application server up and
running. 

=head2 Automated Testing

There a couple of testing modules specifically made for Titanium.

L<Test::WWW::Mechanize::CGIApp|Test::WWW::Mechanize::CGIApp> allows functional
testing of a CGI::App-based project without starting a web server.
L<Test::WWW::Mechanize|Test::WWW::Mechanize> could be used to test the app
through a real web server. 

L<Test::WWW::Selenium|Test::WWW::Selenium::CGIApp> is similar, but uses
Selenium for the testing, meaning that a local web-browser would be used,
allowing testing of websites that contain JavaScript.

Direct testing is also easy. Titanium will normally print the output of it's
run modes directly to STDOUT. This can be surprised with an enviroment variable, 
CGI_APP_RETURN_ONLY. For example:

  $ENV{CGI_APP_RETURN_ONLY} = 1;
  $output = $c->run;
  like($output, qr/good/, "output is good");

Examples of this style can be seen in our own test suite. 

=head1 PLUGINS

Titanium has a plug-in architecture that is easy to use and easy to develop new
plug-ins for.  Plugins made for CGI::Application are directly compatible. The
CGI::Application should be referenced for those who wish to write plugins. 

Select plugins are listed below. For a current complete list, please consult
CPAN:

http://search.cpan.org/search?m=dist&q=CGI%2DApplication%2DPlugin

=over 4

=item *

L<CGI::Application::Plugin::Apache|CGI::Application::Plugin::Apache> - Use Apache::* modules without interference

=item * 

L<CGI::Application::Plugin::AutoRunmode|CGI::Application::Plugin::AutoRunmode> - Automatically register runmodes 

=item * 

L<CGI::Application::Plugin::CompressGzip|CGI::Application::Plugin::CompressGzip> - Add Gzip compression

=item *

L<CGI::Application::Plugin::TT|CGI::Application::Plugin::TT> - Use L<Template::Toolkit|Template::Toolkit> as an alternative to HTML::Template.


=back

Consult each plug-in for the exact usage syntax.

=head1 COMMUNITY

Therese are primary resources available for those who wish to learn more
about Titanium and discuss it with others.

B<Wiki>

This is a community built and maintained resource that anyone is welcome to
contribute to. It contains a number of articles of its own and links
to many other Titanium related pages. It is currently branded as CGI::Application,
but the code is the same. 

L<http://www.cgi-app.org>

B<Support Mailing List>

If you have any questions, comments, bug reports or feature suggestions,
post them to the support mailing list!  To join the mailing list, simply
send a blank message to "cgiapp-subscribe@lists.erlbaum.net".

B<IRC>

You can also drop by C<#cgiapp> on C<irc.perl.org> with a good chance of finding 
some people involved with the project there. 

B<Source Code>

This project is managed using the darcs source control system (
http://www.darcs.net/ ). The darcs archive is here:
http://mark.stosberg.com/darcs_hive/titanium

=head1 TODO

* I would like Titanium to be easier to install and get started with.  Rather
than depending on the large CPAN dependency chain being installed, I would like
an option for users to download the full stack of dependencies, so that you can
just unpack a single file and go.

* I'd like a plugin to cope with the URI-encoding that Dreamweaver does to templates 
that may just mean packing and releasing the following code as a plug-in:

  CGI::Application->add_callback('load_tmpl',sub {
  	my ($c, $ht_params, $tmpl_params, $tmpl_file) = @_;
  
  	require HTML::Template::Filter::URIdecode;
  	import HTML::Template::Filter::URIdecode 'ht_uri_decode';
  
  	# If you already have a filter defined, don't do anything. 
  	# If you want to add more of your own filters later, be mindful
  	# about whether you add to this arrayref, or replace it. 
  	unless ($ht_params->{filter}) {
  		$ht_params->{filter} = [\&ht_uri_decode] 
  	}
  });
 


=head1 SEE ALSO

=over 4

=item * 

L<CGI::Application|CGI::Application>

=back

=head1 MORE READING

If you're interested in finding out more about Titanium, the
following articles are available on Perl.com, providing
context about the underlying CGI::Application framework

    Using CGI::Application
    http://www.perl.com/pub/a/2001/06/05/cgi.html

    Rapid Website Development with CGI::Application
    http://www.perl.com/pub/a/2006/10/19/cgi_application.html

Thanks to O'Reilly for publishing these articles, and for the incredible value
they provide to the Perl community!

=head1 AUTHORS

Many.

Mark Stosberg, C<< mark@summersault.com >> published the original Titanium module, 
while many another contributed to CGI::Application and the related plugins. 

=head1 LICENSE

Copyright (C) 2008, Mark Stosberg. 

This module is free software; you can redistribute it and/or modify it under
the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,

or

b) the "Artistic License".

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

=cut

1;
