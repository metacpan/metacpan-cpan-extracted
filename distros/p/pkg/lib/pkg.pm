package pkg;

use 5.10.1;
use strict;
use warnings;

our $VERSION = '0.04';

my %opt_nargs = (
    alias     => { n => 0, name => 'alias',   value => 1, tag => 1 },
    noalias   => { n => 0, name => 'alias',   value => 0 },
    strip     => { n => 1, name => 'alias',   tag   => 1 },
    require   => { n => 0, name => 'require', value => 1 },
    norequire => { n => 0, name => 'require', value => 0 },
);

my %mopt_nargs = (
    as           => { n => 1 },
    import       => { n => 0, last => 1 },
    require      => { n => 0, name => 'require', value => 1 },
    norequire    => { n => 0, name => 'require', value => 0 },
    version      => { n => 1 },
    include      => { n => 1 },
    inner        => { n => 0 },
    'only_inner' => { n => 0, value => -1, name => 'inner', tag => 0 },
    exclude      => { n => 1 },
);

sub import {

    # first element of @_ is just us!
    shift;

    return unless @_;

    my $to = caller(0);

    my %opt;

    while (@_) {

        if ( 'ARRAY' eq ref $_[0] ) {

            my %lopt = %opt;
            local @_ = @{ shift @_ };

            unshift @_, \%lopt, \%opt_nargs, qq[global option '-%s': %s];
            &_parse_args;

            unshift @_, $to, \%lopt;
            &_process_pkg;

        }

        elsif ( $_[0] =~ /^-/ ) {

            unshift @_, \%opt, \%opt_nargs, qq[global option '-%s': %s];
            &_parse_args;

        }

        else {
            unshift @_, $to, \%opt;
            &_process_pkg;
            last;
        }

    }

    return;
}

