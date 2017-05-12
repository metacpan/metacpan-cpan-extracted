# -*-Perl-*-
use XDR::Encode qw(:all);
use XDR::Decode;

print "1..18\n";

sub result
{
    my ($success, $num, $skip) = @_;
    my $out;
    $out = 'not ' if (! $success);
    $out .= 'ok';
    $out .= " $num" if (defined ($num));
    $out .= " \# skip" if ($skip);
    print $out, "\n";
    # print STDERR "result <$out>\n";
    return $success;
}

# Check that padding happens at all.
my $in_o1 = 'a';
my $o1 = opaque ('a');
my $expected_o1 = "\0\0\0\001a\0\0\0";
if (result ($o1 eq $expected_o1, 1))
{
    my $dec = XDR::Decode->new ($o1);
    my $out_o1 = $dec->opaque ();
    result ($out_o1 eq $in_o1, 2);
}
else
{
    result (0, 2, 1);
}


# Check that padding isn't used where not necessary.
my $in_o2 = 'dcba';
my $o2 = opaque ($in_o2);
my $expected_o2 = "\0\0\0\004dcba";
if (result ($o2 eq $expected_o2, 3))
{
    my $dec = XDR::Decode->new ($o2);
    my $out_o2 = $dec->opaque ();
    result ($out_o2 eq $in_o2, 4);
}
else
{
    result (0, 4, 1);
}


# Try embedding some binary data.
my $in_o3 = "one lit\376le doggie\0moving along";
my $o3 = opaque ($in_o3);
my $expected_o3 = "\0\0\0\036one lit\376le doggie\0moving along\0\0";
if (result ($o3 eq $expected_o3, 5))
{
    my $dec = XDR::Decode->new ($o3);
    my $out_o3 = $dec->opaque ();
    result ($out_o3 eq $in_o3, 6);
}
else
{
    result (0, 6, 1);
}


# Do a simple call packet.
my $in_cp_xid = 0x123;
my $in_cp_proc = 42;
my $in_cp_args = opaque ('abc');
my $in_cp_vers = 4;
my $in_cp_prog = 3;
my $in_cp_rpcvers = 2;
my $cp = call_packet ($in_cp_xid, $in_cp_proc, $in_cp_args,
		      $in_cp_vers, $in_cp_prog, $in_cp_rpcvers);
my $expected_cp = "\0\0\001#\0\0\0\0\0\0\0\002\0\0\0\003\0\0\0\004\0\0\0*\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\003abc\0";
if (result ($cp eq $expected_cp, 7))
{
    my $dec = XDR::Decode->new ($cp);
    my $out_cp = $dec->rpc ();
    result ($out_cp->xid () == $in_cp_xid, 8);
    result ($out_cp->rpcvers () == $in_cp_rpcvers, 9);
    result ($out_cp->prog () == $in_cp_prog, 10);
    result ($out_cp->vers () == $in_cp_vers, 11);
    result ($out_cp->proc () == $in_cp_proc, 12);
    result ($out_cp->args () eq $in_cp_args, 13);
}
else
{
    for (qw(xid rpcvers prog vers proc args))
    {
	result (0, undef, 1);
    }
}


# And a reply packet.
use XDR qw(MSG_ACCEPTED SUCCESS);
my $in_rp_xid = 0x123;
my $in_rp_status = MSG_ACCEPTED;
my $in_rp_reason = SUCCESS;
my $in_rp_result = opaque ('cba');
my $rp = reply_packet ($in_rp_xid, $in_rp_status,
		       $in_rp_reason, $in_rp_result);
my $expected_rp = "\0\0\001#\0\0\0\001\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\003cba\0";
if (result ($rp eq $expected_rp, 14))
{
    my $dec = XDR::Decode->new ($rp);
    my $out_rp = $dec->rpc ();
    result ($out_rp->xid () == $in_rp_xid, 15);
    result ($out_rp->status () == $in_rp_status, 16);
    result ($out_rp->reason () == $in_rp_reason, 17);
    result ($out_rp->result () eq $in_rp_result, 18);
}
else
{
    for (qw(xid status reason result))
    {
	result (0, undef, 1);
    }
}

exit (0);
