#####################################################################
# eXternal Reader
# eXtended Reader
# eXcellent Reader
#####################################################################


my $x_sep_begin1 = '\<\©N\®';
my $x_sep_begin2 = '\®(\d{1})\®(.*?)\®\©\>';
my $x_sep_begin;
my $x_sep_end = '\<\˜\©\˜\>';
my $x_var = '\<\§VAR\§\>';
my $x_named_var = '\{\%\%(\$[^\%\<\>\n]+)\%\%\}';
my $x_sqlvar = '\<S\©LVAR\:(\d{1,})\:S\©L\>';
my $x_SQL_begin = '\<S\©L\:(\d{1,})\:\"(.*?)\"\:(\d{1,})\:(\d{1,})\:(\d{1,})\:(\d{1,})\:S\©L\>';
my $x_template_spl_b = '(\<\!\-\-\:XPART\:';
my $x_template_spl_e = '\:\-\-\>)';
my $x_template_split = $x_template_spl_b.'\d{1,}'.$x_template_spl_e;

my $x_sep_begin1_new = '\<\%N\%';                 # <%N%
my $x_sep_begin2_new = '\%(\d{1})\%(.*?)\%\>';    # %0%this.html%>
my $x_sep_begin_new;
my $x_sep_end_new = '\<\~\%\~\>';                 # <~%~>
my $x_sqlvar_new = '\%\%SQLVAR\:(\d{1,})\%\%';    # %%SQLVAR:2%%
my $x_SQL_begin_new = '\%\%SQL\:(\d{1,})\:\"?(.*?)\"?\:(\d{1,})\:(\d{1,})\:(\d{1,})\:(\d{1,})\:SQL\%\%';
                                                  # %%SQL:1:"select ...":1:1:1:1:SQL%%
my $x_sep_perl_inst = '\%\%perlsub\:([^\%]+)\%\%'; # %%perlsub:some_sub_name()%%

$sys_xreader_file = '';
$sys_xreader_buf = '';

$sys_sql_dbh = undef;
%sys_xreader_queries = ();
my @sys_xreader_VARS = ();

$webtools::loaded_functions = $webtools::loaded_functions | 8;

#####################################################
# That function read from file HTML data (with some
# futures) and substitue SQL queries and vars with
# respective values!
# $scalar = xreader($N_of_part,$filename);
# 
# USAGE:
# 
# $SOURCE = xreader(1,'file_found_in_jhtml_path.jhtml',
#                  $count);
# where your custom jhtml file contain part structured
# as follow:
#--- Save under: file_found_in_jhtml_path.jhtml ---
#<©N®1®1®®©>
#Count of visitors: <§VAR§>
#<˜©˜>
#
# For more information about structure of jhtml files
# please see docs/xreader-legend.txt
#
# TODO: Make calling this function as HTML tag...
#####################################################
sub xreader
{
 local *XFILE;
 my $number = shift(@_);
 my $filename = shift(@_);
 my @vals = @_;
 
 my $old_n = $/;
 $x_sep_begin = $x_sep_begin1.$number.$x_sep_begin2;
 $x_sep_begin_new = $x_sep_begin1_new.$number.$x_sep_begin2_new;
 my $data;
 
 if($sys_xreader_file eq $filename)
  {
   $data = $sys_xreader_buf;
  }
 else
  {
   open(XFILE,$xreader_path.$filename) or return(0);
   binmode(XFILE);
   read(XFILE,$data,(-s XFILE));
   close (XFILE);
   $data =~ s/\r\n/\n/gs;
   $sys_xreader_file = $filename;
   $sys_xreader_buf = $data;
   %sys_xreader_queries = ();
  }
 return(_xreader($data,@vals));
}

