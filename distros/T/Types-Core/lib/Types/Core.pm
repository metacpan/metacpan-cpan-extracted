#!/usr/bin/perl 
use warnings; use strict;
# vim=:SetNumberAndWidth
=encoding utf-8

=head1 NAME

Types::Core - Core types defined as tests and literals (ease of use)

=head1 VERSION

Version "0.2.7";

=cut


{ package Types::Core;

  use strict;
  use warnings;
  use mem;
  our $VERSION='0.2.7';
  use constant Self => __PACKAGE__;

# 0.2.7		- EhV didn't properly test a blessed HASH (but ErV did)
#					- Added tests for both in t00.t and fixed code
# 0.2.6   -	Removed another spurious ref, this time to Carp::Always.  
# 0.2.5   -	Removed spurious reference to unneeded module in t/t00.t.
#						No other source changes.
# 0.2.4   -	fixed current tests in 5.{12,10,8}.x; added some tests for
#						Cmp function to allow comparing objects and sorting them
#						though still leaving it undocumented, as not sure how
#						useful it is
# 0.2.2   - fixed prototype of isnum, tighted up interface and documented it
#         - fix some test suit failures under older (<5.12) perls
# 0.2.1   - re-add 'type' as OK synonym for 'typ' (both in EXPORT_OK)
# 0.2.0   - Allow isnum to take inferred $_ as param.
# 0.1.10  - Added Cmp function for nested data structs
# 0.1.9   Features:
#         - add ErV supercedes EhV, but also works for arrays (EXPORT)
#         - change EhV proto to support multiply nested refs.
#         - add 'LongFunc' & 'ShortFunc' for name of current function either
#           with Package(Long) or without(Short); (EXPORT_OK)
#         - Add 'mk_array/mkARRAY' + 'mk_hash/mkHASH' optional exports
#         Fixes:
#         - delete unused sub referencing 'B'
#         - PerlDoc updates
# 0.1.8   - (fix) remove reference created during development, but not needed
#         - in final version, in t04.t in the testing directory
# 0.1.7   - Attempt to fix a parsing problem in 5.8.9
# 0.1.6   - Needed to split a statement that parsed in a different order under
#           5.8.x
# 0.1.5   - Added code and test case to handle type-named classes
#         - use Scalar::Utils for blessed and 'ref' if available.
# 0.1.4   - Add BUILD_REQ for more modern Ext:MM
# 0.1.3   - investigate fails on perl 5.12.x: 
#         - changed prototypes on single arg tests to use '$' instead of '*';
#         - changed test to use parens around unary ops (needed in 5.12 & before)
#         - tested back to 5.8.9 ( & remove version restriction "use 5.12").
#         - added tests for CODE & REF
#         - clarified true/false returned values
# 0.1.2   - Write tests to verify solo string equality, returning $var on true,
#           capturing undef and returning false;
#         - doc updates
# 0.1.1   - move to using Xporter so EXPORT_OK works w/o deleting defaults
#         - narrow focus of module -- Default to: Basic types, EhV &
#           possible addon of "blessed", "typ"
# 0.1.0   - regularized some naming (Type->type cf. ref; Ref->ref, cf ref) in
#           function names; modularized/functionized type checks
#         - Made previous True/False values return the original value for True
# 0.0.6   - Add ability to use Scalar::Util 'reftype' to determine which
#           of the base types something is (sans classes).  Fall back
#           to pattern matching if it isn't available.
#         - Add IO & GLOB to fill out basic type representation
#         - remove obsolute function calls prior to publishing;
# 0.0.5   - Added type_check function
# 0.0.4   - add RefInit 
# 0.0.3   - add SCALAR test
#         - code simplification
# 0.0.2   - Export EhV by default 
#}}}  

  # MAINT NOTE: this module must not "use P" (literally _use_) 
  #             as "P" needs to use this mod (or dup the functionality)

  our (@CORETYPES, @EXPORT, @EXPORT_OK, %type_lens);

  BEGIN {
    @CORETYPES  = qw(ARRAY CODE GLOB HASH IO REF SCALAR);
    %type_lens  = map { ($_,  length $_ ) } @CORETYPES;
    @EXPORT     = (@CORETYPES, qw(EhV ErV));  
    @EXPORT_OK  = ( qw( typ   type  blessed 
                        LongSub     ShortSub 
                        LongSubName ShortSubName
                        LongFunc    ShortFunc
                        isnum       Cmp
                        _getClass   _InClass
                        _Obj
												mk_array		mkARRAY
											 	mk_hash			mkHASH
                        )  );
  }

  sub _getClass($) { blessed $_[0] }

  sub _InClass($;$) {
    my $class = shift;
    if (!@_) { return sub ($) { ref $_[0] eq $class } }
    else { return ref $_[0] eq $class }
  }
  sub _IsClass($;$) { goto &_InClass }
                  
  use constant shortest_type    => 'REF';
  use constant last_let_offset  => length(shortest_type)-1;

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
          my $start = 1+rindex($_[0], "=", $end);
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
        ';    #end of eval
      $@ && die "_isatype eval(2): $@";
    }
  }

  sub isatype($$) {goto &_isatype}
  sub typ($) {goto &_type}
  sub type($) {goto &_type}

  
