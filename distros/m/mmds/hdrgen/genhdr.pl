#!/usr/bin/perl -w

my $RCS_Id = '$Id: genhdr.pl,v 1.24 2003-01-09 22:56:11+01 jv Exp $ ';
# Author          : Johan Vromans
# Created On      : Sun Oct 20 16:12:50 1991
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan  9 22:30:25 2003
# Update Count    : 232
# Status          : Unknown, Use with caution!

# This program gets the header info (at the end of this program) and
# writes a perl include file to stdout to fill the header associated
# tables.

################ Common stuff ################

use strict;

our $my_package = "Squirrel/MMDS";
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;

################ Options ################

my $language = "uk";
my $verbose;
my $debug;
my $trace;

options() if @ARGV > 0 && $ARGV[0] =~ /^-/;

################ Main ################

my $langinfo = "./gh_nls";
$langinfo .= "-" . $language if $language;
$langinfo .= ".pl";
die ("Error: \"$langinfo\" not found\n") unless -r "$langinfo";

my %dtp_tag;
my %hdr_tag;
my @dtp_allow;
my @dtp_key;
my @dtp_mand;
my @dtp_name;
my @hdr_dtp;
my @hdr_key;
my @nls_name;

our $nls_day_after_month;
our %hdr_aliases;
our @hdr_name;
our @month_names;
our @nls_table;

my @data = get_data();

# Document types
my @types = qw(generic memo mrep report note offering letter slides imp);

# NLS text items
my @nls_items =
    ("TXT_NULL",
     "TXT_LANG",
     "TXT_LANGUAGE",
     "TXT_MEMO",
     "TXT_TOC",
     "TXT_COS",
     "TXT_SECTION",
     "TXT_MAP",
     "TXT_PAGE",
     "TXT_REF",
     "TXT_PHEXT",
     "TXT_CLOSING",
     "TXT_CONFMGT",
     "TXT_CONFSTAT",
     "TXT_DRAFT",
     "TXT_INDEX",
     "FMT_MEETING",
     "PAT_CONFIGMGT",
     "PAT_ANNOUNCE",
     );

my $count = 0;

my @tm = localtime (time);
$tm[5] += 1900;
print STDOUT ("# This file has been generated by $my_package [$my_name $my_version]");
printf STDOUT (", %02d/%02d/%d %02d:%02d\n# DO NOT EDIT MANUALLY!\n\n",
	       $tm[3], 1+$tm[4], $tm[5], $tm[2], $tm[1]);

print STDOUT <<'EOD';
# This file will initialize
#  - $DTP_... defines
#  - $HDR_... defines
#  - @dtp_name  ($DTP_... -> name)
#  - %dtp_name  (name -> $DTP_...)
#  - %hdr_tag   (header name -> $HDR... value)
#  - @hdr_name  ($HDR_... -> header name)
#  - @dtp_allow (bit vector for allowed headers)
#  - @hdr_dtp   (doc type for this header, if significant)
#  - @dtp_mand  (:-separated list of mandatory headers)
#  - $hdr_set   (bit vector for headers that were explicitly set)
#  - NLS tables

EOD

print STDOUT ("# Enumerating document types.\n");

foreach my $type ( @types ) {
    $dtp_name[$count] = $type;
    $dtp_tag{$type} = $count;
    $type =~ tr/a-z/A-Z/;
    $dtp_key[$count] = 'DTP_' . $type;
    $type =~ tr/a-z/A-Z/;
    my $cmd = sprintf ("\$::DTP_%-10s = %2d;", $type, $count);
    &eval ($cmd);
    print STDOUT $cmd, "\n";
    $count++;
}
print STDOUT ("\n");

print STDOUT ("# Enumerating NLS items.\n");
$count = 0;
foreach my $item ( @nls_items ) {
    $nls_name[$count] = $item;
    my $cmd = sprintf ("\$::%-14s = %2d;", $item, $count);
    &eval ($cmd);
    print STDOUT $cmd, "\n";
    $count++;
}
print STDOUT ("\n");

