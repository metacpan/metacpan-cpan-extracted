package WWW::Promotion;

=head1 NAME

C<WWW::Promotion> - WWW::Promotion is a Perl module that allow to submit
your site to lot of search engines.

=head1 DESCRIPTION

WWW::Promotion is used to submit your site to lot of search engines. It is 
possible to download SPT5 interface for WWW::Promotion at 
http://www.tapor.com/promotion/. Also on http://www.tapor.com/promotion/ your 
may find huge database of search engines. WWW::Promotion is 
world wide standart for promoting websites. 

=cut

##############################################################################
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %Promotion %Setup @internal_promotion_categories $outputhandler);

require Exporter;

use TAPORlib 8.70;

@ISA = qw(Exporter);
@EXPORT = qw(&WWW_Promotion
	     @internal_promotion_categories
	     );
@EXPORT_OK = qw();

$VERSION = "5.20";

##############################################################################

=head1 IMPORTED FUNCTIONS/VARS

=head1

=head2 @internal_promotion_categories

 Description:
 
 Array of internal categories, which can you use to promote your website. 
 If you will use other category WWW::Promotion will return an error.

=cut  

@internal_promotion_categories = (

"Art",
"Internet",
"Bussiness",
"Entertainment",
"Other",

);

##############################################################################

=head2 %out=&WWW_Promotion(\%Promotion,\%Setup);

 Description:
 
 This function used to promote your website.

 Usage:

 #---------------------------------------------------------------------
 # Required fields. If this fields not passed, module will not continue.
 #---------------------------------------------------------------------
 $Promotion{'title'}       = "Super Page";
 $Promotion{'url'}         = "http://www.url.com";
 $Promotion{'description'} = "Blah-Blah this page is";
 
 # In this feild you may use only internal categories of WWW::Promotion.
 # See &GetInternalPromotionCategories() procedure.
 $Promotion{'category'}    = "Other";

 #---------------------------------------------------------------------
 # Not required fields. If this fields not passed, defaults will be used.
 #---------------------------------------------------------------------
 # Default: $Promotion{'description'} with words separated by ", "
 $Promotion{'keywords'}    = "Blah-Blah, this, page, is";

 # Default: $Promotion{'description'} 
 $Promotion{'comments'}    = "Blah-Blah this page is";

 # Default "Mr."
 $Promotion{'nametitle'}   = "Mr.";

 # Default: "John"
 $Promotion{'firstname'}   = "John";

 # Default: "Doe"
 $Promotion{'lastname'}    = "Doe";

 # Default: "W."
 $Promotion{'middlename'}  = "W.";

 # Default: "$Promotion{'firstname'} $Promotion{'lastname'}"
 $Promotion{'contactname'} = "John Doe";

 # Default: Random generated email address with domain "@mail.com"
 $Promotion{'email'}       = "blah-blah\@mail.com";

 # Default: "123 Baltimor Street 5"
 $Promotion{'address'}     = "123 Baltimor Street 5";

 # Default: "Boston"
 $Promotion{'city'}        = "Boston";

 # Default: "MA"
 $Promotion{'state'}       = "MA";

 # Default: "United States of America"
 $Promotion{'country'}     = "United States of America";

 # Default: "US"
 $Promotion{'countrycode'} = "US";

 # Default: "46723"
 $Promotion{'zip'}         = "46723";

 # Default: "At Home"
 $Promotion{'company'}     = "At Home";

 # Default: Random generated phone.
 $Promotion{'phone'}       = "1-234-567-8911";

 # Default: Random generated fax.
 $Promotion{'fax'}         = "1-234-567-8911";

 # Default: Random generated string with six chars.
 $Promotion{'password'}    = "password";

 # Default: "English"
 $Promotion{'language'}    = "English";

 # WWW::Promotion will use this file to print what it doing.
 # Default: "/dev/null"
 $Setup{'logfile'} = "/dev/null";

 # Whitch proxy server module must use to connect to servers.
 # If not spicified that SP5 will connect direct.
 $Setup{'proxy'}  = "blah-blah.com:8080";

 # FASTMODE PROMOTION [tm]
 # Does WWW::Promotion use fastmode ?
 # 1  - yes
 # 0  - no
 # p.s: FASTMODE PROMOTION [tm] may be done only via proxy server.
 #      If executed without $Setup{'proxy'} module will exit with error.
 # Default: 0
 $Setup{'fastmode'} = 1;

 # Timeout to connect to server.
 # Default: 10
 $Setup{'timeoutconnect'} = 10;

 # Timeout to wait answer from server.
 # Default: 60
 $Setup{'timeoutrequest'} = 60;

 # You may provide three directories that contains search engines.
 # See "Search engine database" part of this document for more info about.
 $Setup{'enginesdir1'} = "./ENGINES1";
 $Setup{'enginesdir2'} = "./ENGINES2";
 $Setup{'enginesdir3'} = "./ENGINES3";

 # Output handler. 
 # See "Output handler" part of this document for more info about.
 $Setup{'outputhandler'}  = \&OutputHandler;

 # Final action
 # Execute Promotion
 %out=WWW_Promotion(\%Promotion,\%Setup);
 
 Output:

 $out{'error'}
 TRUE if error, then $out{'errortxt'} contains error description. 

