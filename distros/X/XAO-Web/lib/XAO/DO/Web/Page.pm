=head1 NAME

XAO::DO::Web::Page - core object of XAO::Web rendering system

=head1 SYNOPSIS

Outside web environment:

 my $page=XAO::Objects->new(objname => 'Page');
 my $date=$page->expand(template => '<%Date%>');

Inside XAO::Web template:

 <%Page path="/bits/some-path" ARG={<%SomeObject/f%>}%>

=head1 DESCRIPTION

As XAO::DO::Web::Page object (from now on just Page displayable
object) is the core object for XAO::Web web rendering engine we
will start with basics of how it works.

The goal of XAO::Web rendering engine is to produce HTML data file
that can be understood by browser and displayed to a user. It will
usually use database tables, templates and various displayable objects
to achieve that.

Every time a page is requested in someone's web browser a XAO::Web handler
gets executed, prepares site configuration, opens database connection,
determines what would be start object and/or start path and does a lot
of other useful things. If you have not read about it yet it is suggested to
do so -- see L<XAO::Web::Intro> and L<XAO::Web>.

Although XAO::Web handler can call arbitrary object with arbitrary arguments
to produce an HTML page we will assume the simplest scenario of calling
Page object with just one argument -- path to an HTML file template for
simplicity (another way to pass some template to a Page object is
to pass argument named "template" with the template text as the
value). This is the default behavior of XAO::Web handler if you
do not override it in configuration.

Let's say user asked for http://oursite.com/ and XAO::Web translated
that into the call to Page's display method with "path" argument set to
"/index.html". All template paths are treated relative to "templates"
directory in site directory or to system-wide "templates" directory if
site-specific template does not exist. Suppose templates/index.html file
in our site's home directory contains the following:

  Hello, World!

As there are no special symbols in that template Page's display method
will return exactly that text without any changes (it will also cache
pre-parsed template for re-use under mod_perl, but this is irrelevant
for now).

Now let's move to a more complex example -- suppose we want some kind of
header and footer around our text:

  <%Page path="/bits/header-template"%>

  Hello, World!

  <%Page path="/bits/footer-template"%>

Now, Page's parser sees reference to other items in that template -
these things, surrounded by <% %> signs. What it does is the following.

First it checks if there is an argument given to original Page's
display() method named 'Page' (case sensitive). In our case there is no
such argument present.

Then, as no such static argument is found, it attempts to load an
object named 'Page' and pass whatever arguments given to that object's
display method.

I<NOTE:> it is recommended to name static
arguments in all-lowercase (for standard parameters accepted by an
object) or all-uppercase (for parameters that are to be included into
template literally) letters to distinguish them from object names where
only the first letter of every word is capitalized.

In our case Page's parser will create yet another instance of Page
displayable object and pass argument "path" with value
"/bits/header-template".  That will include the content of
templates/bits/header-template file into the output. So, if the content
of /bits/header-template file is:

  <HTML><BODY BGCOLOR="#FFFFFF">

And the content of /bits/footer-template is:

  </BODY></HTML>

Then the output produced by the original Page's display would be:

  <HTML><BODY BGCOLOR="#FFFFFF">

  Hello, World!

  </BODY></HTML>

For the actual site you might opt to use specific objects for header and
footer (see L<XAO::DO::Web::Header> and L<XAO::DO::Web::Footer>):

  <%Header title="My first XAO::Web page"%>

  Hello, World!

  <%Footer%>

Page's parser is not limited to only these simple cases, you can embed
references to variables and objects almost everywhere. In the following
example Utility object (see L<XAO::DO::Web::Utility>) is used to
build complete link to a specific page:

  <A HREF="<%Utility mode="base-url"%>/somepage.html">blah blah blah</A>

If current (configured or guessed) site URL is "http://demosite.com/"
this template would be translated into:

  <A HREF="http://demosite.com/somepage.html">blah blah blah</A>

Even more interesting is that you can use embedding to create arguments
for embedded objects:

  <%Date gmtime={<%CgiParam param="shippingtime" default="0"%>}%>

If your page was called with "shippingtime=984695182" argument in the
query then this code would expand to (in PST timezone):

  Thu Mar 15 14:26:22 2001

As you probably noticed, in the above example argument value was in
curly brackets instead of quotes. Here are the options for passing
values for objects' arguments:

=over

=item 1

You can surround value with double quotes: name="value". This is
recommended for short strings that do not include any " characters.

=item 2

