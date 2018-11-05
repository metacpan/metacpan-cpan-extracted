#ABSTRACT: Pragma qbit

=head1 Name

qbit - Setup envirement to development modern perl applications and add some functions.

=head1 Description

Using this pragma is equivalent:

 use strict;
 use warnings FATAL => 'all';
 use utf8;
 use open qw(:std utf8);

 use Scalar::Util qw(set_prototype blessed dualvar isweak readonly refaddr reftype tainted weaken isvstring looks_like_number);
 use Data::Dumper qw(Dumper);
 use Clone        qw(clone);

 use qbit::Exceptions;
 use qbit::Log;
 use qbit::Array;
 use qbit::Hash;
 use qbit::GetText;
 use qbit::Packages;
 use qbit::StringUtils;
 use qbit::Date;
 use qbit::File;

=head1 Synopsis

 use qbit;

 sub myfunc {
     my ($a1, $a2) = @_;

     throw Exception::BadArguments gettext('First argument must be defined')
         unless defined($a1);

     return ....
 }

 try {
    my $data = myfunc(@ARGV);
    ldump($data);
 } catch Exception::BadArguments with {
     l shift->as_string();
 };

=head1 Internal packages

=over

=item B<L<qbit::Exceptions>> - realize base classes and functions to use exception in perl;

=item B<L<qbit::Log>> - there're some function to simple logging;

=item B<L<qbit::Array>> - there're some function to working with arrays;

=item B<L<qbit::Hash>> - there're some function to working with hashes;

=item B<L<qbit::GetText>> - there're some function to internationalization your's software;

=item B<L<qbit::Packages>> - there're some function to access package internals;

=item B<L<qbit::StringUtils>> - there're some function to working with strings;

=item B<L<qbit::Date>> - there're some function to working with dates;

=item B<L<qbit::File>> - there're some function to manage files.

=back

=cut

package qbit;
$qbit::VERSION = '2.7';
use strict;
use warnings FATAL => 'all';
use utf8;
use open();
use Scalar::Util ();
use Data::Dumper ();
use Clone        ();

use qbit::Exceptions  ();
use qbit::Log         ();
use qbit::Array       ();
use qbit::Hash        ();
use qbit::GetText     ();
use qbit::Packages    ();
use qbit::StringUtils ();
use qbit::Date        ();
use qbit::File        ();

sub import {
    $^H |= $utf8::hint_bits;
    $^H |= 0x00000002 | 0x00000200 | 0x00000400;

    ${^WARNING_BITS} |= $warnings::Bits{'all'};
    ${^WARNING_BITS} |= $warnings::DeadBits{'all'};

    my $pkg         = caller;
    my $pkg_sym_tbl = qbit::Packages::package_sym_table($pkg);

    {
        no strict 'refs';
        *{"${pkg}::TRUE"}  = sub () {1};
        *{"${pkg}::FALSE"} = sub () {''};
    }

    Scalar::Util->export_to_level(
        1, undef,
        @{
            qbit::Array::arrays_difference(
                [
                    qw(set_prototype blessed dualvar isweak readonly refaddr reftype tainted weaken isvstring looks_like_number)
                ],
                [keys(%$pkg_sym_tbl)]
            )
          }
    );    # Don't export functions, if they were imported before

    Data::Dumper->export_to_level(1, qw(Dumper));

    Clone->export_to_level(1, undef, qw(clone));

    qbit::Exceptions->export_to_level(1);
    qbit::Log->export_to_level(1);
    qbit::Array->export_to_level(1);
    qbit::Hash->export_to_level(1);
    qbit::Packages->export_to_level(1);
    qbit::GetText->export_to_level(1);
    qbit::StringUtils->export_to_level(1);
    qbit::Date->export_to_level(1);
    qbit::File->export_to_level(1);

    @_ = qw(open :std :utf8);
    goto &open::import;
}

1;
