package Test::Smoke;
use strict;

use vars qw($conf);
our $VERSION  = "1.84";

use base 'Exporter';
our @EXPORT  = qw( $conf &read_config &run_smoke );

my $ConfigError;

use File::Spec;
use Test::Smoke::Policy;
use Test::Smoke::BuildCFG;
use Test::Smoke::Smoker;
use Test::Smoke::SourceTree qw( :mani_const );
use Test::Smoke::Util qw( get_patch skip_config
                          get_local_patches set_local_patch );
use Config;

=head1 NAME

Test::Smoke - The Perl core test smoke suite

=head1 SYNOPSIS

    use Test::Smoke;

    use vars qw( $VERSION );
    $VERSION = Test::Smoke->VERSION;

    read_config( $config_name ) or warn Test::Smoke->config_error;


=head1 DESCRIPTION

If you are looking to get started, start at the B<README>!

C<Test::Smoke> exports C<$conf> and C<read_config()> by default.

=head2 Test::Smoke::read_config( $config_name )

Read (require) the configfile.

=cut

sub read_config {
    my( $config_name ) = @_;

    $config_name = 'smokecurrent_config'
        unless defined $config_name && length $config_name;
    $config_name .= '_config'
        unless $config_name =~ /_config$/ || -f $config_name;

    # Enable reloading by hackery
    local @INC = ( File::Spec->curdir, @INC );
    delete $INC{ $config_name } if exists $INC{ $config_name };
    eval { require $config_name };
    $ConfigError = $@ ? $@ : undef;

    return defined $ConfigError ? undef : 1;
}

=head2 Test::Smoke->config_error()

Return the value of C<$ConfigError>

=cut

sub config_error {
    return $ConfigError;
}

=head2 is_win32( )

C<is_win32()> returns true if  C<< $^O eq "MSWin32" >>.

=cut

sub is_win32() { $^O eq "MSWin32" }

=head2 do_manifest_check( $ddir, $smoker )

C<do_manifest_check()> uses B<Test::Smoke::SourceTree> to do the
MANIFEST check.

=cut

sub do_manifest_check {
    my( $ddir, $smoker ) = @_;

    my $tree = Test::Smoke::SourceTree->new( $ddir );
    my $mani_check = $tree->check_MANIFEST( 'mktest.out', 'mktest.rpt' );
    foreach my $file ( sort keys %$mani_check ) {
        if ( $mani_check->{ $file } == ST_MISSING ) {
            $smoker->log( "MANIFEST declared '$file' but it is missing\n" );
        } elsif ( $mani_check->{ $file } == ST_UNDECLARED ) {
            $smoker->log( "MANIFEST did not declare '$file'\n" );
        }
    }
}

=head2 set_smoke_patchlevel( $ddir, $patch[, $verbose] )

Set the current patchlevel as a registered patch like "SMOKE$patch"

=cut

sub set_smoke_patchlevel {
    my( $ddir, $patch, $verbose ) = @_;
    $ddir && $patch or return;

    my @smokereg = grep
        /^SMOKE[a-fA-F0-9]+$/
    , get_local_patches( $ddir, $verbose );
    @smokereg or set_local_patch( $ddir, "SMOKE$patch" );
}

=head2 run_smoke( [$continue[, @df_buildopts]] )

C<run_smoke()> sets up de build environment and gets the private Policy
file and build configurations and then runs the smoke stuff for all
configurations.

All arguments after the C<$continue> are taken as default buildoptions
and passed to C<./Configure>.

=cut

sub run_smoke {
    my $continue = shift;
    defined $continue or $continue = $conf->{continue};

    my @df_buildopts = @_ ? grep /^-[DUA]/ => @_ : ();
    # We *always* want -Dusedevel!
    push @df_buildopts, '-Dusedevel'
        unless grep /^-Dusedevel$/ => @df_buildopts;
    Test::Smoke::BuildCFG->config( dfopts => join " ", @df_buildopts );

    my $patch = Test::Smoke::Util::get_patch( $conf->{ddir} );

    { # I cannot find a better place to stick this (thanks Bram!)
      # change 33961 introduced Test::Harness 3 for 5.10.x
      # that needs different parsing, so set the config to do that
      # 20081220; new patchlevels due to git; cannot test it like an int
        if ( $conf->{perl_version} eq '5.10.x' ) {
            $conf->{hasharness3} = 1;
        }
    }

    my $logfile = File::Spec->catfile( $conf->{ddir}, 'mktest.out' );
    my $BuildCFG = $continue
        ? Test::Smoke::BuildCFG->continue( $logfile, $conf->{cfg},
                                           v => $conf->{v} )
        : Test::Smoke::BuildCFG->new( $conf->{cfg}, v => $conf->{v} );

    local *LOG;
    my $mode = $continue ? ">>" : ">";
    open LOG, "$mode $logfile" or die "Cannot create 'mktest.out': $!";

    my $Policy   = Test::Smoke::Policy->new( File::Spec->updir, $conf->{v},
                                             $BuildCFG->policy_targets );

    my $smoker   = Test::Smoke::Smoker->new( \*LOG, $conf );
    $smoker->mark_in;

    $conf->{v} && $conf->{defaultenv} and
        $smoker->tty( "Running smoke tests without \$ENV{PERLIO}\n" );

    my $harness_msg;
    if ( $conf->{harnessonly} ) {
        $harness_msg = "Running test suite only with 'harness'";
        $conf->{harness3opts} and
            $harness_msg .= " with HARNESS_OPTIONS=$conf->{harness3opts}";
    }
    $conf->{v} && $harness_msg and $smoker->tty( "$harness_msg.\n" );

    chdir $conf->{ddir} or die "Cannot chdir($conf->{ddir}): $!";
    unless ( $continue ) {
        $smoker->make_distclean( );
        $smoker->ttylog("Smoking patch $patch->[0] $patch->[1]\n");
        $smoker->ttylog("Smoking branch $patch->[2]\n") if $patch->[2];
        do_manifest_check( $conf->{ddir}, $smoker );
        set_smoke_patchlevel( $conf->{ddir}, $patch->[0] );
    }

    foreach my $this_cfg ( $BuildCFG->configurations ) {
        $smoker->mark_out; $smoker->mark_in;
        if ( skip_config( $this_cfg ) ) {
            $smoker->ttylog( "Skipping: '$this_cfg'\n" );
            next;
        }

        $smoker->ttylog( join "\n",
                              "", "Configuration: $this_cfg", "-" x 78, "" );
        $smoker->smoke( $this_cfg, $Policy );
    }

    $smoker->ttylog( "Finished smoking $patch->[0] $patch->[1] $patch->[2]\n" );
    $smoker->mark_out;

    close LOG or do {
        require Carp;
        Carp::carp "Error on closing logfile: $!";
   };
}

1;

=head1 COPYRIGHT

(c) 2003, All rights reserved.

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
