package OnSearch::Utils; 

#$Id: Utils.pm,v 1.16 2005/08/16 05:34:03 kiesling Exp $

use strict;
use warnings;
use Carp;
use Config;
use Socket;

my $VERSION='$Revision: 1.16 $';

use OnSearch;
use OnSearch::Base64;
use OnSearch::WebLog;

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT);
@ISA = qw(Exporter DynaLoader);
@EXPORT = (qw/http_unescape hex_to_char filetype document_urls 
              new_array_ref http_date str_in_list valid_lock
              basename sigwrapper run_onindex signumber
              client_write/);

my $logfunc = \&OnSearch::WebLog::clf;

sub http_unescape {
    my $uri = $_[0];
    my ($c, $j, $sp);
    $uri =~ s/\+/ /g;
    if ($uri =~ /\%/) {
	for ($j = 0; $j < length($uri); $j++) {
	    if (substr ($uri, $j, 1) eq '%') {
		$c = substr ($uri, $j+1, 2);
		$sp .= hex_to_char ($c);
		$j += 2;
	    } else {
		$sp .= substr ($uri, $j, 1);
	    }
	}
    } else {
	$sp = $uri;
    }
    return $sp;
}

sub hex_to_char {
    my $hexdigit = $_[0];
    my $hexchars = {  '0A' => ' ', '0D' => ' ', 
	          '20' => ' ', '21' => '!', '22' => '"', '23' => '#', 
		  '24' => '$', '25' => '%', '26' => '&', '27' => '\'',
                  '28' => '(', '29' => ')', '2A' => '*', '2B' => '+', 
                  '2C' => ',', '2D' => '-', '2E' => '.', '2F' => '/', 
                  '30' => '0', '31' => '1', '32' => '2', '33' => '3', 
                  '34' => '4', '35' => '5', '36' => '6', '37' => '7', 
                  '38' => '8', '39' => '9', '3A' => ':', '3B' => ';', 
                  '3C' => '<', '3D' => '=', '3E' => '>', '3F' => '?', 
                  '40' => '@', '41' => 'A', '42' => 'B', '43' => 'C', 
                  '44' => 'D', '45' => 'E', '46' => 'F', '47' => 'G', 
                  '48' => 'H', '49' => 'I', '4A' => 'J', '4B' => 'K', 
                  '4C' => 'L', '4D' => 'M', '4E' => 'N', '4F' => 'O', 
                  '50' => 'P', '51' => 'Q', '52' => 'R', '53' => 'S', 
                  '54' => 'T', '55' => 'U', '56' => 'V', '57' => 'W', 
                  '58' => 'X', '59' => 'Y', '5A' => 'Z', '5B' => '[', 
                  '5C' => '\\','5D' => ']', '5E' => '^', '5F' => '_', 
                  '60' => '`', '61' => 'a', '62' => 'b', '63' => 'c', 
                  '64' => 'd', '65' => 'e', '66' => 'f', '67' => 'g', 
                  '68' => 'h', '69' => 'i', '6A' => 'j', '6B' => 'k', 
                  '6C' => 'l', '6D' => 'm', '6E' => 'n', '6F' => 'o', 
                  '70' => 'p', '71' => 'q', '72' => 'r', '73' => 's', 
                  '74' => 't', '75' => 'u', '76' => 'v', '77' => 'w', 
                  '78' => 'x', '79' => 'y', '7A' => 'z', '7B' => '{', 
                  '7C' => '|', '7D' => '}', '7E' => '~',
### Note: These are rendered in X Window System fonts.
                  'C0' => 'À', 'C1' => 'Á', 'C2' => 'Â', 'C3' => 'Ã',
                  'C4' => 'Ä', 'C5' => 'Å', 'C6' => 'Æ', 'C7' => 'Ç',
                  'C8' => 'È', 'C9' => 'É', 'CA' => 'Ê', 'CB' => 'Ë',
		  'CC' => 'Ì', 'CD' => 'Í', 'CE' => 'Î', 'CF' => 'Ï',
                  'D0' => 'Ð', 'D1' => 'Ñ', 'D2' => 'Ò', 'D3' => 'Ó',
### Don't include multiplication sign.
                  'D4' => 'Ô', 'D5' => 'Õ', 'D6' => 'Ö', 
                  'D8' => 'Ø', 'D9' => 'Ù', 'DA' => 'Ú', 'DB' => 'Û',
                  'DC' => 'Ü', 'DD' => 'Ý', 'DE' => 'Þ', 
### This is the X Window rendering of small sharp s.
                  'DF' => 'ß',
                  'E0' => 'à', 'E1' => 'á', 'E2' => 'â', 'E3' => 'ã',
                  'E4' => 'â', 'E5' => 'å', 'E6' => 'æ', 'E7' => 'ç',
                  'E8' => 'è', 'E9' => 'é', 'EA' => 'ê', 'EB' => 'ë',
                  'EC' => 'ì', 'ED' => 'í', 'EE' => 'î', 'EF' => 'ï',
### Rendering of small eth.
                  'F0' => 'ð',
                               'F1' => 'ñ', 'F2' => 'ò', 'F3' => 'ó',
### Don't include division sign.
		  'F4' => 'ô', 'F5' => 'õ', 'F6' => 'ö', 
                  'F8' => 'ø', 'F9' => 'ù', 'FA' => 'ú', 'FB' => 'û',
                  'FC' => 'ü', 'FC' => 'ý',              'FE' => 'þ', 
                  'FF' => 'ÿ'}; 
   return $hexchars -> {$hexdigit};
}


