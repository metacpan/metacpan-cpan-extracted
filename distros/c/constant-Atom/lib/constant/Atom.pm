package constant::Atom;
$constant::Atom::VERSION = '0.10';
use 5.006;
use strict;
use warnings;

use Carp;
sub new {
    my($pkg, $client_package, $name) = @_;

    croak if not defined $name or not defined $client_package;
    my $string = $client_package."::".$name;
    my $self = bless \$string, $pkg;
    return $self;
}

use overload
    '==' => 'equals',
    'eq' => 'equals',
    '!=' => 'notequals',
    'ne' => 'notequals',

    #I've decided that both numeric and string equality operators should be allowed.
    # '==' => sub {my $class = ref(shift); croak "'==' operator isn't defined for $class objects.  Did you mean 'eq'?"},
    # '!=' => sub {my $class = ref(shift); croak "'!=' operator isn't defined for $class objects.  Did you mean 'ne'?"},

    nomethod => sub {
        my($a, $b, $c, $operator) = @_;
        my $class = ref($a);
        croak "The '$operator' operation isn't defined for $class objects";
    },
    '""' =>  'tostring'
;

sub tostring {
    my($self) = @_;

    if (not defined $self) {
        croak "tostring should be called on an atom";
    }
    return overload::StrVal($self).'='.$$self;
}

sub equals {
    ref($_[1]) eq ref($_[0]) and ${$_[0]} eq ${$_[1]}
};

sub notequals {
    not (ref($_[1]) eq ref($_[0]) and ${$_[0]} eq ${$_[1]})
};

sub name {
    my($self) = @_;
    my @parts = split /\:\:/, $$self;
    return $parts[-1];
}

sub fullname {
    my($self) = @_;
    return $$self;
}


sub make_identifier {
    my($pkg, $client_package, $name) = @_;
    my $id = $pkg->new($client_package, $name);

    no strict 'refs';

    my $full_name = $client_package."::".$name;

    *$full_name = sub () { $id; };
}

sub import {
    my($pkg, @names) = @_;

    return unless $pkg;     # Ignore 'use constant;'

    my $client_package = caller(0);
    for (@names) {
        $pkg->make_identifier($client_package, $_);
    }
}


1;

__END__

=head1 NAME

constant::Atom - define unique symbols (constant functions with opaque values)

=head1 SYNOPSIS

 use constant::Atom qw/ red yellow blue /;
 
 my $color = red;
 
 print "Just as we thought!\n"        if $color eq red;
 print "This will never happen.\n"    if $color eq blue;
 print "Atoms never equal strings!\n" if $color eq 'red';
 
 print "Color is ".$color->name."\n";
 
 # The following raises an exception,
 # because addition isn't defined for Atom objects.
 $color + 1; 

=head1 DESCRIPTION

This module is used to declare 'function constants', similar to those
created with L<constant> and L<enum>, but with a key difference:
you don't specify a value for the constants, and you should use it in
situations where you don't need to know the value.

Atoms have their own independent identity,
and will only compare positively (via the 'eq' test)
with other identical Atoms.
All other operations on Atoms are undefined,
including casting to a string and casting to a number.

Atoms are used in place of constants in situations where a unique value
is needed to represent some idea or program state,
but where that value is not naturally associated with a scalar value,
and shouldn't be confused with one.
Atoms are similar to C enums in this respect,
except that Atoms do not have an ordinal value.

For example, you might use L<constant> or L<enum> where you want to
define constants that are used to index an array.
C<constant::Atom> can't be used in such situations.

Below is an example of where an Atom would solve a problem:

 # use constant::Atom 'error';
   use constant 'error' => 999999;
    
   sub bar {
       my($arg) = @_;
 
       # Always return $arg for demonstration purposes (not error).
       return 1 ? $arg : error;
   }
 
   my $foo = bar(999999);
   print "Foo: $foo\n";
   
   print $foo eq error ? "Foo returned error." : "Foo returned $foo.";

Output: Foo returned error.

In the above example, the programmer is trying to choose some unlikely value to alias 'error' to.
The problem is, if 'bar' is ever accidently called with this same value,
the program will mistakenly believe that 'error' had been returned.

This doesn't happen with Atoms.

    use constant::Atom 'error';
 #  use constant 'error' => 999999;
    
    sub bar {
        my($arg) = @_;
    
        #Always return $arg for demonstration purposes (not error).
        return 1 ? $arg : error;
    }
    
    my $foo = bar(999999);
    print "Foo: $foo\n";
    
    print $foo eq error ? "Foo returned error." : "Foo returned $foo.";

Output: Foo returned 999999.

=head1 COMPARISON TO ALTERNATIVES

An alternative to using an Atom is to use a constant aliased to a reference to an arbitrary scalar:

    use constant myconstant => \"";

There are two advantages of Atoms over this kind of constant

=over 4

=item * Scalar references can compare positively to numeric values:

    use constant myconstant => \"";
    my $numeric_value = myconstant + 0;
    die "Trapped!" if $numeric_value == myconstant;

=item * Atoms maintain their identity through serialization, even between processes:

    use constant::Atom 'myatom';
    
    use Storable qw (freeze thaw);
    print "Just as we thought!" if myatom eq thaw(freeze(myatom));

=back

=head1 ATOMS AS STRINGS

An atom cast (stringified) into a string produces a representation that may be useful for debugging purposes:

    use constant::Atom 'myatom';
    
    my $value = myatom;
    print "Myatom cast into a string: $value\n";

Output: Myatom cast into a string: Atom=SCALAR(0x18508dc)=main::myatom

Stringified Atoms can be used as hash keys, matched to a regexps, etc.
When this happens, the string value is not guaranteed to be unique.
Although it is unlikely that you will ever accidently cast an Atom into a string,
and even more unlikely that another string value will equal the string representation of the Atom,
you might want to use constant::Atom::Strict to be 100% safe:

    use constant::Atom::Strict 'myatom';
    
    my $value = myatom;
    print "Myatom cast into a string: $value\n";

Output: Can't cast Atom::Strict object 'main::myatom' into a string.  Use the 'fullname' method for a string representation of this object at C:\test7.pl line 5

=head1 OTHER METHODS

=over 4

=item C<name>

    package Languages;
    use constant::Atom qw (English);
    my $language = English;
    
    #Get the name of the constant
    print "Language: ".English->name."\n";

Output: English

=item C<fullname>

    package Languages;
    use constant::Atom qw (English);
    my $language = English;
    
    #Get the string-representation of the constant, which is simply the fully-qualified symbol name.
    "$language" eq $language->fullname or die "These should be the same.";

Output: Languages::English

=back

=head1 SEE ALSO

L<constant> is a core module used to declare 'function constants', where you specify the value.

L<enum> is used to define a number of function constants where you want them to have sequential values,
like C's enumerated type.

L<Const::Fast> lets you create immutable variables, which act like constants, but can be inlined in strings etc,
where function constants can't.

There are L<plenty of other constant modules|http://neilb.org/reviews/constants.html> on CPAN.

=head1 REPOSITORY

L<https://github.com/neilbowers/constant-Atom>

=head1 AUTHOR

This module was originally created by Jonathan R. Warden E<lt>john@newchester.comE<gt>,
but is currently being maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2004 Jonathan R. Warden. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

