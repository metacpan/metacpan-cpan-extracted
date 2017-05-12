package WWW::Agent::Plugins::Director;

use strict;
use Data::Dumper;
use POE;

=pod

=head1 NAME

WWW::Agent::Plugins::Director - plugin for controlling an agent

=head1 SYNOPSIS

  use WWW::Agent;
  use WWW::Agent::Plugins::Director;
  my $a = new WWW::Agent (plugins => [
                                      ...,
                                      new WWW::Agent::Plugins::Director,
                                      ....
                                      ]);

  # do it manually (consider to use WWW::Agent::Zombie)
  use POE;
  POE::Kernel->post ( 'agent', 'director_execute', 'zombie', $weezl );
  $a->run;

=head1 DESCRIPTION

This plugin for L<WWW::Agent> allows to send the agent a script,
written in WeeZL. That can direct the agent to visit particular pages,
assert that the URL is what you expect, wait for some time, check for
text in the page, fill out forms and automatically click on URLs.

The language also allows to define functional blocks which are
executed whenever a specified URL is visited.

=head2 Requisites

If you use this plugin then you must make sure that also
L<WWW::Agent::Plugins::Focus> is loaded first.

=head2 Web Zombie Language (WeeZL)

The I<Web Zombie Language>, pronounced I<weezle>, specifies the
behaviour of a virtual web user. It also allows to define assertions
and conditions to be checked at certain times. The former can be used
for testing web sites, the latter to trigger customized actions.

WeeZL is for most of its part a procedural language, so commands
are executed in sequential order, as given in the text.

=head3 Comments