sub _process_pkg {

    my ( $to, $opt ) = ( shift, shift );

    my $package = shift;

    unshift @_, \my %mopt, \%mopt_nargs,
      qq[package "$package": package option '-%s': %s];
    &_parse_args;

    $mopt{require} //= $opt->{require} // 1;

    # flag indicationg everything in @_ is to be passed to pkg->import
    unless ( defined $mopt{import} ) {

        # if first argument is [], duplicate standard behavior:
        # use A ();     => don't call import
        # use A (), 'b' => A->import( 'b' );
        if ( 'ARRAY' eq ref $_[0] && $_[0] && @{ $_[0] } == 0 ) {

            shift;
            $mopt{import} = @_;
        }
        else {

            $mopt{import} = 1;

        }

    }

    # load package; this won't try to use inner packages
    if ( $mopt{require} ) {
        require Class::Load;
        Class::Load::load_class( $package,
            exists $mopt{version} ? { -version => $mopt{version} } : () );
    }

    my @packages = ($package);

    if ( $mopt{inner} ) {

        croak(qq[can't use option "-$_" when looping over inner packages\n])
          for grep { defined $mopt{$_} } qw[ as ];

        pop @packages if $mopt{inner} < 0;

        require Devel::InnerPackage;
        push @packages, Devel::InnerPackage::list_packages($package);
    }

    for my $pkg (@packages) {

        # print STDERR "package $pkg proferred\n";

        next if defined $mopt{include} && !( $pkg ~~ $mopt{include} );
        next if defined $mopt{exclude} && $pkg ~~ $mopt{exclude};

        # print STDERR "package $pkg accepted\n";

        my $alias = $mopt{as} // (
            $opt->{alias}
            ? _dispatch_alias( $opt->{alias}, $pkg )
            : $pkg
        );

        if ( $mopt{import} ) {
            require Import::Into;
            $pkg->import::into( $to, @_ );
        }

        # create alias if requested
        _make_alias( $to, $pkg, $alias )
          if $pkg ne $alias;
    }

    # all done
    return;
}

sub _make_alias {

    my ( $to, $package, $alias ) = @_;

    no strict 'refs';    ## no critic
    *{ join( '::', $to, $alias ) } = sub () { $package };

}

# this gets called as &_parse_args so that it alters
# the called @_ array
sub _parse_args {

    my ( $opts, $attr, $fmt ) = ( shift, shift, shift );

    while ( @_ && $_[0] =~ /^-(.*)/ ) {

        shift;
        my $opt  = $1;
        my $attr = $attr->{$opt};

        _die( $fmt, $opt, 'unknown option' )
          unless defined $attr;

        my $n = $attr->{n};

        _die( $fmt, $opt, 'not enough values' )
          if @_ < $n;

        my $value =
            $n == 0 ? ( exists $attr->{value} ? $attr->{value} : 1 )
          : $n == 1 ? shift(@_)
          :           [ splice( @_, 0, $n ) ];

        if ( $attr->{name} ) {

            $opts->{ $attr->{name} } = $attr->{tag} ? [ $opt, $value ] : $value;
        }

        else {

            $opts->{$opt} = $value;
        }

        last if $attr->{last};
    }

    return;
}

sub _dispatch_alias {

    my ( $name, $arg ) = @{ shift() };
    my $package = shift;

    if ( $name eq 'alias' ) {

        return $arg ? ( $package =~ /([^:]+)$/ )[0] : $package;
    }

    elsif ( $name eq 'strip' ) {

        my %attr = 'HASH' eq ref $arg ? %{$arg} : ( pfx => $arg );

        _die("-strip: no prefix specified\n")
          unless defined $attr{pfx};

        $attr{pfx} = quotemeta( $attr{pfx} );

        my $pfx = $attr{pfx};
        my $sep = defined $attr{sep} ? quotemeta( $attr{sep} ) : '';

        ( my $npkg = $package ) =~ s/^$pfx//;

        # don't return an empty package name
        return $package if $npkg eq '';

        # trim leading separator;
        $npkg =~ s/^:://;
        $npkg =~ s/::/$sep/g;

        return $npkg;
    }

    else {

        _die("internal error");

    }

}

sub _die {

    require Carp;

    my $err = @_ > 1 ? sprintf( shift, @_ ) : $_[0];

    Carp::croak( q[error in use pkg: ], $err );

}

__END__

=head1 NAME

pkg - transparently use packages and inner packages

=head1 SYNOPSIS

  # standard operations
  # works on either inner or normal packages
  # -------------------------------       ----------------
  use pkg 'A';                       #=>  use A;
  use pkg 'A', 'a', 'b';             #=>  use A 'a', 'b';
  use pkg 'A', [];                   #=>  use A ();

  # extra operations

  # default alias for a class package
  use pkg -alias => 'A::B::C';
  C->new(...); #equivalent to A::B::C->new();

  # specific alias for a class package
  use pkg 'A::B::C' => -as => 'ABC';
  ABC->new( ); # equivalent to A:B::C->new;

  # multiple packages
  use pkg [ 'A::B::C' => -as => 'ABC'],
          [ 'A::B'    => -as => 'AB' ];

  # operate on A and its inner packages
  use pkg 'A', '-inner';

  # operate only on the inner packages of A
  use pkg 'A', '-only_inner';

  # operate on A and its inner packages, excluding anything below A::B
  use pkg 'A', -inner, -exclude => qr/^A::B::/;

=head1 DESCRIPTION

B<pkg> extends the standard "use" statement to more transparently
handle inner packages, additionally incorporating some of the
functionality of the B<aliased> and B<use> pragmata with a few extra
twists.

An inner package is one which does not have the same name as the
(fully qualified) module in which it is defined.  For example, if
F<A.pm> contains

  package A;

  sub a { ... }

  package A::B;

  sub ab { ... }

  package A::C;

  sub ac { ... }

  1;

packages C<A::B> and C<A::C> are inner packages.  The B<use> statement
(as well as most pragmata dealing with modules) does not handle inner
packages.  Some, such as B<parent>, do, but require the user (via the
C<-norequire> option) to know if the package is inner or not.

For example, after loading the above module:

  use A;

You could simply call

  A::a();
  A::B::ab();
  A::C::ac();

But, what if package B<A::B> exported B<ab>?  Its import routine is
not automatically called when B<A> is loaded. If you try to do this

  use A::B 'ab';

you'll get an error from Perl as it tries to search for a file named
e.g., F<A/B.pm>.  It doesn't check to see if the C<A::B> package has
been loaded.

Instead, you'd need to do this:

  A::B->import( 'ab' );
  ab();

Or, using B<pkg>:

  use pkg [ 'A' ], [ 'A::B' => qw[ ab ] ];


=head2 Simple Usage

In its simplest form, B<pkg> accepts a I<list> of a package name (I<as
a string>) and its imports.

  use pkg 'A::B', qw( funca funcb );

This loads the package C<A::B> (if necessary) and imports the
functions B<funca> and B<funcb>.  Note that if C<A::B> is an inner
package, the module (file) which contains it must be loaded prior to
this e.g.

  # either of these is sufficient
  use A;
  use pkg 'A';

This needs to be done only I<once> (not every time an inner package
is used). Of course it can be combined with loading C<A::B>:

  use pkg [ 'A' ], [ 'A::B' => qw( funca funcb ) ];

=head2 Controlling imports

There is a subtlety in how the standard B<use> statement handles
empty or non-existent import lists:

   use A;           # call A->import();
   use A 'a', 'b'   # call A->import( 'a', 'b' );
   use A ();        # do *not* call A->import;

This mechanism isn't available to B<pkg> as it cannot tell the difference
between:

   use pkg 'A';
   use pkg 'A', ();

Instead, use C<[]> instead of C<()>:

   use pkg 'A', [];

What if you need to pass a C<[]> to C<< A->import() >>? Use the C<-import>
package option:

  use pkg 'A', -import => [];        #=> use A [];
  use pkg 'A', -import => '-import'; #=> use A '-import';

C<-import> instructs B<pkg> that all remaining arguments should be
passed to the package's B<import> routine.

Note that the following are equivalent

  use A (), 'a';
  use pkg 'A', [], 'a';

and result in

  A->import( 'a' );

=head2 Multiple packages

Multiple packages may be operated on by passing each package's
specifications as separate array references:

  use pkg ['A'], ['A::B', qw( funca funcb ) ];


=head1 OPTIONS

B<pkg> accepts options to modify its behavior.
"Global" options (which affect more than one package) can appear in
multiple places if more than one package is manipulated. Package
specific options always appear directly after the package name and
apply only to that package.

If there's only one package, the syntax is simple.  Global options
occur before the package name.

  use pkg -norequire => 'My::Package' -as => 'MyP';

C<-norequire> is a global option, and C<-as> is a package option.

If more than one package is specified, global options may occur both
outside of the package specifications as well as inside of them. For example,

  use pkg
    -alias =>
    [ 'My::FirstClass' ],
    [ -noalias => 'My::SecondClass' ]
    [ 'My::ThirdClass' => -as => 'ThirdClassIsBetterThanFirst' ]
    -noalias =>
    [ 'My::Library1' ],
    [ 'My::Library2' ],
    [ 'My::Library3' ],
    ;

The options appearing outside of the package specifications affect all
packages which follow.  The options inside a specification affect that
package only.  As shown, some options may be negated, and package options
may override global ones.

=head2 Global Options

=over

=item C<-alias>

=item C<-noalias>

Provide (or don't provide) shortened names for class names.
These are simply the last component of the original name.

The idea is borrowed from the C<aliased> pragma; B<pkg> constructs and
exports a subroutine with the shortened name which returns the fully
qualified name.

For example,

  use pkg -alias => 'A::Long:Class';

  # these are equivalent
  A::Long::Class->new();
  Class->new();

If multiple classes are loaded, no checks are performed to ensure that
the shortened names are unique.  Use the C<-as> package option to
specify specific names.

=item C<-strip>

Created aliases by removing a prefix from the succeeding class names.
The prefix may be specified in one of two ways:

=over

=item C<-strip> I<string>

Remove a leading I<string> from the class names.  All component
separators (C<::>) are also removed.  For example,

  -strip => 'A::C', 'A::C::E::F::G'

results in an alias of C<EFG>.

=item C<< -strip { pfx => I<string>, sep => I<string> } >>

Remove I<prefix> from class names, and replace the class component
separators (C<::>) with the specified string.  After prefix removal,
a leading C<::> sequence is removed.

=back


=item C<-require>

=item C<-norequire>

Try to load (or don't try to load) the packages with
B<Class::Load::load_class>.  If you know that the package is an inner
package and the file containing it has already been loaded, specifying
C<-norequire> can speed things up by not loading B<Class::Load>.

By default packages are loaded (i.e. C<-require>).

=back

=head2 Package Options

=over

=item C<-as> => I<string>

Create an alias named I<string> for the package.  The aliased name must be
a legal subroutine name.

For example,

  use pkg 'A::Long:Class' => -as => 'ALC';

  # these are equivalent
  A::Long::Class->new();
  ALC->new();


=item C<-import>

There's always a chance that a package's import list may be confused with
B<pkg> package options (perhaps it also has a C<-as> option).  To avoid this,
a package's import list may be preceded with the C<-import> option, which
indicates to B<pkg> that all of the following arguments are to be passed
as is to the package's B<import> routine.

  # these are equivalent
  use A ( '-as', 'func1', 'func2' );
  use pkg 'A' => -import => ( '-as', 'func1', 'func2' );

=item C<-require>

=item C<-norequire>

This has the same functionality as the similarly named global options, but
as a package option may be placed after the package name for
aesthetics.

=item C<-inner>

In addition to the package, process any of its currently loaded inner
packages.  Inner packages are discovered via B<Devel::InnerPackage>,
and must fall within the "hierarchy" of the package.  For example,
given a module with the following contents:

  package A;
  sub a {}

  package A::B;
  sub ab {}

  package B;
  sub b {}

C<A::B> is an inner package of C<A>, but C<B> is not.  Inner packages
must have defined symbols, otherwise they will not be identified.

=item C<-only_inner>

Similar to C<-inner>, but I<only> the inner packages are processed,
not the package itself.

This I<does not> affect whether the package is loaded; this is controlled
by the C<-require> option.

=item C<-include> I<specification>

Check the package name against the I<specification> using the smart match
operator (C<~~>) and ignore it if it does not match.  If C<-inner> or
C<-only_inner> are specified, inner packages are also checked.

This I<does not> affect whether the package is loaded; this is controlled
by the C<-require> option.

This is most useful when either C<-inner> or C<-only_inner> is specified.

=item C<-exclude> I<specification>

Check the package name against the I<specification> using the smart
match operator (C<~~>) and ignore it if it matches.  The C<-exclude> match is
processed after C<-include> if both are specified.   If C<-inner> or
C<-only_inner> are specified, inner packages are also checked.

This I<does not> affect whether the package is loaded; this is controlled
by the C<-require> option.

This is most useful when either C<-inner> or C<-only_inner> is specified.

=item C<-version> => I<version>

Specify the minimum acceptable version of the package.

=back


=head1 DIAGNOSTICS

=over

=item C<< global option '%s': unknown option >>

The specified option wasn't recognized as a global option.

=item C<< package option '%s': unknown option >>

The specified option wasn't recognized as a package option.

=item C<< option '%s': cannot be negated >>

An illegal negation of the specified option was specified.

=item C<< option '%s': not enough values >>

The specified option required more values than was specified.

=item C<< can't use option "%s" when looping over inner packages >>

The specifed option cannot be used in conjunction with C<-inner> or
C<-only_inner>.

=item C<< -strip: no prefix specified >>

The C<-strip> option requires an argument specifying the prefix to
remove.

=item C<< internal error >>

Something really bad happened.


=back


=head1 IMPLEMENTATION

B<pkg> does very little on its own.  It uses the following modules:

=over

=item B<Class::Load>

B<Class::Load::load_class> is used to load the package.  It also takes
care of checking package versions.

=item B<Import::Into>

This is used to call a package's import routine

=item B<aliased>

This provided the inspiration for the aliasing implementation.

=item B<Devel::InnerPackages>

Discover a package's inner self.

=back


=head1 DEPENDENCIES

B<Class::Load>, B<Import::Into>, B<Devel::InnerPackages>, Perl 5.10.1.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

B<pkg> is focussed specifically on dealing with packages and is not
intended as a general purpose replacement for the standard B<use>
statement.  In particular it does not know how to deal with
other pragmata, e.g.,

  use pkg strict;

will probably not do anything useful and will most probably advance
the heat death of the universe.

Please report any bugs or feature requests to
C<bug-pkg@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=pkg>.

=head1 SEE ALSO

B<aliased>, B<namespace>, B<as>, B<use>.

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Diab Jerius

pkg is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>
