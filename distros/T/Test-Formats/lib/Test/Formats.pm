###############################################################################
#
# This file copyright (c) 2008 by Randy J. Ray, all rights reserved.
#
# See LICENSE in the documentation for redistribution terms.
#
###############################################################################
#
#   $Id: Formats.pm 2 2008-10-20 09:56:47Z rjray $
#
#   Description:    This is an umbrella of sorts, that allows users to make
#                   use of multiple Test::Formats::* implementation classes
#                   at once, while also still getting all the benefits of
#                   being a subclass of Test::Builder::Module.
#
#   Functions:      import
#
#   Libraries:      Test::Builder::Module
#
#   Global Consts:  $VERSION
#
###############################################################################

package Test::Formats;

use 5.008;
use strict;
use warnings;
use subs qw(import);
use base 'Test::Builder::Module';

our $VERSION = '0.10';

###############################################################################
#
#   Sub Name:       import
#
#   Description:    Do some sleight-of-hand with @ISA during the import
#                   stage.
#
#   Arguments:      NAME        IN/OUT  TYPE    DESCRIPTION
#                   $class      in      scalar  Class we're called from
#                   @rest       in      array   Rest of the args-list
#
#   Globals:        @ISA
#
#   Returns:        threads through to SUPER::import()
#
###############################################################################
sub import
{
    my ($class, @rest) = @_;

    # Yes, this means we will be force-exporting other modules' export lists
    # into the namespace of whoever called us.
    my $caller = caller(0);

    # This is tricky. Anything that might be an import argument to
    # Test::Builder::Module has to stay. Things that look like they are
    # specializations of Test::Formats need to be handled here. For now, at
    # least until the first bugs appear on RT, assume any string that leads
    # with an upper-case letter is meant for us.
    my @pass = ();
    for my $opt (@rest)
    {
        if (ref($opt) || ($opt !~ /^[A-Z]/))
        {
            # Assume that this option is intended for the superclass
            push @pass, $opt;
            next;
        }

        # If the name doesn't begin with "Test::", then it is assumed to be
        # relative to this class. Prepend $class to it in that case. This
        # lets format-testing modules that aren't directly under
        # Test::Formats::* be covered by our umbrella.
        $opt = "${class}::$opt" unless $opt =~ /^Test::/;

        # Attempt to load it, importing what it offers into the namespace that
        # called us.
        eval "package $caller; use $opt;";
        die "$class: Error loading format-tester $opt: $@" if $@;
    }

    $class->SUPER::import(@pass);
}

1;

__END__

=head1 NAME

Test::Formats - An umbrella class for test classes that target formatted data

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    use Test::Formats XML => tests => 5;

    our $schema = "structure.xsd";

    for (qw(file1.xml file2.xml file3.xml reference.xml minimal.xml))
    {
        is_valid_against_xmlschema($schema, $_, "$_ validation");
    }

=head1 DESCRIPTION

The Test::Formats module provides unit tests of the Test::More variety,
that work with any TAP-driven test-harness system. The tests are oriented
towards testing textual data that follows defined formats, such as XML or YAML.
Rather than using regular expressions or string-equality comparisons, the
classes provided with this distribution use existing validators. For example,
the XML tests (see L<Test::Formats::XML>) use the XML::LibXML module from
CPAN which provides validation for XML Schema, RelaxNG and DTDs (SGML or XML
style DTDs).

The tests accessible through Test::Formats are broken into groups called
C<specializations>, each represented by a class that inherits from the
Test::Builder::Module class. Each of these can operate as a stand-alone
test module, as their inheritance from Test::Builder::Module also provides
access to the basic testing functionality (C<plan>, C<skip>, etc.). This
module, Test::Formats, acts as an umbrella that makes it easier to load
several of these groups at once.

This class does not actually provide any functionality of its own, except for
an C<import> method that removes arguments that identify specializations, loads
them into the namespace of the caller, and passes the remaining arguments on
to Test::Builder::Module which registers them with the current test-session
being set up.