You can surround value with matching curly brackets. Curly brackets
inside are allowed and counted so that these expansions would work:

 name={Some text with " symbols}

 name={Multiple
       Lines}

 name={something <%Foo bar={test}%> alsdj}

The interim brackets in the last example would be left untouched by the
parser. Although this example won't work because of unmatched brackets:

 name={single { inside}

See below for various ways to include special symbols inside of
arguments.

=item 3

Just like for HTML files if the value does not include any spaces or
special symbols quotes can be left out:

 number=123

But it is not recommended to use that method and it is not guaranteed
that this will remain legal in future versions. Kept mostly for
compatibility with already deployed code.

=item 4

To pass a string literally without performing any substitutions you can
use single quotes. For instance:

 <%FS
   uri="/Members/<%MEMBER_ID/f%>"
   mode="show-hash"
   fields="*"
   template='<%MEMBER_AGE/f%> -- <%MEMBER_STATUS/f%>'
 %>

If double quotes were used in this example then the parser would try to
expand <%MEMBER_AGE%> and <%MEMBER_STATUS%> variables using the current
object arguments which is not what is intended. Using single quotes it
is possible to let FS object do the expansion and therefore insert
database values in this case.

=item 5

To pass multiple nested arguments literally or to include a single quote
into the string matching pairs of {' and '} can be used:

 <%FS
   uri="/Members/<%MEMBER_ID/f%>"
   mode="show-hash"
   fields="*"
   template={'Member's age is <%MEMBER_AGE/f%>'}
 %>

=back


=head2 EMBEDDING SPECIAL CHARACTERS

Sometimes it is necessary to include various special symbols into
argument values. This can be done in the same way you would embed
special symbols into HTML tags arguments:

=over

=item *

By using &tag; construction, where tag could be "quot", "lt", "gt" and
"amp" for double quote, left angle bracket, right angle bracket and
ampersand respectfully.

=item *

By using &#NNN; construction where NNN is the decimal code for the
corresponding symbol. For example left curly bracket could be encoded as
&#123; and right curly bracket as &#125;. The above example should be
re-written as follows to make it legal:

 name={single &#123; inside}

=back


=head2 OUTPUT CONVERSION

As the very final step in the processing of an embedded object or
variable the parser will check if it has any flags and convert it
accordingly. This can (and should) be used to safely pass special
characters into fields, HTML documents and so on.

For instance, the following code might break if you do not use flags and
variable will contain a duoble quote character in it:

 <INPUT TYPE="TEXT" VALUE="<$VALUE$>">

Correct way to write it would be (note /f after VALUE):

 <INPUT TYPE="TEXT" VALUE="<$VALUE/f$>">

Generic format for specifying flags is:

 <%Object/x ...%> or <$VARIABLE/x$>

Where 'x' could be one of:

=over

=item f

Converts text for safe use in HTML elements attributes. Mnemonic for
remembering - (f)ield.

Will convert '123"234' into '123&quot;234'.

=item h

Converts text for safe use in HTML text. Mnemonic - (H)TML.

Will convert '123<BR>234' into '123&lt;BR&gt;234'.

=item q

Converts text for safe use in HTML query parameters. Mnemonic - (q)uery.

Will convert '123 234' into '123%20234'.

Example: <A HREF="test.html?name=<$VAR/q$>">Test '<$VAR/h$>'</A>

=item s

The same as 'h' excepts that it translates empty string into
'&nbsp;'. Suitable for inserting pieces of text into table cells.

=item u

The same as 'q'. Mnemonic - (U)RL, as it can be used to convert text for
inclusion into URLs.

=back

It is a very good habit to use flags as much as possible and always
specify a correct conversion. Leaving output untranslated may lead to
anything from broken HTML to security violations.

=head2 LEVELS OF PARSING

Arguments can include as many level of embedding as you like, but you
must remember:

=over

=item 1

That all embedded arguments are expanded from the deepest
level up to the top before executing main object.

=item 2

That undefined references to either non-existing object or non-existing
variable produce a run-time error and the page is not shown.

=item 3

All embedded arguments are processed in the same arguments space that
the template one level up from them.

=back

As a test of how you understood everything above please attempt to
predict what would be printed by the following example (after reading
L<XAO::DO::Web::SetArg> or guessing its meaning). The answer is
about one page down, at the end of this chapter.

 <%SetArg name="V1" value="{}"%>
 <%SetArg name="V2" value={""}%>
 <%Page template={<%V1%><%V2%>
 <%Page template={<%SetArg name="V2" value="[]" override%><%V2%>}%>
 <%V2%><%V1%>}
 %>

In most cases it is not recommended to make complex inline templates
though, it is usually better to move sub-templates into a separate file
and include it by passing path into Page. Usually it is also more time
efficient because templates with known paths are cached in parsed state
first time they used while inlined templates are parsed every time.

It is usually good idea to make templates as simple as possible and move
most of the logic inside of objects. To comment what you're doing in
various parts of template you can use normal HTML-style comments. They
are removed from the output completely, so you can include any amounts
of text inside of comments -- it won't impact the size of final HTML
file. Here is an example:

 <!-- Header section -->
 <%Header title="demosite.com"%>
 <%Page path="/bits/menu"%>

 <!-- Main part -->
 <%Page path="/bits/body"%>

 <!-- Footer -->
 <%Footer%>

One exception is JavaScript code which is usually put into comments. The
parser will NOT remove comments if open comment is <!--//. Here is an
example of JavaScript code:

 <SCRIPT LANGUAGE="JAVASCRIPT"><!--//
 function foo ()
 { alert("bar");
 }
 //-->
 </SCRIPT>


=head2 CACHING

Parsed templates are always cached either locally or using a configured
cache. The cache is keyed on 'path' or 'template' parameters value (two
identical 'template's will only parse once). Parse cache can be disabled
by giving an "xao.uncached" parameter. See parse() method description
for details.

The fully rendered content can also be cached if a couple of conditions
are met:

=over

=item *

/xao/page/render_cache_name in the config -- this should contain a name of
the cache to be used for rendered page components.

=item *

The page is configured to be cacheable with either an entry in
the configuration under '/xao/page/render_cache_allow' or with a
'xao.cacheable' parameter given (e.g. something like <%Page ...
xao.cacheable%>).

=item *

There is no "/xao/page/render_cache_update" in the clipboard. This can be used
to force cache reload by checking some environmental variable early in
the flow and setting the clipboard to disable all render caches for that
one render. Cached content is not used, but is updated -- so subsequent
cached calls with the same parameters will return new content.

=item *

There is no "/xao/page/render_cache_skip" in the clipboard. This can be used to
skip cache altogether if it is known that pages rendered in this session
are different from cached and the cache does not want to be contaminated
with them.

=back

Properly used render cache can speed up pages significantly, but if
used incorrectly it can also introduce very hard to find issues in the
rendered content.

Carefully consider what pages to tag with "cacheable" tag. Benchmarking
reports can be of great help for that.

Entries in the config /xao/page/render_cache_allow may include additional
specifications for what parameters are checked when rendered content is
cached. By default, if the value is '1' or 'on' all of Page template
parameters are checked, but none of CGI or cookies. Values for
parameters 'path' and 'template' are always checked, regardless of the
configuration.

The configuration can look like this:

 xao => {
    page => {
        render_cache_name   => 'xao_page_render',
        render_cache_allow  => {
            'p:/bits/complex-template'  => 1,
            'p:/bits/complex-cgi'       => {
                param   => [ '*' ],
                cgi     => [ 'cf*' ],
            },
            'p:/bits/complex-cookie'    => {
                param   => [ '*', '!session*' ],
                cookie  => [ 'session' ],
            },
        },
    },
 }


=head2 BENCHMARKING

Benchmarking can be started and stopped by using benchmark_start()
and benchmark_stop() calls. The hash with current benchmarking data can
be retrieved with benchmark_stats() call.

When benchmarking is started all rendered paths (and optionally all
templates) are timed and are also analyzed for potential cacheability --
if rendered content is repeatedly the same for some set of parameters.

Custom execution paths spanning multiple templates can be tracked by
using benchmark_enter($tag) and benchmark_leave($tag) calls.

The data is "static", not specific to a particular Page object.

Benchmarking slows down processing. Do not use it in production.

For an easy way to control benchmarking from templates use <%Benchmark%>
object.


=head2 NOTE FOR HARD-BOILED HACKERS

If you do not like something in the parser behavior you can define
site-specific Page object and refine or replace any methods of system
Page object. Your new object would then be used by all system and
site-specific objects B<for your site> and won't impact any other sites
installed on the same host. But this is mentioned here merely as a
theoretical possibility, not as a good thing to do.

=head2 TEST OUTPUT

The output of the test above would be:

 {}""
 []
 ""{}

In fact first two SetArg's would add two empty lines in front because
they have carriage returns after them, but this is only significant if
your HTML code is space-sensitive.

=head1 METHODS

Publicly accessible methods of Page (and therefor of all objects derived
from Page unless overwritten) are:

=over

=cut

###############################################################################
package XAO::DO::Web::Page;
use strict;
use Digest::SHA qw(sha1_hex);
use Encode;
use Time::HiRes qw(gettimeofday tv_interval);
use JSON qw(to_json);
use XAO::Cache;
use XAO::Objects;
use XAO::PageSupport;
use XAO::Projects qw(:all);
use XAO::Templates;
use XAO::Utils;
use Error qw(:try);

use base XAO::Objects->load(objname => 'Atom');

# Prototypes
#
sub cache ($%);
sub cgi ($);
sub check_db ($);
sub dbh ($);
sub display ($%);
sub expand ($%);
sub finaltextout ($%);
sub object ($%);
sub odb ($);
sub parse ($%);
sub siteconfig ($);
sub textout ($%);
sub benchmark_enabled ($);
sub benchmark_enter ($$;$$$);
sub benchmark_leave ($$;$$);
sub benchmark_start ($;$);
sub benchmark_stats ($;$);
sub benchmark_stop ($);
sub page_clipboard ($);

sub _do_pass_args ($$$);

###############################################################################

sub params_digest ($$;$) {
    my ($self,$args,$spec)=@_;

    # Dropping non-scalar values from params. They get in by calling
    # ::Action::data_... methods for example, and in other scenarios
    # too.
    #
    my $params={ map { ref $args->{$_} ? () : ($_ => $args->{$_}) } keys %$args };

    # Template and path are always passed along
    #
    my $path=delete $params->{'path'};
    my $template=delete $params->{'template'};

    # Checking what is considered important for the digest, getting a
    # specification. It may come from outside in testing.
    #
    if(!$spec) {
        $spec=$args->{'xao.cacheable'};
    }

    if(!$spec && !defined $args->{'template'} && (my $path=$args->{'path'})) {
        my $cache_allow=$self->{'cache_allow'};
        if($cache_allow) {
            $spec=$cache_allow->{'p:'.$path};
        }
    }

    # It may be a hash of instructions about what to keep and what to
    # drop for the key:
    #
    #   param   => [ 'FOO*', '!FOO.BAR*' ],
    #   cgi     => [ 'fn', 'fv' ],
    #   cookie  => [ 'customer_id' ],
    #
    # Default is to ignore cookies and CGI and hash all scalar
    # parameters.
    #
    my $cgis;
    my $cookies;
    my $protocol;
    if($spec && ref($spec)) {
        while(my ($spec_key,$spec_list)=each %$spec) {
            my $hash;
            my $target;

            if($spec_key eq 'param') {
                $hash=$params;
                $target=\$params;
            }
            elsif($spec_key eq 'cgi') {
                my $cgi=$self->cgi;
                $hash={ map { $_ => [ $cgi->param($_) ] } $cgi->param };
                $target=\$cgis;
            }
            elsif($spec_key eq 'cookie' || $spec_key eq 'cookies') {
                my $config=$self->siteconfig;
                $hash={ map { $_ => $config->get_cookie($_,1) } $self->cgi->cookie() };
                $target=\$cookies;
            }
            elsif($spec_key eq 'proto' && $spec_list) {
                $protocol=$self->is_secure ? 'https' : 'http';
                next;
            }
            else {
                throw $self "- unsupported source '$spec_key' for '$args->{'path'}'";
            }

            $$target=$self->_do_pass_args($hash,$spec_list);
        }
    }

    # Converting to a canonical scalar and calculating a unique digest.
    #
    my $params_json=to_json([$path,$template,$params,$cgis,$cookies,$protocol],{ utf8 => 1, canonical => 1 });

    my $params_digest=sha1_hex($params_json);

    return wantarray ? ($params_digest,$params_json) : $params_digest;
}

###############################################################################

sub _do_display ($@) {
    my $self=shift;
    my $cache_args=get_args(\@_);

    # We need to operate on this specific hash because it can get
    # modified during template processing.
    #
    my $args=$self->{'args'} || throw $self "- no 'args' in self";

    # Preparing to benchmark if requested
    #
    my $benchmark=$self->benchmark_enabled();

    # We need to bookmark buffer position to analyze content data later
    # for cacheability later.
    #
    my $bookmark=$benchmark ? XAO::PageSupport::bookmark() : 0;

    # When called from a cache retrieve we have a cache_key parameter.
    #
    my $from_cache_retrieve=$cache_args->{'cache_key'};
    if($from_cache_retrieve) {
        XAO::PageSupport::push();

        if($self->debug_check('render-cache-add')) {
            my ($args_digest,$args_json)=$self->params_digest($args);
            dprint "RENDER_CACHE_ADD: $args_digest / $args_json";
        }
    }

    # Parsing template or getting already pre-parsed template when it is
    # available.
    #
    # Also defining the tag for benchmarking. Normally it is only
    # defined for paths, but can also be defined for templates.
    #
    my $benchmark_tag;
    my $args_digest;
    my $args_json;
    my $parsed;
    if($benchmark) {
        $parsed=$self->parse($args,{ cache_key_ref => \$benchmark_tag });

        if($benchmark<2 && $benchmark_tag && substr($benchmark_tag,0,2) ne 'p:') {
            $benchmark_tag=undef;
        }
    }
    else {
        $parsed=$self->parse($args);
    }

    # Starting the stopwatch if needed. We may not get a tag if this is
    # an inner pre-parsed template.
    #
    # Calculating a 'run' key that uniquely identifies a specific set of
    # parameters.  Used for two purposes: identifying cacheable pages
    # and benchmarking self-referencing recurrent templates.
    #
    if($benchmark_tag) {
        ($args_digest,$args_json)=$self->params_digest($args);
        $self->benchmark_enter($benchmark_tag,$args_digest,$args_json,$self->can_cache_render($args) ? 1 : 0);
    }

    # Template processing itself. Pretty simple, huh? :)
    #
    foreach my $item (@$parsed) {

        my $stop_after;
        my $itemflag;

        my $text;

        if(exists $item->{'text'}) {
            $text=$item->{'text'};
        }

        elsif(exists $item->{'varname'}) {
            my $varname=$item->{'varname'};
            $text=$args->{$varname};
            defined $text ||
                throw $self "- undefined argument '$varname'";
            $itemflag=$item->{'flag'};
        }

        elsif(exists $item->{'objname'}) {
            my $objname=$item->{'objname'};

            $itemflag=$item->{'flag'};

            # First we're trying to substitute from arguments for old
            # style <%FUBAR%>
            #
            $text=$args->{$objname};

            # Executing object if not.
            #
            if(!defined $text) {
                my $obj=$self->object(objname => $objname);

                # Preparing arguments. If argument includes object references -
                # they are expanded first.
                #
                my %objargs;
                my $ia=$item->{'args'};
                my $args_copy;
                my $page_obj;
                foreach my $a (keys %$ia) {
                    my $v=$ia->{$a};
                    if(ref($v)) {
                        if(@$v==1 && exists($v->[0]->{'text'})) {
                            $v=$v->[0]->{'text'};
                        }
                        else {
                            if(!$args_copy) {
                                $args_copy=merge_refs($args);
                                delete $args_copy->{'path'};
                            }
                            if(!$page_obj) {
                                $page_obj=$self->object(objname => 'Page');
                            }
                            $args_copy->{'template'}=$v;
                            $v=$page_obj->expand($args_copy);
                        }
                    }

                    # Decoding entities from arguments. Lt, gt, amp,
                    # quot and &#DEC; are supported.
                    #
                    $v=~s/&lt;/</sg;
                    $v=~s/&gt;/>/sg;
                    $v=~s/&quot;/"/sg;
                    $v=~s/&#(\d+);/chr($1)/sge;
                    $v=~s/&amp;/&/sg;

                    $objargs{$a}=$v;
                }

                # Executing object. For speed optimisation we call object's
                # display method directly if we're not going to do anything
                # with the text anyway. This way we avoid push/pop and at
                # least two extra memcpy's.
                #
                delete $self->{'merge_args'};
                if($itemflag && $itemflag ne 't') {
                    $text=$obj->expand(\%objargs);
                }
                else {
                    $obj->display(\%objargs);
                }

                # Indicator that we do not need to parse or display anything
                # after that point.
                #
                $stop_after=$self->clipboard->get('_no_more_output');

                # Was it something like SetArg object? Merging changes in then.
                #
                if($self->{'merge_args'}) {
                    @{$args}{keys %{$self->{'merge_args'}}}=values %{$self->{'merge_args'}};
                }
            }
        }

        # Safety conversion - q for query, h - for html, s - for
        # nbsp'ced html, f - for tag fields, u - for URLs, t - for text
        # as is (default).
        #
        if(defined($text) && $itemflag && $itemflag ne 't') {
            if($itemflag eq 'h') {
                $text=XAO::Utils::t2ht($text);
            }
            elsif($itemflag eq 's') {
                $text=(defined $text && length($text)) ? XAO::Utils::t2ht($text) : "&nbsp;";
            }
            elsif($itemflag eq 'q') {
                $text=XAO::Utils::t2hq($text);
            }
            elsif($itemflag eq 'f') {
                $text=XAO::Utils::t2hf($text);
            }
            elsif($itemflag eq 'u') {
                $text=XAO::Utils::t2hq($text);
            }
            elsif($itemflag eq 'j') {
                $text=XAO::Utils::t2hj($text);
            }
            else {
                eprint "Unsupported translation flag '$itemflag', objname=",$item->{'objname'};
            }
        }

        # Sending out the text
        #
        $self->textout($text) if defined($text);

        # Checking if this object required to stop processing
        #
        last if $stop_after;
    }

    # We need to return the actual rendered content if this is called
    # from cache render.
    #
    my $content=undef;
    if($from_cache_retrieve) {
        $content=XAO::PageSupport::pop();
    }
    elsif($benchmark_tag) {
        $content=XAO::PageSupport::peek($bookmark);
    }

    # When benchmarking we stop the timer and we also remember the
    # content for cacheability analysis.
    #
    if($benchmark_tag) {
        my $content_digest=sha1_hex($content);
        $self->benchmark_leave($benchmark_tag,$args_digest,$content_digest);
    }

    # This will be an undef if the call is not from cache. That is fine.
    #
    return $content;
}

###############################################################################

sub _render_cache ($) {
    my $self=$_[0];

    return $self->{'render_cache_obj'} if exists $self->{'render_cache_obj'};

    my $cache_name=$self->siteconfig->get('/xao/page/render_cache_name') || '';

    my $cache_obj;

    if($cache_name) {
        dprint "Using a cache '$cache_name' for rendered templates";

        $cache_obj=$self->cache(
            name        => $cache_name,
            coords      => [ 'cache_key' ],
            retrieve    => \&_do_display,
        );
    }

    $self->{'render_cache_obj'}=$cache_obj;

    return $cache_obj;
}

###############################################################################

# In case of memcached this clears ALL caches, not just render!

sub render_cache_clear ($) {
    my $self=$_[0];

    my $cache=$self->_render_cache;

    $cache->drop_all if $cache;
}

###############################################################################

sub can_cache_render ($$) {
    my ($self,$args)=@_;

    return 0 if $self->page_clipboard->{'render_cache_skip'};

    return 1 if $args->{'xao.cacheable'};

    my $path=!defined $args->{'template'} && $args->{'path'};

    return 0 unless $path;

    my $cache_key='p:' . $path;

    my $cache_allow=$self->{'cache_allow'};
    if(!$cache_allow) {
        $cache_allow=$self->siteconfig->get('/xao/page/render_cache_allow');
        if($cache_allow) {
            $self->{'cache_allow'}=$cache_allow;
        }
        else {
            $cache_allow=$self->{'cache_allow'}={ };
            $self->siteconfig->put('/xao/page/render_cache_allow' => $cache_allow);
        }
    }

    return $cache_allow->{$cache_key};
}

###############################################################################

=item display (%)

Displays given template to the current output buffer. The system uses
buffers to collect all text displayed by various objects in a rather
optimal way using XAO::PageSupport (see L<XAO::PageSupport>)
module. In XAO::Web handler the global buffer is initialized and after all
displayable objects have worked their way it retrieves whatever was
accumulated in that buffer and displays it.

This way you do not have to think about where your output goes as long
as you do not "print" anything by yourself - you should always call
either display() or textout() to print any piece of text.

Display() accepts the following arguments:

=over

=item pass

Passes arguments from calling context into the template.

The syntax allows to map parent arguments into new names,
and/or to limit what is passed. Multiple semi-colon separated rules are
allowed. Rules are processed from left to right.

  NEWNAME=OLDNAME  - pass the value of OLDNAME as NEWNAME
  NEW*=OLD*        - pass all old values starting with OLD as NEW*
  VAR;VAR.*        - pass VAR and VAR.* under their own names
  *;!VAR*          - pass everything except VAR*

The default, when the value of 'pass' is 'on' or '1', is the same as
passing '*' -- meaning that all parent arguments are passed literally
under their own names.

There are exceptions, that are never passed from parent arguments:
'pass', 'objname', 'path', and 'template'.

Arguments given to display() override those inherited from the caller
using 'pass'.

=item path => 'path/to/the/template'

Gives Page a path to the template that should be processed and
displayed.

=item template => 'template text'

Provides Page with the actual template text.

=item unparsed => 1

If set it does not parse template, just displays it literally.

=back

Any other argument given is passed into template unmodified as a
variable. Remember that it is recommended to pass variables using
all-capital names for better visual recognition.

Example:

 $obj->display(path => "/bits/left-menu", ITEM => "main");

For security reasons it is also recommended to put all sub-templates
into /bits/ directory under templates tree or into "bits" subdirectory
of some tree inside of templates (like /admin/bits/admin-menu). Such
templates cannot be displayed from XAO::Web handler by passing their
path in URL.

=cut

sub display ($%) {
    my $self=shift;
    my $args=$self->{'args'}=get_args(\@_);

    # Merging parent's args in if requested.
    #
    if($args->{'pass'}) {
        $args=$self->{'args'}=$self->pass_args($args->{'pass'},$args);
    }

    # Is this page cacheable? There is a distinction between page not
    # being cached with '/xao/page/render_cache_skip' and page being flushed in
    # cache with '/xao/page/render_cache_update'.
    #
    if($self->can_cache_render($args)) {
        if(my $cache=$self->_render_cache()) {

            # The key depends on all arguments.
            #
            my ($cache_key,$params_json)=$self->params_digest($args);

            if($self->debug_check('render-cache-get')) {
                dprint "RENDER_CACHE_GET: $cache_key / $params_json";
            }

            # Building the content. Real arguments for displaying are in
            # $self->{'args'}.
            #
            my $content=$cache->get($self,{
                cache_key       => $cache_key,
                force_update    => ($self->page_clipboard->{'render_cache_update'} || $args->{'xao.uncached'}),
            });

            XAO::PageSupport::addtext($content);

            return;
        }
    }

    # We get here if the page cannot be cached
    #
    $self->_do_display();
}

###############################################################################

=item expand (%)

Returns a string corresponding to the expanded template. Accepts exactly
the same arguments as display(). Here is an example:

 my $str=$obj->expand(template => '<%Date%>');

=cut

sub expand ($%) {
    my $self=shift;

    # First it prepares a place in stack for new text (push) and after
    # display it calls pop to get back whatever was written. The sole
    # reason for all this is speed optimization - XAO::PageSupport is
    # implemented in C in quite optimal way.
    #
    XAO::PageSupport::push();

    # Not using Error's try{} -- it is too slow. Benchmarking showed
    # about 7% slowdown.
    #
    ### my $args=get_args(\@_);
    ### try {
    ###     $self->display($args);
    ### }
    ### otherwise {
    ###     my $e=shift;
    ###
    ###     # Popping out the potential output of the failed
    ###     # template. Otherwise we are going to break the stack order.
    ###     #
    ###     XAO::PageSupport::pop();
    ###
    ###     $e->throw();
    ### };

    # Eval is faster, almost indistinguishable from the bare call on
    # benchmark results.
    #
    eval {
        $self->display(@_);
    };

    if($@) {
        XAO::PageSupport::pop();

        if($@->can('throw')) {
            throw $@;
        }
        else {
            throw $self "- $@";
        }
    }

    return XAO::PageSupport::pop();
}

###############################################################################

=item parse ($%)

Takes template from either 'path' or 'template' and parses it. If given
the following template:

    Text <%Object a=A b="B" c={X<%C/f ca={CA}%>} d='D' e={'<$E$>'}%>

It will return a reference to an array of the following structure:

    [   {   text    => 'Text ',
        },
        {   objname => 'Object',
            args    => {
                a => [
                    {   text    => 'A',
                    },
                ],
                b => [
                    {   text    => 'B',
                    },
                ],
                c => [
                    {   text    => 'X',
                    },
                    {   objname => 'C',
                        flag    => 'f',
                        args    => {
                            ca => [
                                {   text    => 'CA',
                                },
                            ],
                        },
                    },
                ],
                d => 'D',
                e => '<$E$>',
            },
        },
    ]

With "unparsed" parameter the content of the template is not analyzed
and is returned as a single 'text' node.

Templates are only parsed once, unless an "xao.uncached" parameter is
set to true.

Normally the parsed templates cache uses a local perl hash. If
desired a XAO::Cache based implementation can be used by setting
/xao/page/parse_cache_name parameter in the site configuration to the desired
cache name (e.g. "xao_parse_cache").

Statistics of various ways of calling:

    memcached-cache-path       1866/s
    memcached-cache-template   2407/s
    no-cache-path              5229/s
    no-cache-template          5572/s
    memory-cache-template     26699/s
    memory-cache-path         45253/s
    local-cache-template      49681/s
    local-cache-path         149806/s

Unless the site has a huge number of templates there is really no
compelling reason to use anything but the default local cache. The
performance of memcached is worse than no caching at all for example.

The method always returns with a correct array or throws an error.

=cut

sub parse_retrieve ($@);

my %parsed_cache;

sub parse ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $unparsed=$args->{'unparsed'};

    my $uncached=$args->{'xao.uncached'};

    # Preparing a short key that uniquely identifies the template given
    # (by either a path or an inline text). Uniqueness is only needed
    # within the site context. Global scope uniqueness is dealt with by
    # cache implementations below.
    #
    my $template;
    my $path;
    my $cache_key;
    if(defined($args->{'template'})) {
        $template=$args->{'template'};

        if(ref($template)) {
            return $template;       # Pre-parsed as an argument of some upper class
        }

        $template=Encode::encode('utf8',$template) if Encode::is_utf8($template);

        if(length $template < 80) {
            $cache_key=($unparsed ? 'T' : 't').':'.$template;
        }
        else {
            $cache_key=($unparsed ? 'H' : 'h').':'.sha1_hex($template);
        }
    }
    else {
        $path=$args->{'path'} ||
            throw $self "- no 'path' and no 'template' given to a Page object";

        $cache_key=($unparsed ? 'P' : 'p').':'.$path;
    }

    # Remembering the key if needed. It is used for benchmark cache.
    #
    my $cache_key_ref=$args->{'cache_key_ref'};
    $$cache_key_ref=$cache_key if $cache_key_ref;

    # With uncached we don't even try to use any caches.
    #
    my $parsed;
    if($uncached) {
        $parsed=$self->parse_retrieve($args);
    }

    # Caching either locally, or in a standard cache
    #
    else {

        # Setup, only executed once.
        #
        my $cache_name=$self->{'parse_cache_name'};
        if(!defined $cache_name) {
            $cache_name=$self->{'parse_cache_name'}=$self->siteconfig->get('/xao/page/parse_cache_name') || '';
        }

        # A fast totally local implementation.
        #
        # About two times faster than a memcached, but grows a template
        # cache per-process.
        #
        if(!$cache_name) {

            # Making it unique per site
            #
            my $sitename=$self->{'sitename'} || get_current_project_name() || '';
            $cache_key=$sitename . ':' . $cache_key;

            # Checking if we have parsed and cached this before
            #
            $parsed=$parsed_cache{$cache_key};

            return $parsed if defined $parsed;

            # Reading and parsing.
            #
            $parsed=$self->parse_retrieve($args);

            # Caching the parsed template.
            #
            $parsed_cache{$cache_key}=$parsed;

            # Logging the size
            #
            if($self->debug_check('page-cache-size')) {
                $self->cache_show_size($cache_key);
            }
        }

        # More generic implementation that can be switched from local to
        # memcached to anything else
        #
        else {
            my $cache=$self->{'parse_cache_obj'};
            if(!$cache) {
                dprint "Using a named cache '$cache_name' for parsed templates";

                $cache=$self->{'parse_cache_obj'}=$self->siteconfig->cache(
                    name        => $cache_name,
                    coords      => [ 'cache_key' ],
                    retrieve    => \&parse_retrieve,
                );
            }

            $parsed=$cache->get($self,$args,{
                cache_key       => $cache_key,
                force_update    => $uncached,
            });
        }
    }

    return $parsed;
}

###############################################################################

sub parse_retrieve ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $path=$args->{'path'};
    my $template=$args->{'template'};
    my $unparsed=$args->{'unparsed'};

    # Reading and parsing.
    #
    if($path && !defined $template) {
        if($self->debug_check('show-read')) {
            dprint $self->{'objname'}."::parse - read path='$path'";
        }

        $template=XAO::Templates::get(path => $path);

        defined($template) ||
            throw $self "- no template found (path=$path)";
    }

    # Unless we need an unparsed template - parse it
    #
    my $parsed;
    if($unparsed) {
        $parsed=[ { text => $template } ];
    }
    else {

        # Logging the template or path if requested.
        #
        if($self->debug_check('show-parse')) {
            if($path) {
                dprint $self->{'objname'}."::parse - parsing path='$path'"
            }
            else {
                my $te=substr($template,0,20);
                $te=~s/\r/\\r/sg;
                $te=~s/\n/\\n/sg;
                $te=~s/\t/\\t/sg;
                $te.='...' if length($template)>20;
                dprint $self->{'objname'}."::parse - parsing template='$te'";
            }
        }

        # Parsing. If a scalar is returned it is an indicator of an error.
        #
        $parsed=XAO::PageSupport::parse($template);

        ref $parsed ||
            throw $self "- $parsed";
    }

    return $parsed;
}

###############################################################################

=item object (%)

Creates new displayable object correctly tied to the current one. You
should always get a reference to a displayable object by calling this
method, not by using XAO::Objects' new() method. Currently most
of the objects would work fine even if you do not, but this is not
guaranteed.

Possible arguments are (the same as for XAO::Objects' new method):

=over

=item objname => 'ObjectName'

The name of an object you want to have an instance of. Default is
'Page'. All objects are assumed to be in XAO::DO::Web namespace,
prepending them with 'Web::' is optional.

=item baseobj => 1

If present then site specific object is ignored and system object is
loaded.

=back

Example of getting Page object:

 sub display ($%) {
     my $self=shift;
     my $obj=$self->object;
     $obj->display(template => '<%Date%>');
 }

Or even:

 $self->object->display(template => '<%Date%>');

Getting FilloutForm object:

 sub display ($%) {
     my $self=shift;
     my $ff=$self->object(objname => 'FilloutForm');
     $ff->setup(...);
     ...
  }

Object() method always returns object reference or throws an exception
- meaning that under normal circumstances you do not need to worry
about returned object correctness. If you get past the call to object()
method then you have valid object reference on hands.

=cut

sub object ($%) {
    my $self=shift;
    my $args=get_args(@_);

    my $objname=$args->{objname} || 'Page';
    $objname='Web::' . $objname unless substr($objname,0,5) eq 'Web::';

    XAO::Objects->new(
        objname => $objname,
        parent => $self,
    );
}

###############################################################################

=item textout ($)

Displays a piece of text literally, without any changes.

It used to be called as textout(text => "text") which is still
supported for compatibility, but is not recommended any more. Call it
with single argument -- text to be displayed.

Example:

 $obj->textout("Text to be displayed");

This method is the only place where text is actually gets displayed. You
can override it if you really need some other output strategy for you
object. Although it is not recommended to do so.

=cut

sub textout ($%) {
    my $self=shift;
    return unless @_;
    if(@_ == 1) {
        XAO::PageSupport::addtext($_[0]);
    }
    else {
        my %args=@_;
        XAO::PageSupport::addtext($args{text});
    }
}

###############################################################################

=item finaltextout ($)

Displays some text and stops processing templates on all levels. No more
objects should be called in this session and no more text should be
printed.

Used in Redirect object to break execution immediately for example.

Accepts the same arguments as textout() method.

=cut

sub finaltextout ($%) {
    my $self=shift;
    $self->textout(@_);
    $self->clipboard->put(_no_more_output => 1);
}

###############################################################################

=item dbh ()

Returns current database handler or throws an error if it is not
available.

Example:

 sub display ($%)
     my $self=shift;
     my $dbh=$self->dbh;

     # if you got this far - you have valid DB handler on hands
 }

=cut

sub dbh ($) {
    my $self=shift;
    return $self->{dbh} if $self->{'dbh'};
    $self->{dbh}=$self->siteconfig->dbh;
    return $self->{dbh} if $self->{dbh};
    throw $self "- no database connection";
}

###############################################################################

=item odb ()

Returns current object database handler or throws an error if it is not
available.

Example:

 sub display ($%) {
     my $self=shift;
     my $odb=$self->odb;

     # ... if you got this far - you have valid DB handler on hands
 }

=cut

sub odb ($) {
    my $self=shift;
    return $self->{odb} if $self->{odb};

    $self->{odb}=$self->siteconfig->odb;
    return $self->{odb} if $self->{odb};

    throw $self "- requires object database connection";
}

###############################################################################

=item cache (%)

A shortcut that actually calls $self->siteconfig->cache. See the
description of cache() in L<XAO::DO::Web::Config> for more details.

=cut

sub cache ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    return $self->siteconfig->cache($args);
}

###############################################################################

=item cgi ()

Returns CGI object reference (see L<CGI>) or throws an error if it is
not available.

=cut

sub cgi ($) {
    my $self=shift;
    $self->siteconfig->cgi;
}

###############################################################################

=item clipboard ()

Returns clipboard object, which inherets XAO::SimpleHash methods. Use
this object to pass data between various objects that work together to
produce a page. Clipboard is cleaned before starting every new session.

=cut

sub clipboard ($) {
    my $self=shift;
    my $clipboard=$self->{'clipboard'};
    if(!$clipboard) {
        $clipboard=$self->{'clipboard'}=$self->siteconfig->clipboard;
    }
    return $clipboard;
}

###############################################################################

=item siteconfig ()

Returns site configuration reference. Be careful with your changes to
configuration, try not to change configuration -- use clipboard to pass
data between objects. See L<XAO::Projects> for more details.

=cut

sub siteconfig ($) {
    my $self=shift;
    my $siteconfig=$self->{'siteconfig'};
    if(!$siteconfig) {
        $siteconfig=$self->{'siteconfig'}=
            $self->{'sitename'} ? get_project($self->{'sitename'})
                                : get_current_project();
    }
    return $siteconfig;
}

###############################################################################

=item base_url (%)

Returns base_url for secure or normal connection. Depends on parameter
"secure" if it is set, or current state if it is not.

If 'active' parameter is set then will return active URL, not the base
one. In most practical cases active URL is the same as base URL except
when your server is set up to answer for many domains. Base will stay
at what is set in the site configuration and active will be the one
taken from the Host: header.

Examples:

 # Returns secure url in secure mode and normal
 # url in normal mode.
 #
 my $url=$self->base_url;

 # Return secure url no matter what
 #
 my $url=$self->base_url(secure => 1);

 # Return normal url no matter what
 #
 my $url=$self->base_url(secure => 0);

 # Return secure equivalent of the current active URL
 #
 my $url=$self->base_url(secure => 1, active => 1);

=cut

sub base_url ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $secure=$args->{secure};
    $secure=$self->is_secure unless defined $secure;

    my $active=$args->{active};

    my $url;
    if($secure) {
        $url=$active ? $self->clipboard->get('active_url_secure')
                     : $self->siteconfig->get('base_url_secure');
    } else {
        $url=$active ? $self->clipboard->get('active_url')
                     : $self->siteconfig->get('base_url');
    }

    return $url;
}

