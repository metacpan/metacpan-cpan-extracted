package Tie::Util;

use 5.008;

$VERSION = '0.04';

# B doesn't export this. I *hope* it doesn't change!
use constant SVprv_WEAKREF => 0x80000000; # from sv.h

use Exporter 5.57 'import';
use Scalar::Util 1.09 qw 'reftype blessed weaken';

@EXPORT = qw 'is_tied weak_tie weaken_tie is_weak_tie tie tied';
@EXPORT_OK = 'fix_tie';
%EXPORT_TAGS = (all=>[@EXPORT,@EXPORT_OK]);

{
	my ($ref, $class);
	sub _underload($) {
		$ref = shift;
		my $type = reftype $ref;
		# This assumes that no one is overloading without loading
		# overload.pm.  I suppose I could  change  this  to  call
		# UNIVERSAL::can($ref, "($sigil\{}") (at the risk of trig-
		# ering  negative  reactions  from  OO-purists  perusing
		# this code :-).
		if(defined blessed $ref && $INC{'overload.pm'}) {
			my $sigil = $type eq 'GLOB' || $type eq 'IO' ? '*'
			           :$type eq 'HASH'                  ? '%'
			           :$type eq 'ARRAY'                 ? '@'
			           :                                   '$';
			if(defined overload::Method($ref,"$sigil\{}")) {
				$class = ref $ref;
				bless $ref;
			}
		}
		return $ref;
	}
	sub _restore() {
		defined $class and bless $ref, $class;
		undef $ref, undef $class
	}
}

