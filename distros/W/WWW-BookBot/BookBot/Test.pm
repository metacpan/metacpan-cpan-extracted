package WWW::BookBot::Test;
use strict;
use warnings;
no warnings qw(uninitialized utf8);
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = "0.12";
@EXPORT = qw(
	new_bot read_file
	dump_class dump_var en_code de_code parse_patterns test_pattern
	match_print string_limitlen get_pattern
	test_init test_begin test_end
	test_encoding test_parse_patterns test_msg_format
	test_file test_log test_result test_DB
	test_agent test_url test_fetch test_parser
	test_catalog_get_book test_book_chapters
	test_writebin test_parse_bintext
);
@EXPORT_OK = @EXPORT;

use Test::More;
use Data::Dumper;
use File::Spec::Functions;
use File::Path;

#------ contants and vars
our $CLEARRESULT=1;				#clear reseult dir before quit
our $TESTONLINE=0;				#test online or not
our $classname='WWW::BookBot';	#class to be tested
our $testdir;					#the dir to put logs in
our $bot;						#the bot created as $classname

#-------------------------------------------------------------
# Support functions
#	new_bot(@args)										=> N/A
#	read_file($filename)								=> $content
#	dump_class()										=> N/A
#	dump_var($var_name)									=> N/A
#	en_code($content_de)								=> $content_en
#	de_code($content_en)								=> $content_de
#	parse_patterns($str)								=> $pattern
#	get_pattern($pattern_name)							=> $pattern
#	test_pattern($pattern_name, $content)				=> 1-match 0-no match
#	string_limitlen($len, $content_de)					=> $content_en
#	match_print($match_bool_result)						=> N/A
#-------------------------------------------------------------
sub new_bot(@) {
	$bot=$classname->new({work_dir=>$testdir, @_});
}
sub read_file($) {
	my $filename = shift;
	my $str="";
	local(*WORK);
	open(WORK, $filename) or return "";
	sysread(WORK, $str, 6000000) or return "";
	close(WORK) or return "";
	$str=~s/\r\n|\r/\n/;	#to ensure tests work on both unix and win32
	return $str;
}
sub dump_class() {
	$bot->dump_class;
}
sub dump_var($) {
	$bot->dump_var($_[0]);
}
sub en_code($) {
	$bot->en_code($_[0]);
}
sub de_code($) {
	$bot->de_code($_[0]);
}
sub parse_patterns($) {
	$bot->parse_patterns($_[0]);
}
sub get_pattern($) {
	$bot->{patterns}->{$_[0]};
}
sub test_pattern($$) {
	$bot->test_pattern(@_);
}
sub string_limitlen($$) {
	length($_[1])<=($_[0]+8) ? 
		$bot->en_code($_[1]) :
		$bot->en_code(substr($_[1],0,$_[0]/2))."......".$bot->en_code(substr($_[1],length($_[1])-$_[0]/2));
}
sub match_print($) {
	my ($result)=@_;
	if( $result ) {
		print "Match ";
		my $i=0;
		foreach ($1, $2, $3, $4, $5, $6, $7, $8, $9) {
			$i++;
			next if $_ eq '';
			printf " [%d]=\'%s\'\n", $i, string_limitlen(300,$_);
		}
		print "\n";
	} else {
		print "No Match\n";
	}
}

#-------------------------------------------------------------
# Routines
#	test_init($classname)								=> N/A
#	test_begin()										=> N/A
#	test_end()											=> N/A
#-------------------------------------------------------------
sub test_init($) {
	$classname=$_[0];
}
sub test_begin() {
	chdir 't' if -d 't';
	$testdir=($classname=~/::([^:]*)$/) ? $1 : $classname;
	rmtree($testdir);
	new_bot();
	ok(defined($bot), "new $classname");
	ok(-d $testdir, "create directory $testdir");
}
sub test_end() {
	rmtree($testdir) if $CLEARRESULT;
	chdir 't';
	chdir '..';
}

