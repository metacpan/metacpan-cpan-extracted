package Test::Taint;

## no critic (Bangs::ProhibitVagueNames)
## We're dealing with abstract vars like "$var" in this code.

=head1 NAME

Test::Taint - Tools to test taintedness

=head1 VERSION

Version 1.08

=cut

use vars qw( $VERSION );
$VERSION = '1.08';

=head1 SYNOPSIS

    taint_checking_ok();        # We have to have taint checking on
    my $id = "deadbeef";        # Dummy session ID
    taint( $id );               # Simulate it coming in from the web
    tainted_ok( $id );
    $id = validate_id( $id );   # Your routine to check the $id
    untainted_ok( $id );        # Did it come back clean?
    ok( defined $id );

=head1 DESCRIPTION

Tainted data is data that comes from an unsafe source, such as the
command line, or, in the case of web apps, any GET or POST transactions.
Read the L<perlsec> man page for details on why tainted data is bad,
and how to untaint the data.

When you're writing unit tests for code that deals with tainted data,
you'll want to have a way to provide tainted data for your routines to
handle, and easy ways to check and report on the taintedness of your data,
in standard L<Test::More> style.

=cut

use strict;
use warnings;

use base 'DynaLoader';
use Test::Builder;
use overload;
use Scalar::Util;
use vars qw( $TAINT );

my $Test = Test::Builder->new;

use vars qw( @EXPORT );
@EXPORT = qw(
    taint             taint_deeply
    tainted           tainted_deeply
    tainted_ok        tainted_ok_deeply
    untainted_ok      untainted_ok_deeply
    taint_checking
    taint_checking_ok
);

bootstrap Test::Taint $VERSION;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    for my $sub ( @EXPORT ) {
        *{$caller.'::'.$sub} = \&{$sub};
    }
    $Test->exported_to($caller);
    $Test->plan(@_);
} # import

sub _deeply_traverse {
    my $callback = shift;
    my @stack    = \@_;

    my %seen;

    while(@stack) {
        my $node = pop @stack;

        # skip the node if its not a reference
        next unless defined $node;

        my($realpack, $realtype, $id) = overload::StrVal($node) =~ /\A(?:(.+)\=)?(HASH|ARRAY|GLOB|SCALAR|REF)\((0x[[:xdigit:]]+)\)\z/
            or next;

        # taint the contents of tied objects
        if(my $tied = $realtype eq 'HASH'   ? tied %{$node} :
                      $realtype eq 'ARRAY'  ? tied @{$node} :
                      $realtype eq 'SCALAR' ? tied ${$node} :
                      $realtype eq 'REF'    ? tied ${$node} : undef) {
            push @stack, $tied;
            next;
        }

        # prevent circular references from being traversed
        no warnings 'uninitialized';
        next if $seen{$realpack, $realtype, $id}++;

        # perform an action on the node, then push them on the stack for traversal
        push @stack,
            $realtype eq 'HASH'   ? $callback->(values %{$node}) :
            $realtype eq 'ARRAY'  ? $callback->(@{$node})        :
            $realtype eq 'SCALAR' ? $callback->(${$node})        :
            $realtype eq 'REF'    ? $callback->(${$node})        :
            map $callback->(*$node{$_}), qw(SCALAR ARRAY HASH);   #must be a GLOB
    }

    return;
} # _deeply_traverse

=head1 C<Test::More>-style Functions

All the C<xxx_ok()> functions work like standard C<Test::More>-style
functions, where the last parm is an optional message, it outputs ok or
not ok, and returns a boolean telling if the test passed.

=head2 taint_checking_ok( [$message] )

L<Test::More>-style test that taint checking is on.  This should probably
be the first thing in any F<*.t> file that deals with taintedness.

=cut

sub taint_checking_ok {
    my $msg = @_ ? shift : "Taint checking is on";

    my $ok = taint_checking();
    $Test->ok( $ok, $msg );

    return $ok;
} # taint_checking_ok

=head2 tainted_ok( $var [, $message ] )

Checks that I<$var> is tainted.

    tainted_ok( $ENV{FOO} );

=cut

sub tainted_ok {
    my $var = shift;
    my $msg = shift;
    my $ok = tainted( $var );
    $Test->ok( $ok, $msg );

    return $ok;
} # tainted_ok

=head2 untainted_ok( $var [, $message ] )

Checks that I<$var> is not tainted.

    my $foo = my_validate( $ENV{FOO} );
    untainted_ok( $foo );

=cut

sub untainted_ok {
    my $var = shift;
    my $msg = shift;

    my $ok = !tainted( $var );
    $Test->ok( $ok, $msg );

    return $ok;
} # untainted_ok