WeeZL can contain comments, similar to Perl these start with a hash
sign (#) and reach until the end of the same line.


=head3 Actions

Actions are the primitives which can be executed. As such, they can
fail and doing so, an internal exception is raised. This is not fatal
to the process as actions can be combined such that one failure can be
compensated by another action.

The agent is also using the concept of a I<focus>: At any page, the
browser can be asked to focus on a particular subelement (interpreting
the HTML as an decent XML document). The focus can be narrowed down.
After every statement, though, the focus is reset to the whole page.

The language offers the following primitives:

=over

=item URL request

The command C<url> I<URL> make the agent move to this given URL.  If
the URL cannot be fetched successfully, an internal exception is
raised.

=item URL assertion

The command C<url> I<regexp> tests whether the agent is currently at a
URL which matches the given regular expression. If not, an internal
exception will be raised.

=item forced exception

The command C<die> I<message> will raise an internal exception. It always
fails (in succeeding :-) The message will be forwarded to the application
unless the exception is handled internally.

=item messages

The command C<warn> I<message> will write the message onto STDERR. It
never fails.

=item waiting

The command C<wait> I<n> C<secs> makes the agent wait the given
amount of time. The command never fails.

The variant C<wait> C<~> I<n> C<secs> will randomly dither the time to
wait. The dithering can be controlled with the C<time_dither>
parameter for the constructor.

=item text testing

The command C<text> I<regexp> test whether the current focus contains
text which matches the given regular expression. Hereby all HTML
elements have been removed. If there is no match, then this command
fails with an exception.

=item HTML testing

The command C<html> I<regexp> tests whether the current focus matches
the regular expression given. If not, then this command will fail with
an exception.

=item focussing

The command E<lt> html-element E<gt> changes the current focus by
looking for this particular HTML element in the current focus (or the
whole page if not focus yet exists). If that subelement cannot be
detected, this command will fail.

Optionally a regular expression can be added, so that this command
only succeeds if the text B<inside> the new focus would match the
regular expression.

Optionally a index can be provided with C<[> I<n> C<]> to select the
I<n>th occurrence of that element in the current focus. Counting
starts with zero.

=item Filling out FORMs

The command C<fill> I<identifier> I<value> assumes that the current
focus is on a FORM element. Otherwise the command will fail.

For FORMs, the field identified will be filled with the value given.

NOTE: This is not yet fully functionally complete (popup menues,
checkboxes....).

=item Following Links

The command C<click> assumes that the current focus is either on a
FORM or on an anchor (E<lt>aE<gt>) element.

For a FORM it will use the FORM's current value and submit the FORM as
provided in the ACTION attribute.

For an anchor, the command will make the agent follow that link
provided in the HREF attribute.

=back

=head3 Blocks

You can also define separate blocks which can be invoked similar to
subroutines or handlers. To define a block you can either use a label
or a regular expression.

In case of simple names for labels these blocks behave like
subroutines, as the following example demonstrates. First we define a
block which takes care of logging into a site:

  login: {
          url http://www.example.org/login.php
          <form> and fill username 'jill'
                 and fill password 'jack'
          text m|logged in|
          }

Later on in our script we invoke that block

  url http://www.example.org/
  login()
  #....

You can also pass parameters into a block

  login: {
          url http://www.example.org/login.php
          <form> and fill username $uid
                 and fill password $pwd
          text m|logged in|
          }

  url http://www.example.org/
  login(uid => 'jill', pwd => 'jack')
  #....

which are then available as variables (prefixed with '$', of course).

You can also use as block names regular expressions. These will be
checked after each successful request whether one of them matches the
current URL. If so, then the block associated with the regular
expression will be executed automatically. No order is defined here.

  q|login.php|: {
          <form> and fill username 'jack'
                 and fill password 'jill'
          text m|logged in|
          }

  url http://www.example.org/
  url http://www.example.org/login.php  # here we trigger the block
  #....

=head2 Application Hooks

In some cases you may want to invoke functions you provide inside a
WeeZL script. This is useful when you have reached a certain page (or
a part of it) and want to extract specific information out of it.

For this purpose you have to list your functions in the constructor

   new WWW::Agent::Plugins::Director (...
                                      functions   => {
                                                      extract1 => sub {...},
                                                      extract2 => sub {...},
                                                      ...
                                                      }
                                      )

Inside a WeeZL script you simple name the function you want to invoke

   url http://www.example.org/interesting.html
   <table> [1] and extract1
   <table> [3] and extract2
   extract3

After loading the named page, the agent will try to focus on the 2nd
(index 1) table element and will invoke the function associated with
C<extract1>. In this process the function will get one parameter,
namely the HTMLified text of the current focus.

NOTE: THIS MAY CHANGE IN FUTURE VERSIONS.

The function is not supposed to return anything but may be allowed to die.

NOTE: THIS IS NOT WELL SUPPORTED YET.

If that invocation was successful then the 4th table is selected in
the current page and C<extract2> is invoked. After that extract3 is
called whereby it gets the whole page as focus.

=head2 Conjunctions

Primitive actions can be combined with C<and>. As a consequence, the
successful execution of the actions to the left of the C<and> are a
prerequisite, that the action right to the C<and> is executed:

  <form> and fill name 'James Bond'

Here the fillout of the form is only tried after the form
has been found, whereas in

  <form>
  fill name 'James Bond'

first the form is found, then again forgotten as we refocus on the page.
Filling out will fail then.

=head2 Random Choice

Using the infix operator C<xor> you can also make the agent to
choose arbitrarily between two or more choices:

  url http://www.example1.org/ xor
  url http://www.example2.org/ xor
  url http://www.example3.org/

will follow one of the choices.

=head2 Catching Exceptions

If an action fails then the exception can be caught internally
by providing more actions connected with the infix operator C<or>:

  url http://www.example1.org/ or warn "that is not good, but we continue"

  url http://www.example2.org/ or die "now this is really bad"

  url http://www.example3.org/logged-in.php or 
      login (uid => 'jack', pwd => 'jill');

Only if the last action in an C<or> sequence fails, the whole command
fails.

=head2 Examples

@@@ TBW @@@

=head2 Grammar

As notation we use C<|> for alternatives, C<[]> to group optional
sequences, C<{}> to group sequences which may occur any number of
times. The notation

   < something ',' >

is equivalent to, but more concise than

   [ something { ',' something } ]

'xxx' is used for terminals, regular expressions are used to
characterize other lexical constants, all others identifiers are
non-terminals:

    plan          : { subplan } { step }

    subplan       : indicator ':' '{' { step } '}'

    indicator     : regexp | identifier

    identifier    : /\w+/

    step          : or_clause

    or_clause     : < xor_clause /or/ >

    xor_clause    : < and_clause /xor/ >

    and_clause    : < clause /and/ >

    clause        : '{' { step } '}'
                    |
		    'url'  url
                    |
		    'url'  regexp
                    |
		    'die'  [ value ]
                    |
		    'warn' [ value ]
                    |
		    'wait' [ '~' ] /\d+/ ('sec' | 'secs' )
                    |
                    identifier '(' < param /,/ > ')'
                    |
		    identifier
                    |
                    'html' regexp
                    |
                    'text' regexp
                    |
                    '<' identifier '>' [ regexp ]  [ index ]
                    |
		    'fill' identifier value
                    |
                    'click' [ identifier ]

    index         : '[' integer ']'

    value         : string | variable

    variable      : /\$\w+/

    integer       : /\d+/

    param         : identifier '=>' value

    url           : /\w+:[^\s)]+/ # crude approximation

    string        :  '"'  /[^\"]*/ '"'

    string        :  /\'/ /[^\']*/ /\'/

    regexp        : 'm|' /[^\|]+/ '|' /[i]*/

=cut

use Class::Struct;
struct 'ZGoto'     => [ url   => '$' ];
struct 'ZURL'      => [ regexp => '$' ];
struct 'ZRegexp'   => [ pattern => '$', modifier => '$' ];
struct 'ZDie'      => [ val   => '$' ];
struct 'ZWarn'     => [ val   => '$' ];
struct 'ZFunc'     => [ name  => '$' ];
struct 'ZSub'      => [ name  => '$', params => '$' ];
struct 'ZWait'     => [ secs  => '$', dither => '$' ];
struct 'ZHTML'     => [ pat   => '$' ];
struct 'ZText'     => [ pat   => '$' ];
struct 'ZElem'     => [ tag   => '$',
			pat   => '$',
			ind   => '$' ];
struct 'ZFill'     => [ id    => '$', val    => '$' ];
struct 'ZClick'    => [ name  => '$'];

our $grammar = q{

    {
	use Data::Dumper;
	my $plan;
	my $functions;
    }

    startrule     : { $functions = $arg[0]; $plan = undef; 1; }
                    plan                                  { $return = $plan; }

    plan          : subplan(s?) step(s?)                  { $return = $plan->{labels}->{'__start'} = $item[2]; }

    subplan       : indicator ':' '{' step(s?) '}'        { $return = ref ($item[1]) ? 
                                                                ($plan->{catchers}->{$item[1]} = [ $item[1], $item[4] ])
								:
								($plan->{labels}->{$item[1]}   = $item[4]); }

    indicator     : regexp | identifier

    identifier    : /\w+/

    step          : or_clause

    or_clause     : xor_clause(s /or/)                    

    xor_clause    : and_clause(s /xor/)

    and_clause    : clause(s /and/)

    clause        : '{' step(s?) '}'                       { $return = $item[2]; }
                    |
		    'url'  url                             { $return = new ZGoto (url => $item[2]); } 
                    |
		    'url'  regexp                          { $return = new ZURL (regexp => $item[2]); }
                    |
		    'die'  value(?)                        { $return = new ZDie  (val => $item[2]->[0] || \ "no particular reason provided"); }
                    |
		    'warn' value(?)                        { $return = new ZWarn (val => $item[2]->[0] || \ "no particular reason provided"); }
                    |
		    'wait' ('~')(?) /\d+/ /secs?/          { $return = new ZWait (secs => $item[3], dither => $item[1]); }
                    |
                    identifier '(' param(s? /,/) ')'       { $return = $plan->{labels}->{$item[1]}      ? new ZSub  (name   => $item[1], 
														     params => { map { %{$_} } @{$item[3]} })
		                                                                                        : undef;     }
                    |
		    identifier                             { $return = $functions->{$item[1]} ? new ZFunc (name => $item[1]) : undef; }
                    |
                    'html' regexp                          { $return = new ZHTML (pat => $item[2]);}
                    |
                    'text' regexp                          { $return = new ZText (pat => $item[2]);}
                    |
                    '<' identifier '>' regexp(?) index(?)  { $return = new ZElem (tag  => $item[2],
										  pat  => $item[4]->[0],
										  ind  => $item[5]->[0] || 0); }
                    |
		    'fill' identifier value                { $return = new ZFill (id   => $item[2],
										  val  => $item[3]);}
                    |
                    'click' identifier(?)                  { $return = new ZClick (name => $item[2]->[0]); }


    index         : '[' integer ']'                        { $return = $item[2]; }

    value         : string | variable

    variable      : /\$\w+/

    integer       : /\d+/

    param         : identifier '=>' value                  { $return = { '$'.$item[1] => $item[3] };}


#             'tick'                  # must be TICKBOX or RADIO
#             'untick'                # ...

    url           : /\w+:[^\s)]+/ # approximation

    string        :  '"'  /[^\"]*/ '"'         { $return = \ $item[2]; }

    string        :  /\'/ /[^\']*/ /\'/        { $return = \ $item[2]; }

    regexp        : 'm|' /[^\|]+/ '|' /[i]*/   { $return = new ZRegexp (pattern => $item[2], modifier => $item[4]); }

#time_spec -> [ '~' ] positive_int time_unit
#
#time_unit -> /secs?/
#
#location -> regexp (for name) | '#' positive_int (counting from start)
};




my $parser; # will hold a local copy to avoid repeated compilation of the RecDescent parser

sub _init_parser {                                      # instantiate only one if we have not done this before
    eval {
        require WWW::Robot::Zombie::CParser;
        $parser = WWW::Robot::Zombie::CParser->new();
    }; if ($@) {
        $main::log->warn ("could not find precompiled CParser, compiling");
        use Parse::RecDescent;
        $::RD_HINT = 1;
        $::RD_WARN = 1;
        $parser = new Parse::RecDescent ($grammar) or $main::log->logdie (__PACKAGE__ . "Problem in grammar");
    }
}

=pod

=head1 INTERFACE

=head2 Constructor

The constructor accepts a hash and processes the following keys:

=over

=item time_dither (percentage value, optional)

To control the randomized waiting a percentage value of the form /\d+%/ can
be provided, the default is 10%.

=item functions (hash reference)

If your script may invoke external functions, then you can provide them here.
The keys are the names which can be used inside WeeZL, the values are subroutine
references.

=item exception

If an exception is not handled internally, then it has to be escalated
into the application. By providing a subroutine reference you define a
handler which may memorize or otherwise process this event.

NOTE: A real exception cannot be used, because we do not want the POE
process really to die.

=back

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = bless { }, $class;

    $self->{functions}   = delete $options{functions}   || {};
    $self->{time_dither} = delete $options{time_dither} || '10%';
    die "unsupported dithering spec '".$self->{time_dither}."'" unless $self->{time_dither} =~ /^(\d+)%$/;
    $self->{time_dither} = $1;

    $self->{exception}   = delete $options{exception}   || sub { die shift; };

    $self->{depends}     = [ 'focus' ];

    $self->{hooks} = { 
	'init' => sub {
	    my ($kernel, $heap) = (shift, shift);
	    $heap->{director}->{functions}   = $self->{functions};
	    $heap->{director}->{time_dither} = $self->{time_dither};
	    $heap->{director}->{exception}   = $self->{exception};

	    return 1; # it worked
	},
	'director_execute'  => sub {
	    my ($kernel, $heap) = @_[KERNEL, HEAP];
	    my $director        = $heap->{director};
	    my ($tab, $plan)    = @_[ARG0, ARG1];

	    $parser or _init_parser;             # make sure we have a parser

	    my $cplan;                           # we try to create this here
	    eval {
#	$::RD_TRACE = 1;
		$plan =~ s/\#.*?\n/\n/sg;
		
		$cplan = $parser->startrule (\$plan, 0, $heap->{director}->{functions});
		$main::log->logdie (__PACKAGE__ . ": Incomplete input")             unless $cplan;
		$main::log->logdie (__PACKAGE__ . ": Found unparseable '$plan'")    unless $plan =~ /^\s*$/s;
	    }; if ($@) {
		$main::log->logdie (__PACKAGE__ . ": $@");
	    }
	    my $wvm = $director->{wvm} = {};
	    # predefined frames
	    $wvm->{frames}->{term}  = [ new WVMTerm  ];
	    $wvm->{frames}->{fatal} = [ new WVMFatal ];
	    # frames for this plan

#warn "parsed plan ".Dumper $cplan;

	    foreach my $label (keys %{$cplan->{labels}}) {               # first we make sure that for every label we have a frame
		$wvm->{label2frame}->{$label} = genL();                  # in the case of forward references
	    }
	    foreach my $label (keys %{$cplan->{labels}}) {               # now we can compile every code segment
		_compile_steps  ($wvm, $cplan->{labels}->{$label}, $wvm->{label2frame}->{$label}, 'term', 'fatal');
	    }

	    foreach my $catcher (keys %{$cplan->{catchers}}) {           # there are no forward references to catcher => one go
		my $l = genL();
		$wvm->{catchers}->{$catcher} = [ $cplan->{catchers}->{$catcher}->[0], $l ];
		_compile_steps  ($wvm, $cplan->{catchers}->{$catcher}->[1], $l, 'term', 'fatal');
	    }

#warn "compiled plan". Dumper $wvm;
	    $wvm->{proc}->{stacks} = [ { frame => $wvm->{label2frame}->{__start},
					 ip    => 0,
					 data  => {} } ];

	    $kernel->yield ( 'director_proceed', $tab );
	},
	'director_proceed' => sub {
	    my ($kernel, $heap) = @_[KERNEL, HEAP];
            my $director        = $heap->{director};
	    my $wvm             = $director->{wvm};
#warn "making a step";#. Dumper $wvm;
	    my ($tab)           = $_[ARG0];
	    my $htab            = $heap->{tabs}->{$tab};

	    my $stack           = $wvm->{proc}->{stacks}->[0];
	    my $instr           = $wvm->{frames}->{$stack->{frame}}->[$stack->{ip}];

	    while (ref ($instr) eq 'WVMChoice') {                        # resolve gotos/arbitrary choices
		my $frame = int(rand (@{$instr->choices}));
		$stack->{frame} = $instr->choices->[$frame];
		$stack->{ip}    = 0;
		$instr = $wvm->{frames}->{$stack->{frame}}->[$stack->{ip}];
	    };
#warn "final action".Dumper $instr;

	    if (ref ($instr) eq 'WVMInstr') {
		my $a = $instr->action;
		if (ref ($a) eq 'ZDie') {                                               # we now already know that this must fail
		    $wvm->{proc}->{message} = _value ($wvm->{proc}->{stacks}, $a->val); # memorize the reason
		    $stack->{frame} = $instr->error;
		    $stack->{ip} = 0;
		    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZWarn') {
		    warn '# '. _value ($wvm->{proc}->{stacks}, $a->val);
                    $stack->{ip}++;                                                     # next statement
		    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZFunc') {
#warn "calling ".$a->name;
		    my $focus = POE::Kernel->call ( 'agent', 'focus_get' );
		    my $text  = $focus->as_text();
		    &{$director->{functions}->{$a->name}} ($text);
                    $stack->{ip}++;                                                     # next statement
		    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZSub') {
#warn "sub exect plan ".$a->name. Dumper ($c->{self}->{cplan}->{labels}->{$a->name});
#warn "params ".Dumper $a->params;	
                    $stack->{ip}++;
		    my $stack = { frame => $wvm->{label2frame}->{$a->name},             # build a new stack frame
				  ip    => 0,
				  data  => $a->params };
		    unshift @{$wvm->{proc}->{stacks}}, $stack;                          # effectively push stack
		    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZWait') {
		    my $s;
		    if ($a->dither) {
			my $variance = $a->secs * $director->{time_dither} / 100.0;
#warn "variance $variance";
			$s           = $a->secs - $variance + rand (2 * $variance);
		    } else {
			$s           = $a->secs;
		    }
                    $stack->{ip}++;                                                     # next statement
#warn "start sleeping $s";
		    $kernel->delay_set ('director_proceed', $s, $tab );

		} elsif (ref ($a) eq 'ZGoto') {
		    my $request = HTTP::Request->new (GET => $a->url);
		    $kernel->yield ( 'cycle_start', $tab, $request );

#		    die $object unless ref ($object) eq 'HTTP::Response' and $object->is_success;

		} elsif (ref ($a) eq 'ZURL') {
		    my $uri = $htab->{response} && $htab->{response}->request->uri;
#warn "in ZURL $uri";
#		    my $url = POE::Kernel->call ( 'agent', 'history', 0);
		    if (_matches ($a->regexp, $uri)) {
			$stack->{ip}++;                                                 # next statement
		    } else {
			$wvm->{proc}->{message} = "url does not match";
			$stack->{frame} = $instr->error;
			$stack->{ip} = 0;
#warn "match failed new stack ".Dumper $stack;
		    }
                    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZHTML') {
		    my $focus = $kernel->call ( 'agent', 'focus_get' );
		    my $html  = $focus->as_HTML();
#warn "focussed html is $html";
		    my $url   = $htab->{response} && $htab->{response}->request->uri;

		    if (_matches ($a->pat, $html)) {
			$stack->{ip}++;                                                 # next statement
		    } else {
			$wvm->{proc}->{message} = "HTML content at '$url' does not match pattern";
			$stack->{frame} = $instr->error;
			$stack->{ip} = 0;
#warn "match failed new stack ".Dumper $stack;
		    }
                    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZText') {
		    my $focus = $kernel->call ( 'agent', 'focus_get' );
		    my $text  = $focus->as_text();
		    my $url   = $htab->{response} && $htab->{response}->request->uri;

		    if (_matches ($a->pat, $text)) {
			$stack->{ip}++;                                                 # next statement
		    } else {
			$wvm->{proc}->{message} = "Text content at '$url' does not match pattern";
			$stack->{frame} = $instr->error;
			$stack->{ip} = 0;
#warn "match failed new stack ".Dumper $stack;
		    }
                    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZElem') {
		    my $regexp;
		    if ($a->pat) {
			my $pat = $a->pat->pattern;
			$regexp = qr/$pat/;
		    }
		    my $url   = $htab->{response} && $htab->{response}->request->uri;
		    my $focus = $kernel->call ( 'agent', 'focus_set', $a->tag, $regexp, $a->ind, $url );
#warn "elem found focus $focus";
		    if ($focus) {
			$stack->{ip}++;                                                 # next statement
		    } else {
			$wvm->{proc}->{message} = "cannot find element '".$a->tag."'";
			$stack->{frame} = $instr->error;
			$stack->{ip} = 0;
		    }
                    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZFill') {
		    my $done = $kernel->call ( 'agent', 'focus_fill', $a->id, _value ($wvm->{proc}->{stacks},, $a->val) );
#warn "fill got done $done";
		    if ($done) {
			$stack->{ip}++;                                                 # next statement
		    } else {
			$wvm->{proc}->{message} = "cannot fill field '".$a->id."'";
			$stack->{frame} = $instr->error;
			$stack->{ip} = 0;
		    }
                    $kernel->yield ( 'director_proceed', $tab );

		} elsif (ref ($a) eq 'ZClick') {
		    my $focus = $kernel->call ( 'agent', 'focus_get' );
#warn "clicking get focus $focus";
		    if (ref ($focus) eq 'HTML::Form') {                    # focus is on form, submit that
			my $req = $focus->click ($a->name);
#warn "submitting form".Dumper $req->as_string;
			return $kernel->yield ( 'cycle_start', $tab, $req );
		    } elsif ($focus->tag eq 'a') {                         # must be a HTML::Tree node otherwise
#warn "anchor here";
			my $anchor  = $focus->as_HTML;
			$anchor     =~ /href="(.+?)"/is;
			use URI;
                        my $baseurl = $htab->{response} && $htab->{response}->request->uri;
			my $req     = HTTP::Request->new (GET => URI->new_abs ( $1, $baseurl ));
			return $kernel->yield ( 'cycle_start', $tab, $req );
		    } else {                                               # click on what?
			# ignore
		    }

		} else {
		    die "not handled action";
		}

	    } elsif (ref ($instr) eq 'WVMReset') {
		$kernel->call ( 'agent', 'focus_reset' );
		$stack->{ip}++;                                                    # next statement
		$kernel->yield ( 'director_proceed', $tab );

	    } elsif (ref ($instr) eq 'WVMTerm') {
#warn "normal termination";
		shift @{$wvm->{proc}->{stacks}};                       # effectively pop stack
#warn "popped stack";

		if (@{$wvm->{proc}->{stacks}}) {
		    $kernel->yield ( 'director_proceed', $tab );
		} else {                                               # no stack, we seem to be done
		    $director->{wvm} = undef;                          # get rid of machine, this indicates that we are not processing anything anymore
		}
		
	    } elsif (ref ($instr) eq 'WVMFatal') {
#warn "sending back exception" . $wvm->{proc}->{message};
		&{$director->{exception}} ($wvm->{proc}->{message});   # NOTE: we cannot simply die here, because POE does not clean up the session then
                                                                       # So, we pass into the Director a manual exception handler and anyone who does that
                                                                       # on the outside has the pleasure to check what should happen
		$director->{wvm} = undef;                              # get rid of machine, this indicates that we are not processing anything anymore

	    } else {
		die "unhandled instruction '".ref ($instr)."'";
	    }
	},
	'cycle_pos_response' => sub {
	    my ($kernel, $heap)  = (shift, shift);
	    my ($tab, $response) = (shift, shift);
	    $heap->{director}->{wvm}->{proc}->{message} = undef if $heap->{director}->{wvm};
	    return $response;
	},
	'cycle_neg_response' => sub {
	    my ($kernel, $heap)  = (shift, shift);
	    my ($tab, $response) = (shift, shift);
	    my $director = $heap->{director};
	    $director->{wvm}->{proc}->{message} = $response->status_line if $director->{wvm};
	    return $response;
	},
	'cycle_complete' => sub {
	    my ($kernel, $heap) = (shift, shift);
	    my ($tab)           = (shift);
#warn "dirctor cycle comlp";
	    my $director = $heap->{director};
	    my $wvm      = $director->{wvm};
	    return 1 unless $wvm;

	    my $stack    = $wvm->{proc}->{stacks}->[0];
	    my $instr    = $wvm->{frames}->{$stack->{frame}}->[$stack->{ip}];

	    if ($director->{wvm}->{proc}->{message}) {                              # if we encountered a problem
		$stack->{frame} = $instr->error;
		$stack->{ip} = 0;
	    } else {
		$stack->{ip}++;                                                     # next statement
# let's check whether there is a catcher for it
		my $htab  = $heap->{tabs}->{$tab};
		my $url   = $htab->{response} && $htab->{response}->request->uri;   # where are we at the moment?

		foreach (values %{$wvm->{catchers}}) {
		    my ($pat, $frame) = @$_;
#warn "checking pattern $pat for frame $frame , current $url";
		    if (_matches ($pat, $url)) { #@@@@
#warn "found one!";
			my $stack = { frame => $frame,
				      ip    => 0,
				      data  => {} };
			unshift @{$wvm->{proc}->{stacks}}, $stack;                          # effectively push stack
		    }
		}
            }
            $kernel->yield ( 'director_proceed', $tab );
	    return 1;
	},
    };

    $self->{namespace} = 'director';
    return $self;
}

