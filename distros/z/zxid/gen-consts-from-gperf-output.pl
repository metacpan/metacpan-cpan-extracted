#!/usr/bin/perl
# Copyright (c) 2006,2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing. See file COPYING.
# $Id: gen-consts-from-gperf-output.pl,v 1.5 2009-08-30 15:09:26 sampo Exp $
# 28.5.2006, created --Sampo
# 19.11.2010, adapted to single elem hash --Sampo
#
# Digest gperf generated hash tables and generate corresponding constants
# Usage: ./gen-consts-from-gperf-output.pl zx_ c/zx-ns.c c/zx-attrs.c c/zx-elems.c >c/zx-const.h

$prefix = shift;
$ns_tab = shift;
$at_tab = shift;
$el_tab = shift;

sub readall {
    my ($f) = @_;
    my ($pkg, $srcfile, $line) = caller;
    local $/ = undef ;         # Read all in, without breaking on lines
    open F, "<$f" or die "$srcfile:$line: Cant read($f): $!";
    binmode F;
    #flock F, 1;
    my $x = <F>;
    #flock F, 8;
    close F;
    return $x;
}

sub process_ns_tab {
    my ($x) = @_;
    print "/* namespaces */\n";
    my ($y) = $x =~ /struct zx_ns_s zx_ns_tab\[\] =\s+\{\s+(.*?)\s+\};/s;
    #warn "$i: $ARGV[$i] tab($y)";  # Output can be rather sizeable
    $y =~ s/\#line \d+ ".*?"\n//gs;
    $y =~ s/^\s*\{//s;
    $y =~ s/\}$//s;
    #warn "$i: ($ARGV[$i]) got($y)";
    my @a = split /\},\s+\{/s, $y;
    die "Danger of exhaustation of NS space" if $#a >250;
    for ($j = 0; $j <= $#a; ++$j) {
	# {"urn:x-demo:me:2006-01", sizeof("urn:x-demo:me:2006-01")-1, sizeof("demomed")-1, "demomed", 0,0,0,0,0,0,0},
	# N.B. split already stripped the curlies and comma
	#                      URI  sizeof   sizeof       1 nsprefix 1
	my ($nsprefix) = $a[$j] =~ /^".*?",\s*[^,]+,\s*[^,]+,\s*"(.*?)",/;
	next if !$nsprefix;  # Do not gen consts for padding to make hash right
	die "Duplicate nsprefix($nsprefix) prev=$ns_const{$nsprefix}" if $ns_const{$nsprefix};
	$ns_const{$nsprefix} = $j << 16;
	printf "#define $prefix${nsprefix}_NS\t0x%08x\n", $ns_const{$nsprefix};
    }
    print "#define ${prefix}_NS_MAX\t$j\n";
}

sub process_at_tab {
    my ($x) = @_;
    print "/* attributes */\n";
    my ($y) = $x =~ /struct zx_at_tok zx_at_tab\[\] =\s+\{\s+(.*?)\s+\};/s;
    #warn "$i: $ARGV[$i] tab($y)";  # Output can be rather sizeable
    $y =~ s/\#line \d+ ".*?"\n//gs;
    $y =~ s/^\s*\{//s;
    $y =~ s/\}$//s;
    #warn "$i: ($ARGV[$i]) got($y)";
    my @a = split /\},\s+\{/s, $y;
    die "Danger of exhaustation of ATTR space" if $#a >= 0x0000ff00;
    for ($j = 0; $j <= $#a; ++$j) {
	my ($name) = $a[$j] =~ /^"(.*?)"/;
	next if !$name;  # Do not gen consts for padding to make hash right
	$name = "$prefix${name}_ATTR";
	die "Duplicate attr name($name)" if $name_used{$name}++;
	printf "#define $name\t0x%06x\n", $j;
    }
    print "#define ${prefix}_ATTR_MAX\t$j\n";
}

sub process_el_tab {
    my ($x) = @_;
    print "/* elems */\n";
    # Extract from comments in union declarations the lists of namespace
    # qualified elements that the hash key corresponds
    #while ($x =~ /union zx_(\w+)_u \{(.*?)\};/gs) {
	#$name = $1;
	#$lines = $2;
	##warn "name($name) lines($lines)";
	#for $line (split /\n/, $lines) {
	#    ($els) = $line =~ m%; /\* (.*?) \*/%;
	#    for $el (split / /, $els) {
	#	++$els{$name}{$el};
	#	#warn "$name: $el";
	#    }
	#}
    #}

    # Extract from comments the lists of namespace
    # qualified elements that the hash key corresponds
    while ($x =~ m%/\*TAG\((\w+)\): (.*?) \*/%gs) {
	$name = $1;
	$els = $2;
	#warn "name($name) els($els)";
	for $el (split / /, $els) {
	    ++$els{$name}{$el};
	    #warn "$name: $el";
	}
    }
    
    my ($y) = $x =~ /struct zx_el_tok zx_el_tab\[\] =\s+\{\s+(.*?)\s+\};/s;
    #warn "$i: $ARGV[$i] tab($y)";  # Output can be rather sizeable
    $y =~ s/\#line \d+ ".*?"\n//gs;
    $y =~ s/^\s*\{//s;
    $y =~ s/\}$//s;
    #warn "$i: ($ARGV[$i]) got($y)";
    my @a = split /\},\s+\{/s, $y;
    die "Danger of exhaustation of ELEM space" if $#a >= 0x0000ff00;
    for ($j = 0; $j <= $#a; ++$j) {
	($name) = $a[$j] =~ /^"(.*?)"/;
	next if !$name;  # Do not gen consts for padding to make hash right
	# Generate namespace qualified element constants that correspond to the key
	for $el (sort keys %{$els{$name}}) {
	    ($nsprefix) = split /_/, $el;
	    die "Duplicate elem name($el)" if $name_used{$el}++;
	    printf "#define $prefix${el}_ELEM\t0x%06x\n", $ns_const{$nsprefix}|$j;
	}
    }
    print "#define ${prefix}_ELEM_MAX\t$j\n";
}

print "/* generated file, do not edit! $prefix\n * \$Id\$ */\n";
print "#ifndef _${prefix}consts\n";
print "#define _${prefix}consts\n";

process_ns_tab(readall($ns_tab));
process_at_tab(readall($at_tab));
process_el_tab(readall($el_tab));

print "#endif\n";
#EOF
