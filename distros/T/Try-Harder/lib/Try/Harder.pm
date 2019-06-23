use strict;
use warnings;
package Try::Harder;

# ABSTRACT: Try hard to get the functionality of Syntax::Keyword::Try

use Module::Load::Conditional qw( can_load );
use Import::Into;

use Carp;
$Carp::Internal{+__PACKAGE__}++;

# determine if we can use Syntax::Keyword::Try or have to use the pure-perl
# source filtering
our $USE_PP;
BEGIN {
  # Syntax::Keyword::Try is faster, safer, and better than the source filter
  # in every way. If it's available, just use it and be done with all this.
  if ( can_load( modules => { 'Syntax::Keyword::Try' => undef } )
       and not $ENV{TRY_HARDER_USE_PP} ) {
    #warn "Using Syntax::Keyword::Try\n";
    $USE_PP = 0;
  }
  else {
    #warn "Using ATHFilter\n";
    $USE_PP = 1;
  }
}

sub import {
  # TODO: add option to force using a particular implementation
  if ( ! $USE_PP ) {
    'Syntax::Keyword::Try'->import::into( scalar caller() );
  }
  else {
    # suppress warnings when user uses next/last/continue from within a
    # try or finally block. This is probably a bad idea, but hell, this
    # whole module is a bad idea.
    warnings->unimport('exiting');
  }
}


### code below only needed for the source-filtering implementation

use if $USE_PP, "Filter::Simple";
use if $USE_PP, "Text::Balanced" => qw( extract_codeblock );
use if $USE_PP, "Try::Tiny" => ();

setup_filter() if $USE_PP;

sub setup_filter {
  # Let Filter::Simple strip out all comments and strings to make it easier
  # to extract try/catch/finally code-blocks correctly.
  FILTER_ONLY(
    code_no_comments => sub { $_ = munge_code( $_ ) }
  );
}

# use an object to indicate a code-block never called return. This assumes
# nobody will ever intentionally return this object themselves...
my $S =  __PACKAGE__ . "::SENTINEL";
our $SENTINEL = bless {}, $S;

# return val of a Try::Tiny try/catch construct gets stored here
# so we can return it to the caller if needed.
my $R = __PACKAGE__ . "::RETVAL";
our @RETVAL;

# if an error is caught, stash it here to inject in the finally block
my $E = __PACKAGE__ . "::ERROR";
our $ERROR;

# flag to set if an exception is thrown
my $D = __PACKAGE__ . "::DIED";
our $DIED;

# wantarray context of the surrounding code
my $W = __PACKAGE__ . "::WANTARRAY";
our $WANTARRAY;

# stash the try/catch/finally closures in these
my $T = __PACKAGE__ . "::TRY";
our $TRY;
my $C = __PACKAGE__ . "::CATCH";
our $CATCH;
my $F = __PACKAGE__ . "::FINALLY";
our $FINALLY;

# name of the ScopeGuard object for finally functionality
my $G = __PACKAGE__ . "::ScopeGuard";


