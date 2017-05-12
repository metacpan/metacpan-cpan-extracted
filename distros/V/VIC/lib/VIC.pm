package VIC;
use strict;
use warnings;

use Env qw(@PATH);
use File::Spec;
use File::Which qw(which);
use Capture::Tiny ':all';
use VIC::Parser;
use VIC::Grammar;
use VIC::Receiver;
use base qw(Exporter);

our @EXPORT = qw(
    compile
    assemble
    simulate
    supported_chips
    supported_simulators
    gpasm
    gplink
    gputils
    bindir
    is_chip_supported
    is_simulator_supported
    list_chip_features
);

our $Debug = 0;
our $Verbose = 0;
our $Intermediate = 0;
our $GPASM;
our $GPLINK;
our $GPUTILSDIR;

our $VERSION = '0.31';
$VERSION = eval $VERSION;

sub compile {
    my ($input, $pic) = @_;

    die "No code given to compile\n" unless $input;
    my $parser = VIC::Parser->new(
        grammar => VIC::Grammar->new,
        receiver => VIC::Receiver->new(
                    pic_override => $pic,
                    intermediate_inline => $Intermediate,
                ),
        debug => $Debug,
        throw_on_error => 1,
    );

    my $output = $parser->parse($input);
    my $chip = $parser->receiver->current_chip();
    my $sim = $parser->receiver->current_simulator();
    return wantarray ? ($output, $chip, $sim) : $output;
}

sub supported_chips { return VIC::Receiver::supported_chips(); }

sub supported_simulators { return VIC::Receiver::supported_simulators(); }

sub is_chip_supported { return VIC::Receiver::is_chip_supported(@_) };

sub is_simulator_supported { return VIC::Receiver::is_simulator_supported(@_) };

sub list_chip_features { return VIC::Receiver::list_chip_features(@_) };

sub print_pinout { return VIC::Receiver::print_pinout(@_) };

sub _load_gputils {
    my ($gpasm, $gplink, $bindir);
    my ($stdo, $stde) = capture {
        my $alien;
        eval q{
            require Alien::gputils;
            $alien = Alien::gputils->new();
        } or warn "Cannot find Alien::gputils. Ignoring\n";
        if ($alien) {
            print "Looking for gpasm and gplink using Alien::gputils\n" if $Verbose;
            $gpasm = $alien->gpasm() if $alien->can('gpasm');
            $gplink = $alien->gplink() if $alien->can('gplink');
            $bindir = $alien->bin_dir() if $alien->can('bin_dir');
        }
        unless (defined $gpasm and defined $gplink) {
            print "Looking for gpasm and gplink in \$ENV{PATH}\n" if $Verbose;
            $gpasm = which('gpasm');
            $gplink = which('gplink');
        }
        unless (defined $bindir) {
            if ($gpasm) {
                my @dirs = File::Spec->splitpath($gpasm);
                pop @dirs if @dirs;
                $bindir = File::Spec->catdir(@dirs) if @dirs;
            }
        }
    };
    if ($Verbose) {
        print $stdo if $stdo;
        print STDERR $stde if $stde;
        print "Using gpasm: $gpasm\n" if $gpasm;
        print "Using gplink: $gplink\n" if $gplink;
        print "gputils installed in: $bindir\n" if $bindir;
    }
    $GPASM = $gpasm;
    $GPLINK = $gplink;
    $GPUTILSDIR = $bindir;
    return wantarray ? ($gpasm, $gplink, $bindir) : [$gpasm, $gplink, $bindir];
}

sub _load_simulator {
    my $simtype = shift;
    my $simexe;
    die "Simulator type $simtype not supported yet\n" unless $simtype eq 'gpsim';
    if ($^O =~ /mswin32/i) {
        foreach (qw{PROGRAMFILES ProgramFiles PROGRAMFILES(X86)
            ProgramFiles(X86) ProgamFileW6432 PROGRAMFILESW6432}) {
            next unless exists $ENV{$_};
            my $dir = ($ENV{$_} =~ /\s+/) ? Win32::GetShortPathName($ENV{$_}) : $ENV{$_};
            push @PATH, File::Spec->catdir($dir, $simtype, 'bin') if $dir;
        }
        $simexe = which("$simtype.exe");
        $simexe = which($simtype) unless $simexe;
    } else {
        $simexe = which($simtype);
    }
    print "$simtype found at $simexe\n" if ($Verbose and $simexe);
    warn "$simtype not found\n" unless $simexe;
    return $simexe;
}

