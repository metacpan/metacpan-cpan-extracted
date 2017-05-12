#################################################
# Author: Julian Lishev, All rights reserved!
# Helpers: Krasimir Krystev & Svetoslav Marinov
#################################################
# Subs: send_mail, mail, mx_lookup, mail_check
#       raw_mx_lookup, raw_dns_record_lookup
#       set_attached_files,
#       remove_mail_attachment,
#       clear_all_mail_attachments
#       get_mime_encoding
#       set_mime_encoding
# Prereqired modules:
#       MIME::Base64
#################################################
# send_mail(FROM,TO,SUBJECT,BODY,AS_HTML);
#################################################
# This version of "mail" is capable to fetch
# MX records, using UDP datagrams sent direct
# to DNS server.
#################################################

use Socket;
use IO::Socket;
use FileHandle;

open (STDERR,'>>/dev/null');

%mole_attached_files = ();  # Please use "set_mail_attachment" and "remove_mail_attachment"
                            # instead of direct manipulating of hash.
$webtools::mail_count_of_iterative_loops  = 5;
$webtools::mail_count_of_attempts_to_send = 2;
$webtools::loaded_functions = $webtools::loaded_functions | 64;

%sys_mime_encoding = ();
%sys_mail_original_names = ();

%sys_dns_mx_cache = ();
%sys_mail_bad_mx_hosts_cache = ();

my $sys_dns_lookup_respsize;
my $sys_dns_lookup_buf;
my $sys_dns_lookup_id = 0;
my $sys_mail_buf_size = 64*57;  # Must be multiple of 57!!!

sub send_mail 
  {
    local($from, $to, $subject, $messagebody, $is_html) = @_;
    my %inp = @_;
    my ($r1,$k1,$v1) = exists_insensetive('to',%inp);
    my ($r2,$k2,$v2) = exists_insensetive('from',%inp);
    my ($r3,$k3,$v3) = exists_insensetive('body',%inp);
    if($r1 and $r2 and $r3)  # Force new style (hash) for this function
     {
      $from = $v2 || die ':QUIT:send_mail() expects "FROM" field!';
      $to = $v1 || die ':QUIT:send_mail() expects "TO" field!';
      $messagebody = $v3;
      ($r2,$k2,$subject) = exists_insensetive('subject',%inp);
      ($r2,$k2,$is_html) = exists_insensetive('html',%inp);
     }
    local($fromuser, $fromsmtp, $touser, $tosmtp);
    my $crlf = $sys_CRLF;
    
    if(($is_html =~ m/^YES$/si) or ($is_html =~ m/^ON$/si) or ($is_html eq '1'))
      {
       $is_html = 1;
      }
    else {$is_html = 0;}
    
    if(!($to =~ m/^([A-Za-z0-9\_\-\.]+)\@([A-Za-z0-9\_\-\.]+)(?:\.)?([A-Za-z0-9\_\-\.]+)$/si))
      {
       return -1; # Bad e-mail address (or not supported from my regex)
      }
    if ($messagebody =~ /\<html\>/is) 
      {
       $is_html = 1; # Force HTML mode
      }
    if ($is_html)
      {
       if ($debug_mail ne 'on') 
         {
          $messagebody = safe_encode_qp($messagebody,$crlf);
         }
      }
    $fromuser = $from;
    $touser = $to;

    $fromsmtp = (split(/\@/,$from))[1];
    $tosmtp = (split(/\@/,$to))[1];
    
    if ($debug_mail ne 'on')
      {
       return(real_send_mail($fromuser, $touser, $subject, $messagebody, $is_html));
      }
    else
      { 
       if (!$is_html)
        {
         writeMailToFile($mailsender_path,'.sent',"FROM:".$fromuser."\n"."TO:".$touser."\n"."SUBJECT:".$subject."\n"."BODY:\n\n".$messagebody."\n");
        }
       else
        {
         writeMailToFile($mailsender_path,'.html.sent',"<HTML>FROM:".$fromuser."<BR>TO:".$touser."<BR>SUBJECT:".$subject."<BR>BODY:<BR><BR>".$messagebody."<BR><BR></HTML>");
        }
       %mole_attached_files = ();   # Attachments are now cleared
       return(1);    # In debug mode mail always successed!
     }
}

sub set_mail_attachment 
{
  my ($original_file_name,$server_file_name) = @_;
  $original_file_name =~ s/.*(\/|\\)(.*)$/$2/s;
  if($original_file_name eq '') {$original_file_name = 'webtools_upload_'.(rand()*1000);}
  $mole_attached_files{$original_file_name} = $server_file_name;
  $sys_mail_original_names{$original_file_name} = $original_file_name;
}

sub remove_mail_attachment 
{
  my ($original_file_name) = @_;
  delete($mole_attached_files{$original_file_name});
  delete($sys_mail_original_names{$original_file_name});
}

sub clear_all_mail_attachments
{
  %mole_attached_files = ();
  %sys_mime_encoding = ();
  %sys_mail_original_names = ();
}

