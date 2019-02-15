#!/usr/bin/env perl
# XML::Axk::L::L1 - axk language, version 1
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

# TODO:
# - Add a way to mark that a node should be kept in the DOM, even if running
#   in SAX mode (`stash`?)
# - Add a way to re-use the last pattern (`ditto`?)
# - Add a static method to XAC to get the next package name, so that each
#   `axk_script_*` is used by only one Core instance.

package XML::Axk::L::L1;
use XML::Axk::Base qw(:default now_names);

use XML::Axk::Matcher::XPath;
use XML::Axk::Matcher::Always;
use HTML::Selector::XPath qw(selector_to_xpath);

use Scalar::Util qw(reftype);

# Packages we invoke by hand
require XML::Axk::Language;
require Exporter;

# Names the axk script will have access to
our @EXPORT = qw(
    pre_all pre_file post_file post_all perform
    always never xpath sel on run entering leaving whenever);
our @EXPORT_OK = qw( @SP_names );

# Config
our $C_WANT_TEXT = 0;

# Helpers ======================================================== {{{1

# Accessor
sub _sandbox {
    my $home = caller(1);
    no strict 'refs';
    return ${"${home}::_AxkSandbox"};
} #_sandbox()

# }}}1
# Definers for special actions==================================== {{{1

sub pre_all :prototype(&) {
    my $sandbox = _sandbox or croak("Can't find sandbox in pre_all");
    #say "core: " . Dumper($sandbox);
    #say Dumper($sandbox->{pre_all});
    #say Dumper(@{$sandbox->{pre_all}});
    push @{$sandbox->pre_all}, shift;
} #pre_all()

sub pre_file :prototype(&) {
    my $sandbox = _sandbox or croak("Can't find sandbox in pre_file");
    push @{$sandbox->pre_file}, shift;
} #pre_file()

sub post_file :prototype(&) {
    my $sandbox = _sandbox or croak("Can't find sandbox in post_file");
    push @{$sandbox->post_file}, shift;
} #post_file()

sub post_all :prototype(&) {
    my $sandbox = _sandbox or croak("Can't find sandbox in post_all");
    push @{$sandbox->post_all}, shift;
} #post_all()

# }}}1
# Definers for node actions ====================================== {{{1

## @function private add_to_worklist (&action, matcher[, when])
## The main way to define pattern/action pairs.  This takes the action first
## since that's how Perl's prototypes are set up the cleanest (block first).
## @params required &action     A block to execute when the pattern matches
## @params required matcher     An object that defines test(%CPs) to determine
##                              whether the element described in
##                              core-parameter hash %CPs matches.
## @params optional when        If provided, when to run the action:
##                              HI, BYE, or CIAO.  Default is BYE.
sub add_to_worklist {
    my $sandbox = _sandbox or croak "Can't find sandbox";
    my ($drAction, $refPattern, $when) = @_;

    $when = $when // BYE;   # only on exit, by default
    $refPattern = \( my $temp = $refPattern ) unless ref($refPattern);

    push @{$sandbox->worklist}, [$refPattern, $drAction, $when];
} #add_to_worklist()

# User-facing alias for add_to_worklist
sub perform :prototype(&@) {
    goto &add_to_worklist;  # Need goto so that _sandbox() can use caller(1)
}

# run { action } [optional <when>] - syntactic sugar for `sub {}, when`
sub run :prototype(&;$) {
    return @_;
} #run()

# pattern-first style - on {} run {} [when];
# The default [when] is BYE so that the text content of the node is
# available --- at HI, all you have are the attributes.
sub on :prototype(&@) {
    my ($drMakeMatcher, $drAction, $when) = @_;

    my $matcher = &$drMakeMatcher;
    @_=($drAction, $matcher, $when);
    goto &add_to_worklist;
} # on()

# pattern-first style, sugar for symmetry with whenever() and entering()
sub leaving :prototype(&@) {
    goto &on
} #entering()

# pattern-first style, common implementation for HI and CIAO
sub _entering_whenever_impl {
    croak "Too many arguments" if $#_>2;
    my ($when, $drMakeMatcher, $drAction) = @_;
    my $matcher = &$drMakeMatcher;
    @_=($drAction, $matcher, $when);
    goto &add_to_worklist;
} #_leaving_whenever_impl()

# pattern-first style, specific to entering nodes (HI) - entering {} run {};
sub entering :prototype(&@) {
    unshift @_, HI;
    goto &_entering_whenever_impl;
} # leaving()

# pattern-first style, specific to hitting nodes (CIAO) - whenever {} run {};
sub whenever :prototype(&@) {
    unshift @_, CIAO;
    goto &_entering_whenever_impl;
} # whenever()

# }}}1
# Definers for matchers ========================================== {{{1

# TODO define subs to tag various things as, e.g., selectors, xpath,
# attributes, namespaces, ... .  This is essentially a DSL for all the ways
# you can write a pattern

# Always match
sub always :prototype() {
    return XML::Axk::Matcher::Always->new();
} #always()

# Never match - for easily turning off a particular clause
sub never :prototype() {
    return XML::Axk::Matcher::Always->new(always => false);
} #never()

