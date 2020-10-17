package Test::Run::Assert;

use strict;
use warnings;

require Exporter;
use vars qw($VERSION @EXPORT @ISA);

$VERSION = '0.0305';

@ISA = qw(Exporter);
@EXPORT = qw(assert);

=head1 NAME

Test::Run::Assert - A Simple Assert Function.

=head1 SYNPOSIS

B<This module is only for internal use>.

    use Test::Run::Assert;

    assert ( EXPR , $name );

=head1 EXPORTS

=head2 assert($condition, $name)

If condition is false - croak with the description $name.

=cut

sub assert($;$)
{
    my ($condition, $name) = @_;

    if (! $condition)
    {
        require Carp;

        my $msg =
            sprintf("Assert failed - '%s'!", $name)
            ;

        Carp::croak($msg);
    }
}

=head1 AUTHOR

Originally written by:

Michael G Schwern C<< <schwern@pobox.com> >>

Rewritten as MIT-X11 Licensed code by:

Shlomi Fish L<http://www.shlomifish.org/>

=head1 COPYRIGHT

Copyright by Shlomi Fish, 2008.

=head1 LICENSE

This file is licensed under the MIT X11 License:

L<http://www.opensource.org/licenses/mit-license.php>

=cut

1;

