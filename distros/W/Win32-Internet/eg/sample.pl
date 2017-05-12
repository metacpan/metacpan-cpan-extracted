# TEST.PL for the Win32::Internet Package
# Version 0.08
# by Aldo Calpini (dada@perl.it)

use Win32::Internet;

print "\nWin32::Internet TEST\n\n";

$I = new Win32::Internet();
# [dada] technical info...
# print "I.handle=".$I->{'handle'}."\n";

($v_package, $v_dll) = $I->Version();

print "Package Version: $v_package\n";
#if($v_package ne "0.08") {
#    print "*** WARNING: Your Win32::Internet package is outdated!\n".
#          "    The latest version is 0.08.\n".
#          "    Please download and install Win32Internet-0.08.zip\n".
#          "    from: http://www.divinf.it/dada/perl/internet...\n\n";
#}

print "DLL Version: $v_dll\n";
#if($v_dll ne "4.70.1215") {
#    print "*** WARNING: Your WININET.DLL is outdated!\n".
#          "    The latest version is 4.70.1215.\n".
#          "    Please download and install WinInet.zip\n".
#          "    from: http://www.divinf.it/dada/perl/internet...\n\n";
#}

print "\n--- CONNECTION INFO --------------------\n";

$whoami = $I->UserAgent();

$I->ConnectTimeout(10000); # sets 10 seconds max timeout
$I->ConnectRetries(1);     # sets 1 retry

print "UserAgent: $whoami\n";
print "ConnectTimeout: ",        $I->ConnectTimeout(),        "\n";
print "ConnectRetries: ",        $I->ConnectRetries(),        "\n";
print "ConnectBackoff: ",        $I->ConnectBackoff(),        "\n";
print "DataSendTimeout: ",       $I->DataSendTimeout(),       "\n";
print "DataReceiveTimeout: ",    $I->DataReceiveTimeout(),    "\n";
print "ControlSendTimeout: ",    $I->ControlSendTimeout(),    "\n";
print "ControlReceiveTimeout: ", $I->ControlReceiveTimeout(), "\n";
print "----------------------------------------\n";


##############################################################################
# GENERIC URL FETCHER

# [dada] this works... 1MB on screen
# $file = $I->FetchURL("ftp://ftp.divinf.it/pub/perl/110-i86.zip");

$URL = "http://www.yahoo.com";

# [dada] for my LAN testing
# $URL = "http://intra.sisnet.it";

print "Fetching URL '$URL'...\n";
$file = $I->FetchURL($URL);
$err = $I->Error();
print "*** Error: $err\n" if !$file;
if($file) {
    print "    File is ".length($file)." bytes long.\n";
    # print "----------------------------------\n";
    # print $file;
    # print "----------------------------------\n";
}
print "\n";

# [dada] An alternative way is...
#
# $result = $I->OpenURL($U, $URL);
# $file = $U->ReadEntireFile();
# $U->Close();


##############################################################################
# FTP STUFF

$host = "ftp.activestate.com";
$user = "anonymous";
$pass = "libwin32\@automated-tests.com";

# [dada] for my LAN testing
# $host = "192.2.3.1";

print "Opening FTP connection to '$host' as '$user', '$pass'...\n";
$I->FTP($FTP, $host, $user, $pass);