#####################################################
# That function is a low level xreader function!
# Actualy, that sub will make all work for xreader()
# $scalar = _xreader($data);
#####################################################
sub _xreader
{
 my ($data) = shift(@_);
 my @vals = @_;
 my $xparts;
 my $xprt_w;
 my $xprt_n;
 local *XFILE;
 @sys_xreader_VARS = ();
 my $x_matchs;
 $x_matchs = $data =~ s/$x_sep_begin(.*?)$x_sep_end/do {
    $xprt_w = $1;
    $xprt_n = $2;
    $xpart = $3;
 };/se;
 if(!$x_matchs)
  {
   $x_matchs = $data =~ s/$x_sep_begin_new(.*?)$x_sep_end_new/do {
    $xprt_w = $1;
    $xprt_n = $2;
    $xpart = $3;
   };/se;
  }
 if (($xprt_w eq '0') and ($xprt_n ne ''))
   {
    $sys_xreader_file = '';
    $sys_xreader_buf = '';
    %sys_xreader_queries = ();
    open(XFILE,$xreader_path.$xprt_n) or return(0);
    binmode(XFILE);
    read(XFILE,$xpart,(-s XFILE));
    close (XFILE); 
   }
 return(_mem_xreader($xpart,@vals));
}

# This function process one template from memmory buffer
sub _mem_xreader
{
 my ($xpart)  = shift(@_);
 my @vals = @_;
 my $xparts;
 my $x_matchs;
 # my @sys_xreader_VARS = ();

 my $xprt_part_from;
 my $xprt_part_to;
 my $data = $xpart;
 
 if($xpart =~ m/$x_template_split/si)
  {
   $xprt_part_from = shift(@vals); # First value must be 'from' part or '0' to start at begining.
   $xprt_part_to = shift(@vals);   # second value must be 'to' part or '0' to end of template.
   my $index_begin = 0;
   my $index_end = 0;

   if($xprt_part_from != 0)
     {
      my $tmplt = $x_template_spl_b.$xprt_part_from.$x_template_spl_e;
      $data =~ m/$tmplt/sig;
      $index_begin = pos($data);
     }
   if($xprt_part_to != 0)
     {
      my $tmplt = $x_template_spl_b.$xprt_part_to.$x_template_spl_e;
      $data =~ m/$tmplt/sig;
      $index_end = pos($data);
     }
   else
     {
      $index_end = length($data);
     }
   if(($index_begin != -1) && ($index_end != -1))
     {
      $xpart = substr($data,$index_begin,$index_end-$index_begin);
     }
   $xpart =~ s/$x_template_split//sig;
  }

 my $bkp_xpart = $xpart;
 $xpart =~ s#$x_named_var#do{
   my $x_e_var = $1;
   my $x_var_res;
   my $x_eval_var = '$x_var_res = '.$x_e_var.';';
   eval $x_eval_var;
   if($@ ne '') {$x_var_res = '';}
   $bkp_xpart =~ s/$x_named_var/$x_var_res/si;
 };#sgie;
 $xpart = $bkp_xpart;

 my @newar = split(/$x_var/si,$xpart);
 $xpart = '';
 
 my $l;
 my @nprts;
 foreach $l (@newar)
  {
   push(@nprts,split(/\%\%VAR\%\%/si,$l));
  }
 @newar = @nprts;
 
 foreach $l (@newar)
  {
    my $loc = shift(@vals);
    $loc =~ s/\±\ÿ\‹//gs;
    if ($loc eq undef) { $loc = ''; }
    $xpart .= $l.$loc;
  }
 $xpart =~ s/^\n(.*)\n$/$1/s;
 
 $xpartb = $xpart;
 $xpart =~ s#$x_sep_perl_inst#do{
   my $name = $1;
   local $x_results = '';
   my $code = '$x_results = '.$name;
   if(!($code =~ m/\;$/)){$code .= ';';}
   eval $code;
   $xpartb =~ s/$x_sep_perl_inst/$x_results/si;
  };#sgie;
 $xpart = $xpartb;

 my $var_counter = 1;
 $xpart =~ s/$x_SQL_begin/do{
  my $numb = $1;
  my $q = $2;
  my $qd = $3;
  my $rq = $4;
  my $c = $5;
  my $visible = $6;
  my $res = '';
  if(exists($sys_xreader_queries{'Q'.$qd.'R'.$rq.'C'.$c}))
    {
     $res = $sys_xreader_queries{'Q'.$qd.'R'.$rq.'C'.$c};
    }
  elsif($sys_sql_dbh ne undef)
    {
     my $r = sql_query($q,$sys_sql_dbh);
     my $x = 1;
     my @arr;
     if($r ne undef)
      {
       while((@arr = sql_fetchrow($r)))
        {
       	 my $i = 1;
         foreach my $l (@arr)
           {
            my $nm = 'Q'.$numb.'R'.$x.'C'.$i;
            $sys_xreader_queries{$nm} = $l;
            $i++;
           }
         $x++;
         @arr = ();
        }
       my $dn = 'Q'.$numb.'R'.$rq.'C'.$c;
       $res = $sys_xreader_queries{$dn};
       }
     push(@sys_xreader_VARS,$res); $var_counter++;
     if(!$visible) { $res = ''; }
    }
  else { $res = ''; }
  $xpartb =~ s!$x_SQL_begin!$res!si;
 };/sige;
 $xpart = $xpartb;

 $xpart =~ s/$x_sqlvar/do{
   my $cl = $sys_xreader_VARS[$1-1];
   $xpartb =~ s!$x_sqlvar!$cl!si;
 };/sige;
 $xpart = $xpartb;
 
 $xpart =~ s/$x_SQL_begin_new/do{
  my $numb = $1;
  my $q = $2;
  my $qd = $3;
  my $rq = $4;
  my $c = $5;
  my $visible = $6;
  my $res = '';
  if(exists($sys_xreader_queries{'Q'.$qd.'R'.$rq.'C'.$c}))
    {
     $res = $sys_xreader_queries{'Q'.$qd.'R'.$rq.'C'.$c};
    }
  elsif($sys_sql_dbh ne undef)
    {
     my $r = sql_query($q,$sys_sql_dbh);
     my $x = 1;
     my @arr;
     if($r ne undef)
      {
       while((@arr = sql_fetchrow($r)))
        {
       	 my $i = 1;
         foreach my $l (@arr)
           {
            my $nm = 'Q'.$numb.'R'.$x.'C'.$i;
            $sys_xreader_queries{$nm} = $l;
            $i++;
           }
         $x++;
         @arr = ();
        }
       my $dn = 'Q'.$numb.'R'.$rq.'C'.$c;
       $res = $sys_xreader_queries{$dn};
       }
     push(@sys_xreader_VARS,$res); $var_counter++;
     if(!$visible) { $res = ''; }
    }
  else { $res = ''; }
  $xpartb =~ s!$x_SQL_begin_new!$res!si;
 };/sige;
 $xpart = $xpartb;

 $xpart =~ s/$x_sqlvar_new/do{
   my $cl = $sys_xreader_VARS[$1-1];
   $xpartb =~ s!$x_sqlvar_new!$cl!si;
 };/sige;
 
 $xpart = $xpartb;
 return($xpart);
}
###################################
sub xreader_dbh ($)  # Set default DB Handler for SQL operations!
{
 my $sys_dbh = shift(@_);
 if($sys_dbh ne '') { $sys_sql_dbh = $sys_dbh;}
 else { $sys_sql_dbh = undef;}
}

