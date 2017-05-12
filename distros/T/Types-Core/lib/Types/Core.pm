#!/usr/bin/perl 
use warnings; use strict;
# vim=:SetNumberAndWidth
=encoding utf-8

=head1 NAME

Types::Core - Core types defined as tests and literals (ease of use)

=head1 VERSION

Version "0.1.8";

=cut


{	package Types::Core;

	use strict;
	use warnings;
	use mem;
	our $VERSION='0.1.8';

# 0.1.8 - remove reference created during development, but not needed
#       - in final version, in t04.t in the testing directory
# 0.1.7 - Attempt to fix a parsing problem in 5.8.9
# 0.1.6 - Needed to split a statement that parsed in a different order under
#         5.8.x
# 0.1.5 - Added code and test case to handle type-named classes
# 			- use Scalar::Utils for blessed and 'ref' if available.
# 0.1.4 - Add BUILD_REQ for more modern Ext:MM
# 0.1.3 - investigate fails on perl 5.12.x: 
# 				- changed prototypes on single arg tests to use '$' instead of '*';
#					- changed test to use parens around unary ops (needed in 5.12 & before)
#					- tested back to 5.8.9 ( & remove version restriction "use 5.12").
# 			- added tests for CODE & REF
# 			- clarified true/false returned values
# 0.1.2 - Write tests to verify solo string equality, returning $var on true,
# 				capturing undef and returning false;
# 			- doc updates
# 0.1.1 - move to using Xporter so EXPORT_OK works w/o deleting defaults
# 			- narrow focus of module -- Default to: Basic types, Ehv &
# 				possible addon of "blessed", "typ"
#	0.1.0 - regularized some naming (Type->type cf. ref; Ref->ref, cf ref) in
#	        function names; modularized/functionized type checks
#	      - Made previous True/False values return the original value for True
#
#	TODO: - conditionalize usage of P::P as we are not "Using it" it won't
#	        flag a 'compile-time' error and late runtime is not best time
#	        to rely on something not there
#
# 0.0.6 - Add ability to use Scalar::Util 'reftype' to determine which
# 				of the base types something is (sans classes).  Fall back
# 				to pattern matching if it isn't available.
# 		  - Add IO & GLOB to fill out basic type representation
# 		  - remove obsolute function calls prior to publishing;
# 0.0.5	-	Added type_check function
# 0.0.4 - add RefInit 
# 0.0.3 - add SCALAR test
# 			- code simplification
# 0.0.2 - Export EhV by default (EXPORT_OK doesn't work reliably)
#}}}	

	our (@TYPES, @EXPORT, @EXPORT_OK, %type_lens);
	BEGIN {
		@TYPES			= qw(ARRAY CODE GLOB HASH IO REF SCALAR);
		%type_lens	= map { ($_,  length $_ ) } @TYPES;
#		@EXPORT			= (@TYPES, q(EhV)); 	@EXPORT_OK	= ( qw(typ blessed) );
	}
  use mem(@EXPORT=(@TYPES,qw(EhV )), 
          @EXPORT_OK=qw(typ blessed));	

	# MAINT NOTE: this module must not "use P" (literally _use_) 
	#  						as "P" needs to use this mod (or dup the functionality)
	

	sub subProto($) { my $subref = $_[0];
		use B ();
		CODE($subref) or die "subProto: expected CODE ref, not " . 
													((ref $subref) || "(undef)");
		B::svref_2object($subref)->GV->PV;
	}

	use constant shortest_type		=> 'REF';
	use constant last_let_offset	=> length(shortest_type)-1;

	our $Use_Scalar_Util;

	BEGIN {
		# see if we have some short-cuts available
		#
		eval { require Scalar::Util };
		$Use_Scalar_Util = !$@;

		if ($Use_Scalar_Util) {

			eval '# line ' . __LINE__ .' '. __FILE__ .' 
			sub _type ($) { Scalar::Util::reftype($_[0]) }
			sub _isatype ($$) { 
				(_type($_[0]) || "") eq ( $_[1] || "") ? $_[0] : undef };
			sub blessed ($) { Scalar::Util::blessed($_[0]) ? $_[0] : undef }';

			$@ && die "_isatype eval(1): $@";

		} else {
				
			eval '# line ' . __LINE__ .' '. __FILE__ .' 
				sub _type ($) {
					my $end = index $_[0], "(";
					return undef unless $end > '. &last_let_offset .';
					my $start	= 1+rindex($_[0], "=", $end);
					substr $_[0], $start, $end-$start; 
				}
					
				sub _isatype($$) {
					my ($var, $type) = @_;
					ref $var && (1 + index($var, $type."(" )) ? $var : undef;
				}

				sub blessed ($) { my $arg = $_[0]; my $tp;
					my $ra = ref $arg;
					$ra && !exists $type_lens{$ra} ? $arg : do {
						my $len = $type_lens{$ra};
						$ra."=" eq substr ("$arg", 0, $len+1) ? $arg : undef };
				}
				';		#end of eval
			$@ && die "_isatype eval(2): $@";
		}
	}

	sub isatype($$) {goto &_isatype}
	sub typ($) {goto &_type}
	sub type($) {goto &_type}

	
=head1 SYNOPSIS


  my @ref_types = (ARRAY CODE GLOB HASH IO REF SCALAR);
  my $ref = $_[0];
  P "Error: expected %s", HASH unless HASH $ref;

Syntax symplifier for type checking.

Allows easy, non-quoted usage of types as literals, and
allows the standard type names to be used as true/false
check routines of references.


=head1 USAGE

=over

B<C<TYPE <Ref>>>  -  Check if I<Ref> has underlying type, I<TYPE>

B<C<TYPE>>  -  Literal usage equal to itself


=back

=head1 Example

  printf "type = %s\n", HASH if HASH $var;

Same as:

  printf "type = %s\n", 'HASH' if ref $var eq 'HASH';)

