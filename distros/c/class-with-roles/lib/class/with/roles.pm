package class::with::roles;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-05'; # DATE
our $DIST = 'class-with-roles'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
#use warnings;

sub import {
    my $package = shift;

    my $caller = caller(0);

    my $class = shift;
    $class =~ /\A\w+(\::\w+)*\z/ or die "Invalid class name syntax: $class";

    my $do_class_import = 1;
    my @class_import_args;
    while (@_) {
        if ($_[0] eq '!') {
            $do_class_import = 0;
            shift;
            last;
        } elsif ($_[0] =~ /\A\+./) {
            last;
        }
        push @class_import_args, shift;
    }
    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;
    if ($do_class_import) {
        eval "package $caller; $class->import(\@class_import_args);";
        die if $@;
    }

    my @roles;
    while (@_) {
        # when there is support for parameterized roles, we'll allow this:
        # "+My::Role1", "import1", "import2", "+My::Role2", "import-for-role2",
        # "another", ...
        $_[0] =~ /\A\+(.+)\z/
            or die "Please specify role with +Role::Name syntax";
        push @roles, $1;
        shift;
    }
    if (@roles) {
        require Role::Tiny;
        Role::Tiny->apply_roles_to_package($class, @roles);
    }
}

1;
# ABSTRACT: Shortcut for using a class and applying it some Role::Tiny roles, from the command line

__END__

=pod

=encoding UTF-8

=head1 NAME

class::with::roles - Shortcut for using a class and applying it some Role::Tiny roles, from the command line

=head1 VERSION

This document describes version 0.004 of class::with::roles (from Perl distribution class-with-roles), released on 2020-06-05.

=head1 SYNOPSIS

To be used mainly from the command line:

 % perl -Mclass::with::roles=MyClass,+My::Role1,+My::Role2 -E'...'
 % perl -Mclass::with::roles=MyClass,import1,import2,+My::Role1,+My::Role2 -E'...'
 % perl -Mclass::with::roles=MyClass,'!',+My::Role1,+My::Role2 -E'...'

which is shortcut for:

 % perl -E'use MyClass;                      use Role::Tiny; Role::Tiny->apply_roles_to_package("MyClass", "My::Role1", "My::Role2"); ...'
 % perl -E'use MyClass "import1", "import2"; use Role::Tiny; Role::Tiny->apply_roles_to_package("MyClass", "My::Role1", "My::Role2"); ...'
 % perl -E'use MyClass ();                   use Role::Tiny; Role::Tiny->apply_roles_to_package("MyClass", "My::Role1", "My::Role2"); ...'

but you can also use it from regular Perl code:

 use class::with::roles MyClass => '+My::Role1', '+My::Role2';
 use class::with::roles MyClass => 'import1', 'import2', '+My::Role1', '+My::Role2';
 use class::with::roles MyClass => '!', '+My::Role1', '+My::Role2';

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/class-with-roles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-class-with-roles>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=class-with-roles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::Tiny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
