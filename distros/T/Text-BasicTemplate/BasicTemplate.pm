#!/usr/bin/perl -w
# $Id: BasicTemplate.pm,v 1.31 2000/02/22 01:55:52 aqua Exp $

package Text::BasicTemplate;

use strict;
use re 'taint';
require 5;

require Exporter;
require AutoLoader;

use vars qw($VERSION);
$VERSION = "2.006.1";

use Fcntl qw(:DEFAULT :flock);

=head1 NAME

  Text::BasicTemplate -- Simple lexical text/html/etc template parser

=cut

=head1 SYNOPSIS

 use Text::BasicTemplate;
 $bt = Text::BasicTemplate->new;
 my %dict = (
   name => 'John',
   location => sub { hostname() },
   condiments => [ 'Salt', 'Pepper', 'Catsup' ],
   sideeffects => { 'Salt' => 'causes high blood pressure',
		    'Pepper' => 'causes mariachi music',
		    'Catsup' => 'brings on warner bros. cartoons' },
   new => int rand 2
 );

 $tmpl = "Hello, %name%; your mail is in %$MAIL%. Welcome to %location%!";
 print $bt->parse(\$tmpl,\%dict);

 $tmpl = "%if new%First time, %name%?%fi%".
         " Care for some %condiments%? ".
         " They are bad for you.  %sideeffects%."
 $bt->{hash_specifier}->{condiments} = ' ';
 print $bt->parse(\$tmpl,\%dict);

=head1 DESCRIPTION

B<Text::BasicTemplate> is a relatively straightforward template
parsing module.  Its overall function is to permit the separation
of format-dependent output from code.

This module provides standard key/value substitutions, lexical
evaluation/parsing, customizable formatting of perl datatypes,
and assorted utility functions.

Templates may be structured by the use of arbitrarily nestable
if-conditions (including elsif and else), and by the use of
subroutine substitutions to provide list parsing.  In general,
the syntax for conditionals is that of perl itself.

Text::BasicTemplate attempts to be as fast and as secure as
possible.  It may be safely used upon tainted templates and
with tainted substitutions without fear of execution of any
malicious code.

=head1 GETTING STARTED

If you have previously used Text::BasicTemplate v0.x, it is
important to read the COMPATIBILITY section -- many things
have changed, and compatibility is not guaranteed to be
preserved in future versions.

In general, start with the SYNTAX section, and be sure to
at least skim the new() section (for configuration settings)
and parse() section (for an explanation of the dictionary).

=head1 SYNTAX

One of the difficulties in employing a new template parser is
picking up the apropriate syntax.  Text::BasicTemplate does
not spare you that, but it does adhere fairly closely to
the syntax of perl itself with respect to operators,
conditional operations, template subroutine calls, etc.

Anything to which Text::BasicTemplate should pay attention in
a template is enclosed in percentage signs (%) -- any such
segments will be interpreted as identifiers, operations,
conditionals, or apropriate combinations thereof.

The simplest of these are variable substitutions; if parse()
was passed a dictionary containing the pair (foo => "bar"), any instances
of %foo% in the template will be evaluated as "bar."  Other
variable substitutions are available for lists and hashes,
passed by reference in the parse() dictionary, as in
(bar => \@r, snaf => \%h).  In such a case %bar% will be
evaluated to the contents of @r, and %snaf% to the contents
of %h.  Both will be formatted according to the configured
delimiters (see B<LIST/HASH FORMATTING>).  Subroutine
references may also be included in the dictionary; in their
simple form, given ( subref => \&myfunction ), %subref% in
the template will be evaluated to whatever is returned from
&myfunction().  For more detail and features in subroutine
handling, see B<SUBROUTINE SUBTITUTIONS>.

In v0.9.7, BasicTemplate introduced simple conditional
evaluation, providing one-level equality/inequality
comparisons.  In 2.0, after a total rewrite, the conditional
evaluation was replaced with a lexically parsed scoping
evaluation, providing arbitrarily deep nesting, most major
unary and binary perl comparison operators, arbitrary
combination of operations, nonconditional evaluation, etc.
For the full explanation, read on:

=head2 SCOPING

Scoped evaluation is available to arbitrary depths, following
the usual if/elsif/else pattern.  B<if> conditions are terminated
by a B<fi>.  By example:

 # single if
 %if <condition>%
   <block>
 %fi%

 # if-else
 %if <condition>%
   <block>
 %else%
   <block2>
 %fi%

 # if-elsif
 %if <condition>%
   <block>
 %elsif <alternate condition>%
   <block2>
 %fi%

 # if-else-elsif
 %if <condition>%
   <block>
 %elsif <alternate condition>%
   <block2>
 %else%
   <block3>
 %fi%

A B<block> above is some amount of further template contents, including
none (%if <condition>%%fi% is perfectly valid, albeit not generally
useful).  A block may contain further conditions.  Dictionary variables
used in a conditional will only be evaluated if they come into scope --
for example, an elsif will not be evaluated unless its preceeding if or
elsif evaluted false -- the principal consequence of this is that
subroutines referenced in a conditional will be called only if they
come into scope per the above.

=head2 IDENTIFIERS

Numeric literals may be given without alteration, e.g. %123%.

String literals should be given in double quotes, e.g. %"hello"%,
or in single quotes, e.g. %'goodbye'%.  Either sort may contain
quotes of the other sort.

Scalar, list and hash variables should be given by name,
e.g. %foo%.

%% gives a literal % sign and is considered normal text.

Environment variables may be used as %$PATH%.

Subroutine references should generally be referenced as %&foo%,
or %&foo(arg1,arg2,...)% as apropriate.  %foo% may be used for
subroutines that return a scalar and will not require further
parsing of their output -- see B<SUBROUTINE SUBSTITUTIONS>.


=head2 EVALUATION

Statements, conditional or otherwise, may be used outside of if/else
contexts, and will have the results of the evaluation inserted at
the point in which they occurred in the template.  If used in an
if/else statement, they will be evaluated, but the apropriate block
will be output instead (pretty much the usual, IOW).

I<There is no operator precedence or conditional short-circuiting.>
%1 || 2% will evaluate both 1 and 2 (and return 2).  Evaluation order
is not guaranteed.  For all matters requiring precedence, parentheses
should be employed (e.g. %1 && (0 || 3)%).

Most of the perl unary and binary operators are supported; the trinary
conditional is not.  Operators presently provided are as follows:

B<eq ne lt le gt ge> -- identical to their perl equivalents.  Return
1 or false.

B<=~ !~> -- also equivalent to the perl versions, but must be enabled
by setting B<enable_pattern_operator> true (see new()), as a malformed
pattern may kill the script -- so do not use them if you think you might
be evaluating untrusted untrusted templates.  The form for these is
=~ pattern, not =~ /pattern/.

B<== != E<lt> E<lt>= E<gt> E<gt>= E<lt>=E<gt>> -- perl equivalent

B<&& and || or> -- the two ands and the two ors are considered
equivalent, as there is no operator precedence in BasicTemplate.
&& and and return the value of the last operand.

B<. x> -- perl equivalent; operand for x must be numeric.

B<+ - * / **> -- perl equivalent, divide-by-zero will be checked.

B<div mod> -- equivalent to int(x/y) and x % y respectively.

B<^ & | E<lt>E<lt> E<gt>E<gt>> -- perl equivalent

B<! defined> -- perl equivalent.  

Examples:
%foo + bar% -- evaluates to result of foo+bar, where foo and bar
are variables given in the dictionary.

%if foo && (bar || snaf)%
  <block>
%fi% -- evaluates foo, bar and snaf, outputs the block if the
foo and one or more of bar and snaf were true.

%"your name: " . &yourname% -- outputs the string "your name: ",
followed by whatever was returned by the subroutine referenced
by the dictionary entry for yourname.

%if $MAIL =~ Maildir%
  Bernstein would be proud.
%else%
  Eric Allman wants you for a sunbeam.
%fi% -- evaluates according to whether the environment variable
$MAIL contains the pattern 'Maildir.'

Note that blocks inside conditional statements begin immediately
following the closing %, so in the above examples, the newline
and spaces would be considered part of the block and output if
the condition evaluated true.  This is acceptable for most
whitespace-independent usages, but you should not include whitespace
in a conditional block if you do not want it in the output.

=head2 LIST/HASH FORMATTING

List references will be parsed and  delimited according to
$obj->{list_delimiter}->{listname} if supplied, and
$obj->{list_delimiter}->{__default} if not (the latter is
set with the default_list_delimiter argument to new()).  The default
is ", ".

Hash references will be delimited using $obj->{hash_delimiter}->{hashname}
between pairs, and $obj->{hash_specifier}->{hashname} between key and
value.  As above, __default will be used if a delimiter has not
been specified for the specific variable.  The defaults are ", " and
"=" respectively.

Example:

 $bt = Text::BasicTemplate->new(default_list_delimiter => ' and');

 $ss = "path: %path%" . "\n" . "env: %env%";
 $bt->{hash_specifier}->{env} = " is ";
 $bt->{hash_delimiter}->{env} = ", ";
 print $bt->parse(\$ss, { path => [ split(/:/,$ENV{PATH}) ],
                          env => \%ENV });

Output from the above would be of the form:

 /bin and /usr/bin and /usr/local/bin
 SHELL is bash, VISUAL is emacs, RSYNC_RSH is ssh

=head2 SUBROUTINE SUBSTITUTIONS

Subroutine references are something of a special-case in Text::BasicTemplate.
In a simple form, they can be used thusly:

 sub heart_of_oak {
   return "me lads, 'tis to glory we steer";
 }
 $bt = Text::BasicTemplate->new();
 $ss = "come cheer up %&rest_of_verse%";
 %ov = ( rest_of_verse => \&heart_of_oak );
 print $bt->parse(\$ss,\%ov);

This would output "come cheer up me lads, 'tis to glory we steer," by calling
&heart_of_oak() and inserting its return value into the template.

You can pass literals and variables defined in the template to a subroutine, as follows:

 sub heart_of_oak {     
   my @lines = ( "come cheer up me lads",
                 "'tis to glory we steer",
                 "to find something new in this wonderful year" );
   my $which = shift;
   my $loud = shift || 0;
   return $loud ? uc $lines[$which] : $lines[$which];
 }
 $bt = Text::BasicTemplate->new();
 $ss = "song: %&song(1,$loud)%, %&song(2,$loud)%, %&song(3,$loud)%";
 print $bt->parse(\$ss, { song => \&heart_of_oak, loud => 1 });

This would produce the lines of the song, separated by ", "; as
written above (with loud == 1 in the dictionary), it will be
shouted (inserted in capitals, as per the call to uc()) -- in
the template, the use of $variable in a subroutine call indicates
that $variable should be gotten from the dictionary rather than
interpreted literally.  Use of $ is not the normal BasicTemplate
syntax -- %variable% would be more proper, but introduces a nasty
parsing mess until the re engine gains balancing abilities
(scheduled for perl5.6 as of this writing).

