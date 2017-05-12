package T;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'Import::Box';

sub __DEFAULT_AS { 't' }
sub __DEFAULT_NS { 'Test' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

T - Encapsulate testing tools instead of cluttering your namespace.

=head1 DESCRIPTION

This module collection makes it possible to use popular testing tools such as
L<Test::More> or L<Test2::Bundle::Extended> without cluttering up your
namespace. Under the hood all the work is done by L<Import::Box> which was
created specifically to implement this.

=head1 SYNOPSIS

=head2 BOX FUNCTIONS

    use T 'More'; # Loads Test::More, and provides the t() box function

    use T2 'Basic'; # Loads Test2::Tools::Basic, and provides the t2() function

    use T2::B 'Extended'; # Loads Test2::Bundle::Extended, also provides/appends to the t2() function

    use T2::P 'SRand'; # Loads Test2::Plugin::SRand, and provides the t2p() function

    t->is('a', 'a', "Can run Test::More::is()");
    t2->is('a', 'a', "Can run Test2::Tools::Compare::is()"); # (Provided by the extended bundle)


    # Alternate syntax:

    t  is => ('a', 'a');
    t2 is => ('a', 'a');

=head2 OO

    use T;
    use T2;
    use T2::B;

    my $t = T->new('More'); # Loads Test::More into $t

    my $t2 = T2->new('Basic'); # Loads Test2::Tools::Basic into $t2

    my $t2b = T2::B->new('Extended'); # Loads Test2::Bundle::Extended into $t2b

    $t->is('a', 'a', "Can run Test::More::is()");

    $t2->ok(1, "ok from Test2::Tools::Basic");

    $t2b->is('a', 'a', "Can run Test2::Tools::Compare::is()");


    # Indirect syntax (just say NO!)

    is $t('a', 'a');
    ok $t2(1, "pass");
    is $t2b('a', 'a');

=head1 PACKAGES

=over 4

=item T

This is used for boxing C<Test::> modules into the C<t()> box.

=item T2

This is used for boxing C<Test2::Tools::> modules into the C<t2()> box.

=item T2::B

This is used for boxing C<Test2::Bundle::> modules into the C<t2()> box.

=item T2::P

This is used for boxing C<Test2::Plugin::> modules into the C<t2p()> box. A
plugin should never actually export anything, so this is actually just a
shortcut for loading plugins.

=back

=head1 METHODS

=over 4

=item t->import($MODULE)

=item $t->import($MODULE)

=item t->import($MODULE => \@IMPORT_ARGS)

=item $t->import($MODULE => \@IMPORT_ARGS)

This will load C<$MODULE> and place the exports into the box instead of your
namespace. A prefix is automatically prepended to C<$MODULE>, which prefix
depends on the class used for boxing. To avoid the prefix you can append '+' to
the front of C<$MODULE>:

    t->import('+My::Module');

=over 4

=item L<T>

Prefixes with C<Test::>

=item L<T2>

Prefixes with C<Test2::Tools::>

=item L<T2::B>

Prefixes with C<Test2::Bundle::>

=item L<T2::P>

Prefixes with C<Test2::Plugin::>

=back

=back

=head1 SEE ALSO

L<Import::Box> - Everything here is based off of this module.

=head1 SOURCE

The source code repository for T can be found at
F<http://github.com/Test-More/T/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
