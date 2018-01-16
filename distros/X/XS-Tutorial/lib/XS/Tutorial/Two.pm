package XS::Tutorial::Two;
require XSLoader;

XSLoader::load();
1;

=head1 NAME

XS::Tutorial::Two - working with more than one value at a time

=head2 Introduction

In L<XS::Tutorial::One>, we learned the basic components of XS, and integrated
two C functions into Perl which were slower than their Perl builtin equivalents.
Oh well, we'll strive to do better in future tutorials. This chapter is going to
show you how to define xsubs that accept multiple parameters.

I realize that sounds I<incredibly> dull, but I promise along the way you'll
pickup some invaluable XS skills that can be used to create your own super fast
programs. 

=head2 Module Code

As before, we'll define the module code to load our XS. This is all that's
required:

  package XS::Tutorial::Two;
  require XSLoader;

  XSLoader::load();
  1;


That should be saved as C<lib/XS/Tutorial/Two.pm>.

=head2 XS Code

The top of the XS file will look similar to the previous chapter:

  #define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
  #include "EXTERN.h"         // globals/constant import locations
  #include "perl.h"           // Perl symbols, structures and constants definition
  #include "XSUB.h"           // xsubpp functions and macros
  #include "stdint.h"         // portable integer types

  MODULE = XS::Tutorial::Two  PACKAGE = XS::Tutorial::Two
  PROTOTYPES: ENABLE

Remember to append any XS code after the C<PROTOTYPES> line. This should be saved
as C<lib/XS/Tutorial/Two.xs>.

=head2 Adding numbers

Here's a simple declaration of an xsub that adds two integers:

  int
  add_ints (addend1, addend2)
    int addend1
    int addend2
    CODE:
      RETVAL = addend1 + addend2;
    OUTPUT:
      RETVAL

This declares an xsub called C<add_ints> which accepts two integers and whose
return type is C<int>. Note the L<K&R|https://stackoverflow.com/questions/1630631/alternative-kr-c-syntax-for-function-declaration-versus-prototypes> style of the function definition. This can also be written as:

  add_ints (int addend1, int addend2)

But you rarely see it done that way in the wild. I don't know if that's a cargo
cult thing or there are edge cases to the xsub compiler that I'm not aware of.
Just to be safe, I'll keep doing it the way everyone else does (the cult
persists!).

Whereas before we were essentially mapping C functions like C<srand> to Perl,
here we're declaring our own logic: C<add_ints> isn't imported from anywhere,
we're declaring it as a new function.

Since C<add_ints> is a new function, we need to define the logic of it, and
that's where the C<CODE> section comes in. Here we can write C code which
forms the body of the function. In this example, I add the two subroutine
parameters together and assign the result to C<RETVAL>.

L<RETVAL|https://perldoc.perl.org/perlxs.html#The-RETVAL-Variable> ("RETurn VALue") is a special variable that is declared by the xsub processor
(xsubpp). The C<OUTPUT> section accepts the return variable for the xsub, placing
it on the stack, so that calling code will receive it.

=head2 Adding more than two numbers

Adding two numbers is all well and good, but lists are the lingua franca of
Perl. Let's update the C<add_ints> xsub to accept n values:

  int32_t
  add_ints (...)
    CODE:
      uint32_t i;
      for (i = 0; i < items; i++) {
        if (!SvOK(ST(i)) || !SvIOK(ST(i)))
          croak("requires a list of integers");

        RETVAL += SvIVX(ST(i));
      }
    OUTPUT:
      RETVAL

First off, notice I've updated the return value. One issue with using C<int> in
C is it may be a different size on different machine architectures. C<int32_t>
is from the C<stdint.h> library, and guaranteed to be a 32 bit signed integer.

I've replaced the function parameters with C<...> which indicates the function
accepts a variable number of arguments, just like in C. In the C<CODE> section,
I declare a C<uint32_t> integer called C<i> (C<uint32_t> is a 32 bit unsigned
integer).

The C<for> loop uses the special variable C<items> (the number of arguments passed
to the function) to iterate over the arguments. The C<if> statement calls
the macro C<ST> to access the stack variable at position C<i>. This is used to
check that the scalar is defined (C<SvOK>) and that it is an integer (C<SvIOK>).
If either test fails, the code calls C<croak> to throw a fatal exception.

Otherwise the integer value is extracted from the scalar (C<SvIVX>) and added
to C<RETVAL>. If all of these C macros look strange to you, don't worry, they are
weird! They are part of the Perl C API, and they're documented in L<perlapi|https://perldoc.perl.org/perlapi.html>.

=head2 Edge cases

It's probably a good time to write some tests for this function, here's a
start:

  use Test::More;

  BEGIN { use_ok 'XS::Tutorial::Two' }

  cmp_ok XS::Tutorial::Two::add_ints(7,3), '==', 10;
  cmp_ok XS::Tutorial::Two::add_ints(1500, 21000, -1000), '==', 21500;

  done_testing;

I saved that file as C<t/two.t>, and run it by building the distribution with
C<make>:

  perl Makefile.PL && make && make test

Do you know what the return value would be if C<add_ints> was called with no
arguments? Maybe C<undef>, since if there are no arguments, the for loop will
not have any iterations. Here's a test for that condition:

  ok !defined XS::Tutorial::Two::add_ints(), 'empty list returns undef';

Re-building and running the tests with:

  make clean && perl Makefile.PL &&  make && make test

That test fails, because the return value is zero! This is a quirk of C:
uninitialized integers can be zero. Let's fix the xsub to return C<undef> when
it doesn't receive any arguments:

  SV *
  add_ints (...)
    PPCODE:
      uint32_t i;
      int32_t total = 0;
      if (items > 0) {
        for (i = 0; i < items; i++) {
          if (!SvOK(ST(i)) || !SvIOK(ST(i)))
            croak("requires a list of integers");

          total += SvIVX(ST(i));
        }
        PUSHs(sv_2mortal(newSViv(total)));
      }
      else {
        PUSHs(sv_newmortal());
      }

Woah, quite a few changes! First I've changed the return type to C<SV *>, from
C<int32_t>. The reason for this will become clear in a moment.  The C<CODE> section
is now called C<PPCODE>, which tells xsubpp that we will be managing the return
value of xsub ourselves, hence the C<OUTPUT> section is gone.

I've declared a new variable called C<total> to capture the running total of the
arguments as they're added. If we received at least one argument, total is copied
into a new scalar integer value (C<newSViv>), it's reference count is corrected
(C<sv_2mortal>) and it is pushed onto the stack pointer (C<PUSHs>).

Otherwise a new C<undef> scalar is declared with C<sv_newmortal> and that is pushed
onto the stack pointer instead. So in both cases we're returning an C<SV>. And as
we're returning a Perl type instead of a C type (C<int32_t>) there is no need for
xsubpp to cast our return value into a Perl scalar, we're already doing it.

=head2 References

=over 4

=item * L<XS::Tutorial::One> contains the background information necessary to understand this tutorial

=item * L<perlxs|http://perldoc.perl.org/perlxs.html> defines the keywords recognized by L<xsubpp|https://metacpan.org/pod/distribution/ExtUtils-ParseXS/lib/ExtUtils/xsubpp>
=item * L<perlapi|http://perldoc.perl.org/perlapi.html> lists the C macros used to interact with Perl data structures (and the interpreter)

=item * The L<stdint.h|http://pubs.opengroup.org/onlinepubs/009695399/basedefs/stdint.h.html> C library provides sets of portable integer types

=back

=cut