The argument $_bt_dict has special meaning, and will be replaced
with the hashref being used as the active substitution dictionary,
thus giving your routines access to it -- it will be passed in
the form of a hashref, which you are free to alter during the call,
so long as you keep the effects of your caching options in mind.

The available formatting of arguments passed to these subroutines
is any combination of:

 word, word,
 word => word, word
 word => "word \"word\" 'word'"
 word => 'word "word"'
 word => "word\nword",

 # as in:
 %&mysubroutine(foo,bar,snaf => 3,str => "foo bar", word => 'k"ib"o', flap => "\"ing\"")%

In the first case, each word argument may contain anything but [,=>]
(that is, a comma, an = or a >; yes, that is not entirely proper).
If you need to use any of those characters, put the arguments in
quotes.  Parsing with quotations is more accurate, but depends on
lookbehind assertions and is accordingly slow (the parse
results are cached, so this is mostly an issue in repetitive
executions rather than use of many instances in one template).

When performing database queries, which may return in increments and
have separate beginning and ending operations, you can use three code
references in a single list reference, for beginning, middle and end.
The first will be called once at the beginning, the second repeatedly
until it returns false, and the third once afterward.  For example:


 sub $number_count = 10;
 sub numbers_start { "Countdown, kinda like BASIC: " }
 sub numbers_list { $number_count-- }
 sub numbers_end { "\"blastoff. whee.\"" }
 my %ov = (
   numbers => [ \&numbers_start, \&numbers_list, \&numbers_end ]
 );
 $bt = Text::BasicTemplate->new();
 $ss = '%numbers%';
 print $bt->parse(\$ss,\%ov);

This would call &numbers_start and insert the result, then call and
insert &numbers_list until it $number_count reached zero, then call
&numbers_end once and insert that.  This may easily be applied, for
example, to an execute, fetch, fetch, fetch, ..., finish sequence in
DBI.  If you need only part of these three functions (e.g. a routine
that does not need a finish function), you can pass any one as an
empty code reference (e.g. \ sub { }).

The real use of subroutine references becomes apparent when you need
the output from a function parsed into a template of its own.  As noted
above in the song() example, you can pass arguments to a subroutine via
the template.  This extends to passing hashes, e.g. %&foo(name => value)%,
in which (name,value) will be passed to the subroutine referenced as foo
in the parse() dictionary.  You may also pass an argument (bt_template => filename),
in which case the output from the coderef will be assumed to be a hashref;
this hashref will then be added to the current parse() dictionary (where
duplication occurs, the hashref will take precedence) and used as the
dictionary given to a recursive call of parse() on the file specified by
bt_template.  So...


 sub start { 
   return "hello, ";
 }
 my $pcount = 0;
 sub getname {
   my @people = ( { firstname => 'John', lastname => 'Doe' },
                  { firstname => 'Susan', lastname => 'Smith' }
                );
   return $people[$pcount++];
 }
 sub end {
   return "Nice to see you.";
 }
 # assume that /path/hello-template contains
 # The Esteemed %firstname% %lastname%, Lord of All You Survey
 $bt = Text::BasicTemplate->new();
 $ss = "Greeting: \"%&greeting(bt_template => /path/hello-template)%\"";
 print $bt->parse(\$ss, { greeting => [ \&start, \&getname, \&end ] });

In this instance, the return values of &start and &end will be used as-is.
&getname will be called until it reaches undef (on the third call); the
hashrefs returned will be parsed into two copies of /tmp/hello-template.
The final output would therefore be:

 hello, The Esteemed John Doe, Lord of All You Survey
 The Esteemed Susan Smith, Lord of All You Survey
 Nice to see you.

This has obvious usefulness in terms of taking database output and
making presentable (e.g. HTML) output from it, amongst other uses.

=head1 PRAGMA/PREPROCESS FUNCTIONS

Some basic pragma functions are provided for use in templates.  These
follow the same syntactical conventions as subroutine substitutions,
but correspond to programs internal to Text::BasicTemplate rather
than supplied by calling code.  Pragmas should not be used on untrusted
templates -- when templates are not trustworthy, they should be disabled
by setting $object->{pragma_enable}->{name_of_pragma} to false, or more
simply disabling all pragmas by setting $object->{pragma_enable} = {}.
If an option pragma_enable is passed to new(), it will be taken as
a substitute for the enabled list and not overridden.

Individual pragmas may be added or overridden with code of your own by
setting $object->{pragma_functions}->{name_of_pragma} to a CODE reference.
The referenced routine should expect to be passed a list containing
a reference to the Text::BasicTemplate object, a hashref to the active
dictionary (which may be {}), followed by any arguments passed in
the template.  Pragma routines must match ^bt_, or they will not be
interpreted as pragmas.

Pragmas provided are as follows.  Note that they follow, to a reasonable
extent, the format given by the Apache 1.3 mod_include specification, with
a few additions.  Options in [ square brackets ] are optional.

=head2 bt_include({ file | virtual }, filename, [ noparse ])

Includes a file in the given location in the template.  The first option
specifies from where the file should be loaded, equivalent to the Apache
mod_include form.  B<file> means any regular path and filename.
B<virtual> is interpreted as relative to $object->{include_document_root}
or $ENV{DOCUMENT_ROOT} in that order of precedence; if no document root is
specified, no include is done.  B<semisecure> is a restricted form of the
B<file> form, in which files must match \w[\w\-.]{0,254} to be included
(this means, generally, that the included files must be in the working
directory, unless you chdir() or something).

If B<noparse> is supplied, the included file will be inserted as-is
without further adjustment.  Otherwise it will be run through parse()
as would any normal template.  You should use the noparse option when
including an untrusted template from a trusted one.

bt_include() will only include readable regular files (that is, those
passing C<-e>, C<-f> and C<-r>).  Note that this is suceptible to race conditions,
so it does not confer any security where a race could be exploited by
the usual file/symlink swapping.

Examples:

 %&bt_include(file,templates/boxscores.html)%
  Includes the file, parses according to the active dictionary
 %&bt_include(file,orders/summary.txt,noparse)%
  Includes the file but without any parsing on the way
 %&bt_include(virtual,index.html)%
  Includes the file index.html from the document_root directory,
  with parsing.

bt_include() is one the user might want to override if template files
are stored in a database or other non-file mechanism.

=head2 bt_exec({ cmd | cgi }, command, parse)

Analogous to the Apache mod_include 'exec' directive.  Executes the
specified command and inserts its stdout output into the template
in place of the directive.  If B<parse> is specified, this output
will be handed to parse() as if it were a template file.

If B<cmd> is given, the command will be read, parsed if selected,
and inserted as-is without validation on the command.  If B<cgi>
is given, the output will be skipped up and including the first
blank line to remove HTTP headers.

bt_exec() is not secure and should not be used except with trusted
templates and on trusted binaries.  For this reason it is disabled
by default and must be manually enabled by setting $object->{pragma_enable}->{bt_exec} true either when calling new() or subsequently.


=head1 COMPATIBILITY

Text::BasicTemplate 2.0 is a major rewrite from v0.9.8 and previous
versions.  Compatibility has been preserved to a degree, enough that
with compatibility mode enabled, there should be no difference in
either output or calling conventions.

I<Backwards-compatibility mode is enabled by default in v2.0, but
will be disabled in some future version, possibly without notice.>

Backwards compatibility is a concern in two respects, that of template
format and calling conventions.

=head2 TEMPLATE FORMAT

The BasicTemplate 2.0 template format is only minimally compatible
with the older form.  If your templates include conditionals or
simple_ssi HTML-style include directives, you will need to update
your templates and/or use compatibility mode.  A template that uses
only variable substitution (e.g. "Hello %name%") will not need
compatibility mode.

Compatibility mode is enabled by passing 'compatibility_mode_0x => 1'
to new() (see the POD for new()).  Note that compatibility mode is
slower than standard mode, because of conversion overhead. 

The convert_template_0x_2x() function can convert a 0.x template to
a 2.0 template -- see the POD for that function for the details.
This function can easily be placed in a script to convert your
templates in place, and it is likely that such a script will be
provided with Text::BasicTemplate releases.

=head2 CALLING CONVENTIONS

In general, there should be no necessary change between 0.x calls
and 2.x calls.  All the old calls have been replaced with stubs
which call the new versions.  These are roughly as follows:

 push(), parse_push() -- replaced by parse()
 print(), parse_print() -- replaced by print parse()
 list_cache() -- replaced by list_lexicon_cache()
 purge_cache() -- replaced by purge_*_cache()
 uncache() -- replaced by purge_lexicon_cache(), purge_file_cache()

=cut


my $errstr;
my $debug = 0;

my %reserved_words = (
		      'if' => 1, '%if%' => 1,
		      'else' => 1, '%else%' => 1,
		      'elsif' => 1, '%elsif%' => 1,
		      'fi' => 1, '%fi%' => 1,
);

my %lexeme_types = (
		   0 => 'plain',
		   1 => 'condi',
		   2 => 'ident',
		   3 => 'liter',
		   4 => 'uoper',
		   5 => 'boper',
		   6 => 'coper',
		  );

=head1 USEFUL FUNCTIONS

=item B<new()>

Make a Text::BasicTemplate object.  Syntax is as follows:

 $bt = Text::BasicTemplate->new(
  max_parse_recursion => 32,
  use_file_cache => 0,
  use_lexicon_cache => 1,
  use_scalarref_lexicon_cache => 0,
  use_full_cond_cache => 1,
  use_cond2rpn_cache => 1,
  use_dynroutine_arg_cache => 1,
  use_flock => 1,
  default_list_delimiter => ", ",
  default_hash_delimiter => ", ",
  default_hash_specifier => "=",
  default_undef_identifier => "",
  compatibility_mode_0x => 1,
  eval_subroutine_refs => 1,
  strip_html_comments => 0,
  strip_c_comments => 0,
  strip_cpp_comments => 0,
  strip_perl_comments => 0,
  condense_whitespace => 0,
  simple_ssi => 1
 );

All explicit arguments to new() are optional; the values shown above are
the defaults.

Configuration arguments given to new() have the following meanings:

=over 4

=item B<max_parse_recursion>:
When performing a recursive parse() on a template, as
in the case of a subroutine substitution with a bt_template parameter (see
the B<SYNTAX> section), parsing will stop if recursion goes more than this
depth -- the typical cause would be a template A that included a subroutine
reference that used a template B, which used a C, which used A again.

=item B<use_file_cache>:
Templates specified to parse() by filename are read into
memory before being given to the lexer.  If this option is set, the contents
of the file will be cached in a hash after being read.  This is largely
unnecessary if (as per default) lexicon caching is enabled.  Do not turn this
on unless you have disabled lexicon caching, or are doing something dubious
to the cache yourself.