sub real_send_mail 
{
  local($fromuser, $touser, $subject, $messagebody, $is_html) = @_;
    
  local($old_path) = $ENV{"PATH"};
  $ENV{"PATH"} = "";
  local *MAIL;
  open (MAIL, "|$mail_program") || return(-1);    # Can't open SendMail
  $ENV{"PATH"} = $old_path;
    
  my %MIMETYPES = ('zip','application/zip','exe','application/octet-stream','doc','application/msword',
                  'report','application/zip','mpga','audio/mpeg','mp3','audio/mpeg','gz','application/x-gzip',
                  'gzip','application/x-gzip','xls','application/vnd.ms-excel','pdf','application/pdf',
                  'swf','application/x-shockwave-flash','tar','application/x-tar','midi','audio/midi',
                  'mid','audio/midi','bmp','image/bmp','gif','image/gif','jpeg','image/jpeg','jpg','image/jpeg',
                  'jpe','image/jpeg','pgn','image/png','html','text/html','htm','text/html','mpeg','video/mpeg',
                  'mpg','video/mpeg','mpe','video/mpeg','avi','video/x-msvideo','movie','video/x-sgi-movie');
 
 eval 'use MIME::Base64;';
 if($@ ne '')
  {
   ClearBuffer(); ClearHeader(); flush_print();
   select(STDOUT);
   CORE::print '<B><font face="Verdana, Arial, Helvetica, sans-serif" size="2">';
   CORE::print "<font color='red'>Error: Sorry but you can't send e-mails till Perl module MIME::Base64 is not available!</font><BR>";
   CORE::print "Hint: Contact your administrator and ask for assistance<BR>";
   CORE::print '</font></B>';
   die ':QUIT:';
  }
 
 my $crlf = $sys_CRLF;
 my $boundary = "=_MZ8dd988d1d73016OQ104bWebTools050010191".(int(rand()*1000000000)+192837460)."PE";
 my $next_boundary = $crlf.'--'.$boundary.$crlf;
 my $last_boundary = $crlf.'--'.$boundary.'--'.$crlf;
 my $a_boundary = "=_ZM".(int(rand()*1000000000)+192837460)."0018104bd730WebTools0598dd16OQ8d10191"."EP";
 my $a_next_boundary = $crlf.'--'.$a_boundary.$crlf;
 my $a_last_boundary = $crlf.'--'.$a_boundary.'--'.$crlf;
 my $charset;
 my $html  = 'Message-ID: <'.(int(rand()*1000000000)+83649814).'.cae99500.2e0aa8c0@localhost>'.$crlf;
 if(!$is_html)
  {
   if($charset eq '') {$charset = 'Content-type: text/plain; charset=us-ascii';}
   if($charset ne '') {$html .= $charset.$crlf;}
  }
 else
  {
   if($charset eq '') {$charset = 'Content-type: text/html; charset=us-ascii';}
  }
 $html .= "From: ".$fromuser.$crlf;
 $html .= "To: ".$touser.$crlf;
 $html .= 'X-Priority: 2'.$crlf;
 $html .= 'X-MSMail-Priority: Normal'.$crlf;

 $html .= "Subject: ".$subject.$crlf;
 $html .= 'MIME-Version: 1.0'.$crlf;
 if(($is_html) or (%mole_attached_files))
   {
    #---------------------------------------------------------------------------
    $html .= 'Content-type: multipart/mixed; boundary="'.$boundary.'"';
    $html .= $crlf;
    $html .= 'This message is in MIME 1.0 format.';
    $html .= $crlf;
    $html .= $next_boundary;
    $html .= 'Content-type: multipart/alternative; boundary="'.$a_boundary.'"';
    $html .= $crlf;
    $html .= 'This alternative message is in MIME 1.0 format.';
    $html .= $crlf;
  if($messagebody ne '')
     {
       #------------------------------------------------------------------------
       $html .= $a_next_boundary;
       $html .= $charset.'; name="document.html"';
       $html .= $crlf;
       $html .= 'Content-Transfer-Encoding: quoted-printable';
       $html .= $crlf;
       $html .= $crlf;
       $html .= safe_encode_qp($messagebody,$crlf);
       $html .= $a_last_boundary;
       if(!(print (MAIL $html))){return(-1);} # -1 Can`t send to SendMail
       $html = '';
     }
 if (%mole_attached_files)
  {
   my ($file,$ext,$type);
   my $cnt = 0;
   my $data;
   foreach $file (keys %mole_attached_files)
   {
    local *ATTCH;
    open (ATTCH,$mole_attached_files{$file}) or next;
    binmode (ATTCH);
    if(($file =~ m/^.*\.(.*)$/s))
     {
      $ext = $1;
     }
    else 
     {
      $ext = '';
     }
    $type = $MIMETYPES{$ext};
 if (($type eq '') or ($ext eq '')) { $type = 'application/octet-stream'; }
    #-----------------------------------------------------------------------------
    $html .= $next_boundary;
    $html .= 'Content-type: '.$type.'; name="'.$file.'"';
    $html .= $crlf;
    $html .= 'Content-Transfer-Encoding: base64';
    $html .= $crlf;
    $html .= 'Content-Disposition: attachment; filename="'.$file.'"';
    $html .= $crlf;
    $html .= $crlf;
    while($data = <ATTCH>)
    {
    $html .= encode_base64($data,$crlf);
    if(!(print (MAIL $html))){return(-1);} # -1 Can`t send to SendMail
    $html = '';
    }
    close (ATTCH);
   }
  }
  #--------------------------------------------------------------------------------------------------------
  $html .= $last_boundary;
 }
 else
 {
 if($messagebody ne '')
  {
   $html .= $crlf.$messagebody;
  }
 }
 if(!(print (MAIL $html))){return(-1);} # -1 Can`t send to SendMail
    
 close (MAIL);
 %mole_attached_files = ();   # Attachments are now cleared.
 %sys_mime_encoding = ();
 %sys_mail_original_names = ();
 return(1);
}

sub web_error {
  my ($msg) = @_;
  
  ClearBuffer(); ClearHeader(); flush_print();
  
  print "<br><font color='red'><h3>";
  print "<p>$msg</p>\n";
  print "</h3></font>";
  
  die ':QUIT:';
}

sub find_mail_program{
  if ($debug_mail eq 'on'){ return 'MAIL_TEST'; }
  local @mailer = ($sendmail,'/usr/lib/sendmail','/usr/bin/sendmail','/usr/sbin/sendmail');
  local $flags  = "-t";
  local $st;
  foreach $st (@mailer){ if ( -e $st){return "$st $flags";}  }
  return("$sendmail $flags");
}


sub writeMailToFile
  {
    my ($temp_dir,$ext,$buffer) = @_;
    my $file_for_attach = '';
    
    foreach my $file (keys %mole_attached_files)
      {
      	$file =~ s/.*(\/|\\)(.*)$/$2/s;
      	$file_for_attach .= $file."\n";
      }
    my (undef,$file) = each (%mole_attached_files);

    $file =~ s/.*\/(.*)$/$1/; 
    if (!($temp_dir =~ /.*\/$/)) { $temp_dir .= '/';}
    # generation of a file name, in test mode usually :)
    my $rndf = rand()*1000;
    if($file ne '') {$rndf = '';}
    $webtools_gen_file_name = $temp_dir.'webtools_'.$rndf.$file.$ext;
    local *FILE;
    open    (FILE,">$webtools_gen_file_name") or return('');
    binmode (FILE);
    print   (FILE "$buffer");
    print   (FILE "\nAttachments: \n$file_for_attach");
    close   (FILE);

    return 1;            
  }

sub readAttach 
  {
    my $filename = shift(@_); 
    return '' if ($filename eq '');
    local $/ = undef;
    my $data;
    local *FILE;
    open (FILE,$filename) or return('');
    binmode (FILE);
    $data = <FILE>;    
    close (FILE);
    
    return $data;
  }
################################################
# This is a direct MAIL client
# It can send e-mails without external
# help software (like sendmail,host,nslookup)
################################################
sub mail
{
 my %input = @_;

 # Parse all TO,CC and BCC mails!
 # Note that CC and BCC fields are not visible
 # from recipient!
 my $cc  = $input{'cc'};
 my $bcc = $input{'bcc'};
 my $to = $input{'to'};
 my @all = ();
 my @results = ();
 my @mails = ();
 push(@mails,split(/\,/s,$to));
 push(@mails,split(/\,/s,$cc));
 push(@mails,split(/\,/s,$bcc));
 foreach $to (@mails)
  {
   $to =~ s/^\ {1,}//s;
   $to =~ s/\ {1,}$//s;
   if($to =~ m/\@/s)
    {
     push(@all,$to);
    }
  }
 delete $input{'to'};
 delete $input{'cc'};
 delete $input{'bcc'};
 
 my $from = $input{'from'};
 $from =~ s/^\ {1,}//s;
 $from =~ s/\ {1,}$//s;
 $input{'from'} = $from;
 
 my $replyto = $input{'replyto'};
 $replyto =~ s/^\ {1,}//s;
 $replyto =~ s/\ {1,}$//s;
 $input{'replyto'} = $replyto;
 
 # Send e-mails to all valid e-mail adresses
 foreach $to (@all)
 {
  my $sending_counter = 1;
  if ($to =~ m/^(.*?)\ {1,}(\d{1,})$/s) {$sending_counter = $2; $to = $1;}
  foreach (1..$sending_counter)
  {
  my $pure_to = $to;
  if($to =~ m/^(.*)\<(.*?)\>(.*)$/si)
   {
    $pure_to = $2;
   }
  $pure_to =~ m/\@(.*)$/s;
  if(exists($sys_mail_bad_mx_hosts_cache{$1}))  # Is this mail server in "bad" list?
    {push(@results,'-1'."\t".$to."\t"."FATAL:Can't resolve host (invalid email)"); next;}
  next_mail:{
  $input{'to'} = $to;
  my $iterative;
  my $last_error = 220;  # 220 - Sent OK
  my $last_data  = '';
  my $mcas;
  my %inp;
  my %backup = %mole_attached_files;
  my $mail__count_of_attempts_to_send = $inp{'counts'} || $mail_count_of_attempts_to_send;
  for($mcas=1;$mcas<=$mail__count_of_attempts_to_send;$mcas++)
   {
    %mole_attached_files = %backup;
    $iterative = 0;
    %inp = %input;
    while($iterative < $mail_count_of_iterative_loops)       # proceed next mail redirect?
     {
      my ($code,$data) = talk_to_smpt(%inp);
      if(($code eq '-1') and ($data =~ m/^FATAL\:(.*)$/si))  # Fatal error for this mail transaction!
       {
        push(@results,'-1'."\t".$input{'to'}."\t".$data);
        my $to = $input{'to'};
        my $pure_to = $to;
        if($to =~ m/^(.*)\<(.*?)\>(.*)$/si)
          {
           $pure_to = $2;
          }
        $pure_to =~ m/\@(.*)$/s;
        $sys_mail_bad_mx_hosts_cache{$1} = '1';     # Cache fall mail server...do not send mails
        next next_mail;                             # Try to send next mail...
       }
      if(($code == 251) or ($code == 551))
       {
        # Get e-mail and use it in next mail pass...
        $last_error = $code;
        $last_data  = $data;
        if($data =~ m/\<([A-Za-z0-9\_\-\.]+)\@([A-Za-z0-9\_\-\.]+)\.([A-Za-z0-9\_\-\.]+)?(\>|\;|\:|\ )/is)
          {
           $inp{'to'} = $1.'@'.$2.'.'.$3;
          }
        else
         {
          push(@results,'550'."\t".$input{'to'}."\t".$data); # Mail server reject this mail
          next next_mail;
         }
        $iterative++;
       }
      else
       {
        if($code != 220)
         {
          $last_error = $code;
          $last_data  = $data;
          $iterative = $webtools::mail_count_of_iterative_loops;
          if(($last_error == 550) or ($last_error == 552) or ($last_error == 553))
            {$mcas = $mail__count_of_attempts_to_send;} # In these cases don't wait!
          if($mcas == $mail__count_of_attempts_to_send)
           {
            push(@results,$last_error."\t".$input{'to'}."\t".$last_data);
           }
          next;
         }
         push(@results,$code."\t".$input{'to'}."\t".$last_data);
         next next_mail;
       }
      }
     }
    }
   }
  }
 return(@results);
}

