use Win32::MSI::DB;
use Time::HiRes qw(gettimeofday tv_interval);


$db=Win32::MSI::DB::new ('test.msi',$Win32::MSI::MSIDBOPEN_TRANSACT);
$db || die "can't open database\n";

$dir=$db->table("Directory") || $db->die();
#print join(" ",$dir->colnames()),"\n";
%d=%p=();
for $rec ($dir->records())
{
	$p{ $rec->get("Directory") } = $rec->get("Directory_Parent") ;
	$d{ $rec->get("Directory_Parent") } { $rec->get("Directory") } = 1;
	$n{$rec->get("Directory")}= $rec->get("DefaultDir");
}

RecDir(0, grep(!exists $n{$_}, keys %d));
sub RecDir
{
	my($eb,@list)=@_;
	my($d);

	for $d (sort @list)
	{
		print "   " x $eb,($n{$d} =~ /([^\|]+)$/),"\n";
		&RecDir($eb+1,keys %{$d{$d}});
	}
}
exit;

$t0 = [gettimeofday];
$tbl=$db->table("File") || die $db->error();
$t1 = [gettimeofday];

@rec=$tbl->records();
$t2 = [gettimeofday];
for $rec (@rec)
{
	$rec->get("FileName");
}
$t3 = [gettimeofday];

print "table:", tv_interval($t0,$t1),"\n";
print "rec:", tv_interval($t1,$t2), "for ",scalar(@rec)," records\n";
print "get", tv_interval($t2,$t3), "for ",scalar(@rec)," records\n";
exit;
for $rec (@rec)
{
	printf "%-50s %7d %7d\n",
	$rec->get("FileName"),
	$rec->get("FileSize"),
	$rec->get("Attributes");
}

