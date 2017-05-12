package Want;

require 5.006;
use Carp 'croak';
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw(want rreturn lnoreturn);
our @EXPORT_OK = qw(howmany wantref);
our $VERSION = '0.29';

bootstrap Want $VERSION;

my %reftype = (
    ARRAY  => 1,
    HASH   => 1,
    CODE   => 1,
    GLOB   => 1,
    OBJECT => 1,
);

sub _wantone {
    my ($uplevel, $arg) = @_;
    
    my $wantref = wantref($uplevel + 1);
    if	  ($arg =~ /^\d+$/) {
	my $want_count = want_count($uplevel);
	return ($want_count == -1 || $want_count >= $arg);
    }
    elsif (lc($arg) eq 'infinity') {
	return (want_count($uplevel) == -1);
    }
    elsif ($arg eq 'REF') {
	return $wantref;
    }
    elsif ($reftype{$arg}) {
	return ($wantref eq $arg);
    }
    elsif ($arg eq 'REFSCALAR') {
	return ($wantref eq 'SCALAR');
    }
    elsif ($arg eq 'LVALUE') {
	return want_lvalue($uplevel);
    }
    elsif ($arg eq 'RVALUE') {
	return !want_lvalue($uplevel);
    }
    elsif ($arg eq 'VOID') {
	return !defined(wantarray_up($uplevel));
    }
    elsif ($arg eq 'SCALAR') {
	my $gimme = wantarray_up($uplevel);
	return (defined($gimme) && 0 == $gimme);
    }
    elsif ($arg eq 'BOOL' || $arg eq 'BOOLEAN') {
	return want_boolean(bump_level($uplevel));
    }
    elsif ($arg eq 'LIST') {
	return wantarray_up($uplevel);
    }
    elsif ($arg eq 'COUNT') {
	croak("want: COUNT must be the *only* parameter");
    }
    elsif ($arg eq 'ASSIGN') {
	return !!wantassign($uplevel + 1);
    }
    else {
	croak ("want: Unrecognised specifier $arg");
    }    
}

sub want {
    if (@_ == 1 && $_[0] eq 'ASSIGN') {
	@_ = (1);
	goto &wantassign;
    }
    want_uplevel(1, @_);
}

# Simulate the propagation of context through a return value.
sub bump_level {
    my ($level) = @_;
    for(;;) {
	my ($p, $r) = parent_op_name($level+1);
	if ($p eq "return"
        or  $p eq "(none)" && $r =~ /^leavesub(lv)?$/)
	{
	    ++$level
	}
	else {
	    return $level
	}
    }
}

sub want_uplevel {
    my ($level, @args) = @_;

    # Deal with special cases (for RFC21-consistency):
    if (1 == @args) {
	@_ = (1 + $level);
	goto &wantref    if $args[0] eq 'REF';
	goto &howmany    if $args[0] eq 'COUNT';
	goto &wantassign if $args[0] eq 'ASSIGN';
    }

    for my $arg (map split, @args) {
	if ($arg =~ /^!(.*)/) {
	    return 0 unless !_wantone(2 + $level, $1);
	}
	else {
	    return 0 unless _wantone(2 + $level, $arg);
	}
    }
    
    return 1;
}

sub howmany () {
    my $level = bump_level(@_, 1);
    my $count = want_count($level);
    return ($count < 0 ? undef : $count);
}

sub wantref {
    my $level = bump_level(@_, 1);
    my $n = parent_op_name($level);
    if    ($n eq 'rv2av') {
	return "ARRAY";
    }
    elsif ($n eq 'rv2hv') {
	return "HASH";
    }
    elsif ($n eq 'rv2cv' || $n eq 'entersub') {
	return "CODE";
    }
    elsif ($n eq 'rv2gv' || $n eq 'gelem') {
	return "GLOB";
    }
    elsif ($n eq 'rv2sv') {
	return "SCALAR";
    }
    elsif ($n eq 'method_call') {
	return 'OBJECT';
    }
    elsif ($n eq 'multideref') {
	return first_multideref_type($level);
    }
    else {
	return "";
    }
}

