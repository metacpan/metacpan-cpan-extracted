################################
# Miscellaneous Tools:
# "tools.pl"
################################

if(!($webtools::loaded_functions & 8)) {require $library_path."xreader.pl";}
$webtools::loaded_functions = $webtools::loaded_functions | 32;
# $bool = CheckLength($int_var, $min_val, $max_val);
sub CheckLength
{
 my ($var,$min,$max) = @_;
 if($min > $max)
   {
    my $tmp = $min;
    $min = $max;
    $max = $tmp;
   }
 my $lng = length($var);
 if(($lng <= $max) and ($lng >= $min)) {return(1);}
 return(0);
}

# $trimed_str = Trim($str);
sub Trim
{
 my $str = shift(@_);
 $str =~ s/^\ *//s;
 $str =~ s/\ *$//s;
 return($str);
}

################################
# Check out diffrent data
# Supported check for:
# 'name','cc','age','date',
# 'number', 'email','phone','base'
################################
sub CheckData
{
 my %in = @_;
 if (!exists($in{'type'}))
   {
    return(undef);
   }
 $type = $in{'type'};
 $var = $in{'var'};
 
 if($type eq 'name')
   {
    if ($var eq '') { return (0);}
    if($var =~ m/^[A-Za-z ]*$/is) { return(1); }
    if($var =~ m/^[À-ßà-ÿ ]*$/is) { return(1); }
    return(0);
   }
 if($type eq 'cc')
   {
    if(($var =~ m/^\d{14,20}$/is)) 
     {
      if(cardtype($var) eq undef) { return(0); }
      return(validate($var));
      return(1); 
     }
    return(0);
   }
 if($type eq 'age')
   {
    if(($var =~ m/^\d{1,3}$/is)) { return(1); }
    return(0);
   }
 if($type eq 'date')
   {
    # Supported date formats:
    # DD/MM/YYYY
    # DD MM YYYY
    # DD:MM:YYYY
    # DD-MM-YYYY
    # And convert current date in last format: DD-MM-YYYY
    my ($dd,$mm,$yy) = ();
    if ($var =~ m/^(\d{1,2})(\/|\ {1,}|\:|\-)(\d{1,2})(\/|\ {1,}|\:|\-)(\d{4})$/s)
      {
      	($dd,$mm,$yy) = ($1,$3,$5);
      	my $c = 2 - length($dd);
      	$dd = ('0'x$c).$dd;
      	$c = 2 - length($mm);
      	$mm = ('0'x$c).$mm;
      	my $result = $dd.'-'.$mm.'-'.$yy;
      	return($result);
      }
     else { return(0);}
   }
 if($type eq 'number')
   {
    if(($var =~ m/^\d*$/is) and ($var ne '')) { return(1); }
    return(0);
   }
 if($type eq 'email')
   {
    if(($var =~ m/^([A-Za-z0-9\_\-\.]+)\@([A-Za-z0-9\_\-\.]+)\.([A-Za-z]{2,})$/is)) { return(1); }
    return(0);
   }  
 if($type eq 'phone')
   {
    if($var =~ m/^[0-9\(\)\-\ \,\.\;\+\*\[\]\{\}]+$/is) { return(1); }
    return(0);
   }
 if($type eq 'base')
   {
    if($var =~ m/^[A-Za-zÀ-ßà-ÿ0-9\$\(\)\-\;\ \_\,\+\*\[\]\{\}\'\"\;\:\%\@\!\#\~\.\,\`\\\/]+$/is) { return(1); }
    return(0);
   }
}
################################
# Make scalar from scalars
################################
sub MakeScalar
{
 my @a = @_;
 my $sclr = '';
 
 my $escape = "\Ž";
 my $row_sep = "\™";
 my $col_sep = "\®";
 
 my $nxt = 0;
 my $self = '';
 
 foreach $l (@a)
  {
   if($nxt)
    {
     $sclr .= $self.$col_sep.encode_separator($l, $escape, $row_sep, $col_sep);
     $nxt--;
    }
   else
    {
     $self = encode_separator($l, $escape, $row_sep, $col_sep);
     $nxt++;
    }
   $sclr .= $row_sep;
  }
 return($sclr);
}
################################
# Make array from scalars
################################
sub MakeArray
{
 my ($sclr) = @_;
 my @a = ();
 my @result = (); 
 
 my $escape = "\Ž";
 my $row_sep = "\™";
 my $col_sep = "\®";
 
 @a = split(/\™/s,$sclr);
 foreach $line (@a)
  {
   my ($a,$b) = split(/$col_sep/,$line);
   $a = decode_separator($a, $escape, $row_sep, $col_sep);
   $b = decode_separator($b, $escape, $row_sep, $col_sep);
   push (@result,$a);
   push (@result,$b);
  }
 return(@result);
}
#######################################################################
# Credit Card Routine
# Check Type of CC
################################
sub cardtype {
    my ($number) = @_;

    $number =~ s/\D//g;

    return "VISA" if substr($number,0,1) == "4";
    return "MasterCard" if substr($number,0,1) == "5";
    return "Discover" if substr($number,0,1) == "6";
    return "AmericanExpress" if substr($number,0,2) == "37";
    return undef;
}
################################
# Credit Card Routine
# Generate Last Number of CC
################################
sub generate_last_digit {
    my ($number) = @_;
    my ($i, $sum, $weight);

    $number =~ s/\D//g;

    for ($i = 0; $i < length($number); $i++) {
	$weight = substr($number, -1 * ($i + 1), 1) * (2 - ($i % 2));
	$sum += (($weight < 10) ? $weight : ($weight - 9));
    }

    return (10 - $sum % 10) % 10;
}
################################
# Credit Card Routine
# Validate CC
################################
sub validate {
    my ($number) = @_;
    my ($i, $sum, $weight);

    $number =~ s/\D//g;

    for ($i = 0; $i < length($number) - 1; $i++) {
	$weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
	$sum += (($weight < 10) ? $weight : ($weight - 9));
    }

    return 1 if substr($number, -1) == (10 - $sum % 10) % 10;
    return 0;
}
#######################################################################
# @ = readFile(fileName)
############################
  sub readFile {
    local $filename = shift(@_);
    local @fileArr = ();
    open (srcFile, $filename);
    while (<srcFile>){
      chop;
      push(@fileArr, $_);
    }
    close (srcFile);
    return @fileArr;
  }
###################################
# Make redirect to some one Link
###################################
sub LinkTo
 {
  my $urlto = shift (@_);
  my $buf = '<HTML><HEAD><META HTTP-EQUIV="refresh" CONTENT="0;URL='.
            $urlto.'"></HEAD></HTML>';
  return($buf);
}
################################################
# Print One Web Page to Browser`s output stream
################################################
sub PrintHtml
{
 my ($file,$path,$base) = @_;
 binmode(STDOUT);
 open(HFILE,$path.$file) or do {
     return('<br><FONT COLOR="#ff0000" SIZE=+1> Web Page not found! </FONT><br>');
    };
 binmode(HFILE);
 read(HFILE,$page,(-s $path.$file));
 close (HFILE);
 $base = '<BASE HREF="'.$base.'">';
 $page =~ s~<HEAD>~<HEAD>\n$base\n~si;
 return ($page);
}
#######################################################################
# That function is very imortant to be explained!
# You must supplay: User,Password,Empty,Old_SID and DB Handler,
# where: Empty is 1, if User and Password vars are not defined;
#     Old_SID is Session ID found from GetCurrentSID($dbh);
# If you want you can suply pointer to custom SignInUser at
# the end of paramerters line!
# Function return action depened of these data.
# Syntax: ($action,$user,$pass,$ID,$DATA) = UserPassword(....);
# Where $action can be: 
# 'redirect' - mean that, no user/pass were found and you
#     must redirect to check out form.
# 'new' - You must create new session, to register vars and to
#     print "Users" menu and so on..
# 'menu' - Evrything is OK..so you must print only menu (without
#     creating new session!)
# 'incorect' - That mean, that your data are wrong i.e. User and/or
#     password are incorect!
# Note: $pass,$ID and $DATA will have empty values if user is 
#   already loged (i.e. user has opened session), so these values
#   will have empty values when $action has value 'menu'!!!
##################################################################
sub UserPassword
{
 my ($user,$pass,$empty,$old_sid,$dbh,$signinuser_sub_ref) = @_;
 my $result = undef;
 my ($id,$data,$sid,$user_loged) = ();
 my ($back_up_header,$back_up_buffer,$back_up_flsh)= ();
 if($old_sid eq '')   # SID is empty
   {
    if($empty)
     {
       # Here we must "Redirect" to entry user/pass page.
       $result = 'redirect';
     }
    else
     {
       if(!ref($signinuser_sub_ref))
        {
         ($id,$data) = SignInUser($user,$pass,$dbh);
        }
       else
        {
         ($id,$data) = &$signinuser_sub_ref($user,$pass,$dbh);
        }
 # Check INPUT User and Pass.
       if ($id eq undef)
         {
	   # Here we must note user that user and pass are incorect!
	   $result = 'incorect';
	 }
       else
        {
	  # Here we must create NEW session, register vars and print MENU.
	  $result = 'new';
	}
     }
   }
 else   #  SID is supplied
  {
   if($empty)
     {
      $back_up_header = $print_flush_buffer;
      $back_up_buffer = $print_header_buffer;
      $back_up_flsh = $sess_header_flushed;
      
      $sid = session_start($dbh,0);
      
      # Read saved values from previos script run.
      $user = read_scalar('user');
      $user_loged = read_scalar('user_loged');
      $pass = '';
      
      $print_flush_buffer = $back_up_header;
      $print_header_buffer = $back_up_buffer;
      $sess_header_flushed = $back_up_flsh;
      
      if($user_loged eq '1')
       {
        # Here we must ONLY print MENU.
	$result = 'menu';
       }
      else
       {
       	# Here we must "Redirect" to entry user/pass page.
	$result = 'redirect';
       }
     }
    else
     {
       if(!ref($signinuser_sub_ref))
        {
         ($id,$data) = SignInUser($user,$pass,$dbh);
        }
       else
        {
         ($id,$data) = &$signinuser_sub_ref($user,$pass,$dbh);
        }
       # Check INPUT User and Pass.
       if ($id eq undef)
         {
	   # Here we must note user that user and pass are incorect!
	   $result = 'incorect';
	 }
       else
        {
	  # Here we must create NEW session, register vars and print MENU.
	  $result = 'new';
	}
     } 
  }
 return(($result,$user,$pass,$id,$data));
}

sub encode_separator
  {
    my ($str, $escape, $row_sep, $col_sep) = @_;

    my $esc_hex = uc($escape.join('',unpack("Hh", $escape x 2)));
    my $row_hex = uc($escape.join('',unpack("Hh",$row_sep x 2)));
    my $col_hex = uc($escape.join('',unpack("Hh",$col_sep x 2)));
    
    $escape = quotemeta($escape);
    $row_sep = quotemeta($row_sep);
    $col_sep = quotemeta($col_sep);
    
    $str =~ s/$escape/$esc_hex/gsi;
    $str =~ s/$row_sep/$row_hex/gsi;  
    $str =~ s/$col_sep/$col_hex/gsi;
    return($str);
  }

sub decode_separator
  {
    my ($enstr, $escape, $row_sep, $col_sep) = @_;

    my $esc_hex = uc($escape.join('',unpack("Hh", $escape x 2)));
    my $row_hex = uc($escape.join('',unpack("Hh",$row_sep x 2)));
    my $col_hex = uc($escape.join('',unpack("Hh",$col_sep x 2)));
    
    $enstr =~ s/$esc_hex/$escape/gsi;
    $enstr =~ s/$row_hex/$row_sep/gsi;  
    $enstr =~ s/$col_hex/$col_sep/gsi;
    return($enstr);
  }

# $GET_method_type_string = make_Form((key1=>'val1',key2=>'val2',...));
sub make_Form
{
 my %arr = @_;
 $msg = "";
 @all_keys = keys(%arr);
 for($i=0; $i< $#all_keys; $i++)
   {
    $k = $all_keys[$i];
    $v = $arr{$k};    
    $v =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/seg;
    $v =~ s/\%20/\+/sg;  
    $m = $k."=".MIME_encoding_data($v);
    if(($i+1) != $#all_keys) {$m .= '&'};
    $msg .= $m;
   }
 return($msg);
}

1;