#-------------------------------------------------------------
# Tests
#-------------------------------------------------------------
sub test_encoding {
	my ($in, $out, $disp)=@_;
	print "Content='$in'\n";
	my $decode=$bot->de_code($in);
	print "  [decode as $bot->{LANGUAGE_ENCODE}] $decode\n";
	my $encode=$bot->en_code($decode);
	print "  [encode as $bot->{LANGUAGE_ENCODE}] $encode\n";
	is($encode, $out, "function en_code and de_code $disp");
}

sub test_parse_patterns {
	my ($in, $out, $disp)=@_;
	is($bot->en_code($bot->parse_patterns($in)), $out, "function parse_patterns $disp");
}

sub test_msg_format {
	my ($pargs, $out, $disp)=@_;
	is($bot->msg_format("TestMsg",$pargs), $out, "function msg_format $disp");
}

sub test_file {
	my $filename=catfile($testdir, "test_file.txt");
	unlink $filename if -f $filename;
	$bot->file_init("DB", $filename);
	ok(-f $filename, "function file_init");
	my $result="";
	foreach (@_) {
		$bot->file_add("DB", $filename, $_);
		$result.=$_;
	}
	is(read_file($filename), $result, "function file_add file=$filename");
}

sub test_log {
	my $filename=$bot->{file_log};
	unlink $filename if -f $filename;
	$bot->log_msg($_[0]);
	$bot->log_msg("");
	$bot->log_msg($_[0], $_[1], "\n");
	is(read_file($filename), "$_[0]$_[0]$_[1]\n", "function log_msg file=$filename");
	unlink $filename if -f $filename;
	my $str=$_[2];
	$bot->log_msgen($bot->de_code($str));
	print "\n";
	is(read_file($filename), $str, "function log_msgen file=$filename");
	unlink $filename if -f $filename;
	$bot->log_add("TestMsg", $_[3]);
	print "\n";
	is(read_file($filename), $_[4], "function logadd file=$filename");
}

sub test_result {
	my $timenow=time;
	sleep 1;
	my $filename=$bot->result_filename({title=>'Result*Test'});	#bad name
	unlink $filename if -f $filename;
	$bot->result_init({title=>'ResultTest'});
	ok(-f $filename, "function result_init file=$filename");
	my $result="";
	foreach (@_) {
		$bot->result_add($filename, $_);
		$result.=$_;
	}
	is(read_file($filename), $result, "function result_add file=$filename");
	$bot->result_settime($filename, $timenow);
	ok((stat($filename))[9]==$timenow, "fucntion result_settime file=$filename");
}

sub test_DB {
	my $filename=$bot->{file_DB};
	unlink $filename if -f $filename;
	$bot->db_init;
	ok(read_file($filename)=~/use $classname/, "function db_init create file=$filename");
	$bot->db_clear;
	ok(not(-f $filename), "function db_clear file=$filename");
	$bot->db_init;
	$bot->db_add("Book", "OK", {other=>'hoho', url=>'http://test.com/test.html'});
	ok(read_file($filename)=~/test\.com/, "function db_add file=$filename");
	$bot->db_load;
	is($bot->{DB_visited_book}->{"http://test.com/test.html"}, "OK", "function db_load file=$filename");
}

sub test_agent {
	$bot->{get_agent_proxy}="No;192.168.1.8:8888";
	$bot->agent_init;
	ok((defined($bot->{get_agent_array}->[0]) and not(defined($bot->{get_agent_array}->[0]->proxy('http')))),
		"function agent_init/agent_setproxy: get_agent_proxy=No");
	ok((defined($bot->{get_agent_array}->[1])
		and ($bot->{get_agent_array}->[1]->proxy('http') eq 'http://192.168.1.8:8888/')),
		"function agent_init/agent_setproxy: get_agent_proxy=192.168.1.8:8888");
	new_bot();
}

sub test_url {
	is($bot->url_rel2abs("index.htm", "http://w.c.c/s/m.txt"), "http://w.c.c/s/index.htm", "function url_rel2abs");
}

