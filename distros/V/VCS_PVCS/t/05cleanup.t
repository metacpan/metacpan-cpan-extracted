use ExtUtils::Command;

print "1..2\n";
my($i)=1;

chdir ("t/PVCSPROJ") && (print "ok $i\n");
$i++;
my ($files) = "islvrc.txt examples.cfg examples.cfg.old examples.prj PVCSWORK/src/*.c PVCSWORK/src/*.h archives/src/*.h_v archives/src/*.c_v archives/src/journal.vcs pvcsproj.pub nfsmap";

@ARGV = split(' ',$files);
rm_rf();
print "ok $i\n";