# stealing ideas from Try::Tiny, re-write the user's code to present the
# same functionality and behavior as Syntax::Keyword::Try, more or less.
# Note that the re-written code should take up the same number of lines
# as the original code, so line-numbers from warnings and such don't
# drive people bonkers.
sub munge_code {
  my ($code_to_filter) = @_;
  my $filtered_code = "";

  # ensure user does not use multiple catch/finally blocks.
  # Note that try { ... } try { ... } is perfectly valid.
  my $found_catch = 0;
  my $found_finally = 0;

  # find try/catch/finally keywords followed by a code-block, and extract the block
  while ( $code_to_filter =~ / ( .*? ) \b( try | catch | finally ) \s* ( [{] .* ) /msx ) {

    my ($before_kw, $kw, $after_kw) = ($1, $2, $3);

    my ($code_block, $remainder) = extract_codeblock($after_kw, "{}");

    # make sure to munge any nested try/catch blocks
    $code_block = munge_code( $code_block ) if $code_block;

    # maybe unnecessary?
    chomp $code_block;

    # rebuild the code with our modifications...
    $filtered_code .= $before_kw;

    if ( $kw eq 'try' ) {
      # found a try block, put everything in a new scope...
      $filtered_code .= ";{ ";
      # wrap the try block in a do block... if we reach the end of the do block,
      # we know return was never used in the do, so return a SENTINEL.
      $filtered_code .= "local \$$T = sub { do $code_block; return \$$S; };";
    }
    elsif ( $kw eq 'catch' ) {
      die "Syntax Error: Only one catch-block allowed." if $found_catch++;
      $filtered_code .= "local \$$C = sub { do $code_block; return \$$S; };";
    }
    elsif ( $kw eq 'finally' ) {
      die "Syntax Error: Only one finally-block allowed." if $found_finally++;
      $filtered_code .= "local \$$F = '$G'->_new(sub $code_block, \@_); ";
    }

    # if the remainder doesn't start with a catch or finally clause, assume
    # that's the end and add the code that makes this monstrosity work.
    if ( $remainder !~ /\A \s* ( catch | finally ) \s* [{] /msx ) {
      # add the code all on one line to preserve the original numbering.
      $filtered_code .=
          # init ERROR, DIED, RETVAL, and WANTARRAY
          "local ( \$$E, \$$D, \@$R ); local \$$W = wantarray; "
        . "{ "
        .   "local \$@; "
            # if an exception is thrown, value of eval will be undef, stash in DIED
        .   "\$$D = not eval { "
              # call TRY sub in appropriate context according to value of WANTARRAY
              # capturing the return value in RETVAL
        .     "if ( \$$W ) { \@$R = &\$$T; } elsif ( defined \$$W ) { \$$R\[0] = &\$$T; } else { &\$$T; } "
              # return 1 if no exception is thrown
        .     "return 1; "
        .   "}; "
            # stash any exception in ERROR
        .   "\$$E = \$@; "
        . "}; "
          # if DIED is true, and there's a CATCH sub, stash the ERROR in $@ and then
          # call the CATCH sub in the apropriate context. Else, re-throw ERROR
        . "if ( \$$D ) { "
        .   "if ( \$$C ) { "
        .     "local \$@ = \$$E; "
        .     "if ( \$$W ) { \@$R = &\$$C; } elsif ( defined \$$W ) { \$$R\[0] = &\$$C; } else { &\$$C; } "
        .   "} "
        .   "else { die \$$E } "
        . "}; "
          # if in current scope caller is true, and RETVAL isn't a ref or a SENTINEL, we know
          # that return was called in the code block, so return RETVAL in the apropriate context
        . "if ( caller() and (!ref(\$$R\[0]) or !\$$R\[0]->isa('$S')) ) { return \$$W ? \@$R : \$$R\[0]; } ";

      # close the scope opened when we first found the "try"
      $filtered_code .= "}";

      # this try/catch/finally construct is done. reset counters.
      $found_catch = $found_finally = 0;
    }

    # repeat this loop on the remaining code
    $code_to_filter = $remainder;
  }

  # overwrite the original code with the filtered code, plus whatever was left-over
  return $filtered_code . $code_to_filter;
}


{
  package # hide from PAUSE
    Try::Harder::ScopeGuard;

  # older versions of perl have an issue with $@ during global destruction
  use constant UNSTABLE_DOLLARAT => ("$]" < '5.013002') ? 1 : 0;

  sub _new {
    shift;
    bless [ @_ ];
  }

  sub DESTROY {
    my ($code, @args) = @{ $_[0] };
    # save the current exception to make it available in the finally sub,
    # and to restore it after the eval
    my $err = $@;
    local $@ if UNSTABLE_DOLLARAT;
    eval {
      $@ = $err;
      $code->(@args);
      1;
    } or do {
      warn
        "Execution of finally() block $code resulted in an exception, which "
      . '*CAN NOT BE PROPAGATED* due to fundamental limitations of Perl. '
      . 'Your program will continue as if this event never took place. '
      . "Original exception text follows:\n\n"
      . (defined $@ ? $@ : '$@ left undefined...')
      . "\n"
      ;
    };
    # maybe unnecessary?
    $@ = $err;
  }
}

1 && "This was an awful idea."; # truth
__END__

=head1 NAME
 
C<Try::Harder> - Yet another pure-perl C<try/catch/finally> module
 
=head1 SYNOPSIS
 
 use Try::Harder;
 
 # returns work as you would expect in other languages
 sub foo
 {
    try {
       attempt_a_thing();
       return "success"; # returns from the sub
    }
    catch {
       warn "It failed - $@";
       return "failure";
    }
 }
 
=head1 DESCRIPTION

This module provides sane C<try/catch/finally> syntax for perl that is (mostly)
semantically compatible with the syntax plugin L<Syntax::Keyword::Try>, but
implemented in pure-perl using source filters. However, if you already have
L<Syntax::Keyword::Try> installed it uses that instead.

Please see the L<Syntax::Keyword::Try> documentation for usage and such.

=head1 RATIONALE

Sometimes you don't have a version of perl new enough to use
L<Syntax::Keyword::Try>, but really want its nice syntax. Or
perhaps you really need your code to be pure-perl for various
reasons.

=head1 CAVEATS

This code implements a source filter, so all standard caveats with that apply.

=head1 TODO

Test with L<fatpack>

=head1 NOTES

See the post-filtered code by running this:

    TRY_HARDER_USE_PP=1 perl -c -Ilib -MFilter::ExtractSource test.pl > transformed.pl

This module tries very hard to not change the line-count of your code, so the
generated code is *very* dense.

=cut