sub _matches {
    my $p = shift;
    my $u = shift || '';

#warn " check against $u";
    my $pattern = 'm|'.$p->pattern.'|'.$p->modifier;
#warn "pattern $pattern";
    my $code = '$u =~ '.$pattern.' or die "current page does not match pattern ('.$pattern.')";';
#warn "code $code";
    eval $code;

    return ! $@;
}

sub _value {
    my $ss = shift;
    my $v  = shift;

#warn "asking for v ".Dumper ($v)." in stacks ".Dumper $ss;

    my $x = ref ($v) ? # it is a string
                      $$v : # or it is a variable
		      _lookup_var ($ss, $v);
#warn "returning $x";
    return $x;
}

sub _lookup_var {
    my $ss = shift;
    my $v  = shift;

    foreach my $s (@$ss) {
	if (defined $s->{data}->{$v}) {
	    return ref ($s->{data}->{$v}) ?                # a text string (is stored as reference
                      ${$s->{data}->{$v}}
	              : 
	              _lookup_var ($ss, $s->{data}->{$v}); # otherwise it is a variable
	}
    }
    die "undefined variable '$v'";
}



# WVM compiler: translates the syntax tree into a set of linearized code segments (called 'frames')

struct 'WVMTerm'     => [ ];                # indicates normal termination
struct 'WVMFatal'    => [ ];                # indicates abnormal termination
struct 'WVMInstr'    => [ action => '$',    # action to be executed
			  error  => '$' ];  # frame id to branch to on error
