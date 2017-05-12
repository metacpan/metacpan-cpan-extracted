my @cgi_lib_errors = ();

# 1  - Error: Request to receive too much data: $len bytes\n
# 2  - Error: Unknown request method: $meth\n
# 3  - Error: Boundary not provided(probably a bug in your server)
# 4  - Error: Invalid request method for  multipart/form-data($meth)\n
# 5  - Error: reached end of input while seeking boundary of multipart. Format of CGI input is wrong.\n
# 6  - Error: reached end of input while seeking end of headers. Format of CGI input is wrong.\n$buf
# 7  - Error: Could not open $fn<BR>Hint: Check your TMP directory!
# -1 - Unknown problem with input/output stream
# 8  - Error: Unknown Content-type (or you prohibit multipart forms)!\n

$cgi_lib_version = sprintf("%d.%02d", q$Revision: 2.18 $ =~ /(\d+)\.(\d+)/);

# Parameters affecting cgi-lib behavior
# User-configurable parameters affecting file upload.
$cgi_lib_writefiles =      0;    # directory to which to write files, or
                                 # 0 if files should not be written
$cgi_lib_filepre    = "webtools_cgi_lib"; # Prefix of file names, in directory above

# Do not change the following parameters unless you have special reasons
$cgi_lib_bufsize  =  8192;    # default buffer size when reading multipart
$cgi_lib_maxbound =   100;    # maximum boundary length to be encounterd
$cgi_lib_headerout =    0;    # indicates whether the header has been printed

# ReadParse
# Reads in GET or POST data, converts it to unescaped text, and puts
# key/value pairs in %in, using "\0" to separate multiple selections

# Returns >0 if there was input, 0 if there was no input 
# undef indicates some failure.

# Now that cgi scripts can be put in the normal file space, it is useful
# to combine both the form and the script in one place.  If no parameters
# are given (i.e., ReadParse returns FALSE), then a form could be output.

# If a reference to a hash is given, then the data will be stored in that
# hash, but the data from $in and @in will become inaccessable.
# If a variable-glob (e.g., *cgi_input) is the first parameter to ReadParse,
# information is stored there, rather than in $in, @in, and %in.
# Second, third, and fourth parameters fill associative arrays analagous to
# %in with data relevant to file uploads. 

# If no method is given, the script will process both command-line arguments
# of the form: name=value and any text that is in $ENV{'QUERY_STRING'}
# This is intended to aid debugging and may be changed in future releases