print STDOUT ("# Enumerating headers.\n");
$count = 0;
foreach my $entry ( @data ) {
    next if $entry =~ /^#/;
    my @a = split(/\s+/, $entry);
    push (@a, "", "") if @a == 1;
    if ( @a != 3 ) {
	print STDERR "Error in info: ", scalar(@a), " fields\n$entry";
	next;
    }
    my ($key,$allow,$mand) = @a;
    $key =~ tr/a-z/A-Z/;
    $allow = join (",", @types) if $allow eq "all";
    $mand = $allow if $mand eq "*";
    $mand = "" if $mand eq "-";
    $allow =~ tr/a-z/A-Z/;
    my @allow = split (/,/, $allow);
    my @mand = split (/,/, $mand);

    # Define it.
    my $this = $count++;
    $hdr_key[$this] = 'HDR_' . $key;
    my $cmd = sprintf ("\$::HDR_%-10s = %2d;", $key, $this);
    &eval ($cmd);
    print STDOUT $cmd, "\n";

    # Allow this header for this doc type. 
    foreach $allow ( @allow ) {
	my $cmd = '$dtp_allow[$::DTP_' . $allow . '] .= "|" . ' . $this . ";";
	&eval ($cmd);
    }

    # If only this type uses this header, it is significant.
    if ( @allow == 1 ) {
	my $cmd = '$hdr_dtp[' . $this . '] = $::DTP_' . $allow. ";";
	&eval ($cmd);
    }

    foreach $mand ( @mand ) {
	$mand = $dtp_tag{$mand};
	if ( defined $dtp_mand[$mand] ) {
	    $dtp_mand[$mand] .= " " . $this;
	}
	else {
	    $dtp_mand[$mand] = $this;
	}
    }
}

require $langinfo;

# Register under all names.
for my $this ( 0..$#hdr_name ) {
    $hdr_tag{$hdr_name[$this]} = $this;
}
while ( my ($name,$this) = each %hdr_aliases ) {
    $hdr_tag{$name} = $this;
}


# Spit out the collected info.

print STDOUT ("\n# Document types.\n");
print STDOUT ("\@::dtp_name = (\n");
$count = 0;
foreach my $type ( @dtp_name ) {
    my $name = $type;
    printf STDOUT (" %-22s\t# %2d  %s\n",
		   '"' . $type. '",', $count, $dtp_key[$count]);
    $count++;
}
print STDOUT (");\n");
print STDOUT ("\%::dtp_name = (\n");
$count = 0;
foreach my $type ( @dtp_name ) {
    my $name = $type;
    printf STDOUT (" %-22s => %2d,\n",
		   $type, $count);
    $count++;
}
print STDOUT (");\n");

print STDOUT ("\n# Official names.\n");
print STDOUT ("\@::hdr_name = (\n");
$count = 0;
foreach my $i ( @hdr_name ) {
    printf STDOUT (" %-22s\t# %2d  %s\n",
		   '"' . $i . '",', $count, $hdr_key[$count]);
    $count++;
}
print STDOUT (");\n");

print STDOUT ("\n# Names and aliases.\n");
print STDOUT ("\%::hdr_tag = (\n");
foreach my $hdr (sort (keys (%hdr_tag))) {
    printf STDOUT (" %-17s %2d,\t# %s\n",
		   '"' . $hdr . '",', $hdr_tag{$hdr},
		   $hdr_key[$hdr_tag{$hdr}]);
}
print STDOUT (");\n");

print STDOUT ("\n# Allowed header info.\n");
print STDOUT ("unless ( \@::dtp_allow ) {\n",
	      "    \@::dtp_allow = (\"\") x ", 0+@dtp_allow, ";\n");
foreach my $i ( 0..$#dtp_allow ) {
    foreach my $a ( split (/\|/, $dtp_allow[$i]) ) {
	next unless $a;
	my $j = $dtp_key[$i];
	printf STDOUT ("    vec (\$::dtp_allow[%2d], %2d, 1) = 1;\t# %-12s + %s\n",
		       $i, $a, $j, $hdr_key[$a]);
    }
}
print STDOUT ("}\n");

print STDOUT ("\n# Significant header info (sparse array).\n");
print STDOUT ("unless ( \@::hdr_dtp ) {\n");
foreach my $i ( 0..$#hdr_dtp ) {
    next unless $hdr_dtp[$i];
    printf STDOUT ("    \$::hdr_dtp[%2d] = %2d;\t\t# %-12s -> %s\n",
		   $i, $hdr_dtp[$i], $hdr_key[$i], $dtp_key[$hdr_dtp[$i]]);
}
print STDOUT ("}\n");

