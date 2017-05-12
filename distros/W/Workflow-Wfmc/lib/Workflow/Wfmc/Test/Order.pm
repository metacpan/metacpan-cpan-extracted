package Workflow::Wfmc::Test::Order;

use 5.008003;
use strict;
use warnings;
use Data::Dumper;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Kai::Order::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03.03';
#


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
my $timestamp = localtime;
use XML::Parser;

sub checkData
{
	my ($order_info) = shift->{'orderInfo'};
	print "$timestamp: Entering sub checkData\n"; 
	print "$timestamp: In sub checkData: validating order data...\n"; 
	my $pa = XML::Parser->new();
	my $res;
	eval{ $res = $pa->parse($order_info);};
	print "$timestamp: Leaving sub checkData\n"; 
	unless($@){
		print "$timestamp: Leaving sub checkData: 'Valid Data'\n"; 
		return {'status' => 'Valid Data'};
	}else{
		print "$timestamp: Leaving sub checkData: 'Inalid Data'\n"; 
		return {'status' => 'Invalid Data'};
	}
}

sub composeMessage
{
	my ($order_number) = shift->{'orderNumber'};
	print "$timestamp: Entering sub composeMessage: order no. $order_number\n"; 
	print "$timestamp: In sub composeMessage: sending message via email to user...\n"; 
	print "$timestamp: Leaving sub composeMessage: order no. $order_number\n"; 
}

sub checkVendor
{
	my $in = shift;
	my ($account_number,$toltal_amount) = ($in->{'orderInfo.AccountNumber'},$in->{'orderInfo.ToltalAmount'});
	print "$timestamp: Entering sub checkVendor: account no. $account_number wishes to spend $toltal_amount EURO\n"; 
	if($toltal_amount > 0 && $toltal_amount < 1000){
		print "$timestamp: Leaving sub checkVendor: Accept\n"; 
		return {'status' => 'Accept'};
	}else{
		print "$timestamp: Leaving sub checkVendor: OverLimit\n"; 
		return {'status' => 'OverLimit'};
	}
}

sub enterOrder
{
	my $in = shift;
	my ($order_info, $order_number) = ($in->{'orderInfo'},$in->{'orderNumber'});
	print "$timestamp: Entering sub enterOrder: order no. $order_number\n"; 
	print "$timestamp: In sub enterOrder: order no. $order_number processed\n"; 
	print "$timestamp: Leaving sub enterOrder: order no. $order_number\n"; 
	return {};
}

sub transformData
{
	my $in = shift;
	my ($order_string, $order_info) = ($in->{'orderString'},$in->{'orderInfo'});
	print "$timestamp: Entering sub enterOrder: $order_info\n"; 
	print "$timestamp: Leaving sub enterOrder: $order_info\n"; 
	return {};
}


1;
__END__
