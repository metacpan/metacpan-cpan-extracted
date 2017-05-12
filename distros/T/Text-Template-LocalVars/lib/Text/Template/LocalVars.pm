package Text::Template::LocalVars;

use 5.008009;
use strict;
use warnings;

use parent 'Text::Template';
use Text::Template::LocalVars::Package;

our @EXPORT_OK = qw(fill_in_file fill_in_string TTerror);

our $VERSION = '0.04';

#################################################################

# These are used to pass the name of the variable package to a nested
# fill. The fragment code may run code compiled into *another* package,
# and if that code wants to perform a localized fill using the
# fragment's variable package, it has no easy way of finding out.
# This package variable is localized to the correct package name just
# prior to calling SUPER::fill_in

our $TemplatePackage;
our $TemplateParentPackage;

our $TrackParentDefault = 1;

#################################################################
# match public API (and some private ones too)

*_param = \&Text::Template::_param;

*TTerror = \&Text::Template::TTerror;

*ERROR = \$Text::Template::ERROR;

sub fill_in_string {
    my $string = shift;
    my $package = _param( 'package', @_ );

    # pull in the correct package if we're tracking parent
    # packages. note that we retain Text::Template's behavior of
    # always assigning a package ( RT#51473 ).  this behavior is most
    # likely because otherwise if the package parameter is not
    # specified the call to fill_this_in() will always use *this*
    # package to store its values, rather than the original caller's
    # package.

    my $trackvarpkg = _param( 'trackvarpkg', @_ );
    $trackvarpkg = $TrackParentDefault unless defined $trackvarpkg;

    if ( !defined $package ) {
        push @_,
          'package' => (
              $trackvarpkg && defined $TemplatePackage
            ? $TemplatePackage
            : scalar( caller ) );
    }
    __PACKAGE__->fill_this_in( $string, @_ );
}

sub fill_in_file {
    my $fn = shift;

    my $package = _param( 'package', @_ );

    # pull in the correct package if we're localizing and tracking
    # parent packages.

    my $trackvarpkg = _param( 'trackvarpkg', @_ );
    $trackvarpkg = $TrackParentDefault unless defined $trackvarpkg;

    push @_, $TemplatePackage
      if !defined $package
      && $trackvarpkg
      && defined $TemplatePackage;

    my $templ = __PACKAGE__->new( TYPE => 'FILE', SOURCE => $fn, @_ )
      or return undef;
    $templ->compile or return undef;
    my $text = $templ->fill_in( @_ );
    $text;
}


# delete a parameter from a passed set and return the key that was
# used to specify it.
sub _del_param {

    my $kk;
    my ( $k, $h ) = @_;

    my $first;

    # delete *all* keys that would match, just to be safe.
    my @keys = grep { exists $h->{$_} } $k, "\u$k", "\U$k", "-$k", "-\u$k",
      "-\U$k";

    delete @{$h}{@keys};

    return $keys[0];
}


sub fill_in {

    my $self = shift;
    my %args = @_;

    my $trackvarpkg = _param( 'trackvarpkg', %args );
    $trackvarpkg = $TrackParentDefault unless defined $trackvarpkg;

    my $localize = _param( 'localize', %args );

    if ( $localize ) {

        my $pkg
          = _param( 'package', %args )
          || ( $trackvarpkg ? $TemplatePackage : () )
          || scalar( caller );

        my $npkg = Text::Template::LocalVars::Package->new( $pkg );
        $args{ _del_param( 'package', \%args ) || 'package' } = $npkg->pkg;
        _del_param( 'localize', \%args );

        local $TemplateParentPackage = $pkg;
        local $TemplatePackage       = $npkg->pkg;

        $self->SUPER::fill_in( %args );

    }

    else {

        # track the template variable package even if not localizing,
        # in case a fragment calls fill_in and wants to localize
        # and track the parent.  yes, we are our own parent.

        my $parent
          = _param( 'package', %args )
          || ( $trackvarpkg ? $TemplatePackage : () )
          || scalar( caller );

        local $TemplateParentPackage = $parent;
        local $TemplatePackage       = $parent;

	# if no package was specified, and we're requested to track the parent,
	# use that as the package
	$args{ _del_param( 'package', \%args ) || 'package' } = $parent
	    if $trackvarpkg;

        $self->SUPER::fill_in( %args );

    }

}

