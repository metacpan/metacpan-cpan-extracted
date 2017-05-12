package version::Store;

use 5.010001;
use strict 'vars';
use warnings;

our $VERSION = '0.01'; # VERSION

sub import {
    my $pkg = shift;
    my $caller = caller;
    *{"$caller\::VERSION"} = \&VERSION;
}

sub VERSION {
    require version;

    my ($pkg, $ver) = @_;
    my $caller = caller;
    my $pkg_ver = ${"$pkg\::VERSION"};
    if (!defined $pkg_ver) {
        die "$pkg does not define \$VERSION, $caller wants >= $ver";
    } elsif (version->parse($pkg_ver) < version->parse($ver)) {
        die "$pkg's VERSION is only $pkg_ver, caller wants >= $ver";
    }
    ${"$pkg\::USER_PACKAGES"}{$caller}{version} = $ver;
}

1;
# ABSTRACT: Get your module's minimum/required version from your users

__END__

=pod

=encoding UTF-8

=head1 NAME

version::Store - Get your module's minimum/required version from your users

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your module:

 package YourModule;
 our $VERSION = 0.12;

 use version::Store;
 our %USER_PACKAGES;

 use Exporter;
 our @ISA = qw(Exporter);
 our @EXPORT = qw(foo);

 sub foo {
     my $caller = caller;
     my $min_ver = $USER_PACKAGES{$caller}{min_ver};
     print "foo" . ($min_ver && $min_ver >= 0.11 ? " with extra zazz!" : "");
 }

In code using your module:

 use YourModule;
 foo(); # prints "foo";

In another code:

 use YourModule 0.12;
 foo(); # prints "foo with extra zazz!"

=head1 DESCRIPTION

Sometimes you want to present different features to each user, depending on what
version of your module she requests.

This pragma lets you do that. This is done by installing a C<VERSION()>
subroutine to your module. This subroutine is called by Perl whenever a user
does something like C<use YourModule 0.12> (the C<use MODULE VERSION> form). The
version information is stored in your module's C<%USER_PACKAGES> package
variable, with each calling package as the key and a hashref for each value.
Each hashref contains the key C<version> containing the data.

Alternatively, you can write your own C<VERSION()> when appropriate.

=for Pod::Coverage ^(VERSION)$

=head1 SEE ALSO

C<use> on L<perldoc>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/version-Store>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-version-Store>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=version-Store>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
