#line 1
package Try::Tiny;
BEGIN {
  $Try::Tiny::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Try::Tiny::VERSION = '0.16';
}
use 5.006;
# ABSTRACT: minimal try/catch with proper preservation of $@

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = our @EXPORT_OK = qw(try catch finally);

use Carp;
$Carp::Internal{+__PACKAGE__}++;

BEGIN { eval "use Sub::Name; 1" or *{subname} = sub {1} }

# Need to prototype as @ not $$ because of the way Perl evaluates the prototype.
# Keeping it at $$ means you only ever get 1 sub because we need to eval in a list
# context & not a scalar one

sub try (&;@) {
  my ( $try, @code_refs ) = @_;

  # we need to save this here, the eval block will be in scalar context due
  # to $failed
  my $wantarray = wantarray;

  my ( $catch, @finally );

  # find labeled blocks in the argument list.
  # catch and finally tag the blocks by blessing a scalar reference to them.
  foreach my $code_ref (@code_refs) {

    if ( ref($code_ref) eq 'Try::Tiny::Catch' ) {
      croak 'A try() may not be followed by multiple catch() blocks'
        if $catch;
      $catch = ${$code_ref};
    } elsif ( ref($code_ref) eq 'Try::Tiny::Finally' ) {
      push @finally, ${$code_ref};
    } else {
      croak(
        'try() encountered an unexpected argument ('
      . ( defined $code_ref ? $code_ref : 'undef' )
      . ') - perhaps a missing semi-colon before or'
      );
    }
  }

  # FIXME consider using local $SIG{__DIE__} to accumulate all errors. It's
  # not perfect, but we could provide a list of additional errors for
  # $catch->();

  # name the blocks if we have Sub::Name installed
  my $caller = caller;
  subname("${caller}::try {...} " => $try);
  subname("${caller}::catch {...} " => $catch) if $catch;
  subname("${caller}::finally {...} " => $_) foreach @finally;

  # save the value of $@ so we can set $@ back to it in the beginning of the eval
  # and restore $@ after the eval finishes
  my $prev_error = $@;

  my ( @ret, $error );

  # failed will be true if the eval dies, because 1 will not be returned
  # from the eval body
  my $failed = not eval {
    $@ = $prev_error;

    # evaluate the try block in the correct context
    if ( $wantarray ) {
      @ret = $try->();
    } elsif ( defined $wantarray ) {
      $ret[0] = $try->();
    } else {
      $try->();
    };

    return 1; # properly set $fail to false
  };

  # preserve the current error and reset the original value of $@
  $error = $@;
  $@ = $prev_error;

  # set up a scope guard to invoke the finally block at the end
  my @guards =
    map { Try::Tiny::ScopeGuard->_new($_, $failed ? $error : ()) }
    @finally;

  # at this point $failed contains a true value if the eval died, even if some
  # destructor overwrote $@ as the eval was unwinding.
  if ( $failed ) {
    # if we got an error, invoke the catch block.
    if ( $catch ) {
      # This works like given($error), but is backwards compatible and
      # sets $_ in the dynamic scope for the body of C<$catch>
      for ($error) {
        return $catch->($error);
      }

      # in case when() was used without an explicit return, the C<for>
      # loop will be aborted and there's no useful return value
    }

    return;
  } else {
    # no failure, $@ is back to what it was, everything is fine
    return $wantarray ? @ret : $ret[0];
  }
}

sub catch (&;@) {
  my ( $block, @rest ) = @_;

  croak 'Useless bare catch()' unless wantarray;

  return (
    bless(\$block, 'Try::Tiny::Catch'),
    @rest,
  );
}

sub finally (&;@) {
  my ( $block, @rest ) = @_;

  croak 'Useless bare finally()' unless wantarray;

  return (
    bless(\$block, 'Try::Tiny::Finally'),
    @rest,
  );
}

{
  package # hide from PAUSE
    Try::Tiny::ScopeGuard;

  use constant UNSTABLE_DOLLARAT => ($] < '5.013002') ? 1 : 0;

  sub _new {
    shift;
    bless [ @_ ];
  }

  sub DESTROY {
    my ($code, @args) = @{ $_[0] };

    local $@ if UNSTABLE_DOLLARAT;
    eval {
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
    }
  }
}

__PACKAGE__

__END__

#line 654