###############################################################################

=item is_secure ()

Returns 1 if the current the current connection is a secure one or 0
otherwise.

=cut

sub is_secure ($) {
    my $self=shift;
    return $self->cgi && $self->cgi->https() ? 1 : 0;
}

###############################################################################

=item pageurl (%)

Returns full URL of current page without parameters. Accepts the same
arguments as base_url() method.

=cut

sub pageurl ($;%) {
    my $self=shift;

    my $pagedesc=$self->clipboard->get('pagedesc') ||
        throw $self "- no Web context, needs clipboard->'pagedesc'";

    my $url=$self->base_url(@_);
    my $uri=$pagedesc->{fullpath} || '/';
    $uri="/".$uri unless substr($uri,0,1) eq '/';

    return $url.$uri;
}

###############################################################################

=item decode_charset ($) {

If there is 'charset' defined in the site configuration then decodes the
argument using that charset. Otherwise returns the string unchanged.

=cut

sub decode_charset ($$) {
    my ($self,$text)=@_;
    return $text if Encode::is_utf8($text);
    if(my $charset=$self->siteconfig->get('charset')) {
        return Encode::decode($charset,$text);
    }
    else {
        return $text;
    }
}

###############################################################################

sub _do_pass_args ($$$) {
    my ($self,$pargs,$spec)=@_;

    my $hash={ };

    foreach my $rule (@$spec) {
        $rule=~s/^\s*(.*?)\s*$/$1/;

        ### dprint "...rule='$rule'";

        if($rule eq '*') {
            $hash=merge_refs($pargs,$hash);
        }
        elsif($rule =~ /^([\w\.]+)\s*=\s*([\w\.]+)$/) {     # VAR=FOO
            $hash->{$1}=$pargs->{$2};
        }
        elsif($rule =~ /^([\w\.]*)\*([\w\.]*)\s*=\s*([\w\.]*)\*([\w\.]*)$/) {# VAR*=FOO* or *VAR=*FOO or V*R=T*Z or *=X*Z
            my ($prnew,$sufnew,$prold,$sufold)=($1,$2,$3,$4);
            my $re=qr/^\Q$prold\E(.*)\Q$sufold\E$/;
            foreach my $k (keys %$pargs) {
                next unless $k =~ $re;
                $hash->{$prnew.$1.$sufnew}=$pargs->{$k};
            }
        }
        elsif($rule =~ /^([\w\.]+)$/) {                     # VAR
            $hash->{$1}=$pargs->{$1};
        }
        elsif($rule =~ /^([\w\.]*)\*([\w\.]*)$/) {          # VAR* or *VAR or VAR*FOO
            my ($pr,$suf)=($1,$2);
            my $re=qr/^\Q$pr\E(.*)\Q$suf\E$/;
            foreach my $k (keys %$pargs) {
                next unless $k =~ $re;
                $hash->{$k}=$pargs->{$k};
            }
        }
        elsif($rule =~ /^!([\w\.]+)$/) {                    # !VAR
            delete $hash->{$1};
        }
        elsif($rule =~ /^!([\w\.]*)\*([\w\.]*)$/) {                  # !VAR* or !*VAR or !VAR*FOO
            my ($pr,$suf)=($1,$2);
            my $re=qr/^\Q$pr\E(.*)\Q$suf\E$/;
            my @todel;
            foreach my $k (keys %$hash) {
                next unless $k =~ $re;
                push(@todel,$k);
            }
            delete @{$hash}{@todel};
        }
        elsif($rule eq '!*') {
            $hash={};
        }
        elsif($rule eq '') {
            # no-op
        }
        else {
            throw $self "- don't know how to pass for '$rule'";
        }
    }

    return $hash;
}

###############################################################################

=item pass_args ($) {

Helper method for supporting "pass" argument in web objects. Synopsis:

    $page->display($page->pass_args($args->{'pass'},$args),{
        path        => $args->{'blah.path'},
        template    => $args->{'blah.template'},
        FOO         => 'bar',
    });

If "pass" argument is not defined it will just return the original args,
otherwise the following rules are supported:

    "on" or "1"     - pass all arguments from parent object
    "VAR=FOO"       - pass FOO from parent as VAR
    "VAR*=FOO*"     - pass FOO* from parent renaming as VAR*
    "*=FOO*"        - pass FOO* from parent stripping FOO
    "VAR"           - pass only VAR from parent
    "VAR*"          - pass only VAR* from parent

Multiple pass specifications can be given with semi-colon delimiter.

Several special tags are deleted from parent arguments: pass, path,
template, and objname.

=cut

sub pass_args ($$;$) {
    my ($self,$pass,$args)=@_;

    $args||={ };

    # The first argument is the content of 'pass', if it's not defined
    # we return unadulteraded arguments.
    #
    return $args unless $pass;

    # If we don't have parent arguments then there is nothing to do.
    #
    my $pargs;
    if(!$self->{'parent'} || !($pargs=$self->{'parent'}->{'args'})) {
        return $args;
    }

    # Simplified (old) way of calling with just <%Page pass
    # template='xxx'%> would result in pass being 'on'.
    #
    if($pass eq 'on' || $pass eq '1') {
        $pass='*';
    }

    # Building inherited hash.
    #
    my $hash=$self->_do_pass_args($pargs,[split(/;/,$pass)]);

    # Always deleting pass, path and template
    #
    delete @{$hash}{'pass','objname','path','template'};

    # This is it, merging with the arguments given to us and returning
    #
    return merge_refs($hash,$args);
}

###############################################################################

sub benchmark_enabled ($) {
    my $self=shift;
    $self->clipboard->get('_page_benchmark_enabled') || 0;
}

###############################################################################

sub _benchmark_hash ($) {
    my $self=shift;

    my $stats=$self->{'benchmark_stats'};

    if(!$stats) {
        $stats=$self->siteconfig->get('_page_benchmark_stats');
        if($stats) {
            $self->{'benchmark_stats'}=$stats;
        }
        else {
            $stats=$self->{'benchmark_stats'}={ };
            $self->siteconfig->put('_page_benchmark_stats' => $stats);
        }
    }

    return $stats;
}

###############################################################################

sub benchmark_tag_data ($$) {
    my ($self,$tag,$key)=@_;

    $tag || throw $self "- no 'tag'";

    $key||='-';

    ref $tag && throw $self "- tag '$tag' is not a scalar";

    my $stats=$self->_benchmark_hash();

    my $tagdata=$stats->{$tag};

    if(!$tagdata) {
        $tagdata=$stats->{$tag}={
            count   => 0,
            total   => 0,
            last    => [ ],
            runs    => { },
        };
    }

    my $rundata=$tagdata->{'runs'};
    $rundata->{$key}||={ };
    $rundata=$rundata->{$key};

    return wantarray ? ($tagdata,$rundata,$key) : $tagdata;
}

###############################################################################

=item benchmark_enter($;$$$)

Start tracking the given tag execution time until benchmark_leave() is
called on the same tag.

An optional second argument can contain a unique key that identifies a
specific run for the tag (in case of recurrent tag execution). The third
optional argument is a description of this run.

=cut

sub benchmark_enter ($$;$$$) {
    my ($self,$tag,$key,$description,$cache_flag)=@_;

    my ($tagdata,$rundata);
    ($tagdata,$rundata,$key)=$self->benchmark_tag_data($tag,$key);

    if($rundata->{'started'}) {
        eprint "Benchmark for '$tag' (key '$key') not finished, discarding";
    }

    $description||='';
    $rundata->{'description'}=length $description > 100 ? substr($description,0,100) : $description;

    $rundata->{'cache_flag'}=$cache_flag ? 1 : 0;

    $rundata->{'started'}=[ gettimeofday ];
}

###############################################################################

=item benchmark_leave ($)

Stop time tracking for the given tag and record tracking results in the
history.

=cut

sub benchmark_leave ($$;$$) {
    my ($self,$tag,$key,$content_digest)=@_;

    my ($tagdata,$rundata);
    ($tagdata,$rundata,$key)=$self->benchmark_tag_data($tag,$key);

    ### dprint to_json($tagdata);

    my $started=$rundata->{'started'};
    if(!$started) {
        eprint "Benchmark for '$tag' (key '$key') was not started";
        return;
    }

    my $taken=tv_interval($started);

    # For median calculation
    #
    my $last=$tagdata->{'last'};
    push(@$last,$taken);
    shift(@$last) if scalar(@$last) > 50;

    ++$tagdata->{'count'};
    ++$rundata->{'count'};

    $tagdata->{'total'}+=$taken;
    $rundata->{'total'}+=$taken;

    # Remembering the content for cacheability analysis.
    #
    $content_digest||='-';
    ++$rundata->{'content'}->{$content_digest};

    # Resetting for the next run
    #
    $rundata->{'started'}=undef;
}

###############################################################################

=item benchmark_start(;$)

Start automatic system-wide page rendering benchmarking.

By default only 'path' based rendering is benchmarked. If an optional
single argument is set to '2' then templates are also benchmarked (this
may demand a lot of extra memory!).

=cut

sub benchmark_start ($;$) {
    my ($self,$level)=@_;
    $self->clipboard->put('_page_benchmark_enabled' => ($level || 1));
}

###############################################################################

=item benchmark_stop()

Stop automatic system-wide rendering benchmarking.

=cut

sub benchmark_stop ($) {
    my $self=shift;
    $self->clipboard->put('_page_benchmark_enabled' => 0);
}

###############################################################################

=item benchmark_stats

Return a hash with accumulated benchmark statistics.

=cut

sub benchmark_stats ($;$) {
    my ($self,$desired_tag)=@_;

    my $stats=$self->_benchmark_hash();

    my %analyzed;

    foreach my $tag (keys %$stats) {
        my $d=$stats->{$tag};
        next unless $d->{'count'};
        next if $desired_tag && $tag ne $desired_tag;

        $d->{'average'}=$d->{'total'} / $d->{'count'};
        $d->{'median'}=$d->{'last'}->[scalar(@{$d->{'last'}})/2];

        # The page is cacheable if the content only depends on
        # parameters and not on clipboard, cookies, CGI, time, or other
        # environment.
        #
        $d->{'cacheable'}=scalar(grep {
            scalar(keys %{$d->{'runs'}->{$_}->{'content'}}) != 1
        } keys %{$d->{'runs'}}) ? 0 : 1;

        # Current cacheable flag, if it's shared across all runs
        #
        $d->{'cache_flag'}=scalar(grep {
            ! $d->{'runs'}->{$_}->{'cache_flag'}
        } keys %{$d->{'runs'}}) ? 0 : 1;

        $analyzed{$tag}=$d;
    }

    ### dprint to_json(\%analyzed,{ utf8 => 1, canonical => 1, pretty => 1 });

    return \%analyzed;
}

###############################################################################

sub cache_show_size ($$) {
    my ($self,$path)=@_;

    eval {
        require Devel::Size;
    };

    if($@) {
        eprint "Devel::Size not available, disabling debug 'page-cache-size'";
        $self->debug_set('cache-size' => 0);
        return;
    }

    my $size=Devel::Size::total_size(\%parsed_cache);

    eprint "Web::Page cache size ".sprintf('%.3f',$size/1024.0)." KB - ",$path;
}

###############################################################################

sub debug_check ($$) {
    my ($self,$type)=@_;

    # This is a speed up (makes the parsing more than twice faster when a
    # local parsing cache is also used).
    #
    #   8 wallclock secs ( 8.78 usr +  0.01 sys =  8.79 CPU) @ 113765.64/s (n=1000000)
    #  19 wallclock secs (18.97 usr +  0.00 sys = 18.97 CPU) @ 52714.81/s (n=1000000)
    #
    ### return $self->clipboard->get("debug/Web/Page/$type");

    my $debug_hash=$self->{'debug_hash'};

    if(!$debug_hash) {
        $debug_hash=$self->clipboard->get('/debug/Web/Page');
        if($debug_hash) {
            $self->{'debug_hash'}=$debug_hash;
        }
        else {
            $self->{'debug_hash'}=$debug_hash={ };
            $self->clipboard->put('/debug/Web/Page' => $debug_hash);
        }
    }

    return $debug_hash->{$type};
}

###############################################################################

sub debug_set ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    foreach my $type (keys %$args) {
        $self->clipboard->put("/debug/Web/Page/$type",$args->{$type} ? 1 : 0);
    }
}

###############################################################################

sub page_clipboard ($) {
    my $self=shift;

    my $cb_hash=$self->{'page_clipboard'};

    if(!$cb_hash) {
        $cb_hash=$self->clipboard->get('/xao/page');
        if($cb_hash) {
            $self->{'page_clipboard'}=$cb_hash;
        }
        else {
            $self->{'page_clipboard'}=$cb_hash={ };
            $self->clipboard->put('/xao/page' => $cb_hash);
        }
    }

    return $cb_hash;
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::Objects>,
L<XAO::Projects>,
L<XAO::Templates>.
L<XAO::DO::Web::Benchmark>.

=cut
