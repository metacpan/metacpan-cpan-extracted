my $joy = Win32::MultiMedia::Joystick->new();
if (!$joy) { die $joy->error," $!\n"; }

$joy->update;
print "Press Button 1 to start\n";
while (!$joy->B1)
{
   $joy->update;
}

sleep 1;
$joy->update;
while (!$joy->B1)
{
   $joy->update;
   print $joy->X, "\t", $joy->Y,"\n";
}

