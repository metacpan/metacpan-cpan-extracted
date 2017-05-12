# -*- perl -*-

print "1..0 # skip Tk::FastSplash not supported anymore\n";

__END__

BEGIN { $| = 1; $^W = 0; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

BEGIN {
    require Tk::FastSplash;
    $loaded = 1;
    print "ok 1\n";
}

sub findINC
{
 my $file = join('/',@_);
 my $dir;
 $file  =~ s,::,/,g;
 foreach $dir (@INC)
  {
   my $path;
   return $path if (-e ($path = "$dir/$file"));
  }
 return undef;
}

BEGIN {
    $splash = Tk::FastSplash->Show(findINC("Tk", "Xcamel.gif"),
				   60, 60, "Splash");
    print "ok 2\n";
}

use Tk;

$top=tkinit;
$top->update;

$splash->Destroy;
print "ok 3\n";

$top->update;
sleep 1;
