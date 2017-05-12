package Xmms;

use strict;
use Xmms::Remote ();
use Xmms::Config ();
use Term::ReadLine ();
use File::Basename qw(basename dirname);
use Exporter ();
use Symbol ();
use File::Find qw(finddepth);
use Data::Dumper ();
use Text::ParseWords ();

{
    no strict;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(shell);
    $VERSION = '0.12';
}

my $Help;

sub helpstr {
    return $Help if $Help;

    my $cmds = Xmms->Cmds;
    my @retval;

    for my $cmd (@$cmds) {
	my $cv = Xmms::Cmd->can($cmd);
	next unless defined $cv;
	my $sub = \&{"Xmms::\u${cmd}Cmds"};
	my($options, $args);
	if (defined &$sub) {
	    $options = '[' . join('|', @{ $sub->() }) . ']';
	}
	if (my $p = prototype $cv) {
	    if ($p eq '*') {
		$args = "(user defined)";
	    }
	    else {
		$p =~ s/^.//;
		$args = ($p =~ /^;/) ? "[arg]" : "arg";
	    }
	}
	my $retval = $cmd . ' ' x (10 - length($cmd));
	$retval .= $options ? "$options $args" : $args;
	push @retval, $retval;
    }
    $Help = join "\n", @retval, "";
}

my $AbbrevStr;

sub abbrevstr {
    return $AbbrevStr if $AbbrevStr;

    my(%seen, @retval);
    my $alias = CmdAlias();
    for (sort keys %$alias) {
	next if $seen{$alias->{$_}}++;
	my $pad = " " x (4 - length);
	push @retval, "   $_ $pad => $alias->{$_}", 
    }
    $AbbrevStr = join "\n", @retval, "";
}

my %jtime;
{
    package Xmms::Jtime;
    no strict;
    @ISA = qw(Xmms::SongChange);
    sub TIEHASH { bless [$_[1]], $_[0] }
    sub FETCH { shift->[0]->jtime_FETCH(@_) }
    sub STORE { shift->[0]->jtime_STORE(@_) }
}

my($remote, $config, $pconfig, $sc, $term, @history);
my $use_sc = 0;
my $is_cpl = 0;
my $Signal = 0;
my $Pid = 0;

sub is_cpl { $is_cpl }

eval {
    require Xmms::SongChange;
};
if ($@) {
    undef &Xmms::Cmd::crop;
}

sub init_songchange {
    return if $sc;
    $sc = Xmms::SongChange->new($remote);
    tie %jtime, 'Xmms::Jtime', $sc;
}

my @urldb = ();
sub urldb { \@urldb }

sub init_urldb {
    if (open FH, "$ENV{HOME}/.xmms/.perlurldb") {
	while (<FH>) {
	    s/^\s+//;
	    next unless /^http:/;
	    s/\s+$//;
	    chomp;
	    push @urldb, $_;
	}
	close FH;
    }
}

sub init {
    $config = Xmms::Config->new(Xmms::Config->file);
    $pconfig = Xmms::Config->new(Xmms::Config->perlfile);
    $remote = Xmms::Remote->new;

    unless ($remote->is_running) {
	exec "xmms" unless $Pid = fork;
	Xmms::sleep(0.25);
	local $SIG{ALRM} = sub {
	    die "connect to xmms failed: $!";
	};
	alarm 5;
	1 while not $remote->is_running;
	alarm 0;
	$remote->all_win_toggle(0);
    }

    init_urldb();

    if ($use_sc) {
	init_songchange();
    }

    eval {
	require MPEG::MP3Info;
	MPEG::MP3Info::->import(qw(get_mp3tag get_mp3info set_mp3tag));
    };
    if ($@) {
	*get_mp3tag = *get_mp3info = sub { undef };
    }

    eval {
	require Term::ANSIColor;
	Term::ANSIColor::->import(qw(color));
    };
    if ($@) {
	*color = sub { "" };
    }

    eval {
	require Audio::CD;
    };
}

sub shell {
    $term = Term::ReadLine->new(__PACKAGE__);
    init();
    boot();

    my $attr = $term->Attribs;
    $attr->{completion_function} = \&cpl;
    $readline::rl_completer_word_break_characters = 
      $readline::rl_basic_word_break_characters = "\\\t\n' \"`\@><=;|&{(";

    init_keybindings();
    $sc->run if $sc;

    my $rcfile = "$ENV{HOME}/.xmms/.perlrc";
    if (-e $rcfile) {
	Xmms::Cmd->history("<$rcfile");
    }   

    while (1) {
	$Signal = 0;
	run_cmd($term->readline("xmms> "));
    }
}

sub version {
    print "xmms shell -- remote control v$Xmms::VERSION\n";

    printf "ReadLine support..........%s\n", 
    $term->ReadLine ne "Term::ReadLine::Stub" ? "enabled" :
      "available (install Bundle::Xmms)";

    print "MPEG::MP3Info support.....", ($INC{'MPEG/MP3Info.pm'} ?
      "enabled" : "available"), "\n";

    print "Audio::CD support.........", ($INC{'Audio/CD.pm'} ?
      "enabled" : "available"), "\n";

    print "Term::ANSIColor support...", ($INC{'Term/ANSIColor.pm'} ?
	"enabled" : "available"), "\n";
}

sub boot {
    version();

    my $op = $config->read(xmms => 'output_plugin');
    if ($op =~ /disk_writer/) {
	print <<EOF;
*************************************************************
* WARNING:
* Your xmms Output Plugin is set to disk_writer,
* which is probably not what you want.
* I\'ll pop up a the preferences window for you to change...
*************************************************************
EOF
        sleep 1;
	$remote->show_prefs_box;
    }
}

#the default C-c binding hosed my tty
sub readline::F_Xmms_interrupt {
    readline::F_UnixLineDiscard();
    Xmms::Cmd->quit if $Signal++;
}

sub readline::F_Xmms_volume_up {
    Xmms::Cmd::volume(undef, '+');
}

sub readline::F_Xmms_volume_down {
    Xmms::Cmd::volume(undef, '-');
}

#remote time slider doesnt work so well
#sub readline::F_Xmms_time_up {
#    Xmms::Cmd::time(undef, '+');
#}

#sub readline::F_Xmms_time_down {
#    Xmms::Cmd::time(undef, '-');
#}

my %keybindings = (
    'M-=' => 'next',
    'M--' => 'prev',
    'M-.' => 'stop',
    'M-/' => 'play',
    'M-,' => 'pause',
    'M-~' => 'shuffle',
    'M-`' => 'history',
    'M-@' => 'repeat',
    'M-\\\\' => 'jtime',
    'M-m' => 'mtime',
    'M-c' => 'crop',
    'C-c' => 'interrupt',
    'M-e' => 'eject',
    qq/"\e[A"/  => 'volume_up',
    qq/"\e[B"/  => 'volume_down',
    qq/"\e[[A"/ => 'volume_up',
    qq/"\e[[B"/ => 'volume_down',
#    qq/"\e[C"/,  'time_up',
#    qq/"\e[D"/,  'time_down',
#    qq/"\e[[C"/,  'time_up',
#    qq/"\e[[D"/,  'time_down',
);

my %window_bindings = (
    'M-w' => 'main',
    'M-l' => 'pl',
    'M-q' => 'eq',
    'M-a' => 'all',
);