struct 'WVMChoice'   => [ choices => '@' ]; # random choice between the list members (which are frame ids)

struct 'WVMReset'    => [];                 # special instruction which resets focus

my $frame_gen = 0;

sub genL {
    return sprintf "%03d", $frame_gen++;
}

sub _compile_labels {
    my $wvm    = shift;
    my $labels = shift;
    my $start  = shift;
    my $end    = shift;
    my $error  = shift;

    _compile_steps  ($wvm, shift @$labels, $start, $end, $error);
    _compile_labels ($wvm, $labels,        genL(), $end, $error) if @$labels; # left
}

sub _compile_steps {
    my $wvm    = shift;
    my $steps  = shift;
    my $start  = shift;
    my $end    = shift;
    my $error  = shift;

#    warn Dumper $steps;
    my $l = @$steps > 1 ? genL() : $end;
    _compile_ors   ($wvm, shift @$steps, $start, $l,   $error);
    _compile_steps ($wvm, $steps,        $l,     $end, $error) if @$steps;
}

sub _compile_ors { # = a step
    my $wvm    = shift;
    my $ors    = shift;
    my $start  = shift;
    my $end    = shift;
    my $error  = shift;

#    warn Dumper $ors;
    my $l = @$ors > 1 ? genL() : $error;
    _compile_xors ($wvm, shift @$ors, $start, $end, $l);
    _compile_ors  ($wvm, $ors,        $l,     $end, $error) if @$ors;
}