sub wantassign {
    my $uplevel = shift();
    return unless want_lvalue($uplevel);
    my $r = want_assign(bump_level($uplevel));
    if (want('BOOL')) {
	return (defined($r) && 0 != $r);
    }
    else {
	return $r ? (want('SCALAR') ? $r->[$#$r] : @$r) : ();
    }
}

sub double_return :lvalue;

sub rreturn (@) {
    if (want_lvalue(1)) {
        croak "Can't rreturn in lvalue context";
    }

    # Extra scope needed to work with perl-5.19.7 or greater.
    # Prevents the return being optimised out, which is needed
    # since it's actually going to be used a stack level above
    # this sub.
    {
        return double_return(@_);
    }
}

sub lnoreturn () : lvalue {
    if (!want_lvalue(1) || !want_assign(1)) {
        croak "Can't lnoreturn except in ASSIGN context";
    }

    # Extra scope needed to work with perl-5.19.7 or greater.
    # Prevents the return being optimised out, which is needed
    # since it's actually going to be used a stack level above
    # this sub.
    #
    # But in older versions of perl, adding the extra scope
    # causes the error:
    #   Can't modify loop exit in lvalue subroutine return
    # so we have to check the version.
    if ($] >= 5.019) {
        return double_return(disarm_temp(my $undef));
    }
    return double_return(disarm_temp(my $undef));
}

# Some naughty people were relying on these internal methods.
*_wantref = \&wantref;
*_wantassign = \&wantassign;

1;

__END__

=head1 NAME

Want - A generalisation of C<wantarray>

=head1 SYNOPSIS

  use Want;
  sub foo :lvalue {
      if    (want(qw'LVALUE ASSIGN')) {
        print "We have been assigned ", want('ASSIGN');
        lnoreturn;
      }
      elsif (want('LIST')) {
        rreturn (1, 2, 3);
      }
      elsif (want('BOOL')) {
        rreturn 0;
      }
      elsif (want(qw'SCALAR !REF')) {
        rreturn 23;
      }
      elsif (want('HASH')) {
        rreturn { foo => 17, bar => 23 };
      }
      return;  # You have to put this at the end to keep the compiler happy
  }

=head1 DESCRIPTION

This module generalises the mechanism of the B<wantarray> function,
allowing a function to determine in some detail how its return value
is going to be immediately used.

=head2 Top-level contexts:

The three kinds of top-level context are well known:

=over 4

=item B<VOID>

The return value is not being used in any way. It could be an entire statement
like C<foo();>, or the last component of a compound statement which is itself in
void context, such as C<$test || foo();>n. Be warned that the last statement
of a subroutine will be in whatever context the subroutine was called in, because
the result is implicitly returned.

=item B<SCALAR>

The return value is being treated as a scalar value of some sort:

  my $x = foo();
  $y += foo();
  print "123" x foo();
  print scalar foo();
  warn foo()->{23};
  ...etc...

=item B<LIST>

The return value is treated as a list of values:

  my @x = foo();
  my ($x) = foo();
  () = foo();		# even though the results are discarded
  print foo();
  bar(foo());		# unless the bar subroutine has a prototype
  print @hash{foo()};	# (hash slice)
  ...etc...

=back

=head2 Lvalue subroutines:

The introduction of B<lvalue subroutines> in Perl 5.6 has created a new type
of contextual information, which is independent of those listed above. When
an lvalue subroutine is called, it can either be called in the ordinary way
(so that its result is treated as an ordinary value, an B<rvalue>); or else
it can be called so that its result is considered updatable, an B<lvalue>.

These rather arcane terms (lvalue and rvalue) are easier to remember if you
know why they are so called. If you consider a simple assignment statement
C<left = right>, then the B<l>eft-hand side is an B<l>value and the B<r>ight-hand
side is an B<r>value.

So (for lvalue subroutines only) there are two new types of context:

=over 4

=item B<RVALUE>

The caller is definitely not trying to assign to the result:

  foo();
  my $x = foo();
  ...etc...

If the sub is declared without the C<:lvalue> attribute, then it will
I<always> be in RVALUE context.

If you need to return values from an lvalue subroutine in RVALUE context,
you should use the C<rreturn> function rather than an ordinary C<return>.
Otherwise you'll probably get a compile-time error in perl 5.6.1 and later.

=item B<LVALUE>

Either the caller is directly assigning to the result of the sub call:

  foo() = $x;
  foo() = (1, 1, 2, 3, 5, 8);

or the caller is making a reference to the result, which might be assigned to
later:

  my $ref = \(foo());	# Could now have: $$ref = 99;
  
  # Note that this example imposes LIST context on the sub call.
  # So we're taking a reference to the first element to be
  # returned _in list context_.
  # If we want to call the function in scalar context, we can
  # do it like this:
  my $ref = \(scalar foo());

or else the result of the function call is being used as part of the argument list
for I<another> function call:

  bar(foo());	# Will *always* call foo in lvalue context,
  		# (provided that foo is an C<:lvalue> sub)
  		# regardless of what bar actually does.

The reason for this last case is that bar might be a sub which modifies its
arguments. They're rare in contemporary Perl code, but perfectly possible:

  sub bar {
    $_[0] = 23;
  }

(This is really a throwback to Perl 4, which didn't support explicit references.)

=back

=head2 Assignment context:

The commonest use of lvalue subroutines is with the assignment statement:

  size() = 12;
  (list()) = (1..10);

A useful motto to remember when thinking about assignment statements is
I<context comes from the left>. Consider code like this:

  my ($x, $y, $z);
  sub list () :lvalue { ($x, $y, $z) }
  list = (1, 2, 3);
  print "\$x = $x; \$y = $y; \$z = $z\n";

This prints C<$x = ; $y = ; $z = 3>, which may not be what you were expecting.
The reason is that the assignment is in scalar context, so the comma operator
is in scalar context too, and discards all values but the last. You can fix
it by writing C<(list) = (1,2,3);> instead.

If your lvalue subroutine is used on the left of an assignment statement,
it's in B<ASSIGN> context.  If ASSIGN is the only argument to C<want()>, then
it returns a reference to an array of the value(s) of the right-hand side.

In this case, you should return with the C<lnoreturn> function, rather than
an ordinary C<return>. 

This makes it very easy to write lvalue subroutines which do clever things:

  use Want;
  use strict;
  sub backstr :lvalue {
    if (want(qw'LVALUE ASSIGN')) {
      my ($a) = want('ASSIGN');
      $_[0] = reverse $a;
      lnoreturn;
    }
    elsif (want('RVALUE')) {
      rreturn scalar reverse $_[0];
    }
    else {
      carp("Not in ASSIGN context");
    }
    return
  }
 
  print "foo -> ", backstr("foo"), "\n";	# foo -> oof
  backstr(my $robin) = "nibor";
  print "\$robin is now $robin\n";		# $robin is now robin

Notice that you need to put a (meaningless) return
statement at the end of the function, otherwise you will get the
error
I<Can't modify non-lvalue subroutine call in lvalue subroutine return>.

The only way to write that C<backstr> function without using Want is to return
a tied variable which is tied to a custom class.

=head2 Reference context:

Sometimes in scalar context the caller is expecting a reference of some sort
to be returned:

    print foo()->();     # CODE reference expected
    print foo()->{bar};  # HASH reference expected
    print foo()->[23];   # ARRAY reference expected
    print ${foo()};	 # SCALAR reference expected
    print foo()->bar();	 # OBJECT reference expected
    
    my $format = *{foo()}{FORMAT} # GLOB reference expected

You can check this using conditionals like C<if (want('CODE'))>.
There is also a function C<wantref()> which returns one of the strings
"CODE", "HASH", "ARRAY", "GLOB", "SCALAR" or "OBJECT"; or the empty string
if a reference is not expected.

Because C<want('SCALAR')> is already used to select ordinary scalar context,
you have to use C<want('REFSCALAR')> to find out if a SCALAR reference is
expected. Or you could use C<want('REF') eq 'SCALAR'> of course.

Be warned that C<want('ARRAY')> is a B<very> different thing from C<wantarray()>.

=head2 Item count

Sometimes in list context the caller is expecting a particular number of items
to be returned:

    my ($x, $y) = foo();   # foo is expected to return two items

If you pass a number to the C<want> function, then it will return true or false
according to whether at least that many items are wanted. So if we are in the
definition of a sub which is being called as above, then:

    want(1) returns true
    want(2) returns true
    want(3) returns false

Sometimes there is no limit to the number of items that might be used:

    my @x = foo();
    do_something_with( foo() );

In this case, C<want(2)>, C<want(100)>, C<want(1E9)> and so on will all return
true; and so will C<want('Infinity')>.

The C<howmany> function can be used to find out how many items are wanted.
If the context is scalar, then C<want(1)> returns true and C<howmany()> returns
1. If you want to check whether your result is being assigned to a singleton
list, you can say C<if (want('LIST', 1)) { ... }>.


=head2 Boolean context

Sometimes the caller is only interested in the truth or falsity of a function's
return value:

    if (everything_is_okay()) {
	# Carry on
    }
    
    print (foo() ? "ok\n" : "not ok\n");
    
In the following example, all subroutine calls are in BOOL context:

    my $x = ( (foo() && !bar()) xor (baz() || quux()) );

Boolean context, like the reference contexts above, is considered to be a subcontext
of SCALAR.

=head1 FUNCTIONS

=over 4

=item want(SPECIFIERS)

This is the primary interface to this module, and should suffice for most
purposes. You pass it a list of context specifiers, and the return value
is true whenever all of the specifiers hold.

    want('LVALUE', 'SCALAR');   # Are we in scalar lvalue context?
    want('RVALUE', 3);		# Are at least three rvalues wanted?
    want('ARRAY');	# Is the return value used as an array ref?

You can also prefix a specifier with an exclamation mark to indicate that you
B<don't> want it to be true

    want(2, '!3');		# Caller wants exactly two items.
    want(qw'REF !CODE !GLOB');  # Expecting a reference that
    				#   isn't a CODE or GLOB ref.
    want(100, '!Infinity');	# Expecting at least 100 items,
    				#   but there is a limit.

If the I<REF> keyword is the only parameter passed, then the type of reference will be
returned.  This is just a synonym for the C<wantref> function: it's included because
you might find it useful if you don't want to pollute your namespace by importing
several functions, and to conform to Damian Conway's suggestion in RFC 21.

Finally, the keyword I<COUNT> can be used, provided that it's the only keyword
you pass. Mixing COUNT with other keywords is an error. This is a synonym for the
C<howmany> function.

A full list of the permitted keyword is in the B<ARGUMENTS> section below.

=item rreturn

Use this function instead of C<return> from inside an lvalue subroutine when
you know that you're in RVALUE context. If you try to use a normal C<return>,
you'll get a compile-time error in Perl 5.6.1 and above unless you return an
lvalue. (Note: this is no longer true in Perl 5.16, where an ordinary return
will once again work.)

=item lnoreturn

Use this function instead of C<return> from inside an lvalue subroutine when
you're in ASSIGN context and you've used C<want('ASSIGN')> to carry out the
appropriate action.

If you use C<rreturn> or C<lnoreturn>, then you have to put a bare C<return;>
at the very end of your lvalue subroutine, in order to stop the Perl compiler
from complaining. Think of it as akin to the C<1;> that you have to put at the
end of a module. (Note: this is no longer true in Perl 5.16.)

=item howmany()

Returns the I<expectation count>, i.e. the number of items expected. If the 
expectation count is undefined, that
indicates that an unlimited number of items might be used (e.g. the return
value is being assigned to an array). In void context the expectation count
is zero, and in scalar context it is one.

The same as C<want('COUNT')>.

=item wantref()

Returns the type of reference which the caller is expecting, or the empty string
if the caller isn't expecting a reference immediately.

The same as C<want('REF')>.

=back

=head1 EXAMPLES

    use Carp 'croak';
    use Want 'howmany';
    sub numbers {
	my $count = howmany();
	croak("Can't make an infinite list") if !defined($count);
	return (1..$count);
    }
    my ($one, $two, $three) = numbers();
    
    
    use Want 'want';
    sub pi () {
	if    (want('ARRAY')) {
	    return [3, 1, 4, 1, 5, 9];
	}
	elsif (want('LIST')) {
	    return (3, 1, 4, 1, 5, 9);
	}
	else {
	    return 3;
	}
    }
    print pi->[2];	# prints 4
    print ((pi)[3]);	# prints 1

=head1 ARGUMENTS

The permitted arguments to the C<want> function are listed below.
The list is structured so that sub-contexts appear below the context that they
are part of.

=over 4

=item *

VOID

=item *

SCALAR

=over 4

=item *

REF

=over 4

=item *

REFSCALAR

=item *

CODE

=item *

HASH

=item *

ARRAY

=item *

GLOB

=item *

OBJECT

=back

=item *

BOOL

=back

=item *

LIST

=over 4

=item *

COUNT

=item *

E<lt>numberE<gt>

=item *

Infinity

=back

=item *

LVALUE

=over 4

=item *

ASSIGN

=back

=item *

RVALUE

=back

=head1 EXPORT

The C<want> and C<rreturn> functions are exported by default.
The C<wantref> and/or C<howmany> functions can also be imported:

  use Want qw'want howmany';

If you don't import these functions, you must qualify their names as (e.g.)
C<Want::wantref>.

=head1 INTERFACE

This module is still under development, and the public interface may change in
future versions. The C<want> function can now be regarded as stable.

I'd be interested to know how you're using this module.

=head1 SUBTLETIES

There are two different levels of B<BOOL> context. I<Pure> boolean context
occurs in conditional expressions, and the operands of the C<xor> and C<!>/C<not>
operators.
Pure boolean context also propagates down through the C<&&> and C<||> operators.

However, consider an expression like C<my $x = foo() && "yes">. The subroutine
is called in I<pseudo>-boolean context - its return value isn't B<entirely>
ignored, because the undefined value, the empty string and the integer 0 are
all false.

At the moment C<want('BOOL')> is true in either pure or pseudo boolean
context. Let me know if this is a problem.

=head1 BUGS

 * Doesn't work from inside a tie-handler.

=head1 AUTHOR

Robin Houston, E<lt>robin@cpan.orgE<gt>

Thanks to Damian Conway for encouragement and good suggestions,
and Father Chrysostomos for a patch.

=head1 SEE ALSO

=over 4

=item *

L<perlfunc/wantarray>

=item *

Perl6 RFC 21, by Damian Conway.
http://dev.perl.org/rfc/21.html

=back

=head1 COPYRIGHT

Copyright (c) 2001-2012, Robin Houston. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