sub ReadParse {
  # Disable warnings as this code deliberately uses local and environment
  # variables which are preset to undef (i.e., not explicitly initialized)
  local ($perlwarn);
  $perlwarn = $^W;
  $^W = 0;
  $cgi_lib_writefiles = $webtools::tmp;
  local * FILE;
  $cgi_lib_writefiles =~ s/\/$//si;
  my $cgi_lib_maxd    = $webtools::cgi_lib_maxdata; # maximum bytes to accept via POST
  local (*in) = shift if @_;    # CGI input
  local (*incfn,                # Client's filename (may not be provided)
	 *inct,                 # Client's content-type (may not be provided)
	 *insfn,*in_ar) = @_;   # Server's filename (for spooled files)
  local ($len, $type, $meth, $errflag, $cmdflag, $got, $name);
  my $n = 0;	
  $in_ar = ();
  
  binmode(STDIN);   # we need these for DOS-based systems
  binmode(STDOUT);  # and they shouldn't hurt anything else 
  binmode(STDERR);
	
  # Get several useful env variables
  $type = $ENV{'CONTENT_TYPE'};
  $len  = $ENV{'CONTENT_LENGTH'};
  $meth = $ENV{'REQUEST_METHOD'};
  if(length($ENV{'QUERY_STRING'}) > $cgi_lib_maxd)
   {
    $cgi_lib_errors[0] = 1;
    return (@cgi_lib_errors);
    #&CgiDie("Error: Request to receive too much data: $len bytes\n");
   }
  my $in_get = '';
  # -----------------------------------------------------------------------
  # Check for valid request method
  # -----------------------------------------------------------------------
  if (!defined $meth || $meth eq '' || $meth eq 'GET' || $meth eq 'HEAD' ||
      $type eq 'application/x-www-form-urlencoded') 
   {
    local ($key, $val, $i);
    # Read in text
    
    if (!defined $meth || $meth eq '') 
     {
      $in = $ENV{'QUERY_STRING'};
      $cmdflag = 1;  # also use command-line options
     }
    elsif($meth eq 'GET' || $meth eq 'HEAD') 
      {
       $in = $ENV{'QUERY_STRING'};
      }
    elsif ($meth eq 'POST') 
      {
      if($len <= $cgi_lib_maxd)
       {
        if (($got = read(STDIN, $in, $len) != $len))
	 {
          $errflag="Short Read: wanted $len, got $got\n";
         }
       }
       else {$in = '';}
       $in_get = $ENV{'QUERY_STRING'};
      } 
     else
      {
       $cgi_lib_errors[0] = 2;
       return (@cgi_lib_errors);
       #&CgiDie("Error: Unknown request method: $meth\n");
      }      
     
     if(($in ne '') and ($in_get ne '')) {$in = $in.'&'.$in_get;}
     elsif ($in_get ne '') {$in = $in_get;}
    
     @in = split(/[&;]/,$in); 
     push(@in, @ARGV) if $cmdflag; # add command-line parameters

     foreach $i (0 .. $#in) 
      {
      # Convert plus to space
      $in[$i] =~ s/\+/ /g;

      # Split into key and value.  
      ($key, $val) = split(/=/,$in[$i],2); # splits on the first =.

      # Convert %XX from hex numbers to alphanumeric
      $key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
      $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;

      # Associate key and value
      $in{$key} .= "\0" if (defined($in{$key})); # \0 is the multiple separator
      $in{$key} .= $val;
      $in_ar[$n] = $key."\0".$val;
      $n++;
      }
  }elsif (($ENV{'CONTENT_TYPE'} =~ m#^multipart/form-data#) and ($webtools::cgi_lib_forbid_mulipart eq 'off')) {
    # for efficiency, compile multipart code only if needed
     $in = $ENV{'QUERY_STRING'};
     @in = split(/[&;]/,$in); 
     push(@in, @ARGV) if $cmdflag; # add command-line parameters

     foreach $i (0 .. $#in) 
      {
      # Convert plus to space
      $in[$i] =~ s/\+/ /g;

      # Split into key and value.  
      ($key, $val) = split(/=/,$in[$i],2); # splits on the first =.

      # Convert %XX from hex numbers to alphanumeric
      $key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
      $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;

      # Associate key and value
      $in{$key} .= "\0" if (defined($in{$key})); # \0 is the multiple separator
      $in{$key} .= $val;
      $in_ar[$n] = $key."\<\t\>".$val;
      $n++;
      }
   if($len > $cgi_lib_maxd)
       {
        $cgi_lib_errors[0] = -2;
        $^W = $perlwarn;
        return (@cgi_lib_errors);
        #&CgiDie("Error: Request to receive too much data: $len bytes\n");
       }
$errflag = !(eval <<'END_MULTIPART');

    local ($buf, $boundary, $head, @heads, $cd, $ct, $fname, $ctype, $blen);
    local ($bpos, $lpos, $left, $amt, $fn, $ser);
    local ($bufsize, $maxbound, $writefiles) = 
      ($cgi_lib_bufsize, $cgi_lib_maxbound, $cgi_lib_writefiles);


    # The following lines exist solely to eliminate spurious warning messages
    $buf = ''; 

    ($boundary) = $type =~ /boundary="([^"]+)"/; #";   # find boundary
    ($boundary) = $type =~ /boundary=(\S+)/ unless $boundary;
    do
     {
      $cgi_lib_errors[0] = 3;
      return (@cgi_lib_errors);
      #&CgiDie ("Error: Boundary not provided(probably a bug in your server)")
     } unless $boundary;
    $boundary =  "--" . $boundary;
    $blen = length ($boundary);

    if ($ENV{'REQUEST_METHOD'} ne 'POST') {
      $cgi_lib_errors[0] = 4;
      return (@cgi_lib_errors);
      #&CgiDie("Error: Invalid request method for  multipart/form-data($meth)\n");
    }

    if ($writefiles) {
      local($me);
      stat ($writefiles);
      $writefiles = "/tmp" unless  -d $writefiles && -w $writefiles;
      # ($me) = $0 =~ m#([^/]*)$#;
      $writefiles .= "/$cgi_lib_filepre"; 
    }

    # read in the data and split into parts:
    # put headers in @in and data in %in
    # General algorithm:
    #   There are two dividers: the border and the '\r\n\r\n' between
    # header and body.  Iterate between searching for these
    #   Retain a buffer of size(bufsize+maxbound); the latter part is
    # to ensure that dividers don't get lost by wrapping between two bufs
    #   Look for a divider in the current batch.  If not found, then
    # save all of bufsize, move the maxbound extra buffer to the front of
    # the buffer, and read in a new bufsize bytes.  If a divider is found,
    # save everything up to the divider.  Then empty the buffer of everything
    # up to the end of the divider.  Refill buffer to bufsize+maxbound
    #   Note slightly odd organization.  Code before BODY: really goes with
    # code following HEAD:, but is put first to 'pre-fill' buffers.  BODY:
    # is placed before HEAD: because we first need to discard any 'preface,'
    # which would be analagous to a body without a preceeding head.

    $left = $len;
   PART: # find each part of the multi-part while reading data
    while (1) {
      die (-1) if $errflag;

      $amt = ($left > $bufsize+$maxbound-length($buf) 
	      ?  $bufsize+$maxbound-length($buf): $left);
      $errflag = (($got = read(STDIN, $buf, $amt, length($buf))) != $amt);
      die (-1) if $errflag;
      $left -= $amt;

      $in{$name} .= "\0" if defined $in{$name}; 
      $in{$name} .= $fn if $fn;

      $name=~/([-\w]+)/;  # This allows $insfn{$name} to be untainted
      if (defined $1) {
        $insfn{$1} .= "\0" if defined $insfn{$1}; 
        $insfn{$1} .= $fn if $fn;
      }
 
     BODY: 
      while (($bpos = index($buf, $boundary)) == -1) {
        if ($left == 0 && $buf eq '') {
	  foreach $value (values %insfn) {
            unlink(split("\0",$value));
	  }
	  $cgi_lib_errors[0] = 5; die (5);
	  #&CgiDie("Error: reached end of input while seeking boundary " .
	  #	  "of multipart. Format of CGI input is wrong.\n");
        }
        die (-1) if $errflag;
        if ($name) {  # if no $name, then it's the prologue -- discard
          if ($fn) { print FILE substr($buf, 0, $bufsize); }
          else     { $in{$name} .= substr($buf, 0, $bufsize); }
        }
        $buf = substr($buf, $bufsize);
        $amt = ($left > $bufsize ? $bufsize : $left); #$maxbound==length($buf);
        $errflag = (($got = read(STDIN, $buf, $amt, length($buf))) != $amt);
        if($errflag) {eval 'close FILE;'; eval 'unlink $fn;';}
	die (-1) if $errflag;
        $left -= $amt;
      }
      if (defined $name) {  # if no $name, then it's the prologue -- discard
        if ($fn) { print FILE substr($buf, 0, $bpos-2); }
        else     { $in {$name} .= substr($buf, 0, $bpos-2); } # kill last \r\n
      }
      close (FILE);
      last PART if substr($buf, $bpos + $blen, 2) eq "--";
      substr($buf, 0, $bpos+$blen+2) = '';
      $amt = ($left > $bufsize+$maxbound-length($buf) 
	      ? $bufsize+$maxbound-length($buf) : $left);
      $errflag = (($got = read(STDIN, $buf, $amt, length($buf))) != $amt);
      if($errflag) {eval 'close FILE;'; eval 'unlink $fn;';}
      die (-1) if $errflag;
      $left -= $amt;


      undef $head;  undef $fn;
     HEAD:
      while (($lpos = index($buf, "\r\n\r\n")) == -1) { 
        if ($left == 0  && $buf eq '') {
	  foreach $value (values %insfn) {
            unlink(split("\0",$value));
	  }
	  $cgi_lib_errors[0] = 6; die(6);
	  #&CgiDie("Error: reached end of input while seeking end of " .
	  #	  "headers. Format of CGI input is wrong.\n$buf");
        }
        die (-1) if $errflag;
        $head .= substr($buf, 0, $bufsize);
        $buf = substr($buf, $bufsize);
        $amt = ($left > $bufsize ? $bufsize : $left); #$maxbound==length($buf);
        $errflag = (($got = read(STDIN, $buf, $amt, length($buf))) != $amt);
        if($errflag) {eval 'close FILE;'; eval 'unlink $fn;';}
        die (-1) if $errflag;
        $left -= $amt;
      }
      $head .= substr($buf, 0, $lpos+2);
      push (@in, $head);
      @heads = split("\r\n", $head);
      ($cd) = grep (/^\s*Content-Disposition:/i, @heads);
      ($ct) = grep (/^\s*Content-Type:/i, @heads);

      ($name) = $cd =~ /\bname="([^"]+)"/i; #"; 
      ($name) = $cd =~ /\bname=([^\s:;]+)/i unless defined $name;  

      ($fname) = $cd =~ /\bfilename="([^"]*)"/i; #"; # filename can be null-str
      ($fname) = $cd =~ /\bfilename=([^\s:;]+)/i unless defined $fname;
      $incfn{$name} .= (defined $in{$name} ? "\0" : "") . 
        (defined $fname ? $fname : "");

      ($ctype) = $ct =~ /^\s*Content-type:\s*"([^"]+)"/i;  #";
      ($ctype) = $ct =~ /^\s*Content-Type:\s*([^\s:;]+)/i unless defined $ctype;
      $inct{$name} .= (defined $in{$name} ? "\0" : "") . $ctype;

      if ($writefiles && defined $fname) {
        $ser++;
	$fn = $writefiles . ".$$.$ser";
	open (FILE, ">$fn") || do {
		$cgi_lib_errors[0] = 7; die (7);
	       };
        binmode (FILE);  # write files accurately
      }
      substr($buf, 0, $lpos+4) = '';
      undef $fname;
      undef $ctype;
    }

