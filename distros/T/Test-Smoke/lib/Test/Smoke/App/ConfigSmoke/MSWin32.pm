package Test::Smoke::App::ConfigSmoke::MSWin32;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/ config_mswin32 /;

use Test::Smoke::App::Options;
use Test::Smoke::Util::FindHelpers qw/ get_avail_w32compilers /;
use System::Info::Windows;

=head1 NAME

Test::Smoke::App::ConfigSmoke::MSWin32 - Mixin for L<Test::Smoke::App::ConfigSmoke>

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_mswin32

=cut

sub config_mswin32 {
    my $self = shift;

    print "\n-- MSWin32 section --\n";

    my $osvers = get_Win_version();
    my %compilers = get_avail_w32compilers();

    my $w32cc = uc( $self->handle_option(w32cc_option(\%compilers, $osvers)) );
    my $w32make = $self->handle_option(w32make_option($w32cc, $compilers{$w32cc}));

    $self->current_values->{w32args} = [
        "--win32-cctype" => $w32cc,
        "--win32-maker"  => $w32make,
        "osvers=$osvers",
        $compilers{$w32cc}->{ccversarg},
    ];
}

=head2 get_Win_version()

Use L<System::Info::Windows> to get the version from a windows system.

=cut

sub get_Win_version {
    my $si = System::Info::Windows->new();
    (my $win_version = $si->os) =~ s/^[^-]*- //;
    return $win_version;
}

=head2 w32cc_option

Dynamic option for configuring the Compiler on Windows.

=cut

sub w32cc_option {
    my ($compilers, $osvers) = @_;
    my $compiler_info = join(
        "\n",
        map {
            sprintf("  %-4s - %s", $_, $compilers->{$_}{ccbin})
        } keys %$compilers
    );
    return Test::Smoke::App::AppOption->new(
        name       => 'w32cc',
        helptext   => "Which compiler should be used for $osvers?",
        configtext => $compiler_info,
        configdft  => sub { ( sort keys %$compilers )[-1] },
        configalt  => sub { [ sort keys %$compilers ] },
    );
}

=head2 w32make_option

Dynamic option for configuring the make program on Windows.

=cut

sub w32make_option {
    my ($w32cc, $this_compiler) = @_;
    return Test::Smoke::App::AppOption->new(
        name       => 'w32make',
        helptext   => "Which 'make' should be used for $w32cc?",
        configtext => join(", ", @{$this_compiler->{maker}}),
        configdft  => sub { ( sort @{$this_compiler->{maker}} )[-1] },
        configalt  => sub { [ sort @{$this_compiler->{maker}} ] },
    );
}

1;

=head1 COPYRIGHT

E<copy> 2022, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
