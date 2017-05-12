package VIC::Command;

use strict;
use warnings;
use Getopt::Long;
use VIC;

our $VERSION = '0.31';
$VERSION = eval $VERSION;

sub usage {
    my $usage = << '...';
    Usage: vic [options] <input file>

        -h, --help            This help message
        --version             Version number
        --verbose             Verbose printing during compilation
        -p, --pic <PIC>       Use this PIC choice instead of the one in the code
        -o, --output <file>   Writes the compiled syntax to the given output file
        -d, --debug           Dump the compile tree for debugging
        -i, --intermediate    Inline the intermediate code with the output
        --simulate            Simulate the code that was compiled
        --list-chips          List the supported microcontroller chips
        --list-simulators     List the supported simulators
        --check <PIC>         Checks if the given PIC is supported
        --list-features <PIC> Lists the features of the PIC
        --chip-pinout <PIC>   Draws the pin diagram of the PIC on screen
        --no-hex              Does not generate the hex file using gputils
        --list-gputils        List the path for the gputils executables

...
    die $usage;
}

sub version {
    my $txt = << "...";
VIC version $VERSION
...
    die $txt;
}

sub print_chips {
    my @chips = VIC::supported_chips();
    my $ctxt = join("\n", @chips);
    my $txt = << "...";
VIC supports the following microcontroller chips:
$ctxt

...
    print $txt;
}

sub print_sims {
    my @sims = VIC::supported_simulators();
    my $stxt = join("\n", @sims);
    my $txt = << "...";
VIC supports the following simulators:
$stxt

...
    print $txt;
}

sub list_gputils {
    my @utils = VIC::gputils();
    if (@utils) {
        print "gpasm: $utils[0]\ngplink: $utils[1]\n";
    } else {
        print "No gputils found.";
    }
}

sub check_support {
    my $chip = shift;
    my $flag = VIC::is_chip_supported($chip);
    die "VIC does not support '$chip'\n" unless $flag;
    unless (@_) {
        print "VIC supports '$chip'\n" if $flag;
    }
}

sub list_features {
    my $chip = shift;
    check_support($chip);
    my $hh = VIC::list_chip_features($chip);
    if ($hh) {
        my $rtxt = join("\n", @{$hh->{roles}});
        print "\n$chip supports the following features:\n$rtxt\n";
        print "\n$chip has the following memory capabilities:\n";
        my $mh = $hh->{memory};
        foreach (keys %$mh) {
            my $units = 'bytes';
            $units = 'words' if $_ =~ /flash/i; # HACK
            print "$_: " . $mh->{$_} . " $units\n";
        }
    }
}

sub chip_pinouts {
    my $chip = shift;
    check_support($chip, 1);
    VIC::print_pinout($chip);
}

sub run {
    my ($class, @args) = @_;
    local @ARGV = @args;

    my $debug = 0;
    my $output = '';
    my $help = 0;
    my $pic = undef;
    my $intermediate = undef;
    my $version = 0;
    my $verbose = 0;
    my $list_chips = 0;
    my $list_sims = 0;
    my $check_support = undef;
    my $chip_features = undef;
    my $chip_pinouts = undef;
    my $no_hex = 0;
    my $list_gputils = 0;
    my $simulate = 0;

    GetOptions(
        "output=s" => \$output,
        "debug" => \$debug,
        "help" => \$help,
        "pic=s" => \$pic,
        "intermediate" => \$intermediate,
        "version" => \$version,
        "verbose" => \$verbose,
        "list-chips" => \$list_chips,
        "list-simulators" => \$list_sims,
        "list-features=s" => \$chip_features,
        "chip-pinout=s" => \$chip_pinouts,
        "check=s" => \$check_support,
        "no-hex" => \$no_hex,
        "list-gputils" => \$list_gputils,
        "simulate" => \$simulate,
    ) or usage();
    usage() if $help;
    version() if $version;
    print_chips() if $list_chips;
    print_sims() if $list_sims;
    check_support($check_support) if $check_support;
    list_features($chip_features) if $chip_features;
    chip_pinouts($chip_pinouts) if $chip_pinouts;
    list_gputils() if $list_gputils;
    return if ($list_chips or $list_sims or $check_support or
                $chip_features or $list_gputils or $chip_pinouts);

    $VIC::Debug = $debug;
    $VIC::Intermediate = $intermediate;
    $VIC::Verbose = $verbose;

    my $fh;
    if (length $output) {
        $no_hex = 1 if $output =~ /\.asm$/;
        $output =~ s/\.hex$/\.asm/g;
        open $fh, ">$output" or die "Unable to open $output: $!";
    } else {
        $fh = *STDOUT;
        $no_hex = 1; # no file name given so print to screen
    }
    return usage() unless scalar @ARGV;
    if (defined $pic) {
        $pic =~ s/^PIC/P/gi;
        $pic = lc $pic;
    }
    my ($compiled_out, $chip, $sim) = VIC::compile(do {local $/; <>}, $pic);
    print $fh $compiled_out;
    warn "Cannot simulate unless -o/--output option is used." if ($simulate and $no_hex);
    return if $no_hex;
    my $ret = VIC::assemble($chip, $output) if length $output;
    return $ret unless $simulate;
    return VIC::simulate($sim, $ret);
}

1;

=encoding utf8

=head1 NAME

VIC::Command

=head1 SYNOPSIS

The command-line tool for compiling VIC files.

=head1 DESCRIPTION

To view all the options run 
    $ vic -h


=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014. Vikas N Kumar

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
