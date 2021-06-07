package lib::noop::missing;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-07'; # DATE
our $DIST = 'lib-noop'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

use Module::Installed::Tiny qw(module_source);

my $opt_warn;
our $noop_code = "1;\n";

our $hook;
$hook = sub {
    my ($self, $file) = @_;

    # prevent infinite recursion
    local @INC = grep { "$_" ne "$hook" } @INC;

    my $src;
    eval { $src = module_source($file) };
    if (!defined($src) && $opt_warn) {
        warn "Warning: Loading of $file is no-op'ed because it is missing\n";
    }

    return defined $src ? \$src : \$noop_code;
};

sub import {
    my $class = shift;

    $opt_warn = @_ && $_[0] eq '-warn' ? 1:0;
    @INC = ($hook, grep { $_ ne "$hook" } @INC);
}

sub unimport {
    return unless $hook;
    @INC = grep { "$_" ne "$hook" } @INC;
}

1;
# ABSTRACT: no-op loading of missing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::noop::missing - no-op loading of missing modules

=head1 VERSION

This document describes version 0.006 of lib::noop::missing (from Perl distribution lib-noop), released on 2021-06-07.

=head1 SYNOPSIS

 use lib::noop::missing;
 use Data::Dumper; # loads as usual
 use Foo::Bar; # a no-op because, say, this module is missing

On the command-line, checking script syntax, ignoring missing modules:

 % perl -Mlib::noop::missing -c your-script.pl
 ...

 % perl -Mlib::noop::missing=-warn -c your-script.pl
 Warning: Loading of Foo/Bar.pm is no-op'ed because it is missing
 ...

=head1 DESCRIPTION

This pragma installs an C<@INC> handler that will no-op module loading (via
C<use> or C<require>) for missing modules. In the case of module missing, Perl
will be tricked to just execute C<"1;"> and move on.

This pragma can be used for testing or for "checking syntax while ignoring
missing modules" in the simplistic cases.

Note that even though the loading is "no-op"-ed, the C<%INC> entry for the
module will still be added, making subsequent loading of the same module a truer
no-op because Perl's C<require()> will see that the entry for the module in
C<%INC> already exists and skips executing the C<@INC> handler altogether.

Also note that since the loading becomes a no-op operation, and no code other
than C<"1;"> is executed during loading, if the original module contains
function or package variable definition, they obviously will not be defined and
your module-using code will be affected.

To cancel the effect of this pragma, you can unimport it. If you then want to
actually load a module that has been no-op'ed, you have to delete its C<%INC>
entry first:

 use lib::noop::missing;
 use Foo::Bar; # loading will be no-op'ed if the module is missing

 no lib::noop::all;
 use Foo::Bar; # this now dies

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-noop>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-noop>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-noop>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::noop>

L<lib::noop::all>

L<lib::noop::except>

L<lib::disallow> will do the opposite: making existing modules unloadable.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
