package Text::Nunjucks::Runtime::Regex;
# ABSTRACT: A template regex literal, with the members of a JS RegExp (ADR 0013)

our $VERSION = '0.001';

use Moo;
use overload
  '""'   => \&_stringify,
  'bool' => sub { 1 },
  fallback => 1;
use Text::Nunjucks::Lib;
use Text::Nunjucks::Runtime;
use namespace::autoclean;

# Regex -- template regex literal (ADR 0013), a port addition to runtime.js at
# its ADR-designated home beside Text::Nunjucks::Runtime (whose ->Regex names
# this class).
#
# A template `/.../flags` becomes a blessed Regex object with the members
# templates read on a JS RegExp (source, flags, global) and call (test, exec).
# The attributes are the JS ones verbatim (source, flags) -- per the k43
# discipline, `flags` is a Moo attribute (auto-generated accessor), NEVER a
# hand-rolled `sub flags` (the previous half-attempt collided with Moo's reader
# and made the whole class unloadable; the rewrite is fresh, not patched).

has source       => ( is => 'ro', required => 1 );
has flags        => ( is => 'ro', required => 1 );
has _qr          => ( is => 'ro', required => 1 );
# _qr_anchored is the same pattern with a leading \G so it can only match at
# the string's current pos(). ADR 0013 requires JS /y (sticky) to behave that
# way: match anchored at lastIndex, advance lastIndex past the match on
# success, reset to 0 on failure. Built unconditionally; test/exec pick which
# one to use from the g/y flags.
has _qr_anchored => ( is => 'ro', required => 1 );
# _captures_count is the number of native (numbered or named) capture groups
# in the JS regex body. Cached at construction time (k48) so exec can detect
# the no-groups case -- Perl 5.40's list-context `=~` returns the boolean
# match result instead of an empty list when the qr// has no groups, which
# the JS RegExp.prototype.exec contract never produces. Zero means: drop the
# boolean before assembling the [full, ...captures] array.
has _captures_count => ( is => 'ro', required => 1 );
# _group_names is every group name of the JS regex body in source order, each
# once (a duplicate name keeps its first place), cached at construction like
# _captures_count. Perl's %+ / %- carry no order, but JS builds a match's
# groups object in group order (oracle: 'ab' with r/(?<z>a)(?<b>b)/ iterates
# z, then b), so the engine-built groups object is filled from this list.
has _group_names => ( is => 'ro', required => 1 );
# lastIndex is the JS RegExp's mutable match position. JS resets it on every
# successful match (g/y) and on every failed match (g/y); for non-g/non-y
# regexes it is left alone. The current value is template-visible
# ({{ r.lastIndex }}).
has lastIndex    => ( is => 'rw', default => 0 );

# JS RegExp.global: true iff the g flag was set. Templates read it as a
# property ({{ r.global }}); the g flag is also tracked separately on the
# object so test/exec honour it (a Perl qr// is single-match by default).
# Returns a Perl boolean (!!1 / !!0) so Runtime::_js_to_string routes it
# through the is_bool branch and renders "true" / "false", matching
# RegExp.prototype.global's JS boolean.
sub global {
  my ($self) = @_;
  return ( index( $self->flags, 'g' ) >= 0 ) ? !!1 : !!0;
}

# True iff the y (sticky) flag is set. Tracked as a separate predicate so
# test/exec don't re-scan flags on every call.
sub _is_sticky {
  my ($self) = @_;
  return index( $self->flags, 'y' ) >= 0 ? 1 : 0;
}

