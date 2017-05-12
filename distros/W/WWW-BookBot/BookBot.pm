package WWW::BookBot;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = "0.12";
@EXPORT = qw();
@EXPORT_OK = @EXPORT;
 
use Encode;
use File::Basename;
use File::Spec::Functions;
use File::Path;
use Fcntl;
use WWW::BookBot::FakeCookies;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Date;
use URI;
use Carp;
use Data::Dumper;
use POSIX qw(ceil floor);

our %entity2char;	#for html entities decoding

#-------------------------------------------------------------
# Create objects and initialize
#	$bot->new(\%args)								=> $bot
#	$class->default_settings						=> \%settings
#	$bot->initialize								=> N/A
#	$bot->work_dir($dir)							=> $work_dir
#-------------------------------------------------------------
sub new {
	my $class = ref($_[0]) || $_[0];
	my $pargs = ref($_[1]) ? $_[1] : {} ;
	my $self = $class->default_settings;
	bless($self, $class);

	# Set default work dir
	my $dirname=$self->{classname};
	$dirname=~s/^WWW:://;
	$self->{work_dir}=catfile($ENV{HOME}, split(/::/,$dirname));

	# Set user defined args
	foreach (keys %$pargs) {
		$self->{$_} = $pargs->{$_};
	}

	# initialize and return
	$self->initialize;
	return $self;
}
sub default_settings {
	{
		classname				=> shift,	#cureent classname
		book_get_num			=> 0,		#statistics of books, to be used in file title
		book_has_chapters		=> 1,		#0-only 1 chapter, 1-multiple chapters
		book_max_levels			=> 5,		#max levels of book - chapters - chapters - chapters ..
		book_max_chapters		=> 500,		#max chapters in 1 book
		catalog_max_pages		=> 500,		#max catalog pages
		get_agent_name			=> "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; AIRF)",
		get_agent_proxy			=> "Default",
			#Default			Use default IE proxy
			#No					Don't use proxy
			#196.23.147.34:80	Use given proxy
			#Default;202.105.138.19:8080;202.110.220.14:80;...
			#					Use multiple proxy, one visit use one proxy in turn
		get_delay_second		=> 0,		#if get_delay_second>0 then delay get_delay_second+rand seconds
		get_delay_second_rand	=> 2,
		get_fail_showtype		=> '',		#''-show simplified info, 'Detail'-show detailed info
		get_file_directory		=> './saved',	#debug save and read file from this directory
		get_from_file			=> 0,		#0-normal operation, 1-get from file only
		get_language			=> "en",	#get headers: language
		get_max_retries			=> 5,		#max retries of 1 get
		get_save_file			=> 0,		#0-normal operation, 1-save to file for latter debug
		get_skip_zip			=> 1,		#skip fetch zip files
		get_skip_media			=> 1,		#skip fetch media files
		get_timeout				=> 40,		#get timeout
		get_trunk_size			=> 50000,	#define 1 trunk = xxxBytes for display
		get_trunk_fresh_size	=> 5000,	#if get size > xxxBytes, then refresh trunk display
		get_visited_url_num		=> 0,		#statistics of visted urls, to be used in get_from_file/get_save_file
		language_decode			=> "utf8",	#to read with encoding
		language_encode			=> "utf8",	#to save with encoding
		process_all				=> 0,		#process all pages of catalog
		result_no_crlf			=> 1,		#0-with crlf, 1-no crlf
		space_leading_remove 	=> 1,		#remove leading spaces
		space_leading_max		=> 20,		#max leading spaces
		space_inner_remove		=> 1,		#remove inner spaces
		space_inner_min_words	=> 5,		#minimal length of word with inner spaces
		text_paragraph_type		=> 'br',	#type of paragraph split methods
			# br		 one br as end of paragraph
			# brbr		 two br as end of paragraph
			# cr		 one cr as end of paragraph
			# crcr		 two cr as end of paragraph
			# crandspace one cr and followed with space as end of paragraph
		screen_limit_trunk		=> 25,		#max trunks to be displayed
		screen_limit_title		=> 14,		#max title to be displayed
	};
}
sub initialize {
	my $self = shift;

	# Initialize languages
	$self->{lang_encode}=find_encoding($self->{language_encode})
		if $self->{language_encode} ne '';
	$self->{lang_decode}=find_encoding($self->{language_decode})
		if $self->{language_decode} ne '';

	# Initialize messages
	$self->trandict_init;
	$self->msg_init;

	# Create work directory
	$self->work_dir( $self->{work_dir} );
	eval {mkpath($self->{work_dir})};
	$self->fatal_error("FailMkDir", dir=>$self->{work_dir}, errmsg=>$@) if $@;

	# Check debug directory
	$self->{get_file_directory_save}=catfile($self->{get_file_directory}, $self->get_alias());
	$self->{get_file_directory_read}=$self->{get_file_directory_save};
	$self->{get_file_directory_read}=~s,\\,/,sg;
	$self->{get_file_directory_read}=~s,/+$,,sg;
	eval {mkpath($self->{get_file_directory_save})}
		if $self->{get_from_file} or $self->{get_save_file};

	# Initialize patterns
	$self->{patterns} = {};
	foreach ($self->getpattern_lists) {
		my $sub="getpattern_".$_;
		my $sub_data=$sub."_data";
		$self->{patterns}->{$_} = $self->can($sub) ?
			$self->$sub : $self->parse_patterns($self->$sub_data);
	}

	# Content Type Initialize
	$self->contenttype_init;

	# Initialize LWP user agents
	$self->agent_init;

	# Initialize DB
	$self->db_init;
	$self->db_load;
	
	# Try to login
	$self->go_login;
}
sub work_dir {
	my ($self, $work_dir) = @_;
	return $self->{work_dir} if $work_dir eq '';

	# Reset default work directory, log file, db file
	$self->{work_dir}=$work_dir;
	$self->{file_log}=catfile($work_dir, "0000log.txt");
	$self->{file_DB}=catfile($work_dir, "0000db.txt");
	return $work_dir;
}

#-------------------------------------------------------------
# Debug functions
#	$bot->dump_class									=> N/A
#	$bot->dump_var(@vars)								=> N/A
#	$bot->test_pattern($pattern_name, $content)			=> 1-match 0-no match
#-------------------------------------------------------------
sub dump_class {
	my $self = shift;
	local $Data::Dumper::Maxdepth=1;	#only show 1 level
	local $Data::Dumper::Sortkeys=1;	#sort keys
	local $Data::Dumper::Quotekeys=0;	#no quote
	local $Data::Dumper::Varname=$self->{classname};
	print Dumper($self);
}
sub dump_var {
	my $self = shift;
	foreach (@_) {
		local $Data::Dumper::Sortkeys=1;	#sort keys
		local $Data::Dumper::Quotekeys=0;	#no quote
		local $Data::Dumper::Varname=$self->{classname}."->{$_}";
		print Dumper($self->{$_});
	}
}
sub test_pattern {
	my ($self, $pattern_name) = (shift, shift);
	
	# get pattern, verify and print its encoded content
	my $pattern = $self->{patterns}->{$pattern_name};
	croak "Invalid pattern name: $pattern" if not(defined($pattern));
	printf "[Pattern $pattern_name]=\"%s\"\n", $self->en_code($pattern);
	
	my $result=1;
	if( $_[0] ne '' ) {
		# test content if specified
		my $str=$self->de_code($_[0]);
		my $result=($str=~/$pattern/);
		printf "  Test with \"%s\": %s\n",
			$_[0],
			$result ? 'match' : 'no match';
	}
	return $result;
}

