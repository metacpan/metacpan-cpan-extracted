###############################################################################
#   Package Tie::TieConstant                                                  #
#   Copyright 2003, Wayne M. Syvinski, MS                                     #
#                                                                             #
#   If you use this software, you agree to the following:                     #
#   (1) You agree to hold harmless, and waive any claims against, the author. #
#   (2) You agree that there is no warranty, express or implied, for this     #
#       software whatsoever.                                                  #
#   (3) You will abide by the GNU General Public License or the Artistic      #
#       License in the use of this software.                                  #
#   (4) You agree not to modify this notice.                                  #
#                                                                             #
#   If you use this software and find it useful, I would appreciate an e-mail #
#   note to wsyvinski@techcelsior.com                                         #
###############################################################################

package Tie::TieConstant;
require Exporter;

use Carp;
use strict;
use warnings;
use warnings::register;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(tieconstant untieconstant);
our $VERSION = 1.01;

my $untying = 0;

my %created = ();

sub tieconstant (\$$)
{
    my ($self,$value) = @_;
    if ($created{$self})
    {
        croak "Constant $self with value $$self is already instantiated";        
    }
    else
    {
        tie ($$self,"TieConstant",$value);
        $created{$self} = 1;
    }
    return 1;
}

sub untieconstant (\$)
{
    my $self = shift;
    $untying = 1;
    undef $created{$self};
    $$self = undef;
    $untying = 0;
}

sub TIESCALAR
{
    my $class = shift;
    my $constantvalue = shift;
    return bless \$constantvalue, $class;
}

sub STORE
{
    my $self = $_[0];
    if ($untying)
    {
        undef $$self;
    }
    else
    {
        croak "Cannot overwrite constant $self with value $$self";
    }
}

sub FETCH
{
    my $self = shift;
    ref $self or confess "Not a class method for $self!";
    return $$self;
}

1;


=head1 NAME

TieConstant - package allowing creation of true scalar constants

=head1 AUTHOR

Wayne M. Syvinski, MS <wsyvinski@techcelsior.com>

=head1 COPYRIGHT NOTICE

Copyright 2003 Wayne M. Syvinski

=head1 WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is offered with this software.  You use this software at your own risk.  In case of loss, neither Wayne M. Syvinski, nor anyone else, owes you anything whatseover.  You have been warned.

=head1 LICENSE

You may use this software under one of the following licenses:

(1) GNU General Public License (can be found at http://www.gnu.org/copyleft/gpl.html)
(2) Artistic License (can be found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 GENERAL INFORMATION

This module was developed using ActivePerl build 804, version 5.8.0, under Windows 2000 Professional.  It needs to be placed in the root directory of your perl libraries.

This module was written entirely in Perl, with dependency on Exporter and Carp.

=head1 USAGE

use TieConstant;

tieconstant $constant, I<value>;
untieconstant $constant;
untie $constant;

=head1 DESCRIPTION

Module TieConstant allows the creation of true scalar constants.  I am aware of the I<constant> module with the default Perl distribution, and the I<Tie::Const> module on CPAN; however, I wanted true scalar constants for my own purposes, AND I wanted to learn about tied data structures in Perl.  TMTOWTDI!

TieConstant uses tied scalars to preserve constant values even through attempted reassignment.  Any attempt at scalar reassignment or double instantiation will result in a fatal error.  This behavior is intentional - I presume you want to keep constants constant for a reason.

You can assign a new value to a constant through use of the I<untieconstant> function.  You can obliterate constant binding of the scalar by using the I<untie> function.

Because the functions I<tieconstant> and I<untieconstant> are implemented using prototypes, you can invoke them without parentheses.

=head1 FUNCTION DESCRIPTIONS AND USE

=head2 tieconstant($constant, I<value>)

Function I<tieconstant> binds I<value> to $constant.  Parameter I<value> may be a literal or variable.  If I<value> is a variable, it is passed by value, so the tying operation has no effect on the original variable.

Once I<value> is bound to $constant, the value of the constant cannot be changed by simple scalar assignment, i.e., $constant = I<value2> is not allowed.

To change the value of the constant, you must explicitly invoke function I<untieconstant>.

To unbind the scalar from "constant behavior", use I<untie>.

=head2 untieconstant($constant)

Function I<untieconstant> allows reassignment of the scalar, and sets the constant value of the scalar to I<undef>.  B<WARNING:  It does not actually untie the scalar.>  The scalar can then receive a new constant value using function I<tieconstant>

=head2 untie($constant)

Function I<untie> is not implemented by package TieConstant, but is instead provided by Perl.  However, it is mentioned here, because you need to call it to break the binding between the scalar and its "constant behavior".

Once you invoke untie($foo), $foo can be treated like any other scalar, including assigning values by scalar assignment (e.g. $foo = 98.765).

However, UNLIKE I<untieconstant>, I<untie> will NOT reset the value of the scalar to I<undef>, but instead previous value of the scalar will be retained.

=cut