=item B<use_lexicon_cache>:
If true, the lexicon generated from an input template
will be cached prior to parsing.  This is the normal form of caching, and
enables subsequent calls to parse() to skip over the lexical parsing of
templates, generally the most expensive part of the process.

=item B<use_scalarref_lexicon_cache>:
If true, the above lexicon caching applies
to templates given to parse() via scalar reference, as well as by filename.
This is generally fine, but if you pass the contents of multiple templates
by a reference to the same scalar, you may get cache mismatching.

=item B<use_full_cond_cache>:
Controls caching of the results of evaluation of conditionals.  Has three
settings, off (0), normal (1), and persistent (2).  If set off, every
conditional will be reevaluated every time it is executed (this is not
very expensive unless use_cond2rpn_cache is set off also; see documentation
for that option).  This is necessary only if you intend to change the
values in the dictionary during a parse(), as in the case of a
template-referenced subroutine calling a method that changes the dictionary.
This cache adds some speed; the operation normally requires O(n) where n is
the number of operators in the conditional, plus the cond2rpn conversion
overhead, if applicable.  When use_full_cond_cache is set to 1 (on, as per
normal), conditionals are cached only for the span of one parse() call; if
a template-referenced routine changes the dictionary for a variable already
used in a conditional, the change will have no effect until the next call
to parse().  When set to 2 (persistent), the conditional cache does not
expire when parse() completes a single template, and indeed will not expire
at all unless you call purge_fullcond_cache() manually.  This setting can
be useful for fast repeated parsing of the same data into multiple
templates, but is not suitable when the dictionary is changing.

=item B<use_dynroutine_arg_cache>:
Subroutine substitutions in templates may be
passed arguments; these arguments are parsed into a suitable list before
being handed to the subroutine in question.  If this is enabled, the results
of that parsing will be cached to speed future use.  This does not incur
cache mismatches; leave enabled unless you have a good reason not to.

=item B<use_flock>:
If set true, template files will be flock()ed with a LOCK_SH
while being read.  Otherwise, they will be read blindly.  Win32 afflictees
might wish to disable this; in general, leave it alone.  Note that files
generally will need to be read only once each if either lexicon or file
caching is enabled (see above).

=item B<default_list_delimiter>:
When listrefs are substituted into a template,
they will be join()ed with the contents of $self->{list_delimiter}->{name}
if defined, or with this default value otherwise.  If you wish your listrefs
contatenated with no delimiting, set this to ''.  Default is ', '.

=item B<default_hash_delimiter>:
As above, but separates key/value pairs in hashref
substitution.  If %x = (y => z, x => p), this delimiter will be placed
between y=z and x=p.  Overridden by $self->{hash_delimiter}->{name}.  Deault ', '.

=item B<default_hash_specifier>:
As above, separating keys and values in hashref
substitution.  In the above %x, this delimiter goes between y and z, and
between x and p.  Overriden by $self->{hash_specifier}->{name}.  Default '='.

=item B<default_undef_identifier>:
When a template calls for a substitution key
which is undefined in the dictionary, this value will be substituted instead.
Default is ''.  Something obvious like '**undefined**' might be a good choice
for debugging purposes.

=item B<eval_subroutine_refs>:
This option enables evaluation of subroutine reference
substitutions, e.g. %&myroutine()%.  Generally a safe option, but you might
want to disable it if parsing untrustworthy templates.

=item B<compatibility_mode_0x>:
Enables compatibility with templates written
for Text::BasicTemplate v0.x.  See B<COMPATIBILITY> section.

=item B<strip_html_comments>:
If set true, HTML comments (E<lt>!-- ... --E<gt>) will be
removed from the parse results.  Note that nested comments are not properly
stripped.  Default off.

=item B<strip_c_comments>:
If true, C comments (/* ... */) will be removed from
parse results.  Default off.

