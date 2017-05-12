use CPAN;
eval 'require Digest::MD5';

@prereq = qw(IO Net::FTP Compress::Zlib Digest::MD5 MIME::Base64
	URI HTML::Parser LWP);
@useful = (qw(Locale::Hebrew Tie::Cache Tie::Depth File::FTS
        Storable Time::Timezone Sys::Syslog Net::Daemon
        RPC::PlServer Clone Crypt::CBC
        DBI DBD::XBase DB_File File::Tools Mail::Tools
	SQL::Statement Text::CSV_XS DBD::CSV FreezeThaw 
        Data::Dumper Image::Size MLDBM Convert::BER IO::Socket::SSL
	Convert::ASN1 Net::LDAP XML::Parser
        Net::DNS Net::Whois Net::Country 
	Filter::Util::Call Text::Autoformat Template XML::Simple
	Date::Language XML::Conf Config::IniFiles IniConf
	Date::Manip));

%answers = ('Template', 'n');

if ($ARGV[0] eq 'NOPREREQ') {
	@modules = @useful;
	shift @ARGV;
} else {
	@modules = (@prereq, @useful);
        if ($] < 5.006) {
            print "Try: perl pre-install NOPREREQ\nif CPAN tries helplessly to download Perl 5.6.0 and install it\07\n";
            sleep 4;
        }
}

unshift(@INC, $ARGV[0]) if (@ARGV);

close(STDIN);

&cls;
&confcpan;
&makeobjs;

foreach $mod (@objs) {
        &cls;
	pipe(STDIN, W);
	$a = $answers{$mod};
	$a =~ s/(\\.)/"$1"/ge;
	print W $a;
	eval { $mod->install; };
        if ($loop < @prereq) {
            $nm = $modules[$loop++];
            eval "require $nm;";
        }
	close(W);
}

&cls;
print "\007";

if (@ARGV) {
    system "rm -rf $root";
}

sub makeobjs {
    &cls;
    @objs = map {
	CPAN::Shell->expand('Module', $_);} @modules;
}

sub cls {
    print "\e[2J";
}

sub confcpan {
  eval 'require CPAN::Config';
  if (@ARGV) {
    require "getcwd.pl";
    $cwd = &getcwd;
    $root = "$cwd/temp";
    $arg = `/bin/cat instnonroot.dat`;
    $arg =~ s/\%/$ARGV[0]/g;
    $arg =~ s/\@/$root/;
    mkdir "$root", 0777;
    mkdir "$root/build", 0777;
    mkdir "$root/sources", 0777;
    $CPAN::Config->{'makepl_arg'} = $arg;
    $CPAN::Config->{'cpan_home'} = $root;
    $CPAN::Config->{'build_dir'} = "$root/build";
    $CPAN::Config->{'keep_source_where'} = "$root/sources";
  }
}
