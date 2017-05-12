package exported::constants;

use strict;
use warnings;

use vars '$VERSION'; $VERSION = '1.0';

use Carp qw/ carp /;

sub import {
    my ($class, @args) = @_;

    my $pkg = caller();

    no strict 'refs';

    push @{$pkg.'::ISA'}, 'Exporter' unless grep { $_ eq 'Exporter' } @{$pkg.'::ISA'};

    while (@args) {
        carp "Last constant $args[0] is missing a definition" unless @args >= 2;

        my ($name, $value) = splice @args, 0, 2;

        *{$pkg.'::'.$name} = sub () { $value };

        push @{$pkg.'::EXPORT'}, $name;
    }
}

1;

=head1 NAME

exported::constants - Declare constants and export them automatically

=head1 SYNOPSIS

    package MyProg::Constants;

    use exported::constants
        USER_TYPE_USER => 'U',
        USER_TYPE_APPLICATION => 'A',
        USER_TYPE_ROBOT => 'B',
    ;

    package MyProg::App;

    use MyProg::Constants;

    my @real_users = $users->search({ user_type => USER_TYPE_USER, });

=head1 DESCRIPTION

This is a boilerplate-removal module for creating modules of just constants in your program.
This is useful if you have a lot of magic numbers you want to eliminate,
especially things that show up in database schemas or APIs that you want to re-use across multiple modules.

It's pretty simple to use;
just say

    use exported::constants
        CONSTANT1 => $value1,
        CONSTANT2 => $value2,
    ;

and your package is automatically an exporter,
and automatically exports (by default) all the constants listed.

=head1 RESTRICTIONS

=over

=item * List constants don't work, because C<exported::constants> is intended to always create multiple constants in a single invocation.

=item * This module always works using C<@EXPORT> in L<Exporter>; this is unfortunate for developers who want to explicitly import all their constants.

=back

=head1 SEE ALSO

=over

=item * L<constant>

=item * L<Exporter>

=back

=head1 AUTHOR

Jonathan Cast <jonathanccast@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Jonathan Cast

Licensed under the Apache License, Version 2.0 (the "License").
