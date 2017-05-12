#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use oEdtk;
use oEdtk::libDev qw ( lastCourt );


sub usage() {
	my $PROG =basename($0, "");
	print STDOUT << "EOF";

Usage:
	$PROG recorder_descriptor.cob > record_ID.pm

Structure of descriptor file SHOULD start with record number 01 and SHOULD be :
               01 VECTOR-RECORD-ID-ROW_NAME-1.
               * comment for row 
                   nn NOM-COLONNE1 PIC X(50).
               * comment for row
                   nn NOM-COLONNE2 PIC S9(10).
                   nn NOM-COLONNEn PIC S9(12)V9(2).
               * comment for row
	       01 VECTOR-RECORD_ID-ROW_NAME-2.
                   ...
               01 VECTOR-RECORD_ID-ROW_NAME-n.
                   ...

NB : nn is a number
ATT: each line should stop with a point '.'
     each line is : comment starting with '*' 
                    or record descriptor starting with nn
     each record line structure is : nn name [data PIC].
          nn level
          name (with no space no underscore)
          for data in record, data PIC
     note, in the recard name the shortest part would be considered as record key

 $PROG release 24/03/2011 15:33:48
 this util builds records modules from copygroups descriptors

EOF
}


sub type2field {
	my ($type) = @_;

	$type =~ s/(.)\((\d+)\)/$1 x $2/ge;

	if ($type =~ /^X+$/) {
		# Alpha-numeric field.
		return ("Field", length($type));
	}
	if ($type !~ /^(S)?(9+)(V9+)?$/) {
		die "ERROR: Unexpected type declaration: \"$type\"\n";
	}
	my ($sign, $int, $frac) = ($1, $2, $3);

	if (defined($frac)) {
		# Floating-point number. oEdtk::SignedField->new('D1-NUMRLV', 9),
		# return ("FPField", length($int), length($frac) - 1);
		return ("SignedField", length($int), length($frac) - 1);
	}
	# Integral number.
	return ("Field", length($int));
}

sub unwind {
	my ($levels, $goal, $cur) = @_;

	while (my ($lvl, $ref, $refid, $occurs) = @{shift(@$levels)}) {
		if ($lvl < $goal) {
			die "ERROR: Unexpected level $goal line $.\n";
		}
		add($ref, $refid, $cur, $occurs);
		$cur = $ref;
		last if $lvl == $goal;
	}
	# XXX Error handling missing.
	return $cur;
}

my %identifiers;
sub get_unique_id {
	my ($id) = @_;

	# Ensure unicity of identifier names.
	my $i = $identifiers{$id};
	if (defined($i)) {
		$i++;
		$identifiers{$id} = $i;
		$id .= "-$i";
	} else {
		$identifiers{$id} = 1;
	}
	return $id;
}

sub dup {
	my ($data) = @_;

	if (ref($data) ne 'ARRAY') {
		die "ARG! ($.)\n";
	}
	my $new = [];
	foreach (@$data) {
		my ($id, $val) = %$_;
		$id = get_unique_id($id);
		if (ref($val) ne '') {
			$val = dup($val);
		}
		push(@$new, { $id => $val });
	}
	return $new;
}

sub add {
	my ($rec, $id, $val, $occurs) = @_;

	my $count = 1;
	$count = $occurs if defined($occurs);

	$id = get_unique_id($id);
	push(@$rec, { $id => $val });

	my $id2 = $id;
	my $val2 = $val;
	while ($count > 1) {
		$id2 = get_unique_id($id);
		$val2 = dup($val);
		push(@$rec, { $id2 => $val2 });
		$count--;
	}
}

sub perlify {
	my ($out, $indent, $ref) = @_;

	foreach my $item (@$ref) {
		my ($id, $type) = %$item;
		if (ref($type) eq '') {
			my ($obj, @args) = type2field($type);
			print $out " " x $indent .
			  "oEdtk::$obj->new('$id', " . join(', ', @args) . "),\n";
		} else {
			print $out " " x $indent . "# $id\n";
			perlify($out, $indent + 4, $type);
		}
	}
}

if (@ARGV < 1) {
	usage(); #"usage: $0 <det-file> [out-file]\n";
	exit 1;
}

# The regular expression that matches an identifier.
# my $idre = qr/[a-zA-Z\d-]{1,31}/;
my $idre = qr/[a-zA-Z\d-]{1,}/;
my $picre = qr/PIC(?:TURE)?(?:\s+IS)?/;
my $typre = qr/S?(?:[9XAV](?:\(\d+\))?)+/;

open(my $in, "<", $ARGV[0]) or die "Cannot open \"$ARGV[0]\": $!\n";
my $out = \*STDOUT;
if (@ARGV > 1) {
	open($out, ">", $ARGV[1]) or die "Cannot open \"$ARGV[1]\": $!\n";
}

my @levels;
my @record = ();
my $cur = \@record;
my $curlvl = 0;
my $recid;

while (<$in>) {
	chomp;
	#s/^.{6}//;		# Remove the first six characters.
	s/^(\*\D*)(\d{2}\.*)$/$2/;		# Strip first col comments.
	s/\*.*$//;		# Strip comments.
	s/\_/\-/g;		# replace '_' with '-'.
	s/\s+$//g;		# remove end line white spaces
	next if m/^\s*$/;	# Ignore empty lines.

	if ($_ !~ /^\s*(\d{2})\s+($idre)(?:\s+OCCURS\s+(\d+)(?:\s+TIMES)?)?/) {
		die "ERROR: Unexpected line format (1) (line $. :'$_')\n";
	}
	my ($level, $id, $occurs, $rest) = ($1, $2, $3, $');

	if (!defined($recid) && $id =~ /^([^-]+)/) {
		$recid = lastCourt($id);
		# $recid = $1;
	}

	if ($level < $curlvl) {
		$cur = unwind(\@levels, $level, $cur);
	}
	$curlvl = $level;

	if ($rest =~ /^\s*\.\s*$/) {
		unshift(@levels, [$curlvl, $cur, $id, $occurs]);
		$cur = [];
	} elsif ($rest =~ /^\s+$picre\s+($typre)\s*\.\s*$/) {
		add($cur, $id, $1, $occurs);
	} else {
		die "ERROR: Unexpected line format (2) (line $. - rest '$rest' - recid $recid -  curlvl $curlvl - id $id)\n";
	}
}

unwind(\@levels, 01, $cur);
close($in);

print $out <<EOF;
package oEUser::Descriptor::$recid;

use strict;
use warnings;

use oEdtk::Record;
use oEdtk::AddrField;
use oEdtk::SignedField;
use oEdtk::Field;

sub get {
    return oEdtk::Record->new(
EOF
perlify($out, 8, \@record);
print $out <<EOF;
    );
}

1;
EOF
close($out);