1;
END_MULTIPART
    if ($errflag) {
      local ($errmsg, $value);
      $errmsg = int($@) || '-1';
      foreach $value (values %insfn) {
        unlink(split("\0",$value));
      }
      $cgi_lib_errors[0] = $errmsg;
      return (@cgi_lib_errors);
      #&CgiDie($errmsg);
    } else {
      # everything's ok.
    }
  } else {
    $cgi_lib_errors[0] = 8;
    return (@cgi_lib_errors);
    #&CgiDie("Error: Unknown Content-type (or you prohibit multipart forms)!\n");
  }

  # no-ops to avoid warnings
  $insfn = $insfn;
  $incfn = $incfn;
  $inct  = $inct;

  $^W = $perlwarn;

  return ($errflag ? () :  @cgi_lib_errors); 
}


# PrintHeader
# Returns the magic line which tells WWW that we're an HTML document

sub PrintHeader {
  return "Content-type: text/html\n\n";
}


# HtmlTop
# Returns the <head> of a document and the beginning of the body
# with the title and a body <h1> header as specified by the parameter

sub HtmlTop
{
  local ($title) = @_;

  return <<END_OF_TEXT;
<html>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
END_OF_TEXT
}


# HtmlBot
# Returns the </body>, </html> codes for the bottom of every HTML page