# Make an XPath matcher
sub xpath {
    my $path = shift or croak("No expression provided!");
    $path = $$path if ref $path;

    my (undef, $filename, $line) = caller;
    my $matcher = XML::Axk::Matcher::XPath->new(
        xpath => $path,
        file=>$filename, line=>$line,
    );
    return $matcher;
} #xpath()

# Make a selector matcher
sub sel {
    my $path = shift or croak("No expression provided!");
    $path = $$path if ref $path;

    my $xp = selector_to_xpath $path;
    my (undef, $filename, $line) = caller;
    my $matcher = XML::Axk::Matcher::XPath->new(
        xpath => $xp, type => 'selector',
        file=>$filename, line=>$line,
    );
    return $matcher;
} #sel()

# }}}1

# Script parameters ============================================== {{{1

# Script-parameter names
our @SP_names = qw($D $E $NOW);

sub update {
    #say "L1::update: ", Dumper(\@_);
    my $hrSP = shift or croak("Invalid call - No hrSP");
    my %CPs = @_;

    $hrSP->{'$D'} = $CPs{document} or croak("No document");
    $hrSP->{'$E'} = $CPs{record} or croak("No record");
    croak("You are in a timeless maze") unless defined $CPs{NOW};
    $hrSP->{'$NOW'} = now_names $CPs{NOW};
} #update()

# }}}1

# Import ========================================================= {{{1

sub import {
    #say "update: ",ref \&update, Dumper(\&update);
    #say "XAL1 run from $target:\n", Devel::StackTrace->new->as_string;
    XML::Axk::Language->import(
        target => caller,
        sp => \@SP_names,
        updater => \&update
    );
        # By doing this here rather than in the `use` statement,
        # we get `caller` and don't have to walk the stack to find the
        # axk script.
    goto &Exporter::import;     # for @EXPORT &c.  @_ is what it was on entry.
} #import()

#}}}1
1;
# === Documentation ===================================================== {{{1

=pod

=encoding UTF-8

=head1 NAME

XML::Axk::Core::L1 - awk-like XML processor, language 1

=head1 EXAMPLE

    L1
    on { xpath(q<//item>) } run {say "$NOW: " . $E->getTagName}, CIAO
        # "CIAO" can also be "HI" or "BYE" (default BYE).
        # "leaving" is a synonym for "on" with no HI/BYE/CIAO.
    whenever { xpath(q<//item>) } run {say "$NOW: " . $E->getTagName};
        # the same as the "on ... CIAO" line
    entering { xpath(q<//item>) } run {say "$NOW: " . $E->getTagName};

=head1 PATTERNS AND ACTIONS

=over

=item * C<< on {<matcher>} run {<action>} [, <when>] >>

Whenever C<< <matcher> >> says that a node matches, run C<< <action> >>.
The optional C<< <when> >> parameter says when in the course of processing to
run C<< <action> >>:

=over

=item C<HI>

When the node is first reached, before any of its children are processed

=item C<BYE>

After all of the node's children have been processed.  This is the default
so that you have the text content of the node available for inspection.

=item C<CIAO>

Both C<HI> and C<BYE>.  Suggestions for alternative terminology are welcome.

=back

=item * C<entering>, C<whenever> C<leaving>

    entering {<matcher>} run {<action>}
    whenever {<matcher>} run {<action>}
    leaving {<matcher>} run {<action>}

The same as C<on {} run {}>, with C<when> set to C<HI>, C<CIAO>, or C<BYE>
respectively.

=item * C<< perform { <action> } <matcher> [, <when>] >>

If you prefer RPN, or you want to save some characters, you can put the
C<< <matcher> >> after the C<< <action> >> using C<perform>.  For example,
the following two lines have exactly the same effect:

    on { xpath(q<//item>) } run {say "$NOW: " . $E->getTagName}, CIAO
    perform {say "$NOW: " . $E->getTagName} xpath(q<//item>), CIAO

=back

=head1 VARIABLES

When an C<< <action> >> is running, it has access to predefined variables
that hold the state of the element being matched.  This is similar to C<$0>,
C<$1>, ... in awk.

At present, L1 uses L<XML::DOM>.

=over

=item B<$D>

The current XML document (L<XML::DOM::Document>)

=item B<$E>

The XML element that was matched (L<XML::DOM::Element>)

=item B<$NOW>

The current phase, as a human-readable string: C<entering> for C<HI>,
C<leaving> for C<BYE>, and C<both> for C<CIAO>.

=back

=head1 MATCHERS

=over

=item * C<< xpath('xpath expression') >>

Match nodes that match the given XPath expression.  Remember that Perl will
interpolate C<@name> in double-quotes, so single-quote or C<q{}> your XPath
expressions.

=item * C<< sel('selector') >>

Match nodes that match the given selector.

=item * C<always>, C<never>

Always or never match, respectively.

=back

=head1 SPECIAL ACTIONS

=over

=item * C<< pre_all {<block>} >>

Run C<< <block> >> before any file is processed.

=item * C<< pre_file {<block>} >>

Run C<< <block>($filename) >> before each file is processed.

=item * C<< post_file {<block>} >>

Run C<< <block>($filename) >> after each file is processed.

=item * C<< post_all {<block>} >>

Run C<< <block> >> after all files have been processed.

=back

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 CONTACT

For any bug reports, feature requests, or questions, please see the
information in L<XML::Axk>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}1
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker: #