=head1 SYNOPSIS


  my @data_types = (ARRAY CODE GLOB HASH IO REF SCALAR);
  my $ref = $_[0];
  P "Error: expected %s", HASH unless HASH $ref;

Syntax symplifier for type checking.

Allows easy, unquoted use of var types (ARRAY, SCALAR, etc.) 
as literals, and allows standard type names to be used as boolean 
checks of the type of a reference as well as passing through the value
of the reference.  For example: C<HASH $href> will return true
if the reference points to a HASH or a HASH-based object.
For example, "HASH $href" 
check routines of references.


=head1 USAGE

=over

B<C<TYPE <Ref>>>  -  Check if I<Ref> has underlying type, I<TYPE>

B<C<TYPE>>  -  Literal usage equal to itself


=back

=head1 EXAMPLE

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

=head1 MORE EXAMPLES

=head4 Initialization

  our %field_types = (Paths{type => ARRAY, ...});

=head4 Flow Routing

    ...
    my $ref_arg = ref $arg;
    return  ARRAY $ref_arg              ? statAR_2_Ino_t($path,$arg)  :
            InClass('stat_t', $ref_arg) ? stat_t_2_Ino_t($path, $arg) :
            _path_2_Ino_t($path); }

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
    my $ar = $_[0]; 
    ARRAY $ar or die P "popable only works with arrays, not %s", ref $ar; }

=head4 Return Value Checks and Dereference Protection

  my $Inos = $mp->get_sorted_Ino_t_Array; 
  return undef unless ARRAY $Inos and @$Inos >= 2;

=cut 




BEGIN {     # create the type functions...
  eval '# line ' . __LINE__ .' '. __FILE__ .'
    sub ' . $_ . ' (;*) { @_ ? isatype($_[0], '.$_.') : '.$_.' } '
    for @CORETYPES;
}


=head2 Non-instantiating existence checks in references: C<ErV>.

S< >

     ErV $ref, FIELDNAME;        # Exist[in]reference? Value : C<undef>
     ErV $hashref, FIELDNAME;    # Exist[in]hashref?   Value : C<undef>

=over

If fieldname exists in the ref pointed to by the reference, return the value,
else return undef.

=back

=head2 Note: What's EhV? (Deprecated)

=over

  You may see older code using C<EhV>.  M<Types::Core> only had this checker
  for hashes, but given combinations of various references, the more
  general C<ErV> replaced it.

=back


=head1 OPTIONAL FUNCTIONS:  C<typ> & C<blessed>

S< >

     typ REF;                    #return underlying type of REF


Once you bless a reference to an object, its type becomes hidden
from C<ref>.  C<typ> allows you to peek into a class reference to
see the basic perl type that the class is based on.  

Most users of a class won't have a need for that information, 
but a 'friend' of the class might in order to offer helper functions.


    blessed REF;                #test if REF is blessed or not


Included for it's usefulness in type checking.  Similar functionality
as implemented in L<Scalar::Util>. This version of C<blessed>
will use the C<Scalar::Util> version if it is already present.
Otherwise it uses a pure-perl implementation.



=head1 EXAMPLE:  C<ErV>

S< >

To prevent automatic creation of variables when accessed
or tested for C<undef>, (i.e. autovivification), one must test
for existence first, before attempting to read or test the
'defined'-ness of the value.

This results in a 2 step process to retrive a value:

  exists $name{$testname} ? $name{testname} : undef;

If you have multiple levels of hash tables say retrieving SSN's
via {$lastname}{$firstname} in object member 'name2ssns' but
don't know if the object member is valid or not, the safe way
to write this would be:

  my $p = $this;
  if (exists $p->{name2ssns} && defined $p->{name2ssns}) {
    $p = $p->{name2ssns};
    if (exists $p->{$lastname} && defined $p->{$lastname}) {
      $p = $p->{$lastname};
      if (exists $p->{$firstname}) {
        return $p->{$firstname};
      }
    }
  }
  return undef;

C<ErV> saves some steps.  Instead of testing for existence, 'definedness',
and then use the value to go deeper in the structuer, C<ErV> does the
testing and returns the value (or undef) in one step.
Thus, the above could be written:

  my $p = $this;
  return $p = ErV $p, name2ssns      and
             $p = ErV $p, $lastname  and 
                  ErV $p, $firstname;

This not only saves coding space & time, but allows faster
comprehension of what is going on (presuming familiarity 
with C<ErV>). 