1;

__END__


=head1 NAME

Text::Template::LocalVars - Text::Template with localized variables

=head1 SYNOPSIS

  use Text::Template::LocalVars 'fill_in_string';

  # store values in 'MyPkg' package
  fill_in_string( $str1, hash => \%vars1, package => 'MyPkg' );

  # use values from MyPkg package, but don't store any new
  # ones there.
  fill_in_string( $str2, hash => \%vars2, package => 'MyPkg',
                  localize => 1 );

  # use the variable package in the last call to a template fill
  # routine in the call stack which led to this code being executed.
  fill_in_string( $str, trackvarpkg => 1 );


=head1 DESCRIPTION

B<Text::Template::LocalVars> is a subclass of L<Text::Template>, with
additional options to manage how and where template variables are stored.
These come in particularly handy when template fragments themselves
perform template fills, either inline or by calling other functions
which do so.

(L<Text::Template> stores template variables either in a package
specified by the caller or in the caller's package.  Regardless of
where it comes from, for conciseness let's call that package the
I<variable package>.  Likewise, invoking a template fill function or
method, such as B<fill_in_string>, B<fill_in_file>, B<fill_this_in>,
or B<fill_in> is called I<filling>, or a I<fill>. )

B<Text::Template::LocalVars> provides the following features:

=over

=item * localized variable packages

The variable package may be I<cloned> instead of being used directly
(see L</Localized Variable Packages>), providing fills with a
sandboxed environment.

=item * tracked parent variable packages

If a fill routine is called without a package name, the package in
which the fill routine is invoked is used as the variable
package. This works well if the fill routine is invoked in a template
fragment, but doesn't if the it is invoked in code compiled in another
package (such as a support subroutine). B<Text::Template::LocalVars>
keeps track of the appropriate package to use, and can pass that
package to the fill routine automatically (see L<Tracking Variable
Packages>).

=back

=head2 Localized Variable Packages

Localized variable packages come in handy if your template fragments
perform template expansions of their own, and while they should have
access to the existing values in the package, you'd prefer they not
alter it.

Here's an example:

  use Text::Template::LocalVars 'fill_in_string';
  Text::Template::LocalVars->always_prepend(
      q[use Text::Template::LocalVars 'fill_in_string';] );

  my $tpl = q[
    { fill_in_string(
		     q[boo + foo = { $boo + $foo }],
		     hash    => { boo => 2 },
		     package => __PACKAGE__,
      );
    }
    foo = { $foo; }
    boo = { $boo; }
    ];

  fill_in_string(
      $tpl,
      hash    => { foo => 3 },
      package => 'Foo',
      output  => \*STDOUT
  );

We're explicitly specifying a variable package in the outer call to
B<fill_in_string> to ensure that we don't contaminate our environment.
(See L</"fill_in_string"> for details).  In the inner B<fill_in_string>
call we use the current variable package so we can
see the variables specified in the outer call.

  This outputs

  boo + foo = 5
  foo = 3
  boo = 2