sub init_keybindings {
    my @code;
    return unless readline::->can('rl_bind');

    while (my($k,$v) = each %keybindings) {
	push @code, <<EOF;
    *F_Xmms_$v = sub { Xmms::Cmd::$v(undef) } unless defined &F_Xmms_$v;
    rl_bind('$k', 'xmms_$v');
EOF
    }
    while (my($k,$v) = each %window_bindings) {
	push @code, <<EOF;
    *F_Xmms_window_$v = 
         sub { Xmms::Cmd::window('','$v','') } unless defined &F_Xmms_window_$v;
    rl_bind('$k', 'xmms_window_$v');
EOF
    }

    for (1..9) {
	push @code, <<EOF;
	sub F_Xmms_$_ { Xmms::Cmd->track($_) }
	rl_bind('M-$_', 'xmms_$_');
EOF
    }

    eval "package readline;\n@code"; die $@ if $@;
}

sub run_cmd {
    if ($_[0] =~ s/^\s*\+//) {
	eval "{package Xmms; no strict; @_}";
	Xmms::Cmds(1); #sync
	$Help = ""; #invalidate cache
    }
    else {
	for my $cmd (split /;/, $_[0]) {
	    eval {
		rrun_cmd(Xmms::interp($cmd));
	    };
	}
    }
    print Xmms::highlight(Error => $@) if $@;
}

use Text::Abbrev qw(abbrev);

my $CmdAlias = "";
my @Cmds = (); 

Xmms::Cmds(1); #init

my $ignore_cmd = join '|', qw{can};

sub Cmds {
    if (@_) {
	@Cmds = sort grep { 
	    package Xmms::Cmd;
	    defined &$_;
	} keys %Xmms::Cmd::;
	$CmdAlias = abbrev @Cmds;
    }
    \@Cmds;
}

sub CmdAlias { $CmdAlias }

sub resolve {
    my $cmd = shift;
    return $cmd if Xmms::Cmd->can($cmd);
    return $CmdAlias->{$cmd} if $CmdAlias->{$cmd};
    return undef;
}

sub rrun_cmd {
    my($line) = @_;
    local *CMD;
    my($cmd, $args) = split /\s+/, $line, 2;

    unless ($is_cpl) {
	return unless $cmd;
    }
    $args =~ s/\s+$//;	

    if (my $command = Xmms::resolve($cmd)) {
	Xmms::Cmd->$command($args);
	push @history, $line;
	shift @history if @history > 100; #?
	#$term->SetHistory(@history);
    }
    elsif (open CMD, "$cmd $args|") {
	local $/;
	print {Xmms::pager()} <CMD>;
	close CMD;
    }
    else {
	print Xmms::highlight(Error => "unknown command: `$cmd'\n");
    }
}

if ($0 eq '-e') {
    no strict;

    for my $cmd (@Cmds) {
	push @EXPORT, $cmd;
	*$cmd = sub { 
	    init() unless $remote;
	    Xmms::Cmd->$cmd(@_ ? @_ : @ARGV);
	};
    }
}

my @PATH = split ':', $ENV{PATH};
my %cmdhash;
my $hashsize = 25;
keys %cmdhash = $hashsize;

sub xcmdcpl {
    my $pcmd = shift;
    my $guess = sub { grep /^$pcmd/o, keys %cmdhash };
    my @guess = $guess->();
    return \@guess if @guess;
    for my $path (@PATH) {
	local *DH;
	opendir DH, $path or next;
	for (readdir DH) {
	    next unless /^$pcmd/ and -x "$path/$_";
	    $cmdhash{$_}++;
	}
	closedir DH;
    }
    @guess = $guess->();
    hashtrunc(\%cmdhash, $hashsize);
    \@guess;
}

sub hashtrunc {
    my($hash, $max) = @_;
    my $keys = keys %$hash;
    while ($keys-- > $max) {
	my $k = each %$hash;
	delete $hash->{$k};
    }
}

sub cpl {
    my($word, $line, $pos) = @_;
    my($cmd, $rest) = split /\s+/, $line, 2;

    if ($cmd =~ s/^\!(.*)/history/) {
	$rest = $1;
    }

    my $command = defined $rest ? Xmms::resolve($cmd) : $cmd;
    if (Xmms::Cmd->can($command) and prototype("Xmms::Cmd::$command")) {
	$is_cpl = 1;
	my @retval = Xmms::Cmd->$command($rest);
	$is_cpl = 0;
	return @retval;
    }

    my @guess = grep /^$cmd/, @Cmds;
    return @guess if @guess;
    unless ($rest) {
	my $guess = xcmdcpl($cmd);
	return @$guess;
    }
    return Xmms::filecomplete((split /\s+/, $rest)[-1]);
}

sub playlist_is_empty {
    my $no_msg = shift;
    unless ($remote->get_playlist_length) {
	print Xmms::highlight(Error => "playlist is empty\n") unless $no_msg;
	return 1;
    }

    return 0;
}

