#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk

package meta 0.014;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

use Carp;

# Hackery to make warnings::warnif callable from XS, on perls too old to have
# warnif_at_level
$^V ge v5.28 or
   *warnif_trampoline = sub { warnings::warnif(@_); };

=head1 NAME

C<meta> - meta-programming API

=head1 SYNOPSIS

=for highlighter language=perl

   use v5.14;
   use meta;

   my $metapkg = meta::get_package( "MyApp::Some::Package" );

   $metapkg->add_symbol(
      '&a_function' => sub { say "New function was created" }
   );

   MyApp::Some::Package::a_function();

=head1 DESCRIPTION

This package provides an API for metaprogramming; that is, allowing code to
inspect or manipulate parts of its own program structure.  Parts of the perl
interpreter itself can be accessed by means of "meta"-objects provided by this
package.  Methods on these objects allow inspection of details, as well as
creating new items or removing existing ones.

The intention of this API is to provide a nicer replacement for existing
tricks such as C<no strict 'refs'> and using globrefs, and also to be a more
consistent place to add new abilities, such as more APIs for inspection and
alteration of internal structures, metaprogramming around the new C<'class'>
feature, and other such uses.

This module should be considered B<experimental>; no API stability guarantees
are made at this time. Behaviour may be added, altered, or removed in later
versions. Once a workable API shape has been found, it is hoped that this
module will eventually become dual-life and shipped as part of Perl core, as
the implementation for PPC 0022. See the link in the L</SEE ALSO> section.

This module attempts to find a balance between accurately representing
low-level concepts within the current implementation of the Perl interpreter,
while also providing higher-level abstractions that provide useful behaviour
for code that uses it. One place this can be seen is the lower-level
L</list_globs> method, which directly maps to the way that GVs are stored in
symbol table stashes but requires the user to be aware of the GV-less
optimisised storage of CVs, as compared to the higher-level L</list_symbols>
method which provides an abstraction over this complication and presents the
more useful but less accurate impression of separately named symbols that
neatly map to their values.

I<Since version 0.003_002> all the entry-point functions and constructors in
this module will provoke warnings in the C<meta::experimental> category. They
can be silenced by

   use meta;
   no warnings 'meta::experimental';

I<Since version 0.005> the various C<can_...>-prefixed variant accessor
methods print deprecation warnings. They are likely to be removed soon.

=cut

=head1 FUNCTIONS

=head2 get_package

   $metapkg = meta::get_package( $pkgname );

Returns a metapackage reference representing the given package name, creating
it if it did not previously exist.

An alternative to C<< meta::package->get >> in a plain function style.

=head2 get_this_package

   $metapkg = meta::get_this_package;

I<Since version 0.002.>

Returns a metapackage reference representing the package of the code that
called the function.

Useful for performing meta-programming on the contents of a module during its
C<BEGIN> or loading time. Equivalent to but more efficient than the following:

   meta::get_package(__PACKAGE__)

=head2 for_reference

   $metasym = meta::for_reference( $ref );

I<Since version 0.007.>

Returns a metasymbol reference representing the glob, variable or subroutine
that is pointed to by the given reference.

Note that passing in a reference to a symbol table hash ("stash") does not
result in a metapackage. For that you will have to call L</get_package> or
similar.

=cut

=head1 METHODS ON C<meta::package>

=head2 get

   $metapkg = meta::package->get( $pkgname );

I<Since version 0.003_001.>

Returns a metapackage reference representing the given package name, creating
it if it did not previously exist.

An alternative to C<meta::get_package> in an object constructor style.

=head2 is_class

   $bool = $metapkg->is_class;

I<Since version 0.009.>

Returns true if on a version of Perl that supports C<use feature 'class'>, and
the package being represented is a real C<class> created by that feature.
False for regular packages, and always false on earlier versions of Perl
before that feature was introduced.

=head2 name

   $name = $metapkg->name;

Returns the name of the package being represented.

=head2 get_glob

   $metaglob = $metapkg->get_glob( $name );

Returns a metaglob reference representing the given symbol name within the
package, if it exists. Throws an exception if not.

=head2 try_get_glob, can_glob

   $metaglob = $metapkg->try_get_glob( $name );
   $metaglob = $metapkg->can_glob( $name );

Similar to L</get_glob> but returns undef if the glob does not exist.

=head2 list_globs

   @metaglobs = $metapkg->list_globs;

I<Since version 0.005.>

Returns a list of all the globs in the package that may refer to symbols (i.e.
not subpackages). They are returned in no particular order.

For a more convenient return value form, see also L</list_symbols>.

=head2 list_subpackage_globs