# RegExp.prototype.test -- ADR 0013 g/y semantics:
#   * y (sticky): match anchored at lastIndex via the \G-prefixed qr//. On
#     success, advance lastIndex by the match length. On failure, reset to 0.
#   * g (global, not y): match starting from lastIndex (set pos($str) before
#     matching). On success, advance lastIndex by the match length. On
#     failure, reset to 0.
#   * neither: stateless match; lastIndex is left alone (JS does not touch
#     it for non-g/non-y regexes -- oracle-checked).
# Returns a Perl boolean (!!1/!!0) so _js_to_string renders "true"/"false".
#
# Perl implementation note: pos() only advances on m//g matches (perldoc
# perlvar). The qr// we hold has no /g, so a plain `$str =~ $self->_qr`
# updates neither pos nor lastIndex. The stateful probe is therefore
# written as `$str =~ /$qr/g`, which interpolates the qr object and
# applies /g, advancing pos past the found match. The original k46 v1
# mistakenly used `=~ $self->_qr` and silently never advanced lastIndex.
#
# CAVEAT: $self overloads "" to render /source/flags (RegExp.prototype.
# toString). Interpolation of the qr through a method call (e.g.
# /$self->_qr/g) forces stringification of the qr and Perl sees a junk
# pattern like `/x/y->_qr`. Cache the qr in a local first.
sub test {
  my ( $self, $str ) = @_;
  $str = defined($str) ? "$str" : '';
  my $sticky = $self->_is_sticky;
  my $global = index( $self->flags, 'g' ) >= 0;

  if ($sticky) {
    my $qr_a = $self->_qr_anchored;
    my $start = $self->lastIndex;
    pos($str) = $start;
    if ( $str =~ /$qr_a/g ) {
      $self->lastIndex( pos($str) );
      return !!1;
    }
    $self->lastIndex(0);
    return !!0;
  }
  if ($global) {
    my $qr = $self->_qr;
    my $start = $self->lastIndex;
    pos($str) = $start;
    if ( $str =~ /$qr/g ) {
      $self->lastIndex( pos($str) );
      return !!1;
    }
    $self->lastIndex(0);
    return !!0;
  }
  return ( $str =~ $self->_qr ) ? !!1 : !!0;
}

# RegExp.prototype.exec -- same g/y semantics as test. Returns an Array of
# [full match, cap1, cap2, ...] (JS renders as 'a,b,c' via toString; that
# is what `{{ r/(.)(.).exec('ab') }}` wants). On no-match returns null
# (undef, which the engine renders as empty). The Perl qr// match in list
# context returns only the capture groups; we prepend $& (the full match)
# so the array matches RegExp.prototype.exec's shape.
#
# k48: when the pattern has no capture groups, Perl 5.40's list-context
# match returns the boolean match result (builtin::true / builtin::false)
# instead of an empty list. JS never does that. _captures_count == 0
# means drop the boolean from @captures before assembling the result.
#
# Implementation note: pos() is only honoured as a START position by
# m//g matches (perldoc perlop). So a plain list-context `$str =~ $qr`
# silently ignores pos() and always re-finds the first match from offset
# 0, breaking global/sticky iteration. Compounded: list-context
# `$str =~ /$qr/g` iterates ALL matches and returns ALL captures (perldoc
# perlop), not the captures from one anchored match. Two failure modes
# need two different probes:
#
# * Sticky (y): the prebuilt _qr_anchored pattern starts with \G, which
#   only matches at pos(). A non-/g list-context match against that
#   pattern is therefore pos-anchored; on success it returns the captures
#   from the one match starting at pos, with no skip-ahead. New lastIndex
#   is start + length of full match.
# * Global (g, no y): we cannot use a \G-anchored pattern (global skips
#   forward to the next match, sticky does not). Run the qr in scalar
#   /g context (which DOES honour pos as start AND advances it past the
#   found match, skipping non-matches); then substring the matched
#   region and run a fresh non-/g list-context match on it to grab the
#   captures. The slice is short (one match's width) so the cost is
#   bounded.
#
# CAVEAT (same as test above): Regex overloads "" to render /source/flags,
# so `$self->_qr` interpolates as a string. Cache in a local first.
sub exec {
  my ( $self, $str ) = @_;
  $str = defined($str) ? "$str" : '';
  my $sticky = $self->_is_sticky;
  my $global = index( $self->flags, 'g' ) >= 0;
  my $no_caps = $self->_captures_count == 0;

  if ($sticky) {
    my $qr_a  = $self->_qr_anchored;
    my $start = $self->lastIndex;
    pos($str) = $start;
    my @captures = $str =~ $qr_a;   # non-/g; \G anchors at pos
    if (@captures) {
      @captures = () if $no_caps;   # k48: drop the bool for no-groups patterns
      $self->lastIndex( $start + length($&) );
      return [ $&, @captures ];
    }
    $self->lastIndex(0);
    return undef;
  }
  if ($global) {
    my $qr     = $self->_qr;
    my $start  = $self->lastIndex;
    pos($str)  = $start;
    if ( $str =~ /$qr/g ) {         # scalar /g: honours pos, advances it
      my $full = $&;
      my $end  = pos($str);
      # Slice the matched region; non-/g list-context match returns
      # exactly the captures from this one match.
      my @captures = substr( $str, $start, $end - $start ) =~ $qr;
      @captures = () if $no_caps;   # k48: drop the bool for no-groups patterns
      $self->lastIndex($end);
      return [ $full, @captures ];
    }
    $self->lastIndex(0);
    return undef;
  }
  my @captures = $str =~ $self->_qr;
  return undef unless @captures;
  @captures = () if $no_caps;       # k48: drop the bool for no-groups patterns
  return [ $&, @captures ];
}

