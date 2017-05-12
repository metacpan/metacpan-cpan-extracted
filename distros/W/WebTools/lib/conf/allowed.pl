#################################################
# Set of IPs from where scripts can be executed!
#################################################

my @allowed_IPs = ();
open (IPF, $webtools::db_path.'ips.pl');
my @IPs = <IPF>;  # Load allowed IPs
close IPF;
foreach my $ip (@IPs)
 { 
  $ip =~ s/^(.*?)(#.*)$/$1/si;
  $ip =~ s/(\n|\r|\t)//sg;
  if($ip) {push(@allowed_IPs,$ip);}
 }

#################################################
# Call this function to check whether calling
# IP mach your restrictions.
#################################################

sub Check_Remote_IP
{
 my $ip = shift(@_);
 my ($act,$addr,$url,$l) = ();
 my @a = ('0','');
 foreach $l (@allowed_IPs)
  {
   $l =~ /^(\!)?([^\ ]+)(\ {0,})(.*)$/s;
   ($act,$addr,$url) = ($1,$2,$3.$4);

   $addr =~ s/^\ {1,}//s; $addr =~ s/\ {1,}$//s;
   $url  =~ s/^\ {1,}//s; $url  =~ s/\ {1,}$//s;
   
   $addr =~ s/\./\\./sg;
   $addr =~ s/\*/\\d{0,3}/sig;
   $addr =~ s/\?/\\d{1}/sig;
   $addr = '^'.$addr.'$';
   if($ip =~ m/$addr/s)
     {
      @a = ('1',$url);
      if($act eq '!')
       {
        @a = ('0',$url);
       }
      return(@a);
     }
    else
     {
      if($act eq '!')
       {
        @a = ('1',$url);
        return(@a);
       }
     }
  }
 return(@a);
}

1;