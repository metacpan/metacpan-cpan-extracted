#!/usr/bin/perl -w

use strict;

use Win32API::File qw(
    QueryDosDevice
    fileLastError
);

exit main();


sub main {
    my $size= 1024;
    my $all;
    while(  ! QueryDosDevice( [], $all, $size )  ) {
	$size *= 2;
    }
    my @all= split /\0/, $all;
    my %all;
    for(  @all  ) {
	if(  ! QueryDosDevice( $_, $all, 0 )  ) {
	    print "Can't get device definition ($_): ", fileLastError(), "\n";
	} else {
	    $all =~ s/\0\0.*//;	# Audio devices return some strange items?
	    my @list= split /\0/, $all;
	    $all{$_}= \@list;
	}
    }
    for(  sort { $all{$a}->[0] cmp $all{$b}->[0] } keys %all  ) {
	print "$_ = ", join( ", ", @{$all{$_}} ), "\n";
    }
    return 0;
}
