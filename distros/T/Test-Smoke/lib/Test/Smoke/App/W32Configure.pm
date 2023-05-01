package Test::Smoke::App::W32Configure;
use warnings;
use strict;

our $VERSION = '0.002';

use base 'Test::Smoke::App::Base';

use Cwd;
use System::Info::Windows;
use Test::Smoke::Util qw/Configure_win32/;

=head1 NAME

Test::Smoke::App::W32Configure - Create F<< $ddir\win32\smoke.mk >>

=head1 SYNOPSIS

See also L<bin/tsw32configure.pl>:

    bin/tsw32configure.pl -c smokecurrent -Duseithreads

=head1 DESCRIPTION

This calls L<Test::Smoke::Util/"Configure_win32">

=head2 new

Instantiate the applet.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_verbose} = $self->option('verbose');
    return $self;
}

=head2 $app->run();

run the applet.

=cut

sub run {
    my $self = shift;

    my $w32override;
    my @configure_args = map {
        $w32override = !$w32override && /^--w32override$/;
        $w32override ? () : $_;
    } @{$self->ARGV_EXTRA};

    die "This ($^O) is not MSWin32, use Configure.\n"
        unless $^O eq 'MSWin32' or $w32override;

    push @configure_args, "-DCCTYPE=" . $self->option('w32cc')
        unless grep { /^-DCCTYPE/ } @configure_args;
    my $c_args = join(" ", @configure_args);

    my @cfg_vars = @{ $self->option('w32args') };
    @cfg_vars = @cfg_vars > 4
        ? splice(@cfg_vars, 4)
        : ( 'osvers=' . _Win_version() );


    my $cwd = getcwd();
    chdir($self->option('ddir')) or
        die sprintf("Cannot chdir(%s): %s", $self->option('ddir'), $!);

    $self->log_info("./Configure [$c_args] %s '@cfg_vars'", $self->option('w32make'));
    Configure_win32( "./Configure $c_args", $self->option('w32make'), @cfg_vars );

    chdir($cwd);
};

sub _Win_version {
    my $si = System::Info::Windows->new();
    (my $win_version = $si->os) =~ s/^[^-]*- //;
    return $win_version;
}

1;

=head1 COPYRIGHT

(c) 2020, Abe Timmerman <abeltje@cpan.org> All rights reserved.

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