sub _compile_xors {
    my $wvm    = shift;
    my $xors   = shift;
    my $start  = shift;
    my $end    = shift;
    my $error  = shift;

#    warn Dumper $xors;

    my @choices;
    foreach my $xor (@$xors) {
	my $l = genL();
	push @choices, $l;
	_compile_ands ($wvm, $xor, $l, $end, $error);
    }
    $wvm->{frames}->{$start} = [ WVMChoice->new (choices => \@choices) ];
}

sub _compile_ands {
    my $wvm    = shift;
    my $ands   = shift;
    my $start  = shift;
    my $end    = shift;
    my $error  = shift;

#    warn Dumper $ands;
    $wvm->{frames}->{$start} = [ WVMReset->new (), 
				 ( map { WVMInstr->new (action => $_, error => $error) } @$ands ), 
				 WVMChoice->new (choices => [ $end ]) ];
}

=pod

=head1 SEE ALSO

L<WWW::Agent>

=head1 AUTHOR

Robert Barta, E<lt>rho@bigpond.net.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION = '0.02';
our $REVISION = '$Id: Director.pm,v 1.2 2005/03/19 10:02:12 rho Exp $';

__END__



sub stalk {
    my $self = shift;
    _do_steps ($self->{cplan}->{labels}->{'__start'}, { self => $self, vars => [] });
}