##################################################
# Read all templates from file and query DB for
# respective Products IDs!
# USAGE:
# @Array_With_Prod_IDs = xshopreader('',$dbh,'my_products_html_template_page.html');
# or
# @Array = xshopreader($read_html_source,$dbh);

sub xshopreader
{
 my ($data,$dbh,$fname) = @_;
 my ($id,$q,$work,$r);
 local *SHOPT;
 my @arr;
 my @result = ();
 if($fname ne '')
   {
    open (SHOPT,$fname) or return(-2);
    read(SHOPT,$data,(-s SHOPT));
    close (SHOPT);
   }
 # Please do not use "#" in follow block!
 # where $1 is ID number and $2 is SQL query returned ID
 # Example: 
 # <SHOP_ITEM:1:SELECT Product_ID FROM products WHERE Product_Hot='Y' AND Product_Category='0':>
 $data =~ s#\<SHOP\_ITEM\:(\d{1,10})\:(.*?)\:\>#do
   {
    $id = $1;
    $q  = $2;
    $r = sql_query($q,$dbh);
    if($r)
      {
       @arr = sql_fetchrow($r);
       push(@result,$arr[0]);
      }
    else { push(@result,-1);}
   };#sige;
 
 return(@result);
}

#######################################################
# USAGE:
# $SOURCE  = 'Message of the <B>day</B>: <§TEMPLATE:7§><br>';
# 
# $SOURCE = ReplaceTemplateWith(7,$SOURCE,'New release of Webtools is now available!');

