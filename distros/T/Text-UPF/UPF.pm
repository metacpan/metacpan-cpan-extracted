###################################################
## UPF.pm
## Andrew N. Hicox <andrew@hicox.com>
##
## Provides auto-population facilities using 
## <pop> tags.
###################################################


## Global Stuff ###################################
  package Text::UPF;
  use 5.6.0;
  #use warnings;

  require Exporter;
  require Text::Wrapper;
  use AutoLoader qw(AUTOLOAD);
 
## Class Global Values ############################ 
  our @ISA = qw(Exporter);
  our $VERSION = '1.0.5';
  our $errstr = ();
  our @EXPORT_OK = ($VERSION, $errstr);

## new ############################################
 sub new {
     my %p = @_;
     my $obj = bless ({
       #the tagset
        'tagin'		=> "<pop>",
        'tagout'	=> "</pop>",
       #view to get forms from in GetFormDB
        "Form View"	=> "<pop>Form View</pop>",
        "Form Name"	=> "<pop>Form Name</pop>",
        "Form Text"	=> "<pop>Form Text</pop>",
       #form name of standard disclaimer
        "Disclaimer"=> "<pop>Disclaimer</pop>",
       #options to pass to DBIx::YAWM::new
        "DBAccess"	=> {
           #default values for getting forms from db view
            "Server"			=> "<pop>Database Server</pop>",
            "DBType"			=> "<pop>Database Type</pop>",
            "User"				=> "<pop>User Key</pop>",
            "Pass"				=> "<pop>Pass Key</pop>",
            "SID"				=> "<pop>SID</pop>",
            "Port"				=> "<pop>Port</pop>"
        },
       #wrap lines larger than
        'Columns'	=> "<pop>Column Length</pop>",
       #quote the disclaimer with this
        'DiscQuote'	=> "<pop>Disclaimer Quote</pop>"
     });
   #delete null parameters from the object
    foreach (keys %{$obj}){
        if (ref ($obj->{$_}) eq "HASH"){
           foreach my $par (keys %{$obj->{$_}}){ if ($obj->{$_}->{$par} =~/^$/){ delete($obj->{$_}->{$par}); } }
        }else{
            if ($obj->{$_} =~/^$/){ delete($obj->{$_}); }
        }
    }
   #overrides and extra directives go here
    if (exists($p{Port})){ $obj->{DBAccess}->{Port} = $p{Port}; delete($p{Port}); }
    foreach (keys %p){ $obj->{$_} = $p{$_}; }
    return ($obj);
 }

## Populate #######################################
 sub Populate {
    #local vars
     my ($self, %p) = @_;
    #local for easier regex syntax
     my ($tagin,$tagout) = ($self->{tagin},$self->{tagout});
    #if there's no Text, look for Form to get from DB, or as last resort
    #try to open File, if it exists
     unless (exists ($p{Text})){
         if (exists ($p{Form})){
             unless ($p{Text} = $self->GetFormDB(Form => $p{Form})){
                 $self->{errstr} = "failed to get form ($p{Form}) from database! $self->{errstr}";
                 return (undef);
             }
         }elsif (exists ($p{File})){
             unless ($p{Text} = $self->GetFormFile(File => $p{File})){
                 $self->{errstr} = "failed to open form file ($p{File}) $self->{errstr}";
                 return (undef);
             }
         }else{
             $self->{errstr} = "Text, Form, or File is a required option for Text::UPF::Populate";
             return (undef);
         }
     }
    #while there are <pop>'s left to read
     while ($p{Text} =~/($tagin)(.+?)($tagout)/i){
         my ($tag_in,$method,$tag_out) = ($1,$2,$3);
         my $whole_tag = quotemeta("$tag_in$method$tag_out");
         my ($directive,$replace) = ();
         if (exists ($p{Data}->{$method})){
            #if we have the data, just replace it
             $p{Text} =~s/$whole_tag/$p{Data}->{$method}/ig;
             next;
         }elsif ($method =~/(.+)\{(.+)\}/i){
            #look for directive in the method
             ($method,$directive) = ($1,$2);
             my $str = '$replace = $self->$method(directive => $directive, %p)';
             eval ($str);
             if ($@ =~/^can't locate object method/i){
                 $replace = "[Unsuported Population Method: $method]";
             }
             $p{Text} =~s/$whole_tag/$replace/ig;
         }else{
            #maybe we need to call a subroutine?
             my $str = '$replace = $self->$method(%p)';
             eval ($str);
             if ($@ =~/^can't locate object method/i){
                 $replace = "[Undefined Population Method: $method]";
             }
             $p{Text} =~s/$whole_tag/$replace/ig;
         }
     }
    #wrap the lines
     unless (exists($self->{wrapper})){
         $self->{wrapper} = Text::Wrapper->new(columns => $self->{'Columns'});
     }
     unless ($p{NoWrap}){ $p{Text} = $self->{wrapper}->wrap($p{Text}); }      
    #duff man says ... oh yeaaaah!
     return ($p{Text});
 }