=item B<strip_cpp_comments>:
If true, C and C++ comments (/* ... */ and // ...\n) will
be removed from parse results.  Default off.

=item B<strip_perl_comments>:
If true, perl and similar style comments (# ... \n) will
be removed from parse results.  Default off.

=item B<condense_whitespace>:
If true, whitespace in parse results will be condensed to
the first byte of each, as would be done by most web browsers.  Useful for
tightening bandwidth usage on HTML templates without making the input templates
themselves unreadable.  Default off.

=item B<simple_ssi>:
If true, server-parsed HTML directives of the #include persuasion
will have the file referenced in their file="" or virtual="" arguments inserted
in their place.  The form is <!--#include file="..."-->.  This usage is deprecated
in favor of the %&bt_include()% function -- see the B<SYNTAX> section.  Default off;
this should not be enabled when using untrusted templates.

=back

=cut

sub new {
  my $class = shift;
  my %params = @_;
  my $self = { %params };
  bless $self, $class;

  $self->{max_parse_recursion} ||= 32;
  $self->{reserved_words} ||= \%reserved_words;
  !defined $self->{use_full_cond_cache} and $self->{use_full_cond_cache} = 1;
  !defined $self->{use_cond2rpn_cache} and $self->{use_cond2rpn_cache}=1;
  !defined $self->{use_dynroutine_arg_cache} and $self->{use_dynroutine_arg_cache}=1;

  !defined $self->{taint_enabled} and
    $self->{taint_enabled} = $self->taint_enabled();

  # the file cache should be enabled if the lexicon cache isn't,
  # but we don't need to cache files if the lexicons themselves are
  # being cached, since the file cache would never be used anyway.

  if (!defined $self->{use_file_cache}) {
      $self->{use_file_cache} = !$self->{use_lexicon_cache};
  }
  $self->{use_scalarref_lexicon_cache} ||= 0;

  !defined $self->{use_flock} and $self->{use_flock} = 1;

  # caches conversions of conditionals into their RPN conversions
  # for cond_evaluate()
  $self->{cond2rpn_cache} = ();

  # caches the actual returns from cond_evaluate();
  $self->{fullcond_cache} = ();

  # caches argument lists passed to subrefs (saves reparsing)
  $self->{dynroutine_arg_cache} = ();

  # caches lexicons
  $self->{lexicon_cache} = ();

  # caches files in the absence of lexicon caching
  $self->{file_cache} = ();

  $self->{enable_pattern_operator} = !$self->{taint_enabled};

  !defined $self->{list_delimiter}->{__default} and
    $self->{list_delimiter}->{__default} = $self->{default_list_delimiter} || ', ';
  !defined $self->{hash_delimiter}->{__default} and
    $self->{hash_delimiter}->{__default} = $self->{default_hash_delimiter} || ', ';
  !defined $self->{hash_specifier}->{__default} and
    $self->{hash_specifier}->{__default} = $self->{default_hash_specifier} || '=';

  $self->{default_undef_identifier} = '';
  $self->{disabled_pragma_identifier} = '[pragma not enabled]';
  $self->{disabled_subref_identifier} = '[subroutine not enabled]';
  $self->{tainted_content_identififer} = '[tainted template contents]';

  $self->{pragma_enable} = {} unless ref $self->{pragma_enable} eq 'HASH';
  $self->{pragma_functions} = {} unless ref $self->{pragma_functions} eq 'HASH';

  # v0.x backwards-compatibility settings
  !defined $self->{compatibility_mode_0x}
    and $self->{compatibility_mode_0x} = 1;

  if ($self->{compatibility_mode_0x}) {
      $self->{taint_enabled} = 0;
      
      !defined $self->{simple_ssi} and $self->{simple_ssi} = 1;
      if ($self->{simple_ssi}) {
	  $self->{pragma_enable}->{bt_include} = 1;
      }
  }


  $self->{bt_include_allow_tainted} ||= 0;
  if (!defined $self->{pragma_enable}->{bt_include}) {
      if (!$self->{taint_enabled}) {
	  # if taint checking is enabled, we can't safely
	  # do include.
	  $self->{pragma_enable}->{bt_include} = 1;
    }
  }
  $self->{pragma_functions}->{bt_include} = \&bt_include;
  $self->{pragma_functions}->{bt_exec} = \&bt_exec;


  $self->{eval_subroutine_refs} = 1;
  for ('strip_html_comments','strip_c_comments','strip_cpp_comments',
       'strip_perl_comments','condense_whitespace','simple_ssi') {
      $self->{$_} ||= 0;
  }
  $self;
}

=item B<parse SOURCE_TEMPLATE [ OVR ]>

Given a source template in SOURCE_TEMPLATE, parses that template according
to the key/value hash referenced by $ovr, then returns the result.

If SOURCE_TEMPLATE is given as a scalar, it will be interpreted as a filename,
and the contents of that file will be read, parsed, and returned.  If given as
a scalar reference, it will be interpreted as a reference to a buffer
containing the template (the referenced template will not be modified, and
copies of the relevant parts will be used to build the lexicon).  If
SOURCE_TEMPLATE contains an array reference, that array will be used instead
of generating a new lexicon.

If use_file_template_cache is true and the source template is loaded from a
file, or if use_scalarref_lexicon_cache is true and the source template is
given in a scalar reference, the lexicon will be cached to accelerate future
parsing of the template.  If the contents of either the file or the
referenced buffer changes during the lifespan of the Text::BasicTemplate
object, the code will not notice -- if you need to change the templates in
this fashion, use B<uncache()> to delete the cached lexicon.  Lexicon
references are not cached, since the code assumes if you make your own
templates you are capable of caching them, too.

For templates stored in and loaded from files, note that they will be
read and parsed in core, so you probably should not try to parse templates
that would occupy a significant amount of your available memory.  For
large seldom-used templates, also consider disabling lexicon caching or
calling B<uncache()> afterwards.

B<OVR> is a euphemism for some arbitrary combination of lists, scalar paris,
hashrefs and listrefs.  These should cumulatively amount to the substitution
dictionary -- the simple form is { x => 'y' }, in which all %x% in the
template will be replaced with y.  (x,y) will work also (and by extension,
you may pass lists of these, or raw hashes).  The dictionary is parsed
once, start-to-finish, so in the event of duplicated entries, the last
entry of a given name will be the only one retained.

Note on backwards-compatibility: in v0.x, it was possible to pass scalars
of the form "x=y".  This is deprecated, and is only available if
B<compatibility_mode_0x> is set true.  Further, as references are now legal
fodder for substitutions, ("x",\%y) means that %x% will parse to the
contents of %y -- if %y contains part of your substitution dictionary,
then the above will present an error in any case, and ("x","y",\%y) is likely
what you intended.

=cut

sub parse {
    my $self = shift;
    my $isrc = shift || return undef;
    my @dict = (@_);
    my $ovr = {};
    my $L;
    my $ss;
    my ($d,$e,$src,$tsrc); ##


    while ($d = shift @dict) {
      if (ref $d eq 'HASH') {
	unshift @dict, map { ($_,$d->{$_}) } keys %{$d};
      } elsif (ref $d eq 'ARRAY') {
	unshift @dict,@{$d};
      } elsif (!ref $d) {
	if ($self->{compatibility_mode_0x} and $d =~ /^([\w\.\-]+)=(.*)/s) {
	  $ovr->{$1} = $2;
	  next;
	}
	if (@dict) {
	    $e = shift @dict;
	    $ovr->{$d} = $e;
	} else {
	  print STDERR "Text::BasicTemplate::parse($isrc): Stack underflow while flattening dictionary; odd number of elements, last was '$d'";
	}
      }
    }
    $ovr->{_bt_recurse_count} ||= 0;

    # horrible hack
    if ($self->{compatibility_mode_0x}) {
	$self->{compat_0x_ovr} = $ovr;
    }

    return '[Text::BasicTemplate::parse() recursion limit exceeded]'
      if $self->{max_parse_recursion} and
	 $ovr->{_bt_recurse_count} > $self->{max_parse_recursion};
#    print STDERR "ovr = {".join(',',map { "$_=$ovr->{$_}" } keys %{$ovr})."}";
    if (ref $isrc eq 'ARRAY') {
	$L = $isrc;
    } elsif (ref $isrc eq 'SCALAR') {
	if ($self->{use_scalarref_lexicon_cache} and
	    defined $self->{lexicon_cache}{$isrc}) {
	    $debug && print STDERR "]using lexicon cache for $isrc]";
	    $L = $self->{lexicon_cache}{$isrc};
	} else {
	    $L = $self->lex($src = $isrc);	
	    if ($self->{use_scalarref_lexicon_cache}) {
		$self->{lexicon_cache}{$isrc} = $L;
	    }
	}
    } elsif (!ref $isrc) {
	if ($self->{use_scalarref_lexicon_cache} and
	    defined $self->{lexicon_cache}{$isrc}) {
	    $L = $self->{lexicon_cache}{$isrc};
	} else {
	    unless ($tsrc = $self->load_from_file($isrc)) {
		warn "Text::BasicTemplate::parse($isrc): File not available";
		return undef;
	    }
	    $L = $self->lex($isrc = $tsrc);
	    if ($self->{use_scalarref_template_cache}) {
		$self->{lexicon_cache}{$isrc} = $L;
	    }
	}
    }

    # horrible hack
    if ($self->{compatibility_mode_0x}) {
	delete $self->{compat_0x_ovr};
    }

    $ss = $self->parse_range($L,0,$#{$L},$ovr);
    $$ss =~ s/<!--.*?-->//mg if $self->{strip_html_comments};
    $$ss =~ s/\/\*.*?\*\///mg if $self->{strip_c_comments} or
                                 $self->{strip_cpp_comments};
    $$ss =~ s/\/\/.*?\n/\n/mg if $self->{strip_cpp_comments};
    $$ss =~ s/\#.*?\n/\n/mg if $self->{strip_perl_comments};
    $$ss =~ s/(\s)\s+/$1/mg if $self->{condense_whitespace};
    if ($self->{use_full_cond_cache} == 1) {
	$self->purge_fullcond_cache;
    }
    $$ss;
}


=item parse_range \@lexicon $start $end [ \@ov ]

Parses and returns the relevant parts of the specified lexicon
over the given range.  This has the happy side effect of eliminating
the obnoxious passing around of chunks of the lexicon.  Instead one
need only pass references to a single lexicon and the range over which
it should be parsed.  This routine does the actual work of parse(),
but is really only useful internally.

=cut

sub parse_range {
  my $self = shift;
  my $L = shift;
  my ($start_pos,$end_pos,$ovr) = @_;
  my ($lexeme);
  my $out;
  my ($i,$i1,$i2,$s);
  my ($cond,$subcond,$rcond);

  use re 'taint';
  ref $ovr eq 'HASH' or $ovr = {};
  ref $L eq 'ARRAY' or $L = [];
  return \ '' unless defined $start_pos and defined $end_pos and $end_pos >= $start_pos;
  return \ '' if ($end_pos<0 || !@{$L});

  $debug and print STDERR "\nlexicon[$start_pos,$end_pos, #L=$#{$L}]:\n";
  $debug and
    print STDERR $self->dump_lexicon($L,$start_pos,$end_pos);

  for ($i=$start_pos; $i<=$end_pos && $i<=$#{$L}; $i++) {
#      print " start loop iteration, \$i=$i, end_pos=$end_pos, #L=$#{$L}\n";
      $lexeme = $L->[$i];
      next if ($lexeme->[0] > $self->{max_parse_recursion});

      $debug and print STDERR "[L$lexeme->[0]] $lexeme->[1]";
      $debug and print STDERR " -- op" if $lexeme->[2];
      if (!$lexeme->[2]) {
	  $out .= $lexeme->[1];
	  $debug and print STDERR "\n";
	  next;
      }

      if ($lexeme->[2] == 2) { # is_identifier
	  $debug and print STDERR " [ $lexeme->[1] is identifier, passing $lexeme->[3]/$lexeme->[4] ]";
	  $out .= $self->identifier_evaluate($lexeme->[1],
					     $ovr,$lexeme->[3],$lexeme->[4]);
	  next;
      } elsif ($lexeme->[2] == 6) { #is_nonconditional_operation
	  $debug and print STDERR "[ nco lexeme: ".join(',',@{$lexeme}),"]";
	  $out .= $self->cond_evaluate($lexeme->[1],$ovr);
      }

      # For these purposes, if and elsif are roughly equivalent, and
      # 
      if ($lexeme->[2] == 1 and
	  $lexeme->[1] =~ /^%(else|(if|elsif)\s+([^%]+))%$/) {
	  $cond = $3;
	  $1 eq 'else' and $cond = 1;
	  $debug and print STDERR " [if '$cond' from $lexeme->[1]]";
	  if ($self->cond_evaluate($cond,$ovr)) {
	      $debug and print STDERR " [eval true]";
	      
	      # find end of block, and skip over else/elsifs; if we drop down a level,
	      # there's likely something wrong with the lexer.
	    BLOCKLEXEME: for ($i1=$i+1, $i2 = 0;
			      $i1<=$#{$L} &&
			      $L->[$i1]->[0] >= $lexeme->[0] &&
			      $i1<=$end_pos; $i1++) {
		  
		  # conditional components are a matter for concern iff they're on the
		  # same level as the if we started from; if we find them from higher
		  # levels, the recursive call will handle them, and we should not be
		  # able to get to a lower level by loop conditions immediately above.
		  if ($L->[$i1]->[0] == $L->[$i]->[0] &&
		      $L->[$i1]->[1] eq '%fi%') {
		      last BLOCKLEXEME;
		  } elsif ($L->[$i1]->[0] == $L->[$i]->[0] and
		      $L->[$i1]->[1] eq '%else%' or
		      substr($L->[$i1]->[1],0,7) eq '%elsif ') {
		      
		      # if we actually find an else or elsif, we can skip to the end of
		      # the block, since the condition from which we started was true,
		      # and everything including and after an else/elsif is not going
		      # to get parsed this trip anyway.

		      for ($i2=0; $i1+$i2 <= $end_pos &&
			          $i1+$i2 <= $#{$L} &&
			          defined $L->[$i1+$i2+1]->[0] &&
			          $L->[$i1+$i2+1]->[0] >= $L->[$i1]->[0]; $i2++) {
#			  print STDERR "\ni1=$i1 i2=$i2 end_pos=$end_pos #L=$#{$L}",
#			  " L->[".($i1+$i2+1)."]->[0]=".$L->[$i1+$i2+1]->[0],
#			  " L->[$i1]->[0]=".$L->[$i1]->[0],"\n";
		      }
		      last BLOCKLEXEME;
		  }
	      }
#	      $debug and print STDERR " [recurs over ".($i+1)."..".($i1-1).", then skip $i2]";
#	      $debug and print STDERR " lexdump passed on: ".$self->dump_lexicon($L,$i+1,$i1-1);
	      
	      $s = $self->parse_range($L,$i+1,$i1-1,$ovr);
	      $s and ref $s eq 'SCALAR' and $out .= $$s;
#	      $debug and print STDERR " back from recursion, i=$i i1=$i1 i2=$i2";
	      #	  $out .= ${ $self->parse([ $L->[($i+1)..$i1] ]) };
	      
	      # adjust parse position to the end of the if {} block plus the
	      # distance from that position to the end of the else/elsifs.
	      $i = $i1 + $i2;
	  } else {
	      $debug and print STDERR " [eval false]";
	      # if the condition didn't pass, just advance to the next conditional, unless
	      # we need to go down a level to find it.  If we hit an %elsif%, %fi% or %else%,
	      # stop seeking and resume parsing from that point.
#	      $debug and print STDERR " [ranging !if block from $i+1 for level $lexeme->[0]: ";
	      for ($i1=$i+1; ($L->[$i1]->[0] >= $lexeme->[0]) &&
		             ($i1<=$end_pos) and
		             !($L->[$i1]->[0] == $L->[$i]->[0]  &&
			       $L->[$i1]->[1] =~ /^%(elsif\s|fi%|else%)/) &&
		             $i1<=$#{$L}; $i1++) {}
#	      $debug and print STDERR "[$i1 computed]";
	      $1 and $1 eq 'fi' and $i1++;
	      $debug and print STDERR "[if-false offset computed, adjusting i from $i to $i1 ($L->[$i1]->[1])]";
	      $i = $i1-1;
	  }
      }
      $debug and print STDERR " \n";
  }
#  $debug and print STDERR " [parse over $start_pos-$end_pos complete]\n";
  \$out;
}

=item cond_evaluate CONDITIONAL [ \%ovr ]

Evaluates the specified conditional left-to-right.  At present it does
not handle operators also, just boolean/scalar evaluation.

=cut

sub cond_evaluate {
  my $self = shift;
  my $cond = shift;
  my $ovr = shift || [];
  my @cstack = ();
  my ($psc,$subcond,$rcond);
  my $binop_leftover = '';
  my ($x,$y);

  # first recursively evaluate according to parentheses

  $debug and print STDERR " [cond_evaluate(): $cond]";
  defined $cond or return undef;

  # have we computed this condition all the way before?
  # Generally we can't use this because $ovr may change, but
  # if the user wants it, it's fast.
  $self->{use_full_cond_cache} and $self->{fullcond_cache}{"$ovr\t$cond"} and
    return $self->{fullcond_cache}{"$ovr\t$cond"};

## BUG: the cond2rpn cache breaks things.  It should live for at most one parse() call, not
## the life of the module.

  # Are we supposed to use the conditional -> RPN conversion cache, and if so,
  # have we already parsed this one before?
  if ($self->{use_cond2rpn_cache} && $self->{cond2rpn_cache}{$cond}) {
      $debug and print STDERR "[cache hit on cond '$cond' \@ $self->{cond2rpn_cache}{$cond}]";

      @cstack = map { [ $_->[0], $_->[1] ] } @{ $self->{cond2rpn_cache}{$cond} };
#      for $x (@{ $self->{cond2rpn_cache}{$cond} }) {
#	  push @cstack, [ $_->[0], $_->[1] ];
#      }


#      @cstack = @{ $self->{cond2rpn_cache}{$cond} };
  } else {
      $debug and print STDERR "[cache miss on cond '$cond']";
      while ($cond =~ /(^| |\()\(([^\)]+)\)/) {
	  ($psc,$subcond) = ($1,$2);
	  $rcond = $self->cond_evaluate($subcond,$ovr);
	  $debug and print STDERR " [eval $subcond-> $rcond in $cond]";
	  #      $cond =~ s/($&)/$rcond/g;
	  # fix in 2.005: Shouldn't have permitted active metachars here:
	  $cond =~ s/\(\Q$subcond\E\)/$rcond/g;
	  $debug and print STDERR " [reduced to $cond]";
      }
      $debug and print STDERR " [simplified cond: $cond]"; 
      
      # stdvar, !func, &cgivar, $envvar, 42
#      $cond =~ s/(^| )(\w+)\(/$1&$2/g;
      while ($cond =~ m/(defined |\!| not )?\s*([\$]?([A-Za-z_]\w*|\"[^\"]*\"|\d+|\&\w+\([^)]*\)))
	     \s*(&&|\|\|| (and|or) |                      # logical binary ops
		 \&|\||\^|\<\<|\>\>|                           # bitwise binary ops
		 ==|!=|<=>|<=|>=|<|>| (eq|ne|lt|le|gt|ge) |   # comparison binary ops

		 \=~|\!~| x |\.|\+|\-|\*\*|\*| (mod|div) |\/)?/gmx) { # arithmetic and string ops
	  $debug and print STDERR " [ conditional ($1,$2,$3,$4,$5,$6,$7,$8)]";
	  
	  my ($unaryop,$operand,$binaryop) = ($1,$2,$4);
#          print STDERR " [unaryop=",($unaryop || 'undef'),", calling ident_eval($operand)]";

	  if (1) {
	      defined $operand and push @cstack, [ 2, $operand ];
	  } elsif ($unaryop && $unaryop eq 'defined') {
	      defined $operand and push @cstack, [ 2, $self->identifier_evaluate($operand,$ovr,undef,undef,undef,1) ];
	  } else {
	      defined $operand and push @cstack, [ 2, $self->identifier_evaluate($operand,$ovr) ];
	  }
#          print  STDERR "ident_eval($operand): ".$self->identifier_evaluate($operand,$ovr)."\n";
	  $unaryop and push @cstack, [ 4, $unaryop ];
	  if ($binop_leftover) {
	      push @cstack, [ 5, $binop_leftover ];
	      $binop_leftover = '';
	  }
	  $binaryop and $binop_leftover=$binaryop;
	  
	  $debug and print STDERR "[unary=$unaryop operand=$operand binaryop=$binaryop lo=$binop_leftover, new cstack={".
	    $self->dump_stack(\@cstack,1)."} ]";
      }
      
      $binop_leftover and push @cstack, [ 5, $binop_leftover ];
      
      if ($self->{use_cond2rpn_cache}) {
	  $self->{cond2rpn_cache}{$cond} = [ map { [ $_->[0], $_->[1] ] } @cstack ];
      }
  }

#  print STDERR "[cache for $cond was: ".$self->dump_stack($self->{cond2rpn_cache}{$cond},1)."]";
#  print STDERR "[cstack pre-eval {".$self->dump_stack(\@cstack,1)."} count=$#cstack]";
  for (@cstack) {
      if ($_->[0] == 2) {
	  if ($_->[1] eq 'cacheablething') {
#	      print STDERR "[item = $ovr->{cacheablething}]";
	  }
#	  print STDERR "[stack eval ident $_->[1] -> ";
	  $_->[1] = $self->identifier_evaluate($_->[1],$ovr,undef,undef,undef,1);
#	  print STDERR "$_->[1]]";
      }
  }
#  print STDERR "[cstack post-eval {".$self->dump_stack(\@cstack,1)."} count=$#cstack]";
#  print STDERR "[cache for $cond now: ".$self->dump_stack($self->{cond2rpn_cache}{$cond},1)."]";

  # now put in the stuff to handle boolean chaining (and/or)
  return '' unless @cstack;
  my ($lvalue,$op,$operand,$n,@ostack);
  $debug and print STDERR " [pre-loop: cstack contains {".$self->dump_stack(\@cstack,1)."} count=$#cstack]";

  $debug and
    print STDERR "[preloop #cstack = $#cstack]";

  while ($#cstack != 0) {
      $debug and
	print STDERR " [cstack contains {".$self->dump_stack(\@cstack,1)."} count=$#cstack]";
      $n = shift @cstack;
      if ($n->[0] != 2) {
	  print STDERR "Got $lexeme_types{$n->[0]} $n->[1] where identifier expected in '$cond'";
	  return undef;
      }
#      $operand = $n->[1];
#      print STDERR "[operand $n->[1] -> ";
      $operand = $n->[1];
#      print STDERR "$operand]";
      !@cstack and return $operand;

      $n = shift @cstack;
      if ($n->[0] == 4) { # unary op
	  $op = $n->[1];
	  unshift @cstack, [ 2, $self->unaryop_evaluate($op,$operand) ];
	  next;
      } elsif ($n->[0] == 2) { # another identififer
	  $lvalue = $operand;
	  $operand = $n->[1];
#	  print STDERR "[new operand $n->[1] -> ";
#	  $operand = $self->identifier_evaluate($n->[1],$ovr);
#	  print STDERR "$operand]";

	  $n = shift @cstack;
	  if ($n->[0] == 5) { # binaryop?
	      $op = $n->[1];
	      unshift @cstack, [ 2, $self->binaryop_evaluate($lvalue,$op,$operand) ];
	      next;
	  } elsif ($n->[0] == 4) { # unaryop (to work on operand, ignoring lvalue)
	      $op = $n->[1];
	      unshift @cstack, [ 2, $self->unaryop_evaluate($op,$operand) ];
	      unshift @cstack, [ 2, $lvalue ];
	      next;
	  } else {
	      print STDERR "Got $lexeme_types{$n->[0]} $n->[1] where operator expected in '$cond'";
	      return '';
	  }
	  next;
      } else {
	  print STDERR "Got $lexeme_types{$n->[0]} $n->[1] where unaryop or identifier expected in '$cond'";
	  return '';
      }
  }
  $n = $cstack[0];
  $debug and
    print STDERR "[postloop n={$n->[0],$n->[1]}]";

  if ($self->{use_full_cond_cache}) {
      $self->{fullcond_cache}{"$ovr\t$cond"} = $n->[1];
  }
  defined $n->[1] and return $n->[1];
  '';
}

sub binaryop_evaluate {
  my $self = shift;
  my ($lvalue,$op,$operand) = @_;

  $debug and
    print STDERR "[binaryop_eval($lvalue,$op,$operand)]";
  if (!defined $op) {
#      print STDERR "[missing operator in binaryop_evaluate]";
      return undef;
  }
  if (!defined $lvalue) {
#      print STDERR "[lvalue undefined in binaryop_evaluate]";
      return undef;
  }
  if (!defined $operand) {      
#      print STEDRR "[operand undefined in binaryop_evaluate]";
      return undef;
  }
  # string comparison ops
  if ($op eq 'eq') {
      return $lvalue eq $operand;
  } elsif ($op eq 'ne') {
      return $lvalue ne $operand;
  } elsif ($op eq 'lt') {
      return $lvalue lt $operand;
  } elsif ($op eq 'le') {
      return $lvalue le $operand;
  } elsif ($op eq 'gt') {
      return $lvalue gt $operand;
  } elsif ($op eq 'ge') {
      return $lvalue ge $operand;
  } elsif ($op eq '=~' and $self->{enable_pattern_operator}) {
      return $lvalue =~ m/$operand/;
  } elsif ($op eq '!~' and $self->{enable_pattern_operator}) {
      return $lvalue !~ m/$operand/;
  }
  # numeric comparison ops
  elsif ($op eq '==') {
    return $lvalue == $operand;
  } elsif ($op eq '!=') {
      return $lvalue != $operand;
  } elsif ($op eq '<') {
      return $lvalue < $operand;
  } elsif ($op eq '<=') {
      return $lvalue <= $operand;
  } elsif ($op eq '>') {
      return $lvalue > $operand;
  } elsif ($op eq '>=') {
      return $lvalue >= $operand;
  } elsif ($op eq '<=>') {
      return $lvalue <=> $operand;
  }
  # logical ops
  elsif ($op eq '&&' or $op eq 'and') {
      return ($lvalue && $operand);
  } elsif ($op eq '||' or $op eq 'or') {
      return ($lvalue || $operand);
  }

  # string combination ops
  elsif ($op eq '.') {
      return $lvalue . $operand;
  } elsif ($op eq 'x') {
      return $lvalue x $operand;
  }

  # arithmetic ops
  elsif ($op eq '+') {
      return $lvalue + $operand;
  } elsif ($op eq '-') {
      return $lvalue - $operand;
  } elsif ($op eq '*') {
      return $lvalue * $operand;
  } elsif ($op eq '/' and $operand) {
      return $lvalue / $operand;
  } elsif ($op eq 'div' and $operand) {
      return int($lvalue/$operand);
  } elsif ($op eq 'mod' and $operand) { # % is reserved
      return $lvalue % $operand;
  } elsif ($op eq '**') {
      return $lvalue ** $operand;
  }
  # bitwise ops
  elsif ($op eq '^') {
      return 1*$lvalue ^ 1*$operand;
  } elsif ($op eq '&') {
      return 1*$lvalue & 1*$operand;
  } elsif ($op eq '|') {
      return 1*$lvalue | 1*$operand;
  } elsif ($op eq '<<') {
      return 1*$lvalue << 1*$operand;
  } elsif ($op eq '>>') {
      return 1*$lvalue >> 1*$operand;
  }
  undef;
}

sub unaryop_evaluate {
  my $self = shift;
  my ($op,$operand) = @_;

  $debug and
    print STDERR " [unary_eval $op, $operand]";
  if (!$op) {
    return (!(!($operand)));
  } elsif ($op eq '!') {
    return !$operand;
  } elsif ($op eq 'defined' || $op =~ /^defined\s+/) {
    return defined $operand;
  }
  # fill in other ops here
  undef;
}

=item identifier_evaluate $identifier \%ovr [ $type, $name ]

Evaluates the specified identifier and returns its value.  Literals,
being of the form \d+, "[...]" and '[...]', are returned as-is (leading
and trailing quotes will be removed from string literals).

Identifiers of standard (no special type) form are returned as they appear
in \%ovr; if those stored values are listrefs or hashrefs, they will be
returned in formatted form -- listrefs will be returned as a scalar
delimited by the value of $self->{list_delimiter}->{B<name>}, hashes will
be mapped into a scalar using $self->{hash_specifier}->{B<name>} and
$self->{hash_delimiter}->{B<name>}, which three have the form ", ",
"=" and ", " respectively by default.

Identifiers of the form $name will be checked against the environment
variable of the same name, and if present, that value will be returned,
otherwise undef will be returned.

Identififers of the form &name will be returned according to those entries
in \%ovr of the form &name -- this is used to provide a separate namespace
for substitutions, e.g. for CGI parameters.

Identifiers of the form !name will be evaluated according to the return
value(s) from whatever stored procedure(s) have been registered under that
name, if any.  See C<store_dynroutine> for details.

=cut

sub identifier_evaluate {
  my $self = shift;
  my $identifier = shift;
  my $ovr = shift || {};
  my ($type,$name,$args,$undef_asis) = @_;

  # undef is an OK value, but undef
  # is also the correct thing to return in such a case.
  $debug and print STDERR " [identifier $identifier(",$type || '',',',$name || '',")]";
  !defined $identifier and return $self->{default_undef_identifier};
  !$identifier and return $identifier;
  unless (defined $type && $name) {
      return $1 if $identifier =~ /^(\d+)$/;
      return $1 if $identifier =~ /^\"(.*)\"$/;
      return $1 if $identifier =~ /^\'(.*)\'$/;
      if ($identifier =~ /^([&\$\"]?)([A-Za-z_]\w*)$/) {
	  ($type,$name) = ($1,$2);
      } elsif ($identifier =~ /^&(\w+)\((.*)\)$/) {
	  ($type,$name,$args) = ('&',$1,$2);
      } else {
	  print STDERR "Malformed identifier '$identifier'";
	  return undef;
      }
  }
  $debug and print STDERR " [identifier_evaluate: type=$type name=$name]";
  if (!$type) {
      if (!defined $ovr->{$name}) {
#	  print STDERR "!defined $name, undef_asis=$undef_asis";
	  return ($undef_asis ? undef : $self->{default_undef_identifier} );
      } elsif (!ref $ovr->{$name}) {
	  return $ovr->{$name};
      } elsif (ref $ovr->{$name} eq 'ARRAY') {
	  return join($self->{list_delimiter}->{$name} ||
		      $self->{list_delimiter}->{__default},
		      @{ $ovr->{$name} });
      } elsif (ref $ovr->{$name} eq 'SCALAR') {
	  return ${ $ovr->{$name} };
      } elsif (ref $ovr->{$name} eq 'HASH') {
	  return join($self->{hash_delimiter}->{$name} ||
		      $self->{hash_delimiter}->{__default},
		       map { $_.
			      ($self->{hash_specifier}->{$name} ||
			       $self->{hash_specifier}->{__default}).
			      $ovr->{$name}->{$_}
		       } keys %{$ovr->{$name}}
		      );
      } elsif (ref $ovr->{$name} eq 'CODE') {
	!$self->{eval_subroutine_refs} and return $self->{disabled_subref_identifier};
	return $self->evaluate_dynroutine($name,'',$ovr);
      }
      return $ovr->{$name};
#  } elsif ($type eq '&') {
#      return $ovr->{'&'.$name};
  } elsif ($type eq "\$") {
      return $ENV{$name};
  } elsif ($type eq '&') {
      $args ||= '';
      $debug and print STDERR " [returning \$self->evaluate_dynroutine($name,$args,$ovr)]";
      !$self->{eval_subroutine_refs} and return $self->{disabled_subref_identifier};
      return $self->evaluate_dynroutine($name,$args,$ovr);
  }
  return undef;
}

=item evaluate_dynroutine $name, $args, \%ovr

Evalutes a routine referenced by a template.  The general form gives the
name of the routine in $name (if no such named routine is available,
returns undef), any arguments as a scalar $args, and the key-sub list
in $ovr.

$args should be given as a scalar -- it will be parsed in
B<parse_dynroutine_args> and the result cached against future use.

=cut

sub evaluate_dynroutine {
    my $self = shift;
    my ($name,$args,$ovr) = @_;
    my @real_args;
    my ($buf,$seg,$sseg) = ('');
    my $use_recursive_parse = 0;
    my %ra;
    
    $name && $ovr or return undef;
    $name =~ /^bt_/ and return $self->evaluate_pragma(@_);
    $ovr->{$name} or return undef;
    $args ||= '';
    $debug && print STDERR " [evaluate_dynroutine: name=$name args=$args ovr=$ovr]";
    if ($args) {
	if ($self->{dynroutine_arg_cache}{$args}) {
	    $args = $self->{dynroutine_arg_cache}{$args};
	} else {
	    my $targs = $self->parse_dynroutine_args($args);
	    $self->{dynroutine_arg_cache}{$args} = $targs;
	    $args = $targs;
	}
    }
    if (ref $args eq 'ARRAY') {
	for (0..$#{$args}) {
	    if ($args->[$_] eq '$_bt_dict') {
		$args->[$_] = $ovr;
	    } elsif ($args->[$_] =~ /^\\(.*)$/) {
		# escaped anything
		$args->[$_] = $1;
	    } elsif ($args->[$_] =~ /^\$([\$\&]?\w+)$/) {
		# scalar
		$args->[$_] = $self->identifier_evaluate($1,$ovr);
	    } elsif ($args->[$_] =~ /^\$\{([^\}]+)\}$/) {
		$args->[$_] = $self->cond_evaluate($1,$ovr);
	    }
	}
	@real_args = @{ $args };
    } else {
	@real_args = ();
    }

    if (@real_args and !(($#real_args+1) % 2)) {
	$debug and print STDERR " [right number of args to recurse, ref=".(ref $ovr->{$name})."]";
	if (ref $ovr->{$name} eq 'CODE' or
	    (ref $ovr->{$name} eq 'ARRAY' and
	     $#{ $ovr->{$name} } == 2 and
	     ref $ovr->{$name}->[1] eq 'CODE')) {
	    %ra = @real_args;
	    if ($ra{bt_template}) {
		$use_recursive_parse = 1;
	    }
#	    $debug and print STDERR " [use recursive_parse]";
        }
    }

#    print " [e_d: name=$name, ovr=$ovr ovr->name=$ovr->{$name}]";
#    ref $ovr->{$name} eq 'ARRAY' and $debug and print STDERR " [num=".$#{ $ovr->{$name} }."]";
    if (ref $ovr->{$name} eq 'CODE') {
	$buf = &{ $ovr->{$name} }(@real_args);
	$debug and print STDERR " [real_args=".join(',',@real_args)." n=$#real_args]";
	!ref $buf and return $buf;
	if (ref $buf eq 'HASH' and $use_recursive_parse) {
	    $debug and print STDERR " [would now recurse to parse subref output]";

	}
    } elsif (ref $ovr->{$name} eq 'ARRAY' and
	     $#{ $ovr->{$name} } == 2) {
	if (!ref $ovr->{$name}->[0]) {
	    $buf = $ovr->{$name}->[0];
	    $debug and print STDERR " [started with scalar $buf]";
        } elsif (ref $ovr->{$name}->[0] eq 'CODE') {
	    $seg = &{ $ovr->{$name}->[0] }(@real_args);
	    if ($use_recursive_parse and ref $seg eq 'HASH') {
		$sseg = $self->parse($ra{bt_template},$seg,$ovr,
					 { _bt_recurse_count =>
					   $ovr->{_bt_recurse_count}+1 });
		if (ref $sseg eq 'SCALAR') {
		    $buf = $$sseg;
		} elsif (!ref $sseg) {
		    $buf = $sseg;
		}
	    } else {
		$buf = $seg;
	    }		
	}
	if (!ref $ovr->{$name}->[1]) {
	    $buf .= $ovr->{$name}->[1];
        } elsif (ref $ovr->{$name}->[1] eq 'CODE') {
	    while ($seg = &{ $ovr->{$name}->[1] }(@real_args)) {
		if ($use_recursive_parse and ref $seg eq 'HASH') {
		    $sseg = $self->parse($ra{bt_template},$seg,$ovr,
					 { _bt_recurse_count =>
					   $ovr->{_bt_recurse_count}+1 });
		    if (ref $sseg eq 'SCALAR') {
			$buf .= $$sseg;
		    } elsif (!ref $sseg) {
			$buf .= $sseg;
		    }
		} else {
		    $buf .= $seg;
		}
	    }
	}
        if (!ref $ovr->{$name}->[2]) {
	    $buf .= $ovr->{$name}->[2];
        } elsif (ref $ovr->{$name}->[2] eq 'CODE') {
#            $buf .= &{ $ovr->{$name}->[2] }(@real_args);
	    $seg = &{ $ovr->{$name}->[2] }(@real_args);
	    if ($use_recursive_parse and ref $seg eq 'HASH') {
		$sseg = $self->parse($ra{bt_template},$seg,$ovr,
				     { _bt_recurse_count =>
				       $ovr->{_bt_recurse_count}+1 });
		$buf .= $$sseg;
	    } else {
		$buf .= $seg;
	    }		
	}
	return $buf;
    }
}

=item parse_dynroutine_args $argstr

Pulls apart the argument string passed to a template-referenced
dynamic routine, and returns a listref for it.

Format tolerance is only minimally clever.  The formats tolerated
are, in any combination:

 word, word,
 word => word, word
 word => "word \"word\" 'word'"
 word => 'word "word"'
 word => "word\nword",

In the first case, each word argument may contain anything but [,=>'"]
(that is, ', ", =, or >; yes, that is not entirely proper).
If you need to use any of those characters, put the arguments in
quotes.  Parsing with quotations is more accurate, but depends on
lookbehind assertions and is accordingly slow (the parse
results are cached, so this is mostly an issue in repetitive
executions rather than use of many instances in one template).

=cut

sub parse_dynroutine_args {
    my $self = shift;
    my $argstr = shift || return [];
    my @args = ();
    my $x;

    if ($argstr =~ tr/\"\'/\"\'/) {
	while ($argstr =~ m/\s*([^,=>\"\']+?|           # word arg (yes, the => in the class is bad
				(\"|\')(.*?(?<!\\))\2   # quoted
			       )\s*(?:,|=>|$)/sgx) {    # space, comma, =>
		   $x = $3 || $1;
		   $x eq "''" or $x eq '""' and $x = '' ;
		   $x =~ s/(?<!\\)\\([\"\'])/$1/g;
		   push @args, $x;
	}
    } else {
	@args = split(/\s*(?:=>|,)\s*/,$argstr);
    }
#	   warn "parse_args: [new: $argstr -> ".join('|',@args)."]";
#	   warn "parse_args: vs [old: $argstr -> ".join('|',split(/\s*(?:=>|,)\s*/,$argstr))."]";
#	   return [ split(/\s*(?:=>|,)\s*/,$argstr) ];
    \@args;
}

=item evaluate_pragma $name, $args, \%ovr

=cut

sub evaluate_pragma {
    my $self = shift;
    my ($name,$args,$ovr) = @_;
    my @real_args;

    $args ||= '';
    $name && $ovr or return undef;
    $debug && print STDERR " [evaluate_dynroutine: name=$name args=$args ovr=$ovr]";
    if ($args) {
	if ($self->{dynroutine_arg_cache}{$args}) {
	    $args = $self->{dynroutine_arg_cache}{$args};
	} else {
	    my $targs = $self->parse_dynroutine_args($args);
	    $self->{dynroutine_arg_cache}{$args} = $targs;
	    $args = $targs;
	}
    }
    if (ref $args eq 'ARRAY') {
	@real_args = @{ $args };
    } else {
	@real_args = ();
    }
    unless ($self->{pragma_enable}->{$name} &&
	    ref $self->{pragma_functions}->{$name} eq 'CODE') {
	$debug && print STDERR "pragma $name is disabled or has no function reference (enable=$self->{pragma_enable}->{$name}, ref=$self->{pragma_functions}->{$name}";
	return $self->{disabled_pragma_identifier};
    }
#    print STDERR "pragma_enable->{$name} is true, calling prama";
    return &{ $self->{pragma_functions}->{$name} }($self,$ovr,@real_args);
}

=item is_identifier \$candidate

Takes a reference to a scalar containing a potential identifier.
In a scalar context, returns 1 or 0.  In a list context, returns
(type,name) where type is one of the identififer type designators
(&, !, $, etc) and name is the remainder of the identifier.

=cut

sub is_identifier {
    my $self = shift;
    my $nr = shift;

    !defined $nr and return undef;
    !ref $nr and $nr = \$nr;

    $debug and print STDERR " [ checking nr=$$nr ]";
    if (!$self->{reserved_words}->{$$nr} &&
	$$nr =~ /^%?([&\$]?)(\w+)%?$/) {
	$debug and print STDERR "[ $$nr is an identifier:($1,$2) ]";
	wantarray and return ($1,$2);
	return 1;
#    } else {
#	$debug and print STDERR " [ not identifier ]";
    }
    wantarray and return ();
    return 0;
}


=item lex \$src

Splits the specified source buffer into a series of tokens, returns
a listref to the resulting lexicon.  See B<ABOUT> for the details.

=cut

sub lex {
  my $self = shift;
  my $src = shift || return;
  my ($inlen,$inblock,$pos);
  my ($prior,$opseq,$opcontent);
  my ($itype,$iname);
  my @lexicon = ();
  my $clevel = 0;

  !ref $src and $src = \$src;

  use re 'taint';
  $self->{compatibility_mode_0x} and
    $$src = $self->convert_template_0x_2x($$src);  
  !$$src and return [];
    
  $inlen = length($$src) || 0;
  $pos = 0;
 LEXEME: while ($pos < $inlen) {
      next LEXEME unless $$src =~ m/([^%]*)(%([^%]*)%)?/mg;
      $pos = pos($$src);
      ($prior,$opseq,$opcontent) = ($1,$2 || '',$3 || '');
      if ($opseq eq '%%') {
	  $prior .= '%';
	  $opseq = '';
      }

      push @lexicon, [ $clevel, $prior, 0 ];
      next LEXEME unless $opseq;
#      if ($opseq =~ /^%(if |elsif |fi%)/) {
#	  $debug and print STDERR " [ found std. conditional $opseq ]";
#	  push @lexicon, [ ++$clevel, $opseq, 1 ];
#	  next LEXEME;
#      } els
#      print STDERR " [opseq=$opseq]";
      if (($itype,$iname) = $self->is_identifier(\$opseq)) {
	  $debug and
	    print STDERR " [ found identifier $itype,$iname ]";
	  push @lexicon, [ $clevel, $opseq, 2, $itype, $iname ];
	  
	  next LEXEME;
      } elsif (($opcontent) &&
	       ($opcontent !~ /^(if\s|elsif\s|fi$|else$)/) &&
	       ($opcontent =~ tr/^A-Za-z0-9_/^A-Za-z0-9_/)) {
	  $debug and
	    print STDERR " [ found non-conditional operation $opcontent ]";	  
	  push @lexicon, [ $clevel, $opseq, 6, $opcontent ];
	  next LEXEME;
      }
      $clevel++ if $opseq =~ /^%if\s/;
      push @lexicon, [ $clevel, $opseq, 1 ];
      $clevel-- if $opseq eq '%fi%';
  }
  \@lexicon;
}

=item load_from_file $filename

Loads a template from the specified file.  If use_file_cache is true,
the file will be stored in the file cache (not necessary if caching
is enabled for lexicons).

This code is very trusting concerning its filename -- the only check
performed is to strip leading <, >, | and + signs to try to ensure that
the filehandle obtained is read-only.  Trailing pipes will be left
alone, so that "/path/to/binary|" may use the output from 'binary'.

=cut

sub load_from_file {
    my $self = shift;
    my $fn = shift || return undef;
    my ($b,$buf);

    if (!$self->{open_tainted_files} &&
	$self->is_tainted($fn)) {
	print STDERR "Text::BasicTemplate: load_from_file: '$fn' is tainted, can't open safely\n";
	return undef;
    }
    $self->{file_cache}{$fn} and return $self->{file_cache}{$fn};
    $fn =~ s/^[\+<>|]+//;
    $buf = '';
    sysopen(TMPL,$fn,0) || do {
	$debug and print STDERR "Text::BasicTemplate::load_from_file($fn): $!";
	return undef;
    };
    $self->{use_flock} and flock(TMPL,LOCK_SH);
    while (sysread(TMPL,$b,4096)) {
	$buf .= $b;
    }
    $self->{use_flock} and flock(TMPL,LOCK_UN);
    close(TMPL);
    $buf .= substr($^X,0,0); # deliberately taint the contents
    $self->{use_file_cache} and $self->{file_cache}{$fn} = \$buf;
    \$buf;
}


## pragma functions

sub bt_include {
    my $self = shift;
    my $ovr = shift || {};
    my ($type,$file,$parse) = @_;
    my $buf;

    if ($type && !$file) {
	$file = $type;
	$type = 'file';
    }
    $parse = !($parse and $parse eq 'noparse');
    
    $type && $type =~ /^(file|virtual|semisecure)$/ && $file or
      return '[format: bt_include([ file | virtual | semisecure ], fn, [ noparse])]';
    if ($type eq 'semisecure') {
	no re 'taint';
	if ($file =~ /^(\w[\w\-.]{0,254})$/) {
	    $file = $1;
	} else {
	    return "[bt_include: File '$file' does not match valid pattern in semisecure mode]";
	}
	if ($self->is_tainted($file) &&
	    !$self->{bt_include_allow_tainted}) {
	    return "[bt_include: semisecure filename $file is tainted, can't include]";
	}
	-e $file or return "[bt_include: semisecure file $file does not exist]";
	-f _ or return "[bt_include: semisecure file $file is not a regular file]";
	-r _ or return "[bt_include: semisecure file $file not readable]";
	$parse and return $self->parse($file,$ovr);
	$buf = $self->load_from_file($file);
	print STDERR "[buf=$buf for file=$file]";
	return ((ref $buf eq 'SCALAR') ? $$buf : "[bt_include: load_from_file returned nothing]");
    } elsif ($type eq 'virtual') {
	unless ($self->{include_document_root} || $ENV{DOCUMENT_ROOT}) {
	    return '[bt_include: No document root supplied in virtual mode]';
	}
	if ($self->is_tainted($file) &&
	    !$self->{bt_include_allow_tainted}) {
	    return "[bt_include: virtual filename $file is tainted, can't include]";
	}
	$file = ($self->{include_document_root} || $ENV{DOCUMENT_ROOT}) .
	  '/' . $file;
 	-e $file or return "[bt_include: virtual file $file does not exist]";
	-f _ or return "[bt_include: virtual file $file is not a regular file]";
	-r _ or return "[bt_include: virtual file $file not readable]";
	$parse and return $self->parse($file,$ovr);
	$buf = $self->load_from_file($file);
	return ((ref $buf eq 'SCALAR') ? $$buf : "[bt_include: load_from_file returned nothing]");
    } elsif ($type eq 'file') {
	if ($self->is_tainted($file) &&
	    !$self->{bt_include_allow_tainted}) {
	    return "[bt_include: filename $file is tainted, can't include]";
	}
	-e $file or return "[bt_include: file $file does not exist]";
	-f _ or return "[bt_include: file $file is not a regular file]";
	-r _ or return "[bt_include: file $file not readable]";
	$parse and return $self->parse($file,$ovr);
	$buf = $self->load_from_file($file);
	print STDERR "[buf=$buf for file=$file]";
	return ((ref $buf eq 'SCALAR') ? $$buf : "[bt_include: load_from_file returned nothing]");
    } else {
	return "[bt_include: include type '$type' not known]";
    }
}

=item bt_exec

=cut


sub bt_exec {
    my $self = shift;
    my $ovr = shift || {};
    my ($type,$command,$parse) = @_;
    my $buf;

    $type && $type =~ /^(cmd|cgi)$/ && $command or
      return '[format: bt_exec({ cmd | file }, command [, parse ])]';
    $parse ||= 0;
    if ($type eq 'cmd') {
	open(IC,$command.'|') ||
	  return "[bt_exec: Couldn't exec $command: $!]";
	$buf = join(',',<IC>);
	close IC;
	if ($parse && $buf) {
	    $buf = $self->parse(\$buf,$ovr);
	}
	return $buf;
    } elsif ($type eq 'cgi') {
	open(IC,$command.'|') ||
	  return "[bt_exec: Couldn't exec $command: $!]";
	while (<IC>) {
	    chomp;
	    last if !$_;
	}
	$buf = join(',',<IC>);
	close IC;
	if ($parse && $buf) {
	    $buf = $self->parse(\$buf,$ovr);
	}
	return $buf;
    }
}

=item dump_lexicon \@lexicon [ $start_pos [ $end_pos ] ]

Returns a dump of the given lexicon.  Principally used for debugging the
module, or if you need to optimize templates to save lexical storage.
If $start_pos/$end_pos are given, only that range of the lexical array
is dumped.

=cut

sub dump_lexicon {
    my $self = shift;
    my $L = shift;
    my $l;
    my ($start_pos,$end_pos) = @_;
    my $x;
    my $b = '';


    ref $L eq 'ARRAY' or return undef;
    for (my $i=$start_pos || 0; $i<=($end_pos || $#{$L}); $i++) {
	$l = $L->[$i];
	$b .= "[ $i: L$l->[0] $lexeme_types{$l->[2]}";
	$x = $l->[1];
	$x =~ s/\n/\\n/g;
	$x =~ s/\t/\\t/g;
	$x =~ s/\r/\\r/g;
	$b .= " '$x'";
	defined $l->[3] and $b .= " '$l->[3]'";
	defined $l->[4] and $b .= " '$l->[4]'";
        $b .= " ]\n";
    }
    $b;
}

=item dump_stack \@stack

Dumps the contents of a conditional-eval stack, which consists of a list of listrefs
containing [ type, value ], type being one of the lexeme_types, value being either
the identififer or an operator, depending on the type.

=cut

sub dump_stack {
    my $self = shift;
    my $sr = shift;
    my $terse = shift || 0;
    my $S;
    my $b = '';
    my $x = 0;

    ref $sr eq 'ARRAY' or return undef;
    for $S (@{$sr}) {
	if ($terse) {
	    $b .= ',' if $x++;
	    $b .= "$S->[1]";
	} else {
	    $b .= "{ $lexeme_types{$S->[0]}, $S->[1] }";
	}
    }
    $b;
}

=item list_lexicon_cache

Lists the lexicons cached for files/scalars/etc.

=cut

sub list_lexicon_cache {
  my $self = shift;

  keys %{$self->{lexicon_cache}};
}

=item list_file_cache

Lists the files cached in the file cache.  Empty unless use_file_cache is
true.

=cut

sub list_file_cache {
  keys %{$_[0]->{file_cache}};
}

=item list_cond2rpn_cache

Lists the conditional-to-RPN conversion cache.  Empty if B<use_cond2rpn_cache>
is false.

=cut

sub list_cond2rpn_cache {
  keys %{$_[0]->{cond2rpn_cache}};
}

=item list_fullcond_cache

Lists the contents of the conditional evaluation cache.  Empty unless
B<use_full_cond_cache> is set true.

=cut

sub list_fullcond_cache {
  keys %{$_[0]->{fullcond_cache}};
}

=item taint_enabled

Tries to work out if taint checking is enabled, so that the right things
can be enabled/disabled by new().

=cut

sub taint_enabled {
    return not eval { my $x = $^X, kill 0; $x };
}

=item is_tainted SCALAR

Returns true if taint checking is enabled and the specified
variable is tainted.

=cut

sub is_tainted {
    return undef unless defined $_[1];
    return not eval { my $x = $_[1], kill 0; $x };
}


=item debug DEBUGLEVEL

Activates debugging output.

=cut

sub debug {
    shift;
    $debug = shift;
}

=item purge_lexicon_cache

=item purge_cond2rpn_cache

=item purge_fullcond_cache

=item purge_file_cache

Purges the given cache.

=cut

sub purge_lexicon_cache { $_[0]->{lexicon_cache} = (); }
sub purge_cond2rpn_cache { $_[0]->{cond2rpn_cache} = (); }
sub purge_fullcond_cache { $_[0]->{fullcond_cache} = (); }
sub purge_file_cache { $_[0]->{file_cache} = (); }


## backwards-compatibility functions


=item list_cache

Compatibility function for BasicTemplate 0.x; synonym for B<list_lexicon_cache>

=cut

sub list_cache { $_[0]->list_lexicon_cache };


=item push, parse_push

Compatibility functions for BasicTemplate 0.x; synonym for B<parse>.

=cut

sub push { my $self = shift; $self->parse(@_) };
sub parse_push { my $self = shift; $self->parse(@_) };

=item print, parse_print

Compatibility functions for BasicTempltae 0.x

=cut

sub print { my $self = shift; print $self->parse(@_); };
sub parse_print { my $self = shift; print $self->parse(@_); };

=item purge_cache

Compatibility function for BasicTemplate 0.x; purges all
applicable caches.

=cut

sub purge_cache {
  $_[0]->purge_lexicon_cache;
  $_[0]->purge_cond2rpn_cache;
  $_[0]->purge_fullcond_cache;
  $_[0]->purge_file_cache;
  1;
}

=item uncache FILE

Compatibility function for BasicTemplate 0.x; purges the
specified file from the file and lexicon caches.

=cut

sub uncache {
    $_[0]->purge_lexicon_cache($_[1]);
    $_[0]->purge_file_cache($_[1]);
}

=item convert_template_0x_2x $buffer

Backwards-compatibility function for BasicTemplate 0.x; converts a
template constructed for v0.x to v2.x.  Used internally for conversions
on-the-fly in backwards-compatible mode.

Note that this method will have no effect unless the 0.x template
contains conditionals -- simple %key% substitutions are the same in
both versions.

=cut

sub convert_template_0x_2x {
  my $self = shift;
  my $buf = shift || return undef;
  my ($lvalue,$operator,$operand,$aoperand,
      $aoperator,$truesub,$atruesub,
      $falsesub,$afalsesub);

  ref $buf eq 'SCALAR' and $buf = $$buf;
  !$buf and return '';

  use re 'taint';

#  print STDERR "Pbuf=$buf\n";
#  $buf =~ s/([^%])%([^%\w\s?!])/$1%%$2/g;

#

  # does it have anything that looks 2.0-ish in it?
  $buf =~ m/(%if\s+[^%]+%|%&\w+\([^\)]*\)%)/gm and do {
#      warn "convert_template_0x_2x(): matched $1, assuming new template";
      return $buf;
  };

  # does it use 0.x-style conditionals?
  $buf =~ m/%\?|<!--\#include/m or return $buf;

#  print STDERR "2buf=[$buf]\n";
#  my ($itype,$ifn);
#  while ($buf =~ /<!--\#include\s+(virtual|file)\s*=\s*\"?(.+?)\"?-->/i) {
#      ($itype,$ifn) = (lc $1,$2);
#      # more horrible hack -- parses %key% in the filename (-ian)
#      while ($itype =~ /%(.*?)%/g) {
#	  $self->{compat_0x_ovr} and
#	    defined $self->{compat_0x_ovr}->{$1} and
#	      $itype =~ s/\Q$1\E/$self->{compat_0x_ovr}->{$1};
#      }
#  }

  # without the horrible hack:
    $buf =~ s/<!--\#include\s+(virtual|file)\s*=\s*\"?(.+?)\"?-->/%&bt_include($1,$2)%/g;

#  print STDERR "3buf=[$buf]\n";

  while ($buf =~ m/%\?([\w\.\-]+)\s*(==?|!=)\s*([^%]*)%([^%]*)%([^%]*)%/gm) {
      ($lvalue,$operator,$operand,$truesub,$falsesub) =
	($1,$2,$3,$4,$5);
      ($atruesub,$afalsesub) = ($truesub,$falsesub);
      if ($operand =~ /^{(\w+)}$/) {
	  $aoperand = $1;
      } else {
	  $aoperand = "\"$operand\"";
      }
      $aoperator = ($operator eq '!=') ? ' ne ' : ' eq ';
#    $operand =~ s/^{(\w+)}$/$1/g;
      $atruesub =~ s/{(\w+)}/%$1%/g;
      $afalsesub =~ s/{(\w+)}/%$1%/g;

#      print STDERR "lvalue=$lvalue operator=$operator operand=$operand truesub=$truesub falsesub=$falsesub\n";
    
#    print STDERR "$buf =~ s/%\?\s*$lvalue\s*$operator\s*$operand%$truesub%$falsesub%/%if $lvalue$operator$operand%$truesub%else%$falsesub%fi%/xg;\n";
    
    $buf =~ s/%\?\s*\Q$lvalue\E\s*\Q$operator\E\s*\Q$operand\E\s*%\Q$truesub%$falsesub%\E/%if $lvalue$aoperator$aoperand%$atruesub%else%$afalsesub%fi%/gm;
  }

#  $buf =~ s/([^%]|^)%([,.\'\"<>\[\]{}()@\#\$\^&*])(?!bt_)/$1%%$2/g;
#  $buf =~ s/([ =\"]\d+)%([,.\'\"<>\[\]{}()@\#\$\^&*])(?!bt_)/$1%%$2/g;
#  print STDERR "backconvert[$buf]";
  $buf;
}

1;

__END__

=head1 HISTORY

2.004: Fixed a dumb oversight in test suite where valid comparison
strings assumed that the iteration order in a hash would be consistent
and predictable.  Passes make-test under perl5.6 now.

2.0: Major rewrite.  Introduced lexical parsing, nested conditionals,
list/hash formatting, subroutine references, operator evaluation and
much other related stuff.

0.9.8: Added subroutine-reference parsing.  This makes it possible to
bind keys to subroutines which will be called (once per template)
when needed; this can make things quicker if the template-specific
informational requirements may not be easily predicted in advance.

0.9.7: Made stripping of lingering keys optional (default off); it
was causing problems with URI-encoded substitutions, and in
retrospect probably was not a good idea anyway.  Thanks to Ian Baker
<ian@sonic.net> for the bug report.

0.9.6.1: Fixed stupid idiotic bug caused by overzealous optimization (some
things were not meant to be done with references -- setting cache scalars,
for iinstance).  Renamed from ParsePrint to BasicTemplate for submission to
CPAN.  Fixed oversight wherein files inserted via simple_ssi #includes were
having keys stripped, but not parsed first.

First fully public release.  Hooray...

0.9.6: Rewrote argument handling in constructor the same way;
deprecated old style arg passage.

0.9.5: Rewrote argument handling in parse_push to handle arbitrary
combinations of different arg types.

0.9.4.1: Fixed nasty bug that set the lvalue in comparison to
the name of the entitity lvalue, not the value thereof.

0.9.4: Lots of optimizations.  Inlined eval_conditional(),
introduced caching of condititionals (parse-once, print repeatedly),
other such changes.  Approximately doubled output speed to about
3100 conditionals/sec on my i686-200 Linux box.

0.9.3: First stable, releaseable version.  Much documentation.

=head1 AUTHOR

Text::BasicTemplate is by Devin Carraway <tbtpod@devin.com>, originally
written for Sonoma.Net in 1996.  Maintained until v0.9.5 as ParsePrint,
then Text::ParsePrint, then renamed for CPAN upload to Text::BasicTemplate.
Assorted further assistance and debugging rendered by Ian Baker <ian@sonic.net>
and Eric Eisenhart <tbtpod@eisenhart.com>.

=head1 COPYRIGHT

Copyright (c) 1996-1997 by Devin Carraway and Sonoma.Net.
Copyright (c) 1997-1999 by Devin Carraway.
Released under terms of the Perl Artistic License.

=cut