Multiple levels of hashes or arrays may be tested in one usage. Example:

  my $nested_refs = {};
  $nested_refs->{a}{b}{c}{d}[2]{f}[1] = 7;
  P "---\nval=%s", ErV $nested_refs, a, b, c, d, e, f, g;
  ---
  val=7

  The current ErV handles around thirty levels of nested hashing.
      
=cut

  BEGIN {
    sub ErV ($*;******************************) { 
      my ($arg, $field) = (shift, shift);
      my $h;
      while (defined $field and
            (($h=HASH $arg) && exists $arg->{$field} or
            ARRAY $arg && $field =~ /^[-\d]+$/ && exists $arg->[$field])) {
        $arg = $h ? $arg->{$field} : $arg->[$field];
        $field = shift, next if @_;
        return $arg;
      }
      return undef;
    }

    sub EhV ($*;******************************) { 
      my ($arg, $field) = (shift, shift);
      while (defined($arg) && typ $arg eq 'HASH' and 
							defined($field) && exists $arg->{$field}) {
				return $arg->{$field} unless @_ > 0;
				$arg		= $arg->{$field};
				$field	= shift;
      }
      return undef;
    }


    sub LongFunc(;$) { (caller (@_ ? 1+$_[0] : 1))[3] }
    sub ShortFunc(;$) { 
      my $f = (@_ ? LongFunc(1+$_[0]) : LongFunc(1) ) || ""; 
      substr $f, (1+rindex $f,':') }

    sub LongSub(;$) { goto &LongFunc }
    sub ShortSub(;$) { goto &ShortFunc }
    sub LongSubName(;$) { goto &LongFunc }
    sub ShortSubName(;$) { goto &ShortFunc }
    
    sub mk_array($) { $_[0] = [] unless q(ARRAY) eq ref $_[0] ; $_[0] }
    sub mkARRAY($) { goto &mk_array }
    sub mk_hash($) { $_[0] = {} unless q(HASH) eq ref $_[0] ; $_[0] }
    sub mkHASH($) { goto &mk_hash }

    # for testing only (EXPERIMENTAL):
    # _Obj - 1 or 2 parms (on top of "objref" ($p))
    ##1st param - name to verify against; verify against objptr by default
    #2nd optional parm = verify against this ref instead of objptr
    #
    sub _Obj($;$) { my $p = shift if ref $_[0] || $_[0] eq Self;
      my $objname = shift;                      # txt name
      my $objref = @_ ? ref $_[0] : ref $p;     # if another parm, chk it as ref
      $objref && $objref eq $objname
    }
  
  }


=head2 MORE OPTIONAL FUNCTIONS C<mk_array> and C<mk_hash>


$<  >

    mk_array $p->ar;

without C<mk_array>, the following generates a runtime error (can't
use an undefined value as an ARRAY reference):

    my $ar;
    printf "items in ar:%s\n", 0+@{$ar};

but using mk_array will ensure there is an ARRAY ref there if there
is not one there already:
    
    my $ar;
    mk_array $ar;
    printf "items in ar:%s\n", 0+@{$ar};

While the above would be solved by initalizing $ar when defined,
expicit initialization might be useful to protect against the same
type of error in dynamically allocated variables.


=head1 UTILITY FUNCTIONS:  C<isnum> & C<Cmp>

S< >

     isnum STR              #return <NUM> if it starts at beginning of STR

     Cmp [$p1,$p2]          # C<cmp>-like function for nested structures
                            # uses C<$a>, C<$b> as default inputs
                            # can be used in sort for well-behaved data
                            # (incompare-able data will return undef)
                            # builtin debug to see where compare fails
#

C<isnum> checks for a number (int, float, or with exponent) at the 
beginning of the string passed in.  With no argument uses C<$_>
as the parameter.  Returns the number with any non-number suffix
stripped off or C<undef> if no num is found at the beginning
of the string.  C<isnum> is an optional import that must be included
via C<@EXPORTS_OK>.  Note: to determine if false, you must use
C<defined(isnum)> since numeric '0' can be returned and would also
evaluate to false.

The existence of C<Cmp> is a B<side effect of testing> needs.  To compare
validity of released functions, it was necessary to recursively 
compare nested data structures.  To support development, debug
output was added that can be toggled on at runtime to see where
a compare fails.

Normally you only use two parameters C<$a> and C<$b> that are references
to the data structures to be compared.  If debugging is wanted,
a third (or first if C<$a> and C<$b> are used) parameter can be 
pass with a non-zero value to enable primitive debug output.

Additionally, if the compare I<fails> and does not return an integer
value (returning C<undef> instead), a 2nd return value can tell you
where in the compare it failed.  To grab that return value,
use a two element list or an array to catch the status, like

  C<my ($result, $err)=Cmp; (pointers passed in C<$a> and C<$b>)