sub _do_steps {
    my $ss = shift;
    my $c  = shift;

    foreach my $s (@$ss) { # all steps, one after the other
#warn "executing step ".Dumper $s;
	$c = _do_ors ($s, $c);
    }
    return $c;
}

sub _do_ors {
    my $os = shift;
    my $c  = shift;

    foreach my $o (@$os) { # all or clauses, if one fails, no worries, continue
#warn "exec or ".Dumper $o;
	eval {
	    $c = _do_xors ($o, $c);
	};
	return $c unless $@;
    }
    die $@;                # ok, everything is wrong (Moby), we escalate
}

sub _do_xors {
    my $xs = shift;
    my $c  = shift;

    my $r = int(rand (@$xs));
#warn "random $r from ". Dumper $xs;
    my $a = $xs->[$r];     # exactly one must do
#warn "going for ".Dumper $a;
    POE::Kernel->call ( 'agent', 'focus_reset' );
    $c = _do_ands ($a, $c);
    die "not satisfiable" unless $c;
    return $c;
}

sub _do_ands {
    my $as = shift;
    my $c  = shift;

    foreach my $a (@$as) { # all and clauses, no failure allowed
#warn "exec and ".Dumper $x;
        $c = _do_clause ($a, $c);
        die "not satisfiable" unless $c;
    }
    return $c;
}

