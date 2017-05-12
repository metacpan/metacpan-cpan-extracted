package VarGuard;

use 5.006;
use strict;
use warnings;

=head1 NAME

VarGuard - safe clean blocks for variables

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use VarGuard;

    {
	var_guard { print "$_[0]\n" } my $scalar;
	$scalar = 'abc';
    } # print "abc\n"; when scalar is destroyed

    {
	var_guard { print "@_\n" } my @array;
	...
    }

    {
	var_guard { print "@_\n" } my %hash;
	...
    }

    {
	var_guard { $_[0]() } my $code;
	$code = sub { ... };
	...
    }

=head1 DESCRIPTION

This module is similar to L<Guard>, except that this module is guard on a variable.

=head1 CAVEAT

This module will tie something on the variable. So don't use it on a tied variable,
or tie the guarded variable.

=head1 EXPORT

var_guard

=head1 SUBROUTINES

=head2 var_guard { ...code block... } VAR(could be $, @, %, or any reference)

=cut

use base qw(Exporter);
our @EXPORT = qw(var_guard);

use VarGuard::Scalar;
use VarGuard::Array;
use VarGuard::Hash;

sub var_guard(&\[$@%*]) {
    my($cb, $var) = @_;
    my $ref_type = ref $var;
    if( $ref_type eq 'SCALAR' or $ref_type eq 'CODE' ) {
	tie $$var, 'VarGuard::Scalar', $cb;
    }
    elsif( $ref_type eq 'ARRAY' ) {
	tie @$var, 'VarGuard::Array', $cb;
    }
    elsif( $ref_type eq 'HASH' ) {
	tie %$var, 'VarGuard::Hash', $cb;
    }
    else {
	die "type: $ref_type is not supported.";
    }
}


=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-varguard at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VarGuard>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Guard>

=cut

1; # End of VarGuard
