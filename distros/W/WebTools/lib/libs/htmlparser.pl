#########################################################################
# Xreader HTML Parser
# Vers 2.0
# Last modified: 26.07.2002
#########################################################################

#########################################################################
# Parse whole HTML with hash!
# PROTO: $html = html_parse($html,$hash_ref,%data);
# Where: $html is html code where script parsing;
#        $hash_ref is reference to hash with "old" values of parsed,
#              tags;
#        %data is hash with "name" : "value" for tags.
#########################################################################
sub html_parse
{
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 $html =~ s/\r\n/\n/sgi;
 my %inp = @_;
 my @forms = ();
 my $result = '';
 while($html =~ m/^(.*?)(\<\/FORM\>)/si)
  {
   push(@forms,$1.$2);
   $html =~ s/^(.*?)(\<\/FORM\>)//si;
  }
 push(@forms,$html);
 foreach $html (@forms)
  {
   foreach $k (keys %inp)
    {
     $html = html_parse_input($k,$inp{$k},$html,$hashref);
     $html = html_parse_select($k,$inp{$k},$html);
     $html = html_parse_textarea($k,$inp{$k},$html,$hashref);
     $html = html_parse_frame($k,$inp{$k},$html,$hashref);
     $html = html_parse_link($k,$inp{$k},$html,$hashref);
     $html = html_parse_meta($k,$inp{$k},$html,$hashref);
     $html = html_parse_img($k,$inp{$k},$html,$hashref);
    }
   $result .= $html;
  }
 return($result);
}
#########################################################################
# Parse one FORM
# PROTO: $html = html_parse_form($form,$html,
#                                $hash_ref,%data);
#########################################################################
sub html_parse_form
{
 my ($name) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 $html =~ s/\r\n/\n/sgi;
 my %inp = @_;
 my ($uniq) = generate_unique_string($html);
 my $data = $html;
 my $temp;
 my ($k,$key,$v);
 
 $html =~ s#(\<FORM[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>(.*?)(\<\/FORM\>)#do{
     $temp = $uniq.":1:";
     my $begin = $1.$2.$3.$4.$5.$6.'>';
     my $end = $8;
     $v = $7;
     $data =~ s/(\<FORM[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>(.*?)\<\/FORM\>/$begin$temp$end/si;
     $k = $temp;
     foreach $key (keys %inp)
      {
       $v = html_parse_input($key,$inp{$key},$v,$hashref);
       $v = html_parse_select($key,$inp{$key},$v);
       $v = html_parse_textarea($key,$inp{$key},$v,$hashref);
       $v = html_parse_frame($key,$inp{$key},$v,$hashref);
       $v = html_parse_link($key,$inp{$key},$v,$hashref);
       $v = html_parse_meta($key,$inp{$key},$v,$hashref);
       $v = html_parse_img($key,$inp{$key},$v,$hashref);
      }
     substr($data,index($data,$k),length($k),$v);
 };#sie;

 return($data);
}
#########################################################################
# Parse one select filed
# PROTO: 
# $html = html_parse_select($name,$val,$html);
#########################################################################
sub html_parse_select
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my ($uniq) = generate_unique_string($html);
 my $data = $html;
 my $temp;
 my $k;
 my $v;

 $html =~ s#(\<SELECT[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>(.*?)(\<\/SELECT\>)#do{
     $temp = $uniq.":1:";
     my $begin = $1.$2.$3.$4.$5.$6.'>';
     my $end = $8;
     $v = $7;
     $data =~ s/(\<SELECT[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>(.*?)\<\/SELECT\>/$begin$temp$end/si;
     $k = $temp;
     $v = html_parse_select_options($value,$v);
     substr($data,index($data,$k),length($k),$v);
 };#sie;

 return($data);
}

#########################################################################
# Parse one textarea filed
# PROTO: 
# $html = html_parse_textarea($name,$val,$html,$hash_ref);
#########################################################################
sub html_parse_textarea
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 my $data = $html;

 $html =~ s#(\<TEXTAREA[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>(.*?)(\<\/TEXTAREA\>)#do{
     my $begin = $1.$2.$3.$4.$5.$6.'>';
     if($hashref ne undef){$hashref->{$name} = $7;}
     my $end = $8;
     
     $data =~ s/(\<TEXTAREA[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>(.*?)\<\/TEXTAREA\>/$begin$value$end/si;
 };#sie;

 return($data);
}

#########################################################################
# Parse one input filed
# PROTO: 
# $html = html_parse_input($name,$val,$html,$hash_ref);
#########################################################################
sub html_parse_input
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 my ($uniq) = generate_unique_string($html);
 my $html_parser_counter = '0';
 my $data = $html;
 my $temp;
 my $k;
 my $v;
 my @k_t = ();
 my @v_t = ();

 $html =~ s#(\<INPUT[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>#do{
     $temp = $uniq.":".$html_parser_counter.":";
     $v = $1.$2.$3.$4.$5.$6;
     $data =~ s/(\<INPUT[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)$name(\ |\"|\')(.*?)\>/$temp/si;
     $k = $temp;
     if($v =~ m/(\<INPUT[^\<\>]*?)( TYPE\ {0,})([\=\ \"\']+)(checkbox|radio)(\ |\"|\')(.*)/si)
     {
      my $tv = $1.$2.$3.$4.$5.$6;
      $v = html_parse_remove_attribute('checked',$v);
      $tv = html_parse_remove_attribute('checked',$tv);
      if($v =~ m/(\<INPUT[^\<\>]*?)( VALUE\ {0,})([\=\ \"\'|]+)($value)(\ |\"|\'|)(.*)/si)
       {
        $tv .= ' checked>';
        push(@k_t,$k); push(@v_t,$tv);
       }
      else {$v .= '>';push(@k_t,$k); push(@v_t,$v);}
     }
     else
     {
      if($v =~ m/^(.*?)( VALUE\ {0,}\=)(.*)?$/si)
       {
        my $prev = $1.$2;
        my $l = $3;
        $l =~ s/^\ {0,}(\"|\'|)([^\'\"]+)?(\"|\'|)(.*)$/\"$value\"$4\>/si;
        if($hashref ne undef){$hashref->{$name} = $2;}
        $v = $prev.$l;
        if(!($v =~ m/\>\ {0,}$/)){$v .= '>';}
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
      else
       {
       	$v .= ' VALUE="'.$value.'">';
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
      }
     $html_parser_counter++;
 };#sieg;
        my $i;
        for ($i=0;$i<scalar(@k_t);$i++)
         {
          substr($data,index($data,$k_t[$i]),length($k_t[$i]),$v_t[$i]);
         }

 return($data);
}

#########################################################################
# Parse one <frame> tag
# PROTO: 
# $html = html_parse_frame($name,$val,$html,$hash_ref);
#########################################################################
sub html_parse_frame
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 my ($uniq) = generate_unique_string($html);
 my $html_parser_counter = '0';
 my $data = $html;
 my $temp;
 my $k;
 my $v;
 my @k_t = ();
 my @v_t = ();

 $html =~ s#(\<FRAME[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>#do{
     $temp = $uniq.":".$html_parser_counter.":";
     $v = $1.$2.$3.$4.$5.$6;
     $data =~ s/(\<FRAME[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)$name(\ |\"|\')(.*?)\>/$temp/si;
     $k = $temp;
      if($v =~ m/^(.*?)( SRC\ {0,}\=)(.*)?$/si)
       {
        my $prev = $1.$2;
        my $l = $3;
        $l =~ s/^\ {0,}(\"|\'|)([^\'\"]+)?(\"|\'|)(.*)$/\"$value\"$4\>/si;
        if($hashref ne undef){$hashref->{$name} = $2;}
        $v = $prev.$l;
        if(!($v =~ m/\>\ {0,}$/)){$v .= '>';}
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
      else
       {
       	$v .= ' SRC="'.$value.'">';
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
     $html_parser_counter++;
 };#sieg;
        my $i;
        for ($i=0;$i<scalar(@k_t);$i++)
         {
          substr($data,index($data,$k_t[$i]),length($k_t[$i]),$v_t[$i]);
         }

 return($data);
}

#########################################################################
# Parse one <img> tag
# PROTO: 
# $html = html_parse_img($name,$val,$html,$hash_ref);
#########################################################################
sub html_parse_img
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 my ($uniq) = generate_unique_string($html);
 my $html_parser_counter = '0';
 my $data = $html;
 my $temp;
 my $k;
 my $v;
 my @k_t = ();
 my @v_t = ();

 $html =~ s#(\<IMG[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>#do{
     $temp = $uniq.":".$html_parser_counter.":";
     $v = $1.$2.$3.$4.$5.$6;
     $data =~ s/(\<IMG[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)$name(\ |\"|\')(.*?)\>/$temp/si;
     $k = $temp;
      if($v =~ m/^(.*?)( SRC\ {0,}\=)(.*)?$/si)
       {
        my $prev = $1.$2;
        my $l = $3;
        $l =~ s/^\ {0,}(\"|\'|)([^\'\"]+)?(\"|\'|)(.*)$/\"$value\"$4\>/si;
        if($hashref ne undef){$hashref->{$name} = $2;}
        $v = $prev.$l;
        if(!($v =~ m/\>\ {0,}$/)){$v .= '>';}
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
      else
       {
       	$v .= ' SRC="'.$value.'">';
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
     $html_parser_counter++;
 };#sieg;
        my $i;
        for ($i=0;$i<scalar(@k_t);$i++)
         {
          substr($data,index($data,$k_t[$i]),length($k_t[$i]),$v_t[$i]);
         }

 return($data);
}

#########################################################################
# Parse one <A NAME=... HREF=...> tag
# PROTO: 
# $html = html_parse_link($name,$val,$html,$hash_ref);
#########################################################################
sub html_parse_link
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 my ($uniq) = generate_unique_string($html);
 my $html_parser_counter = '0';
 my $data = $html;
 my $temp;
 my $k;
 my $v;
 my @k_t = ();
 my @v_t = ();

 $html =~ s#(\<A[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>#do{
     $temp = $uniq.":".$html_parser_counter.":";
     $v = $1.$2.$3.$4.$5.$6;
     $data =~ s/(\<A[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)$name(\ |\"|\')(.*?)\>/$temp/si;
     $k = $temp;
      if($v =~ m/^(.*?)( HREF\ {0,}\=)(.*)?$/si)
       {
        my $prev = $1.$2;
        my $l = $3;
        $l =~ s/^\ {0,}(\"|\'|)([^\'\"]+)?(\"|\'|)(.*)$/\"$value\"$4\>/si;
        if($hashref ne undef){$hashref->{$name} = $2;}
        $v = $prev.$l;
        if(!($v =~ m/\>\ {0,}$/)){$v .= '>';}
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
      else
       {
       	$v .= ' HREF="'.$value.'">';
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
     $html_parser_counter++;
 };#sieg;
        my $i;
        for ($i=0;$i<scalar(@k_t);$i++)
         {
          substr($data,index($data,$k_t[$i]),length($k_t[$i]),$v_t[$i]);
         }

 return($data);
}

#########################################################################
# Parse one <META NAME=... CONTENT=...> tag
# PROTO: 
# $html = html_parse_meta($name,$val,$html,$hash_ref);
#########################################################################
sub html_parse_meta
{
 my ($name) = shift;
 my ($value) = shift;
 my ($html) = shift;
 my $hashref = ref($_[0]) ? shift : undef;
 my ($uniq) = generate_unique_string($html);
 my $html_parser_counter = '0';
 my $data = $html;
 my $temp;
 my $k;
 my $v;
 my @k_t = ();
 my @v_t = ();

 $html =~ s#(\<META[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)($name)(\ |\"|\')(.*?)\>#do{
     $temp = $uniq.":".$html_parser_counter.":";
     $v = $1.$2.$3.$4.$5.$6;
     $data =~ s/(\<META[^\<\>]*?)( NAME\ {0,})([\=\ \"\']+)$name(\ |\"|\')(.*?)\>/$temp/si;
     $k = $temp;
      if($v =~ m/^(.*?)( CONTENT\ {0,}\=)(.*)?$/si)
       {
        my $prev = $1.$2;
        my $l = $3;
        $l =~ s/^\ {0,}(\"|\'|)([^\'\"]+)?(\"|\'|)(.*)$/\"$value\"$4\>/si;
        if($hashref ne undef){$hashref->{$name} = $2;}
        $v = $prev.$l;
        if(!($v =~ m/\>\ {0,}$/)){$v .= '>';}
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
      else
       {
       	$v .= ' CONTENT="'.$value.'">';
        substr($data,index($data,$k),length($k),$v);
        return($data);
       }
     $html_parser_counter++;
 };#sieg;
        my $i;
        for ($i=0;$i<scalar(@k_t);$i++)
         {
          substr($data,index($data,$k_t[$i]),length($k_t[$i]),$v_t[$i]);
         }

 return($data);
}
#########################################################################
sub generate_unique_string
{
 my $body = shift;
 my $charset = 'QWERTYUIOPASDFGHJKLZXCVBNM_1234567890qwertyuiopasdfghjklzxcvbnm';
 my $start = '';
 my $i;
 while ($body =~ m/\<\=\_$start\_\=\>/s)
  {
   $start .= substr($charset,rand(length($charset)),1);
  }
 $start = '<=_'.$start.'_=>';
 return($start);
}
#########################################################################
sub html_parse_remove_attribute
{
 my ($tag,$v) = @_;
 my @backup = ();
 my @templ = ();
 my $copy = $v;
 $v =~ s/([\"\'][^\"]*?[\"\'])/do{
 my $uniq = generate_unique_string($copy);
 push(@backup,$1);
 push(@templ,$uniq);
 $copy =~ s!([\"\'][^\"]*?[\"\'])!$uniq!s;
 };/gse;
 $copy =~ s/\ $tag(\ |\>|)/$1/sgi;
 my $i;
 for($i=0;$i<scalar(@templ);$i++)
   {
    substr($copy,index($copy,$templ[$i]),length($templ[$i]),$backup[$i]);
   }
 return($copy);
}
#########################################################################
sub html_parse_select_options
{
 my ($value,$html) = @_;
 my $uniq = generate_unique_string($html);
 my $html_parser_counter = '0';
 my @k_t = ();
 my @all = ();
 my @vals = split(/\|/,$value);
 
 while($html =~ m/(\<OPTION[^\<\>]*?)(\>)([^\>\<]*)?(\<|)/si)
  {
   my $temp = $uniq.":".$html_parser_counter.":";
   my $v = $1.$2;
   my $val = $3;
   $v = html_parse_remove_attribute('selected',$v);
   my $k = $temp;
   push(@k_t,$k);
   $html =~ s/(\<OPTION[^\<\>]*?)(\>)([^\>\<]*?)(\<|)/$temp/si;
   my $flag = 0;
   foreach $value (@vals)
    {
     if($v =~ m/(\<OPTION[^\<\>]*?)( VALUE\ {0,})([\=\ \"\'|]+)($value)(\ |\"|\'|)(.*)\>/si)
       { 
        $v = $1.$2.$3.$4.$5.$6.' selected>';
        push(@all,$v);
        $flag = 1;
        last;
       }
    }
   if(!$flag) {push(@all,$v);}
   $html_parser_counter++;
  }
 my $i;
 for($i=0;$i<scalar(@k_t);$i++)
   {
    substr($html,index($html,$k_t[$i]),length($k_t[$i]),$all[$i]);
   }
 return($html);
}

1;