## Destroy ########################################
 #clean up db connection (if it belongs to us), destroy object
 sub Destroy {
     my ($self) = shift();
     if (($self->{myDB}) && ($self->{DBTool})){ $self->{DBTool}->Destroy(); }
     $self = undef;
 }

## True for perl include ##########################
 1;
__END__
## AutoLoaded Methods


## Wants ##########################################
## return a unique list of datafields required in 
## the given form letter
sub Wants {
	my ($self, %p) = @_;
	
	#try to open File, if it exists
	unless (exists ($p{Text})){
		if (exists ($p{Form})){
			unless ($p{Text} = $self->GetFormDB(Form => $p{Form})){
				$self->{errstr} = "failed to get form ($p{Form}) from database! $self->{errstr}";
				return (undef);
			}
		}elsif (exists ($p{File})){
			unless ($p{Text} = $self->GetFormFile(File => $p{File})){
				$self->{errstr} = "failed to open form file ($p{File}) $self->{errstr}";
				return (undef);
			}
		}else{
			$self->{errstr} = "Text, Form, or File is a required option for Text::UPF::Populate";
			return (undef);
		}
	}
	
	#local for easier regex syntax
	my ($tagin,$tagout) = ($self->{tagin},$self->{tagout});
	
	#go through and get all the pop tags
	my %wants = ();
	while ($p{Text} =~s/($tagin)(.+?)($tagout)//i){
		$wants{$2} ++;
	}
	
	my @return = keys(%wants);
	return (\@return);
	
}


## GetFormDB ######################################
##retrieve form letter from a database. This method
##requires Config::Framework and DBIx::YAWM and values to
##be set durring Makefile.PL.
sub GetFormDB {
   #local vars
    my ($self, %p) = @_;
    my ($DBTool,$data) = ();
   #make sure we have what we need to do this
    foreach ("Form View","Form Name","Form Text","DBAccess"){
        unless (exists ($self->{$_})){
            $self->{errstr} = "GetFormDB missing required data to connect to database ";
            $self->{errstr}.= "Set data by editing Text::UPF.pm or rebuilding the module.";
            return (undef);
        }
    }
   #make sure someone specified which form to get
    unless (exists($p{Form})){
        $self->{errstr} = "Form is a required option to Text::UPF::GetFormDB";
        return (undef);
    }
   #did we already get this one?
    if (exists ($self->{formCache}->{$p{Form}})){ return ($self->{formCache}->{$p{Form}}); }
   #stuff we're gonna need
    require Config::Framework;
    require DBIx::YAWM;
   #get configuration data
    unless (exists($self->{Config})){
        unless ($self->{Config} = new Config::Framework(GetSecure	=> 1)){
            $self->{errstr} = "failed to get Config::Framework object";
            return (undef);
        }
    }
   #get DBIx::YAWM object
    unless (exists($self->{DBTool})){
        my %conn = (
            Server		=> $self->{DBAccess}->{Server},
            DBType		=> $self->{DBAccess}->{DBType},
            SID			=> $self->{DBAccess}->{SID},
            User		=> $self->{Config}->{Secure}->{$self->{DBAccess}->{User}},
            Pass		=> $self->{Config}->{Secure}->{$self->{DBAccess}->{Pass}}
        );
        if (exists($self->{DBAccess}->{Port})){ $conn{Port} = $self->{DBAccess}->{Port}; }
        unless ($self->{DBTool} = DBIx::YAWM::new(%conn)){
            $self->{errstr} = "GetFormDB can't connect to db: $DBIx::YAWM::errstr";
            return (undef);
        }
        $self->{myDB} = 1;
    }
   #get the text of the form
    unless ($data = $self->{DBTool}->Query(
        Select	=> [ $self->{'Form Text'} ],
        From	=> $self->{'Form View'},
        Where	=> "$self->{'Form Name'} = '$p{Form}'"
    )){
        $self->{errstr} = "GetFormDB can't get form $p{Form}: $DBTool->{errstr}";
        return (undef);
    }
   #we'll presume there will never be more than one record here
    $self->{formCache}->{$p{Form}} = $data->[0]->{$self->{'Form Text'}};
    return ($self->{formCache}->{$p{Form}});
}

