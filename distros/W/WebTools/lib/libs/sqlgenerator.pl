############################
# SQL Move/Limit generator
############################

$sys_SQL_generator_DefaultCount = 10;
$sys_SQL_generator_DefaultOrder = 'ORDER BY ID';
%sys_SQL_generator_Dirs = (up => 'bottom', down => 'top');

sub  MoveSQLGenerator
{
 my ($from,$count,$dir,$order) = @_;
 my @out = ();
 my $p;
 if($from <= 0){ $from = 1; }
 $from --;
 if($count <= 0) { $count = $sys_SQL_generator_DefaultCount; }
 if($dir eq '') {$dir = 'bottom';}
 push(@out,$from+1+$count);
 push(@out,$count);
 if($dir eq $sys_SQL_generator_Dirs{'up'})
   {
    $p = "LIMIT $from,$count";
   }
 if($dir eq $sys_SQL_generator_Dirs{'down'})
   {
    $p = "DESC LIMIT $from,$count";
   }
 if($order eq '') {$order = $sys_SQL_generator_DefaultOrder;}
 $q = $order.' '.$p.';';
 push(@out,$dir);
 push(@out,$q);
 return(@out);
}


# print MoveSQLGenerator(1,10,'top');


1;