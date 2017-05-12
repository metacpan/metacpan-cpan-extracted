# $Id: Util.pm,v 1.15 2001-07-27 09:06:13-04 roderick Exp $
#
# Copyright (c) 1997-2000 Roderick Schertler.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;

package Sirc::Util;

=head1 NAME

Sirc::Util - Utility sirc functions

=head1 SYNOPSIS

    # sirc functions
    use Sirc::Util ':sirc';
    # overrides:
    addhelp $cmd, $usage_line, $rest;
    timer $delay, $code_string_or_ref, [$reference];

    # user messages
    arg_count_error undef, $want, [@arg];	# or 1st arg $name
    tell_error $msg;
    tell_question $msg;
    xtell $msg;

    # miscellaneous
    $pattern = ban_pattern $nick, $user, $host;
    $boolean = by_server [$who, $user, $host];
    eval_this $code, [@arg];
    eval_verbose $name, code$, [@arg];
    $boolean = have_ops $channel;
    $boolean = have_ops_q $channel;
    $boolean = ieq $a, $b;
    $re = mask_to_re $mask;
    $unused_timer = newtimer;
    optional_channel or return;
    $boolean = plausible_channel $channel;
    $boolean = plausible_nick $nick;
    $arg = xgetarg;
    $restricted = xrestrict;

    # /settables
    settable name, $var_ref, $setter_ref;
    settable_boolean $name, $var_ref, [$validate_ref];
    settable_int $name, $var_ref, [$validate_ref];
    settable_str $name, $var_ref, [$validate_ref];

    # hooks
    add_hook_type $name;
    add_hook $name, $code;
    run_hook $name, [@arg];

=head1 DESCRIPTION

This module provides a bunch of utility functions for B<sirc>.

It also allows you to import from it all of the standard sirc API
functions, so that you can more simply write your script as a module.

Nothing is exported by default.

=cut

use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS %Cmd $Debug %Hook);

use Exporter ();

# Supply dummy definitions for testing.
BEGIN {
    eval q{
    	sub main::addhelp	{ }
    	sub main::addhook	{ }
    	sub main::addset	{ }
    	sub main::docommand	{ }
    	sub main::tell		{ print @_, "\n" }
    } unless $::version || $::version;
}

# I need %EXPORT_TAGS in a BEGIN to get the list of symbols to import
# from main, so just set all the globals at compile time.

BEGIN {
    # This first line is for MakeMaker, it extracts the version for the
    # whole distribution from here.
    $VERSION = '0.12';
    $VERSION .= '-l' if 0;
    $::add_ons .= "+libsirc $VERSION"
	if !defined $::add_ons || $::add_ons !~ /\blibsirc\b/;

    # This is the real version for this file.
    $VERSION  = do{my@r=q$Revision: 1.15 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
    $VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

    @ISA	= qw(Exporter);
    @EXPORT_OK	= qw(
		     	arg_count_error tell_error tell_question xtell

			ban_pattern by_server eval_this eval_verbose have_ops
			have_ops_q ieq mask_to_re newtimer optional_channel
			plausible_channel plausible_nick xgetarg
			xrestrict

    	    	    	settable settable_boolean settable_int settable_str

		     	add_hook add_hook_type run_hook

		    );

=head1 STANDARD SIRC FUNCTIONS

You can import the standard SIRC API functions individually or, using
the tag B<:sirc>, as a group.  The available functions are:

=over

=item

accept addcmd addhelp addhook addset connect deltimer describe docommand
doset dosplat dostatus eq getarg getuserline getuserpass listen load me
msg newfh notice print remhook remsel resolve say sl tell timer userhost
yetonearg

=back

Some of these are actually enhanced versions of the routines that B<sirc>
provides, see below for information about them.

=cut

    %EXPORT_TAGS	= (
	'sirc'	=> [qw(accept addcmd addhelp addhook addset
			connect deltimer describe docommand doset dosplat
			dostatus eq getarg getuserline getuserpass listen
			load me msg newfh notice print remhook remsel
			resolve say sl tell timer userhost yetonearg)],
    );
    Exporter::export_ok_tags;

    $Debug = 0;
}

my $Old_w;
BEGIN { $Old_w = $^W; $^W = 1 }

# Import sirc's functions.
BEGIN {
    no strict 'refs';
    for my $fn (grep { $_ !~ /^(addcmd|addhelp|timer|userhost)$/ }
		    @{ $EXPORT_TAGS{'sirc'} }) {
	*$fn = \&{ "main::$fn" };
    }
}

use subs qw(tell_error xtell);

sub debug {
    xtell "debug " . join '', @_
	if $Debug;
}

#------------------------------------------------------------------------------

=head1 STANDARD MESSAGE FORMS

These functions provide for a few standard message forms which are shown
to the user via main::tell().

=over

=item B<arg_count_error> I<name>, I<want>, [I<arg>...]

This prints an error appropriate to an incorrect number of arguments.
I<name> is the name to report as having been invoked incorrectly.  If
it's C<undef> (which is the usual case) it's set to the caller's
function name.  I<want> is how many arguments were desired and the
remaining I<arg> arguments are the arguments which were actually
received.

=cut

sub arg_count_error {
    my ($fn, $want, @got) = @_;
    $fn = (caller 1)[3] if !defined $fn;
    tell_error "Wrong number of args to $fn, wanted $want got "
		. @got . ' (' . join(', ', @got) . ')';
}

=item B<tell_error> I<msg>

This formats I<msg> as an error message and passes it to main::tell.
It's appropriate for errors caused by the system or an invalid invocation
of your code.

=cut

#';

sub tell_error {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return;
    }
    main::tell("*\cbE\cb* $_[0]");
}