print STDOUT "\n# Mandatory header info.\n";
print STDOUT ("unless ( \@::dtp_mand ) {\n");
print STDOUT ("    \@::dtp_mand = (\n");
for my $i ( 0..$#dtp_mand ) {
    if ( my $mand = $dtp_mand[$i] ) {
	my @mand = split (' ', $mand);
	my $list = join(":", @mand);
	printf STDOUT ("     %-23s\t# %-12s -> %s\n",
		       '"' . $list . '",', $dtp_key[$i], 
		       join (" ", grep($_=$hdr_key[$_],@mand)));
    }
    else {
	printf STDOUT ("     %-23s\t# %-12s -> %s\n", '"",', $dtp_key[$i]);
    }
}
print STDOUT ("\t);\n");
print STDOUT ("}\n");

print STDOUT ("\n# Bits for headers that are explicitly set\n",
       '$::hdr_set = "" unless defined $::hdr_set;', "\n");

print STDOUT ("\n# NLS translations\n",
	      "\@::nls_table = (\n");
$nls_table[0] ||= "";
for my $i ( 0..$#nls_table ) {
    printf STDOUT (" %-22s\t# %2d  %s\n",
		   "'" . $nls_table[$i] . "',", $i, $nls_items[$i]);
}
print STDOUT (");\n");

print STDOUT ("\n# Month names (zero relative)\n",
	      "\@::month_names = (\n");
for ( my $i = 0; $i <= $#month_names; $i += 4 ) {
    printf STDOUT (" %-13s%-13s%-13s%-13s\n",
		   "'" . $month_names[$i] . "',",
		   "'" . $month_names[$i+1] . "',",
		   "'" . $month_names[$i+2] . "',",
		   "'" . $month_names[$i+3] . "',",
		   "\n");
}
print STDOUT (");\n");
print STDOUT ("\$::nls_day_after_month = ",
	      (defined $nls_day_after_month) ? $nls_day_after_month : 0,
	      ";\n");

#print STDOUT ("\n}\nelse {\n\n    # Called from package. Use reference to main object.\n");
#foreach my $tbl ( "headers", "hdr_tag", "hdr_name", "hdr_dtp", "dtp_allow",
#		  "dtp_mand", "dtp_name", "hdr_set", "nls_table", "month_names",
#		  "nls", "nls_day_after_month"
#		) {
#    printf STDOUT ("    *%-12s = *main'%s;\n", $tbl, $tbl);
#}
#print STDOUT "}\n";

print STDOUT "\n1;\n";

################ Subroutines ################

sub options {
    use Getopt::Long;

    my $help;
    my $ident;

    $language = "";
    if ( ! GetOptions ("language=s" => \$language,
		       "ident" => \$ident,
		       "verbose" => \$verbose,
		       "debug" => \$debug,
		       "trace" => \$trace,
		       "help" => \$help)
	 || $help ) {
	print STDERR <<EndOfUsage;
This is $my_package [%M% %I%]
Usage: $0 [options]
  options are:
    -language XX	language code (NL, EN, ...)
    -ident		print program name and version
    -verbose		verbose info
    -help		this message
EndOfUsage
	exit(1);

	print STDERR ("This is $::my_package [%M% %I%]\n")
	  if $ident;
    }
}

sub eval {
    my ($cmd) = @_;
    print STDERR $cmd, "\n" if $debug;
    CORE::eval ($cmd);
    warn ($@) if ($@);
}

sub get_data {

    # Format of this table:
    #
    #  KEY:   The code for this header.
    #  ALLOW: The document types that allow this header. If there
    #	      is only one document type that allows this header, it
    #	      becoms significant for this doc type.
    #	      Document type 'all' can be used to indicate all types.
    #  MAND:  The document types this header is mandatory for.
    #	      Doc type '*' can be used to copy the types from
    #	      the ALLOW column.
    #	      Type '-' means: no document types.

    my $data = <<EOD;
#KEY		ALLOW				MAND
null
absent		mrep				-
author		report,note			*
cc		memo,mrep,letter		-
city		letter				-
closing		letter				-
cmpy		all				-
company		all				-
date		all				-
dept		all				-
docid		report,note,slides		-
documentstyle	all				-
encl		letter,offering			-
from		all				memo,letter
index		imp,report			-
meeting		mrep				*
mhid		all				note,report,slides
next		all				-
note		note				*
number		mrep				*
offering	offering			*
opening		letter				*
ok		offering,report			-
options		all				-
phone		memo				-
present		mrep				*
project		report				*
ref		letter				*
secr		mrep				-
section		imp				*
slides		slides				*
subject		memo,letter			memo
title		note,report,imp,offering	*
to		memo,letter			*
version		note,report,slides		*
EOD
    split (/\n/, $data);
}
