#!/usr/bin/env perl
#
# Calculate structure offsets by directly asking
# the currently configured compiler.
#
# This will be moved to Win32::API::Packing (or similar)
#
# $Id$

use strict;
use warnings;

use Data::Dumper;
use ExtUtils::CBuilder;
use File::Temp;

sub build_packing_code {
    my ($struct) = @_;

    if (!$struct || ref $struct ne 'ARRAY') {
        return;
    }

    # "void *" fails with MSVC with "unknown size of void *" error
    my $ptr_type = 'char *';

    my $code = <<END_OF_C;
#include <stdio.h>

/* Structure declaration */
struct s1 {
%s
};

struct s1 ts;

int main() {

	/* Start of struct pointer */
	${ptr_type}start = ($ptr_type) &ts;

	/* Moving "member" pointer */
	${ptr_type}p;

	/* Output struct member offsets */
%s
	return 0;
}
END_OF_C

    my @struct_decl   = ();
    my @struct_output = ();

    for my $member (@{$struct}) {
        push @struct_decl, qq{\t$member;};

        my ($type, $name) = split m{\s+}, $member, 2;
        $type =~ s{^\s*}{};
        $name =~ s{\s*$}{};

        push @struct_output,
            qq{\tp = ($ptr_type) &ts.$name;},
            qq{\tprintf("struct.$name\\t%d\\n", p - start);},
            q{};
    }

    $code = sprintf($code, join("\n", @struct_decl), join("\n", @struct_output));

    return $code;
}

sub compile_code {
    my ($code) = @_;

    my $fh = File::Temp->new(SUFFIX => '.c', UNLINK => 0);
    print $fh $code;
    close $fh;

    my $fname    = $fh->filename();
    my $exe_file = "$fname.exe";

    # Use ExtUtils::CBuilder ???
    my $cc     = 'gcc';
    my $cc_cmd = qq{$cc $fname -o $exe_file};
    my $status = system($cc_cmd);
    $status >>= 8;
    if ($status != 0) {
        die "Temp file $fname didn't compile: $!\n";
    }

    unlink $fname;
    return $exe_file;

}

sub compile_code_eucb {
    my ($code) = @_;

    my $fh = File::Temp->new(SUFFIX => '.c', UNLINK => 0);
    print $fh $code;
    close $fh;

    my $fname    = $fh->filename();
    my $exe_file = "$fname.exe";

    my $eucb = ExtUtils::CBuilder->new();
    my $obj_file = $eucb->compile(source => $fname);
    $exe_file = $eucb->link_executable(
        objects  => $obj_file,
        exe_file => $exe_file
    );
    unlink $fname;
    return $exe_file;
}

sub parse_packing_output {
    my ($exe_file) = @_;

    my @output = qx{$exe_file};
    if (!@output) {
        die "Couldn't get any packing info from $exe_file: $!\n";
    }

    my @struct;

    for (@output) {
        next if m{^\s*$};
        chomp;
        my ($member, $offset) = split "\t", $_, 2;
        push @struct, {name => $member, offset => $offset};
    }

    return \@struct;
}

my $struct = ['int i', 'char c1', 'char c2', 'char c3', 'int j',];

my $code = build_packing_code($struct);
my $exe  = compile_code_eucb($code);
if (!$exe) {
    die "Code didn't compile. Too bad.\n";
}

my $packing = parse_packing_output($exe);
print Dumper($packing);