sub gputils {
    return ($GPASM, $GPLINK, $GPUTILSDIR) if (defined $GPASM and defined $GPLINK
                                                and defined $GPUTILSDIR);
    return &_load_gputils();
}

sub gpasm {
    return $GPASM if defined $GPASM;
    my @out = &_load_gputils();
    return $out[0];
}

sub gplink {
    return $GPLINK if defined $GPLINK;
    my @out = &_load_gputils();
    return $out[1];
}

sub bindir {
    return $GPUTILSDIR if defined $GPUTILSDIR;
    my @out = &_load_gputils();
    return $out[2];
}

sub assemble($$) {
    my ($chip, $output) = @_;
    return unless defined $chip;
    return unless defined $output;
    my $hexfile = $output;
    my $objfile = $output;
    my $codfile = $output;
    my $stcfile = $output;
    if ($output =~ /\.asm$/) {
        $hexfile =~ s/\.asm$/\.hex/g;
        $objfile =~ s/\.asm$/\.o/g;
        $codfile =~ s/\.asm$/\.cod/g;
        $stcfile =~ s/\.asm$/\.stc/g;
    } else {
        $hexfile = $output . '.hex';
        $objfile = $output . '.o';
        $codfile = $output . '.hex';
        $stcfile = $output . '.o';
    }
    my ($gpasm, $gplink, $bindir) = VIC::gputils();
    unless (defined $gpasm and defined $gplink and -e $gpasm and -e $gplink) {
        die "Cannot find gpasm/gplink to compile $output into a hex file $hexfile.";
    }
    my ($inc1, $inc2) = ('', '');
    if (defined $bindir) {
        my @dirs = File::Spec->splitdir($bindir);
        my $l = pop @dirs if @dirs;
        if (defined $l and $l ne 'bin') {
            push @dirs, $l; # return the last directory
        }
        my @includes = ();
        my @linkers = ();
        push @includes, File::Spec->catdir(@dirs, 'header');
        push @linkers, File::Spec->catdir(@dirs, 'lkr');
        push @includes, File::Spec->catdir(@dirs, 'share', 'gputils', 'header');
        push @linkers, File::Spec->catdir(@dirs, 'share', 'gputils', 'lkr');
        foreach (@includes) {
            $inc1 .= " -I $_ " if -d $_;
        }
        foreach (@linkers) {
            $inc2 .= " -I $_ " if -d $_;
        }
    }
    $codfile = File::Spec->rel2abs($codfile);
    $stcfile = File::Spec->rel2abs($stcfile);
    $hexfile = File::Spec->rel2abs($hexfile);
    $objfile = File::Spec->rel2abs($objfile);
    my $gpasm_cmd = "$gpasm $inc1 -p $chip -M -c $output";
    my $gplink_cmd = "$gplink $inc2 -q -m -o $hexfile $objfile ";
    print "$gpasm_cmd\n" if $Verbose;
    system($gpasm_cmd) == 0 or die "Unable to run '$gpasm_cmd': $?";
    print "$gplink_cmd\n" if $Verbose;
    system($gplink_cmd) == 0 or die "Unable to run '$gplink_cmd': $?";
    my $fh;
    open $fh, ">$stcfile" or die "Unable to write $stcfile: $?";
    print $fh "load s '$codfile'\n";
    close $fh;
    return { hex => $hexfile, obj => $objfile, cod => $codfile, stc => $stcfile };
}

sub simulate {
    my ($sim, $hh) = @_;
    my $stc;
    if (ref $hh eq 'HASH') {
        $stc = $hh->{stc};
    } elsif (ref $hh eq 'ARRAY') {
        ($stc) = grep {/\.stc$/} @$hh;
    } else {
        $stc = $hh;
    }
    die "Cannot find $stc to run the simulator $sim on\n" unless (defined $stc and -e $stc);
    my $simexe = &_load_simulator($sim);
    die "$sim is not present in your system PATH for simulation\n" unless $simexe;
    my $sim_cmd = "$simexe $stc";
    print "$sim_cmd\n" if $Verbose;
    system($sim_cmd) == 0 or die "Unable to run '$sim_cmd': $?";
    1;
}

1;

=encoding utf8

=head1 NAME

VIC - A Viciously Simple Syntax for PIC Microcontrollers

=head1 SYNOPSIS

    $ vic program.vic -o program.asm

    $ vic -h

=head1 DESCRIPTION

Refer documentation at L<http://selectiveintellect.github.io/vic/>.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014-2016. Vikas N Kumar

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