=cut  

sub WWW_Promotion {
    my ($LPromotion,$LSetup) = @_;
    
    %Promotion = %$LPromotion;
    %Setup = %$LSetup;
    
    my %out;

    if(!$Setup{'logfile'}) {$Setup{'logfile'} = "/dev/null";}
    my $logfile = $Setup{'logfile'};

    #-------------------------------------------------------------------------
    add_string_to_file($logfile,"WWW::Promotion: v$VERSION\n\n");
    #------------------------- Checking input data ---------------------------
    if(!$Promotion{'title'})
	{
	$out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","\$Promotion{'title'} must be passed");
	goto print_error_to_log_and_exit;
	}
    if(!$Promotion{'url'})
	{
	$out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","\$Promotion{'url'} must be passed");
	goto print_error_to_log_and_exit;
	}
    if(!($Promotion{'url'} =~ m/^http:\/\//i))
	{
	$out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","Invalid url '$Promotion{'url'}'");
	goto print_error_to_log_and_exit;
	}
    if(!$Promotion{'description'})
	{
	$out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","\$Promotion{'description'} must be passed");
	goto print_error_to_log_and_exit;
	}
    if(!$Promotion{'category'})	
	{
	$out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","\$Promotion{'category'} must be passed");
	goto print_error_to_log_and_exit;
	}
    else
	{
        my $ok=0;
	foreach (@internal_promotion_categories)
	    {
	    if($_ eq $Promotion{'category'})
		{
		$ok=1;
		last;
		}
	    }
	if(!$ok)
	    {
            $out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","\$Promotion{'category'} has invalid internal category");
            goto print_error_to_log_and_exit;
	    }
	}
    my $internalcategory = $Promotion{'category'};
    
    if(defined($Setup{'fastmode'}) && !defined($Setup{'proxy'}))
	{
        $out{'errortxt'} = create_error_string("WWW::Promotion::WWW_Promotion()","FASTMODE [tm] may be done only via proxy - \$Setup{'proxy'}!");
	goto print_error_to_log_and_exit;
	}
    #-------------------------------- Defaults -------------------------------
    if($Setup{'outputhandler'})
	{
	$outputhandler = $Setup{'outputhandler'};
	}
    
    if(!$Promotion{'keywords'})
	{
	my @keywords = split(/ /,$Promotion{'description'});
	$Promotion{'keywords'} = join(',',@keywords);
	}
    if(!$Promotion{'comments'})
	{
	$Promotion{'comments'} = $Promotion{'description'};
	}
    if(!$Promotion{'nametitle'})
	{
	$Promotion{'nametitle'} = "Mr.";
	}
    if(!$Promotion{'firstname'})
	{
	$Promotion{'firstname'} = "John";
	}
    if(!$Promotion{'lastname'})
	{
	$Promotion{'lastname'} = "Doe";
	}
    if(!$Promotion{'middlename'})
	{
	$Promotion{'middlename'} = "W.";
	}
    if(!$Promotion{'contactname'})
	{
	$Promotion{'contactname'} = "$Promotion{'firstname'} $Promotion{'lastname'}";
	}
    if(!$Promotion{'email'})
	{
	$Promotion{'email'} = GenerateRandomString(5);
	$Promotion{'email'} = $Promotion{'email'}  . "\@mail.com";
	}
    if(!$Promotion{'address'})
	{
	$Promotion{'address'}     = "123 Baltimor Street 5";
	}
    if(!$Promotion{'city'})
	{
	$Promotion{'city'}        = "Boston";
	}
    if(!$Promotion{'state'})
	{
	$Promotion{'state'}       = "MA";
	}
    if(!$Promotion{'country'})
	{
	$Promotion{'country'}     = "United States of America";
	}
    if(!$Promotion{'countrycode'})
	{
	$Promotion{'countrycode'} = "US";
	}
    if(!$Promotion{'zip'})
	{
	$Promotion{'zip'}         = "46723";
	}
    if(!$Promotion{'company'})
	{
	$Promotion{'company'}     = "At Home";
	}
    if(!$Promotion{'phone'})
	{
	$Promotion{'phone'} = "1-" . int(rand(9)) . int(rand(9)) . int(rand(9)) . "-". int(rand(9)) . int(rand(9)) . int(rand(9)) . "-" . int(rand(9)) . int(rand(9)) . int(rand(9)) . int(rand(9));
	}
    if(!$Promotion{'fax'})
	{
	$Promotion{'fax'} = "1-" . int(rand(9)) . int(rand(9)) . int(rand(9)) . "-". int(rand(9)) . int(rand(9)) . int(rand(9)) . "-" . int(rand(9)) . int(rand(9)) . int(rand(9)) . int(rand(9));
	}
    if(!$Promotion{'password'})
	{
	$Promotion{'password'}    = GenerateRandomString(6);
	}
    if(!$Promotion{'language'})
	{
	$Promotion{'language'}    = "English";
	}
    if(!$Promotion{'url-without-http'})
	{
	$Promotion{'url-without-http'} = $Promotion{'url'};
	$Promotion{'url-without-http'} =~ s/^http:\/\///i;
	}
    if(!$Promotion{'street'})
	{
	$Promotion{'street'} = $Promotion{'address'};
	}

    if(!$Setup{'timeoutconnect'}) {$Setup{'timeoutconnect'} = 10;}
    if(!$Setup{'timeoutrequest'}) {$Setup{'timeoutrequest'} = 60;}
    #-------------------------------------------------------------------------
    add_string_to_file($logfile,"Input Promotion hash:\n\n");
    foreach (sort keys %Promotion)
	{
	$Promotion{$_} = Delete_CRLF_from_End_Of_String($Promotion{$_});
	add_string_to_file($logfile,"\$Promotion{'$_'} = '$Promotion{$_}'\n");
	}
    add_string_to_file($logfile,"\n");
    #-------------------------------------------------------------------------
    add_string_to_file($logfile,"Input Setup hash:\n\n");
    foreach (sort keys %Setup)
	{
	$Setup{$_} = Delete_CRLF_from_End_Of_String($Setup{$_});
	add_string_to_file($logfile,"\$Setup{'$_'} = '$Setup{$_}'\n");
	}
    add_string_to_file($logfile,"\n");
    #-------------------------------------------------------------------------    
    my @filestosubmitto;
    my @tmp;
    if(defined($Setup{'enginesdir1'}))
	{
	@tmp = ();
	@tmp = GetAllFilesInDir($Setup{'enginesdir1'});
	push(@filestosubmitto,@tmp);
	}
    if(defined($Setup{'enginesdir2'}))
	{
	@tmp = ();
	@tmp = GetAllFilesInDir($Setup{'enginesdir2'});
	push(@filestosubmitto,@tmp);
	}
    if(defined($Setup{'enginesdir3'}))
	{
	@tmp = ();
	@tmp = GetAllFilesInDir($Setup{'enginesdir3'});
	push(@filestosubmitto,@tmp);
	}
    #-------------------------------------------------------------------------
    my %data = ();
    
    $data{'action'} = "sendheader";
    
    if($outputhandler) { &$outputhandler(%data); }
    
    foreach my $se (@filestosubmitto)
	{
	%data = ();
	$data{'se'} = $se;
        $data{'action'} = "sedata";
	
	if(!open(FILE,$se)) {next;}
	my @bodyse = <FILE>;
	close(FILE);
    
	my($GET,$POST,$SEname,$SEurl,$Referer,$Host,$Content,$Server,$Country);
	my(@Category);
	
	undef($GET);
	undef($POST);
	undef($SEname);
	undef($SEurl);
	undef($Referer);
	undef($Host);
	undef($Content);
	undef($Server);
	undef($Country);
	@Category = ();
    
	foreach (@bodyse)
	    {
	    $_ = Delete_CRLF_from_End_Of_String($_);
	    
	    if(/^GET\s*([^\s\r\n]*)/i) { $GET = $1; }
	    if(/^POST\s*([^\s\r\n]*)/i) { $POST = $1; }

	    if(/^SEname:\s*([^\r\n]*)/i) { $SEname = $1; }
	    if(/^SEurl:\s*([^\r\n]*)/i) { $SEurl = $1; }
	    
	    if(/^Referer:\s*([^\s\r\n]*)/i) { $Referer = $1; }
	    if(/^Host:\s*([^\s\r\n]*)/i) { $Host = $1; }
	    if(/^Content:\s*([^\r\n]*)/i) { $Content = $1; }
	    if(/^Server:\s*([^\r\n]*)/i) { $Server = $1; }
	    if(/^Country:\s*([^\r\n]*)/i) { $Country = $1; }
	    
	    if(/^Category:\s*([^\r\n]*)/i) { push(@Category,$1); }
	    }
        #---------------------------------------------------------------------
	# Checking data
	my($Method,$Url);
	
	if(defined($GET) && defined($POST))
	    {
	    add_string_to_file($logfile,"\nWWW::Promotion::WWW_Promotion() Error in $se - 2 Methods POST & GET are defined!\n");
	    next;
	    }
	if(defined($GET))
	    {
	    $Method  = 'GET';
	    my @parts = split(/\?/,$GET);
	    $Url     = $parts[0];
	    $Content = $parts[1];
	    }
        elsif(defined($POST))
	    {
	    $Method = 'POST';
	    $Url    = $POST;
	    }
        else
	    {
	    add_string_to_file($logfile,"\nWWW::Promotion::WWW_Promotion() Error in $se - Can't find Method!\n");
	    next;
	    }	
        if(!$Content)
	    {
	    add_string_to_file($logfile,"\nWWW::Promotion::WWW_Promotion() Error in $se - Can't find content!\n");
	    next;
	    }
        #---------------------------------------------------------------------
        # Переводим $url к виду http://
        unless($Url =~ m/^http:\/\//) { $Url = "http://$Host/$Url"; }
        # Убираем двойные //
        $Url =~ s|^http://||;
        $Url =~ s|//|/|g;
        $Url = "http://$Url";
        #---------------------------------------------------------------------
	add_string_to_file($logfile,"\n");
	add_string_to_file_spec_output($logfile,"WWW::Promotion::WWW_Promotion()","Search Engine","\n");
        add_string_to_file($logfile,"Search Engine: $se\n");
	if(defined($Country)) { add_string_to_file($logfile,"Country: $Country\n"); }
	if(defined($SEname)) { add_string_to_file($logfile,"SEname: $SEname\n"); }
	if(defined($SEurl)) { add_string_to_file($logfile,"SEurl: $SEurl\n"); }
	add_string_to_file($logfile,"Method: $Method\n");
	if(defined($Referer)) { add_string_to_file($logfile,"Referer: $Referer\n"); }
	if(defined($Host)) { add_string_to_file($logfile,"Host: $Host\n"); }
	add_string_to_file($logfile,"Url: $Url\n");
	add_string_to_file($logfile,"Content: $Content\n");
	if(defined($Server)) { add_string_to_file($logfile,"Server: $Server\n"); }
	if($#Category >=0 )
	    {
	    foreach (@Category)
		{
		add_string_to_file($logfile,"Category:  $_\n");
		}
	    }
	add_string_to_file($logfile,"\n");

	if(defined($Country)) { $data{'Country'} = $Country; }
	if(defined($Server)) { $data{'Server'} = $Server; }
	if(defined($SEname)) { $data{'SEname'} = $SEname; }
	if(defined($SEurl)) { $data{'SEurl'} = $SEurl; }
	
        #---------------------------------------------------------------------
	# Internal category -> Search Engine category
	delete($Promotion{'category'});

	if($#Category >= 0)
	    {
	    
	    add_string_to_file($logfile,"--- Selecting category for Search Engine (Internal category -> Search Engine category) ---\n");
	    add_string_to_file($logfile,"Internal category: '$internalcategory'\n");
	    
	    foreach (@Category)
	        {
	        if(/<\*\*\*>/i)
		    {
		    $_ =~ m/\s*(.*?)\s*<\*\*\*>\s*(.*?)\s*$/i;
		    my $cat = $1;
		    my $intcat = $2;

		    if($intcat =~ m/^$internalcategory$/i)
		        {
		        $Promotion{'category'} = $cat;
			last;
		        }
		    }
		if(/^$internalcategory$/i)
		    {
		    $Promotion{'category'} = $internalcategory;
		    last;
		    }
		}
	    if(!$Promotion{'category'}) 
		{
		$_ = $Category[0];
		add_string_to_file($logfile,"CATWARN!!! Using first default category: '$_'\n");
		if(/<\*\*\*>/i)
	    	    {
	    	    $_ =~ m/\s*(.*?)\s*<\*\*\*>/i;
	    	    $Promotion{'category'} = $1;
	    	    }
		else
	    	    {
	    	    $Promotion{'category'} = $_;
	    	    }
		}
	    }

	if($Promotion{'category'})	    
	    {
	    add_string_to_file($logfile,"Selected Search Engine category is: '$Promotion{'category'}'\n");
	    }
        #---------------------------------------------------------------------
	# Set new Content
	foreach my $key (keys %Promotion)
	    {
	    $Content =~ s/<\*\*\*$key\*\*\*>/$Promotion{$key}/ig;
	    $Referer =~ s/<\*\*\*$key\*\*\*>/$Promotion{$key}/ig;
	    }
        $Content =~ s|<\*\*\*RANDOM:([0-9]+)-([0-9]+):\*\*\*>|$1+(int rand($2-$1+1))|igme;
        $Referer =~ s|<\*\*\*RANDOM:([0-9]+)-([0-9]+):\*\*\*>|$1+(int rand($2-$1+1))|igme;
        $Content =~ s|<\*\*\*ONERANDOMKEYWORD\*\*\*>|&getrandomkeyword()|igme;
        $Referer =~ s|<\*\*\*ONERANDOMKEYWORD\*\*\*>|&getrandomkeyword()|igme;
        #---------------------------------------------------------------------
	while($Content =~ /(<\*\*\*[^\*]*\*\*\*>)/g)
	    {
	    add_string_to_file($logfile,"Keyword not changed => $1\n");
	    }
	add_string_to_file($logfile,"\n");
	add_string_to_file($logfile,"After <***KEYS***> to VALUES:\n");
	add_string_to_file($logfile,"New Referer: $Referer\n");
	add_string_to_file($logfile,"New Content: $Content\n");	
	
	my %pagenow = ();
	
        $pagenow{'logfile'} = $Setup{'logfile'};
	
        $pagenow{'method'}  = $Method;
        $pagenow{'url'}     = $Url;
	$pagenow{'referer'} = $Referer;
	$pagenow{'content'} = $Content;

        $pagenow{'proxy'}          = $Setup{'proxy'} ? $Setup{'proxy'} : undef;
	$pagenow{'norequest'}      = $Setup{'fastmode'} ? 1 : undef; 
        $pagenow{'timeoutconnect'} = $Setup{'timeoutconnect'} ? $Setup{'timeoutconnect'} : 10;
        $pagenow{'timeoutrequest'} = $Setup{'timeoutrequest'} ? $Setup{'timeoutrequest'} : 60;
	    
        my %out = GetPageNow_4(%pagenow);
        if($out{'error'})
	    {
            my $error = create_error_string("WWW::Promotion::WWW_Promotion()","Error in $se - $out{'errortxt'}!");
	    add_string_to_file($logfile,"\n$error\n");
	    $data{'error'} = 1;
	    $data{'errortxt'} = $error;
	    if($outputhandler) { &$outputhandler(%data); }
	    }    
	else
	    {
	    $data{'body'} = $out{'body'};
	    if($outputhandler) { &$outputhandler(%data); }
	    }
        #---------------------------------------------------------------------
	}
    %data = ();
    $data{'action'} = "sendfooter";
    if($outputhandler) { &$outputhandler(%data); }
    $out{'error'} = 0;
    delete $out{'errortxt'};
    return %out;

    print_error_to_log_and_exit:
    $out{'error'} = 1;
    add_string_to_file($logfile,"\n$out{'errortxt'}\n");
    return %out;
}
##############################################################################
sub getrandomkeyword {
    my @keywords=split(/,/,$Promotion{'keywords'});
    
    return $keywords[int(rand(@keywords))];
}
##############################################################################

=head1 Search Engine Database (SEDB)
 
 SEDB contains an information about search engines. WWW::Promotion 
 will use this information to submit your URL.

 SEDB it is a directory which contains files. Each file contains
 an information about one search engine. Files has various names
 and may reside in different subdirectories inside SEDB. This files 
 has the following format:

 POST http://www.rex-search.com/add/add.cgi HTTP/1.0
 Content: thispage=3&catnum=&url=<***URL***>&navigate=&yourname=<***CONTACTNAME***>&email=<***EMAIL***>&name=<***TITLE***>&keys=<***KEYWORDS***>&desc=<***DESCRIPTION***>&confirm=&urlfail=&refer=http%3A%2F%2Fwww.rex-search.com%2Fadd%2F&cat=<***CATEGORY***>&catkeep=Submit+this+Site

 Or

 GET http://www.ditto.com/urlrequest/AddResponse.asp?txtUserName=<***CONTACTNAME***>&txtURL=<***URL***>&txtEmail=<***EMAIL***>&submit1=Submit&xfrm=True&cs=AddRemoveURL&ac=AddRemoveURL&Action=Add HTTP/1.0

 The first line describes which method to use for submit. Also it
 contains the address where to post data. "HTTP/1.0" in this line 
 unessential, WWW::Promotion will ignore it. This line is required, 
 without it the module will log a bad file and process the next file. 
 For method POST it is required second line (Content:), which contains 
 search engine cantent data. In method GET content is placed in the 
 first line through "?". In a case if the address contains a relative 
 address it is required third line (Host:), which describes  which 
 address of server to use for connect.

 Also the file may contain unessential lines:

 Referer: http://www.ditto.com/urlrequest/addurl.asp
 Inform the module to use this referer. Advanced technology, the 
 engines "think" you are submitting from their form. 

 Host: www.ditto.com
 Inform the module which server to use for connect. It is required 
 only when the first line contains a relative address on a server 
 (for example " GET / HTTP/1.0 ").

 Country: United States
 Country of the search engine. WWW::Promotion uses this info for 
 OutputHandler.

 SEname: Magellan
 Name of the search engine. WWW::Promotion uses this info for 
 OutputHandler.

 SEurl: http://www.url.com
 URL of the search engine. WWW::Promotion uses this info for  
 OutputHandler.

 Server: Netscape-Enterprise/2.01
 The software which is used in the search engine.
 WWW::Promotion uses this info for OutputHandler.

 Category: SEcat-Internet <***> Internet
 Category: SEcat-Business <***> Business
 Categories determined in the search engine. These lines may 
 be more than one. Format:

 Category: (a category of the search engine)<***>(an internal category of the module).
 
 The module will search for conformity of an internal category 
 with a category of a search engine. If you for example have 
 defined an internal category "Other", the module will search for 
 line "Category: SEcat <***> Other" and will use the category 
 "SEcat" for submit. In a case if it does not find the 
 appropriate category it will use first of determined.
 (Category:) it is required only when a content contains a key 
 <***CATEGORY***>. See below.

 The content contains keys which in process of submiting of your 
 URL will be replaced with the data, which you have entered. 
 The following keys can be used in the content:


 <***TITLE***>              -> Ttile of the page (Ex: Super Page)
 <***URL***>                -> URL of the page (Ex: http://www.url.com)
 <***URL-WITHOUT-HTTP***>   -> URL without http:// (Ex: www.url.com)
 <***DESCRIPTION***>        -> Description (Ex: Blah-Blah this page is)
 <***KEYWORDS***>           -> Keywords (Ex: test, test2, test3) 
 <***ONERANDOMKEYWORD***>   -> One random keyword. Keywords are 
			       separeted by points. (Ex: test2)
 
 <***CONTACTNAME***>        -> Contact name (Ex: John Doe)
 <***NAMETITLE***>          -> Nametitle (Ex: Mr.)
 <***FIRSTNAME***>          -> Your first name (Ex: John)
 <***MIDDLENAME***>         -> Your middle name (Ex: W.)
 <***LASTNAME***>           -> Your last name (Ex: Doe)
 <***EMAIL***>              -> E-MAIL address (Ex: blah@blah.com)
   
 <***ADDRESS***>            -> Street address (Ex: 464 Ave Street Gold)
 <***CITY***>               -> City (Ex: Boston)
 <***STATE***>              -> State (Ex: MA)
 <***COUNTRY***>            -> Country (Ex: "United States of America")
 <***COUNTRYCODE***>        -> Country code (Ex: US)
 <***ZIP***>                -> ZIP code (Ex: 68738)
 
 <***COMPANY***>            -> Company name (Ex: IBM, Inc)
 <***PHONE***>              -> Phone (Ex: 1-234-233-2132) 
 <***FAX***>                -> Fax (Ex: 1-234-233-2132) 
 
 <***RANDOM:50-60:***>      -> Random number between 50 and 60.
 <***PASSWORD***>           -> Password (Ex: aaazzz)

 <***CATEGORY***>           -> Internal category (Ex: Other)
 <***COMMENTS***>           -> Comments (Ex: This page is)
 <***LANGUAGE***>           -> Language (Ex: English)


 If you want to create your own file which describe a search engine 
 use your liked text editor or PERL script NEWSE.cgi delivered with 
 SPT5 (http://www.tapor.com/promotion/).
 
=head1 &OutputHandler() Procedure

 It's procedure which will be called by the module for a conclusion 
 of the data about submit process. Procedure OutputHandler has the 
 following format:

 sub OutputHandler {
    local (%data) = _;
 }

 Hash %data will contains data from WWW::Promotion module. The module 
 sends 3 types of the data:

 1. $data{'action'} eq "sendheader"

 WWW:: Promotion tell to you to send header of HTML page to the client 
 browser. It's sent once by the module.

 2 $data{'action'} eq "sedata"

 WWW::Promotion tell you to send the information on the search engine, 
 which was processed.

 3 $data{'action'} eq "sendfooter"

 WWW::Promotion tell you to send footer of HTML page to the client 
 browser. It is sent once by the module.

 When $data{'action'} it is equal "sedata" the hash %data contains 
 also other keys:

 $data{'SEname'}
 The name of the search engine. Defined if a file of search engine 
 contains a line (SEname:).

 $data{'SEurl'}
 The URL of the search engine. Defined if a file of search engine 
 contains a line (SEurl:).

 $data{'se'}
 Contains filename of file in a SE database. It is always defined.

 $data {'Country'}
 The country of the search engine. Defined if a file of search engine 
 contains a line (Country:).

 $data{'error'}
 TRUE if there was an error at submit process, $data {'errortxt'} 
 contains the text of the error.

 $data {'Server'}
 The software which is used in the search engine.
 Defined if a file of search engine contains a line (Server:).

=head1 FASTMODE [tm]

 FASTMODE[tm] is method to submit your URL. In the FASTMODE submission is 
 blazing fast. When $Setup{'fastmode'} flag is passed to WWW_Promotion
 procedure WWW::Promotion looks for $Setup{'proxy'} and if $Setup{'proxy'}
 not defined it returns error.
 
 Why FASTMODE is fast ?
 
 Because WWW::Promotion will not wait answer from server. 
 It will continue to the next search engine without waiting answer
 from previous one. This is may be done only via proxy server.

=head1 COPYRIGHT

Copyright (c) 1999-2001 TAPOR, Inc. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

http://www.tapor.com/promotion/

=cut
