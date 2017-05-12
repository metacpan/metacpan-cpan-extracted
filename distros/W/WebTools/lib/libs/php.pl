#####################################################################
# Broad library of base Php functions ported
# to Perl sub system: WebTools
# WARNING: NOT ALL OF FUNCTIONS WILL WORK AS YOU EXPECT!
#          That is related to particulrity of Perl language!
#####################################################################


# Implemented Set Of Functions

# $bool_result = IsSet(variable);
sub IsSet ($)
{
 if(shift(@_) ne undef) {return(1);}
 return(0);
}

# $bool_result = IsEmpty($scalar);
sub IsEmpty ($)
{
 my $fp = shift(@_);
 if(($fp eq undef) or ($fp eq '')) {return(1);}
 return(0);
}

# $type = gettype(variable);
sub gettype
{
 my ($fp_s) = @_;
 my @fp_a = @_;
 if($#fp_a == 0)
  {
   if(!IsSet($fp_s))  {return('EMPTY');}
   if(IsEmpty($fp_s)) {return('EMPTY');}
   if($fp_s =~ m/^(\+|\-)?([0-9])+$/s) {return('INT');}
   if($fp_s =~ m/^(\+|\-)?([0-9])*?(\.|\,)([0-9])+$/s) {return('FLOAT');}
   if(length(ref($fp_s))) {return('REF:'.ref($fp_s))};
   return('SCALAR');
  }
 else {return('LIST');}
}

# $bool_result = is_int(variable);
sub is_int
{
 my ($fp_s) = @_;
 if(gettype($fp_s) eq 'INT') {return(1);}
 return(0);
}

# $bool_result = is_integer(variable);
sub is_integer
{
 return(is_int(shift(@_)));
}

# $bool_result = is_long(variable);
sub is_long
{
 return(is_int(shift(@_)));
}

# $bool_result = is_float(variable);
sub is_float
{
 my ($fp_s) = @_;
 if(gettype($fp_s) eq 'FLOAT') {return(1);}
 return(0);
}

# $bool_result = is_double(variable);
sub is_double
{
 return(is_float(shift(@_)));
}

# $bool_result = is_real(variable);
sub is_real
{
 return(is_float(shift(@_)));
}

# $bool_result = is_string(variable);
sub is_string
{
 my ($fp_s) = @_;
 if(gettype($fp_s) eq 'SCALAR') {return(1);}
 return(0);
}

# $bool_result = is_ref(variable);
sub is_ref
{
 my ($fp_s) = @_;
 if(gettype($fp_s) =~ m/^REF\:/s) {return(1);}
 return(0);
}

# $new_value = settype($var,$type);
sub settype ($$)
{
 my ($fp_s,$type) = @_;
 
 if(($type =~ m/^int$/si) or ($type =~ m/^integer$/si))
  {
   $fp_s =~ s/ //g;
   $fp_s =~ s/\,/\./g;
   $fp_s =~ s/[^0-9\-\+\.]//g;
   return(int($fp_s));
  }
 if(($type =~ m/^double$/si) or ($type =~ m/^real$/si) or ($type =~ m/^float$/si))
  {
   $fp_s =~ s/ //g;
   $fp_s =~ s/\,/\./g;
   $fp_s =~ s/[^0-9\.\-\+]//g;
   return($fp_s + 0.0);
  }
 if(($type =~ m/^string$/si) or ($type =~ m/^str$/si))
  {
   return($fp_s.'');
  }
 if(($type =~ m/^bool$/si) or ($type =~ m/^boolean$/si))
  {
   if(($fp_s ne undef) and ($fp_s ne 0) and (length($fp_s) > 0)) {return(1);}
   return(0);
  }
 return($fp_s);
}

# $new_value = integer($var);
sub integer ($)
{
 my ($fp_s) = @_;
 $fp_s = settype($fp_s,'int');
 return($fp_s);
}

# $new_value = double($var);
sub double ($)
{
 my ($fp_s) = @_;
 $fp_s = settype($fp_s,'double');
 return($fp_s);
}

# $new_value = real($var);
sub real ($)
{
 my ($fp_s) = @_;
 $fp_s = settype($fp_s,'double');
 return($fp_s);
}

# $new_value = float($var);
sub float ($)
{
 my ($fp_s) = @_;
 $fp_s = settype($fp_s,'double');
 return($fp_s);
}

# $new_value = string($var);
sub string ($)
{
 my ($fp_s) = @_;
 $fp_s = settype($fp_s,'string');
 return($fp_s);
}

# $new_value = ceil ($double);
sub ceil ($)
{
 my ($fp_s) = @_;
 $fp_s = double($fp_s);
 return(int($fp_s + 0.5));
}

# $new_value = round ($double);
sub round ($)
{
 my ($fp_s) = @_;
 $fp_s = double($fp_s);
 return(int($fp_s + 0.5));
}

# $new_value = floor ($double);
sub floor ($)
{
 my ($fp_s) = @_;
 $fp_s = double($fp_s);
 return(int($fp_s - 0.5));
}

# $new_value = trunc ($double);
sub trunc ($)
{
 my ($fp_s) = @_;
 $fp_s = double($fp_s);
 return(int($fp_s));
}

# $ret = echo (...);
sub echo
{
 return(print(@_));
}

# $string = addslashes ($str);
sub addslashes
{
 my ($fp_s) = @_;
 $fp_s =~ s/\\/\\\\/sg;
 $fp_s =~ s/\'/\\\'/sg;
 $fp_s =~ s/\"/\\\"/sg;
 $fp_s =~ s/\x0/\\\x0/sg;
 return($fp_s);
}

# $string = bin2hex ($str);
sub bin2hex
{
 my $str = shift;
 $str =~ s/(.)/uc sprintf("%02x",ord($1))/seg;
 return $str
}

# $string = htmlspecialchars ($str);
sub htmlspecialchars 
{
 my $str = shift;
 $str =~ s{&}{&amp;}gso;
 $str =~ s{\"}{&quot;}gso;
 $str =~ s{<}{&lt;}gso;
 $str =~ s{>}{&gt;}gso;
 return $str;
}

# $string = undo_htmlspecialchars ($str);
sub undo_htmlspecialchars
   {
    my ($string) = shift(@_);
    
    $string =~ s/\&amp\;/\&/sgi;
    $string =~ s/\&quot\;/\//sgi;
    $string =~ s/\&lt\;/\</sgi;
    $string =~ s/\&gt\;/\>/sgi;
    return $string;
  }

# $string = htmlencode ($str);
sub htmlencode
   {
    my ($string) = shift(@_);
    my $ret_string="";
    my $x;
    my $ord;
    $string =~ s#(.)#do{
     $ord = ord($1);
     $ret_string .= "&\#$ord;";
     };#sgie;
    return $ret_string;
   }

# $string = implode ($join_string, @array);
sub implode
{
 return(join(shift(@_),@_));
}

# @array = explode ($split_separator, $string, $limit);
sub explode
{
 my $spl = shift(@_);
 my $str = shift(@_);
 my $lim = &integer(shift(@_));
 my @arr = ();
 my @add = ();
 my @res = ();
 my $el;
 my $cnt = 0;
 my $flag = 1;
 @arr = split($spl,$str);
 
 foreach $el (@arr)
  {
   if((!&IsEmpty($lim)) and ($lim != 0) and ($cnt == ($lim-1))) {$flag = 0;}
   $cnt++;
   if($flag)
    {
     push(@res,$el);
    }
   else
    {
     push(@add,$el);
    }
  }
 if(scalar(@add) > 0) {push(@res,join($spl,@add));}
 
 return(@res);
}

# $string = trim ($str);
sub trim
{
 my $str = shift(@_);
 $str =~ s/^\ *//s;
 $str =~ s/\ *$//s;
 return($str);
}

# $string = ltrim ($str);
sub ltrim
{
 my $str = shift(@_);
 $str =~ s/^\ *//s;
 return($str);
}

# $string = rtrim ($str);
sub rtrim
{
 my $str = shift(@_);
 $str =~ s/\ *$//s;
 return($str);
}

# $length = strlen ($str);
sub strlen
{
 return(length(shift(@_)));
}

# $pos = strpos (...);
sub strpos
{
 return(index($_[0],$_[1],$_[2]));
}

# $str = wordwrap ($str,$width,$brk,$cut);
sub wordwrap
{
 my ($str,$width,$brk,$cut) = @_;
 my ($l,$clen,$res);
 return($str) if($str eq '');
 
 if($cut != 0 and $cut != 1) {$cut = 0;}
 if($width eq 0 or $width eq '') {$width = 75;}
 $brk = $brk || "\n";

 $clen = 0;
 $res = '';
 if($cut)
  {
   while($str)
    {
     my $l = substr($str,0,$width,'');
     $res .= $l.$brk;
    }
  }
 else
  {
   my @data = split(/\ /,$str);
   foreach $l (@data)
    {
     if(($clen + length($l)+1) > $width)
       {
        if($clen == 0)
          {
           $res .= $l." ";
          }
        else
          {
           $res .= $brk.$l." ";
          }
        $clen=(length($l)+1);
       }
     else 
       {
        $res .= $l." ";
        $clen += (length($l)+1);
       }
    }  
  }
 return($res);
}

# @ips = mx_lookup($domain_or_ip, [$path_to_nslookup_or_to_host]);
# Windows like OS should use 'nslookup' but Unix like OS should use 'host'!
sub _mx_lookup
{
 print "Use mx_lookup() from mail.pl library!";
 exit;
}



# TODO: More and more... :-)
$webtools::loaded_functions = $webtools::loaded_functions | 512;
1;