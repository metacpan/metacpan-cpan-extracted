#!/usr/bin/perl 

use Zcash::RPC::Client;
use Data::Dumper;

# Address listens for JSON-RPC connections
$RPCHOST = "127.0.0.1";

# User for JSON-RPC api commands
# rpcuser from file ~/.zcash/zcash.conf
$RPCUSER = "Your_zcashd_RPC_User_Name";

# Password for JSON-RPC api commands
# rpcpassword from file ~/.zcash/zcash.conf
$RPCPASSWORD = 'Your_zcashd_RPC_Password';

# Create RPC object
$zec = Zcash::RPC::Client->new(
	host     => $RPCHOST,
	user     => $RPCUSER,
	password => $RPCPASSWORD,
	#debug   => 1,
);

# Zcash supports all commands in the Bitcoin Core API (as of version 0.11.2)

# Check the block height of our Zcash node
#     https://bitcoin.org/en/developer-reference#getinfo
print ">> getinfo\n";
$getinfo = $zec->getinfo;
print Dumper($getinfo);
print "blocks: $getinfo->{blocks}\n";

# Information about the current state of the block chain.
#     https://bitcoin.org/en/developer-reference#getblockchaininfo
print ">> getblockchaininfo\n";
$getblockchaininfo = $zec->getblockchaininfo;
print Dumper($getblockchaininfo);
# JSON arrays
@forks = @{ $getblockchaininfo->{softforks} };
foreach $f (@forks) {
	print $f->{id};
	print "\n";
}

# Return the total value of funds stored in the node’s wallet
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#accounting
print ">> z_gettotalbalance\n";
$z_gettotalbalance = $zec->z_gettotalbalance;
print Dumper($z_gettotalbalance);
print "total: $z_gettotalbalance->{total}\n";

# Return a new zaddr for sending and receiving payments.
# The spending key for this zaddr will be added to the node’s wallet.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#addresses
print ">> z_getnewaddress\n";
$z_getnewaddress = $zec->z_getnewaddress;
print Dumper($z_getnewaddress);
print "new zaddr: $z_getnewaddress\n";

# Returns a list of all the zaddrs in this node’s wallet for which you have a spending key.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#addresses
print ">> z_listaddresses\n";
$z_listaddresses = $zec->z_listaddresses;
print Dumper($z_listaddresses);
# JSON array
@zaddresses = @{ $z_listaddresses };
foreach $zaddress (@zaddresses) {
	print "$zaddress\n";
}

# First/oldest zaddr
$oldest_zaddr = $zaddresses[$#zaddresses];

# Return information about a given zaddr.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#addresses
print ">> z_validateaddress $oldest_zaddr\n";
$z_validateaddress = $zec->z_validateaddress( $oldest_zaddr );
print Dumper($z_validateaddress);

# Return a list of amounts received by a zaddr belonging to the node’s wallet.
# Optionally set the minimum number of confirmations which a received amount must have in 
# order to be included in the result. 
# Use 0 to count unconfirmed transactions.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#payment
print ">> z_listreceivedbyaddress $oldest_zaddr\n";
$z_listreceivedbyaddress = $zec->z_listreceivedbyaddress( $oldest_zaddr );
print Dumper($z_listreceivedbyaddress);
# https://explorer.testnet.z.cash/tx/c1eed9cd7f756174822a8e9929863b0334ffd386d3e0620225c4e37623d02ee9

# Returns the balance of a taddr or zaddr belonging to the node’s wallet.
# Optionally set the minimum number of confirmations a private or transparent transaction 
# must have in order to be included in the balance. 
# Use 0 to count unconfirmed transactions.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#accounting
print ">> z_getbalance $oldest_zaddr\n";
$z_getbalance = $zec->z_getbalance( $oldest_zaddr, 6 );
print Dumper($z_getbalance);
print "balance: $z_getbalance\n";

# Send funds from an address to multiple outputs. 
# The address can be either a taddr or a zaddr.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#accounting
print ">> z_sendmany $oldest_zaddr\n";
# key/value pairs corresponding to the addresses and amount to pay
@amounts = (
	{
		# Zcash Testnet Faucet
		address => 'ztbx5DLDxa5ZLFTchHhoPNkKs57QzSyib6UqXpEdy76T1aUdFxJt1w9318Z8DJ73XzbnWHKEZP9Yjg712N5kMmP4QzS9iC9',
		amount  => 123.456789,
	},
);
$z_sendmany = $zec->z_sendmany( $oldest_zaddr, [@amounts] );
print Dumper($z_sendmany);
$operationid = $z_sendmany;
print "operationid: $operationid\n";

# Return OperationStatus JSON objects for all operations the node is currently aware of.
#     https://github.com/zcash/zcash/blob/master/doc/payment-api.md#operations
print ">> z_getoperationstatus [\"$operationid\"]\n";
@operationids = ( $operationid );
$z_getoperationstatus = $zec->z_getoperationstatus( [\@operationids] );
print Dumper($z_getoperationstatus);

exit(0);