#-------------------------------------------------------------
# Pattern utility functions
#	$bot->parse_patterns("a\n'b\nc\n")				=> [aA]|\'[bB]|[cC]
#		add \ before /"'`$& automatically
#		encoding -> decoding
#		auto-case insensitive conversion except 2:
#			first line is (case)
#			[...]
#-------------------------------------------------------------
sub parse_patterns {
	my ($self, $str) = @_;
	$str='' if not(defined($str));

	# simplify pattern construction by add \ before /"'`$& automatically
	$str=~s,(?=\/|\"|\'|\`|\$|\&),\\,g;
	
	# multiplie lines -> |
	my $pattern = "";
	foreach ( split /\r\n|\r|\n/, $str ) {
		$pattern .= $_.'|' if $_ ne '';
	}
	$pattern=~s/\|$//;
	
	# parse \n
	$pattern=~s/\\n/\n/sg;
	
	# decode
	$str=$self->de_code($pattern);
	
	# case sensitive and insensitive
	if( $str=~/^\(case\)\|/s ) {
		# case sensitive
		$str=~s/^\(case\)\|//s;
		$pattern=$str;
	} else {
		# change to case insensitive form
		$pattern="";
		my $meet_left=0;
		foreach (split /(\\.|[\[\]])/, $str) {
			$meet_left=1 if $_ eq '[';
			$meet_left=0 if $_ eq ']';
			s,([a-zA-Z]),'['.lc($1).uc($1).']',eg if $meet_left==0 and not(/^\\/);
					# skip [...] and \d
			$pattern.=$_;
		}
	}

	# return
	return $pattern;
}

#-------------------------------------------------------------
# Message functions
#	$bot->trandict_init								=> $bot->{translate_dict}
#	$bot->msg_init									=> $bot->{messages}
#	$bot->msg_format($msgid, \%args)				=> $msgstr
#	$bot->fatal_error($msgid, \%args)				=> N/A
#-------------------------------------------------------------
sub trandict_init {
	shift->{translate_dict} = {
		'log'		=> "log",
		'result'	=> "result",
		'DB'		=> "DB",
		'debug'		=> 'debug',
	}
}
sub msg_init {
	my $skip_info="\n".'$pargs->{levelspace}  url=$pargs->{url}'."\n";
	shift->{messages} = {
		TestMsg			=> 'Test: $pargs->{TestInfo} $pargs->{TestNum}',
		BookBinaryOK	=> '$pargs->{data_len_KB} $pargs->{write_file}'."\n",
		BookChapterErr	=> ' cannot parse'.$skip_info,
		BookChapterMany	=> '[$pargs->{chapter_num}CH]',
		BookChapterOne	=> '[0001CH]',
		BookChapterOK	=> '$pargs->{data_len_KB}'."\n",
		BookStart		=> '$pargs->{levelspace} [$pargs->{bpos_limit}/$pargs->{book_num}] $pargs->{title_limit} ',
		BookTOCFinish	=> '$pargs->{TOC_len_KB}'."\n",
		CatalogInfo		=> 'Get Catalog: ',
		CatalogResultErr=> ' 0 books'."\n",
		CatalogResultOK	=> ' $pargs->{book_num} books'."\n",
		CatalogURL		=> '$pargs->{url}',
		CatalogURLEmpty	=> '[Fail] catalog url is empty'."\n",
		DBHead			=> <<'DATA',
#!$pargs->{perlcmd}
##======================================
## Auto-generated DB File of $pargs->{classname}
##    Create time: $pargs->{createtime}
##======================================

use $pargs->{classname};
my \$bot = new $pargs->{classname};

DATA
		DBCatalogErr	=> ' \$bot->go_catalog({$pargs->{allargs}});'."\t#Err\n",
		DBCatalogOK		=> '#\$bot->go_catalog({$pargs->{allargs}});'."\n",
		DBBookErr		=> "\t".' \$bot->go_book({$pargs->{allargs}});'."\t#Err\n",
		DBBookOK		=> "\t".'#\$bot->go_book({$pargs->{allargs}});'."\n",
		FailClearDB		=> 'Fail to clear DB file $pargs->{filename}: $pargs->{errmsg}',
		FailClose	 	=> 'Fail to close $self->{translate_dict}->{$pargs->{filetype}} file $pargs->{filename}: $pargs->{errmsg}',
		FailMkDir		=> 'Fail to mkdir $pargs->{dir}: $pargs->{errmsg}',
		FailOpen	 	=> 'Fail to open $self->{translate_dict}->{$pargs->{filetype}} file $pargs->{filename}: $pargs->{errmsg}',
		FailWrite	 	=> 'Fail to write $self->{translate_dict}->{$pargs->{filetype}} file $pargs->{filename}: $pargs->{errmsg}',
		GetFail404		=> <<'DATA',
[$pargs->{code},Fail] No such file
        $pargs->{url_real}
DATA
		GetFail404Detail=> <<'DATA',
[$pargs->{code},Fail] No such file
>>>>Request
$pargs->{req_content}<<<<Response
$pargs->{status_line}

DATA
		GetFailRetries	=> <<'DATA',
[$pargs->{code},Fail] Exceed retry limits
        $pargs->{url_real}
DATA
		GetFailRetriesDetail	=> <<'DATA',
[$pargs->{code},Fail] Exceed retry limits
>>>>Request
$pargs->{req_content}<<<<Response
$pargs->{status_line}
$pargs->{res_content}

DATA
		GetURLRetry		=> '[$pargs->{code}, Retry] ',
		GetURLSuccess	=> '$pargs->{len_KB} ',
		GetWait			=> 'Wait..',
		SkipMaxLevel	=> '[Skip]level>$self->{book_max_levels}'.$skip_info,
		SkipMedia		=> '[Skip]media files'.$skip_info,
		SkipTitleEmpty	=> '[Skip]title is empty'.$skip_info,
		SkipUrlEmpty	=> '[Skip]url is empty'."\n",
		SkipVisited		=> '[Skip]visited'."\n",
		SkipZip			=> '[Skip]zip files'.$skip_info,
	};
}
sub msg_format {
	my ($self, $id, $pargs) = @_;
	return eval('"'.$self->{messages}->{$id}.'"');
}
sub fatal_error {
	croak shift->msg_format(@_);
}

#-------------------------------------------------------------
# Encode and decode functions
#	$bot->en_code($string)							=> $octets
#	$bot->de_code($octets)							=> $contents
#-------------------------------------------------------------
sub en_code {
	return ($_[0]->{language_encode} ne '')
		? $_[0]->{lang_encode}->encode($_[1]) : $_[1];
}
sub de_code {
	return ($_[0]->{language_decode} ne '')
		? $_[0]->{lang_decode}->decode($_[1]) : $_[1];
}

#-------------------------------------------------------------
# File I/O functions
#	$bot->file_init($filetype, $filename, @contents)	=> N/A
#	$bot->file_writebin($filetype, $filename, $buf)		=> N/A
#	$bot->file_add($filetype, $filename, @contents)		=> N/A
#-------------------------------------------------------------
sub file_init {
	my ($self, $filetype, $filename) = (shift, shift, shift);
	local(*WORK);
	open(WORK, ">$filename")
		or $self->fatal_error("FailOpen", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
	binmode(WORK) if (($filetype eq 'result') and $self->{result_no_crlf}) or $filetype eq 'debug';
	(print WORK @_)
		or $self->fatal_error("FailWrite", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
	close(WORK)
		or $self->fatal_error("FailClose", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
}
sub file_add {
	my ($self, $filetype, $filename) = (shift, shift, shift);
	local(*WORK);
	open(WORK, ">>$filename")
		or $self->fatal_error("FailOpen", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
	binmode(WORK) if (($filetype eq 'result') and $self->{result_no_crlf}) or $filetype eq 'debug';
	(print WORK @_)
		or $self->fatal_error("FailWrite", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
	close(WORK)
		or $self->fatal_error("FailClose", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
}
sub file_writebin {
	my ($self, $filetype, $filename) = (shift, shift, shift);
	local(*WORK);
	sysopen(WORK, $filename, O_WRONLY|O_TRUNC|O_CREAT)
		or $self->fatal_error("FailOpen", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
	syswrite(WORK, $_[0], 200000000)
		or $self->fatal_error("FailWrite", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
	close(WORK)
		or $self->fatal_error("FailClose", {filetype=>$filetype, filename=>$filename, errmsg=>$!});
}

#-------------------------------------------------------------
# Logging functions
#	$bot->log_msg($contents)						=> N/A
#	$bot->log_msgen($contents)						=> N/A
#	$bot->log_add($msgid, \%args)					=> N/A
#-------------------------------------------------------------
sub log_msg {
	my $self = shift;
	$|=1;
	print @_;
	$self->file_add( "log", $self->{file_log}, @_ );
}
sub log_msgen {
	my $self = shift;
	$self->log_msg( $self->en_code($_[0]) );
}
sub log_add {
	my $self = shift;
	$self->log_msg(	$self->msg_format(@_) );
}

#-------------------------------------------------------------
# Result output functions
#	$bot->result_filename(\%args)					=> filename
#	$bot->result_init(\%args)						=> filename
#	$bot->result_add($filename, $content_en)		=> N/A
#	$bot->result_adden($filename, $content_de)		=> N/A
#	$bot->result_settime($filename, $curtime)		=> N/A
#	$bot->string2time($str)							=> $time
#-------------------------------------------------------------
sub result_filename {
	my ($self, $pargs) = @_;
	my $filename=$self->result_filestem($pargs).".".$pargs->{ext_save};
	$filename=$self->de_code($filename);
	$filename=~s/[\\\/\:\*\?\"<>\|]//g;	# remove banned characters
	$filename=$self->en_code($filename);
	return catfile($self->{work_dir}, $filename);
}
sub result_init {
	my $self = shift;
	my $filename = $self->result_filename(@_);
	$self->file_init( "result", $filename );
	return $filename;
}
sub result_add {
	my $self = shift;
	my $filename = shift;
	$self->file_add( "result", $filename, $_[0] );
}
sub result_adden {
	my $self = shift;
	my $filename = shift;
	$self->file_add( "result", $filename, $self->en_code($_[0]) );
}
sub result_settime {
	my ($self, $filename, $curtime) = @_;
	utime $curtime, $curtime, $filename;
}
sub string2time {
	str2time($_[1]);
}

#-------------------------------------------------------------
# DB functions
#	$bot->db_init									=> N/A
#	$bot->db_clear									=> N/A
#	$bot->db_load									=> N/A
#	$bot->db_add($type, $result, \%args)			=> N/A
#-------------------------------------------------------------
sub db_init {
	my $self = shift;
	$self->{DB_visited_book}={};
	return if -f $self->{file_DB};

	my $perlcmd = $^X;
	$perlcmd=~s/\\/\//g;
	$self->file_init( "DB", $self->{file_DB}, $self->msg_format( "DBHead", {
		perlcmd=>$perlcmd,
		classname=>$self->{classname},
		createtime=>HTTP::Date::time2iso(time),
	}));
}
sub db_clear {
	my $self = shift;
	my $filename = $self->{file_DB};
	unlink($filename)
		or $self->fatal_error("FailClearDB", {filename=>$filename, errmsg=>$!});
}
sub db_load {
	my $self = shift;
	my $filename = $self->{file_DB};
	local(*WORK);
	open(WORK, $filename)
		or $self->fatal_error("FailOpen", {filetype=>"DB", filename=>$filename, errmsg=>$!});
	my ($type, $result, $url, $paras);
	while(<WORK>) {
		if( /(.)\$bot->go_([^\(]*)\((.*)\)/ ) {
			$type=$2;
			$result=($1 eq '#') ? 'OK' : 'Err';
			$url=($3=~/url=>\'([^\']*)\'/) ? $1 : '';
			$self->{"DB_visited_$type"}->{$url}=$result;
		}
	}
	close(WORK)
		or $self->fatal_error("FailClose", {filetype=>"DB", filename=>$filename, errmsg=>$!});
}
sub db_add {
	my ($self, $type, $result, $pargs) = @_;
	return if not defined($pargs->{url});
	my $url = $pargs->{url};
	my $allargs = "";
	my $str;
	foreach (sort keys %$pargs) {
		$str=$pargs->{$_};
		$str=~s/\'/\\\'/g;
		$allargs .= "$_=>'$str', ";
	}
	$self->{"DB_visited_$type"}->{$url}=$result;
	$self->file_add( "DB", $self->{file_DB},
		$self->msg_format( "DB".ucfirst($type)."$result", {allargs=>$allargs}) );
}

#-------------------------------------------------------------
# Agent functions
#	$bot->agent_init								=> N/A
#	$bot->agent_setproxy($ua, $proxy_name)			=> $proxy_settings
#		$proxy_name eq "No"				Don't use proxy
#		$proxy_name eq "Default"		suggest IE's default proxy
#		$proxy_name eq "192.168.1.5"	defined proxy
#-------------------------------------------------------------
sub agent_init {
	my $self = shift;
	my $cookies=new WWW::BookBot::FakeCookies;
	$self->{get_agent_cur} = 0;
	$self->{get_lasturl} = "" if not(defined($self->{get_lasturl}));
	$self->{get_agent_array} = [];
	foreach ( split /;/, $self->{get_agent_proxy} ) {
		my $ua=new LWP::UserAgent;
		$ua->agent( $self->{get_agent_name} );
		$self->agent_setproxy( $ua, $_ );
		$ua->timeout( $self->{get_timeout} );
		$ua->cookie_jar( $cookies );
		push @{ $ua->requests_redirectable }, 'POST';
		push @{$self->{get_agent_array}}, $ua;
	}
}
sub agent_setproxy {
	my ($self, $ua, $proxy_name) = @_;
	$proxy_name=~s/ //g;	# Remove spaces
	return '' if $proxy_name eq 'No' or $proxy_name eq '';	#Don't use proxy

	# Check assigned proxy
	if( $proxy_name ne 'Default' ) {
		$ua->proxy(['http','https','ftp'],"http://$proxy_name/");
		return $proxy_name;
	}

	# Check Win32::TieRegistry module
	my $ie_proxy_ok=0;
	my %RegHash;
	my $win32_registry='use Win32::TieRegistry(Delimiter=>"/", TiedHash => \%RegHash);';
	if( $^O eq 'MSWin32' ) {
		eval $win32_registry;
		$ie_proxy_ok=1 if not $@;
	}
	return "" if not $ie_proxy_ok;

	# Get IE registry
	my($iekey, $ie_proxy_enable, $ie_proxy_server);
	$iekey=$RegHash{"CUser/Software/Microsoft/Windows/CurrentVersion/Internet Settings/"}
		or return "";
	$ie_proxy_enable=$iekey->{"/ProxyEnable"} or return "";
	$ie_proxy_server=$iekey->{"/ProxyServer"} or return "";
	return "" if !($ie_proxy_enable=~/1$/);

	# Set LWP proxy
	if($ie_proxy_server=~/;/) {
		#Multiple proxies, such as ftp=192.168.1.3:8080;...;https=192.168.1.3:8080
		foreach (split(/;/, $ie_proxy_server)) {
			next if $_ eq '';
			$ua->proxy($1,"http://$2/") if /^(.*?)=(.*?)$/;
		}
	}else{
		#Single proxy, such as 192.168.1.3:8080
		$ua->proxy(['http','https','ftp'],"http://$ie_proxy_server/");
	}
	return $ie_proxy_server;
}

#-------------------------------------------------------------
# string utility functions
#	$bot->url_rel2abs($relative, $baseurl)			=> $absolute_url
#	$bot->len_KB(95632)								=> "   93K"
#	$bot->string_limit($str, $limit_len)			=> $str_limit
#		'abc', 4	-> 'abc '
#		'abcdef', 4	-> 'abcd'
#-------------------------------------------------------------
sub url_rel2abs {
	return URI->new_abs($_[1], URI->new($_[2]))->as_string;
}
sub len_KB {
	my ($self, $len)=@_;
	if($len<1024) {
		return sprintf("%5dB", $len);
	} elsif($len<9999*1024) {
		return sprintf("%5dK", $len/1024);
	} else {
		return sprintf("%5dM", $len/(1024*1024));
	}
}
sub string_limit {
	my ($self, $str, $limit_len)=@_;
	$str=$self->de_code($str);
	my ($i, $j);
	for($i=0, $j=0; $i<length($str); $i++) {
		if( ord(substr($str, $i, 1))>=128 ) {
			last if $j+2>$limit_len;
			$j+=2;
		}else{
			last if $j+1>$limit_len;
			$j++;
		}
	}
	$str=substr($str, 0, $i).(" " x ($limit_len-$j));
	return $self->en_code($str);
}

#-------------------------------------------------------------
# fetch functions
#	$bot->get_url($url)								=> $res
#	$bot->get_url_request($url, $pargs)				=> $res
#		$bot->get_url_request($url)
#		$bot->get_url_request($url, {method='post', form={var=>value, var=>value}})
#	$bot->get_fail($msgid, $res)					=> N/A
#-------------------------------------------------------------
sub get_url {
	my ($self, $url) = @_;
	my $res;
	$self->get_url_verify($url);	#verify or change $url before real work
	my %info=(url=>$url);			#for display messages
	my $wait_msg=$self->msg_format('GetWait', {});	#perpare for wait message

	for(my $i=$self->{get_max_retries}; $i>0; $i--) {
		#issues real request
		$res=$self->get_url_request($url);
		
		#record infos for display messages
		$info{retry}=$i;
		$info{code}=$res->code;
		$info{len}=length($res->content);
		$info{len_KB}=$self->len_KB($info{len});

		# display before sleep
		$self->log_add("GetURLSuccess", \%info) if $res->is_success;
		$self->get_fail("GetFail404", $res) if $res->code==404;
		
		if($self->{get_delay_second}>0) {
			# sleep if needed
			print $wait_msg;
			sleep $self->{get_delay_second}+rand($self->{get_delay_second_rand});
			print "\b" x length($wait_msg);
		}

		# return or display after sleep
		return $res if $res->is_success or $res->code==404;
		$self->log_add("GetURLRetry", \%info) if $i>1;
	}
	$self->get_fail("GetFailRetries", $res);
	return $res;
}
sub get_url_request {
	my ($self, $url, $pargs) = @_;

	# prepare for parameters
	$pargs={} if not(ref($pargs));
	$self->{get_lasturl}=$url if $self->{get_lasturl} eq '';
	$self->{get_visited_url_num}++;
	$url='file:'.$self->{get_file_directory_read}.'/'.$self->{get_visited_url_num}.'.htm' if $self->{get_from_file};
	my $agent=$self->{get_agent_array}->[$self->{get_agent_cur}];
	my $method=defined($pargs->{method}) ? $pargs->{method} : 'get';
	my %header=(
		'Accept'			=>	'*/*',
		'Referer'			=>	$self->{get_lasturl},
		'Accept-Language'	=>	$self->{get_language},
	);

	# trunk display vars
	my $get_trunk_size=$self->{get_trunk_size};
	my $screen_limit_trunk=$self->{screen_limit_trunk};
	my $get_trunk_fresh_size=$self->{get_trunk_fresh_size};
	my ($first_run, $expected_length, $expected_trunks, $bytes_received, $trunk_received)=(1,0,0,0,0);
	my @trunk_statuschar=qw(- \ | /);
	my ($trunk_status, $trunk_now, $trunk_refresh_now, $trunk_ceil, $trunk_floor)=(0, 0,0,0,0);
	my ($str_display, $bak_number);

	# get it
	my $res = $agent->request(
		$method eq 'get' ? GET($url, %header) : POST($url, $pargs->{form}, %header) ,
		sub {
			if($first_run) {
				# first get, then caculate expected length and print
				$first_run=0;
				$expected_length=$_[1]->headers->content_length;
				if($expected_length>0) {
					$expected_trunks=ceil($expected_length/$get_trunk_size);
					$expected_trunks=$screen_limit_trunk if $expected_trunks>$screen_limit_trunk;
					$str_display="." x $expected_trunks;
					$str_display.=" " x ($screen_limit_trunk-$expected_trunks);
					$str_display.=$self->len_KB($expected_length) if $expected_length>0;
					$str_display.="\b" x length($str_display);
					print $str_display;
				}
			}
			$bytes_received += length($_[0]);
			$trunk_ceil=ceil($bytes_received/$get_trunk_size);
			$trunk_ceil=$screen_limit_trunk if $trunk_ceil>$screen_limit_trunk;
			$trunk_floor=floor($bytes_received/$get_trunk_size);
			$trunk_floor=$screen_limit_trunk-1 if $trunk_floor>$screen_limit_trunk-1;
			$str_display="";
			$bak_number=0;
			if($trunk_floor>$trunk_received) {
				$str_display.= ">" x ($trunk_floor - $trunk_received);
			}
			if($trunk_floor<$trunk_ceil and $bytes_received>=$trunk_refresh_now+$get_trunk_fresh_size) {
				$trunk_status=0 if ++$trunk_status>=scalar(@trunk_statuschar);
				$str_display.= $trunk_statuschar[$trunk_status];
				$bak_number++;
			}
			if($bytes_received>=$trunk_refresh_now+$get_trunk_fresh_size) {
				if($expected_length>0 and $trunk_ceil>=$screen_limit_trunk) {
					my $trunk_percent=int(100*$bytes_received/$expected_length);
					$trunk_percent=100 if $trunk_percent>100;
					$str_display.= "   $trunk_percent%";
					$bak_number+=length($trunk_percent)+4;
				}
				$trunk_refresh_now=$bytes_received;
			}
			print $str_display. "\b" x $bak_number;
			$trunk_received=$trunk_floor;
			$_[1]->add_content(\$_[0]);
		},
	);
	
	# print rest trunks
	print ">" x ($trunk_ceil - $trunk_received);
	print " " x ($screen_limit_trunk - $trunk_ceil) if $res->is_success;

	# status processing
	$self->{get_lasturl}=$url if $res->is_success;
	$self->{get_agent_cur}=0 if ++$self->{get_agent_cur} >= @{$self->{get_agent_array}};
	if( $res->is_success and $self->{get_save_file} ){
		#debug writing
		$self->file_writebin('debug',
			catfile($self->{get_file_directory_save}, $self->{get_visited_url_num}.'.htm'),
			$res->content);
	}
	return $res;
}
sub get_fail {
	my $self = shift;
	my $msgid = shift;
	my $url_real="";
	$url_real=$_[0]->request->uri->as_string if defined($_[0]->request->uri);
	$self->log_add($msgid.$self->{get_fail_showtype}, {
		code		=>	$_[0]->code,
		req_content	=>	$_[0]->request->as_string,
		status_line	=>	$_[0]->status_line,
		res_content	=>	$_[0]->as_string,
		url_real	=>	$url_real,
	});
}

#-------------------------------------------------------------
# Parser utility functions
#	$bot->normalize_space($content_dein_deout)			=> N/A
#	$bot->remove_html($content_dein_deout)				=> N/A
#	$bot->decode_entity($content_dein_deout)			=> N/A
#	$bot->normalize_paragraph_1($content_dein_deout)	=> N/A
#	$bot->parse_title($content_dein_deout)				=> $content_deout
#	$bot->parse_titleen($content_dein_deout)			=> $content_enout
#	$bot->normalize_paragraph($content_dein_deout)		=> N/A
#		$bot->remove_line_by_end($content_dein_deout)
#		$bot->parse_paragraph_br($content_dein_deout)
#		$bot->parse_paragraph_brbr($content_dein_deout)
#		$bot->parse_paragraph_brandspace($content_dein_deout)
#		$bot->parse_paragraph_brbr_or_brandspace($content_dein_deout)
#		$bot->parse_paragraph_cr($content_dein_deout)
#		$bot->parse_paragraph_crcr($content_dein_deout)
#		$bot->parse_paragraph_crandspace($content_dein_deout)
#		$bot->remove_leadingspace($content_dein_deout)
#		$bot->remove_innerspace($content_dein_deout)
#-------------------------------------------------------------
sub normalize_space {
	$_[1]=~s/$_[0]->{patterns}->{space}/ /osg;
	$_[1]=~s/$_[0]->{patterns}->{space2}/  /osg;
}
sub remove_html {
	$_[1]=~s/$_[0]->{patterns}->{remove_html}//osg;
	$_[1]=~s/<[^<>]*>//osg;
}
sub decode_entity {
	$_[1]=~s/(?:&\#(\d{1,5});?)/chr($1)/esg;
	$_[1]=~s/(?:&\#[xX]([0-9a-fA-F]{1,5});?)/chr(hex($1))/esg;
	$_[1]=~s/(&([0-9a-zA-Z]{1,9});?)/$entity2char{$2} or $1/esg;
}
sub normalize_paragraph_1 {
	$_[1]=~s/^ +/ /mg;								#normalize spaces before paragraph
	$_[1]=~s/ +$//mg;								#remove spaces after paragraph
	$_[1]=~s/^ ?(?:$_[0]->{patterns}->{mark_dash} *){2,}/ ---/omg;
													#normalize repeated dash
	$_[1]=~s/\n{2,}/\n/sg;							#remove empty paragraph
	$_[1]=~s/(?: ---\n?){2,}/ ---\n/sg;				#remove too much dash line
	$_[1]=~s/(?:^\n|\n$)//s;						#remove leading and ending \n
	$_[1]=~s/$_[0]->{patterns}->{word_finish}//os;	#remove finish words
	$_[1]=~s/\n$//s;								#remove ending \n
}
sub parse_title {
	$_[0]->normalize_space($_[1]);
	$_[0]->remove_html($_[1]);
	$_[0]->decode_entity($_[1]);
	$_[1]=~s/\n+/ /sg;	# CRLF as space
	$_[0]->normalize_paragraph_1($_[1]);
	$_[1]=~s/ +/ /sg;	#remove extra spaces

	#remove ending space or wordsplit mark
	my $p1=$_[0]->{patterns}->{mark_wordsplit};
	$p1=~s/(?:^\[|\]$)//sg;
	$p1="[".$p1." ]";
	$_[1]=~s/$p1+$//os;

	#remove paraentheses
	$_[1]=~s/(?:^ +| +$)//sg;
	while($_[1]=~/^(?:$_[0]->{patterns}->{parentheses})$/os) {
		$_[1]=$^N;
		$_[1]=~s/(?:^ +| +$)//sg;
	}
	
	$_[1];
}
sub parse_titleen {
	$_[0]->en_code($_[0]->parse_title($_[1]));
}
sub normalize_paragraph {
	$_[0]->normalize_space($_[1]);
	$_[0]->parse_paragraph_begin($_[1]);
	my $sub="parse_paragraph_".$_[0]->{text_paragraph_type};
	$_[0]->$sub($_[1]);
	$_[0]->remove_html($_[1]);
	$_[0]->decode_entity($_[1]);
	$_[0]->normalize_paragraph_1($_[1]);
	$_[0]->remove_line_by_end($_[1]);
	$_[0]->normalize_paragraph_1($_[1]);
	$_[0]->parse_paragraph_end($_[1]);
	$_[1]=~s/ ?\$BOOKBOTRETURN\$//sg;		#remove for reserved return
	$sub='$_[1]=~s/^ /'.$_[0]->{patterns}->{line_head}.'/mg;'; #normalize with 4 spaces
	eval $sub;
}
sub remove_line_by_end {
	$_[1]=~s/(?:---\n|\n).*(?:$_[0]->{patterns}->{remove_line_by_end})$_[0]->{patterns}->{parentheses_right}?$//omg;
	$_[1]=~s/\n $_[0]->{patterns}->{remove_line_by_end_special}$//osg;
}
sub parse_paragraph_br {
	$_[1]=~s/\n//sg;
	$_[1]=~s/<[bB][rR]> */\n /sg;
}
sub parse_paragraph_brbr {
	$_[1]=~s/\n//sg;
	$_[1]=~s/(?:<[bB][rR]> *){2,}/\n /sg;
}
sub parse_paragraph_brandspace {
	$_[1]=~s/\n//sg;
	$_[1]=~s/<[bB][rR]>(?=[^ ])//sg;
	$_[1]=~s/<[bB][rR]> */\n /sg;
}
sub parse_paragraph_brbr_or_brandspace {
	$_[1]=~s/\n//sg;
	$_[1]=~s/<[bB][rR]>(?=[^ <])//sg;
	$_[1]=~s/(?:<[bB][rR]> *){1,}/\n /sg;
}
sub parse_paragraph_br_or_p {
	$_[1]=~s/\n/ /sg;
	$_[1]=~s/<[bB\/][rRpP]>/\n/sg;
}
sub parse_paragraph_cr {
}
sub parse_paragraph_crcr {
	$_[1]=~s/(?<=[^\n])\n(?=[^\n])//sg;		#remove single \n
	$_[1]=~s/\n{2,}/\n/sg;					#change multiple \n into one \n
}
sub parse_paragraph_crandspace {
	$_[1]=~s/\n(?=[^ ])//sg;				#remove \n without " " followed
}
sub remove_leadingspace {
	my $self = shift;
	return if not $self->{space_leading_remove};
	for(my $i=$self->{space_leading_max}; $i>0; $i--) {
		my $spaces=" " x $i;
		my $linefollow=$spaces."[^ ].*?\n";
		if( $_[0]=~/\n$spaces .*?\n$linefollow$linefollow$linefollow/o ) {
			$_[0]=~s/\n$spaces/\n/og;
			return;
		}
	}
}
sub remove_innerspace {
	my $self = shift;
	return if not $self->{space_inner_remove};

	my $pattern='\w ' x $self->{space_inner_min_words};
	return if not $_[0]=~/$pattern/o;

	my ($str) = @_;
	$pattern=$self->{patterns}->{mark_wordsplit};
	$pattern=~s/\|//og;
	$_[0]=~s/(?<=[^$pattern\s])\s(?=\S)//omg;
	$_[0]=~s/(?<=\S)\s\s(?=\S)/ /omg;
}

#-------------------------------------------------------------
# Parser main functions
#	$bot->go_catalog(\%args)							=> $booknum
#		url
#	$bot->catalog_get_book(\%args, $content_dein)		=> @books
#	$bot->catalog_get_next(\%args, $content_dein)		=> $booknum, 0-no next
#	$bot->go_book(\%args)								=> $content_de
#		level, bpos, book_num, url, title
#	$bot->book_html(\%args, $content_enin_deout)		=> N/A
#	$bot->book_text(\%args, $content_enin_deout)		=> N/A
#	$bot->book_bin(\%args, $content_enin_deout)			=> N/A
#	$bot->book_writebin(\%args, $content_bin)			=> $filebasename_de
#	$bot->book_chapters(\%args, $content_dein)			=> @chapters
#		() means this is a chapter or wrong
#		({url=>..., title=>..., ...}, {}) means chapters
#	$bot->TOC_parser(\%args, $content_dein_deout)		=> N/A
#	$bot->chapter_process(\%args, $content_dein_deout)	=> N/A
#	$bot->chapter_parser(\%args, $content_dein_deout)	=> N/A
#-------------------------------------------------------------
sub go_catalog {
	my ($self, $pargs) = @_;
	$pargs={} if not(ref($pargs));
	my %args_orig=%$pargs;							#keep original args
	$pargs->{url}=$self->msg_format('CatalogURL', $pargs);
	$self->log_add('CatalogInfo', $pargs);
	
	# Get it
	if( $pargs->{url} eq '' ) {
		$self->log_add('CatalogURLEmpty', $pargs);
		return 0;
	}
	my $res=$self->get_url($pargs->{url});
	if( not($res->is_success) ) {
		$self->db_add("catalog", "Err", \%args_orig);
		return 0;
	}
	$pargs->{url_real}=$res->request->uri->as_string;
	$pargs->{url_base}=$res->base->as_string;
	my $str=$self->de_code($res->content);
	undef $res;
	$str=~s/\r\n|\r/\n/sg;
	my $str_all=$str;

	# Parse books
	$str=~s/^.*?$self->{patterns}->{catalog_head}//os if $self->{patterns}->{catalog_head} ne '';
	$str=~s/$self->{patterns}->{catalog_end}.*$//os if $self->{patterns}->{catalog_end} ne '';
	my @books=$self->catalog_get_book($pargs, $str);
	undef $str;
	$pargs->{book_num}=scalar(@books);
	$self->log_add('CatalogResult'.($pargs->{book_num}>0 ? 'OK' : 'Err'), $pargs);
	$self->db_add("catalog", $pargs->{book_num}>0 ? 'OK' : 'Err', \%args_orig);
	
	# Parse next area
	my $go_next=$self->catalog_get_next($pargs, $str_all);
	undef $str_all;

	# Get books
	for(my $bpos=0; $bpos<$pargs->{book_num}; $bpos++) {
		$books[$bpos]->{book_num}=$pargs->{book_num};
		$books[$bpos]->{bpos}=$bpos+1;
		$self->go_book($books[$bpos]);
	}
	
	return $go_next;
}
sub catalog_get_book {
	my ($self, $pargs) = (shift, shift);
	my @books = ();
	while($_[0]=~/$self->{patterns}->{catalog_get_bookargs}/osg) {
		my $pargs1={};
		next if $self->catalog_get_bookargs($pargs1, $1, $2, $3, $4, $5, $6, $7, $8, $9) eq 'Skip';
		$pargs1->{url}=$self->url_rel2abs($pargs1->{url}, $pargs->{url_base});
		push @books, $pargs1;
	}
	return @books;
}
sub catalog_get_next {
	my ($self, $pargs) = (shift, shift);
	return $pargs->{book_num} if $self->{patterns}->{catalog_get_next} eq '';
	return $_[0]=~/$self->{patterns}->{catalog_get_next}/os ? $pargs->{book_num} : 0;
}
sub go_book {
	my ($self, $pargs) = @_;
	$pargs->{level}=0 if $pargs->{level} eq '';
	my %args_orig=%$pargs if $pargs->{level}==0;	#keep original args
	$pargs->{bpos}=0 if $pargs->{bpos} eq '';
	$pargs->{url}=~s/\#.*$//;						#Remove references in url
	$pargs->{levelspace} = "  " x $pargs->{level};	#caculate spaces to purify log output
	$pargs->{bpos_limit}=sprintf("%0".length($pargs->{book_num})."d", $pargs->{bpos});
	$pargs->{title_limit}=$self->string_limit($pargs->{title}, $self->{screen_limit_title});
	$self->log_add("BookStart", $pargs);

	# Skip some special urls
	if($pargs->{level}>$self->{book_max_levels})
		{$self->log_add("SkipMaxLevel", $pargs); return "";}
	if($pargs->{title} eq '')
		{$self->log_add("SkipTitleEmpty", $pargs); return "";}
	if($pargs->{url} eq '')
		{$self->log_add("SkipUrlEmpty", $pargs); return "";}
	if($self->{get_skip_zip} and $pargs->{url}=~/(?:$self->{patterns}->{postfix_zip})$/i)
		{$self->log_add("SkipZip", $pargs); return "";}
	if($self->{get_skip_media} and $pargs->{url}=~/(?:$self->{patterns}->{postfix_media})$/i)
		{$self->log_add("SkipMedia", $pargs); return "";}
	if(defined($self->{DB_visited_book}->{$pargs->{url}}))
		{$self->log_add("SkipVisited", $pargs); return "";}

	# Get URL
	my $res=$self->get_url($pargs->{url});
	if(not($res->is_success)) {
		$self->db_add("book", "Err", \%args_orig) if $pargs->{level}==0;
		return "";
	}
	my $str=$res->content;
	$pargs->{content_type}=$res->headers->content_type;
	$pargs->{content_len}=length($str);
	$pargs->{last_modified}=$res->headers->last_modified;
	$pargs->{last_modified_str}=HTTP::Date::time2iso($res->headers->last_modified);
	$pargs->{url_real}=$res->request->uri->as_string;
	$pargs->{url_base}=$res->base->as_string;
	my $url1=$pargs->{url_real};
	$url1=~s/\?.*$//;
	$pargs->{ext_real}=($url1=~/\.([^\.]+)$/) ? lc($1) : "";
	$pargs->{ext_save}=$pargs->{ext_real};
	if( $pargs->{ext_save}=~/^(?:$self->{patterns}->{postfix_free}|)$/ ) {
		# file extension cannot be confirmed, since it's cgi
		$pargs->{ext_save}=$self->{Content_Type}->{$pargs->{content_type}};	#try to new_bot via content-type
		$pargs->{ext_save}='txt' if $pargs->{ext_save} eq '';				#add default txt if fail
	}
	undef $res;

	# html/text/bin
	if( $pargs->{content_len}>0 ) {
		if($pargs->{ext_real} eq 'txt') {
			$self->book_text($pargs, $str);
		} elsif($pargs->{content_type} eq 'text/html') {
			$self->book_html($pargs, $str);
		} else {
			$self->book_bin($pargs, $str);
		}
	}
	$self->db_add("book", (length($str)==0) ? 'Err' : 'OK', \%args_orig) if $pargs->{level}==0;
	return $str;
}
sub book_html {
	my ($self, $pargs) = (shift, shift);

	# check 1 chapter or more, return if 1 chapter
	$_[0]=$self->de_code($_[0]);
	$_[0]=~s/\r\n|\r/\n/og;
	my @chapters=$self->book_chapters($pargs, $_[0]);
	$pargs->{chapter_num}=scalar(@chapters);
	$pargs->{chapter_num_limit}=sprintf("%04d", $pargs->{chapter_num});
	if( $pargs->{chapter_num}==0 ){
		$self->log_add("BookChapterOne", $pargs);
		$self->chapter_process($pargs, $_[0]);
		return;
	}
	$self->log_add("BookChapterMany", $pargs);

	# initialize result file to put TOC
	$self->{book_get_num}++;
	my $filename=$self->result_init($pargs);
	$pargs->{filename}=$filename;

	# parse TOC and save it
	$self->TOC_parser($pargs, $_[0]);
	my $out_en=$self->en_code($_[0]);
	$self->result_add($filename, $out_en);
	$pargs->{TOC_len}=length($out_en);
	$pargs->{TOC_len_KB}=$self->len_KB($pargs->{TOC_len});
	$self->log_add("BookTOCFinish", $pargs);

	# parse other chapters
	for(my $bpos=0; $bpos<$pargs->{chapter_num}; $bpos++) {
		$chapters[$bpos]->{level}=$pargs->{level}+1;
		$chapters[$bpos]->{book_num}=$pargs->{chapter_num};
		$chapters[$bpos]->{bpos}=$bpos+1;
		$self->result_add( $filename, "\n\n" );
		$self->result_adden( $filename, $self->go_book($chapters[$bpos]) );
	}
	$self->book_finish($pargs);

	# finish work
	my $result_time=$self->result_time($pargs);
	$self->result_settime($filename, $result_time) if defined($result_time);
}
sub book_text {
	my ($self, $pargs) = (shift, shift);
	$_[0]=$self->de_code($_[0]);
	$_[0]=~s/\r\n|\r/\n/og;
	$self->chapter_process($pargs, $_[0]);
}
sub book_bin {
	my ($self, $pargs) = (shift, shift);
	$pargs->{data_len}=length($_[0]);
	$pargs->{data_len_KB}=$self->len_KB($pargs->{data_len});
	return if $pargs->{data_len}==0;
	$pargs->{write_file}=$self->book_writebin($pargs, $_[0]);
	$self->log_add("BookBinaryOK", $pargs);
	$_[0]="[$pargs->{write_file}]";
}
sub book_writebin {
	my ($self, $pargs) = (shift, shift);
	my $filename=$self->result_filename($pargs);
	$self->file_writebin("result", $filename, $_[0]);
	my $result_time=$self->result_time($pargs);
	$self->result_settime($filename, $result_time) if defined($result_time);
	return $self->de_code(basename($filename));
}
sub book_chapters {
	my ($self, $pargs, $str) = @_;
	return () if $self->{book_has_chapters}==0;
	return () if $self->{patterns}->{TOC_exists} ne '' and not($str=~/$self->{patterns}->{TOC_exists}/os);
	$str=~s/^.*?$self->{patterns}->{chapters_head}//os if $self->{patterns}->{chapters_head} ne '';
	$str=~s/$self->{patterns}->{chapters_end}.*$//os if $self->{patterns}->{chapters_end} ne '';
	
	my @chapters = ();
	while($str=~/$self->{patterns}->{chapters_get_chapterargs}/oisg) {
		my $pargs1={};
		next if $self->chapters_get_chapterargs($pargs1, $1, $2, $3, $4, $5, $6, $7, $8, $9) eq 'Skip';
		$pargs1->{url}=$self->url_rel2abs($pargs1->{url}, $pargs->{url_base});
		push @chapters, $pargs1;
	}
	return @chapters;
}
sub TOC_parser {
	$_[2]=~s/^.*?$_[0]->{patterns}->{TOC_head}//os if $_[0]->{patterns}->{TOC_head} ne '';
	$_[2]=~s/$_[0]->{patterns}->{TOC_end}.*$//os if $_[0]->{patterns}->{TOC_end} ne '';
	$_[0]->normalize_paragraph($_[2]);
}
sub chapter_process {
	my ($self, $pargs) = (shift, shift);
	$self->chapter_parser($pargs, $_[0]);
	my $out_en=$self->en_code($_[0]);
	$pargs->{data_len}=length($out_en);
	$pargs->{data_len_KB}=$self->len_KB($pargs->{data_len});
	if( $pargs->{level}==0 and $pargs->{data_len}>0 ) {	# save single chapter as a book
		$self->{book_get_num}++;
		my $filename=$self->result_init($pargs);
		$pargs->{filename}=$filename;
		$self->result_add($filename, $out_en);
		$self->book_finish($pargs);
		my $result_time=$self->result_time($pargs);
		$self->result_settime($filename, $result_time) if defined($result_time);
		$pargs->{write_file}=$self->de_code(basename($filename));
	} else {
		$pargs->{write_file}="";
	}
	$self->log_add("BookChapter".(($pargs->{data_len}>0)?"OK":"Err"), $pargs);
	$_[0]="[$pargs->{write_file}]" if $pargs->{level}==0 and $pargs->{data_len}>0;
}
sub chapter_parser {
	$_[2]=~s/^.*?$_[0]->{patterns}->{chapter_head}//os if $_[0]->{patterns}->{chapter_head} ne '';
	$_[2]=~s/$_[0]->{patterns}->{chapter_end}.*$//os if $_[0]->{patterns}->{chapter_end} ne '';
	$_[0]->normalize_paragraph($_[2]);
}

#-------------------------------------------------------------
# pattern initialize functions
#-------------------------------------------------------------
sub getpattern_lists {
	qw(
		space space2 line_head parentheses mark_dash mark_wordsplit
		remove_html remove_line_by_end remove_line_by_end_special word_finish
		postfix_zip postfix_media postfix_img postfix_free
		catalog_head catalog_end catalog_get_bookargs catalog_get_next
		chapters_head chapters_end chapters_get_chapterargs
		TOC_exists TOC_head TOC_end
		chapter_head chapter_end
	);
}
sub getpattern_space_data {
	<<"DATA";
[\000-\011\013-\037]
DATA
}
sub getpattern_space2_data {
	<<"DATA";
^\000\000
DATA
}
sub getpattern_line_head_data {
	'    ';
}
sub getpattern_parentheses {
	my $self = shift;
	my ($left, $right);
	my $pattern='';
	my $pattern_left='';
	my $pattern_right='';
	foreach(split /\r\n|\r|\n/, $self->de_code($self->getpattern_parentheses_data)) {
		next if $_ eq '';
		($left, $right)=split(/ /, $_);
		$pattern.=$left."(.*)".$right."|";
		$pattern_left.=$left;
		$pattern_right.=$right;
	}
	$pattern=~s/\|$//;
	$self->{patterns}->{parentheses_left}='['.$pattern_left.']';
	$self->{patterns}->{parentheses_right}='['.$pattern_right.']';
	return $pattern;
}
sub getpattern_parentheses_data {
	<<'DATA';
\( \)
\[ \]
\{ \}
\" \"
\' \'
\` \`
DATA
}
sub getpattern_mark_dash_data {
	<<'DATA';
[#-&\*\+\-=@_~]
DATA
}
sub getpattern_mark_wordsplit_data {
	<<'DATA';
[\.\,\?\!\:\;]
DATA
}
sub getpattern_remove_html_data {
	<<'DATA';
<head.*?</head>
<script.*?</script>
<title.*?</title>
<style.*?</style>
<!--.*?-->
DATA
}
sub getpattern_remove_line_by_end_data {
	<<'DATA';
\000
DATA
}
sub getpattern_remove_line_by_end_special {
	my $self=shift;
	my $special=$self->parse_patterns($self->getpattern_remove_line_by_end_special_data);
	my $left=$self->{patterns}->{parentheses_left};
	$left=~s/(?:^\[|\]$)//sg;
	"[^ \n]{1,8}?[$special][ $left][^\n]*";
}
sub getpattern_remove_line_by_end_special_data {
	<<'DATA';
\000
DATA
}
sub getpattern_word_finish {
	my $self = shift;
	my ($t, $result);
	$result=" *";
	$t=$self->{patterns}->{parentheses_left};
	$t=~s/\]$//;
	$result.=$t;
	$t=$self->{patterns}->{mark_dash};
	$t=~s/^\[//;
	$result.=$t."? *";

	$result.="(?:".$self->parse_patterns($self->getpattern_word_finish_data).") *";

	$t=$self->{patterns}->{parentheses_right};
	$t=~s/\]$//;
	$result.=$t;
	$t=$self->{patterns}->{mark_dash};
	$t=~s/^\[//;
	$result.=$t."?\$";
}
sub getpattern_word_finish_data {
	<<'DATA';
\000
DATA
}
sub getpattern_postfix_zip {
	return shift->parse_patterns(<<'DATA');
^case$
zip
r(?:a[rx]|\d\d)
z
gz
t[ga]z
7z
a\d\d
ace
ain
akt
ap[qx]
ar(?:[jc]|)
asd
bh
bi[nx]
bz2
cab
cfd
class
com
cru
cpio
cpt
dcf
ddi
dpa
dsk
dup
dwc
eli
enc
esp
exe
f
ha(?:p|)
hex
hp[ak]
hqx
hyp
ice
im[gp]
is[co]
jar
jrc
lbr
lha
lz[ahwx]
mar
mime
pak
pk3
pz[hk]
q
qfc
saif
sar
sbx
sdn
sea
shar
sit
sqz
td0
uc2
ufa
uu(?:u|)
xxe
zoo
DATA
}
sub getpattern_postfix_media {
	return shift->parse_patterns(<<'DATA');
avi
as[fx]
r(?:m|am|a)
mov(?:ie|)
mp(?:\d|eg|ga|g)
wma
wav
3ds
aif(?:[cf]|)
au
cd(?:a|)
code
d[cix]r
fl[cit]
fon
kar
m3u
mid(?:i|)
qt
r[fp]
scr
snd
spl
swf
tt[cf]
DATA
}
sub getpattern_postfix_img {
	return shift->parse_patterns(<<'DATA');
gif
jp(?:eg|e|g)
png
ani
ai
ais
art
bmp
bw
ddf
dib
col
crw
cur
dcx
djv(?:u|)
dwg
dxf
emf
fpx
ic[lno]
ief
iff
ilbm
int(?:a|)
iw4
jfif
kdc
lbm
mag
pc[dxt]
pic(?:t|)
pix
p[nbgp]m
pntg
ps[dp]
qtif
ras
rgb(?:a|)
rle
rsb
sgi
sid
svg
targa
tga
thm
tif(?:f|)
yuv
wbmp
wmf
x[bp]m
xif
xwd
DATA
}
sub getpattern_postfix_free {
	return shift->parse_patterns(<<'DATA');
htm(?:l|)
cgi
jsp
asp(?:x|)
php(?:\d|)
cfm
phtml
pl
nph
fcgi
ht[ac]
DATA
}
sub contenttype_init {
	shift->{Content_Type} = {
		'text/plain'					=> 'txt',
		'text/html'						=> 'txt',
		'image/jpeg'					=> 'jpg',
		'image/png'						=> 'png',
		'image/gif'						=> 'gif',
		'application/ami'				=> 'ami',
		'application/caa'				=> 'caa',
		'application/caj'				=> 'caj',
		'application/cas'				=> 'cas',
		'application/cdf'				=> 'cdf',
		'application/andrew-inset'		=> 'ez',
		'application/fractals'			=> 'fif',
		'application/futuresplash'		=> 'spl',
		'application/kdh'				=> 'kdh',
		'application/mac-binhex40'		=> 'hqx',
		'application/mac-compactpro'	=> 'cpt',
		'application/msaccess'			=> 'mdb',
		'application/msword'			=> 'doc',
		'application/nh'				=> 'nh',
		'application/octet-stream'		=> 'exe',
		'application/oda'				=> 'oda',
		'application/pdf'				=> 'pdf',
		'application/pkcs10'			=> 'p10',
		'application/pkcs7-mime'		=> 'p7m',
		'application/pkcs7-signature'	=> 'p7s',
		'application/pkix-cert'			=> 'cer',
		'application/pkix-crl'			=> 'crl',
		'application/postscript'		=> 'ps',
		'application/rat-file'			=> 'rat',
		'application/sdp'				=> 'sdp',
		'application/set-payment-initiation'		=> 'setpay',
		'application/set-registration-initiation'	=> 'setreg',
		'application/smil'				=> 'smil',
		'application/streamingmedia'	=> 'ssm',
		'application/vnd.adobe.xfdf'	=> 'xfdf',
		'application/vnd.fdf'			=> 'fdf',
		'application/vnd.mif'			=> 'mif',
		'application/vnd.ms-excel'		=> 'xls',
		'application/vnd.ms-mediapackage'			=> 'mpf',
		'application/vnd.ms-pki.certstore'			=> 'sst',
		'application/vnd.ms-pki.pko'	=> 'pko',
		'application/vnd.ms-pki.seccat'	=> 'cat',
		'application/vnd.ms-pki.stl'	=> 'stl',
		'application/vnd.ms-powerpoint'	=> 'ppt',
		'application/vnd.ms-project'	=> 'mpp',
		'application/vnd.ms-wpl'		=> 'wpl',
		'application/vnd.rn-realmedia'	=> 'rm',
		'application/vnd.rn-realmedia-vbr'			=> 'rmvb',
		'application/vnd.rn-realplayer'	=> 'rnx',
		'application/vnd.rn-realsystem-rjs'			=> 'rjs',
		'application/vnd.rn-realsystem-rmx'			=> 'rmx',
		'application/vnd.rn-rn_music_package'		=> 'rmp',
		'application/vnd.rn-rsml'		=> 'rsml',
		'application/vnd.visio'			=> 'vsd',
		'application/vnd.wap.wbxml'		=> 'wbxml',
		'application/vnd.wap.wmlc'		=> 'wmlc',
		'application/vnd.wap.wmlscriptc'			=> 'wmlsc',
		'application/xhtml+xml'			=> 'xhtml',
		'application/xml'				=> 'xml',
		'application/xml-dtd'			=> 'dtd',
		'application/x-ami'				=> 'ami',
		'application/x-bcpio'			=> 'bcpio',
		'application/x-ccf'				=> 'ccf',
		'application/x-cdf'				=> 'cdf',
		'application/x-cdlink'			=> 'vcd',
		'application/x-ceb'				=> 'ceb',
		'application/x-cef'				=> 'cef',
		'application/x-chess-pgn'		=> 'png',
		'application/x-compress'		=> 'z',
		'application/x-compressed'		=> 'tgz',
		'application/x-cpio'			=> 'cpio',
		'application/x-csh'				=> 'csh',
		'application/x-director'		=> 'dir',
		'application/x-dvi'				=> 'dvi',
		'application/x-futuresplash'	=> 'spl',
		'application/x-gtar'			=> 'gtar',
		'application/x-gzip'			=> 'gz',
		'application/x-hdf'				=> 'hdf',
		'application/x-internet-signup'	=> 'ins',
		'application/x-iphone'			=> 'iii',
		'application/x-javascript'		=> 'js',
		'application/x-java-jnlp-file'	=> 'jnlp',
		'application/x-koan'			=> 'skp',
		'application/x-latex'			=> 'latex',
		'application/x-netcdf'			=> 'cdf',
		'application/x-mix-transfer'	=> 'nix',
		'application/x-msdownload'		=> 'exe',
		'application/x-mplayer2'		=> 'asx',
		'application/x-msexcel'			=> 'xls',
		'application/x-mspowerpoint'	=> 'ppt',
		'application/x-ms-wmd'			=> 'wmd',
		'application/x-ms-wms'			=> 'wms',
		'application/x-ms-wmz'			=> 'wmz',
		'application/x-pkcs12'			=> 'p12',
		'application/x-pkcs7-certificates'			=> 'p7b',
		'application/x-pkcs7-certreqresp'			=> 'p7r',
		'application/x-quicktimeplayer'	=> 'qtl',
		'application/x-rtsp'			=> 'rtsp',
		'application/x-sdp'				=> 'sdp',
		'application/x-sh'				=> 'sh',
		'application/x-shar'			=> 'shar',
		'application/x-shockwave-flash'	=> 'swf',
		'application/x-stuffit'			=> 'sit',
		'application/x-sv4cpio'			=> 'sv4cpio',
		'application/x-sv4crc'			=> 'sv4crc',
		'application/x-tar'				=> 'tar',
		'application/x-tcl'				=> 'tcl',
		'application/x-tex'				=> 'tex',
		'application/x-texinfo'			=> 'texinfo',
		'application/x-troff'			=> 'tr',
		'application/x-troff-man'		=> 'man',
		'application/x-troff-me'		=> 'me',
		'application/x-troff-ms'		=> 'ms',
		'application/x-ustar'			=> 'ustar',
		'application/x-wais-source'		=> 'src',
		'application/x-x509-ca-cert'	=> 'cer',
		'application/x-zip-compressed'	=> 'zip',
		'application/zip'				=> 'zip',
		'audio/aiff'					=> 'aiff',
		'audio/basic'					=> 'au',
		'audio/mid'						=> 'mid',
		'audio/midi'					=> 'mid',
		'audio/mp3'						=> 'mp3',
		'audio/mp4'						=> 'mp4',
		'audio/mpeg'					=> 'mp3',
		'audio/mpegurl'					=> 'm3u',
		'audio/mpg'						=> 'mp3',
		'audio/vnd.qcelp'				=> 'qcp',
		'audio/vnd.rn-realaudio'		=> 'ra',
		'audio/wav'						=> 'wav',
		'audio/x-aiff'					=> 'aiff',
		'audio/x-gsm'					=> 'gsm',
		'audio/x-mid'					=> 'mid',
		'audio/x-midi'					=> 'mid',
		'audio/x-mp3'					=> 'mp3',
		'audio/x-mpeg'					=> 'mp3',
		'audio/x-mpegurl'				=> 'm3u',
		'audio/x-mpg'					=> 'mp3',
		'audio/x-ms-wax'				=> 'wax',
		'audio/x-ms-wma'				=> 'wma',
		'audio/x-pn-realaudio'			=> 'ram',
		'audio/x-realaudio'				=> 'ra',
		'audio/x-wav'					=> 'wav',
		'chemical/x-pdb'				=> 'pdb',
		'chemical/x-xyz'				=> 'xyz',
		'image/bmp'						=> 'bmp',
		'image/ief'						=> 'ief',
		'image/pict'					=> 'pict',
		'image/pjpeg'					=> 'jpg',
		'image/svg'						=> 'svg',
		'image/svg+xml'					=> 'svg',
		'image/svg-xml'					=> 'svg',
		'image/tiff'					=> 'tif',
		'image/vnd.djvu'				=> 'djvu',
		'image/vnd.dwg'					=> 'dwg',
		'image/vnd.dxf'					=> 'dxf',
		'image/vnd.rn-realflash'		=> 'rf',
		'image/vnd.rn-realpix'			=> 'rp',
		'image/vnd.wap.wbmp'			=> 'wbmp',
		'image/xbm'						=> 'xbm',
		'image/x-cmu-raster'			=> 'ras',
		'image/x-icon'					=> 'ico',
		'image/x-macpaint'				=> 'pntg',
		'image/x-pict'					=> 'pict',
		'image/x-png'					=> 'png',
		'image/x-portable-anymap'		=> 'pnm',
		'image/x-portable-bitmap'		=> 'pbm',
		'image/x-portable-graymap'		=> 'pgm',
		'image/x-portable-pixmap'		=> 'ppm',
		'image/x-quicktime'				=> 'qtif',
		'image/x-rgb'					=> 'rgb',
		'image/x-sgi'					=> 'sgi',
		'image/x-targa'					=> 'targa',
		'image/x-tiff'					=> 'tif',
		'image/x-xbitmap'				=> 'xbm',
		'image/x-xpixmap'				=> 'xpm',
		'image/x-xwindowdump'			=> 'xwd',
		'interface/x-winamp3-skin'		=> 'wal',
		'interface/x-winamp-skin'		=> 'wal',
		'midi/mid'						=> 'mid',
		'model/iges'					=> 'iges',
		'model/mesh'					=> 'mesh',
		'model/vnd.dwf'					=> 'dwf',
		'model/vrml'					=> 'vrml',
		'text/calendar'					=> 'ics',
		'text/css'						=> 'css',
		'text/h323'						=> '323',
		'text/iuls'						=> 'uls',
		'text/richtext'					=> 'rtx',
		'text/rtf'						=> 'rtf',
		'text/sgml'						=> 'sgml',
		'text/tab-separated-values'		=> 'tsv',
		'text/scriptlet'				=> 'wsc',
		'text/vnd.rn-realtext'			=> 'rt',
		'text/vnd.wap.wml'				=> 'wml',
		'text/vnd.wap.wmlscript'		=> 'wmls',
		'text/xml'						=> 'xml',
		'text/x-ms-iqy'					=> 'iqy',
		'text/x-ms-odc'					=> 'odc',
		'text/x-ms-rqy'					=> 'rqy',
		'text/x-setext'					=> 'etx',
		'text/x-vcard'					=> 'vcf',
		'video/avi'						=> 'avi',
		'video/flc'						=> 'flc',
		'video/mp4'						=> 'mp4',
		'video/mpeg'					=> 'mpg',
		'video/mpg'						=> 'mpg',
		'video/msvideo'					=> 'avi',
		'video/quicktime'				=> 'mov',
		'video/vnd.mpegurl'				=> 'mxu',
		'video/vnd.rn-realvideo'		=> 'rv',
		'video/x-ivf'					=> 'ivf',
		'video/x-mpeg'					=> 'mpg',
		'video/x-mpeg2a'				=> 'mpg',
		'video/x-ms-asf'				=> 'asf',
		'video/x-ms-asf-plugin'			=> 'asx',
		'video/x-msvideo'				=> 'avi',
		'video/x-ms-wm'					=> 'wm',
		'video/x-ms-wmp'				=> 'wmp',
		'video/x-ms-wmv'				=> 'wmv',
		'video/x-ms-wmx'				=> 'wmx',
		'video/x-ms-wvx'				=> 'wvx',
		'video/x-sgi-movie'				=> 'movie',
		'x-conference/x-cooltalk'		=> 'ice',
	};
}
%entity2char = (	# copied from HTML::Entities
 # Some normal chars that have special meaning in SGML context
 amp    => '&',  # ampersand 
'gt'    => '>',  # greater than
'lt'    => '<',  # less than
 quot   => '"',  # double quote
 apos   => "'",  # single quote

 # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
 AElig	=> 'Æ',  # capital AE diphthong (ligature)
 Aacute	=> 'Á',  # capital A, acute accent
 Acirc	=> 'Â',  # capital A, circumflex accent
 Agrave	=> 'À',  # capital A, grave accent
 Aring	=> 'Å',  # capital A, ring
 Atilde	=> 'Ã',  # capital A, tilde
 Auml	=> 'Ä',  # capital A, dieresis or umlaut mark
 Ccedil	=> 'Ç',  # capital C, cedilla
 ETH	=> 'Ð',  # capital Eth, Icelandic
 Eacute	=> 'É',  # capital E, acute accent
 Ecirc	=> 'Ê',  # capital E, circumflex accent
 Egrave	=> 'È',  # capital E, grave accent
 Euml	=> 'Ë',  # capital E, dieresis or umlaut mark
 Iacute	=> 'Í',  # capital I, acute accent
 Icirc	=> 'Î',  # capital I, circumflex accent
 Igrave	=> 'Ì',  # capital I, grave accent
 Iuml	=> 'Ï',  # capital I, dieresis or umlaut mark
 Ntilde	=> 'Ñ',  # capital N, tilde
 Oacute	=> 'Ó',  # capital O, acute accent
 Ocirc	=> 'Ô',  # capital O, circumflex accent
 Ograve	=> 'Ò',  # capital O, grave accent
 Oslash	=> 'Ø',  # capital O, slash
 Otilde	=> 'Õ',  # capital O, tilde
 Ouml	=> 'Ö',  # capital O, dieresis or umlaut mark
 THORN	=> 'Þ',  # capital THORN, Icelandic
 Uacute	=> 'Ú',  # capital U, acute accent
 Ucirc	=> 'Û',  # capital U, circumflex accent
 Ugrave	=> 'Ù',  # capital U, grave accent
 Uuml	=> 'Ü',  # capital U, dieresis or umlaut mark
 Yacute	=> 'Ý',  # capital Y, acute accent
 aacute	=> 'á',  # small a, acute accent
 acirc	=> 'â',  # small a, circumflex accent
 aelig	=> 'æ',  # small ae diphthong (ligature)
 agrave	=> 'à',  # small a, grave accent
 aring	=> 'å',  # small a, ring
 atilde	=> 'ã',  # small a, tilde
 auml	=> 'ä',  # small a, dieresis or umlaut mark
 ccedil	=> 'ç',  # small c, cedilla
 eacute	=> 'é',  # small e, acute accent
 ecirc	=> 'ê',  # small e, circumflex accent
 egrave	=> 'è',  # small e, grave accent
 eth	=> 'ð',  # small eth, Icelandic
 euml	=> 'ë',  # small e, dieresis or umlaut mark
 iacute	=> 'í',  # small i, acute accent
 icirc	=> 'î',  # small i, circumflex accent
 igrave	=> 'ì',  # small i, grave accent
 iuml	=> 'ï',  # small i, dieresis or umlaut mark
 ntilde	=> 'ñ',  # small n, tilde
 oacute	=> 'ó',  # small o, acute accent
 ocirc	=> 'ô',  # small o, circumflex accent
 ograve	=> 'ò',  # small o, grave accent
 oslash	=> 'ø',  # small o, slash
 otilde	=> 'õ',  # small o, tilde
 ouml	=> 'ö',  # small o, dieresis or umlaut mark
 szlig	=> 'ß',  # small sharp s, German (sz ligature)
 thorn	=> 'þ',  # small thorn, Icelandic
 uacute	=> 'ú',  # small u, acute accent
 ucirc	=> 'û',  # small u, circumflex accent
 ugrave	=> 'ù',  # small u, grave accent
 uuml	=> 'ü',  # small u, dieresis or umlaut mark
 yacute	=> 'ý',  # small y, acute accent
 yuml	=> 'ÿ',  # small y, dieresis or umlaut mark

 # Some extra Latin 1 chars that are listed in the HTML3.2 draft (21-May-96)
 copy   => '©',  # copyright sign
 reg    => '®',  # registered sign
 nbsp   => " ", # non breaking space

 # Additional ISO-8859/1 entities listed in rfc1866 (section 14)
 iexcl  => '¡',
 cent   => '¢',
 pound  => '£',
 curren => '¤',
 yen    => '¥',
 brvbar => '¦',
 sect   => '§',
 uml    => '¨',
 ordf   => 'ª',
 laquo  => '«',
'not'   => '¬',    # not is a keyword in perl
 shy    => '­',
 macr   => '¯',
 deg    => '°',
 plusmn => '±',
 sup1   => '¹',
 sup2   => '²',
 sup3   => '³',
 acute  => '´',
 micro  => 'µ',
 para   => '¶',
 middot => '·',
 cedil  => '¸',
 ordm   => 'º',
 raquo  => '»',
 frac14 => '¼',
 frac12 => '½',
 frac34 => '¾',
 iquest => '¿',
'times' => '×',    # times is a keyword in perl
 divide => '÷',
   OElig    => chr(338),
   oelig    => chr(339),
   Scaron   => chr(352),
   scaron   => chr(353),
   Yuml     => chr(376),
   fnof     => chr(402),
   circ     => chr(710),
   tilde    => chr(732),
   Alpha    => chr(913),
   Beta     => chr(914),
   Gamma    => chr(915),
   Delta    => chr(916),
   Epsilon  => chr(917),
   Zeta     => chr(918),
   Eta      => chr(919),
   Theta    => chr(920),
   Iota     => chr(921),
   Kappa    => chr(922),
   Lambda   => chr(923),
   Mu       => chr(924),
   Nu       => chr(925),
   Xi       => chr(926),
   Omicron  => chr(927),
   Pi       => chr(928),
   Rho      => chr(929),
   Sigma    => chr(931),
   Tau      => chr(932),
   Upsilon  => chr(933),
   Phi      => chr(934),
   Chi      => chr(935),
   Psi      => chr(936),
   Omega    => chr(937),
   alpha    => chr(945),
   beta     => chr(946),
   gamma    => chr(947),
   delta    => chr(948),
   epsilon  => chr(949),
   zeta     => chr(950),
   eta      => chr(951),
   theta    => chr(952),
   iota     => chr(953),
   kappa    => chr(954),
   lambda   => chr(955),
   mu       => chr(956),
   nu       => chr(957),
   xi       => chr(958),
   omicron  => chr(959),
   pi       => chr(960),
   rho      => chr(961),
   sigmaf   => chr(962),
   sigma    => chr(963),
   tau      => chr(964),
   upsilon  => chr(965),
   phi      => chr(966),
   chi      => chr(967),
   psi      => chr(968),
   omega    => chr(969),
   thetasym => chr(977),
   upsih    => chr(978),
   piv      => chr(982),
   ensp     => chr(8194),
   emsp     => chr(8195),
   thinsp   => chr(8201),
   zwnj     => chr(8204),
   zwj      => chr(8205),
   lrm      => chr(8206),
   rlm      => chr(8207),
   ndash    => chr(8211),
   mdash    => chr(8212),
   lsquo    => chr(8216),
   rsquo    => chr(8217),
   sbquo    => chr(8218),
   ldquo    => chr(8220),
   rdquo    => chr(8221),
   bdquo    => chr(8222),
   dagger   => chr(8224),
   Dagger   => chr(8225),
   bull     => chr(8226),
   hellip   => chr(8230),
   permil   => chr(8240),
   prime    => chr(8242),
   Prime    => chr(8243),
   lsaquo   => chr(8249),
   rsaquo   => chr(8250),
   oline    => chr(8254),
   frasl    => chr(8260),
   euro     => chr(8364),
   image    => chr(8465),
   weierp   => chr(8472),
   real     => chr(8476),
   trade    => chr(8482),
   alefsym  => chr(8501),
   larr     => chr(8592),
   uarr     => chr(8593),
   rarr     => chr(8594),
   darr     => chr(8595),
   harr     => chr(8596),
   crarr    => chr(8629),
   lArr     => chr(8656),
   uArr     => chr(8657),
   rArr     => chr(8658),
   dArr     => chr(8659),
   hArr     => chr(8660),
   forall   => chr(8704),
   part     => chr(8706),
   exist    => chr(8707),
   empty    => chr(8709),
   nabla    => chr(8711),
   isin     => chr(8712),
   notin    => chr(8713),
   ni       => chr(8715),
   prod     => chr(8719),
   sum      => chr(8721),
   minus    => chr(8722),
   lowast   => chr(8727),
   radic    => chr(8730),
   prop     => chr(8733),
   infin    => chr(8734),
   ang      => chr(8736),
  'and'     => chr(8743),
  'or'      => chr(8744),
   cap      => chr(8745),
   cup      => chr(8746),
  'int'     => chr(8747),
   there4   => chr(8756),
   sim      => chr(8764),
   cong     => chr(8773),
   asymp    => chr(8776),
  'ne'      => chr(8800),
   equiv    => chr(8801),
  'le'      => chr(8804),
  'ge'      => chr(8805),
  'sub'     => chr(8834),
   sup      => chr(8835),
   nsub     => chr(8836),
   sube     => chr(8838),
   supe     => chr(8839),
   oplus    => chr(8853),
   otimes   => chr(8855),
   perp     => chr(8869),
   sdot     => chr(8901),
   lceil    => chr(8968),
   rceil    => chr(8969),
   lfloor   => chr(8970),
   rfloor   => chr(8971),
   lang     => chr(9001),
   rang     => chr(9002),
   loz      => chr(9674),
   spades   => chr(9824),
   clubs    => chr(9827),
   hearts   => chr(9829),
   diams    => chr(9830),
);

#-------------------------------------------------------------
# callback functions
#	$bot->get_alias()									=> $alias
#	$bot->argv_default()								=> @argv_args
#		qw(cat1=i cat2=i pageno=i desc=s)
#	$bot->argv_process(\%args)							=> N/A
#	$bot->argv_process_all(\%args)						=> N/A
#	$bot->get_url_verify($url_in_out)					=> N/A
#		a callback to verify or change $url before real get
#	$bot->go_login()									=> N/A
#	$bot->getpattern_catalog_head_data()				=> N/A
#	$bot->getpattern_catalog_end_data()					=> N/A
#	$bot->getpattern_catalog_get_bookargs_data()		=> $raw_pattern
#	$bot->catalog_get_bookargs(\%args)					=> 'OK' / 'Skip'
#		called after match
#	$bot->getpattern_chapters_head_data()				=> N/A
#	$bot->getpattern_chapters_end_data()				=> N/A
#	$bot->getpattern_chapters_get_chapterargs_data()	=> $raw_pattern
#	$bot->chapters_get_chapterargs(\%args)				=> 'OK' / 'Skip'
#		called after match
#	$bot->getpattern_TOC_exists_data()					=> $raw_pattern
#		'' means TOC is always exists
#	$bot->getpattern_TOC_head_data()					=> N/A
#	$bot->getpattern_TOC_end_data()						=> N/A
#	$bot->getpattern_chapter_head_data()				=> N/A
#	$bot->getpattern_chapter_end_data()					=> N/A
#	$bot->parse_paragraph_begin($content_dein_deout)	=> N/A
#	$bot->parse_paragraph_end($content_dein_deout)		=> N/A
#	$bot->book_finish(\%args)							=> N/A
#	$bot->result_filestem(\%args)						=> filestem
#	$bot->result_time(\%args)						=> time / undef
#		undef forbiden bot to set file time
#-------------------------------------------------------------
sub get_alias {
	'unknown';
}
sub argv_default {
	# default argv list in Getopt::Long format, to pass back to argv_process
	qw();
}
sub argv_process {
}
sub argv_process_all {
}
sub get_url_verify {
	# a call back to verify or change $_[1] before real get
}
sub go_login {
	# login after initialize
}
sub getpattern_catalog_head_data {
	<<'DATA';
(?=<body)
DATA
}
sub getpattern_catalog_end_data {
	<<'DATA';
</body>
DATA
}
sub getpattern_catalog_get_bookargs_data {
	<<'DATA';
<a[^<>]*href=['"]{0,1}(.*?)(?:['" ][^<>]*>|>)(.*?)</a>
DATA
}
sub catalog_get_bookargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$pargs->{url}=$a[1];
	$pargs->{title}=$self->parse_titleen($a[2]);
	'OK';
}
sub getpattern_catalog_get_next_data {
	'';		#'' means don't know how to stop
}
sub getpattern_chapters_head_data {
	$_[0]->getpattern_TOC_head_data;
}
sub getpattern_chapters_end_data {
	$_[0]->getpattern_TOC_end_data;
}
sub getpattern_chapters_get_chapterargs_data {
	<<'DATA';
<a[^<>]*href=['"]{0,1}(.*?)(?:['" ][^<>]*>|>)(.*?)</a>
DATA
}
sub chapters_get_chapterargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$pargs->{url}=$a[1];
	$pargs->{title}=$self->parse_titleen($a[2]);
	'OK';
}
sub getpattern_TOC_exists_data {
	'';
}
sub getpattern_TOC_head_data {
	<<'DATA';
(?=<body)
DATA
}
sub getpattern_TOC_end_data {
	<<'DATA';
</body>
DATA
}
sub getpattern_chapter_head_data {
	<<'DATA';
(?=<body)
DATA
}
sub getpattern_chapter_end_data {
	<<'DATA';
</body>
DATA
}
sub parse_paragraph_begin {
}
sub parse_paragraph_end {
}
sub book_finish {
}
sub result_filestem {
	my ($self, $pargs) = @_;
	return $pargs->{prefix}.
		sprintf("%04d",$self->{book_get_num}).
		$pargs->{title}.
		$pargs->{postfix};
}
sub result_time {
	my ($self, $pargs) = @_;
	return $pargs->{last_modified};
}

1;
__END__

=head1 NAME

WWW::BookBot - Bot to fetch web e-texts with catalog, books and chapters.

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Novel::DragonSky;
  my $bot=WWW::BookBot::Chinese::Novel::DragonSky->new({work_dir=>'/output'});
  $bot->go_catalog({});

  use WWW::BookBot::Chinese::Novel::ShuKu;
  my $bot=WWW::BookBot::Chinese::Novel::ShuKu->new({});
  $bot->go_catalog({desc=>'NewNovel', cat1=>0, cat2=>1, pageno=>0});

=head1 ABSTRACT

bot to fetch web e-texts with catalog, books and chapters.

=head1 DESCRIPTION

Virtual classes of bot to fetch web e-texts with catalog, books and chapters.

to be added.

=head2 EXPORT

None by default.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<bookbot>

=cut
