#!/usr/bin/perl
# $Id: gen-conf-ref.pl,v 1.1 2009-08-25 16:22:44 sampo Exp $
# 21.8.2009, Sampo Kellomaki <sampo@iki.fi>
#
# Generate configuration reference from zxidconf.h specially
# maerked comments

$usage = <<USAGE;
Usage: ./gen-conf-ref.pl [opts] <zxidconf.h >confref.pd
USAGE
    ;

$project = 'ZXID';

$write = 1;
if ($ARGV[0] eq '-n') {
    shift;
    $write = 0;
}

use Data::Dumper;
die $USAGE if $ARGV[0] =~ /^-/;
select STDERR; $|=1; select STDOUT;
undef $/;
$x = <STDIN>;

#                      1 1      2      2   3   3
@a = split /(?:\n\/\*\((c)\)[ ]*([^\n]+)\s*(.+?)\*\/)/gsx, $x;

shift @a;  # Starting comment

while (@a) {
    ++$n;
    $docflag = shift @a;
    $title   = shift @a;
    $comment = shift @a;
    $body    = shift @a;

    $comment =~ s/^\* //s;
    $comment =~ s/\*\/$//gs;
    $comment =~ s/\n ?\* ?/\n/gs;

    print <<PD;

4.1.$n $title
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$comment

PD
    ;

    #                              1   1 2   2  3   34        5   5      4
    @opts = $body =~ m/^\#define ZX(ID_)?(\w+) +(.+?)( *\/\* *(.*?) *\*\/)?$/gm;
    #warn "opts($body): " . Dumper \@opts if $n == 2 || $n == 4;
    while (@opts) {
	shift @opts;
	$opt_name = shift @opts;
	$opt_val  = shift @opts;
	shift @opts;
	$opt_comment = shift @opts;

	print "${opt_name}:: $opt_comment (default: $opt_val)\n\n";
    }

    #warn "\n\n=======\n$comment";
}

exit;

#EOF gen-conf-ref.pl
