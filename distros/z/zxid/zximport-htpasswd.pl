#!/usr/bin/perl
# Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id$
#
# 17.9.2010, created --Sampo
#
# Commandline for importing .htpasswd file to /var/zxid/idpuid

$usage = <<USAGE;
Commandline for importing .htpasswd file to /var/zxid/idpuid
Usage: ./zximport-htpasswd.pl <.htpasswd
USAGE
    ;
die $USAGE if $ARGV[0] =~ /^-[Hh?]/;

#$dir = '/tmp/idpuid';
$dir = '/var/zxid/idpuid';

use Data::Dumper;

sub writeall {
    my ($f,$d) = @_;
    open F, ">$f" or die "Cant write($f): $!";
    binmode F;
    flock F, 2;    # Exclusive
    print F $d;
    flock F, 8;    
    close F;
}

while ($line = <STDIN>) {
    ($uid, $crypt) = split /:/, $line, 2;
    chomp $crypt;
    mkdir "$dir/$uid" or die "Cant mkdir $dir/$uid: $!";
    mkdir "$dir/$uid/.bs" or die "Cant mkdir $dir/$uid/.bs: $!";
    mkdir "$dir/$uid/.ykspent" or die "Cant mkdir $dir/$uid/.ykspent: $!";
    writeall("$dir/$uid/.pw", '$c$'.$crypt);
    writeall("$dir/$uid/.bs/.at", "cn: $uid (TAS3)\ntas3entitlement: member\n");
}

__END__
