# -*-Perl-*-
print "1..8\n";

package TestX;

# Define some RPCs.
use XDR::CallReply;
my $proto = XDR::CallReply->new (0x1234, 5);

$proto->typedef ('opaque', 'buffer');
$proto->typedef ('struct', 'strint', 'buffer', 'unsigned');

# Do nothing.
$proto->define (0x0, 'void', 'NULL', 'void');

# Pass a block of data without confirmation.
$proto->define (0x1, 'void', 'DATA', 'buffer');

# Pass a few integers, and return their product.
$proto->define (0x2, 'unsigned', 'PRODUCE', 'unsigned a', 'unsigned b');

# Pass and return a structure.
$proto->define (0x3, 'strint', 'ADDCAT', 'strint a', 'strint b');

package main;
use XDR::Encode ':simple';

my $NULL = 1;
my $DATA = 2;
my $PRODUCE = 4;
my $ADDCAT = 8;
my $ran;
my $reply = TestX->reply;

sub null
{
    my ($rpc) = @_;
    $ran |= $NULL;
    return $rpc->reply (); # Empty success reply.
}

my $out_data;
sub data
{
    my ($rpc, $buffer) = @_;
    $ran |= $DATA;
    $out_data = $buffer;
    return ''; # No reply.
}

sub produce
{
    my ($rpc, $a, $b) = @_;
    $ran |= $PRODUCE;
    return $rpc->reply ($reply->PRODUCE ($a * $b));
}

sub addcat
{
    my ($rpc, $a, $b) = @_;
    $ran |= $ADDCAT;
    return $rpc->reply ($reply->ADDCAT ([$a->[1] . $b->[1],
					 ord ($a->[0]) + ord ($b->[0])]));
}


# Dispatch.
my $hookdb = TestX->hookdb;
$hookdb->hook ($hookdb->NULL, \&null);
$hookdb->hook ($hookdb->DATA, \&data);
$hookdb->hook ($hookdb->PRODUCE, \&produce);
$hookdb->hook ($hookdb->ADDCAT, \&addcat);

# Try the NULL call.
$ran = 0;
my $call = TestX->call;
my $pkt = $call->NULL ();

# travel... to server
use XDR::RPC;
$pkt = $hookdb->dispatch ($pkt);
print $ran == $NULL ? 'ok' : 'not ok', " 1\n";

# Another call.
$ran = 0; undef $out_data;
my $in_data = "this is a really long, we\0\21\4\2ird argument";
$pkt = $call->DATA ($in_data);

# travel... to server
$pkt = $hookdb->dispatch ($pkt);
print $ran == $DATA ? 'ok' : 'not ok', " 2\n";
print $out_data eq $in_data ? 'ok' : 'not ok', " 3\n";


# Finally, do the product with a full return.
$ran = 0;
my $a = 3;
my $b = 49;
my $product;

sub produce_return
{
    my ($rpc, $p) = @_;
    $product = $p;
}

$pkt = $call->PRODUCE ($a, $b);
my $hooks = TestX->hookdb ();
$hooks->hook ($hooks->PRODUCE, \&produce_return, $pkt);

# travel... to server
$pkt = $hookdb->dispatch ($pkt);
print $ran == $PRODUCE ? 'ok' : 'not ok', " 4\n";

# travel... back to client
$hooks->dispatch ($pkt);
print $product == $a * $b ? 'ok' : 'not ok', " 5\n";


# Try passing structures.
$ran = 0;
my ($add, $cat);
sub addcat_return
{
    my ($rpc, $ret) = @_;
    $cat = $ret->[0];
    $add = $ret->[1];
}

my $s0 = 'abc';
my $s1 = 'def';
my $i0 = 12;
my $i1 = 34;

$pkt = $call->ADDCAT ([$s0, $i0], [$s1, $i1]);
$hooks->hook ($hooks->ADDCAT, \&addcat_return, $pkt);

# To server...
$pkt = $hookdb->dispatch ($pkt);
print $ran == $ADDCAT ? 'ok' : 'not ok', " 6\n";

# travel... back to client
$hooks->dispatch ($pkt);
print $add == (ord $s0) + (ord $s1) ? 'ok' : 'not ok', " 7\n";
print $cat eq $i0 . $i1 ? 'ok' : 'not ok', " 8\n";

exit (0);