sub HtmlBot
{
  return "</body>\n</html>\n";
}


# SplitParam
# Splits a multi-valued parameter into a list of the constituent parameters

sub SplitParam
{
  local ($param) = @_;
  local (@params) = split ("\0", $param);
  return (wantarray ? @params : $params[0]);
}


# MethGet
# Return true if this cgi call was using the GET request, false otherwise

sub MethGet {
  return (defined $ENV{'REQUEST_METHOD'} && $ENV{'REQUEST_METHOD'} eq "GET");
}


# MethPost
# Return true if this cgi call was using the POST request, false otherwise

sub MethPost {
  return (defined $ENV{'REQUEST_METHOD'} && $ENV{'REQUEST_METHOD'} eq "POST");
}


# MyBaseUrl
# Returns the base URL to the script (i.e., no extra path or query string)
sub MyBaseUrl {
  local ($ret, $perlwarn);
  $perlwarn = $^W; $^W = 0;
  $ret = 'http://' . $ENV{'SERVER_NAME'} .  
         ($ENV{'SERVER_PORT'} != 80 ? ":$ENV{'SERVER_PORT'}" : '') .
         $ENV{'SCRIPT_NAME'};
  $^W = $perlwarn;
  return $ret;
}


# MyFullUrl
# Returns the full URL to the script (i.e., with extra path or query string)
sub MyFullUrl {
  local ($ret, $perlwarn);
  $perlwarn = $^W; $^W = 0;
  $ret = 'http://' . $ENV{'SERVER_NAME'} .  
         ($ENV{'SERVER_PORT'} != 80 ? ":$ENV{'SERVER_PORT'}" : '') .
         $ENV{'SCRIPT_NAME'} . $ENV{'PATH_INFO'} .
         (length ($ENV{'QUERY_STRING'}) ? "?$ENV{'QUERY_STRING'}" : '');
  $^W = $perlwarn;
  return $ret;
}


