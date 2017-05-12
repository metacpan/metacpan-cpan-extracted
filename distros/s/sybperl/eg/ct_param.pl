#!/usr/local/bin/perl
#
# 	@(#)ct_param.pl	1.4	10/5/95
#
# Example of ct_param() usage.
# The RPC we want to run is in the proc.isql file in this directory.

use Sybase::CTlib;

$d = new Sybase::CTlib mpeppler;

$d->ct_command(CS_RPC_CMD, "t_proc", CS_NULLTERM, CS_NO_RECOMPILE);

%param = (name => '@acc',
	  datatype => CS_CHAR_TYPE,
	  status => CS_INPUTVALUE,
	  value => 'CIS 98941' ,
	  indicator => CS_UNUSED);

$d->ct_param(\%param) == CS_SUCCEED || die;

# Alternate technique: pass an anonymous hash...
$d->ct_param({name => '@date',
	      datatype => CS_DATETIME_TYPE,
	      status => CS_RETURN,
	      value => '950529' ,
	     indicator => CS_UNUSED});
$d->ct_param({name => '@open_val',
	     datatype => CS_FLOAT_TYPE,
	     status => CS_RETURN,
	     indicator => -1});
$d->ct_param({name => '@open_val_t',
	      datatype => CS_FLOAT_TYPE,
	      status => CS_RETURN,
	     indicator => -1});

$d->ct_send();
while($d->ct_results($restype) == CS_SUCCEED)
{
    print "$restype\n";
    next if($restype != CS_ROW_RESULT &&
	    $restype != CS_PARAM_RESULT &&
	    $restype != CS_STATUS_RESULT);

    while(%dat = $d->ct_fetch(1))
    {
	foreach (keys(%dat)) {
	    print "$_: $dat{$_}\n";

	    # Check to see if the date parameter that we've retrieved is really
	    # a Sybase::CTlib::DateTime reference.
	    if($_ =~ /\@date/)
	    {
		print ref($dat{$_}), "\n";
		# Should print 'Sybase::CTlib::DateTime'.
	    }
	}
    }
}