if(!$FTP) {

    ($num, $text) = $I->Error();
    print "*** Error: [$num] $text\n";

} else {

    # print "    FTP.handle=" . $FTP->{'handle'} . "\n";

    print "    Pasvmode is:   ", $FTP->Pasv(), "\n";
    print "    Binamode is:   ", $FTP->Mode(), "\n";
    print "--- Server replied -----------------------\n";
    print $FTP->GetResponse();
    print "\n----------------------------------------\n";
    
    $path = $FTP->Pwd();
    $err = $FTP->Error();
    print "    Error: $err\n";
    print "    Current directory is '$path'\n" if ! $result;
    
    $dir = "/contrib";
    print "Trying 'cd $dir'...\n";
    $result = $FTP->Cd($dir);
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    $path = $FTP->Pwd();
    if($path) {
        print "    Current directory is '$path'\n";
    } else {
        $err=$FTP->Error();
        print "*** Error: $err\n";
    }

    print "    Trying 'ls *.*' (method 1)...\n";
    @files = $FTP->List("*.*");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! @files;
    print "    Found $#files files.\n";
    if($#files>0) {
        foreach $file (@files) {
            print $file." ";
        }
        print "\n";
    }    

    print "    Trying 'ls *.*' (method 2)...\n";
    @files = $FTP->List("*.*", 2);
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! @files;
    for($i = 0; $i <= $#files; $i += 7) {
        ($s, $m, $h, $D, $M, $Y) = split(",", $files[$i+6]);
        printf("%02d/%02d/%04d %02d:%02d:%02d ", $D, $M, $Y, $h, $m, $s);
        $size = $files[$i+2];
        printf("%12d ",$size);
        print $files[$i]."\n";
    }  

    print "    Trying 'ls *.*' (method 3)...\n";
    @files = $FTP->List("*.*", 3);
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! @files;

    print "    Found $#files files.\n";
    if($#files>0) {
        foreach $file (@files) {
            print "-------------------------\n";
            print "Name    = $file->{'name'}\n";
            print "Altname = $file->{'altname'}\n";
            print "Size    = $file->{'size'}\n";
            print "Attr    = $file->{'attr'} (";
            print join(" ",$FTP->FileAttrInfo($file->{'attr'}));
            print ")\n";
            print "Ctime   = ";
            ($s, $m, $h, $D, $M, $Y) = split(",", $file->{'ctime'});
            printf("%02d/%02d/%04d %02d:%02d:%02d\n", $D, $M, $Y, $h, $m, $s);
            print "Atime   = ";
            ($s, $m, $h, $D, $M, $Y) = split(",", $file->{'atime'});
            printf("%02d/%02d/%04d %02d:%02d:%02d\n", $D, $M, $Y, $h, $m, $s);
            print "Mtime   = ";
            ($s, $m, $h, $D, $M, $Y) = split(",", $file->{'mtime'});
            printf("%02d/%02d/%04d %02d:%02d:%02d\n",$D, $M, $Y, $h, $m, $s);
        }
    }

    print "    Setting ASCII mode...\n";
    $FTP->Ascii();
    print "    Mode is now ",$FTP->Mode(),"\n";

    print "    Setting BINARY mode...\n";
    $FTP->Binary();
    print "    Mode is now ",$FTP->Mode(),"\n";

    print "    Trying 'get dde.zip'...\n";
    $result = $FTP->Get("dde.zip","dde.zip");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    print "    Trying 'put test.pl'...\n";
    $result = $FTP->Put("test.pl","test.pl");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    print "    Trying 'mkdir internet_testing'...\n";
    $result = $FTP->Mkdir("internet_testing");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    print "    Trying 'rmdir internet_testing'...\n";
    $result = $FTP->Rmdir("internet_testing");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    print "    Trying 'ren test.pl test.xxx'...\n";
    $result = $FTP->Rename("test.pl", "test.xxx");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    print "    Trying 'del test.pl'...\n";
    $result = $FTP->Delete("test.pl");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    print "    Trying 'del test.xxx'...\n";
    $result = $FTP->Del("test.xxx");
    $err = $FTP->Error();
    print "*** Error: $err\n" if ! $result;

    $FTP->Close();
}

##############################################################################
# HTTP STUFF

exit; # 25Aug2000 Jan Dubois
# Dada's server is often unavailalble, so we skip these test for the time being

$host = "www.divinf.it";
$user = "anonymous";
$pass = "dada\@perl.it";

# for my LAN testing
# $host = "intra.sisnet.it";

print "Opening HTTP connection to '$host' as '$user', '$pass'...\n";
$I->HTTP($HTTP, $host, $user, $pass);

if(!$HTTP) {
    ($num, $text)=$I->Error();
    print "*** Error: [$num] $text\n";

} else {

    # print "    HTTP.handle=".$HTTP->{'handle'}."\n";

    print "Requesting for '/'...\n";
    ($statuscode, $headers, $file) = $HTTP->Request("/");
    print "    Status Code=$statuscode\n";
    print "--- Headers ------------------------------\n";
    print $headers;
    print "\n----------------------------------------\n";
    print "    File is ",length($file)," bytes long.\n";

    # Alternatively:

    print "\nRequesting for '/' (with headers control)...\n";
    ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime();
    $ifmod = sprintf(qq/%s, %02d-%s-%02d %02d:%02d:%02d GMT/,
                     ("Sunday", "Monday", "Tuesday", "Wednesday",
                      "Thursday", "Friday", "Saturday")[$wday],
                     $mday,
                     ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")[$mon],
                     $year,
                     $hour-1,
                     $min,
                     $sec);

    $result = $HTTP->OpenRequest($HREQ, "/");

    $result = $HREQ->AddHeader("If-Modified-Since: $ifmod\r\n");

    $result = $HREQ->SendRequest();

    $status = $HREQ->QueryInfo("",HTTP_QUERY_STATUS_CODE);
    print "    Status Code=$status\n";
    
    $agent = $HREQ->UserAgent();
    print "    Agent=$agent\n";

    $method = $HREQ->QueryInfo("",HTTP_QUERY_REQUEST_METHOD | HTTP_QUERY_FLAG_REQUEST_HEADERS);
    print "    Method=$method\n";

    $header = $HREQ->QueryInfo("",HTTP_QUERY_LAST_MODIFIED);
    # [dada] or: $header = $HREQ->QueryInfo("Last-Modified");
    print "    Last-Modified=$header\n";

    $header = $HREQ->QueryInfo("",HTTP_QUERY_SERVER);
    print "    Server=$header\n";

    $file = $HREQ->ReadEntireFile();

    print "    File is ",length($file)," bytes long.\n";
    $HREQ->Close();

}



##############################################################################
# EXITING

$host = "www.divinf.it";
$user = "anonymous";
$pass = "dada\@perl.it";

# [dada] for my LAN testing
# $host = "intra.sisnet.it";

$I->FTP($another, $host, $user, $pass); if($another) { ; }
$I->FTP($andanother, $host, $user, $pass); if($andanother) { ; }
$I->HTTP($andyetanother, $host, $user, $pass); if($andyetanother) { ; }

print "\nExiting with ", $I->Connections(), " open connections...\n";

# all connections left open will automatically be closed.
# if you don't trust me ;) use:
# $I->Close();



