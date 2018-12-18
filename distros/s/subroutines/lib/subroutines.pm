package subroutines;

our $DATE = '2018-12-15'; # DATE
our $VERSION = '0.001'; # VERSION

#use strict 'subs', 'vars';

sub _package_exists {
    my $pkg = shift;

    if ($pkg =~ s/::(\w+)\z//) {
        return !!${$pkg . "::"}{$1 . "::"};
    } else {
        return !!$::{$pkg . "::"};
    }
}

sub import {
    my $class = shift;
    my $noreq = $_[0] eq '-norequire' ? shift : 0;
    my $orig  = shift;

    my $caller = caller();

    unless ($noreq) {
        (my $orig_pm = "$orig.pm") =~ s!::!/!g;
        require $orig_pm;
    }

    die "Cannot use subroutines from '$orig': package does not exist" unless
        _package_exists($orig);

    my $symtbl = \%{$orig . "::"};

    while (my ($k, $v) = each %$symtbl) {
        next if $k =~ /::$/; # subpackage
        if ("$v" !~ /^\*/) {
            # constant
            *{"$caller\::$k"} = \*{$orig . "::"};
        } elsif (defined *$v{CODE}) {
            # subroutine
            *{"$caller\::$k"} = *$v{CODE};
        }
    }
}

1;
# ABSTRACT: Use subroutines from another module

__END__

=pod

=encoding UTF-8

=head1 NAME

subroutines - Use subroutines from another module

=head1 VERSION

This document describes version 0.001 of subroutines (from Perl distribution subroutines), released on 2018-12-15.

=head1 SYNOPSIS

 package Your::Module;
 use subroutines 'Another::Module';

To avoid require()-ing:

 use subroutines '-norequire', 'Another::Module';

=head1 DESCRIPTION

This pragma declares routines in your module that are copied from another
module.

 package Your::Module;
 use subroutines 'Another::Module';

is equivalent to this pseudo-code:

 package Your::Module;
 BEGIN {
     require Another::Module;
     for my $name (all_subroutines_in("Another::Module")) {
         *{"Your::Module::$name"} = \&{"Another::Module::$name"};
     }
 }

This is a form of code reuse when you cannot do:

 package Your::Module;
 use parent 'Another::Module';

because the original subroutines do not expect to be called as methods, and/or
when your subroutines are not called as methods.

Another alternative is to declare C<Your::Module> as an alias of
C<Another::Module>, e.g. using L<alias::module>.

 package Your::Module;
 use alias::module 'Another::Module';

but this copies everythng, not just subroutines.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/subroutines>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-subroutines>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=subroutines>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<alias::module>

L<parent>, L<base>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