# k48: the capture groups of a JS regex body, in source order: one entry per
# group, its name for a named group, undef for a numbered one (the count is
# the array's size). ECMAScript regex syntax:
# `(` starts a group; `(?:` / `(?=` / `(?!` / `(?<=` / `(?<!` / `(?#` are
# non-capturing / zero-width / comment forms; `(?<NAME>` is a NAMED
# capture group (counts); everything else is a numbered capture group.
# Backslash escapes any following byte; `[...]` is a character class
# where parens are literals. Walk the body byte-by-byte (the JS body is
# ASCII for every pattern in the corpus; UTF-8 non-ASCII literals would
# still walk correctly because substr/skip is over bytes, not codepoints).
sub _capture_groups {
  my ( $self, $body ) = @_;
  my @groups;
  my $i        = 0;
  my $len      = length $body;
  my $in_class = 0;
  while ( $i < $len ) {
    my $c = substr( $body, $i, 1 );
    if ( $c eq '\\' ) {                                # escape: skip 2 bytes
      $i += 2;
      next;
    }
    if ($in_class) {                                   # inside [...] -- parens literal
      $in_class = 0 if $c eq ']';
      $i++;
      next;
    }
    if ( $c eq '[' ) {
      $in_class = 1;
      $i++;
      next;
    }
    if ( $c eq '(' && $i + 1 < $len && substr( $body, $i + 1, 1 ) eq '?' ) {
      my $after = $i + 2 < $len ? substr( $body, $i + 2, 1 ) : '';
      if ( $after eq ':' || $after eq '=' || $after eq '!' || $after eq '#' ) {
        # (?:  (?=  (?!  (?# -- non-capturing / zero-width / comment
      }
      elsif ( $after eq '<' ) {
        my $after_lt = $i + 3 < $len ? substr( $body, $i + 3, 1 ) : '';
        if ( $after_lt ne '=' && $after_lt ne '!' ) {
          # (?<NAME> -- named capture; the name runs to the next '>' (the
          # pattern already compiled, so there is one)
          my $gt = index( $body, '>', $i + 3 );
          push @groups, substr( $body, $i + 3, $gt - ( $i + 3 ) );
        }
        # (?<= / (?<! -- lookbehind, non-capturing
      }
      else {
        push @groups, undef;       # (?xyz -- invalid ECMAScript; count defensively
      }
    }
    elsif ( $c eq '(' ) {
      push @groups, undef;         # plain ( ... ) -- numbered capture
    }
    $i++;
  }
  return \@groups;
}

# Stringification: `/source/flags` -- matches RegExp.prototype.toString so
# `{{ r/x/i }}` renders the right thing (oracle proves it: rendering
# `{{ r/name [0-9] \\// }}` produces `/name [0-9] \\//`).
sub _stringify {
  my ($self) = @_;
  return '/' . $self->source . '/' . $self->flags;
}

sub to_string { return '/' . $_[0]->source . '/' . $_[0]->flags }

sub _runtime { 'Text::Nunjucks::Runtime' }
sub _lib     { 'Text::Nunjucks::Lib' }