sub ReplaceTemplateWith
 {
  my ($numb,$var,$msg) = @_;
  $var =~ s/\<\§TEMPLATE\:$numb\§\>/$msg/is;
  $var =~ s/\?\?TEMPLATE\:$numb\?\?/$msg/is;
  $var =~ s/\%\%TEMPLATE\:$numb\%\%/$msg/is;
  return($var);
 }

# Clear all fields that are not still replaced!
sub ClearAllTemplates
 {
  my ($var,$msg) = @_;
  $var =~ s/\<\§TEMPLATE\:\d{1,}\§\>/$msg/is;
  $var =~ s/\?\?TEMPLATE\:\d{1,}\?\?/$msg/is;
  $var =~ s/\%\%TEMPLATE\:\d{1,}\%\%/$msg/is;
  return($var);
 }

#######################################################
# USAGE:
# @DB_VALUES = ("Y","N","-");
# @TEMPLATE_NUMBERS = (1,2,3);
# @HTML_VALUES = ("checked","");
# $SOURCE  = '<input type="radio" name="Male" value="Y" <§TEMPLATE:1§>>Yes<br>';
# $SOURCE .= '<input type="radio" name="Male" value="N" <§TEMPLATE:2§>>No';
# $SOURCE .= '<input type="radio" name="Male" value="-" <§TEMPLATE:3§>>Unknown :-)';
# 
# $SOURCE = MenuSelect($SOURCE,"SELECT MenuState FROM MyTable WHERE Condition1 = $C1 AND ...",
#                      \@DB_VALUES,\@TEMPLATE_NUMBERS,\@HTML_VALUES,$dbh);
# TODO: Make calling this function as HTML tag...

sub MenuSelect
 {
  my ($var,$q,$SQL_ref,$VAR_ref,$MACH_ref,$dbh) = @_;
  my @SQL_arr = @$SQL_ref;
  my @VAR_arr = @$VAR_ref;
  my @MACH_arr = @$MACH_ref;
  my @row = ();
  my $sa_size = $#SQL_arr;
  my $ptr = 0;
  my $res;
  if($q =~ m/^\!(.*?)$/si)
    {
     @row = split(/\,/,$1);
    }
  else
    {
     $res = sql_query($q, $dbh);
     if($res) {@row = sql_fetchrow($res);}
     else { @row = (); }
    }
  my $row_size = $#row;
  my $i;
  for ($i=0;$i<=$sa_size;$i++)
    {
     $res = $row[$ptr];
     if($res eq $SQL_arr[$i])
       {
        my $row_number = $VAR_arr[$i];
        $var = ReplaceTemplateWith($row_number,$var,$MACH_arr[0]);
        $r = $row[$ptr++];
        if($ptr <= $row_size) {$i = -1;}
        else {last;}
       }
    }
  if(($row[0] eq '') && ($row_size == 1))
    {
     $var = ReplaceTemplateWith($VAR_arr[0],$var,$MACH_arr[0]);
    }
  my $va_size = $#VAR_arr+1;
  for ($i=0;$i<$va_size;$i++)
    {
     $var = ReplaceTemplateWith($VAR_arr[$i],$var,$MACH_arr[1]);
    }
  return($var);
 }

1;