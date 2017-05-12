package Test::Install::METArequires;

=head1 NAME

Test::Install::METArequires - TAP output of installing requires listed in META.yml

=head1 SYNOPSIS

    use Test::Install::METArequires;
    Test::Install::METArequires->t();

    prove -Ilib `perl -MTest::iMETAr -le 'print Test::iMETAr->t_file'` t/

=head1 DESCRIPTION

Reads F<META.yml> in current folder and tries to install any of the
C<configure_requires>, C<build_requires>, C<requires> modules listed
there. Output is TAP - one test line (OK/FAIL) per module with note output.

=cut

use warnings;
use strict;

use YAML::Syck ();
use IPC::Run 'run', 'timeout';
use Test::Builder;
use File::Basename 'fileparse';

our $VERSION = '0.03';

my $tb = Test::Builder->new();

=head1 METHODS

=head2 t

Install requires listed in META.yml and output results as TAP.

=cut

sub t {
    my $self = shift;
    
    my $meta = eval { YAML::Syck::LoadFile('META.yml') };
    if ($@) {
        $tb->plan( skip_all => $@ );
        return;
    }
    
    my %configure_requires = eval { %{$meta->{'configure_requires'}} };
    my %build_requires     = eval { %{$meta->{'build_requires'}} };
    my %requires           = eval { %{$meta->{'requires'}} };
    
    $tb->plan('tests' => ((keys %requires) + (keys %build_requires) + (keys %configure_requires)));
    
    $tb->note('--- configure_requires ---');
    while (my ($module, $version) = each %configure_requires) {
        $self->install($module, $version);
    }
    $tb->note('--- build_requires ---');
    while (my ($module, $version) = each %build_requires) {
        $self->install($module, $version);
    }
    $tb->note('--- requires ---');
    while (my ($module, $version) = each %requires) {
        $self->install($module, $version);
    }
}

=head2 install($module, $version)

Do C<cpan -i $module> if the required C<$version> is not jet
installed.

If L<dbedia::Debian> is loaded. It will install modules from Debian packages
if available. Or at least module dependencies if higher version is required
than it is available in Debian.

Set C<$ENV{IMETAR_SUDO}> to true if `sudo` has to be executed before each
C<cpan> or C<apt-get> commands.

=cut

sub install {
    my $self    = shift;
    my $module  = shift;
    my $version = shift;
    
    my $test_name = $module.' version >='.$version;

    # skip installing modules already in the system
    eval "use $module $version;";
    if (not $@) {
        $tb->skip('already have '.$test_name);
        return;
    }
    
    # use `sudo ...` if required
    my @sudo = ();
    push @sudo, 'sudo'
        if $ENV{IMETAR_SUDO};
    
    # install module
    my ($in, $out, $dep_out) = ('', '', '');
    my @run = (@sudo, 'cpan', '-i', $module);

    # install Debian package if there is one and dbedia::Debian is loaded
    if ($INC{'dbedia/Debian.pm'}) {
        my $package_name = dbedia::Debian->find_perl_module_package($module, $version);
        if ($package_name) {
            @run = (@sudo, 'apt-get', 'install', '--yes', $package_name);
        }
        # if not found for that version try to find an old version and install build dependecies
        else {
            $package_name = dbedia::Debian->find_perl_module_package($module);
            run [ @sudo, 'apt-get', 'build-dep', '--yes', $package_name ], \$in, \$dep_out, \$dep_out, timeout( $self->cpan_i_timeout )
                if ($package_name);
        }
    }
    
    if (run [ @run ], \$in, \$out, \$out, timeout( $self->cpan_i_timeout )) {
        eval "use $module $version;";
        if ($@) {
            $tb->ok(0, $test_name);
            $tb->note($dep_out.$out);
            $tb->note($@);
        }
        else {
            $tb->ok(1, $test_name);
        }
    }
    else {
        $tb->ok(0, $test_name.' - timeout');
        $tb->note($out);
    }
}

=head2 cpan_i_timeout

Set/get timeout for one `cpan -i ...` execution. Default is 1h.

=cut

my $cpan_i_timeout = 60*60;    # default timeout is 1h
sub cpan_i_timeout {
    my $self    = shift;

    $cpan_i_timeout = shift @_
        if (@_ > 0);

    return $cpan_i_timeout;
}

=head2 t_file

Return the location of F<METArequires.t> file.

=cut

sub t_file {
    my ($filename, $dirname) = fileparse($INC{"Test/Install/METArequires.pm"}, '.pm');
    return $dirname.$filename.'.t';
}

=head2 t_debian_file

Return the location of F<METArequires-Debian.t> file.

=cut

sub t_debian_file {
    my ($filename, $dirname) = fileparse($INC{"Test/Install/METArequires.pm"}, '.pm');
    return $dirname.$filename.'-Debian.t';
}

1;


__END__

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-install-metarequires at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Install-METArequires>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Install::METArequires


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Install-METArequires>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Install-METArequires>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Install-METArequires>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Install-METArequires/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Install::METArequires