=head2 list_all_globs

   @metaglobs = $metapkg->list_subpackage_globs;
   @metaglobs = $metapkg->list_all_globs;

I<Since version 0.005.>

Returns a list of all the globs in the package that refer to subpackages, or
all globs, including subpackages. They are returned in no particular order.

For a more convenient return value form, see also L</list_subpackages>.

=head2 get_symbol

   $metasym = $metapkg->get_symbol( $name );

Returns a metasymbol reference representing the given symbol name within the
package. The symbol name should include the leading sigil; one of the
characters C<*>, C<$>, C<@>, C<%> or C<&>. Throws an exception if the symbol
does not exist.

=head2 try_get_symbol, can_symbol

   $metasym = $metapkg->try_get_symbol( $name );
   $metasym = $metapkg->can_symbol( $name );

Similar to L</get_symbol> but returns undef if the symbol does not exist.

=head2 add_symbol

   $metasym = $metapkg->add_symbol( $name, $valueref );

Creates a new symbol of the given name in the given package. The new symbol
will refer to the item given by reference, whose type must match the sigil
of the symbol name. Returns a metasymbol reference as per L</get_symbol>. If
a symbol already existed of the given name then an exception is thrown.

I<Note> that this does not create a copy of a variable, but stores an alias
to the referred item itself within the symbol table.

   $metapkg->add_symbol( '@things', \my @array );

   push @array, "more", "values";
   # these values are now visible in the @things array

If adding a scalar, array or hash variable, the C<$valueref> argument is
optional. If not provided then a new, blank variable of the correct type will
be created.

=head2 get_or_add_symbol

   $metasym = $metapkg->get_or_add_symbol( $name, $valueref );

I<Since version 0.003_003.>

Similar to L</get_symbol> but creates a new symbol if it didn't already exist
as per L</add_symbol>.

Note that if the symbol did already exist it is returned and C<$valueref> will
be ignored. The symbol will not be modified in that case to point to the value
referred to instead.

=head2 remove_symbol

   $metapkg->remove_symbol( $name );

Removes a symbol of the given name from the given package. If the symbol was
the last item in the glob then the glob too is removed from the package. If
the named symbol did not previously exist then an exception is thrown.

To only conditionally remove a symbol if it already exists, test for it first
by using L</try_get_symbol>:

   $metapkg->try_get_symbol( '$variable' ) and
      $metapkg->remove_symbol( '$variable' );

=head2 list_symbols

   %sub_metasyms = $metapkg->list_symbols;
   %sub_metasyms = $metapkg->list_symbols( sigils => $filter );

I<Since version 0.006.>

Returns an even-sized key/value list containing the symbols within the given
package instance. Each symbol is returned as a pair, with its sigil-prefixed
basename first, followed by a metasymbol instance representing it. Since the
sigil-prefixed names must be unique, it is convenient to assign this list into
a hash. The symbols are returned in no particular order.

If the optional C<sigils> named parameter is given, it should be a string of
possible symbol sigils (the characters C<$>, C<@>, C<%> or C<&>). In this
case, only symbols whose sigil is present in this string will be returned.

=head2 list_subpackages

   %sub_metapkgs = $metapkg->list_subpackages;

I<Since version 0.006.>

Returns an even-sized key/value list containing the immediate sub-packages of
the given package instance. Each sub-package is returned as a pair, with its
basename first (minus the "::" suffix), followed by a metapackage instance
representing it. Since the names of each sub-package must be unique, it is
convenient to assign this list into a hash. The sub-packages are returned in
no particular order.

=cut

# Named param handling is a lot easier in pureperl
sub meta::package::list_symbols
{
   my ( $self, %params ) = @_;
   my $sigils = delete $params{sigils};
   keys %params and
      croak "Unrecognised named parameters to meta::package::list_symbols: " . join( ", ", sort keys %params );
   return meta::package::_list_symbols( $self, $sigils );
}

=head2 add_named_sub

   $metasub = $metapkg->add_named_sub( $name, $code );

I<Since version 0.008.>

A convenient shortcut for adding a subroutine symbol and setting the subname
of the newly-added sub. Equivalent to calling L</add_symbol> and then
L</set_subname> on its result, but more efficient as it does not have to
create a separate fake GV to store the subname in.

Note that C<$name> should be given as a barename, without the leading C<&>
sigil.

=cut

=head1 METHODS ON METASYMBOLS

=head2 is_glob, is_scalar, ...

   $bool = $metasym->is_glob;
   $bool = $metasym->is_scalar;
   $bool = $metasym->is_array;
   $bool = $metasym->is_hash;
   $bool = $metasym->is_subroutine;

Returns true if the symbol being referred to is of the given type, or false if
not.