# MyURL
# Returns the base URL to the script (i.e., no extra path or query string)
# This is obsolete and will be removed in later versions
sub MyURL  {
  return &MyBaseUrl;
}


# CgiError
# Prints out an error message which which containes appropriate headers,
# markup, etcetera.
# Parameters:
#  If no parameters, gives a generic error message
#  Otherwise, the first parameter will be the title and the rest will 
#  be given as different paragraphs of the body

sub CgiError {
  local (@msg) = @_;
  local ($i,$name);

  $cgi_lib_errors[0] = $msg[0];
  return (@cgi_lib_errors);
}


# CgiDie
# Identical to CgiError, but also quits with the passed error message.

sub CgiDie {
  local (@msg) = @_;
  &CgiError (@msg);
}


# PrintVariables
# Nicely formats variables.  Three calling options:
# A non-null associative array - prints the items in that array
# A type-glob - prints the items in the associated assoc array
# nothing - defaults to use %in
# Typical use: &PrintVariables()

sub PrintVariables {
  local (*in) = @_ if @_ == 1;
  local (%in) = @_ if @_ > 1;
  local ($out, $key, $output);

  $output =  "\n<dl compact>\n";
  foreach $key (sort keys(%in)) {
    foreach (split("\0", $in{$key})) {
      ($out = $_) =~ s/\n/<br>\n/g;
      $output .=  "<dt><b>$key</b>\n <dd>:<i>$out</i>:<br>\n";
    }
  }
  $output .=  "</dl>\n";

  return $output;
}

# PrintEnv
# Nicely formats all environment variables and returns HTML string
sub PrintEnv {
  &PrintVariables(*ENV);
}


1;