=head1 DESCRIPTION

For the most basic functions listed in the Synopsis, they take
either 0 or 1 arguments.  If 1 parameter, then they test it
to see if the C<ref> is of the given I<type> (blessed or not).
If false, I<C<undef>> is returned, of true, the ref, itself is returned.

For no args, they return literals of themselves, allowing the 
named strings to be used as Literals w/o quotes.

=head1 More Examples

=head4 Initialization

  our %field_types = (Paths{type => ARRAY, ...});

=head4 Flow Routing

    ...
    return statAR_2_Ino_t($path,$arg)    if $ref_arg eq ARRAY;
    return stat_t_2_Ino_t($path, $arg)   if $ref_arg eq 'stat_t' }
  else { _path_2_Ino_t($path) }

=head4 Data Verification

  sub Type_check($;$) { ...
    if (ARRAY $cfp) { 
      for (@$cfp) { 
        die P "Field %s does not exist", $_ unless exists $v->{$_}; 
        my $cls_ftpp = $class."::field_types"; 
        if (HASH $cls_ftpp) { 
          if ($cls_ftpp->{type} eq ARRAY) {  ...

=head4 Param Checking

  sub popable (+) { 
    my $ar=$_[0]; 
    ARRAY $ar or die P "popable only works with arrays, got %s", ref $ar; 

=head4 Return Value Checks and Dereference Protection

  my $Inos = $mp->get_sorted_Ino_t_Array; 
  return undef unless ARRAY $Inos and @$Inos >= 2;

=cut 

BEGIN {     # create the type functions...
	eval '# line ' . __LINE__ .' '. __FILE__ .'
		sub ' . $_ . ' (;*) {	@_ ? isatype($_[0], '.$_.') : '.$_.' } '
		for @TYPES;
}


=head1 Helper/Useful shorthand Functions 


     EhV $hashref, FIELDNAME;     # Exist[in]hash? Value : undef

=over

If fieldname exists in the HASH pointed to by hashref, return the value,
else returns undef.

=back

     typ REF;                     #return underlying type of REF

=over

Just as c<ref> returns the name of the package or class of a reference,
it had to start out with a reference to one of the basic types.
That's the value returned by C<typ>.  Note: use of this function
violates object integrity by "peeking under the hood" at how class
is implemented.  

=back

    blessed REF;                #is REF blessed or not?

=over

Included for it's usefulness in type checking.  Similar functionality
as implemented in L<Scalar::Util> (uses C<Scalar::Util> if available,
though it is not needed).

=back


=head1 EhV Example

In order to prevent automatic creation of variables when accessed
or tested for C<undef>, (i.e. autovivification), one must test
for existence first, before attempting to read or test the
'defined'-ness of the value.

This results in a 2 step process to retrive a value:

  exists $name{$testname} ? $name{testname}:undef;

If you have multiple levels of hash tables say retrieving SSN's
via {$lastname}{$firstname} in object member 'name2ssns' but
don't know if the object member is valid or not, you could have
nested code:

  my $p=$this;
  if (exists $p->{name2ssns}) {
    $p=$p->{name2ssns};
    if (exists $p->{$lastname}) {
      $p=$p->{$lastname};
      if (exists $p->{$firstname}) {
        return $p->{$firstname};
      }
    }
  }
  return undef;

Instead EhV saves 1 step.  Instead of having to test then
reference the value to return it, it returns the value if 
it exists, else it returns C<undef>.  Thus, the above could
be written:

  my $p=$this;
  return $p = EhV $p, name2ssns      and
             $p = EhV $p, $lastname  and 
                  EhV $p, $firstname;

This not only saves coding space & time, but allows faster
comprehension of what is going on (presuming familiarity 
with C<EhV>).  
      
=cut

	sub EhV($*) {	my ($arg, $field) = @_;
		(HASH $arg) && defined $field && exists $arg->{$field} ? 
																						$arg->{$field} : undef
	}


	use Xporter;

1}

=head3 Compatibility Note with Perl 5.12.5 and earlier

In order for earlier perls to parse things correctly parentheses may be
needed if unrelated arguments follow the B<type> tests.  

=cut 

# vim: ts=2 sw=2
