package HTML::HTPL::Sys;

require HTML::HTPL::Lib;
require HTML::HTPL::Config;

use Carp;
use strict qw(vars subs);
use vars qw($htpl_pkg $htpl_old_hnd $htpl_app_obj
	$have_time_hires $started_time $htpl_redirected $on_htpl
	@cookies $TCL_LOADED $in_mod_htpl @ISA @EXPORT
	@MONTH_NAMES @WEEKDAY_NAMES $DB_HASH $REMOTE_HOST $REMOTE_USER
        @__htpl_stack $debug_file);

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(call html_table html_table_out evit publish doredirect
parse_cookies getmailprog proper ch2x safehash parse_tags outhtmltag
enforce_tags htpl_startup get_session gethash
revmap ReadParse cleanup exit getvar safetags isheb safetags
checktaint pushvars popvars pkglist getpkg compileutil
$htpl_pkg DEBUG scriptdir);

$in_mod_htpl ||= $HTML::HTPL::Lib::in_mod_htpl;

push(@EXPORT, 'exit') unless ($in_mod_htpl || $HTML::HTPL::Lib::in_mod_htpl);

@MONTH_NAMES = qw(January February March April May June July August
September October December);
@WEEKDAY_NAMES = qw(Sunday Monday Tuesday Wednesday Thursday Friday
Saturday);

sub call (&$) {
    my ($code, $val) = @_;
    local ($_) = $val;
    &$code($val);
}

sub html_table {
    my ($x, $y, $i, $el, $a);
    my (%tags) = &safetags(@_);
    my (@items) = @{$tags{'items'}};
    my ($expr) = $tags{'expr'};

    $i = 0;
    $a = [];
    foreach $el (@items) {
        $_ = $i++;
        ($x, $y) = &$expr;
	$a->[$x][$y] = $el;
    }
    delete $tags{'expr'};
    delete $tags{'items'};
    &html_table_out(%tags, 'table' => $a);
}