The inner fill sees C<$foo> from the top level fill (as we've specified), and
adds C<$boo> to package C<Foo>.

But, what if you don't want to pollute the upper fill's environment?
You can't give the inner fill it's own package because it won't see
the variables in B<Foo>.  You could extract the values from B<Foo> and
explicitly pass them to the inner fill, but that is error prone.

With B<Text::Template::LocalVars>, if you pass the C<localize> option,
the fill routine gets a I<copy> of the variable package, so it
can't contaminate it

  my $tpl = q[{
	 fill_in_string(
	     q[boo + foo = { $boo + $foo }],
	     hash    => { boo => 2 },
             package => __PACKAGE__,
	     localize => 1,
	 );}
  foo = { $foo; }
  boo = { $boo; }
  ];

results in

  boo + foo = 5
  foo = 3
  boo =

Certain constructs in packages are not easily copied, so the cloned
package isn't identical to the original.  The C<HASH>, and C<ARRAY>
values in the package are cloned using L<Storable::dclone>; the
C<SCALAR> values are copied if they are not references, and the
C<CODE> values are copied.  All other entries are ignored.  This is
not a perfect sandbox.


=head2 Tracking Variable Packages

If your processing becomes complicated enough that you begin nesting
template fills and abstracting some into subroutines, keeping track of
variable packages may get complicated.  For instance

  sub name {
      my ( $reverse ) = @_;

      my $tpl
	= $reverse
	? q[ { $last },  { $first } ]
	: q[ { $first }, { $last }  ];

      fill_in_string( $tpl );
  }

  my $tpl = q[
	name = { name( $reverse ) }
    ];

  fill_in_string(
      $tpl,
      hash => {
	  first   => 'A',
	  last    => 'Uther',
	  reverse => 1,
      },
      package => 'Foo'
  );

Here, we're implementing some complicated template logic in a
subroutine, generating a new string with a template fill, and then
returning that to an upper level template fragment for inclusion.
All of the data required are provided to the top level template fill
via the package C<Foo>, but how does that percolate down to the C<name()>
subroutine?  There are several ways to do this:

=over

=item *

Explicitly pass the I<data> to C<name()>:

  my $tpl = q[
	name = { name( $reverse, $first, $last ) }
    ];

=item *

Explicitly pass the I<variable package> to C<name()>:

  my $tpl = q[
	name = { name( $reverse, __PACKAGE__ ) }
    ];

=item *

Turn on variable package tracking in C<name()>:

  fill_in_string( $tpl, trackvarpkg => 1 );

C<Text::Template::LocalVars> keeps track of which variable packages are
used in I<nested calls> to fill routines; setting C<trackvarpkg> tells
C<fill_in_string> to use the package used by the last fill routine in
the call stack which led to this one.  In this case, it'll be the one
setting C<package> to C<Foo>.  If there is none, it falls back to
the standard means of determining which package to use.

=back

=head1 METHODS

=head2 new

See L<Text::Template/"new">.

=head2 compile

See L<Text::Template/"compile">.

=head2 fill_in

The API is the same as in L<Text::Template/"fill_in">, with the
addition of the following options:

=over

=item * localize

If true, a clone of the template variable package is used.

=item * trackvarpkg

If true, and no template variable package is specified, use the one used
in the last B<Text::Template::LocalVars> fill routine which led to invoking
this one.

=back

=head1 FUNCTIONS

=head2 fill_this_in

=head2 fill_in_string

=head2 fill_in_file

The API is the same as See L<Text::Template/"fill_this_in">, with the
addition of the C<localize> and C<trackvarpkg> options (see L</"fill_in">).

If the B<trackvarpkg> option is I<not> set, B<fill_in_string> retains
B<Text::Template::fill_in_string> behavior in regards to default
variable packages.  Unlike other fill routines,
B<Text::Template::fill_in_string> will I<not> create an anonymous
variable package if one is not specified, but will instead it use the
current package. See
L<https://rt.cpan.org/Public/Bug/Display.html?id=51473>.

=head1 EXPORT

The following are available for export (the same as L<Text::Template>):

=over

=item fill_in_file

=item fill_in_string

=item TTerror

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-template-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Template-LocalVars>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Template::LocalVars


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Template-LocalVars>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Template-LocalVars/>

=back


=head1 ACKNOWLEDGEMENTS

Mark Jason Dominus for L<Text::Template>

=head1 AUTHOR

Diab Jerius, C<< <djerius at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Mark Jason Dominus

Copyright (C) 2014 Smithsonian Astrophysical Observatory

Copyright (C) 2014 Diab Jerius

Text::Template::LocalVars is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


