#!/usr/bin/perl

use Test::More;

sub testit {
    my ($type) = @_;
    my $out = "t/x1_$type.out";
    my $ref = "t/x1.$type";

    @ARGV = ( "--$type", "-output", $out, "t/x1.eps" );
    require_ok "blib/script/eps2png";

    ok(-s $out, "created: $out");
    is(-s $out, -s $ref, "size check");
    if( differ($ref, $out) ) {
	ok( 0, "content check");
    }
    else {
	ok( 1, "content check");
	unlink($out);
    }
}

sub differ {
    # Perl version of the 'cmp' program.
    # Returns 1 if the files differ, 0 if the contents are equal.
    my ($old, $new) = @_;
    unless ( open (F1, $old) ) {
	print STDERR ("$old: $!\n");
	return 1;
    }
    unless ( open (F2, $new) ) {
	print STDERR ("$new: $!\n");
	return 1;
    }
    my ($buf1, $buf2);
    my ($len1, $len2);
    while ( 1 ) {
	$len1 = sysread (F1, $buf1, 10240);
	$len2 = sysread (F2, $buf2, 10240);
	return 0 if $len1 == $len2 && $len1 == 0;
	return 1 if $len1 != $len2 || ( $len1 && $buf1 ne $buf2 );
    }
}

sub findbin {
    my $bin = shift;
    my @path = split(":", $ENV{PATH});
    unshift(@path, ".") if $^O =~ /^win/i;
    foreach my $p ( @path ) {
	return 1 if -x "$p/$bin";
	next unless $^O =~ /^win/i;
	return 1 if -x "$p/$bin.exe";
	return 1 if -x "$p/$bin.bat";
    }
    return;
}

1;