sub html_table_out {
    my (%tags) = @_;
    my ($a) = $tags{'table'};
    my ($s, $el, $data, $cell);
    my ($x, $y, $xx, $yy);

    $xx = $#$a;

    $yy = &HTML::HTPL::Lib::max(map {$#$_;} @$a);

    $s = "<TABLE";
    $s .= (($el = &evit($tags{'tattr'})) ? " $el" : "");
    $s .= ">\n";
    &pushvars(qw(x y mx my));
    &publish('mx' => $xx, 'my' => $yy);
    foreach $y (0 .. $yy) {
        $s .= "<TR";
        $s .= (($el = &evit($tags{'rattr'})) ? " $el" : "");
        $s .= ">\n";
        &setvar('y' => $y);

        foreach $x (0 .. $xx) {
            &setvar('x' => $x);
            $data = $a->[$x][$y];
            $cell = 'TD';
            $el = $tags{'cattr'};
            if (UNIVERSAL::isa($data, 'HASH')) {
                &safehash($data);
                next if ($data->{'noop'});
                $el = $data->{'cattr'};
                $cell = 'TH' if ($data->{'header'});
                $data = $data->{'data'};
            }
            $el = " " . &evit($el) if ($el);
            $data = &$data($x, $y, $a->[$x][$y]) 
                if (UNIVERSAL::isa($data, 'CODE'));
            $data = "&nbsp;" unless $data;
            $s .=  "<$cell$el>\n" . $data . "\n</$cell>\n";
        }
        $s .= "</TR>\n";
    }
    $s .= "</TABLE>\n";
    &popvars;

    print $s unless ($tags{'noout'});
    $s;
}

sub evit {
    my ($ev) = @_;
    $ev = &$ev if (UNIVERSAL::isa($ev, 'CODE'));
    if (UNIVERSAL::isa($ev, 'HASH')) {
        my %this = %$ev;
        $ev = join(" ", grep /./, map {my $val = $ev->{$_};
                       my $toadd = ref($val) ? &evit($val) : $val;
                       $toadd ? (uc($_) . "=" . $toadd) : undef} keys %$ev);
    }
    return $ev;
}

sub strong_publish {
    my %_hash = ($#_ ? @_ : %{$_[0]});
    foreach (keys %_hash) {
        if (UNIVERSAL::isa($_hash{$_}, 'ARRAY')) {
            &setvar($_, $_hash{$_}->[0]);
            &setarray($_, @{$_hash{$_}});
        } else {
            &setvar($_, $_hash{$_});
            &setarray($_, $_hash{$_});
        }
    }
}

sub publish {
    my %hash = @_;
    my ($k, $v);
    while (($k, $v) = each %hash) {
        &setvar($k, $v);
    }
    if ($TCL_LOADED) {
        &HTML::HTPL::Tcl::exportvars(map {'$' . $htpl_pkg . "::$_"}
            keys %hash);
    }
}

sub doredirect {
    my ($url) = @_;
    my (@hds) = ();
    return unless ($on_htpl);
    &HTML::HTPL::Lib::eraseheader('Content-type');
    print HEADERS "Location: $url\n";
    close(HEADERS);
    &rewind;
    $htpl_redirected = $url if ($in_mod_htpl);
}

sub parse_cookies {
    require Tie::Func;
    my %cookies;
    my $line = $ENV{'HTTP_COOKIE'};
    @cookies = split(/;\s*/, $line);
    foreach (@cookies) {
        my ($key, $val) = split(/=/);
        $cookies{$key} = $val;
    }
    tie %{$htpl_pkg . "'cookies"}, 'Tie::Func', undef,
      sub {&HTML::HTPL::Lib::setcookie($_[1], $_[2]); 1;}, 
      sub {&HTML::HTPL::Lib::erasecookie($_[1]);}, %cookies;
}


sub getmailprog {
    return $HTML::HTPL::Config::mailprog if ($HTML::HTPL::Config::mailprog);
    my ($p);
    $p = `which sendmail`;
    chop $p;
    return $p if (-x $p);
    return "/usr/sbin/sendmail" if (-e "/usr/sbin/sendmail");
    return "/usr/bin/sendmail" if (-e "/usr/bin/sendmail");
    return "/usr/lib/sendmail" if (-e "/usr/lib/sendmail");
    Carp::croak("sendmail not present");
}

sub proper (&@) {
    my ($sub, @l) = @_;
    my $i;
    for($i = 0; $i < $#l; $i+=2) {
        $l[$i] =~ s/([a-z]+)/&call($sub,$1)/gei;
        $l[$i] =~ s/_/-/g;
    }
    @l;
}

sub ch2x {
    '%' . uc(unpack("H*", shift));
}

sub safehash {
    my ($hashref) = @_;

    my %hash = %$hashref;
    %hash = safetags(%hash);
    %$hashref = %hash;
}

sub safetags {
    &proper(sub {lc($_);}, @_);
}

sub parse_tags {
    my ($str) = @_;
    require HTML::TokeParser;
    my ($tag) = "<X $str>";
    my ($prh) = new HTML::TokeParser(\$tag);
    my ($tk) = $prh->get_token;
    &proper(sub {uc($_);} ,%{$$tk[2]});
}

sub outhtmltag {
    my ($name, %attrs) = @_;
    my ($res) = "<$name";
    my ($fe) = join(" ", map {$_ . '="' . $attrs{$_} . '"'} keys %attrs);
    $res .= " $fe" if ($fe);
    "$res>";
}

sub enforce_tags {
    my ($str, $mac, @tags) = @_;
    my (%t) = &proper(sub {uc($_);}, @tags);
    foreach (split(/,\s*/, $str)) {
        unless (defined($t{uc($_)})) {
            Carp::croak("$_ is necessary for $mac"); 
        }
    }
}

sub initrun {
    $have_time_hires = undef;
    eval 'require Time::HiRes; $have_time_hires = 1;';
    $started_time = &mytime;
    require Tie::Func;
    tie ${$htpl_pkg . "::timer"}, 'Tie::Func', \&HTML::HTPL::Lib::elapsed,
               undef, undef;
    my $filter = $HTML::HTPL::Config::filter;
    $htpl_old_hnd = select;
    if ($filter) {
	tie *HOUT, 'HTML::HTPL::Filter', $filter, $htpl_old_hnd;
	select HOUT;
    }
}

sub htpl_startup {
    $in_mod_htpl ||= $HTML::HTPL::Lib::in_mod_htpl;
    $htpl_pkg ||= $HTML::HTPL::LIB'htpl_pkg || "main";
    $htpl_redirected = undef;
    %ENV = %{"$htpl_pkg\'ENV"};
    %HTML::HTPL::Lib::ENV = %ENV;

    require "./htpl-glob.pl" if (-e "htpl-glob.pl");
    $htpl_app_obj = {};   
    import HTML::HTPL::Lib;

    my ($host, $port, $scr);
    &setvar('SCRIPT_NAME' => $scr = $ENV{'PATH_INFO'});
    &setvar('QUERY_STRING'=> $ENV{'QUERY_STRING'});
    &setvar('REMOTE_USER' => $ENV{'REMOTE_USER'});
    &setvar('REMOTE_HOST' => &saferevnslookup($ENV{'REMOTE_ADDR'}));
    &setvar('HTTP_REFERER' => $ENV{'HTTP_REFERER'});
    &setvar('SERVER_NAME' => $host = $ENV{'SERVER_NAME'});
    &setvar('SERVER_PORT' => $port = $ENV{'SERVER_PORT'});
    &setvar('REQUEST_METHOD' => $ENV{'REQUEST_METHOD'});
    $port = ($port == 80 ? "" : ":$port");
    &setvar('SELF_URL' => "http://$host$port$scr");
    require Tie::Func;
    tie ${$htpl_pkg . "::SELF"}, 'Tie::Func',
        sub { &HTML::HTPL::Lib::selfurl(); }, undef, undef;

    if ($ENV{'HTTP_HEADERS'}) {
        if ($ENV{'HTTP_HEADERS'} eq 'NONE') {
            $on_htpl = undef;
            delete $ENV{'HTTP_HEADERS'};
        } else {
            $on_htpl = 1;
            open(HEADERS, '+>' . $ENV{'HTTP_HEADERS'});
            print HEADERS "Content-type: text/html\n"; # Do not double new line!
        }
    } else {
        $on_htpl = undef;
        print "Content-type: text/html\n\n";
    }

    my $dir = &HTML::HTPL::Lib::getcwd;

    unshift(@INC, $dir);
    &setvar("ORIGDIR" => $dir);

    my $cdir;

    foreach (($0, $ENV{'PATH_TRANSLATED'})) {
        if ($_) {
            $cdir = $_;
            $cdir =~ s|/[^/]*?$||;
            next unless ($cdir);
            $dir = $cdir;
            chdir($dir);
            unshift(@INC, $dir);
        }
    }
    &setvar("SCRIPTDIR" => $dir);

    &parse_cookies;
    &ReadParse;
    &readini;
    &get_session if ($HTML::HTPL::Config::htpl_persistent);
    &initrun;
    $debug_file = undef;
    if ($HTML::HTPL::Config::htpl_debug) {
        my %h;
        if
(HTML::HTPL::Lib::chknetmask($ENV{'REMOTE_ADDR'},
		%HTML::HTPL::Config::htpl_debug_hosts)) {
            my $slash = &slash;
            my $qslash = quotemeta($slash);
            $debug_file = $0;
            $debug_file =~ s/\.\w+$/.txt/;
	    $debug_file =~ s/${qslash}htpl-cache${qslash}(.*?)$/${slash}$1/;
            open(O, ">$debug_file") && close(O) || ($debug_file = undef);
        } 
    } 
}

sub makepersist {
    require MLDBM;
    require FreezeThaw;
    require DB_File;
    import DB_File;
    use Fcntl; # Never ever change to require + import
    import MLDBM qw(DB_File FreezeThaw);
    require Tie::Collection;
    return if (tied(%HTML::HTPL::Root::objects));
    my $dbm = (tie %HTML::HTPL::Root::db, 'DB_File', 
        $HTML::HTPL::Config::htpl_db_file, 
	O_RDWR | O_CREAT,
                   0644, $DB_HASH) || die "No dbm: $!";
    my $htpl_dbm = tie %HTML::HTPL::Root::persist, 'MLDBM' || die "no mldbm";
    $htpl_dbm->UseDB($dbm) || die "No db";
    tie %HTML::HTPL::Root::objects, 'Tie::Collection', $htpl_dbm, $HTML::HTPL::Config::htpl_persist_cachesize, {'MaxBytes' => 1024 * ($HTML::HTPL::Config::htpl_persist_cachesize || 4)};
}

sub get_session {
    my ($quick) = @_;
    require Tie::DeepTied;

    &makepersist;
    $REMOTE_HOST = &getvar('REMOTE_HOST');
    if ($quick) {
        my $session = $HTML::HTPL::Root::session;
        $HTML::HTPL::Root::objects{"sessions\0$session"} = 
            \%{$htpl_pkg . "'session"};
        $HTML::HTPL::Root::objects{"app"} =
                        \%{$htpl_pkg . "'application"};
        untie %HTML::HTPL::Root::objects;
        untie %HTML::HTPL::Root::persist;
        return;	
    }
    my ($s_id, $session, $x, $y);
    foreach $session (keys %{$HTML::HTPL::Root::objects{'sessions'}}) {
            if ($HTML::HTPL::Root::objects{"sessions"}->{$session} +
               $HTML::HTPL::Config::htpl_per_session_idle_time < time)
                    {
        delete $HTML::HTPL::Root::objects{"sessions\0$session"};
        delete $HTML::HTPL::Root::objects{"sessions"}->{$session};
            my $host = $HTML::HTPL::Root::objects{"hosts"}->{$session};
            if ($host) {
        delete $HTML::HTPL::Root::objects{"hosts"}->{$session};
        delete $HTML::HTPL::Root::objects{"hosts\0$host"};
                       }
                     }
    }
    if ($HTML::HTPL::Config::htpl_use_cookies) {
        $s_id = ${$htpl_pkg . "'cookies"}{$HTML::HTPL::Config::htpl_cookie};
        unless ($s_id) {
            $s_id = "__htpl_ck_" . ++$HTML::HTPL::Root::objects{'next_session'};
            &HTML::HTPL::Lib::setcookie($HTML::HTPL::Config::htpl_cookie, $s_id);
            push(@HTML::HTPL::Root::sessions, $s_id);
        }
    } else {
        $s_id = $HTML::HTPL::Root::objects{"hosts\0$REMOTE_HOST"};
        unless ($s_id) {
            $HTML::HTPL::Root::objects{"hosts\0$REMOTE_HOST"} =
              ($s_id = "ip" . ++$HTML::HTPL::Root::objects{'next_session'});
            $HTML::HTPL::Root::objects{"hosts"}->{$s_id} = $REMOTE_HOST;
        }
    }
    $HTML::HTPL::Root::objects{"sessions"}->{$s_id} = time;
    $HTML::HTPL::Root::session = $s_id;
    tie %{$htpl_pkg . "'session"}, 'Tie::DeepTied', 
        tied(%HTML::HTPL::Root::objects), "sessions\0$s_id";
    tie %{$htpl_pkg . "'application"}, 'Tie::DeepTied', 
        tied(%HTML::HTPL::Root::objects), 'app';
}

sub revmap {
    my ($listref, $el) = @_;
    ($el) x @$listref;
}

sub ReadParse {
    my ($q);
    my ($e) = &getvar('QUERY_STRING');
    return if ($e && $e !~ /=/ && $ENV{'REQUEST_METHOD'} != 'GET');
    require CGI;
    import CGI;
    $q = new CGI;
    my (@keys) = $q->param;
    my (%hash, %upfile);
    my $key;
    foreach $key (@keys) {
        &dieTaint if ($key =~ /^[^a-zA-Z]$/ || $key =~ /^\d+$/);
        my @val = $q->param($key);  
        my $id = fileno($val[0]);
        if ($id =~ /^\d+$/) {
            binmode $val[0];
            my $buffer;
            while (sysread($val[0], $buffer, 4096, length($buffer))) {}
            my $disp = $q->uploadInfo($val[0])->{'Content-Disposition'};
            my @tokens = split(/;\s*/, $disp);
            my $filename;
            foreach (@tokens) {
                ($filename) = /^filename=(.*)$/;
                last if ($filename);
            }
            $filename =~ s/^\"(.*)\"$/$1/;
            $upfile{$key} = $filename;
            @val = ($buffer);
        } elsif ($HTML::HTPL::Config::htpl_flip_hebrew) {
            my @f = map { $_ = hebrewflip($_) if (&isheb($_))} @val;
        }
        $hash{$key} = ($#val ? \@val : $val[0]);
    }
    &sethash($ENV{'REQUEST_METHOD'} eq 'GET' ? 'url' : 'form', %hash);
    return if ($_[0] eq 'forge');
    if ($ENV{'REQUEST_METHOD'} eq 'POST' && $e =~ /=/) {
        $ENV{'REQUEST_METHOD'} = 'GET';
        &ReadParse('forge');
    }
    %hash = &gethash('url');
    my %h2 = &gethash('form');
    foreach (keys %h2) {
        $hash{$_} = $h2{$_};
    }
    &sethash('in', %hash);
    &sethash('upfile', %upfile);
    &strong_publish(%hash);
}

sub cleanup {
    select $htpl_old_hnd if (ref($htpl_old_hnd));
    return unless ($on_htpl);
    truncate(STDOUT, tell(STDOUT));
    close(HEADERS);
    &get_session(1) if ($HTML::HTPL::Config::htpl_persistent);
}

sub exit {
    &cleanup;
    if ($in_mod_htpl) {
        goto htpl_lblend;
    } else {
        CORE::exit($_[0]);
    }
}

sub getvar {
    my $key = shift;
    my $var = "${htpl_pkg}::$key";
    return \$$var if ($_[0]);
    my $val = $$var;
    $val = "" unless (defined($val));
    $val = eval($val) if ($val =~ /^[-+]?(\d*\.)?\d+(e\d+)?$/i);
    $val;
}

sub setvar {
    my ($key, $val) = @_;
    ${$htpl_pkg . "'$key"} = $val;
}

sub setarray {
    my ($key, @val) = @_;
    @{$htpl_pkg . "'$key"} = @val;
}

sub sethash {
    my ($key, %val) = @_;
    %{$htpl_pkg . "'$key"} = %val;
}

sub gethash {
    my $key = shift;
    my %val = %{$htpl_pkg . "'$key"};
    %val;
}

sub checktaint {
    my $val = shift;
    &dieTaint if ($val =~ /[`;(<>|&]/);
    $val;
}

sub init_offline {
    my $i = 0;
    return if ($htpl_pkg);
    foreach (@main'ARGV) {
        ${'main::arg' . ++$i} = $_;
    }
    $htpl_pkg = 'main';
    &initrun;
}

sub getcc {
    return $HTML::HTPL::Config::ccprog if ($HTML::HTPL::Config::ccprog);

    my ($cc, $p, $d);
    foreach $cc (qw(gcc shlicc2 cc egcs)) {
        $p = `which $cc`;
        chop $p;
        return $p if ($p);
        foreach $d (qw(/bin /sbin /usr/bin /usr/sbin
              /usr/local/bin/ /usr/local/sbin/ /u/local/bin/)) {
            $p = "$d/$cc";
            return $p if (-e $p);
        }
    }
    Carp::croak("No C compiler");
}

sub dieTaint {
    &HTML::HTPL::Lib::rewind;
    &HTML::HTPL::Lib::setmimetype("text/plain");
    my $log = sprintf("Taint attempt from %s on %s", getvar('REMOTE_HOST'),
          scalar(localtime));
    &HTML::HTPL::Lib::takelog($log, $HTML::HTPL::Config::htpl_system_log);
    print "$log\n";
    exit;
}

sub isheb {
    shift =~ /[\xE0-\xFA]/;
}

sub readini {
    return unless (-f 'website.ini');

    eval "require IniConf;";
    return unless ($IniConf::VERSION);
    my $cfg = new IniConf( -file => 'website.ini', -nocase => 1);
    my (%hash, $s, $p, $v);
    foreach $s ($cfg->Sections) {
        foreach $p ($cfg->Parameters($s)) {
            $hash{$s, $p} = $cfg->val($s, $p);
        }
    }    
    sethash('config', %hash);
}

sub pushvars {
    my @vars = @_;
    @vars = @{$vars[0]} if (!$#vars && UNIVERSAL::isa($vars[0], 'ARRAY'));
    my $hash = {};
    foreach (@vars) {
        $hash->{$_} = &getvar($_);
    }
    push(@__htpl_stack, $hash);
}

sub popvars {
    my $hash = pop @__htpl_stack;
    &publish(%$hash);
}

sub pkghash {
    %{(eval "*$_[0]\::")};
}

sub pkganalyze {
    my ($pkg, $full) = @_;
    my %hash = pkghash($pkg);
    my @result;
    my $pre = $full ? "$pkg\::" : "";
    foreach (keys %hash) {
        my $t = "*${pkg}::$_";
        push(@result, '$' . $pre . $_) if (eval("$t\{SCALAR}"));
        push(@result, '@' . $pre . $_) if (eval("$t\{ARRAY}"));
        push(@result, '%' . $pre . $_) if (eval("$t\{HASH}"));
        push(@result, '&' . $pre . $_) if (eval("$t\{CODE}"));
    }
    @result;
}

sub pkglist {
    my ($pkg, $char, $full) = @_;
    $char =~ s/^(.)$/^\\$1/;
    grep /$char/, &pkganalyze($pkg, $full);
}

sub getpkg {
    my $caller = (caller)[0];
    my $loop;
    do {
        $loop++;
        my $this = (caller($loop))[0];
        return $this if ($this ne $caller);
    }
}

sub mytime {
    $have_time_hires ? Time::HiRes::gettimeofday() : time;
}

sub mytimesince {
    my $from = shift;
    my $t = &mytime;
    $have_time_hires ? tv_interval($t, $from) : abs($t - $from);
}

sub compileutil {
    my $exp = shift;
    my @tokens = split(/\s+/, $exp);
    my @trans = map {
        s/^AND$/&&/i;
        s/^OR$/||/i;
        s/^NOT$/!/i;
        /^[a-z]/i && tr/A-Z/a-z/ && 
            ((":lt:gt:eq:ge:le:ne:" =~ /$_/i)
              || ($_ = "\$hash->{'$_'}"));
        $_;
    } @tokens;
    my $code = qq!sub {
        my \$hash = shift;
        ! . join(" ", @trans) . qq!;
    }!;
    my $ref = eval($code);
    &HTML::HTPL::Lib::htdie($@) unless (UNIVERSAL::isa($ref, 'CODE'));
    $ref;
}

sub DEBUG (&) {
    return unless ($debug_file);
    my $code = shift;
    &HTML::HTPL::Lib::begintransaction;
    eval '&$code';
    my $txt = &HTML::HTPL::Lib::endtransaction;
    open(O, ">>$debug_file");
    print O $txt;
    print O "$@\n" if ($@);
    close(O);
}

sub scriptdir {
    my $slash = &HTML::HTPL::Lib::slash;
    my @tokens = split($slash, $0);
    pop @tokens;
    pop @tokens if ($tokens[-1] eq 'htpl-cache');
    join($slash, @tokens);
}

1;