# RegExp.prototype[Symbol.replace](string, replaceValue) -- what
# String.prototype.replace runs for a regex pattern, so the replace filter's
# regex branch (str.replace(old, new_)) lands here (ADR 0013). A coderef
# replaceValue is called once per match with (matched, captures..., position,
# string[, groups]) and its result goes through ToString; anything else goes
# through ToString and then GetSubstitution (Lib js_get_substitution: $&,
# $1..$99, $<name>, $`, $', $$). The g / y state follows RegExpBuiltinExec: g
# resets lastIndex to 0 and replaces every match, an empty match stepping
# lastIndex one on; y matches only at lastIndex; a regex with neither replaces
# the first match from 0 and leaves lastIndex alone. Oracle: 'aaa' with
# r/a*/g -> '--', 'ab' with r/x*|a/g -> '-a-b-' (Perl's own s///g gives
# '--b-'), 'aab' with r/a/y -> '-ab' and with r/a/gy -> '--b'.
# Matching and lastIndex reckon in code points, as test / exec do (k53); the
# position GetSubstitution and a replacer see is counted in code units (ADR
# 0012); the pieces are joined through js_string_append.
sub symbol_replace {
  my ( $self, $string, $replace_value ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;

  my $s          = $rt->_js_to_string($string);
  my $functional = $lib->is_function($replace_value);
  $replace_value = $rt->_js_to_string($replace_value) unless $functional;
  my $global = index( $self->flags, 'g' ) >= 0;
  $self->lastIndex(0) if $global;

  my @results;
  while ( my $result = $self->_regexp_exec($s) ) {
    push @results, $result;
    last unless $global;
    # AdvanceStringIndex past an empty match
    $self->lastIndex( $self->lastIndex + 1 ) if $result->{matched} eq '';
  }

  my $accumulated_result   = '';
  my $next_source_position = 0;
  # the code-unit position of each match, counted on from the previous one
  my ( $chars, $units ) = ( 0, 0 );
  for my $result (@results) {
    my $position = $result->{index};
    $units += $lib->js_string_length( substr( $s, $chars, $position - $chars ) );
    $chars = $position;
    my $replacement = $functional
      ? $rt->_js_to_string(
          $replace_value->(
            $result->{matched}, @{ $result->{captures} }, $units, $s,
            defined( $result->{named} ) ? $result->{named} : (),
          ) )
      : $lib->js_get_substitution( $result->{matched}, $s, $units, $result->{captures},
          $result->{named}, $replace_value );
    if ( $position >= $next_source_position ) {
      $lib->js_string_append( $accumulated_result,
        substr( $s, $next_source_position, $position - $next_source_position ) );
      $lib->js_string_append( $accumulated_result, $replacement );
      $next_source_position = $position + length( $result->{matched} );
    }
  }
  return $accumulated_result if $next_source_position >= length($s);
  $lib->js_string_append( $accumulated_result, substr( $s, $next_source_position ) );
  return $accumulated_result;
}

# RegExpBuiltinExec for symbol_replace: the next match under the g / y state as
# { matched, index (a character offset), captures (undef for a group that did
# not take part), named (the groups object, or undef if the regex has no named
# group) }, or nothing. The groups object is engine-built, so it is an ordered
# dict (ADR 0011) with every group name in group order (_group_names), undef
# for a group that did not take part. lastIndex is read and moved only for a g
# or y regex; a failed match resets it to 0.
sub _regexp_exec {
  my ( $self, $s ) = @_;
  my $sticky     = $self->_is_sticky;
  my $stateful   = $sticky || index( $self->flags, 'g' ) >= 0;
  my $last_index = $stateful ? $self->lastIndex : 0;
  if ( $last_index > length($s) ) {
    $self->lastIndex(0) if $stateful;
    return;
  }
  # CAVEAT (see the test method): the qr must sit in a lexical before interpolation
  my $qr = $sticky ? $self->_qr_anchored : $self->_qr;
  pos($s) = $last_index;
  if ( !( $s =~ /$qr/g ) ) {
    $self->lastIndex(0) if $stateful;
    return;
  }
  # every group of the pattern ($#+), not @{^CAPTURE}: that one stops at the
  # last group that took part (oracle: 'ab' with r/(a)|(z)/ and '[$1|$2]'
  # gives '[a|]', $2 being a group that exists)
  my %result = (
    matched  => substr( $s, $-[0], $+[0] - $-[0] ),
    index    => $-[0],
    captures => [ map { defined( $-[$_] ) ? substr( $s, $-[$_], $+[$_] - $-[$_] ) : undef } 1 .. $#+ ],
    named    => @{ $self->_group_names }
      ? $self->_runtime->make_dict( map { $_ => $+{$_} } @{ $self->_group_names } )
      : undef,
  );
  $self->lastIndex( $+[0] ) if $stateful;
  return \%result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Runtime::Regex - A template regex literal, with the members of a JS RegExp (ADR 0013)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A regex literal of a template (C<r/.../flags>) becomes one of these. It has
the members a template reads on a JavaScript C<RegExp>: C<source>, C<flags>,
C<global> and C<lastIndex>, and C<test> and C<exec>; it stringifies to
C</source/flags>. The engine creates it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