sub _do_clause {
    my $a = shift;
    my $c = shift;

#warn "exec clause ".Dumper $a;

    if (ref ($a) eq 'ZDie') {
warn "before die";
	die _value ($c, $a->val);
	
    } elsif (ref ($a) eq 'ZWarn') {
	warn '# '. _value ($c, $a->val);

    } elsif (ref ($a) eq 'ZGoto') {
	my $request = HTTP::Request->new (GET => $a->url);
	my $object  = POE::Kernel->call ( 'agent', 'goto', $request);
	die $object unless ref ($object) eq 'HTTP::Response' and $object->is_success;

	# check for catchers
	my $url = POE::Kernel->call ( 'agent', 'history', 0);

	foreach (values %{$c->{self}->{cplan}->{catchers}}) {
	    my ($pat, $plan) = @$_;
#warn "checking pattern $pat";
	    $c = _do_steps ($plan, $c) if _matches ($pat, $url);
	}

    } elsif (ref ($a) eq 'ZURL') {
	my $url = POE::Kernel->call ( 'agent', 'history', 0);
	die $@ unless _matches ($a->regexp, $url);

    } elsif (ref ($a) eq 'ZHTML') {
	my $focus = POE::Kernel->call ( 'agent', 'focus_get' );
	my $html  = $focus->as_HTML();
	my $url   = POE::Kernel->call ( 'agent', 'history', 0 );
	die "HTML content at '$url' does not match pattern " unless _matches ($a->pat, $html);

    } elsif (ref ($a) eq 'ZText') {
	my $focus = POE::Kernel->call ( 'agent', 'focus_get' );
	my $text = $focus->as_text();
	my $url   = POE::Kernel->call ( 'agent', 'history', 0 );
	die "text content at '$url' does not match pattern " unless _matches ($a->pat, $text);

    } elsif (ref ($a) eq 'ZClick') {
	POE::Kernel->call ( 'agent', 'focus_activate', $a->name );

    } elsif (ref ($a) eq 'ZFill') {
	POE::Kernel->call ( 'agent', 'focus_fill', $a->id, _value ($c, $a->val) );

    } elsif (ref ($a) eq 'ZElem') {
	my $regexp;
	if ($a->pat) {
	    my $pat = $a->pat->pattern;
	    $regexp = qr/$pat/;
	}
	POE::Kernel->call ( 'agent', 'focus_set', $a->tag, $regexp, $a->ind ) or die "cannot find element '".$a->tag."'";

    } elsif (ref ($a) eq 'ZFunc') {
#warn "calling ".$a->name;
	my $focus = POE::Kernel->call ( 'agent', 'focus_get' );
	my $text = $focus->as_text();
	&{$c->{self}->{functions}->{$a->name}} ($text);

    } elsif (ref ($a) eq 'ZSub') {
#warn "sub exect plan ".$a->name. Dumper ($c->{self}->{cplan}->{labels}->{$a->name});
#warn "params ".Dumper $a->params;	
	
	push @{$c->{vars}}, $a->params;
	$c = _do_steps ($c->{self}->{cplan}->{labels}->{$a->name}, $c);
	pop @{$c->{vars}};

    } elsif (ref ($a) eq 'ZWait') {
	my $s;
	if ($a->dither) {
	    my $variance = $a->secs * $c->{self}->{time_dither} / 100.0;
#warn "variance $variance";
	    $s           = $a->secs - $variance + rand (2 * $variance);
	} else {
	    $s           = $a->secs;
	}

#warn "start sleeping $s";
	sleep $s;
#warn "stop sleeping";

    } else {
	die "unhandled clause '".ref ($a)."'";
    }
    return $c;
}

sub _value {
    my $c = shift;
    my $v = shift;

    return ref ($v) ? # it is a string
                      $$v : # or it is a variable
		      _lookup_var ($c, $v);
}

sub _lookup_var {
    my $c = shift;
    my $v = shift;

    foreach my $f (reverse @{$c->{vars}}) {
	if (defined $f->{$v}) {
	    return ref ($f->{$v}) ?                # a text string (is stored as reference
                      ${$f->{$v}}
	              : 
	              _lookup_var ($c, $f->{$v}); # otherwise it is a variable
	}
    }
    die "undefined variable '$v'";
}

