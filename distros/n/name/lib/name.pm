package name;

use 5.008;
use strict;
use warnings;

use Carp 'croak';
use Sub::Util qw(set_prototype set_subname);

our $VERSION = '0.0.0';

sub import {
    my $me = shift;
    my $name = shift or croak "$me: no name given";
    my %args = @_;
    my $alias  = $args{alias}
        or croak "$me: An 'alias' is required with 'use name'";
    my $caller = caller;

    no strict 'refs';
    no warnings 'redefine';

    *{"${caller}::$name"} =
        set_subname "${caller}::$name",
        set_prototype '',
            sub {
                return $alias;
            };
}

1; # End of name

__END__

=head1 NAME

name

=head1 VERSION

Version 0.0.0

=head1 SYNOPSIS

  use name 'bonnie', alias => 'Bonnie Elizabeth Parker';

  print bonnie;

=head1 DESCRIPTION

C<use name> to get one.

=head1 EXPORT

Whenever you C<use name> the first argument is the name of a subroutine that
is exported into your namespace.

=head1 SUBROUTINES

=head2 import

This is called by L<use|perlfunc/use> and handles the C<name> arguments.

=head1 AUTHOR

Bernhard Graf

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/augensalat/perl-name/issues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Bernhard Graf.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