If the compare was successful, it will return -1, 0 or 1 as 'cmp'
does. If it fails, C<$result> will contain C<undef> and C<$err> will
contain a number indicating what test failed.

Failures can occur if Cmp is asked to compare different object with
different refs ('blessed' refname), or same blessed class and different
underlying types.  Unbless values and those in the same classes can
be compared.



=cut

use constant numRE => qr{^ ( 
														[-+]? (?: (?: \d* \.? \d+ ) | 
																			(?: \d+ \.? \d* ) ) 
																			(?: [eE] [-+]? \d+)? ) }x;

sub isnum(;$) { 
	local $_ = @_ ? $_[0] : $_;
	return undef unless defined $_;
	my $numRE = numRE;
	m{$numRE} && return $1;
	undef;
}


sub Cmp (;$$$);
sub Cmp (;$$$) { my $r=0; my $dbg;
  if (@_) {
    $dbg = @_==1 ? $_[0] : @_==3 ? $_[2] : undef;
   ($a, $b) = @_ if @_>1;
  }
	$a="" unless defined $a;
	$b="" unless defined $b;
  require P if $dbg;
  my ($ra, $rb)   = (defined(ref $a)||"", defined(ref $b)||"");
  my ($ta, $tb)   = (defined(type $a) || "", defined(type $b)||"");
  do {  P::Pe("ta=%s, tb=%s", $ta, $tb);
        P::Pe("ra=%s, rb=%s", $ra, $rb) } if $dbg;
  my ($dta, $dtb) = (defined $ta, defined $tb);

  # first handle "values" (neither are a type reference)
  if ($dta && $dtb) {
    $r = isnum($a) && isnum($b)
                    ? $a <=> $b
                    : $a cmp $b;
    P::Pe("isnum, a=%s, b=%s, r=%s", isnum($a), isnum($b), $r) if $dbg;
    return $r } 
  # then handle unequal type references
  elsif ($dta ^ $dtb) { return (undef, 1) } 
  elsif ($dta && $dtb && $ta ne $tb) { return (undef, 2) }

  # now, either do same thing again, or handle differing classes
  # the no-class on either implies no type-ref on either & is handled above
  my ($dra, $drb) = (defined $ra, defined $rb);
  if ($dra ^ $drb) { return (undef, 3) } 
  elsif ($dra && $drb && $ra ne $rb) { return (undef, 4) }

  # now start comparing references: dereference and call Cmp again
  if ($ta eq SCALAR) {
    return Cmp($$a, $$b) }
  elsif ($ta eq ARRAY) {

    P::Pe("len of array a vs. b: (%s <=> %s)", @$a, @$b) if $dbg;
    return $r if $r = @$a <=> @$b;

    # for each member, compare them using Cmp
    for (my $i=0; $i<@$a; ++$i) {
      P::Pe("a->[i] Cmp b->[i]...\0x83", $a->[$i], $b->[$i]) if $dbg;
      $r = Cmp($a->[$i], $b->[$i]);
      P::Pe("a->[i] Cmp b->[i], r=%s", $a->[$i], $b->[$i], $r) if $dbg;
      return $r if $r;
    }
    return 0;   # arrays are equal
  } elsif ($ta eq HASH) {
    my @ka = sort keys %$a;
    my @kb = sort keys %$b;
    $r = Cmp(0+@ka, 0+@kb);
    P::Pe("Cmp #keys a(%s) b(%s), in hashes: r=%s", 0+@ka, 0+@kb, $r) if $dbg;
    return $r if $r;

    $r = Cmp(\@ka, \@kb);
    P::Pe("Cmp keys of hash: r=%s", $r) if $dbg;
    return $r if $r;

    my @va = map {$a->{$_}} @ka;
    my @vb = map {$b->{$_}} @kb;
    $r = Cmp(\@va, \@vb);
    P::Pe("Cmp values for each key, r=%s", $r) if $dbg;
    return $r;
  } else {
    P::Pe("no comparison for type %s, ref %s", $ta, $ra) if $dbg;
    return (undef,5); ## unimplemented comparison
  }
}
    use Xporter;

  
1}

=head1 NOTE on INCLUDING OPTIONAL (EXPORT_OK) FUNCTIONS

Importing optional functions B<does not> cancel default imports 
as this module uses L<Xporter>. To dselect default exports, add
'C<->' (I<minus> or I<dash>) at the beginning of argument list to 
C<Types::Core> as in C<use Types::Core qw(- blessed);>.
See L<Xporter> for more details.

=back

=head3 COMPATIBILITY NOTE: with Perl 5.12.5 and earlier

=over

In order for earlier perls to parse things correctly parentheses are needed
for two or more arguments after a B<ErV> test verb.

=cut 

# vim: ts=2 sw=2 sts=2