## GetFormFile ####################################
#open a file, get form text from it
sub GetFormFile {
   #local vars
    my ($self,%p) = @_;
    unless (exists ($p{File})){
        $self->{errstr} = "File is a required option to Text::UPF::GetFormFile";
        return (undef);
    }
   #did we already get this one?
    if (exists ($self->{formCache}->{$p{File}})){ return ($self->{formCache}->{$p{File}}); }
   #open da file
    open (INFORM, "$p{File}") || do {
        $self->{errstr} = "can't open $p{File}: $!";
        return (undef);
    };
   #diddydid --- it's diddy, and he won't stop!
    my $str = join ('',<INFORM>);
    close (INFORM);
   #because he can't stop, evidently
    return ($str);
}

###################################################
##      auto-population method subroutines
###################################################

## nbd ########################
##calculates next business day
##does not calculate for holidays
sub nbd {
    require Date::Parse;
    my ($day,$caca) = split (/\s+/,localtime(time()));
    my $n_time = time();
    if ($day eq "Fri"){
        $n_time += (86400 * 3);
    }elsif ($day eq "Sat"){
        $n_time += (86400 * 2);
    }else{
        $n_time += 86400;
    }
    my @d_time = split (/\s+/,Date::Parse::localtime($n_time));
    splice (@d_time,3,1);
    my $o_time = join (" ",@d_time);
    return ($o_time);
}

## today ######################
##returns today's date
sub today {
     my @d_time = split (/\s+/,localtime(time()));
     splice (@d_time,3,1);
     my $o_time = join (" ",@d_time);
     return ($o_time);
}

## ShowDiary ######################
##this "decodes" the format that diaries are passed in as
##the optional mode specifies "html" or "text". "text" inserts
##the text in <pre> tags. "html" makes a list-entry style output.
##default mode is "html"
sub ShowDiary {
     my ($self, %p) = @_;
    #the directive contains a hash!
     my %directive = ();
     my $str = '%directive = ( ';
     $str   .= $p{directive};
     $str   .= ')';
     eval ($str);
    #default mode
     if (! exists($directive{'Mode'})){ $directive{'Mode'} = "html"; }
    #make sure we have the data we need
     unless (exists($p{Data}->{$directive{'Data'}})){
         $self->{errstr} = "$directive{'Data'} does not exist in Data ... no diary to show";
         $out = "no diary to show";
         return($out);
     }
    #prefixes and stuff
     if ($directive{'Mode'} eq "html"){
         $out = "";
     }else {
         $out = "<pre>";
     }
    #do it
     foreach (@{$p{Data}->{$directive{'Data'}}}){
        #user / timestamp
         if ($directive{'Mode'} eq "html"){
             $out .= "<b>$_->{timestamp} - User: <font color=red>$_->{user}</font></b><hr noshade><p>\n";
             $out .= "<pre>$_->{'value'}</pre>\n";
             $out .= "<br><br></li>\n";
         }else{
             $out .= "[USER]: $_->{user}  /  [DATE]: $_->{timestamp}\n";
             my @temp = split ("\n",$_->{value});
             foreach $l (@temp){
                 $out .= "\t$l\n";
             }
         }
     }
    #suffixes and stuff
     if ($directive{'Mode'} eq "html"){
         $out .= "";
     }else {
         $out .= "</pre>";
     }
    #back out there
     return ($out);
}

# end of Text::UPF::ShowDiary
1;


## Disclaimer #####################
sub Disclaimer {
   #local vars
    my ($self,%p) = @_;
    my ($text,$text2) = ();
   #we must have 'REPLY_TO' in the data
    unless (exists($p{Data}->{REPLY_TO})){
        $self->{errstr} = "REPLY_TO must be supplied when populating Disclaimer";
        return ("[failure populating standard disclaimer!]");
    }
   #yeah! ...
    unless ($text = $self->Populate(
        Form	=> $self->{Disclaimer},
        Data	=> $p{Data},
        NoWrap	=> 1
    )){
        $self->{errstr} = "failed to get disclaimer text! $self->{errstr}";
        return ("[failure retrieving disclaimer from database!]");
    }
   #filter native line returns
    $text =~s/\n/ /g;
   #put the quote chars in
    my $wrapper = Text::Wrapper->new(columns => ($self->{'Columns'} - length($self->{DiscQuote})));
    $text = $wrapper->wrap($text);
    foreach (split (/\n/,$text)){ $text2 .= "$self->{DiscQuote}$_\n"; }
   #back out there
    return ($text2);
}
