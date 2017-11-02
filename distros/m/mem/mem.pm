#!/usr/bin/perl 

BEGIN { require $_.".pm" && $_->import for qw(strict warnings) }

=encoding utf-8

=pod

=head1 NAME

=over

•ḟmem - use modules in "mem"ory (already declared in same file)

=back

=head1 VERSION

Version "0.4.7"

=cut

package mem;  
  our $VERSION='0.4.7';
	
  # RCS $Revision: 1.8 $ $Date: 2015-06-30 01:36:59-07 $
	# 0.4.7   - minor POD corrections
	# 0.4.6	  - conditionalize warning & strict based on presence;  
	#         - Documentation changes.
	# 0.4.5		- Add alt version format for ExtMM 
	# 0.4.4		- Add dep on recent ExtMM @ in BUILD_REQ
	#           Documentation enhancements and clarifications.
	# 0.4.3		- change format of VERSION to a string (vec unsupported
	# 					in earlier perl versions)
	# 0.4.2		- doc change & excisement of a symlink (maybe winprob)
	# 0.4.1		- revert attempt to use win32 BS -- seems to cause
	# 					more problems than it fixed.
	# 0.4.0		- Documentation upgrade; 
  #           Attempt to point to win32 paths w/backslash
	# 0.3.3		- Switch to using ptar for archive creation
	# 0.3.2		- Fix summary to be more descriptive
	#	0.3.1		- Fix Manifest => MANIFEST
	#	0.3.0		- Initial external 'non'-release

	sub sep_detect() { '/' }

	our $sep;

  sub import { 
    if (@_ >= 1) {
      my ($p, $f, $l)=caller;
		  $sep ||= sep_detect();
      if (@_ >= 1) { 
        $p="main" unless $p;
        $p =~ s!::!$sep!ge;
        $p .= ".pm";
        $::INC{$p} = $f."#".$l unless exists $::INC{$p};
      }
    }
  } 
1;


##########################################################################
#                 use mem; {{{1


=head1 SYNOPSIS


  use mem;
  use mem(@COMPILE_TIME_DEFINES=qw(a b c));

B<C<mem>> is a I<syntactic-sugar> C<pragma> that allows C<use>-ing a C<package> as it is previously defined, B<in the same file>. This allows easy declaration of specialized, typed data structures (like I<C> C<struct> definitions) that increase code legibility and concept clarity.  In a similar usage, the L<constants> pragma allows defining low-overhead, runtime constants. 

Allowing C<use> of packages in the same file allows calling code to access classes in a clean, object oriented manner, allowing for identical code to
exist either in the same file, or in a separate file without making code
changes or requiring use of non-portable, language specific features to
accomplish the same thing.

In the 2nd form, it can allow in-lined BEGIN's for single line
assignments.  While one could use it as a replacement for multiple
lines, an actual BEGIN block can often look as much or more tidy.

In many cases, these compile time assignments are essential to take full
advantage of perl's strengths.  For example, without compile time assignment
of '@EXPORT', you can't use perl's function prototypes.  Due the overhead and difficulty in getting them right, new perl programmers are dissuaded from
using such featues.

When used to force assignments into the early parsing stages of perl, Using dynamically allocated, pre-initialized and type-checked data structures become
possible.

=head1 EXAMPLE

Following, is a sample program, showing two uses of  C<mem> .  This first example allows declaring a run-time keyword 'ARRAY', that can check to see
if it's argument is an ARRAY reference, B<and> provide a runtime
literal,  C<ARRAY> , that can be used without quotes.

  use strict; use warnings;

  { package Ar_Type;
      #
      use mem;                                    #1st usage 
      our (@EXPORT);
      sub ARRAY (;*) {
          my $p = $_[0]; my $t="ARRAY";
          return @_ ? (ref $p && (1+index($p, $t))) : $t;
      }
      #
      use mem( @EXPORT=qw(ARRAY) );               #2nd usage 
      
			use Xporter;
  }

  package main;
  use Ar_Type;
  use P;

  my @a=(1,2,3);
  my ($ed, $light);
      (@$ed, @$light) = (@a, @a);  #ed & light point to copies of @a
  bless $ed, "bee";

  P "\@a = ref of array" if ARRAY \@a;
  P "ref of \$ed is \"%s\".", ref $ed;
  P "ed still points to underlying type, 'array'" if ARRAY $ed;
  P "Is ref \$light, an ARRAY?: %s", (ref $light eq ARRAY) ? 'yes':'no';
  P "Does \"ref \$ed\" eq ARRAY?: %s", (ref $ed eq ARRAY) ? 'yes':'no';
  P "%s", "#  (Because \"ref \$ed\" is really a bless \"ed\" bee)"