=head2 tainted_ok_deeply( $var [, $message ] )

Checks that I<$var> is tainted.  If I<$var>
is a reference, it recursively checks every
variable to make sure they are all tainted.

    tainted_ok_deeply( \%ENV );

=cut

sub tainted_ok_deeply {
    my $var = shift;
    my $msg = shift;

    my $ok = tainted_deeply( $var );
    $Test->ok( $ok, $msg );

    return $ok;
} # tainted_ok_deeply

=head2 untainted_ok_deeply( $var [, $message ] )

Checks that I<$var> is not tainted.  If I<$var>
is a reference, it recursively checks every
variable to make sure they are all not tainted.

    my %env = my_validate( \%ENV );
    untainted_ok_deeply( \%env );

=cut

sub untainted_ok_deeply {
    my $var = shift;
    my $msg = shift;

    my $ok = !tainted_deeply( $var );
    $Test->ok( $ok, $msg );

    return $ok;
} # untainted_ok_deeply

=head1 Helper Functions

These are all helper functions.  Most are wrapped by an C<xxx_ok()>
counterpart, except for C<taint> which actually does something, instead
of just reporting it.

=head2 taint_checking()

Returns true if taint checking is enabled via the -T flag.

=cut

sub taint_checking() {
    return tainted( $Test::Taint::TAINT );
} # taint_checking

=head2 tainted( I<$var> )

Returns boolean saying if C<$var> is tainted.

=cut

sub tainted {
    no warnings qw(void uninitialized);

    return !eval { local $SIG{__DIE__} = 'DEFAULT'; join('', shift), kill 0; 1 };
} # tainted

=head2 tainted_deeply( I<$var> )

Returns boolean saying if C<$var> is tainted.  If
C<$var> is a reference it recursively checks every
variable to make sure they are all tainted.

=cut

sub tainted_deeply {
  my $is_tainted = 1;

  _deeply_traverse(
      sub {
          foreach (@_) {
            next
              if not defined
              or ref
              or Scalar::Util::readonly $_
              or tainted $_;

            $is_tainted = 0;
            last;
          }

          return @_;
      },
      shift,
  );

  return $is_tainted;
} # tainted_deeply

=head2 taint( @list )

Marks each (apparently) taintable argument in I<@list> as being tainted.

References can be tainted like any other scalar, but it doesn't make
sense to, so they will B<not> be tainted by this function.

Some C<tie>d and magical variables may fail to be tainted by this routine,
try as it may.

=cut

sub taint {
    local $_;

    for ( @_ ) {
        _taint($_) unless ref or Scalar::Util::readonly $_;
    }
} # taint

# _taint() is an external function in Taint.xs

=head2 taint_deeply( @list )

Similar to C<taint>, except that if any elements in I<@list> are
references, it walks deeply into the data structure and marks each
taintable argument as being tainted.

If any variables are C<tie>d this will taint all the scalars within
the tied object.

=cut

sub taint_deeply {
    _deeply_traverse(
        sub { taint @_; @_ },
        @_,
    );

    return;
} # taint_deeply

BEGIN {
    MAKE_SOME_TAINT: {
        # Somehow we need to get some taintedness into $Test::Taint::TAINT
        # Let's try the easy way first. Either of these should be
        # tainted, unless somebody has untainted them, so this
        # will almost always work on the first try.
        # (Unless, of course, taint checking has been turned off!)
        $TAINT = substr("$0$^X", 0, 0);
        last if tainted $TAINT;

        # Let's try again. Maybe somebody cleaned those.
        $TAINT = substr(join('', @ARGV, %ENV), 0, 0);
        last if tainted $TAINT;

        # If those don't work, go try to open some file from some unsafe
        # source and get data from them.  That data is tainted.
        # (Yes, even reading from /dev/null works!)
        local(*FOO);
        for ( qw(/dev/null / . ..), values %INC, $0, $^X ) {
            next unless defined $_;
            if ( open FOO, $_ ) {
                my $potentially_tainted_data;
                if ( defined sysread FOO, $potentially_tainted_data, 1 ) {
                    $TAINT = substr( $potentially_tainted_data, 0, 0 );
                    last if tainted $TAINT;
                }
            }
        }
        close FOO;
    }

    # Sanity check
    die 'Our taintbrush should have zero length!' if length $TAINT;
}


=head1 AUTHOR

Written by Andy Lester, C<< <andy@petdance.com> >>.

=head1 COPYRIGHT

Copyright 2004-2019, Andy Lester.

You may use, modify, and distribute this package under the
same terms as Perl itself.

=cut

1;