sub expand($) {
	local *_ = \do{my $x = shift};
	my $done_type;
	s<<<<(.*?)>>>><
		my $code = $1;
		my $type_decl = '';
		unless($done_type++) {
			$code =~ /\*(?:(\$\w+)|\{(.*?)})/;
			$type_decl = "my \$type = reftype " . ($1||$2);
		}
		my $subst = "
			$type_decl;
			if(\$type eq 'GLOB' || \$type eq 'IO') {
				$code
			} elsif(\$type eq 'HASH') {
		";
		(my $copy = $code) =~ y @*@%@;
		$subst .= qq!
				$copy
			} elsif(\$type eq 'ARRAY') {
		!;
		($copy = $code) =~ y ~*~@~;
		$subst .= "
				$copy
			} else {
		";
		$code =~ y&*&$&;
		"$subst$code}";
	>gse;
#local $SIG{__WARN__} = sub { warn shift;die $_ };
	eval "$_}1" or die $@, "\n", $_;
#warn $_;
}

# This is what I first intended, but I realised that a to:: package allowed
# a weak tie as well, without requiring Yet Another function.
#expand<<'}';
#sub tie_to (\[%$@*]$) {
#	my ($var, $obj) = @_;
#	my $class = _underload $var;
#	<<<tie *$var, __PACKAGE__, $obj;>>>
#	_restore;
#	$obj
#}

#*TIEARRAY = *TIESCALAR = *TIEHANDLE = *TIEHASH = sub { $_[1] };
*to'TIEARRAY = *to'TIESCALAR = *to'TIEHANDLE = *to'TIEHASH = sub { $_[1] };


# :lvalue makes the following sub return the same scalar, as is evidenced
# by the following one-liner:
#
# perl -MScalar::Util=refaddr -le 'print refaddr \sub:lvalue { \
# print refaddr \my $x; $x}->()'
#
# (Remove the :lvalue and you get two different refaddrs.)

expand<<'}';
sub tie(\[%$@*]$@):lvalue  {
	my($var,$class,@args) = @_; _underload $var;
#warn "$class: $args[0]";
	my $ref_thereto;
	<<<$ref_thereto =
		\tie *$var, $class,
			$class eq 'to'
			? $dummy ||= bless\my $dummy
			: @args;>>>
	_restore;
	$$ref_thereto = $args[0], if $class eq 'to';
	$$ref_thereto;
}

expand<<'}';
sub is_tied (\[%$@*]) {
	my ($var) = @_;
	my $class = _underload $var;
	<<<defined CORE::tied *$var and _restore, return !0;>>>
        # If tied returns undef, it might still be tied, in which case all
	# tie methods will die.
	local *@;
	eval {
		if( $type eq 'GLOB' || $type eq 'IO' ){
			no warnings 'unopened';
			()= tell $var
		} elsif($type eq 'HASH') {
			#()= %$var # We can't use this, because it might
			           # be an untied hash with a stale tied
			           # element, and we could get a
			           # false positive.
			()= scalar keys %$var
		} elsif($type eq 'ARRAY') {
			#()= @$var # same here
			()= $#$var;
		} else {
			my $dummy = $$var
		}
	};
	_restore;
	return !!$@;
}

sub weak_tie(\[%@$*]$@):lvalue{
	my($var,$class,@args) = @_;
	my $ref =\ &tie($var, $class, @args);
	weaken $$ref;
	$$ref;
}

expand<<'}';
sub weaken_tie(\[%@$*]){
	my $var = _underload shift;
	my $obj;
	<<<$obj = CORE::tied *$var;>>>
	if(!defined $obj) {
		_restore, return
	}
	# I have to re-tie it, since 'weaken tied' doesn't work.
	local *{ref($obj).'::UNTIE'};
	<<<weaken CORE::tie *$var, to => $obj>>>;
	_restore, return;
}

expand<<'}';
sub is_weak_tie(\[%@$*]){
	return undef unless &is_tied($_[0]);
	_underload $_[0];
	<<<
	 _restore,return !1 if not defined reftype CORE::tied *{$_[0]};
	>>>

	# We have to use B here because 'isweak tied' fails.

# From pp_sys.c in the perl source code:
#	    /* For tied filehandles, we apply tiedscalar magic to the IO
#	       slot of the GP rather than the GV itself. AMS 20010812 */
	my $thing = shift;
	$type eq 'GLOB' and $thing = *$thing{IO};
	_restore;

	exists & svref_2object or require(B), B->import('svref_2object');
	for(svref_2object($thing)->MAGIC) {
		$_->TYPE =~ /^[qPp]\z/ and
			return !!($_->OBJ->FLAGS & SVprv_WEAKREF);
	}
	die "Tie::Util internal error: This tied variable has no tie magic! Bug reports welcome.";
}

sub tied(\[%@$*]):lvalue{
	return undef unless &is_tied($_[0]);

# From pp_sys.c in the perl source code:
#	    /* For tied filehandles, we apply tiedscalar magic to the IO
#	       slot of the GP rather than the GV itself. AMS 20010812 */
	my $thing = shift;
	_underload $thing;
	reftype $thing eq 'GLOB' and $thing = *$thing{IO};
	_restore;

	exists & svref_2object or require(B), B->import('svref_2object');
	for(svref_2object($thing)->MAGIC) {
		$_->TYPE =~ /^[qPp]\z/ and
			$thing = $_->OBJ->object_2svref;
	}
	$thing or die "Tie::Util internal error: " .
	    "This tied variable has no tie magic! Bug reports welcome.";
	$$thing;
}

sub fix_tie($):lvalue {
 for my $tie ($_[0]) {
  return
   unless ref \$tie eq REF and defined( my $tie_obj = CORE::tied $tie);
  my $pkg = ref $tie_obj;
  length $pkg or $pkg = $tie_obj;
  local *{"$pkg:\:STORE"};
  undef *{"$pkg:\:STORE"};
  eval { $tie = undef }
 }
 $_[0];
}

undef *expand;

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!()__END__()!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 NAME

Tie::Util - Utility functions for fiddling with tied variables

=head1 VERSION

Version 0.04 (beta)

=head1 SYNOPSIS

  use Tie::Util;
  
  use Tie::RefHash;
  tie %hash, 'Tie::RefHash';
  
  $obj = tied %hash;
  tie %another_hash, to => $obj; # two hashes now tied to the same object
  Tie::Util::tie @whatever, to => "MyClass"; # tie @whatever to a class
  
  is_tied %hash; # returns true
  
  $obj = weak_tie %hash3, 'Tie::RefHash';
  # %hash3 now holds a weak reference to the Tie::RefHash object.
  
  weaken_tie %another_hash; # weaken an existing tie
  
  is_weak_tie %hash3; # returns true
  is_weak_tie %hash;  # returns false but defined
  is_weak_tie %hash4; # returns undef (not tied)


=head1 DESCRIPTION

This module provides a few subroutines for examining and modifying
tied variables, including those that hold weak references to the
objects to which they are tied (weak ties).

It also provides tie constructors in the C<to::> namespace, so that you can
tie variables to existing objects, like this:

  tie $var, to => $obj;
  weak_tie @var, to => $another_obj; # for a weak tie

It also allows one to tie a variable to a package, instead of an object
(see below).

=for comment
This is how it would read if perl let me override tie
, if the C<tie> function is imported (which is done by default).

=head1 FUNCTIONS

All the following functions are exported by default, except for C<fix_tie>.
You can choose to
import only a few, with C<use Tie::Util qw'is_tied weak_tie'>, or none at
all, with C<use Tie::Util()>.

=over 4

=item is_tied [*%@$]var

Similar to the built-in L<tied|perlfunc/tied> function, but it returns a
simple scalar.

With this function you don't have to worry about whether the object to 
which a variable is tied overloads its booleanness (like L<JE::Boolean>
I<et al.>), so you can simply write C<is_tied> instead
of C<defined tied>.

Furthermore, it will still return true if it is a weak tie that has gone
stale (the object to which it was tied [without holding a reference count]
has lost all other references, so the variable is now tied to C<undef>),
whereas C<tied> returns C<undef> in such cases.

=item tie [*%@$]var, $package, @args

=item &tie( \$var, $package, @args );

perl did not allow the built-in to be overridden until version 5.13.3, so, 
for older perls, you have to
call this with the C<Tie::Util::> prefix or use the C<&tie(...)> notation.

This is just like the built-in function except that, when called with
'to' as the package, it allows you to tie the variable to I<anything> 
(well,
any scalar at least).  This is
probably only useful for tying a variable to a package, as opposed to an
object.  (Believe it or not, it's just pure Perl; no XS trickery.)

Otherwise the behaviour is identical to the core function.

=item weak_tie [*%@$]var, $package, @args

Like perl's L<tie|perlfunc/tie> function, this calls C<$package>'s tie 
constructor, passing
it the C<@args>, and ties the variable to the returned object.  But the tie
that it creates is a weak one, i.e., the tied variable does not hold a
reference count on the object.

Like C<tie>, above, it lets you tie the variable to anything, not just an
object.

=item weaken_tie [*%@$]var

This turns an existing tie into a weak one.

=item is_weak_tie [*%@$]var

Returns a defined true or false, indicating whether a tied variable is
weakly tied.  Returns C<undef> if the variable is not tied.

NOTE: This used to return true for a variable tied to C<undef>.  Now (as of
version 0.02) it returns false, because the tie does not actually hold a
weak reference; it holds no reference at all.

=item tied [*%@$]var

=item &tied( \$var )

Like perl's L<tied|perlfunc/tied> function, this returns what the variable
is tied to, but, unlike the built-in, it returns the actual scalar that the
tie uses (instead of copying it), so you can, for instance, check to see 
whether the variable is
tied to a tied variable with C<tied &tied($var)>.

As with C<tie>, you need to use the C<Tie::Util::> prefix or the ampersand
form if your perl
version is less than 5.13.3.

=item fix_tie (scalar lvalue expression)

This provides a work-around for a bug in perl that was introduced in 5.8.9
and 5.10.0, but was fixed in 5.13.2: If you assign a reference to a
tied scalar variable, some operators will operate on that reference,
instead of
calling C<FETCH> and using its return value.

If you assign a reference to a tied variable, or a value that I<might> be a
reference to a variable that I<might> be tied, then you can 'fix' the tie
afterwards by called C<fix_tie> on it.  C<fix_tie> is an lvalue function
that returns its first argument after fixing it, so you can replace code
like

  ($var = $value) =~ s/fror/dwat/;

with

  fix_tie( $var = $value ) =~ s/fror/dwat/;

=back

=head1 THE to NAMESPACE

Tie::Util installs tie constructors in the 'to' package to work its magic.
If anyone else wants to release a module named 'to', just let me know and
I'll give you comaint status, as long as you promise not to break 
Tie::Util!

=head1 PREREQUISITES

perl 5.8.0 or later

Exporter 5.57 or later

Scalar::Util 1.09 or later

=head1 BUGS

=over 4

=item *

This module does not provide a single function to access the information 
obscured by 
a tie.  For
that, you can simply untie a variable, access its contents, and re-tie it
(which is fairly trivial with the functions this module already provides).

=back

Please report bugs at L<http://rt.cpan.org/> or send email to
<bug-Tie-Util@rt.cpan.org>.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2007-14 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

=head1 SEE ALSO

The L<tie|perlfunc/tie> and L<tied|perlfunc/tied> functions in the
L<perlfunc> man page.

The L<perltie> man page.

L<Scalar::Util>'s L<weaken|Scalar::Util/weaken> function

The L<B> module.

L<Data::Dumper::Streamer>, for which I wrote two of these functions.