=head2 reference

   $ref = $metasym->reference;

Returns a regular Perl reference to the symbol being represented.

=cut

=head1 METHODS ON C<meta::glob>

=cut

@meta::glob::ISA = qw( meta::symbol );

=head2 get

   $metaglob = meta::glob->get( $globname );

I<Since version 0.003_001.>

Returns a metaglob reference representing the given symbol from the symbol
table from a fully-qualified name, if it exists. Throws an exception if not.

=head2 try_get

   $metaglob = meta::glob->try_get( $globname );

I<Since version 0.003_003.>

Similar to L</get> but returns undef if the given symbol does not exist.

=head2 get_or_add

   $metaglob = meta::glob->get_or_add( $globname );

I<Since version 0.003_003.>

Similar to L</get> but creates the symbol if it didn't already exist.

=head2 basename

   $name = $metaglob->basename;

Returns the name of the glob I<within its package>.

=head2 get_scalar, get_array, ...

   $metasym = $metaglob->get_scalar;
   $metasym = $metaglob->get_array;
   $metasym = $metaglob->get_hash;
   $metasym = $metaglob->get_code;

Returns a metasymbol reference representing the symbol in the given slot of
the glob, if it exists. Throws an exception if not.

=head2 try_get_scalar, try_get_array, ...

Similar to L</get_scalar>, L</get_array>, etc... but returns undef if the
given slot does not exist.

=cut

=head1 METHODS ON METAVARIABLES

=cut

@meta::variable::ISA = qw( meta::symbol );

=head2 value

   $scalar = $metavar->value;
   @array  = $metavar->value;
   %hash   = $metavar->value;

   $count = scalar $metavar->value;

Returns the current value of the variable, as if it appeared in regular Perl
code.

=cut

=head1 METHODS ON METASUBROUTINES

=cut

@meta::subroutine::ISA = qw( meta::symbol );

=head2 is_method

   $bool = $metasub->is_method;

I<Since version 0.009.>

Returns true if on a version of Perl that supports C<use feature 'class'>, and
the subroutine being represented is a real C<method> created by that feature.
False for regular C<sub>-based subroutines, and always false on earlier
versions of Perl before that feature was introduced.

=head2 subname

   $name = $metasub->subname;

Returns the (fully-qualified) name of the subroutine.

=head2 set_subname

   $metasub = $metasub->set_subname( $name );

I<Since version 0.007.>

Sets a new name for the subroutine.

If C<$name> is not fully-qualified (i.e. does not contain a C<::> sequence),
then the package name of the caller is used to create the fully-qualified name
to be stored.

=head2 prototype

   $proto = $metasub->prototype;

Returns the prototype of the subroutine.

=head2 set_prototype

   $metasub = $metasub->set_prototype( $proto );

I<Since version 0.007.>

Sets a new prototype for the subroutine.

Returns the C<$metasub> instance itself to allow for easy chaining.

=head2 signature

   $metasig = $metasub->signature;

I<Since version 0.010.>

If on Perl version 5.26 or above and the subroutine has a signature, returns
an object reference representing details about the signature. This can be
queried using the methods below. If the subroutine does not use a signature
(or on Perl versions before 5.26) returns C<undef>.

=cut

=head1 METHODS ON SUBROUTINE METASIGNATURES

=head2 mandatory_params

   $n = $metasig->mandatory_params;

Returns the number of parameters that are mandatory (i.e. do not have a
defaulting expression). This is the minimum number of argument values that
must be passed to any call of this function and does not count a final slurpy
parameter.

Note that the implicit C<$self> parameter to a C<method> subroutine is
included in this count. This count will always be at least 1 on such a method.

=head2 optional_params

   $n = $metasig->optional_params;

Returns the number of parameters that are optional (i.e. have a defaulting
expression).

=head2 slurpy

   $slurpy = $metasig->slurpy;

Returns the sigil character associated with the final slurpy parameter if it
exists (i.e. C<%> or C<@>), or C<undef> if no slurpy parameter is defined.

=head2 min_args

=head2 max_args

   $n = $metasig->min_args;

   $n = $metasig->max_args;

Returns the minimum or maximum number of argument values that can be passed to
a call to this function. C<min_args> is the same as C<mandatory_params> but is
offered as an alias in case the data model ever changes. C<max_args> will be
C<undef> if the function uses a slurpy final parameter.

=cut

=head1 TODO

=over 4

=item

Access to the new parts of API introduced by Perl 5.38 to deal with classes,
methods, fields.

=back

=cut

=head1 SEE ALSO

L<PPC 0022 "metaprogramming"|https://github.com/Perl/PPCs/blob/main/ppcs/ppc0022-metaprogramming.md>

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