sub new_array_ref { my @a; return \@a; }

###
###  If adding magic types, also add to OnSearch::VFile::vf_ftype
###
sub filetype {
    my $fname = $_[0];
    my $type = 'text/plain'; 
    my $buf;
    my $size = 1024;

    sysopen (F, $fname, 0) or return -1;  # O_RDONLY
    return undef unless sysread (F, $buf, $size); 

    if ($buf =~ /\<html/ism) { $type = 'text/html'; }
    if ($buf =~ /\<\?xml/ism) { $type = 'text/html'; }
    if ($buf =~ /^%!PS-Adobe/) { $type = 'application/postscript'; }
    if ($buf =~ /^%PDF-/) { $type = 'application/pdf'; }
    if ($buf =~ /^PK\003\004/) { $type = 'application/zip'; }
    if ($buf =~ /^\037\213/) { $type = 'application/x-gzip'; }
    if ($buf =~ /^GIF8/) { $type = 'image/gif'; }
    if ($buf =~ /^\211PNG/) { $type = 'image/png'; }
    if ($buf =~ /^\037\235/) { $type = 'application/compress'; }
    if ($buf =~ /^\312\376\272\276/) { $type = 'application/java-class'; }
    no warnings;
    if (substr ($buf, 6, 4) eq 'JFIF') { $type = 'image/jpeg'; }
    if (substr ($buf, 24, 22) eq 'outname=install.sfx.$$') 
    { $type = 'application/vnd.sun.pkg'; }
    use warnings;
    close F;
    return $type;
}

sub document_urls {
    my $doc = $_[0];
    my $base_url = $_[1];
    my ($subdoc, $url);
    my (%links, @sortedlinks, @uniqlinks);

    if ($doc =~ /<base\s*href/is) {
	($base_url) = ($doc =~ /<base\s*href\s*=\s*"(.*?)"/);
	($base_url) =~ s/(\w+:\/\/[^:\/]+).*/$1/;
    }

    my $regex = qr/href\s*?=\s*?"(.*?)["#] |
	           <frame\s*?src\s*?=\s*?"(.*?)["#] /imsx;

    $subdoc = $doc;
    while (length ($subdoc) &&   ($subdoc =~ $regex)) {
	$url = '';
	($url) = ($subdoc =~ $regex);
	$subdoc = $';
	# This leads to lots of warnings and bad matches if included
	# in $regex.
	next if ($url =~ /^\.+/) || ! length ($url);
	$url = "$base_url/$url" unless $url =~ /http\:/;
	$links{$url} = '' unless exists $links{$url};
    }
    @sortedlinks = sort (keys %links);

    return @sortedlinks;
}

