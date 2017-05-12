use strict;
use warnings;
package WebService::SendGrid::Newsletter::Base;

use Carp;

# Checks if the required arguments are present

sub _check_required_args {
    my ($self, $required_args, %args) = @_;

    foreach my $arg ( @{$required_args} ) {
        if (!exists $args{$arg}) {
            croak "Required parameter '$arg' is not defined";
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Base

=head1 VERSION

version 0.02

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