sub talk_to_smpt
{
 my %inp = @_;
 my $crlf = $sys_CRLF;
 my ($timeout,$from,$to,$subject,$body,$replyto,$raw,$ns_lookup,$qfrom,$text,$dns,$check);
 my ($peer,$user,$ip,$data,$fdom,$html,$charset,$priority,$raw_from) = ();
 my @res = ();
 
 if(exists($inp{'timeout'})) {$timeout = $inp{'timeout'};}
 else {$timeout = 40;}

 if(exists($inp{'from'})) {$from = 'From: '.$inp{'from'}.$crlf; $qfrom = $inp{'from'};}
 else {$from = ''; $qfrom = '';}
 
 $raw_from = $inp{'from'};
 if($raw_from =~ m/^(.*)\<(.*?)\>(.*)$/si)
  {
   $raw_from = $2;
  }
  
 if(exists($inp{'check'})) {$check = $inp{'check'}; $check = $check=~m/^(Y|YES|1|ON|TRUE)$/si ? 1 : 0;}
 else {$check = 0;}
 
 if(exists($inp{'to'})) {$to = 'To: '.$inp{'to'}.$crlf;}
 else {return((-1,'FATAL:Empty TO'));}                                   # No receiver!
 
 if(exists($inp{'subject'})) {$subject = 'Subject: '.$inp{'subject'}.$crlf;}
 else {$subject = '';}
 
 if(exists($inp{'replyto'})) {$replyto = 'Reply-to: '.$inp{'replyto'}.$crlf;}
 else {$replyto = '';}
 
 if(exists($inp{'body'})) {$body = $inp{'body'};}
 else {$body = '';}
 
 if(exists($inp{'text'})) {$text = $inp{'text'};}
 else {$text = '';}
 
 if(exists($inp{'date'})) {$date = 'Date: '.$inp{'date'}.$crlf;}
 else {$date = 'Date: '.&mail_default_DATE().$crlf;}
 
 if(exists($inp{'raw'})) {$raw = $inp{'raw'};}
 else {$raw = '';}
 
 if(exists($inp{'nslookup'})) {$ns_lookup = $inp{'nslookup'};}
 else {$ns_lookup = '';}
 
 if(exists($inp{'dns'})) {$dns = $inp{'dns'};}
 else {$dns = '';}
 
 if(exists($inp{'charset'})) {$charset = $inp{'charset'};}
 else {$charset = '';}
 
 if(exists($inp{'priority'})) 
   {
    $priority = $inp{'priority'};
    if(($priority =~ m/HIGH/si) or ($priority eq 0)) {$priority = 0;}
    if(($priority =~ m/NORMAL/si) or ($priority eq 1)) {$priority = 1;}
    if(($priority =~ m/LOW/si) or ($priority eq 2)) {$priority = 2;}
   }
 else {$priority = 1;}
 
 if(exists($inp{'html'})) 
   {
    $html = $inp{'html'};
    if(($html == 1) or ($html =~ m/^YES$/si) or ($html =~ m/^ON$/si)) {$html = 1;}
    else {$html = 0;}
   }
 else {$html = 0;}
 
 my $pure_to = $inp{'to'};
 if($pure_to =~ m/^(.*)\<(.*?)\>(.*)$/si)
  {
   $pure_to = $2;
  }
 $pure_to =~ m/^([A-Za-z0-9\_\-\.]+)\@([A-Za-z0-9\_\-\.]+)\.([A-Za-z0-9\_\-\.]+)$/is;
 $peer = $2.'.'.$3;
 $user = $1;
 my $pure_from = $inp{'from'};
 if($pure_from =~ m/^(.*)\<(.*?)\>(.*)$/si)
  {
   $pure_from = $2;
  }
 $pure_from =~ m/^([A-Za-z0-9\_\-\.]+)\@([A-Za-z0-9\_\-\.]+)\.([A-Za-z0-9\_\-\.]+)$/is;
 $fdom  = $2.'.'.$3;
 
 my $proto = getprotobyname('tcp');
 local *Sock;
 my $port = 25;
 
 my $query = $peer;
 $query =~ s/^\ *//s;
 $query =~ s/\ *$//s;
 
 if($query =~ m/^\d{1,3}\./s)
  {
   my $inet_res = inet_aton($query);
   if($inet_res eq undef) {return((-1,"FATAL:Can't resolve host (invalid email)"));}
   $query = gethostbyaddr($inet_res, AF_INET);
   $query =~ s/^.*\.(.*)\.(.*)^/$1\.$2/s;
   my @host = split(/\./,$query);
   if($#host > 1) {$query = $host[-2].'.'.$host[-1];}
  }
 
 my @ips = ();
 if(exists($sys_dns_mx_cache{$query}))   # Lookup in temp cache
 {
  my $ptr = $sys_dns_mx_cache{$query};   # ...use found MX records
  @ips = @$ptr;
 }
else
 {
  @ips = mx_lookup($query,$ns_lookup,$dns); # fetch MX records
  if(scalar(@ips) == 0) {@ips = ("10\t".$peer);}
  elsif(($ips[0] == -1) or ($ips[0] == 0))
    {
      my @res = (0,"Can't connect to DNS server");                  # Can't connect to DNS server
      return(@res);
    }
  my @mxs = @ips;
  $sys_dns_mx_cache{$query} = \@mxs;     # Save in cache found records
 }

 my $flag_succ = 0;

 foreach $ip (@ips)
  {
   $ip =~ m/^\d{1,5}\t(.*?)$/s;
   $ip = $1;
   my $inet_res = inet_aton($ip);
   if($inet_res eq undef) {return((-1,"FATAL:Can't resolve host (invalid email)"));}
   my $sin = sockaddr_in($port,$inet_res);
   socket(Sock, AF_INET, SOCK_STREAM, $proto);
   $isconnected = connect(Sock,$sin);
   if ($isconnected)
     {					       # ?Mail server? not responding!?
      @res = ReadFromSocket(Sock,$timeout);
      if($res[0] == 220)
        {
         $flag_succ = 1;
         last;
        }
      close Sock;
     }
   else
    {
     @res = (0,"Can't connect to mail host");                            # Can't connect.
    }
  }
  if($flag_succ)
   {
    if(send(Sock,"HELO $fdom".$crlf,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
    @res = ReadFromSocket(Sock,$timeout);
    if($res[0] != 250) {return(($res[0],$res[1]));}

    if(send(Sock,"MAIL FROM:<$raw_from>".$crlf,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
    @res = ReadFromSocket(Sock,$timeout);
    if($res[0] != 250) {return(($res[0],$res[1]));}
    
    if(send(Sock,"RCPT TO:<$user\@$peer>".$crlf,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
    @res = ReadFromSocket(Sock,$timeout);
    if($res[0] != 250) {return(($res[0],$res[1]));}     # 251,551 (redirect) ?
    
    if($check == 0){

    if(send(Sock,"DATA".$crlf,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
    @res = ReadFromSocket(Sock,$timeout);
    if($res[0] != 354) {return(($res[0],$res[1]));}
    if($raw eq '')
     {
      mail_data('from'=>$from,'to'=>$to,'subject'=>$subject,'body'=>$body,'replyto'=>$replyto,
                'date'=>$date,'html'=>$html,'text'=>$text,'charset'=>$charset,'priority'=>$priority,
                'sock'=>Sock);
     }
    else
     {
      $data = $raw;      # $raw should contain all data that needed for DATA command to smpt!!!
                         # don't forget to put "CRLF.CRLF" sequence!
      if(send(Sock,$data,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
     }
    @res = ReadFromSocket(Sock,$timeout);
    if($res[0] != 250) {return(($res[0],$res[1]));}
    
    }
    if(send(Sock,"QUIT".$crlf.'.'.$crlf,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
    @res = ReadFromSocket(Sock,$timeout);
    if($res[0] != 221) {return(($res[0],$res[1]));}
    close (Sock);
    return((220,$res[1]));					   # OK, mail sent or user checked!
   }
  return(($res[0],$res[1]));
}

# @ips = mx_lookup($domain_or_ip, [$path_to_nslookup_or_to_host]);
# Windows like OS should use 'nslookup' but Unix like OS should use 'host'!
# If you haven't one of these programs, script will make raw query to DNS server.
sub mx_lookup
{
 my $result;
 my $domain = shift;
 my @digout;
 my $line;
 my @mxrecs = ();
 my $nslookup = $_[0] ne '' ? $_[0] : 'nslookup';
 my $host     = $_[0] ne '' ? $_[0] : 'host';
 if($_[1] ne '') {shift;}
 my $dns      = shift;
 my $qrt = $domain;
 $qrt =~ s/\./\\\./sig;
 $nslookup .= " -q=MX $domain";
 $host .= " -t MX $domain";

 if(!($dns =~ m/^[0-9\.\ \,]+$/)) {
 # Try to get MX recors through 'host' program
 $! = 0;
 @digout =  `$host`;
 if($! eq '')
  {
   foreach $line (@digout) 
     {
      if($line =~ m/^$qrt\.\ mail\ is\ handled\ by\ (\d{1,})\ (.*)\./si)
       {
        my $h = $2;
        my $prority = $1;
        if ($h =~ m/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/s)
          {
           $h = $1;
           push(@mxrecs,$prority."\t".$h);
          }
        else
          {
           $h =~ s/^[\ \t\r\n]*//s;
           $h =~ s/[\ \t\r\n]*$//s;
           (undef, undef, undef, undef, @addrs) = gethostbyname($h);
           if(scalar(@addrs) == 0) {next;}
           $h  = inet_ntoa($addrs[0]);
           push(@mxrecs,$prority."\t".$h);
          }
       }
     }
    if(scalar(@mxrecs) == 0) {return();} # Mail server is $peer!
   }
   
 if(scalar(@mxrecs) == 0) # If 'host' is not avalible or not work
 {
  $! = 0;
  @digout =  `$nslookup`;  # we must try 'nslookup'!
  if($! eq '')
   {
    foreach $line (@digout) 
     {
      if($line =~ m/^$qrt\x9(MX)?\ ?preference\ =\ (\d{1,5})\, mail\ exchanger\ =\ (.*?)$/si)
       {
        my $h = $3;
        my $prority = $2;
        if ($h =~ m/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/s)
         {
          $h = $1;
          push(@mxrecs,$prority."\t".$h);
         }
        else
         {
          $h =~ s/\.$//s;
          $h =~ s/^[\ \t\r\n]*//s;
          $h =~ s/[\ \t\r\n]*$//s;
          (undef, undef, undef, undef, @addrs) = gethostbyname($h);
          if(scalar(@addrs) == 0) {next;}
          $h  = inet_ntoa($addrs[0]);
          push(@mxrecs,$prority."\t".$h);
         }
       }
     }
    if(scalar(@mxrecs) == 0) {return();} # Mail server is $peer!
   }
  }
 }
 # Still can't find working software :))?
 if(scalar(@mxrecs) == 0) # If 'nslookup' and 'host' is not avalible
 {
  my @mx = raw_mx_lookup($domain,$dns);
  
  if(scalar(@mx) == 0) {return();}
  if(($mx[0] != -1) and ($mx[0] != 0)) {@mxrecs = @mx;}
 }
 return dns_sort_mx_records(@mxrecs);
}

# $code = ReadFromSocket(SOCK, $timeout);
sub ReadFromSocket
 {
   local (*Hand) = $_[0];
   my ($line,$l_line) = ();
   my $timeout = $_[1];
   my $rbits = "";
   my $done = 0;
   my $filehand;
   my $finish_time = time() + $timeout;
   while (!$done && $timeout > 0)          # Keep trying if we have time
      {
       $filehand = fileno(Hand);
       if($filehand eq undef) {return (0);} # Is still socket opened?
       vec($rbits, $filehand, 1) = 1;
       my $nfound = select($rbits, undef, undef, 0.5); # Wait for packet
       $timeout = $finish_time - time();   # Get remaining time
       if (!defined($nfound))              # Hmm, a strange error
        {
         return(0,'');
        }
       else
        {
          if($nfound <= 0)
           {
            if($timeout <= 0)
              {
               return (0);
              }
            else
              {
               next;
              }
           }
          # Done... data wait us.
          while ($line = <Hand>)
            {
             $l_line .= $line."<BR>";
             if ($line =~ m/\d{3} /) {last;};
            }
         $done = 0;
        }
       if (defined($line)) {last;}
      }    
    $l_line  =~ m/^(\d{3})/;
    return (($1,$l_line));
 }

sub mail_data
{
 my %inp = @_;
 my ($from,$to,$subject,$body,$replyto,$date,$is_html,$text,$charset,$priority);
 local *Hand = $inp{'sock'};
 $from = $inp{'from'};
 $to = $inp{'to'};
 $subject = $inp{'subject'};
 $body = $inp{'body'};
 $text = $inp{'text'};
 $date = $inp{'date'};
 $replyto = $inp{'replyto'};
 $is_html = $inp{'html'};
 $charset = $inp{'charset'};
 $priority = $inp{'priority'};
 my $priority_level = 'Normal';
 if($priority == 0) {$priority_level = 'High';}
 if($priority == 1) {$priority = 3;}
 if($priority == 2) {$priority_level = 'Low'; $priority = 5;}
 my %MIMETYPES = ('zip','application/zip','exe','application/octet-stream','doc','application/msword',
                  'report','application/zip','mpga','audio/mpeg','mp3','audio/mpeg','gz','application/x-gzip',
                  'gzip','application/x-gzip','xls','application/vnd.ms-excel','pdf','application/pdf',
                  'swf','application/x-shockwave-flash','tar','application/x-tar','midi','audio/midi',
                  'mid','audio/midi','bmp','image/bmp','gif','image/gif','jpeg','image/jpeg','jpg','image/jpeg',
                  'jpe','image/jpeg','pgn','image/png','html','text/html','htm','text/html','mpeg','video/mpeg',
                  'mpg','video/mpeg','mpe','video/mpeg','avi','video/x-msvideo','movie','video/x-sgi-movie');
 
 eval 'use MIME::Base64;';
 if($@ ne '')
  {
   ClearBuffer(); ClearHeader(); flush_print();
   select(STDOUT);
   CORE::print '<B><font face="Verdana, Arial, Helvetica, sans-serif" size="2">';
   CORE::print "<font color='red'>Error: Sorry but you can't send e-mails till Perl module MIME::Base64 is not available!</font><BR>";
   CORE::print "Hint: Contact your administrator and ask for assistance<BR>";
   CORE::print '</font></B>';
   die ':QUIT:';
  }

 my $crlf = $sys_CRLF;
 my $boundary = "=_MZ8dd988d1d73016OQ104bWebTools050010191".(int(rand()*1000000000)+192837460)."PE";
 my $next_boundary = $crlf.'--'.$boundary.$crlf;
 my $last_boundary = $crlf.'--'.$boundary.'--'.$crlf;
 my $a_boundary = "=_ZM".(int(rand()*1000000000)+192837460)."0018104bd730WebTools0598dd16OQ8d10191"."EP";
 my $a_next_boundary = $crlf.'--'.$a_boundary.$crlf;
 my $a_last_boundary = $crlf.'--'.$a_boundary.'--'.$crlf;

 my %sys_mail_format_types = 
  (
   'text'        => 'MESSAGE-ID,CHARSET,REPLYTO,FROM,TO,X-PRIORITY,X-MSMail-Priority,SUBJECT,DATE,'.
                  'USER-AGENT,MIME-VERSION,SIMPLE',
   'html'        => 'MESSAGE-ID,REPLYTO,FROM,TO,X-PRIORITY,X-MSMail-Priority,SUBJECT,DATE,'.
                  'USER-AGENT,MIME-VERSION,MULTYPART-ALTERNATIVE',
   'attachments' => 'MESSAGE-ID,REPLYTO,FROM,TO,X-PRIORITY,X-MSMail-Priority,SUBJECT,DATE,'.
                  'USER-AGENT,MIME-VERSION,MULTYPART-MIXED',
  );
  
 my %sys_mail_format_patterns = ();
 
 $sys_mail_format_patterns{'MESSAGE-ID'}  = 
      'Message-ID: <'.(int(rand()*1000000000)+83649814).'.cae99500.2e0aa8c0@localhost>';
      
 if(!$is_html)
  {
   if($charset eq '') 
     {
      $sys_mail_format_patterns{'CHARSET'}  = 'Content-type: text/plain; charset=us-ascii';
      $charset = $sys_mail_format_patterns{'CHARSET'};
     }
   if($charset ne '') 
     {
      $sys_mail_format_patterns{'CHARSET'}  = $charset;
     }
  }
 else
  {
   if($charset eq '') 
     {
      $sys_mail_format_patterns{'CHARSET'}  = 'Content-type: text/html; charset=us-ascii';
      $charset = $sys_mail_format_patterns{'CHARSET'};
     }
   if($charset ne '') 
     {
      $sys_mail_format_patterns{'CHARSET'}  = $charset;
     }
  }
 $sys_mail_format_patterns{'REPLYTO'} = $replyto;
 $sys_mail_format_patterns{'FROM'} = $from;
 $sys_mail_format_patterns{'TO'} = $to;
 $sys_mail_format_patterns{'X-PRIORITY'} = 'X-Priority: '.$priority;
 $sys_mail_format_patterns{'X-MSMail-Priority'} = 'X-MSMail-Priority: '.$priority_level;
 $sys_mail_format_patterns{'SUBJECT'} = $subject;
 $sys_mail_format_patterns{'DATE'} = $date;
 $sys_mail_format_patterns{'USER-AGENT'} = 'User-Agent: WebTools mail client';
 $sys_mail_format_patterns{'MIME-VERSION'} = 'MIME-Version: 1.0';
 if($is_html)
  {
   if(%mole_attached_files)
    {
     $sys_mail_format_patterns{'TYPE'} = $sys_mail_format_types{'attachments'};
    }
   else
    {
     $sys_mail_format_patterns{'TYPE'} = $sys_mail_format_types{'html'};
    }
  }
 else
  {
   $sys_mail_format_patterns{'TYPE'} = $sys_mail_format_types{'text'};
  }

 my $html =  '';
 my $field;
 
 my @sys_mail_fields = split(/\,/,$sys_mail_format_patterns{'TYPE'});
 foreach $field (@sys_mail_fields)
  {
   if($field =~ m/^MESSAGE\-ID$/i)
    {
     $html .= $sys_mail_format_patterns{'MESSAGE-ID'}.$crlf;
     next;
    }
   if($field =~ m/^CHARSET$/i)
    {
     if(!$is_html) {$html .= $sys_mail_format_patterns{'CHARSET'}.$crlf;}
     next;
    }
   if($field =~ m/^REPLYTO$/i)
    {
     $html .= $sys_mail_format_patterns{'REPLYTO'};
     next;
    }
   if($field =~ m/^FROM$/i)
    {
     $html .= $sys_mail_format_patterns{'FROM'};
     next;
    }
   if($field =~ m/^TO$/i)
    {
     $html .= $sys_mail_format_patterns{'TO'};
     next;
    }
   if($field =~ m/^X\-PRIORITY$/i)
    {
     $html .= $sys_mail_format_patterns{'X-PRIORITY'}.$crlf;
     next;
    }
   if($field =~ m/^X\-MSMail-Priority$/i)
    {
     $html .= $sys_mail_format_patterns{'X-MSMail-Priority'}.$crlf;
     next;
    }
   if($field =~ m/^SUBJECT$/i)
    {
     $html .= $sys_mail_format_patterns{'SUBJECT'};
     next;
    }
   if($field =~ m/^DATE$/i)
    {
     $html .= $sys_mail_format_patterns{'DATE'};
     next;
    }
   if($field =~ m/^USER\-AGENT$/i)
    {
     $html .= $sys_mail_format_patterns{'USER-AGENT'}.$crlf;
     next;
    }
   if($field =~ m/^MIME\-VERSION$/i)
    {
     $html .= $sys_mail_format_patterns{'MIME-VERSION'}.$crlf;
     next;
    }
   if($field =~ m/^MULTYPART\-MIXED$/i)
    {
     # ##############################################################################################
     # -------------------------------------- MULTYPART MIXED MAIL ----------------------------------
     # ##############################################################################################

     #---------------------------------------------------------------------------
     $html .= 'Content-type: multipart/mixed; boundary="'.$boundary.'"';
     $html .= $crlf;
     $html .= 'This message is in MIME 1.0 format.';
     $html .= $crlf;
     $html .= $next_boundary;
     $html .= 'Content-type: multipart/alternative; boundary="'.$a_boundary.'"';
     $html .= $crlf;
     $html .= 'This alternative message is in MIME 1.0 format.';
     $html .= $crlf;
     if($body ne '')
      {
       #------------------------------------------------------------------------
       $html .= $a_next_boundary;
       $html .= $charset.'; name="document.html"';
       $html .= $crlf;
       $html .= 'Content-Transfer-Encoding: quoted-printable';
       $html .= $crlf;
       $html .= $crlf;
       my $val = safe_encode_qp($body,$crlf);
       $html .= $val;
       if($text ne '')
        {
         #-------------------------------------------------------------------------
         $html .= $a_next_boundary;
         my $txt_charset = $charset;
         $txt_charset =~ s/text\/html/text\/plain/si;
         $html .= $txt_charset.'; name="document.txt"';
         $html .= $crlf;
         $html .= 'Content-Transfer-Encoding: quoted-printable';
         $html .= $crlf;
         $html .= $crlf;
         my $val = safe_encode_qp($text,$crlf);
         $html .= $val;
        }
       $html .= $a_last_boundary;
       if(send(Hand,$html,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
       $html = '';
       }
      else
       {
        #-------------------------------------------------------------------------
        $html .= $a_next_boundary;
        my $txt_charset = $charset;
        $txt_charset =~ s/text\/html/text\/plain/si;
        $html .= $txt_charset.'; name="document.txt"';
        $html .= $crlf;
        $html .= 'Content-Transfer-Encoding: quoted-printable';
        $html .= $crlf;
        $html .= $crlf;
        my $val = safe_encode_qp($text,$crlf);
        $html .= $val;
        $html .= $a_last_boundary;
        if(send(Hand,$html,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
        $html = '';
       }
     if (%mole_attached_files)
      {
       my ($file,$ext,$type);
       my $cnt = 0;
       my $data;
       foreach $file (keys %mole_attached_files)
       {
        local *ATTCH;
        open (ATTCH,$mole_attached_files{$file}) or next;
        binmode (ATTCH);
        if(($file =~ m/^.*\.(.*)$/s))
         {
          $ext = $1;
         }
        else 
         {
          $ext = '';
         }
        $type = $MIMETYPES{$ext};
     if (($type eq '') or ($ext eq '')) { $type = 'application/octet-stream'; }
        #-----------------------------------------------------------------------------
        $html .= $next_boundary;
        $html .= 'Content-type: '.$type.'; name="'.$file.'"';
        $html .= $crlf;
        my $sys_mime_encoding = $sys_mime_encoding{$file};
        if($sys_mime_encoding =~ m/^quoted\-printable$/si)
         {
          $html .= 'Content-Transfer-Encoding: quoted-printable';
         }
        if($sys_mime_encoding =~ m/^8bit$/si)
         {
          $html .= 'Content-Transfer-Encoding: 8bit';
         }
        if($sys_mime_encoding =~ m/^(base64|)$/si)
         {
          $html .= 'Content-Transfer-Encoding: base64';
         }
        $html .= $crlf;
        $html .= 'Content-Disposition: attachment; filename="'.$file.'"';
        $html .= $crlf;
        $html .= $crlf;
        my $bkp = $/;
        my $cnt = -s ATTCH;
        while($cnt > 0)
        {
          my $part = $cnt > $sys_mail_buf_size ? $sys_mail_buf_size : $cnt;
          $cnt -= $part;
          read(ATTCH,$data,$part);
          my $val;
          if($sys_mime_encoding =~ m/^quoted\-printable$/si) {$val = safe_encode_qp($data,$crlf);}
          if($sys_mime_encoding =~ m/^8bit$/si) {$val = $data; }
          if($sys_mime_encoding =~ m/^(base64|)$/si) {$val = encode_base64($data,$crlf);}
          $html .= $val;
          if(send(Hand,$html,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
          $html = '';
        }
        close (ATTCH);
       }
      }
      #--------------------------------------------------------------------------------------------------------
      $html .= $last_boundary;
      next;
    }
   if($field =~ m/^MULTYPART\-ALTERNATIVE$/i)
    {
     # ##############################################################################################
     # -------------------------------------- MULTYPART ALTERNATIVE MAIL ----------------------------
     # ##############################################################################################

     #---------------------------------------------------------------------------
     $html .= 'Content-type: multipart/alternative; boundary="'.$a_boundary.'"';
     $html .= $crlf;
     $html .= 'This message is in MIME 1.0 format.';
     $html .= $crlf;
     if($body ne '')
      {
       #------------------------------------------------------------------------
       $html .= $a_next_boundary;
       $html .= $charset;
       $html .= $crlf;
       $html .= 'Content-Transfer-Encoding: quoted-printable';
       $html .= $crlf;
       $html .= $crlf;
       my $val = safe_encode_qp($body,$crlf);
       $html .= $val;
       if($text ne '')
        {
         #-------------------------------------------------------------------------
         $html .= $a_next_boundary;
         my $txt_charset = $charset;
         $txt_charset =~ s/text\/html/text\/plain/si;
         $html .= $txt_charset;
         $html .= $crlf;
         $html .= 'Content-Transfer-Encoding: quoted-printable';
         $html .= $crlf;
         $html .= $crlf;
         my $val = safe_encode_qp($text,$crlf);
         $html .= $val;
        }
       $html .= $a_last_boundary;
       if(send(Hand,$html,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
       $html = '';
       }
      else
       {
        #-------------------------------------------------------------------------
        $html .= $a_next_boundary;
        my $txt_charset = $charset;
        $txt_charset =~ s/text\/html/text\/plain/si;
        $html .= $txt_charset;
        $html .= $crlf;
        $html .= 'Content-Transfer-Encoding: quoted-printable';
        $html .= $crlf;
        $html .= $crlf;
        my $val = safe_encode_qp($text,$crlf);
        $html .= $val;
        $html .= $a_last_boundary;
        if(send(Hand,$html,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
        $html = '';
       }
      next;
     }
   if($field =~ m/^SIMPLE$/i)
    {
     # ##############################################################################################
     # -------------------------------------- PLAIN TEXT --------------------------------------------
     # ##############################################################################################
     if($body ne '')
      {
       $body =~ s/\n/$crlf/sg;
       $html .= $crlf.$body;
      }
     else
      {
       $text =~ s/\n/$crlf/sg;
       $html .= $crlf.$text;
      }
     next;
    }
   }
 $html .= $crlf.'.'.$crlf;
 if(send(Hand,$html,0) eq undef){return((-1,"Can't sent to socket"));} # -1 Can`t send to socket
 %mole_attached_files = ();
 %sys_mime_encoding = ();
 %sys_mail_original_names = ();
 return(1);
}

############################################################
# RAW Lookup in DNS server for MX records
# returns sorted array of mail servers ordered by preference 
# Each line has follow format: "PREFERENCE\tMAIL_HOST"
# Example:
# ('5	mx1.mail.bg',
#  '10	ns.mail.bg')
# will return this query: raw_mx_lookup('mail.bg');
############################################################
sub raw_mx_lookup
{
 my $hostname = shift;
 my $dns      = shift || dns_nameserver();       # DNS Server
 my $line;
 my @mx_recs  = ();
 my @recs = &raw_dns_record_lookup($hostname,'MX',$dns);
 if(($recs[0] eq '0') or ($recs[0] == -1)) {return (@recs);}
 if(scalar(@recs) == 0) {return(@mx_recs);}
 foreach $line (@recs)
  {
   if($line =~ m/^MX\t(.*?)\t(.*)$/s) # Filter only MX records
    {
     push(@mx_recs,$1."\t".$2);       # ...and make required structure
    }
  }

 @mx_recs = dns_sort_mx_records(@mx_recs); # Sort found MX records
 return(@mx_recs);
}

##############################################################
# RAW Lookup in DNS server for:
# 'A','NS','CNAME','SOA','PTR','HINFO','MX' and 'ANY' records
# TYPE     MEANING (see RFC 1035)
# A        a host address
# NS       an authoritative name server
# CNAME    the canonical name for an alias
# SOA      marks the start of a zone of authority
# PTR      a domain name pointer
# HINFO    host information
# MX       mail exchange
# ANY      request for any known records
# PROTO: raw_dns_record_lookup($host[,$record_type,$nserver,
#                              $timeout]);
# return values:
# All queries can return array of lines with mixed RTypes,
# in follow format:
# Prototype for 'A' record:     "A\tIP_ADDRESS"
# Prototype for 'MX' record:    "MX\tPREFERENCE\tMAIL_HOST"
# Prototype for 'CNAME' record: "CNAME\tALIAS"
# Prototype for 'SOA' record:
# "SOA\tMNAME\tRNAME\tSERIAL\tREFRESH\tRETRY\tEXPIRE\tMINIMUM"
# Prototype for 'NS' record:    "NS\tNAME_HOST"
# Prototype for 'PTR' record:   "PTR\tPOINTER_HOST"
# Prototype for 'HINFO' record: "HINFO\tMACHINE\tOS"
# NOTE: Currently this function doesn't support DNS responeses
# larger than 512 bytes (due UDP packet size restriction)
##############################################################
sub raw_dns_record_lookup
{
 my $hostname = shift;
 my $r_type   = uc(shift) || 'A';
 my $dns      = shift || dns_nameserver();       # DNS Server
 my $timeout  = shift || 10;
 my $proto    = getprotobyname('udp');
 my $port     = getservbyname('domain', 'udp');  # Port 53
 my ($lformat,$question,$sock,$flag_recv,$rin,$rout,$s_timer,$e_timer);
 my $timer = 0;
 my $counter = 0;
 my $count    = 0;
 my @labels   = ();
 my @recs  = ();
 my %records  = (A=>1, NS=>2, CNAME=>5, SOA=>6, PTR=>12, HINFO=>13, MX=>15, ANY=>255);

 my $header = pack("n C2 n4",++$sys_dns_lookup_id,1,0,1,0,0,0);
 for(split(/\./,$hostname))
   {
    $lformat .= "C a* ";
    $labels[$count++]=length;
    $labels[$count++]=$_;
   }
 $question = pack($lformat."C n2",@labels,0,$records{$r_type},1);
 
 my @dns_ips = split(/\,/s,$dns);
 while(1)
  {
   if($counter > 360) {last;}
   foreach $dns (@dns_ips)
    {
     $dns =~ s/^\ {1,}//sg;
     $dns =~ s/\ {1,}$//sg;
     $sock = new IO::Socket::INET(PeerAddr=>$dns,PeerPort=>$port,Proto=>$proto,Timeout=>5);
     $flag_recv = 0;
     $s_timer = time();
     $sock->send($header.$question);
     $rin = '';
     vec($rin, fileno($sock), 1) = 1;
     while (select($rout = $rin, undef, undef, 5))
      {
       if(recv($sock, $sys_dns_lookup_buf, 512, 0)) {$flag_recv=1;last;}
      }
     close($sock);
     $e_timer = time();
     $timer += $e_timer - $s_timer;
     if(($timer > $timeout) and (!$flag_recv)) {return(-1);}
     if($flag_recv) {last;}
    }
   if($flag_recv) {last;}
   $counter++
  }
 if(!$flag_recv) {return(-1);}
 $sys_dns_lookup_respsize = length($sys_dns_lookup_buf);
 my ($id,$qr_opcode_aa_tc_rd,$rd_ra,
     $qdcount,$ancount,$nscount,$arcount) = unpack("n C2 n4",$sys_dns_lookup_buf);

 if(length($sys_dns_lookup_buf) == 0)
   {
    return(0);
   }
 if(!$ancount)
   {
    return(@recs); # Empty answare (no records available for requested host)!
   }
 
 my ($rname,$rtype,$rclass,$rttl,$rdlength);
 my ($position,$qname) = &dns_decompress_label(12); 
 my ($qtype,$qclass)   = unpack('@'.$position.'n2',$sys_dns_lookup_buf);
  
 $position += 4; 
 # Unpack all answare records
 @recs = ();
 for( ;$ancount;$ancount--)
    {
     ($position,$rname) = &dns_decompress_label($position);
     ($rtype,$rclass,$rttl,$rdlength) = unpack('@'.$position.'n2 N n',$sys_dns_lookup_buf);
     $position +=10;
     
     # All answares are with same structure but different records need
     # different parsing!

     # MX record parse
     if($rtype eq $records{'MX'})
      {
       # First 16bits are "preference"
       my $record = "MX\t";
       $record .= unpack("n1",substr($sys_dns_lookup_buf,$position,2));
       $position += 2;
       # Second n-bits are domain-name label
       $record .= "\t";
       ($new_pos,$rname) = &dns_decompress_label($position);
       $record .= $rname;
       $position -= 2;
       $position +=$rdlength;
       $record =~ s/\.$//s;
       push(@recs,$record);
      }
      
     # A record parse
     if($rtype eq $records{'A'})
      {
       # 32bits internet address
       push(@recs,"A\t".join('.',unpack('@'.$position.'C'.$rdlength,$sys_dns_lookup_buf)));
       $position +=$rdlength;
      }
      
     # CNAME record parse
     if($rtype eq $records{'CNAME'})
      {
       # Follow n-bits are domain-name label
       ($new_pos,$rname) = &dns_decompress_label($position);
       $record = "CNAME\t".$rname;
       $position +=$rdlength;
       $record =~ s/\.$//s;
       push(@recs,$record);
      }
      
     # NS record parse
     if($rtype eq $records{'NS'})
      {
       # Follow n-bits are domain-name label
       ($new_pos,$rname) = &dns_decompress_label($position);
       $record = "NS\t".$rname;
       $position +=$rdlength;
       $record =~ s/\.$//s;
       push(@recs,$record);
      }
    
     # PTR record parse
     if($rtype eq $records{'PTR'})
      {
       # Follow n-bits are domain-name label
       ($new_pos,$rname) = &dns_decompress_label($position);
       $record = "PTR\t".$rname;
       $position +=$rdlength;
       $record =~ s/\.$//s;
       push(@recs,$record);
      }
    
     # HINFO record parse
     if($rtype eq $records{'HINFO'})
      {
       my $bkp = $position;
       # First 8bits are length of string
       my $size = unpack('@'.$position."C1",$sys_dns_lookup_buf);
       $position += 1;
       # Followed by string
       my $record = unpack('@'.$position."a".$size,$sys_dns_lookup_buf)."\t";
       $position += $size;
       # Next 8bits are length of string
       $size = unpack('@'.$position."C1",$sys_dns_lookup_buf);
       $position += 1;
       # Followed by string
       $record .= unpack('@'.$position."a".$size,$sys_dns_lookup_buf);
       
       push(@recs,"HINFO\t".$record);
       $position = $bkp + $rdlength;
      }
     
     # SOA record parse
     if($rtype eq $records{'SOA'})
      {
       my $bkp = $position;
       ($position,$rname) = &dns_decompress_label($position);
       $rname =~ s/\.$//s;
       my $record = $rname;
       ($position,$rname) = &dns_decompress_label($position);
       $rname =~ s/\.$//s;
       $record .= "\t".$rname;
       $record .= "\t".unpack('@'.$position."N",$sys_dns_lookup_buf);
       $position += 4;
       $record .= "\t".unpack('@'.$position."N",$sys_dns_lookup_buf);
       $position += 4;
       $record .= "\t".unpack('@'.$position."N",$sys_dns_lookup_buf);
       $position += 4;
       $record .= "\t".unpack('@'.$position."N",$sys_dns_lookup_buf);
       $position += 4;
       $record .= "\t".unpack('@'.$position."N",$sys_dns_lookup_buf);
       push(@recs,"SOA\t".$record);
       $position = $bkp + $rdlength;
      }
    }
 return(@recs);
}

# "Unpack" one "label", relying on RFC 1035
sub dns_decompress_label
 { 
  my($start) = shift;
  my($domain,$i,$lenoct);
    
 for($i=$start;$i<=$sys_dns_lookup_respsize;)
    {
     $lenoct=unpack('@'.$i.'C', $sys_dns_lookup_buf);
     if(!$lenoct)
       {
        $i++;
	last;
       }
     if($lenoct == 192) 
       {
	$domain.=(&dns_decompress_label((unpack('@'.$i.'n',$sys_dns_lookup_buf) & 1023)))[1];
	$i+=2;
	last;
       }
     else
       {
	$domain.=unpack('@'.++$i.'a'.$lenoct,$sys_dns_lookup_buf).'.';
	$i += $lenoct;
       }
    }
 return($i,$domain);
}
# Sort found mx records on preference value
sub dns_sort_mx_records
{
 my @mxs = @_;
 my @res = ();
 my $i;
 foreach $i (@mxs)
  {
   $i =~ m/^(\d{1,})\t(.*)$/s;
   my $pref = int($1);
   my $host = $2;
   $pref = ('0' x (5 - length($pref))).$pref;
   push(@res,$pref."\t".$host);
  }
 @res = sort(@res);
 @mxs = ();
 foreach $i (@res)
  {
   $i =~ m/^(.*?)\t(.*)$/s;
   my $pref = int($1);
   my $host = $2;
   push(@mxs,$pref."\t".$host);
  }
 return(@mxs);
}


# Simple function for nameserver locating
sub dns_nameserver
{
 my $name = '/etc/resolv.conf';   # For Unix-like systems
 local * RESOLV;
 my $code;
 my @lines = ();
 my $line;
 my $nameserver = 'localhost';    # assume 'localhost' as default nameserver
 my $host;
 eval << 'TERM_CODE';
 use Sys::Hostname;
 $host = &Sys::Hostname::hostname(); # Get local host
 $nameserver = $host || 'localhost';
TERM_CODE
 my $host = $nameserver;
 
 if($^O =~ m/Win32/si)
  {
   my $dns_ips = mail_get_win32_NameServer();
   if($dns_ips != -1)
    {
     return($dns_ips);
    }
  }
 
 if(-e $name) # If resolv.conf is available
  {
   if(open(RESOLV,$name))
    {
     local $/ = undef;
     binmode RESOLV;
     $code = <RESOLV>;
     close RESOLV;
     $code =~ s/\r//sg;
     @lines = split(/\n/,$code);
    }
   foreach $line (@lines)
    {
     if($line =~ m/^([^\#]*?)nameserver\ {1,}(.*?)$/si) # Get all 'nameserver' lines
      {
       $nameserver = $2;
       $nameserver =~ s/^(.*?)\ (.*)$/$1/s; # Filter only nameserver
      }
    }
  }
 if(!($nameserver =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)) # If nameserver is not in "IP" format
  {
   my (undef, undef, undef, undef, @addrs) = gethostbyname($nameserver);
   if(scalar(@addrs) != 0)
    {
     $nameserver = inet_ntoa($addrs[0]);    # ...locate IP address via OS core functions
    }
  }

 return($nameserver); # Return found IP address (or your server IP)
}

sub mail_get_win32_NameServer
{
 my @dns_ips = ();
 my @results = ();
 my %uniq = ();
 my $entry;
 my $data;
 my $eval_code =<< 'Win32CODE';
 use Win32::TieRegistry( Delimiter=>"/", ArrayValues=>0 );
 my $data = $Registry->{"LMachine/SYSTEM/CurrentControlSet/Services/Tcpip/Parameters/NameServer"};
 if($data eq '')           # Win 2000/XP ?
  {
   my $diskKey = $Registry->{"LMachine/SYSTEM/CurrentControlSet/Services/Tcpip/Parameters/Interfaces"};
   if($diskKey)
    {
     foreach $entry (keys(%$diskKey))
      {
       $data = $Registry->{"LMachine/SYSTEM/CurrentControlSet/Services/Tcpip/Parameters/Interfaces/".$entry."NameServer"};
       if($data ne '') {push(@dns_ips,$data);}
      }
     }
  }
 else                     # NT 4
  {
   push(@dns_ips,$data);
  }
 foreach $entry (@dns_ips)
  {
   $entry =~ s/\,/\ /sg;
   $entry =~ s/\;/\ /sg;
   $entry =~ s/\ {2,}/\ /sg;
   my @ips = split(/\ /,$entry);
   my $ip;
   foreach $ip (@ips)
    {
     if($ip ne '')
      {
       if(!exists($uniq{$ip}))
        {
         push(@results,$ip);
        }
       else
        {
         $uniq{$ip} = 1;
        }
      }
    } 
  }
Win32CODE
 eval $eval_code;
 if($@ eq '')
  {
   return join(',',@results);
  }
 return(-1);
}

sub mail_default_DATE
{
 my $now_string = localtime;
 $now_string =~ m/^(.*?)\ {1,}(.*?)\ {1,}(.*?)\ {1,}(.*?)\ {1,}(.*?)$/s;
 my $weekDay = $1;
 my $month   = $2;
 my $mnthDay = $3;
 my $time    = $4;
 my $year    = $5;
 return($weekDay.', '.$mnthDay.' '.$month.' '.$year.' '.$time.' GMT');
}

sub set_mime_encoding
{
 my $file = shift;
 $file = $sys_mail_original_names{$file};
 $sys_mime_encoding{$file} = shift;
}

sub get_mime_encoding
{
 my $file = shift;
 $file = $sys_mail_original_names{$file};
 return($sys_mime_encoding{$file});
}

# Via this function you can encode in Quote Printable even binary files
sub safe_encode_qp
{
  my $data = shift;
  my $crlf = shift;
  $data =~ s/([^A-Za-z0-9\'\(\)\*\+\,\-\/\<\>\:\;\?\_])/sprintf("=%02X", ord($1))/seg;
  my $result = '';
  my $ptr = 0;
  my $len = length($data);
  while (1)
   {
    my $copy = substr($data,$ptr,75);
    my $cp = length($copy);
    if($cp == 0) {last;}
    if($cp > 72)
     {
      if($copy =~ m/^(.*)\=$/s) {$copy = $1; $cp-=1;}
      elsif($copy =~ m/^(.*)\=\w{1}$/s) {$copy = $1; $cp-=2;}
      elsif($copy =~ m/^(.*)\=\w{2}$/s) {$copy = $1; $cp-=3;}
     }
    $ptr += $cp;
    $result .= $copy.'='.$crlf;
   }
  return($result);
}

################################################
# Check validity of email. This check is not
# only lexical. This check is REAL. It try to
# simulate mail sending to this åmail!
# If server not exists or reject user, sub
# assume that user is invalid.
################################################
sub mail_check
{
 my %input = @_;
 $input{'check'} = 'YES';
 my $email = $input{'email'};
 delete $input{'email'};
 $input{'to'} = $email;
 my $username = rand();
 $username =~ s/[^0-9]//sg;
 $username =~ m/^(\d{1,4})/s;
 $username = 'user'.$1;
 # This email is provied only if you forgot to setup 'from' mail!
 # DON'T RUN SCRIPT WITH THIS E-MAIL!
 if($input{'from'} eq '') {$input{'from'} = $username.'@isc.org';}
 my @results = mail(%input);
 my @checked = ();
 my $r;
 foreach $r (@results)
  {
   $r =~ m/^(.*?)\t(.*?)\t(.*)$/s;
   my $code = $1;
   my $mail = $2;
   my $errm = $3;
   if($code == 220)
      {
       push(@checked,"$mail\t1");
      }
   else { push(@checked,"$mail\t0"); }
  }
 return(@checked);
}

$mail_program = find_mail_program();

return 1;