my @months = (qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/);
my @wdays = (qw/Sun Mon Tue Wed Thu Fri Sat/);

sub http_date {
    my $adv_secs = $_[0];

    my $now = time();
    my $later = $now + $adv_secs;
    my @d_array = gmtime ($later);
    my $datestr = sprintf ("%s, %02d-%s-%d %02d:%02d:%02d GMT",
			   $wdays[$d_array[6]],  # weekday
			   $d_array[3],          # date
			   $months[$d_array[4]], # month
			   $d_array[5] + 1900,   # year
			   $d_array[2],          # hour
			   $d_array[1],          # min
			   $d_array[0]);         # sec

    return $datestr;
}

sub str_in_list {
    my $s = shift;
    my $listref = shift;
    my $match_case = shift;

    $s = lc $s unless $match_case;
    foreach my $l (@{$listref}) { 
	$l = lc $l unless $match_case; 
	return 1 if $l eq $s; 
    }
    return undef;
}

sub valid_lock {
    my $lockfn = shift;

    my ($l, $r, $lockfh);

    return undef unless (-f $lockfn);
    local $!;
    ###
    ### Suppress warnings about opening standard I/O channels
    ###
    no warnings;
    open $lockfh, "$lockfn" or warn "valid_lock $lockfn: $!";
    use warnings;
    while (defined ($l = <$lockfh>)) {
	chomp $l;
	$r = kill 0, $l;
	if (!$r) {
	    OnSearch::WebLog::clf ('notice', 
                "Removing stale lock $lockfn ID $l");
	      unlink $l;
	}
    }
    close ($lockfh);
    return $r;
}

sub basename {
    my $pathname = shift;

    my $basename;

    if ($pathname =~ /\\/) {
	$basename = substr ($pathname, rindex ($pathname, '\\') + 1);
    } elsif ($pathname =~ /\//) {
	$basename = substr ($pathname, rindex ($pathname, '/') + 1);
    } else {
	$basename = $pathname;
    }
    
    return $basename
}

sub sigwrapper {
    my ($signame, $sigsub, $wrapsub, @args) = @_;
    
    my $oldsig = $SIG{$signame} if $SIG{$signame}; 
    $SIG{$signame} = ($sigsub ? $sigsub : 'IGNORE');
    &$wrapsub (@args);
    $SIG{$signame} = $oldsig if $oldsig;
}

###
### TO DO - this so far is the most reliable way to index
### immediately.  Try to clean up this implementation.
###
sub run_onindex {
    my $txt = `/usr/local/etc/init.d/onindex index`;
    OnSearch::WebLog::clf ('notice', "Onindex: $txt");
}

sub signumber {
    my $signame = $_[0];
    my (%sigs, $number, $name);
    $number = 0;
    foreach $name (split (' ', $Config{sig_name})) {
	$sigs{$name} = $number++;
    }
    return $sigs{$signame};
}

sub client_write {
    my $session_id = shift;
    my $buf = shift;
    my ($name, $clientfh, $serverfh);
    $name = '/tmp/.onsearch.sock.' . $session_id;
    socket ($serverfh, PF_UNIX, SOCK_STREAM, 0) || 
	die "OnSearch: client_write socket: $!";
    if (-S $name && ! unlink ($name)) {	
	&$logfunc ('error', "client_write unlink: $!\n"); 
      }
    bind ($serverfh, sockaddr_un($name)) || 
	warn ("client_write bind: $!."); 
    listen ($serverfh, SOMAXCONN) || 
	warn ("client_write listen: $!."); 
    accept ($clientfh, $serverfh) ||
	warn ("client_write $$ accept: $!."); 
    if (fileno ($clientfh)) {
	syswrite ($clientfh, $buf);
	close $clientfh;
	close $serverfh;
    }
    return;
}

1;
