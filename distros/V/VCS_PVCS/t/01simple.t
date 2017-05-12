#!../../perl 
BEGIN{
    use Cwd;
    my($wd) = cwd();
    $ENV{'ISLVINI'} = "$wd/t/PVCSPROJ/islvrc.txt";
}
$|=1;
print "1..1\n";
use VCS::PVCS::Project;
print "ok 1\n";
