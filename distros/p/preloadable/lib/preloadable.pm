package preloadable;

our $DATE = '2019-03-19'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub import {
    my $class = shift;
    my $mod   = shift;

    (my $mod_pm = "$mod.pm") =~ s!::!/!g;

    if ($ENV{PERL_PRELOAD_MODULES}) {
        require $mod_pm;
    } else {
        require B::Hooks::AtRuntime;
        B::Hooks::AtRuntime::at_runtime(sub { require $mod_pm });
    }
}

1;
# ABSTRACT: Require a module during run-time (or compile-time)

__END__

=pod

=encoding UTF-8

=head1 NAME

preloadable - Require a module during run-time (or compile-time)

=head1 VERSION

This document describes version 0.001 of preloadable (from Perl distribution preloadable), released on 2019-03-19.

=head1 SYNOPSIS

In your script:

 use preloadable 'Foo';

 sub baz {
     use preloadable 'Bar';
     Bar::blah(1, 2);
 }
 baz;

If the environment PERL_PRELOAD_MODULES is false or not defined, the above
script is equivalent to:

 require Foo;
 sub baz {
     require Bar;
     Bar::blah(1, 2);
 }
 baz;

But if PERL_PRELOAD_MODULES is true, the above script is equivalent to:

 BEGIN { require Foo }
 sub baz {
     BEGIN { require Bar }
     Bar::blah(1, 2);
 }
 baz;

which means C<Foo> and C<Bar> are loaded during compile-time.

=head1 DESCRIPTION

With PERL_PRELOAD_MODULES unset or false, this statement:

 use preloadable 'Foo';

is basically equivalent to run-time C<require()>:

 require Foo;

B<preloadable> uses B<B::Hooks::AtRuntime> to perform the C<require()> on
runtime. During runtime, you do take a hit of an extra subroutine call.

With PERL_PRELOAD_MODULES set to true, this statement:

 use preloadable 'Foo';

will simply instruct B<preloadable> to C<require> C<Foo> at compile-time.

=head1 NOTES

L<B::Hooks::AtRuntime>'s startup overhead is a bit heavier than I'd like. Will
probably fork to create a lite alternative.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/preloadable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-preloadable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=preloadable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