=head2 Defining Specialization Classes

A specialization class can stand alone, and does not need to be loaded through
the Test::Formats container. It should be a subclass of
Test::Builder::Module, or if it isn't it should provide the full
functionality of Test::Builder through its own means.

If a specialization class is loaded through the Test::Formats umbrella, it
will not receive any arguments in the C<use> command that loads it. Any
test-suite control arguments are passed on to the superclass. Therefore, the
specialization class should not override the C<import> method it inherits
from Test::Builder::Module unless the local version ends with a call to
C<SUPER::import(@_)> (passing C<@_> ensures that the class does work when
loaded directly, by passing any arguments it received to the parent class). The
specialization class should instead rely only on the C<@EXPORT> list to define
the functions it provides.

See L<Test::Formats::XML> for an example of a specialization class.

=head2 Loading Specializations from Test::Formats

One or more specialization classes can be loaded through a single call to
Test::Formats by passing their names in the import-list to the load of
this class. As an example:

    use Test::Formats XML => tests => 5;

This invocation loads the Test::Formats::XML specialization class, then
passes the arguments C<tests> and C<5> on to the construction of the test
suite.

Such classes do not need to be named B<< Test::Formats::<Something> >>. The
Test::Formats C<import> method scans the list of arguments for any value
that is not a reference and whose first character is an upper-case letter.
Anything else is presumed to be intended for Test::Builder. If the argument
string does not start with C<Test::>, then the value of C<__PACKAGE__> is
prepended to it. Thus, Test::Formats can itself be used as a base class
in which the derived class' name is used in creating the full class name. If
the argument's first six characters I<are> C<Test::>, then it is used without
modification. The final name, modified or not, is then used in an C<eval>
block that tries to load the module via C<use>, in the namespace that initally
loaded Test::Formats (or the class derived from it).

To illustrate the modification of arguments to class names, consider this
table:

    Main class name     Argument text     Name of class that get loaded
    ===============     =============     =============================
    Test::Formats       XML               Test::Formats::XML
    Test::Formats       XML::Simple       Test::Formats::XML::Simple
    Test::Formats       Test::Hooks       Test::Hooks
    My::Test::Formats   MyFormat          My::Test::Formats::MyFormat

Note that in the third case, no change is made to the argument. And in the
fourth case (assuming that B<My::Test::Formats> is a subclass of
Test::Formats) the modified argument has the derived class prepended to it,
not Test::Formats.

=head1 FUNCTIONS

Test::Formats does not export any functions of its own. It only facilitates
the loading of specialization classes and the export of their functionality
into the namespace of the package that uses Test::Formats. However, since
it is a sub-class of Test::Builder::Module, it is fully usable as a test
framework (provided at least one specialization is loaded) and provides all
the functionality described in Test::More (in addition to any functions
provided by specialization classes). See L<Test::More> for documentation on
those functions provided.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-formats at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Formats>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Formats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Formats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Formats>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Formats>

=back

=head1 ACKNOWLEDGMENTS

The original idea for this stemmed from a blog post on L<http://use.perl.org>
by Curtis "Ovid" Poe. He proferred some sample code based on recent work he'd
done, that validated against a RelaxNG schema. I generalized it for all the
validation types that XML::LibXML offers, and expanded the idea to cover
more general cases of structured, formatted text.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Randy J. Ray, all rights reserved.

This module and the code within are released under the terms of the Artistic
License 2.0
(L<http://www.opensource.org/licenses/artistic-license-2.0.php>). This code
may be redistributed under either the Artistic License or the GNU Lesser
General Public License (LGPL) version 2.1
(L<http://www.opensource.org/licenses/lgpl-license.php>).

=head1 SEE ALSO

=head1 AUTHOR

Randy J. Ray, C<< <rjray at blackperl.com> >>
