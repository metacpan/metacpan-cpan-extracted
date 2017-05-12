#!/usr/local/bin/perl
#
# 	@(#)ct_cursor.pl	1.1	9/19/95
#
# Example of ct_cursor() usage.

use Sybase::CTlib;

$d = new Sybase::CTlib mpeppler;

$d->ct_cursor(CS_CURSOR_DECLARE, 'cursor_eg',
	      'select * from master.dbo.sysprocesses',
	      CS_READ_ONLY) == CS_SUCCEED || die;
$d->ct_cursor(CS_CURSOR_ROWS, undef, undef, 5) == CS_SUCCEED || die;
$d->ct_cursor(CS_CURSOR_OPEN, undef, undef, CS_UNUSED) == CS_SUCCEED || die;
$d->ct_send();
while($d->ct_results($restype) == CS_SUCCEED)
{
    print "$restype\n";
    
    next if($restype != CS_ROW_RESULT &&
	    $restype != CS_PARAM_RESULT &&
	    $restype != CS_STATUS_RESULT &&
	    $restype != CS_CURSOR_RESULT &&
	    $restype != CS_COMPUTE_RESULT);

    while(%dat = $d->ct_fetch(1))
    {
	foreach (keys(%dat))
	{
	    print "$_: $dat{$_}\n";
	}
	print "\n";
    }
}

$d->ct_cursor(CS_CURSOR_CLOSE, undef, undef, CS_DEALLOC) == CS_SUCCEED || die;
$d->ct_send;
while($d->ct_results($restype) == CS_SUCCEED)
{
    print "$restype\n";
    
    next if($restype != CS_ROW_RESULT &&
	    $restype != CS_PARAM_RESULT &&
	    $restype != CS_STATUS_RESULT &&
	    $restype != CS_CURSOR_RESULT &&
	    $restype != CS_COMPUTE_RESULT);

    while(@dat = $d->ct_fetch(1))
    {
	print "@dat\n";
    }
}
