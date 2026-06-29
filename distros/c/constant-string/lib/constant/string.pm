package constant::string;

use strict;
use warnings;
use utf8;
use constant (); 

our $VERSION = '2026.267';

sub import {
    my ($class, @args) = @_;
    my $caller = caller;

	my %constants = map +( "${caller}::$_" => $_ ), @args;

	constant->import( \%constants ) if %constants;

}

1;

__END__

=pod

=encoding utf8

=head1 NAME

constant::string - Perl pragma to declare constants whose values are their own names

=head1 VERSION

version 2026.267

=head1 SYNOPSIS

    use constant::string qw( FOO BAR BAZ );

    print FOO;  # Outputs: FOO
    print BAR;  # Outputs: BAR

=head1 DESCRIPTION

This pragma allows you to declare compile-time constants without having to explicitly 
repeat their names as string values. Passing a list of strings to C<use constant::string> 
creates constant subroutines in the caller's namespace where each constant returns 
its own name.

It behaves exactly like the core L<constant> pragma under the hood, meaning these are 
fully optimized, inlined compile-time constants—not regular subroutine calls.

=head1 SEE ALSO

=over 4

=item * L<constant> - The core Perl pragma utilized under the hood.

=back

=head1 AUTHOR

James Wright E<lt>jameswright6@acm.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by James Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
