#!/usr/bin/perl -w
# Simple test program for Text::TemplateFill module.
# In fact it is ripped out of one of the first applications that I wrote this
# for, so it is more of a demo and probably doesn't test all the nooks & crannies.
# It ought to be extended to check everything. 
#
#	SCCS: @(#)test.pl 1.1 03/27/03 09:08:12
# Alain D D Williams <addw@phcomp.co.uk>, March 2003

use strict;

use Text::TemplateFill;
use Time::Local;

my $TemplateDir = 'Test';

my $Branch;	# The Branch/store that we work with.
my $Country;	# The country that we work with
my $NoteFile;	# Where we write the PO note to.
my $Errors = 0;	# How many errors

# The following are used in a write, so make them global:
my ($dept, $Sku, $descrip, $Quant, $price, $oldprice, $Value, $TotalItems);
my ($Date, $To, $From, $PONo, $ShipDate);
my ($VendorNumber, $VendorName, $VendorPhone);

my @Input;	# Input is here so that we can use it more than once

# Print an error message - printf style.
# Note that a \n needs to be appended to the message.
sub Errors {
	my $fmt = shift @_;

	printf STDERR $fmt . "\n", @_;

	$Errors++;
}

# Error & quit
sub ErrorQ {
	&Errors(@_);

	exit 2;
}

# Generate a set of notes in one language.
# The arg is the base of the file names that we are to generate.
sub GenerateNote {
	my $File = $_[0];
	my $NoteNo = 0;
	my $vatcode;
	my $LastPo = '';

	# Create a new template handle:
	my $tmpl = new Text::TemplateFill;

	# Set options:
	# * where the templates are to be found
	# * how to report errors
	# * MSDOS line terminator
	$tmpl->SetOpt('BaseDir' => "$TemplateDir/$Country", 'ErrorFunction' => \&Errors,
		'LineTerminator' => "\r\n");

	# Read the paragraphs:
	$tmpl->ReadPara('Header');
	$tmpl->ReadPara('FirstHeader');
	$tmpl->ReadPara('ItemPO');
	$tmpl->ReadPara('Footer');
	$tmpl->ReadPara('FootNote');

	# Bind variables in this program to the names used in the paragraphs:
	$tmpl->BindVars('purchase_order_no' => \$PONo, 'orderdate' => \$Date, 'shipdate' => \$ShipDate,
		'branch' => \$Branch, 'department' => \$dept,
		'vendor_number' => \$VendorNumber, 'vendor_name' => \$VendorName, 'vendor_phone' => \$VendorPhone,
		'description' => \$descrip, 'SKU' => \$Sku, 'quantity' => \$Quant,
		'price' => \$price, 'old_price' => \$oldprice, 'total_items' => \$TotalItems,
		'value' => \$Value, 'country' => \$Country);

	# Generate each transfer
	foreach (@Input) {

		# Read a line:
		my ($_Date, $_ShipDate);
		($PONo, $_Date, $_ShipDate, $dept, $VendorNumber, $VendorName, $VendorPhone, $descrip,
			$Sku, $Quant, $price, $oldprice) = split /\t/;

		# New PO, start a new file:
		if($PONo ne $LastPo) {
			if($LastPo ne '') {	# Footer paragraph
				# Extra instructions & things
				print NOTE $tmpl->CompletePage('FootNote');

				close(NOTE);
			}

			open(NOTE, ">$File$NoteNo") || &ErrorQ("Cannot open/write to '%s' as: $!", $File . $NoteNo);
			$tmpl->Reset;

			$NoteNo++;

			$_Date =~ /^(....)(..)(..)/;
			$Date = timelocal(0, 0, 12, $3, $2 - 1, $1);

			$_ShipDate =~ /^(....)(..)(..)/;
			$ShipDate = timelocal(0, 0, 12, $3, $2 - 1, $1);

			$TotalItems = 0;

			$LastPo = $PONo;

			# The first line in the header is recognised by the s/ware on the till in generating an index
			print NOTE $tmpl->GeneratePara('FirstHeader');
		}

		# I suppose that these could be done by arith statements in the files, but so what ...
		$TotalItems += $Quant;
		$Value = $price * $Quant;

		# Print the paragraph with the items that we have just read in
		print NOTE $tmpl->GeneratePara('ItemPO');
	}

	if($LastPo ne '') {
		# Extra instructions & things
		print NOTE $tmpl->CompletePage('FootNote');
		close(NOTE);
	}

	printf STDERR "#errors %d\n", $tmpl->{Errors} if($tmpl->{Errors} != 0);
}

# ****************

# Make the output directory:
( -d 'Out' ) || mkdir 'Out' || exit;

while(<DATA>) {
	chop;
	s/\s*$//;
#	print "'$_'\n";
	next if($_ eq '' or $_ =~ /^#/);	# Ignore blank/comments

	push @Input, $_;
}

$Country = 'uk';
$Branch = 123;
&GenerateNote('Out/uk-print-');

# Do that all again for a different locale - a bit unusual, but this is a test program:
$Country = 'fr';
$Branch = 456;
&GenerateNote('Out/fr-print-');

exit;

__END__

# Test data here. Simple, but does for the purposes of this demo/test.
# Note that will start a new sheet if the PO# changes,
# within a PO it makes sense to keep: dates & Vendor info the same.
# PO	Date		Shipdate	Dept	Vend#	VendName	VendPhone	Descript	SKU	Qty	Price	oldprice
1234	20030326	20030328	32	99	ACME Toys Ltd	01234566789	Teddy Bear	432167	10	12.99	11.50
1234	20030326	20030328	456	99	ACME Toys Ltd	01234566789	Toy Train	432101	25	22.99	22.99

1245	20030326	20030328	456	99	Big Company Ltd	0123456000	Pea Shooter	433234	100	1.50	1.50


# end