=over

=item 

Now, to show what happens using  C<mem>, and the errors that occur if you
do not.  First, the correct output:

  @a = ref of array
  ref of $ed is "bee".
  ed still points to underlying type, 'array'
  Is ref $light, an ARRAY?: yes
  Does ref $ed eq ARRAY?: no
  #  (Because ref "ed" is really a bless"ed" bee)


=item 

Second, B<I<without>> the first "C< use mem >", presuming the line was commented out:

  Can't locate Ar_Type.pm in @INC (@INC contains: 
    /usr/lib/perl5/5.18.2 ...   /usr/lib/perl5/site_perl .) 
    at /tmp/ex line 18.
  BEGIN failed--compilation aborted at /tmp/ex line 18.  

This is due to C<package AR_Type>, the package already declared
and in I<C<mem>ory>>, being I<ignored> by Perl's C<use> statement
because some I<Perl-specific>, I<"internal flag"> is not set for
C<package Ar_Type>.  The first C<use mem> causes this flag, normally
set with the path of the of a C<use>d file, to be set with the
containing file path and an added comment, containing the line number.

This tells perl to use the definition of the package that is already
in C<mem>ory.

=over

I<and>

=back

=item 

Third, instead of dropping the 1st "C< use mem >", you drop (or comment out) the 2nd usage in the above example, you get:

  Bareword "ARRAY" not allowed while "strict subs" 
    in use at /tmp/ex line 27.
  syntax error at /tmp/ex line 27, near "ARRAY \"
  Bareword "ARRAY" not allowed while "strict subs" 
    in use at /tmp/ex line 30.
  Bareword "ARRAY" not allowed while "strict subs" 
    in use at /tmp/ex line 31.
  Execution of /tmp/ex aborted due to compilation errors. 


This happens because when C<use Xporter> is called, the 
contents of C<@EXPORT> is not known.  Even with the assignment
to C<@EXPORT>, the "C<@EXPORT=qw(ARRAY)>" being right above
the C<use Exporter> statement.  Similarly to the first error, above,
Perl doesn't use the value of C<@EXPORT> just above it.  Having
C< use mem > in the second position forces Perl to put the assignment
to @EXPORT in C< mem >ory, so that when C< use Exporter > is called, 
it can pick up the name of C<ARRAY> as already being "exported" and
B<defined>.  

Without C<use mem> putting the value of C<@EXPORT> in C<mem>ory, 
C<ARRAY> isn't defined, an you get the errors shown above.

=back

=head2 Summary

The first usage allows 'C<main>' to find C<package Ar_Type>, I<already in 
C<mem>ory>.

The second usage forces the definition of 'C<ARRAY>' into C<mem>ory so
they can be exported by an exporter function.

In B<both> cases, C<mem> allows your already-in-C<mem>ory code to 
be used.  Thsi allows simplified programming and usage without knowledge
of or references to Perl's internal-flags or internal run phases.


=head1 SEE ALSO

See L<Xporter> for more help with exporting features from your modules, or
the older L<Exporter> for the cadillac of exporting that will do everything you want (and a bit more). See L<P> for more details about 
the generic print operator that is actually B<user friendly>, and see L<Types::Core> for a more complete treatment of the CORE Types (with helpers for other perl data types besides  C<ARRAY>'s.



=cut

