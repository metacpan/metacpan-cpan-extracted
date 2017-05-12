package pluskeys;

use strict;
use warnings;

use Carp;

our($VERSION) = q($Revision: 2.4 $) =~ / \b ( \d+ (?: \. \d+ )+ ) \b /x;

my $My_Package = __PACKAGE__;

sub import { 
    shift; # discard "pluskeys" invocant

#################################################################
# Create named constants in caller's package so they 
# can be used to access munged member names with +NAME
# which both catches typos and adds package-name munging so
# that more than one class in a hierarchy can have a key
# with the same name.  
#
# Must be called from a BEGIN block to do any good. That's
# why it is a use statement, since that has a BEGIN blocked
# wrapped around it.
#################################################################

    for my $member (@_) {
        # Has to start with a letter or an underscore, and be one
        # or more identifier characters long and nothing else.
        $member =~ / ^ (?= [\p{Letter}_] ) \w+ $ /x
            || croak "Bad pluskey: '$member' is not a valid identifier";

        my $his_package = caller;

        eval <<"MAKE_A_MEMBER_CONSTANT" || croak "member init of $member failed: $@";
            package $his_package;
            use constant $member => ${My_Package}::_mk_safe_member('$member');
            1;
MAKE_A_MEMBER_CONSTANT
    } 
} 

sub _mk_safe_member($) {
    my($member_name) = @_;
    my $his_package = caller;
    return $his_package . "::" . $member_name;
} 

1;

__END__

=head1 NAME

pluskeys - pragma to declare class- and typo-safe keys to use in objects

=head1 SYNOPSIS

    package Some::Package;

    use strict;
    use warnings;

    use pluskeys qw(
        NAME
        RANK
        SERIAL_NUMBER
    );

    ....

    if ($self->{ +RANK } =~ /General/) { .... }

=head1 DESCRIPTION

The C<use pluskeys> pragma takes a list of identifiers and creates
constants (zero-argument functions) in the caller's package that return
their own name prefixed with that package.  It is most commonly used 
from within a class definition to declare the object attributes (that 
is, its data members) in a way that can be checked at compile time.

The convention is to use a leading C<+> as a "member key" pseudo-prefix
when subscripting the hash.  This really makes something like C<+NAME>
get parsed as C<NAME()> instead.

That way you can use it as the subscript into a hash and have it be
"typo-checked" under C<use strict>, because if you try to use one 
of these that you didn't declare, it will look like an illegal
bareword string and make C<use strict> blow up at compile time.

For example, given the example in the SYNOPSIS above, this 
would be a syntax error:

    if ($self->{ +SERIAL_NUBMER } =~ /999/) { .... }

Because it would produce an error along these lines (adjusting for
filename and line number):

 Bareword "SERIAL_NUBMER" not allowed while "strict subs" in use at test-pluskeys line 13.

But this would be ok:

    if ($self->{ +SERIAL_NUMBER } =~ /999/) { .... }

Because that would be interpreted as:

    if ($self->{ SERIAL_NUMBER() } =~ /999/) { .... }

And thus (resolving at compile time into):

    if ($self->{ "Some::Package::SERIAL_NUMBER" } =~ /999/) { .... }

The other thing this does is prefix each key with the current package name,
so that C<+NAME> is really C<Some::Package::NAME>.  That way each class
in an inheritance hierarchy can have its own member data without risk of
trampling on some other class using that same key.  It's the only safe
way to do things when you cannot know what classes will be using what.

The only drawback is that the same notation cannot be used as the left
operand to the C<< => >> operator.  This doesn't work:

    %hash = (
        +NAME => "Joe Blow",    # DOESN'T WORK
        +RANK => "peon",        # DOESN'T WORK
    );

Because unlike it use as a braced hash subscript, there it will be
interpreted as a bareword string and not complained about.  This is due 
to the auto-quoting behavior of the C<< => >> operator.

Instead you would have to write that one this way:

    %hash = (
        NAME() => "Joe Blow",   # this works
        RANK() => "peon",       # this works
    );

But that is a comparatively rare occurrence compared with 
all the times you say C<< $self->{ +NAME } >>, and a small
price to pay.

Although the "member names" at the end in that object
do not happen to conflict, it would not matter if they
did, because it would be package-qualified into a different
package.

Needless to say, you should only ever access your B<own> private data
members from within the class that declared them via C<use pluskeys>,
because doing so with some other class's is bound to get you talked about,
and not in a good way.

The fact that 

    $self->{ $self->COLUMN_MAP } 

kind of works (provided there are no conflicts) should not be taken
as licence to use that sort of gross invasion of privacy.  Always use the 
designated accessor methods for data members; don't go barging
in where you're not at home.

=head1 SEE ALSO

The entire Fido class hierarchy uses this notation exclusively for dealing
with its objects; this is critical when a final format object may
have five or ten different unrelated mix-in classes in its ancestry.
See L<Fido::Intro(3)> for starters; then look into
some of the many Fido classes, such as L<Fido::Data(3)> for example.

Also see L<Class::Struct> for the same idea.  The package qualification is
all based on an idea of Tom's from back in perl4 days, and it is still
perfectly lovely today.

=head1 BUGS AND LIMITATIONS

Because L<constant> is used, it is currently ill-advised to use
non-ASCII identifiers.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005-2015, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