sub test_fetch {
	SKIP: {
		my ($url, $res);
		skip "cannot visit online sites", 3 if not $TESTONLINE;
		$url="http://www.cpan.org/";
		$res=$bot->get_url($url);
		print "\n";
		ok($res->content=~/<html/, "function get_url text $url");
		$url="http://www.cpan.org/misc/gif/funet.gif";
		$res=$bot->get_url($url);
		print "\n";
		ok($res->content=~/^GIF89/, "function get_url gif $url");
		$url="http://www.cpan.org/unavailable-test.txt";
		$res=$bot->get_url($url);
		print "\n";
		ok(not($res->is_success), "function get_url WRONG $url");
		undef $res;
	}
}

sub test_parser {
	my ($func, $in, $out, $disp)=@_;
	my $str=$bot->de_code($in);
	$bot->$func($str);
	my $result=$bot->en_code($str);
	is($result, $out, "function $func $disp");
}

sub test_parser_enin_deout {
	my ($func, $pargs, $in, $out, $disp)=@_;
	my $str=$in;
	$bot->$func($pargs, $str);
	my $result=$bot->en_code($str);
	is($result, $out, "function $func $disp");
}
sub test_catalog_get_book {
	my ($str_nothing, $str_good, $url, $title)=@_;
	my $pargs={url_base=>'http://www.sina.com.cn/index.htm'};
	my @a1=$bot->catalog_get_book($pargs, $bot->de_code($str_nothing));
	is(scalar(@a1), 0, "function catalog_get_book empty catalog");
	my @a2=$bot->catalog_get_book($pargs, $bot->de_code($str_good));
	is(scalar(@a2), 1, "function catalog_get_book good catalog");
	is($a2[0]->{url}, $url, 'function catalog_get_book get url');
	is($a2[0]->{title}, $title, 'function catalog_get_book get title');
}
sub test_book_chapters {
	my ($str_nothing, $str_good, $url, $title)=@_;
	my $pargs={url_base=>'http://www.sina.com.cn/index.htm'};
	my @a1=$bot->book_chapters($pargs, $bot->de_code($str_nothing));
	is(scalar(@a1), 0, "function book_chapters empty catalog");
	my @a2=$bot->book_chapters($pargs, $bot->de_code($str_good));
	is(scalar(@a2), 1, "function book_chapters good catalog");
	is($a2[0]->{url}, $url, 'function book_chapters get url');
	is($a2[0]->{title}, $title, 'function book_chapters get title');
}
sub test_writebin {
	my ($str)=@_;
	new_bot();
	my $pargs={title=>"WBIN", ext_save=>"cov"};
	my $filename_full=$bot->result_filename($pargs);
	my $filename=$bot->book_writebin($pargs, $str);
	is($filename, "0000WBIN.cov", "function book_writebin return correct name");
	is(read_file($filename_full), $str, "function book_writebin write file");
}

sub test_parse_bintext {
	my ($str)=@_;
	new_bot();
	test_parser_enin_deout('book_bin',
		{title=>"WBIN", ext_save=>"cov"},
		$str, "[0000WBIN.cov]");
	test_parser_enin_deout('book_text',
		{title=>"WTXT", ext_save=>"txt", level=>0},
		$str, "[0001WTXT.txt]", "level=0");
	test_parser_enin_deout('book_text',
		{title=>"WTXT", ext_save=>"txt", level=>1},
		$str, $str, "level=1");
}

1;
__END__

=head1 NAME

WWW::BookBot::Test - Test utilities for inherited bot of WWW::BookBot.

=head1 SYNOPSIS

  use Test::More tests => 37;
  BEGIN { use_ok('WWW::BookBot::Test'); use_ok(test_init('WWW::BookBot')); };
  test_begin();
  ...
  test_end();

=head1 ABSTRACT

  Test utilities for inherited classes of WWW::BookBot.

=head1 DESCRIPTION

WWW::BookBot::Test provides basic test routines for inherited classes of
WWW::BookBot.

=head2 Basic test environment

  test_init($classname) will set internal test classname and return $classname.
  test_begin() will initialize test environment.
  test_end() will close test environment.

=head2 Test utilities

  new_bot({...}) new_bots a new $bot using given classname and arguments.
  read_file($filename) returns all contents of $filename.
  dump_class() dumps out first level of class.
  dump_var($var_name) dumps out all about $var_name of class.
  test_pattern($pattern_name, $content) tests given pattern with $content.

=head2 EXPORT

  all functions are exported.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>

=cut