sub playlist_do {
    my($thing, $pat) = @_;

    return unless $remote->get_playlist_length;

    my %search = (
        file  => $remote->get_playlist_files, 
	title => $remote->get_playlist_titles,
    );
    my $search_list = $search{$thing};
    my @new_playlist;

    #let * mean .*
    $pat =~ s/([^.]|^)\*/$1 . ".*"/eg;
    #if you fancy !~
    my $negate = ($pat =~ s/^\!//);

    for (my $i = 0; $i < @{ $search{file} }; $i++) {
	my $matched = $search_list->[$i] =~ /$pat/i;
	push @new_playlist, $search{file}->[$i] if 
	  $negate ? !$matched : $matched;

    }

    $remote->playlist(\@new_playlist) if @new_playlist;
}

sub filesel_path {
    my $val = shift;

    if ($val) {
	$pconfig->write(perl => 'play_path', $val);	
    }

    return unless defined wantarray;

    $pconfig->read(perl => 'play_path') ||	
      $config->read(xmms => 'filesel_path') ||
	$ENV{MP3_HOME};
}

sub urlsel {
    my $val = shift;

    if ($val) {
	$pconfig->write(perl => 'urlsel', $val);	
    }

    return unless defined wantarray;

    $pconfig->read(perl => 'urlsel') || qw(http://);
}

sub historysel {
    my $val = shift;

    if ($val) {
	$pconfig->write(perl => 'historysel', $val);	
    }

    return unless defined wantarray;

    $pconfig->read(perl => 'historysel') || filesel_path();
}

sub defaultpaths {
    '.', filesel_path(), historysel(), "$ENV{HOME}/.xmms";
}

sub guesspath {
    my($file) = @_;

    return $file if $file =~ m:^/:;
    for (defaultpaths()) {
	my $guess = "$_/$file";
	return $guess if -e $guess;
    }

    $file;
}

sub change_pos {
    my $cv = shift;
    my $track = $remote->get_playlist_pos;

    $cv->(@_);

    unless ($remote->get_playlist_length > 1) {
	return;
    }

    waitfor(sub { $track != $remote->get_playlist_pos });
}

sub waitfor (&) {
    my $true = shift;

    eval {
	local $SIG{ALRM} = sub {die};
	alarm 2;
	Xmms::sleep(0.05) while !$true->();
	alarm 0;
    };
}

sub rl_termchar {
    $readline::rl_completer_terminator_character = shift;
}

sub sleep {
    select(undef, undef, undef, shift);
}

sub clearscreen {
    readline::F_ClearScreen(shift);
    '';
}

sub pager {
    my $fh = Symbol::gensym();

    if ($ENV{PAGER}) {
	open $fh, "|$ENV{PAGER}";
    }
    else {
	$fh = \*STDOUT;
    }

    return $fh;
}

sub open_careful {
    my $file = shift;

    if (-e $file) {
	my $ans = $term->readline("$file exists: overwrite? [y/n] ");
	if ($ans =~ /^n/i) {
	    print Xmms::highlight(Warn => "save aborted\n");
	    return;
	}
    }

    my $fh = Symbol::gensym();
    open $fh, ">$file" or die "open $file: $!";

    return $fh;
}

#thanks andreas
my %colors = (
   Error => 'bold red on_white',
   Msg   => 'bold blue on_white', 
   Warn  => 'bold red on_yellow',
);

sub highlight {
    my($how, $what) = @_;

    my $nl = chomp($what) ? "\n" : "";

    return join '',
    color($colors{$how} ? $colors{$how} : $how), $what, color('reset'), $nl;
}

package Xmms::CD;

sub new {
    my $class = shift;

    my $id = 0;

    if ($INC{'Audio/CD.pm'}) {
	$id = Audio::CD->init;
    }

    bless {
	   id => $id,
	  }, ref($class) || $class;
}

sub id {
    my $self = shift;
    return 0 unless $self->{id};
    sprintf "%lx", $self->{id}->cddb->discid;
}

sub cd_is_playing {
    $remote->get_playlist_file(0) =~ /\.cda$/;
}

sub eject {
    my $self = shift;
    my $args = shift;
    my $cd_is_playing = $self->cd_is_playing;
    unless ($cd_is_playing or $args eq 'cd' and $self->{id}) {
	$remote->eject;
	return;
    }

    if ($cd_is_playing) {
	$remote->stop;
	1 while $remote->is_playing;
    }
    for (1..3) {
	my $rc = $self->{id}->eject;
	last if $rc == 0;
	sleep(1);
    }
}

package Xmms::Sort;

sub order {
    my $args = shift;
    my $files = $remote->get_playlist_files;
    my $range = Xmms::range($args);
    my @new;
    my $i = 0;

    for (@$range) {
	$files->[$_-1] =~ /(\d+)\.cda$/;
	$Xmms::CD::order{$i++} = int($1)-1;
	push @new, $files->[$_-1];
    }

    $remote->playlist(\@new);
}

sub reverse {
    $remote->playlist([reverse @{ $remote->get_playlist_files }]);
}

#thanks perlfaq4.pod
sub random {
    my $files = $remote->get_playlist_files;

    for (my $i = @$files; --$i; ) {
	my $j = int rand ($i+1);
	next if $i == $j;
	@$files[$i,$j] = @$files[$j,$i];
    }

    $remote->playlist($files);
}

sub title {
    my @list;
    my %playlist;
    my $titles = $remote->get_playlist_titles;

    @playlist{ @$titles } = @{ $remote->get_playlist_files };
    @$titles = sort @$titles;

    for (@$titles) {
	push @list, $playlist{$_};
    }

    $remote->playlist(\@list);
}

sub path {
    $remote->playlist([sort @{ $remote->get_playlist_files }]);
}

sub file {
    my(@list) = sort { 
	Xmms::basename($a) cmp Xmms::basename($b);
    } @{ $remote->get_playlist_files };

    $remote->playlist(\@list);
}

my %decending = map { $_, 1 } qw(new large);

sub Xmms::File::sort {
    my $sort = shift;
    my @list;

    for my $file (@{ $remote->get_playlist_files }) {
	stat $file;
	my $entry = {
		     file => $file,
		     size   => (stat _)[7],
		     access => (stat _)[8],
		     mtime  => (stat _)[9],
		     ctime  => (stat _)[10],
		    }; 
	$entry->{old}   = $entry->{new}   = $entry->{mtime};
	$entry->{large} = $entry->{small} = $entry->{size};
	push @list, $entry;
    }

    @list = $decending{$sort} ? 
      (sort { $b->{$sort} <=> $a->{$sort} } @list) : 
      (sort { $a->{$sort} <=> $b->{$sort} } @list);

    $remote->playlist([map { $_->{file} } @list]);
}

{
    for my $meth (qw(old new large small access)) {
	no strict 'refs';
	*$meth = sub { Xmms::File::sort($meth) };
    }
}

sub Xmms::FileInfo::sort {
    my $sort = uc shift;
    my @list;

    for my $file (@{ $remote->get_playlist_files }) {
	my $tag = Xmms::get_mp3tag($file);
	$tag->{FILE} = $file;
	push @list, $tag;
    }

    $remote->playlist([map { $_->{FILE} } 
		       sort {
			   my($aval, $bval) = ($a->{$sort}, $b->{$sort});
			   ($aval =~ /^\d+$/ and $bval =~ /^\d+$/) ?
			     $aval <=> $bval : $aval cmp $bval;
		       } @list
		      ]);
}

{
    for my $meth (qw(album artist comment genre tracknum year)) {
	no strict 'refs';
	*$meth = sub { Xmms::File::sort($meth) };
    }
}

package Xmms::Cmd;

sub alias ($$) {
    my($self, $args) = @_;
    my($sub, $stuff) = split /\s+/, $args, 2;
    no strict;
    if ($stuff =~ /^(\S+)/ and $sub eq $1) {
	die "alias recursion detected\n";
    }
    *{"Xmms::Cmd::$sub"} = sub (*) { Xmms::run_cmd($stuff) };
    Xmms::Cmds(1); #sync
    $Help = ""; #invalidate cache
}

sub export ($@) {
    my($self, $args) = @_;
    package Xmms;
    no strict;

    if ($is_cpl) {
	my $arg = (split /\s+/, $args)[-1];
	return grep /^$arg/, keys %ENV;
    }

    for my $ex (Text::ParseWords::parse_line('\s+', 0, $args)) {
	my($key,$val) = split /=/, $ex;
	if ($val) {
	    $ENV{$key} = ${"Xmms::$key"} = $val;
	}
	else {
	    *{"Xmms::$key"} = \$ENV{$key};
	}
    }
}

sub help { print {Xmms::pager()} Xmms::helpstr() }

my %sig_name = ();
{
    my $i = 0;

    for (split /\s+/, $Config::Config{sig_name}) {
	$sig_name{$_} = $i++;
    }
}

sub quit {
    $remote->stop;
    Xmms::resume_config(1);
    $pconfig->write_file(Xmms::Config->perlfile);
    print Xmms::highlight(Msg => "Goodbye\n");
    $remote->quit;
    exit;
}

sub resume {
    my $str = Xmms::resume_config();
    return unless $str;
    my $resume = eval $str;

    if ($resume->{'files'}) {
	Xmms::playlist_load($resume->{'files'});
    }
    Xmms::sleep(0.25);
    $remote->set_playlist_pos($resume->{'pos'}) if exists $resume->{'pos'};
    Xmms::sleep(0.25);
    $remote->jump_to_time($resume->{'time'}) if exists $resume->{'time'};
}

sub Xmms::resume_config {
    return if Xmms::playlist_is_empty(1);
    my $save = shift;
    if ($save) {
	my $resume = {
		      'files' => "$ENV{HOME}/.xmms/perl_resume_files",
		      'pos' => $remote->get_playlist_pos,
		      'time' => $remote->get_output_time,
		     };
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Terse = 1;
	$pconfig->write(perl => 'resume', 
			Data::Dumper::Dumper($resume));
	Xmms::List::save($resume->{'files'}, 1);
    }
    else {
	$pconfig->read(perl => 'resume');
    }
}

sub Xmms::History::clear { @history = () }

#prototypes are just for help()
sub history ($;$) {
    my($self, $args) = @_;

    #M-`
    unless ($_[0]) {
	my $line = $readline::rl_History[-1];
	Xmms::run_cmd($line);
	return;
    }

    if ($is_cpl) {
	if ($args =~ /^\d+$/) {
	    return grep /^$args/, (1..$#history);
	}
	elsif($args =~ s/^([<>])//) {
	    return Xmms::filecomplete($args, \&Xmms::historysel);
	}
	else {
	    return grep /^$args/, reverse @history;
	}
    }
    
    unless ($args) {
	for (my $i = 0; $i < @history; $i++) {
	    printf "%d\t$history[$i]\n", $i+1;
	}
	return;
    }

    if (my $meth = Xmms::History->can($args)) {
	return $meth->();
    }

    my $line;
    if ($args =~ /^\d+$/) {
	$line = $history[$args-1];
    }
    elsif ($args =~ s/^<//) {
	my $fh = Symbol::gensym();
	$args = Xmms::guesspath($args);
	open $fh, $args or die "open $args: $!";
	while (<$fh>) {
	    next if /^#/;
	    next if /^history/;
	    print unless s/^\@// or /^\+/;
	    chomp;
	    Xmms::run_cmd($_);
	}
	close $fh;
	Xmms::historysel(Xmms::dirname($args)) unless $args =~ /\.perlrc$/;
    }
    elsif ($args =~ s/^>//) {
	my $fh = Xmms::open_careful($args);
	print $fh join "\n", grep { !/^history/ } @history, "";
	close $fh;
    }
    else {
	$line = $args;
    }

    Xmms::run_cmd($line);
}

my @windows = qw(main pl eq prefs all);
sub Xmms::WindowCmds { \@windows }
my %windows = map { $_,1 } @windows;

sub Xmms::Usage::window {
    my $opts = join '|', @windows;

    print Xmms::highlight(Error => 
			    "usage: window [$opts] [hide|show]\n");
}

my %window_state = (
    'main' => 0, 'pl' => 0, 'eq' => 0, 'all' => 0,
);

sub window ($$$) {
    my($self, $args) = @_;
    my($win, $val) = split /\s+/, $args;

    if ($is_cpl) {
	if ($win and $windows{$win}) {
	    return grep /^$val/, qw(show hide);
	}
	else {
	    return grep /^$win/, @windows;
	}
	return $args;
    }

    $val ||= $window_state{$win} ? 'hide' : 'show';

    unless ($win && $val) {
	Xmms::Usage->window;
	return;
    }

    my $meth = "${win}_win_toggle";
    $window_state{$win} = $val eq 'show';

    if ($remote->can($meth)) {
	$remote->$meth($window_state{$win});
    }
    else {
	Xmms::Usage->window;
    }
}

my @BalanceCmds = sort grep { Xmms::Balance->can($_) } keys %Xmms::Balance::;
sub Xmms::BalanceCmds { \@BalanceCmds }

sub Xmms::Usage::balance {
    my $opts = join '|', @BalanceCmds;

    print Xmms::highlight(Error => 
			    "usage: balance [$opts] [value]\n");
}

{
    package Xmms::Balance;

    sub center {
	$remote->set_balance(0);
    }
    sub left {
	my($self, $val) = @_;
	$remote->set_balance(-$val);
    }
    sub right {
	my($self, $val) = @_;
	$remote->set_balance($val);
    }
}

sub balance ($;$$) {
    my($self, $args) = @_;
    my($subcmd, $val) = split /\s+/, $args;

    if ($is_cpl) {
	if (defined $val) {
	    return grep /^$val/, map {$_ * 10} (1..10);
	}
	else {
	    return grep /^$subcmd/, @BalanceCmds;
	}
    }

    if ($subcmd) {
	if (Xmms::Balance->can($subcmd)) {
	    Xmms::Balance->$subcmd($val);
	}
	else {
	    Xmms::Usage->balance;
	}
    }
    else {
	my $bal = $remote->get_balancestr;
	print Xmms::highlight(Msg => "$bal\n");
    }
}

sub volume ($;$) {
    my($self, $args) = @_;
    $args =~ s/ $// if $args;

    my $slide = ($is_cpl || $self eq undef);
    my $vol = $remote->get_main_volume;

    if ($args eq '-') {
	$remote->set_main_volume(--$vol);
	Xmms::rl_termchar('');
	return Xmms::clearscreen($is_cpl) if $slide;
    }
    elsif ($args eq '+') {
	$remote->set_main_volume(++$vol);
	Xmms::rl_termchar('');
	return Xmms::clearscreen($is_cpl) if $slide;
    }
    elsif ($is_cpl) {
	return grep /^$args/, map {$_ * 10} 1..10;
    }
    elsif ($args =~ /^\d+$/) {
	$remote->set_main_volume($args);
    }

    if ($args and $args ne $vol) {
	Xmms::waitfor(sub { $remote->get_main_volume != $vol });
    }

    $vol = $remote->get_main_volume;
    print Xmms::highlight(Msg => "    $vol%    \n");
}

sub next { 
    Xmms::change_pos(sub { $remote->playlist_next });
    current() if $_[0];
}

sub prev { 
    Xmms::change_pos(sub { $remote->playlist_prev });
    current() if $_[0];
}

sub crop {
    my($self, $args) = @_;
    return unless $use_sc;
    my($track, $time);
    if ($args) {
	($track, $time) = split /\s+/, $args;
    }
    else {
	$track = $remote->get_playlist_pos+1;
	$time = $remote->get_output_timestr;
    }
    $sc->crop_STORE($track, $time);
}

sub change ($;$) {
    my($self, $args) = @_;
    return grep /^$args/, qw(on off) if $is_cpl;

    if ($args) {
	Xmms::init_songchange();
	$use_sc = ($args =~ /^on$/i);
	my $meth = $use_sc ? "run" : "stop";
	$sc->$meth();
    }
    my $on_off = $use_sc ? "is running" : "stopped";
    print Xmms::highlight(Msg => "SongChange thread $on_off\n");
}

sub current {
    return if Xmms::playlist_is_empty();

    my $track = $remote->get_playlist_pos;
    print Xmms::highlight(Msg => sprintf "%d - %s\n", $track+1, 
			  $remote->get_playlist_title($track)); 

    my($rate, $freq, $nch) = $remote->get_info;
    print Xmms::highlight(Msg => sprintf "[%s] [%d kbps][%d kHz][%s]\n", 
			    $remote->get_output_timestr,
			    ($rate / 1000), ($freq / 1000),
			    $nch == 2 ? "stereo" : "mono");
}

sub pause   { $remote->pause }
sub stop    { $remote->stop }
sub clear   { 
    if ($use_sc) {
	$sc->clear;
    }
    $remote->playlist_clear;
}
sub shuffle { $remote->toggle_shuffle }
sub eject   { shift; Xmms::CD->new->eject(@_) }

sub Xmms::urlcomplete {
    my $arg = shift;
    if ($arg eq '-') {
	if (my $url = Xmms::urlsel()) {
	    Xmms::rl_termchar('');
	    return $url;
	}
    }
    else {
	return @urldb ? (grep /^$arg/, @urldb) : qw(http://);
    }
}

my $xmms_scalars = sub {
    package Xmms;
    no strict;
    grep { defined $$_ } keys %Xmms::;
};

sub Xmms::interp {
    my $string = shift;
    $Xmms::file = $remote->get_playlist_file;
    eval "{package Xmms; no strict; qq($string)}";
}

sub Xmms::filecomplete {
    my $arg = shift;

    if (my $earg = Xmms::interp($arg)) {
	$arg = $earg;
    }
    else {
	if ($arg =~ s/^\$//) {
	    Xmms::rl_termchar('/');
	    return map { "\$$_" } grep /^$arg/, $xmms_scalars->();
	}
    }

    my $dpath = shift || \&Xmms::filesel_path;
    if ($arg eq '-') {
	if (my $path = $dpath->()) {
	    $path =~ s:/$::;
	    Xmms::rl_termchar('/');
	    return $path;
	}
    }
    elsif ($arg eq '!') {
	if (my $path = Xmms::historysel()) {
	    $path =~ s:/$::;
	    Xmms::rl_termchar('/');
	    return $path;
	}
    }

    if ($arg =~ /\#$/) {
	my $id = Xmms::CD->new->id;
	$arg =~ s/\#$/$id/ if $id;
    }

    my @retval = glob($arg."*");
    @retval = $arg unless @retval;

    if (@retval > 1) {
	return @retval;
    }
    else {
	if (-d $retval[0] and $retval[0] !~ m:/$:) {
	    Xmms::rl_termchar('/');
	}
	return @retval;
    }
}

sub Xmms::range {
    my $string = shift;
    $string =~ s/\s+//g;
    my @entries = split ',', $string;
    my @range;
    for (@entries) {
	if (/^\d+$/) {
	    push @range, $_;
	}
	elsif (/^(\d+)\.\.(\d+)$/) {
	    push @range, $1 .. $2;
	}
    }
    \@range;
}

sub delete ($$) {
    my($self, $args) = @_;
    if ($is_cpl) {
	my $len = $remote->get_playlist_length;
	return grep /^$args/, (1..$len);
    }

    for (sort { $b <=> $a } @{ Xmms::range($args) }) {
	$remote->playlist_delete($_-1);
    }
}

sub add ($$) {
    my($self, $args) = @_;

    my(@cpl) = Xmms::filecomplete($args);
    return @cpl if $is_cpl;

    if ($args) {
	if (-d $args) {
	    Xmms::filesel_path($args);
	}
	$remote->playlist_add(\@cpl);
    }
}

sub url ($$) {
    my($self, $args) = @_;

    my(@urls) = Xmms::urlcomplete($args);
    return @urls if $is_cpl;

    if ($args) {
	Xmms::urlsel($urls[0]);
	for (@urls) {
	    $remote->playlist_add_url($_);
	}
	$remote->play;
    }
}

sub Xmms::playlist_load {
    my($file) = @_;
    my $fh = Symbol::gensym();
    open $fh, $file or die "open $file: $!";

    my @files;
    while (<$fh>) {
	chomp;
	push @files, $_;
    }

    $remote->playlist(\@files);
    close $fh;
}

{
    package Xmms::List;

    sub size {
	my($file) = @_;
	local *FH;
	open FH, $file;
	my $size = 0;
	while (<FH>) {
	    chomp;
	    next unless -e $_;
	    my $fsize = -s _;
	    $size += $fsize;
	    printf "%s %s\n", Xmms::basename($_), Xmms::size_string($fsize);
	}
	close FH;
	printf "Total: %s\n", Xmms::size_string($size);
    }

    sub save {
	my($file, $is_config) = @_;

	unless (-e $file) {
	    $file = glob($file);
	}
	if ($is_config) {
	    unlink $file;
	}
	my $fh = Xmms::open_careful($file);

	for (@{ $remote->get_playlist_files }) {
	    print $fh "$_\n";
	}

	if (close $fh) {
	    print Xmms::highlight(Msg => "playlist saved\n") unless $is_config;
	}
    }
}

my @ListCmds = sort grep { Xmms::List->can($_) } keys %Xmms::List::;
sub Xmms::ListCmds { \@ListCmds }

sub list ($$) {
    my($self, $args) = (shift,shift);
    $args .= " @_" if @_;
    my($subcmd, $subargs) = split /\s+/, $args;
    
    if ($subcmd && $subargs) {
	if (my $meth = Xmms::List->can($subcmd)) {
	    my(@files) = Xmms::filecomplete($subargs);
	    if ($is_cpl) {
		return @files;
	    }
	    $meth->(@files);
	}
    }
    else {
	if ($args) {
	    my(@files) = Xmms::filecomplete($args);
	    if ($is_cpl) {
		if (my(@cpl) = grep /^$args/, @ListCmds) {
		    return @cpl;
		}
		return @files;
	    }
	    Xmms::playlist_load(@files);
	}
    }
}

my @SortCmds = sort grep { Xmms::Sort->can($_) } keys %Xmms::Sort::;
sub Xmms::SortCmds { \@SortCmds }

sub sort ($$) {
    my($self, $str) = @_;
    my($args, $subargs) = split /\s+/, $str, 2;

    unless ($is_cpl) {
	if (my $meth = Xmms::Sort->can($args)) {
	    $meth->($subargs);
	}
	else {
	    print Xmms::highlight(Error => "unknown sort method: $args\n");
	}
	return;
    }

    return grep /^$args/, @SortCmds;
}

sub play ($;$) { 
    my($self, $args) = @_;

    unless ($is_cpl) {
	if ($args) {
	    if ($args ne '/cdrom' and -d $args) {
		Xmms::filesel_path($args);
	    }
	    $remote->playlist([Xmms::filecomplete($args)]);
	}
	else {
	    $remote->play;
	}
	return;
    }
    
    Xmms::filecomplete($args);
}

my @DigCmds = ();
sub Xmms::DigCmds { 
    @DigCmds = (@{Xmms->InfoCmds}, 'file') unless @DigCmds;
    return \@DigCmds;
}

#I only have ~100 mp3z, dunno how much cpu more would burn, so pause
my $pause = 200;
sub dig ($$;$) {
    my($self, $args) = (shift,shift);
    $args .= " @_" if @_;
    my($path, $pat) = split /\s+/, $args, 2;

    if ($is_cpl) {
	if (my(@by) = grep /^$path/, @{Xmms::DigCmds()}) {
	    return @by;
	}
	elsif (my(@pm) = Xmms::filecomplete($path)) {
	    return @pm;
	}
	return;
    }

    my(@list, $search_by);
    my $dir = Xmms::filesel_path();

    if (-e $path) {
	$dir = $path;
	$args = $pat;
    }
    elsif (grep { $path eq $_ } @{Xmms::DigCmds()}) {
	$search_by = uc $path;
	$args = $pat;
    }   
    
    unless ($args) {
	print Xmms::highlight(Error => "no search pattern specified\n");
	return;
    }

    print Xmms::highlight(Msg => "searching in $dir...\n");
    my $depth = 0;
    Xmms::finddepth(sub {
			 my $file = "$File::Find::dir/$_";
			 if (++$depth >= $pause) {
			     print Xmms::highlight(Msg =>
						     "pause after $pause searches...\n");
			     sleep 1, $depth=0;
			 }
			 return unless /\.mp[123]$/;
			 my $tag = Xmms::get_mp3tag($file);
			 $tag->{FILE} = $file;
			 my @tagms = $search_by ? $tag->{$search_by} : 
			                          values %{$tag || {}};
			 my $tagmatch = sub {
			     for (@tagms) {
				 return 1 if /$args/i;
			     }
			     return 0;
			 };
			 return unless $tagmatch->();
			 push @list, $file;
		     }, $dir);

    if(@list) {
	Xmms::filesel_path($dir);
	if (!$remote->get_playlist_length) {
	    $remote->playlist(\@list);
	}
	else {
	    $remote->playlist_add(\@list);
	}
    }
}

sub track ($;$) {
    return if Xmms::playlist_is_empty();

    my($self, $args) = @_;
    my $title_maybe = $args;
    my $pos = $remote->get_playlist_pos;
    my $len = $remote->get_playlist_length;
    my @range = ();

    if ($args and $args =~ /\D+/) {
	@range = map { $_-1 } @{ Xmms::range($args) };
	$args = "";
    }

    if (!$args or $args eq ' ') {
	my @retval;
	unless (@range) {
	    @range = 0..$len-1;
	}
	for (@range) {
	    last if $_ >= $len;
	    my $num = $_ + 1;
	    my $title = $remote->get_playlist_title($_);
	    my $desc = "$num - $title";
	    my $jt = " {$jtime{$num}}" if $jtime{$num};
	    my($ctime, $repeat);
	    if ($use_sc) {
		if ($ctime = $sc->crop_FETCH($num)) {
		    $ctime = " >$ctime<";
		}
		my $count;
		($repeat, $count) = $sc->repeat_FETCH($num);
		if ($repeat) {
		    $repeat = " \@$count:$repeat";
		}
	    }
	    my $extra = join '', $jt, $ctime, $repeat;
	    if ($_ == $pos) {
		my $time = $remote->get_output_timestr;
		push @retval, Xmms::highlight(Msg => "$desc [$time]$extra");
	    }
	    else {
		my $time = $remote->get_playlist_timestr($_);
		my $t = "$desc ($time)$extra";
		push  @retval, $t;
	    }
	}
	return (@retval) if $is_cpl;
	#local $SIG{PIPE} = 'IGNORE';
	#local $SIG{INT} = 'IGNORE';
	print {Xmms::pager()} join "\n", @retval, "";
	return;
    }

    if ($args =~ /^\d+$/) {
	if ($is_cpl) {
	    return grep /^$args/, (1..$len);
	}
	else {
	    $remote->set_playlist_pos($args-1);
	}
    }
    else {
	my %titles;

	for (0..$len-1) {
	    my $title = $remote->get_playlist_title($_);
	    $title =~ s/ /-/g;
	    $titles{$title} = $_; 
	}

	if (exists $titles{$title_maybe}) {
	    $remote->set_playlist_pos($titles{$title_maybe});
	}
	else {
	    return sort grep /^$title_maybe/, keys %titles;
	}
    }
}

sub titles ($$) {
    my($self, $args) = @_;
    return if $is_cpl;
    Xmms::playlist_do("title", $args);
}

sub files ($$) {
    my($self, $args) = @_;
    return if $is_cpl;
    Xmms::playlist_do("file", $args);
}

sub repeat (;$)  { 
    my($self, $args) = @_;

    if ($is_cpl) {
	return grep /^$args/, qw(reset);
    }

    unless ($use_sc) {
	$remote->toggle_repeat;
	return;
    }
    if (defined $args) {
	my($track, $num) = split /\s+/, $args, 2;
	if ($track && $num) {
	    $sc->repeat_STORE($track, $num);
	}
	elsif ($track eq 'reset') {
	    $sc->repeat_reset;
	}
    }
    else {
	$remote->toggle_repeat;
    }
}

sub mtime {
    my $pos = $remote->get_playlist_pos+1;
    my $time = $remote->get_output_time/1000;
    $jtime{$pos} = sprintf "%d:%-2.2d", $time/60, $time % 60;
}

sub jtime ($;$$) { 
    my($self, $args) = (shift,shift);
    $args .= " @_" if @_;
    my $len = $remote->get_playlist_length;

    if ($args) {
	my($track, $time) = split /\s+/, $args;
	if ($is_cpl) {
	    return grep /^$args/, (1..$len) unless defined $time;
	    return $jtime{$track} || '0:00';
	}
	$jtime{$track} = $time;
    }
    else {
	return (1..$len) if $is_cpl;
	my $pos = $remote->get_playlist_pos+1;
	my $str = $jtime{$pos || '0:00'};
	$remote->jump_to_timestr($str);
    }
}

sub time ($;$) {
    my($self, $args) = @_;
    $args =~ s/ $// if $args;
    my $slide = ($is_cpl || $self eq undef);

    return if Xmms::playlist_is_empty();

    my $pos  = $remote->get_playlist_pos;
    my $time = $remote->get_output_time;
    my $skip = 1000;

    if ($args =~ /^-(\d*)$/) {
	$remote->jump_to_time($time-($skip * ($1||1)));
	Xmms::rl_termchar('');
	return "-" if $slide;
    }
    elsif ($args =~ /^\+(\d*)$/) {
	$remote->jump_to_time($time+($skip * ($1||1)));
	Xmms::rl_termchar('');
	return '+' if $slide;
    }
    elsif ($is_cpl) {
	my $str = $remote->get_playlist_timestr($pos);
	return ("0:00..$str");
    }
    elsif (!$args) {
    	print Xmms::highlight(Msg => $remote->get_output_timestr."\n");
    }
    elsif ($args =~ /^\d+$/) {
	$remote->jump_to_time($args);
    }
    elsif ($args =~ /^\d+:\d+$/) {
	$jtime{$pos+1} = $args;
	$remote->jump_to_timestr($args);
    }
    elsif ($args =~ /^\d+:\d+..(\d+):(\d+)$/) { #random time jump
	my $len = $remote->get_playlist_time($pos);
	my $rand = int rand $len;
	$remote->jump_to_time($rand);
	Xmms::sleep(0.10);
	my $ostr = $remote->get_output_timestr;
	print Xmms::highlight(Msg => "jumped to $ostr\n");
    }
    else {
	print Xmms::highlight(Error => "unknown time format: $args\n");
    }
}

{
    package Xmms::Info;

    for my $meth (qw(album artist title tracknum genre comment year)) {
	no strict 'refs';
	*$meth = sub {
	    my($self, $tag, $file, $val) = @_;
	    my $key = uc $meth;

	    if ($val) {
		$tag->{$key} = $val;
		if (-w $file) {
		    Xmms::set_mp3tag($file, $tag);
		    print Xmms::highlight(Msg => "$meth set to `$val'\n");
		}
		else {
		    print Xmms::highlight(Error => "$file is not writable\n");
		}
	    }
	    else {
		Xmms::info_print("\u$meth" => $tag->{$key});
	    }
	}
    }
}

my @InfoCmds = sort grep { Xmms::Info->can($_) } keys %Xmms::Info::;
sub Xmms::InfoCmds { \@InfoCmds }

sub Xmms::info_print {
    my($key, $val) = @_;
    $val ||= '?';
    print $key . '.' x (13 - length($key));
    print "$val\n";
}

sub info ($$) {
    my($self, $args) = (shift,shift);
    $args .= " @_" if @_;
    my $len = $remote->get_playlist_length;
    my($track, $subcmd, $subargs) = split /\s+/, $args, 3;
    my $want_subcmd = defined $subcmd;

    if (!$track && $is_cpl) {
	return (1..$len);
    }

    my $pos = $remote->get_playlist_pos+1;
    $track ||= $pos;

    if ($is_cpl) {
	unless ($want_subcmd) {
	    if ($track =~ /^\d+/) {
		return grep /^$track/, (1..$len);
	    }
	    else {
		return Xmms::filecomplete($track);
	    }
	}
	return grep /^$subcmd/, @InfoCmds;
    }

    my $track_is_num = ($track =~ /^\d+$/);
    if ($track_is_num and $track > $len) {
	print Xmms::highlight(Error => "no such track\n");
	return;
    }

    my $file;
    unless ($track_is_num or -e ($file = $track)) {
	($subcmd, $subargs, $track) = ($track, $subcmd, $pos);
	#print Xmms::highlight(Error => "choose track 1..$len ($pos)\n");
	return;
    }

    $file = $remote->get_playlist_file($track-1) unless $file;
    unless (-e $file) {
	print Xmms::highlight(Error => "$file does not exist: $!\n");
	return;
    }
    my $tag  = Xmms::get_mp3tag($file)  || {};
    my $info = Xmms::get_mp3info($file) || {};

    if ($subcmd) {
	if (Xmms::Info->can($subcmd)) {
	    Xmms::Info->$subcmd($tag, $file, $subargs);
	}
	else {
	    print Xmms::highlight(Error => 
				    "unknown info method: $subcmd\n");    
	}
	return;
    }

    stat $file;
    Xmms::info_print(File => $file);
    Xmms::info_print(Size => Xmms::size_string(-s _));
    Xmms::info_print(Modified => scalar localtime((stat _)[9]));

    for (@InfoCmds) {
	Xmms::Info->$_($tag);
    }

    Xmms::info_print(Time => "$info->{MM}:$info->{SS}");
    for (qw(FREQUENCY STEREO BITRATE LAYER VERSION)) {
	Xmms::info_print("\u\L$_" => $info->{$_});
    }
}

1;
__END__

=head1 NAME

Xmms - Interactive remote control shell for xmms

=head1 SYNOPSIS

  perl -MXmms -e shell

=head1 DESCRIPTION

Xmms::shell provides an alternative or companion interface to the
xmms gui.

Feature summary:

=over 4

=item Standard Play Controls

play, pause, stop, next, prev, eject

=item Standard Options

toggle repeat, toggle shuffle

=item Playlist Controls

clear, select, add file(s), add url(s), playlist load/save,
sort (more options than the gui)

=item File Info

search, view and edit mp3 tags

=item Misc Controls

time change (and slider), volume change (and slider), balance change, 
window toggle 

=item Shell Features

=over 4

=item command history

=item command/file completion

=item file matching

=item title matching

=item emacs key bindings

=back

=back

=head1 Shell Command Summary

The complete list of shell commands is also available via the I<help> command. 

=over 4

=item add

Add files to the current playlist, without clearing the current playlist.
See also: I<play> description of the special `-' character.

=item alias

Alias a long command to one of your own definition, e.g.:

 xmms> alias cd play /cdrom
 xmms> cd

=item balance

View or change the balance.

=item clear

Clear the current playlist.

=item current

Display the current playlist track number, title, time, rate,
frequency and mode.

=item delete

Delete tracks from the playlist.  (NOTE: at the time of this writing,
the I<patches/xmms-playlist-delete.pat> patch must be applied to 
xmms-0.9.1.)
Example:

 xmms> delete 3

This command can also handle ranges, e.g. to play just your favorite
tracks from and audio cd:

 xmms> play /cdrom
 xmms> delete 5, 7..10

=item dig

Search for mp3 files by mp3 tag or file name.  Root directory defaults
to the last I<play> command or greedy I<dig> command.

Example:

 #"greedy" match against *.mp3 filename and all tag info
 xmms> dig ~/mp3 gabba|break

 xmms> track
 1 - Prodigy - Break'n'Enter [0:11/5:59 (3%)]
 2 - gabba (6:12)
 3 - gabba (4:47)
 4 - break_and_enter_95_live (5:58)
 5 - Prodigy - Diesel Power (Snake break - Mi (7:08)
 6 - The Prodigy - Acid Break (4:42)

 #match against mp3 `artist' tag only
 xmms> dig artist maxim|liam
 1 - Biohazard feat. Maxim Reality - Breathe [0:03/3:33 (1%)]
 2 - Liam Howlett (DJ mix) - Heavyweight Selection XL Mix (19:37)
 3 - Maxim - Dog Day (4:41)
 4 - Maxim - Factory Girl (2:33)

See also: I<play> description of the special `-' character.

=item eject

Just like pressing the I<eject> button on the gui, pops up the I<load
file> window.  However, if an audio cd is/was playing (and Audio::CD
is installed), the cd tray will pop open.  If an audio cd is I<not> 
playing, but you want to open the tray, provided the I<cd> argument:

 xmms> eject cd

=item export

Make environment variables available to the shell, e.g.:

 xmms> export PWD
 xmms> play $PWD/fav.mp3

 xmms> export MP3_HOME=/usr/local/mp3
 xmms> play $MP3_HOME/fav.mp3

 xmms> export CD="play /cdrom"
 xmms> $CD

=item files

The current playlist with be reduced to files matching the given pattern.
If no files match, the playlist is not changed.
Example:

 xmms> files ro(ck|ll) #reduces playlist to files containing `rock' and `roll'

To negate, use the ! prefix:

 xmms> files !fire    #removes files containing `fire' from the playlist

=item help

Print command summary.

=item history

This function adds a bit of functionality over the readline history.
Mainly, ability to save and run history to and from files on disk.
Example:

 xmms> play ~/mp3/favorites
 xmms> volume 40
 xmms> jtime 1 2:00
 xmms> jtime 2 0:45
 xmms> history >~/mp3/fav.hist #save current history
 xmms> history <~/mp3/fav.hist #read/run history from fav.hist

TAB completion on the special character `-' will recall the last
directory from which a history script was read.  
See also: I<Xmms::SongChange>.

If the file I<~/.xmms/.perlrc> exists, it will be automatically run
as a history script when the shell is invoked, before the prompt
loop.  For example, my I<~/.xmms/.perlrc> file looks like so:

 volume 30
 resume

The I<clear> subcommand can be used to clear the current history:

 xmms> history clear

=item info

This command will display information about the given track, where track is a
number in the current playlist file.  The sub-commands can be used to edit the
mp3 tag of the track file.  Example:

 xmms> info 2
 File........./usr/local/mp3/prodigy/rare/we_eat_rhythm.mp3
 Size......... 4.9M
 Modified.....Thu May 20 16:29:43 1999
 Album........deleted from Jilted Generation
 Artist.......The Prodigy
 Comment......?
 Genre........Electronic
 Title........We Eat Rhythm (Original Version)
 Tracknum.....?
 Year.........1994
 Time.........5:18
 ...

 xmms> info 2 comment Great Tune
 comment set to `Great Tune'

 xmms> info 2 comment
 Comment......Great Tune

=item jtime

This command jumps to the last time set by the I<time> command and
defaults to I<0:00>.  For example:

 xmms> dig file speedway #load files with the name `speedway'
 xmms> time 1:10         #jump 1:10 into the song
 ... time passes ...
 xmms> jtime             #jump back to 1:10

A two argument form of I<jtime> can be used to set jump times for 
tracks without actually jumping to that time, until I<jtime> is called 
in the no argument form.   I like this for playing my favorite parts
of songs, example:

 #set jump times for these three tracks
 xmms> jtime 3 0:30
 xmms> jtime 4 1:00
 xmms> jtime 6 2:11

See also, key bindings: I<M-\>

=item list

This command is used to load a playlist file or to save the current playlist 
file to disk.

Example:

 xmms> list save ~/mp3/fav-tracks #save list
 playlist saved

 xmms> list ~/mp3/fav-tracks      #load list

To measure the size of a list:

 xmms> list size ~/mp3/slipknot.m3u
 slipknot_742617000027.mp3  560k
 slipknot_sic.mp3  3.1M
 ...
 Total: 40.2M

=item mtime

Mark the current output time for I<jtime>.

=item next

Skip forward to next track in the playlist.

=item pause

Pause the current track in the playlist.

=item play

With no arguments, this command is just the same as hitting the gui
play button. 
When given an argument of a directory, file or file glob, the playlist
will be set to these files.  Example:

 xmms> play ~/mp3/prodigy/remixes/

 xmms> play ~/mp3/prodigy/live/*skylined*

TAB completion on the special character `-' will recall the last
directory used with the I<add>, I<play> or I<dig> command, this value
is also saved to your ~/.xmms/config file, so it is always available.
Example:

 xmms> play -<TAB>

completes to:

 xmms> play /home/dougm/mp3/prodigy/remixes/

=item prev

Skip backward to previous track in the playlist.

=item quit

Quit the xmms shell.

=item repeat

Toggle the I<repeat> button.

=item resume

This command will restore the xmms state to where it was just before
the last I<quit> command was run.  That is, it will load the saved
playlist and jump to the list position and output time where xmms was
just before quitting. 
The playlist, position and output time are saved in I<~/.xmms/config>.

=item shuffle

Toggle the I<shuffle> button.

=item sort

Sort the playlist various ways:

=over 4

=item access

Sort by last file access time.

=item album

Sort by I<album> mp3 tag.

=item artist

Sort by I<artist> mp3 tag.

=item comment

Sort by I<artist> mp3 tag.

=item file

Sort by file basename.

=item genre

Sort by I<genre> mp3 tag.

=item large

Sort by file size, from large to small.

=item new

Sort by file modification time, from new to old.

=item old

Sort by file modification time, from old to new.

=item order

Sort the list by order of your choice, e.g.:

 xmms> play /cdrom
 xmms> sort order 3, 10, 6..9, 1 

Tracks not specified in the new order are left out of the new playlist.

=item path

Sort by filename, including the path name.

=item random

Sort in random order.

=item reverse

Reverse the playlist order.

=item small

Sort by file size, from small to large.

=item title

Sort by title name.

=item tracknum

Sort by I<tracknum> mp3 tag.

=item year

Sort by I<year> mp3 tag.

=back

=item time

With no argument, this command will display the elapsed, total and
remaining percentage time of the current track.
When given a I<+N> argument, it will jump the song forward I<N> seconds.
When given a I<-N> argument, it will jump the song backward I<N> seconds.
I<+<TAB>> and I<-<TAB>> can be used a slider for moving forward and
backward.  Finally, a I<mm:ss> argument will jump to that time in the song.
Oh, and I<time <TAB>> will complete to the form I<0:00..mm:ss>, which
will jump to a random time in the song.

=item titles

This function works just the same as the I<files> function, but
matches against playlist titles.

=item track

This function is used for interacting with the current playlist.
With no arguments, it will print the entire list.
When given a range argument, it will print the info for those tracks, for example:

 xmms> track 100..230

Given a number or title name, it will jump to that track in the playlist.

=item url

Add a url to the playlist for streaming.
TAB completion on the special character `-' will recall the last url
used with this command.

If I<Xmms::shell> finds the I<$ENV{HOME}/.xmms/.perlurldb> file when
starting up, the urls in this file will be used for url tab completion.

=item volume

View or change the volume.
With no argument, this command displays the current volume percentage.
With an argument, changes the volume to the given percentage.
I<+<TAB>> and I<-<TAB>> can be used a slider for moving raising and
lowering the volume.  The up/down arrow keys are also bound to this slider.

=item window

This command is used to I<show> or I<hide> the xmms windows.
If the shell is started and xmms is not already running, all windows
will be hidden by default.

=back

=head1 Key Bindings

Here is a list of some of the more useful key bindings.  `C' is
shorthand for the I<control> key, `M' is shorthand for the I<meta>
key, which is normally the I<escape> key.

=over 4

=item C-a : move to beginning of the line

=item C-b : move backward one character

=item C-c : interrupt

=item C-d : delete next character

=item C-e : move to end of the line

=item C-f : more forward one character

=item C-h : delete previous character

=item TAB : complete

=item C-k : kill line

=item C-l : clear screen

=item C-n : next command in history list

=item C-p : previous command in history list

=item C-r : reverse search in history list

=item C-s : forward search in history list

=item C-t : transpose characters

=item C-u : discard line

=item C-y : yank line

=item M-< : beginning of history

=item M-> : end of history

=item M-b : move backward one word

=back

The following key bindings are shortcuts specific to xmms:

=over 4

=item up arrow : volume slide up

=item down arrow : volume slide down

=item M-= : next

=item M-- : prev

=item M-. : stop

=item M-/ : play

=item M-\ : jtime

=item M-m : mtime

=item M-, : pause

=item M-~ : shuffle

=item M-@ : repeat

=item M-` : run previous command in history list

=item M-1 : play track 1 in the playlist

=item M-2 : play track 2 in the playlist (and so on to #9)

=back

The nice part about these key bindings is the single-keystoke-ness and 
that they are not added to the command history, leaving just the more
complex commands in your history buffer.

Effective use of these bounds keys can actually make up a half-assed
sampler too.

The following key bindings will toggle the xmms windows:

=over 4

=item M-a : all windows

=item M-w : main window

=item M-l : playlist window

=item M-q : equalizer window

=back

=head1 Command Aliases

A command abbreviation table is built at startup to provide the following
command aliases:

   a     => add
   b     => balance
   ch    => change
   cl    => clear
   cr    => crop
   cu    => current
   de    => delete
   di    => dig
   e     => eject
   f     => files
   he    => help
   hi    => history
   i     => info
   j     => jtime
   l     => list
   m     => mtime
   n     => next
   pa    => pause
   pl    => play
   pr    => prev
   q     => quit
   rep   => repeat
   res   => resume
   sh    => shuffle
   so    => sort
   st    => stop
   tim   => time
   tit   => titles
   tr    => track
   u     => url
   v     => volume
   w     => window

=head1 SEE ALSO

xmms(1), Xmms::SongChange(3), Xmms::Remote(3), Xmms::Config(3), MPEG::MP3Info(3)

=head1 AUTHOR

Doug MacEachern