=item B<tell_question> I<msg>

This formats I<msg> as an error message for something the user did
wrong.  The message is passed to main::tell.

=cut

sub tell_question {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return;
    }
    main::tell("*\cb?\cb* $_[0]");
}

=item B<xtell> I<msg>

This is just C<main::tell "*** $msg">.

=cut

sub xtell {
    my $s = shift;
    main::tell("*** $s");
}

=back

=cut

#------------------------------------------------------------------------------

=head1 MISCELLANEOUS FUNCTIONS

These are some functions which don't fall nicely into groups like those
following do.

=over

=item B<addcmd> I<command>

This is an enhanced version of B<sirc>'s addcmd().  It lets you define
commands whose names contain non-alphanumeric characters.

=cut

sub addcmd {
    @_ == 1 || arg_count_error undef, '1', @_;
    my ($cmd) = @_;

    (my $qcmd = $cmd) =~ s/(['\\])/\\$1/g;
    my $ucmd = uc $cmd;
    $::cmds{$ucmd} = "\&{'cmd_$qcmd'}();";
    debug "command $cmd => $::cmds{$ucmd}";
}

=item B<addhelp> I<command>, I<help>

=item B<addhelp> I<command>, I<usage line>, I<rest>

This is an enhanced version of B<sirc>'s addhelp().  It arranges for the
new command to appear in the master help list.

Additionally, there's a new 3-arg syntax.  When called with 2 args it
uses the regular addhelp() command.  I hate the way this makes you
hardcode the standard form for help info, though, so I added the second
form.  This form takes the usage info which appears after the command
as its first arg, and the bulk of the help as its 3rd arg.

=cut

{ my (%seen_cmd, %seen_set);
sub addhelp {
    @_ == 2 || @_ == 3 || arg_count_error undef, '2 or 3', @_;
    my $cmd = shift @_;
    my $text = @_ == 1 ? shift : ("Usage: \cB\U$cmd\E\cB " . join "\n", @_);

    my ($rseen, $seen_tag, $targ, $intro);
    if ($cmd =~ /^set (.*)/) {
	$rseen	= \%seen_set;
	$seen_tag = uc $1;
	$targ	= '@set';
	$intro	= "List of non-builtin SET variables:";
    }
    else {
	$rseen	= \%seen_cmd;
	$seen_tag = uc $cmd;
	$targ	= '@main';
	$intro	= "List of non-builtin commands with help:";
    }

    if (@::help && !$rseen->{$seen_tag}++) {
	# The help info is stored as an array of lines, then they're
	# scanned when you use /help!  Entries are introduced with
	# "@name".

	my $state	= 0;
	my $i		= -1;
	my $first	= undef;
	my $len		= 0;

	for (@::help) {
	    $i++;
	    if ($state == 0) {
		$state = 1 if $_ eq $targ;
	    }
	    elsif ($state == 1) {
		if ($_ eq $intro) {
		    $first = $i;
		    $len = 1;
		    $state = 2;
		}
		elsif (/^@/) {
		    $first = $i;
		    $len = 0;
		    last;
		}
	    }
	    elsif ($state == 2) {
		if (/^@/) {
		    last;
		}
		else {
		    $len++;
		}
	    }
	}

	if (defined $first) {
	    # I found the help entry, $first and $len are the splice()
	    # indicators which for the part I've added to it.
	    local $_;
	    my @labels = sort keys %$rseen;
	    my $l = 0;		# max label length
	    for (@labels) {
		$l = length if length > $l;
	    }
	    $l += 2;		# spaces between
	    my $w = 80 - 4;	# XXX terminal width less wrap margin
	    my @out = ($intro, '');
	    while (@labels) {
		my $this = sprintf "%-${l}s", shift @labels;
		if (length($out[$#out]) + length($this) > $w) {
		    push @out, '';
		}
		$out[$#out] .= $this;
	    }
	    if ($out[$#out] eq '') {
		pop @out;
	    }
	    splice @::help, $first, $len, @out;
	}
    }

    return main::addhelp $cmd, $text;
} }

=item B<ban_pattern> I<nick>, I<user>, I<host>

This returns a pattern suitable for banning the given nick, user and host.

The current implementation is this:  Any nick is always matched.  If the
user has a ~ at the start (that is, it didn't come from identd) all user
names are matched, else just the one given matches.  If the host is an
IP address, it bans a class C sized chunk of IP space, otherwise
part of it is wildcarded (how much depends on how many parts it has).

For example:

    qw(Nick  user 1.2.3.4)		*!user@1.2.3.*
    qw(Nick ~user 1.2.3.4)		*!*@1.2.3.*
    qw(Nick  user host.foo.com)		*!user@*.foo.com
    qw(Nick ~user host.foo.com)		*!*@*.foo.com
    qw(Nick  user foo.com)		*!user@*foo.com
    qw(Nick ~user foo.com)		*!*@*foo.com

=cut

sub ban_pattern {
    debug "ban_pattern @_";
    unless (@_ == 3) {
    	arg_count_error undef, 1, @_;
    	return;
    }
    my ($n, $u, $h) = @_;

    $n = '*';
    $u =~ s/^~.*/*/;
    # 1.2.3.4 => 1.2.3.*
    if ($h =~ /^(\d+\.\d+\.\d+)\.\d+$/) {
	$h = "$1.*";
    }
    # foo.bar.baz => *.bar.baz
    elsif ($h =~ /^[^.]+\.(.+\..+)$/) {
    	$h = "*.$1";
    }
    # foo.bar => *foo.bar
    elsif ($h =~ /^[^.]+\.[^.]+$/) {
	$h = "*$h";
    }
    return "$n!$u\@$h";
}

=item by_server [I<who>, I<user>, I<host>]

If the given I<who>, I<user>, I<host> corresponds to a server rather
than a user, return the server name, else return undef.  If these aren't
specified the global $::who, $::user, and $::host are used, which is
what you usually want anyway.

=cut

sub by_server {
    unless (@_ == 0 || @_ == 3) {
	arg_count_error undef, '0 or 3', @_;
	return;
    }
    my ($n, $u, $h) = @_ ? @_ : ($::who, $::user, $::host);

    return $u eq '' ? $n : undef;
}

=item B<eval_this> I<code>, [I<arg>...]

This B<eval>s I<code> with I<arg> as arguments.  The I<code> can be
either a code reference or a string.  In either case the I<arg>s will be
available in @_.  The return value is whatever the I<code> returns.
$@ will be set if an exception was raised.

=cut

#';

sub eval_this {
    debug "eval_this @_";
    unless (@_ >= 1) {
	arg_count_error undef, '1 or more', @_;
	return;
    }
    my $code = shift;

    package main;
    no strict;
    return ref $code ? eval { $code->(@_) } : eval $code;
}

=item B<eval_verbose> I<name>, I<code>, [I<arg>...]

This is like B<eval_this> except that if an exception is raised it is
passed along to B<tell_error> (with a message indicating it's from
B<name>).

=cut

#';

sub eval_verbose {
    unless (@_ >= 2) {
	arg_count_error undef, '2 or more', @_;
	return;
    }
    my ($what, $code, @arg) = @_;

    eval_this $code, @arg;
    if ($@) {
	chomp $@;
	tell_error "Error running code for $what: $@";
	return 0;
    }
    return 1;
}

=item B<have_ops> I<channel>

This function returns true if you have ops on the specified channel.  If
you don\'t have ops it prints an error message and returns false.

=cut

sub have_ops {
    unless (@_ == 1) {
    	arg_count_error undef, 1, @_;
    	return;
    }
    my ($c) = @_;

    if (!$::haveops{lc $c}) {
	tell_question "You don't have ops on $c";
	return 0;
    }
    return 1;
}

=item B<have_ops_q> I<channel>

This is like B<have_ops> except that no message is printed, it just
returns true or false depending on whether you have ops on the specified
channel.

=cut

sub have_ops_q {
    unless (@_ == 1) {
    	arg_count_error undef, 1, @_;
    	return;
    }
    my ($c) = @_;

    return $::haveops{lc $c};
}

=item B<ieq> $a, $b

This sub returns true if its two args are eq, ignoring case.

=cut

sub ieq {
    unless (@_ == 2) {
    	arg_count_error undef, 2, @_;
    	return;
    }
    return lc($_[0]) eq lc($_[1]);
}

=item B<mask_to_re> I<glob>

Convert the given "mask" (an IRC-style glob pattern) to a regular
expression.  The only special characters in IRC masks are C<*> and
C<?> (there's no way to escape one of these).  The returned pattern
always matches case insensitively and is anchored at the front and
back (as IRC does it).

=cut

sub mask_to_re {
    unless (@_ == 1) {
    	arg_count_error undef, 1, @_;
    	return;
    }
    my ($s) = @_;

    $s = quotemeta $s;
    $s =~ s/\\\*/.*/g;
    $s =~ s/\\\?/./g;
    return "(?is)^$s\$";
}

=item B<optional_channel>

This sub examines $::args to see if the first word in it looks like a
channel.  If it doesn't then $::talkchannel is inserted there.  If there
was no channel present and you're not on a channel then an error message
is printed and false is returned, otherwise true is returned.

Here's a replacement for /names which runs /names for your current
channel if you don't provide any args.

    sub main::cmd_names {
	optional_channel or return;
	docommand "/names $::args";
    }
    addcmd 'names';

=cut

sub optional_channel {
    unless (@_ == 0) {
    	arg_count_error undef, 0, @_;
    	$::args = "#invalid-optional_channel-invocation $::args";
    	return;
    }
    my $ret = 1;
    if ($::args !~ /^[\#&]/) {
	if (!$::talkchannel) {
	    tell_question "Not on a channel";
	    $ret = 0;
	}
	$::args = ($::talkchannel || '#not-on-a-channel') . " $::args";
    }
    return $ret;
}

=item B<newtimer>

Return an unused timer number.

=cut

sub newtimer {
    unless (@_ == 0) {
	arg_count_error undef, 1, @_;
	return;
    }

    while (1) {
	my $n = 1 + int rand 2**31;
	return $n unless grep { $_ == $n } @::trefs;
    }
}

=item B<plausible_channel> I<channel>

This returns true if I<channel> is syntactically valid as a channel
name.

=cut

sub plausible_channel {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return;
    }
    my ($c) = @_;
    return $c =~ /^[\#&][^ \a\0\012\015,]+$/;
}

=item B<plausible_nick> I<nick>

This returns true if I<nick> is syntactically valid as a nick name.
Originally I used the RFC 1459 definition here, but that turns out to be
no longer valid.  I don't know what definition modern IRC servers are
using.  This sub allows characters in the range [!-~].

=cut

#';

sub plausible_nick {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return;
    }
    my ($n) = @_;
    #return $n =~ /^[a-z][a-z0-9\-\[\]\\\`^{}]*$/i;
    return $n =~ /^[!-~]+$/;
}

=item B<timer> @args

This is an enhanced version of B<sirc>'s timer().  It allows you to use
a code reference as the code arg.

=cut

#';

my $timer_name = 'timersub000';

sub timer {
    my @arg = @_;

    if (@arg > 1 && ref $arg[1]) {
	# The strategy here is to give a name to the code reference
	# and then call it via that name.  After calling it the glob
	# containing the name is deleted to free memory.  (You can't
	# just undef the &sub because that would leave the glob and CV
	# in existance.)
	no strict 'refs';
	$timer_name++;
	my $pkg = __PACKAGE__;
	*{ "${pkg}::$timer_name" } = $arg[1];
	$arg[1] = qq{${pkg}::$timer_name(); delete \$${pkg}::{"$timer_name"}};
    }
    return main::timer(@arg);
}

# Hack:  Chantrack overrides userhost, so I have to call through here.
# If I assign to *userhost at compile time I'll retain a reference to
# the original sub.

sub userhost {
    goto &main::userhost;
}

=item B<xgetarg>

This is like main::getarg, but it returns the new argument (in addition
to setting $::newarg).

=cut

sub xgetarg {
    getarg;
    return $::newarg;
}

=item B<xrestrict>

This just returns $::restrict.

=cut

sub xrestrict {
    return $::restrict;
}

=back

=cut

#------------------------------------------------------------------------------

=head1 /SET COMMANDS

These commands provide a simplified interface to adding /set variables.

=over

=item B<settable> I<name>, I<var-ref>, I<setter-ref>

This sub adds a user-settable option.  I<name> is its name, I<var-ref>
is a reference to the place it will be stored, and I<setter-ref> is a
reference to code to validate and save new values.  The code will be
called as C<$rsetter->($rvar, $name, $value)>.  $name will be in upper
case.  The code needs to set both $$rvar and $::set{$name}.  (The values
in %set are user-visible.)

=cut

sub settable {
    my ($name, $rvar, $rsetter) = @_;
    my $subname = "main::set_$name";
    my $uname = uc $name;
    my $closure = sub {
	my $val = shift;
	$rsetter->($rvar, $uname, $val);
    };
    {
	no strict 'refs';
	*$subname = $closure;
    }
    # XXX 2nd arg is ignored
    addset $name, $name;
}

=item B<settable_boolean> I<name>, I<var-ref>, [I<validate-ref>]

This adds a /settable boolean called I<name>.  I<var-ref> is a reference
to the scalar which will store the value.

I<validate-ref>, if provided, will be called to validate a new value is
legal.  It will receive both the I<name> and the new value (as a boolean,
not as the user typed it) as arguments.  It should return a boolean to
indicate whether the value is okay.

=cut

sub settable_boolean {
    my ($name, $rvar, $rvalidate) = @_;
    my $closure = sub {
	my ($rvar, $name, $val) = @_;
	my $new = $$rvar;
	my $lval = lc $val;
	if ($lval eq 'on') {
	    $new = 1;
	}
	elsif ($lval eq 'off') {
	    $new = 0;
	}
	elsif ($lval eq 'toggle') {
	    $new = !$new;
	}
	elsif ($lval eq 'nil') {
	    # do nothing, for initial set
	}
	else {
	    tell_question "Invalid value `$val' for $name";
	    return;
	}
	if ($rvalidate && !$rvalidate->($name, $new)) {
	    tell_question "Invalid value `$val' for $name";
	    return;
	}
	$$rvar = $new;
	$::set{$name} = $$rvar ? 'on' : 'off';
    };
    settable $name, $rvar, $closure;
    $::set{uc $name} = $$rvar ? 'on' : 'off';
}

=item B<settable_int> I<name>, I<var-ref>, [I<validate-ref>]

This function adds a /settable integer called I<name>.  I<var-ref> is a
reference to the scalar which will store the value.

I<validate-ref>, if provided, will be called to validate a new
value is legal.  It will receive both the I<name> and the new value as
arguments.  Before it is called the new value will have been vetted for
number-hood.  It should return a boolean to indicate whether the value
is okay.

=cut

sub settable_int {
    my ($name, $rvar, $rvalidate) = @_;
    my $closure = sub {
	my ($rvar, $name, $val) = @_;
	if (!defined $val) {
	    tell_question "Can't set $name to undefined value";
	}
	elsif ($val !~ /^-?\d+$/
		|| ($rvalidate && !$rvalidate->($name, $val))) {
	    tell_question "Invalid value `$val' for $name";
	}
	else {
	    $$rvar = $::set{$name} = $val;
	}
    };
    settable $name, $rvar, $closure;
    $$rvar ||= 0;	# must be defined for /set to work
    $::set{uc $name} = $$rvar;
}

=item B<settable_str> I<name>, I<var-ref>, [I<validate-ref>]

This function adds a /settable called I<name>.  I<var-ref> is a reference
to the scalar which will store the value.

I<validate-ref>, if provided, will be called to validate the a new
value is legal.  It will receive both the I<name> and the new value as
arguments.  It should return a boolean to indicate whether the value is
okay.

=cut

sub settable_str {
    my ($name, $rvar, $rvalidate) = @_;
    my $closure = sub {
	my ($rvar, $name, $val) = @_;
	if (!defined $val) {
	    tell_question "Can't set $name to undefined value";
	}
	elsif ($rvalidate && !$rvalidate->($name, $val)) {
	    tell_question "Invalid value `$val' for $name";
	}
	else {
	    $$rvar = $::set{$name} = $val;
	}
    };
    settable $name, $rvar, $closure;
    $$rvar ||= '';	# must be defined for /set to work
    $::set{uc $name} = $$rvar;
}

=back

=cut

#------------------------------------------------------------------------------

#=head1 CHAINED COMMANDS
#
#=over
#
#=cut
#
#sub chain_cmd_runner {
#    my $type = shift;
#    for my $code (@{ $Cmd{$type} }) {
#	if (ref $code) {
#	    eval { &$code };
#	}
#	else {
#	    eval $code;
#	}
#	die if $@;
#    }
#}
#
#sub chain_cmd {
#    my ($type, $new) = @_;
#    $type = lc $type;
#    my $old = $main::cmds{$type};
#    my $cmd = "chain_cmd_runner '$type'";
#    if ($old && $old ne $cmd) {
#	push @{ $Cmd{$type} }, $old;
#	$main::cmds{$type} = $cmd;
#    }
#    push @{ $Cmd{$type} }, $new;
#}
#
#=back
#
#=cut

#------------------------------------------------------------------------------

=head1 HOOKS

Sirc::Util provides functionality for creating, adding code to and
running hooks.

=over

=item B<add_hook_type> I<name>

This creates a new hook called I<name>.

=cut

sub add_hook_type {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return;
    }
    my ($hook) = @_;

    if (exists $Hook{$hook}) {
	tell_error "add_hook_type: Hook $hook already exists";
	return;
    }
    $Hook{$hook} = [];
}


=item B<add_hook> I<name>, I<code>

Add I<code> to the I<name> hook.  The I<name> must already have been
created with add_hook_type().  The I<code> can be either a string or a
code reference.

=cut

sub add_hook {
    unless (@_ == 2) {
	arg_count_error undef, 2, @_;
	return;
    }
    my ($hook, $code) = @_;

    if (!exists $Hook{$hook}) {
	tell_error "add_hook: Invalid hook `$hook'";
	return;
    }
    push @{ $Hook{$hook} }, $code;
}

=item B<run_hook> I<name>, [I<arg>...]

Run the I<name> hook, passing the I<arg>s to each hook member via @_.

=cut

sub run_hook {
    unless (@_ >= 1) {
	arg_count_error undef, '1 or more', @_;
	return;
    }
    my ($hook, @arg) = @_;

    if (!exists $Hook{$hook}) {
	tell_error "run_hook: Invalid hook `$hook'";
	return;
    }
    for my $code (@{ $Hook{$hook} }) {
	eval_verbose "$hook hook", $code, @arg;
    }
}

=back

=cut

#------------------------------------------------------------------------------

BEGIN { $^W = $Old_w }

1;

=head1 AVAILABILITY

Check CPAN or http://www.argon.org/~roderick/ for the latest version.

=head1 AUTHOR

Roderick Schertler <F<roderick@argon.org>>

=head1 SEE ALSO

sirc(1), perl(1), Sirc::Chantrack(3pm).

=cut
