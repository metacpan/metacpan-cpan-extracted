=pod

=head1 NAME

Flail::Exec - Flail Command Interpreter

=head1 VERSION

  Time-stamp: <2006-12-04 18:02:31 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec;

=head1 DESCRIPTION

Command processor for flail commands.

=cut

package Flail::Exec;
use strict;
use Carp;
use Flail::Thing;
use base qw(Flail::Thing);
use Flail::Exec::Cmd::check qw(:cmd);
use Flail::Exec::Cmd::get qw(:cmd);
use Flail::Exec::Cmd::open qw(:cmd);
use Flail::Exec::Cmd::stat qw(:cmd);
use Flail::Exec::Cmd::next qw(:cmd);
use Flail::Exec::Cmd::prev qw(:cmd);
use Flail::Exec::Cmd::read qw(:cmd);
use Flail::Exec::Cmd::decrypt qw(:cmd);
use Flail::Exec::Cmd::send qw(:cmd);
use Flail::Exec::Cmd::forward qw(:cmd);
use Flail::Exec::Cmd::resend qw(:cmd);
use Flail::Exec::Cmd::reply qw(:cmd);
use Flail::Exec::Cmd::mkdir qw(:cmd);
use Flail::Exec::Cmd::decode qw(:cmd);
use Flail::Exec::Cmd::range qw(:cmd);
use Flail::Exec::Cmd::list qw(:cmd);
use Flail::Exec::Cmd::move qw(:cmd);
use Flail::Exec::Cmd::copy qw(:cmd);
use Flail::Exec::Cmd::remove qw(:cmd);
use Flail::Exec::Cmd::help qw(:cmd);
use Flail::Exec::Cmd::quit qw(:cmd);
use Flail::Exec::Cmd::sync qw(:cmd);
use Flail::Exec::Cmd::goto qw(:cmd);
use Flail::Exec::Cmd::reset qw(:cmd);
use Flail::Exec::Cmd::map qw(:cmd);
use Flail::Exec::Cmd::mark qw(:cmd);
use Flail::Exec::Cmd::unmark qw(:cmd);
use Flail::Exec::Cmd::count qw(:cmd);
use Flail::Exec::Cmd::alias qw(:cmd);
use Flail::Exec::Cmd::unalias qw(:cmd);
use Flail::Exec::Cmd::headers qw(:cmd);
use Flail::Exec::Cmd::addressbook qw(:cmd);
use Flail::Exec::Cmd::run_hooks qw(:cmd);
use Flail::Exec::Cmd::echo qw(:cmd);
use Flail::Exec::Cmd::invert qw(:cmd);
use Flail::Exec::Cmd::split qw(:cmd);
use vars qw(@EXPORT_OK @EXPORT %EXPORT_TAGS %COMMANDS $ME $CLI);
@EXPORT = ();
@EXPORT_OK = qw(
    flail_check
    flail_get
    flail_open
    flail_stat
    flail_next
    flail_prev
    flail_read
    flail_decrypt
    flail_send
    flail_forward
    flail_resend
    flail_reply
    flail_mkdir
    flail_decode
    flail_range
    flail_list
    flail_move
    flail_copy
    flail_remove
    flail_help
    flail_quit
    flail_sync
    flail_goto
    flail_reset
    flail_map
    flail_mark
    flail_unmark
    flail_count
    flail_alias
    flail_unalias
    flail_headers
    flail_addressbook
    flail_run_hooks
    flail_echo
    flail_invert
    flail_split

    flail_defcmd
    flail_defcmd1
    flail_eval
);
%EXPORT_TAGS = ( 'all' => \@EXPORT );

sub flail_eval;
sub flail_defcmd;
sub flail_defcmd1;

%Flail::Exec::COMMANDS = (
    'check'   => [ \&flail_check, "check [imap|pop3|spool] file|mailbox [server]" ],
    'get'     => [ \&flail_get, "get [imap|pop3] mailbox [server [folder]]" ],
    'cd'      => [ \&flail_open, "cd foldername" ],
    'pwd'     => [ \&flail_stat, "show current folder" ],
    'next'    => [ \&flail_next, "go to next message" ],
    'prev'    => [ \&flail_prev, "go to previous message" ],
    'cat'     => [ \&flail_read, "show a message's content" ],
    'decrypt' => [ \&flail_decrypt, "decrypt and show a message" ],
    'send'    => [ \&flail_send, "send a message" ],
    'forward' => [ \&flail_forward, "forward a message" ],
    'resend'  => [ \&flail_resend, "resend a message" ],
    'reply'   => [ \&flail_reply, "reply to a message" ],
    'mkdir'   => [ \&flail_mkdir, "create new folder" ],
    'decode'  => [ \&flail_decode, "decode a MIME message" ],
    'range'   => [ \&flail_range, "expand a range expression" ],
    'ls'      => [ \&flail_list, "list messages and subfolders" ],
    'mv'      => [ \&flail_move, "move a message or folder" ],
    'cp'      => [ \&flail_copy, "copy a message or folder" ],
    'rm'      => [ \&flail_remove, "remove a message or folder" ],
    'help'    => [ \&flail_help, "help [pod|license|warranty|version|brief|cmd|regexp ...]" ],
    'quit'    => [ \&flail_quit, "quit $::P" ],
    'sync'    => [ \&flail_sync, "sync current folder state" ],
    'goto'    => [ \&flail_goto, "go to a specific message" ],
    'reset'   => [ \&flail_reset, "reset all|pass|conns - reset various bits of state" ],
    'map'     => [ \&flail_map, "map label cmd ..." ],
    'mark'    => [ \&flail_mark, "mark msg ..." ],
    'unmark'  => [ \&flail_unmark, "unmark msg ..." ],
    'count'   => [ \&flail_count, "count [-list] [label ...]" ],
    'alias'   => [ \&flail_alias, "alias name cmds..." ],
    'unalias' => [ \&flail_unalias, "unalias name [name...]" ],
    'headers' => [ \&flail_headers, "headers [msgno ...]" ],
    'address' => [ \&flail_addressbook, "address {add|show|list|del|import|help} [...]" ],
    'run'     => [ \&flail_run_hooks, "run [label] - run hooks for label, default=marked" ],
    'echo'    => [ \&flail_echo, "echo whatever - print out a message" ],
    'invert'  => [ \&flail_invert, "invert [label] - invert selected messages" ],
    'split'   => [ \&flail_split, "split prefix count - split all msgs into folders" ],
);

sub _struct {
    shift->SUPER::_struct, (
        'cfg' => undef,
        'cmds' => undef,
        'folder' => ':none',
        'msg' => ':none',
    );
}

sub _init_new {
    my $self = shift->SUPER::_init_new(@_, 'cmds' => {
        map { $_ => $Flail::Exec::COMMANDS{$_} }
        keys %Flail::Exec::COMMANDS,
    });
    $ME ||= $self;
    return $self;
}

sub say {
    if ($CLI) {
        $CLI->say(@_);
    } else {
        $::Debug && warn("[COMPAT] @_\n");
    }
}

sub flail_defcmd {
    my($name,$func,$help) = @_;
    die "$::P: no command name given to flail_defcmd\n" unless defined($name);
    die "$::P: command $name not given a function\n" unless defined($func);
    die "$::P: command $name not given any help\n" unless defined($help);
    die "$::P: command $name already defined\n"
        if (defined($Flail::Exec::COMMANDS{$name} && !$::AllowCommandOverrides));
    $Flail::Exec::COMMANDS{$name} = [ $func, $help ];
    return $name;
}

sub flail_defcmd1 {
    my($name) = @_;
    return if defined($Flail::Exec::COMMANDS{$name});
    return flail_defcmd(@_);
}

sub parse_cmd_opts {
    my $optstr = shift(@_);
    $optstr = substr($optstr, 1) if ($optstr =~ /^\//);
    my @opts = split(/\//, $optstr);
    my %opthash = ();
    foreach my $o (@opts) {
        say "parsing opt: $o";
        my($k,$v) = split(':', $o, 2);
        $v = $1 if ($v =~ /^\"(.*)\"$/);
        $v = 1 unless defined($v);
        $opthash{lc($k)} = $v;
        say "opthash: " . lc($k) . " => " . $v;
    }
    return \%opthash;
}

# get_command_word - parse out the command word plus options
#
sub get_command_word {
    my $str = shift(@_);
    my $i = 0;
    my $done = 0;
    my $instr = 0;
    my $quote = 0;
    my $cmd;
    my $rest;
    while (($i < length($str)) && !$done) {
        my $c = substr($str,$i,1);
        if ($quote) {
            $quote = 0;
            next;
        }
        $quote = 1 if ($c eq "\\");
        $instr = !$instr if (($c eq "\"") || ($c eq "\'"));
        if (!$instr && ($c =~ /\s/)) {
            $cmd = substr($str, 0, $i);
            $rest = substr($str, $i + 1);
            $rest = psychochomp($rest);
            last;
        }
        ++$i;
    }
    if (!defined($cmd)) {
        $cmd = $str;
        $rest = "";
    }
    return ($cmd, $rest);
}

sub expand_words {
    my @words;
    foreach my $word (@_) {
        if ($word =~ /^,(.*)$/) {
            my $exp = '';
            $exp = eval "$1";
            $::Verbose && warn("expand_words($word): $exp ($@)\n");
            warn("error: $word: $@\n") if $@;
            $word = $exp;
        }
        push(@words, $word);
    }
    return @words;
}

sub Default { shift->new(@_); }

sub DefaultContext_ {
    $ME ||= Flail::Exec->Default;
    $CLI ||= Flail::CLI->Default;
    return($ME,$CLI);
}

sub flail_eval {
    my($line,$cli,$self);
    if (ref($_[0]) && ($#_ == 2)) {
        ($self,$cli,$line) = @_;
        $ME ||= $self;
        $CLI ||= $cli;
    } else {
        ($self,$cli) = DefaultContext_();
        ($line) = @_;
    }
    my $cmd;
    my @words;
    $cli->say("flail_eval($line)");
    if ($line =~ /^\S+\//) {
        my($c,$r) = $self->get_command_word($line);
        $cmd = $c;
        $line = $r;
        $cli->say("command word: $cmd");
        $cli->say("rest of line: $line");
        @words = split(/ /, $line);
    } else {
        @words = split(" ", $line);
        $cmd = shift(@words);
    }
    @words = $self->expand_words(@words);
    my $opthash = {};
    if ($cmd =~ /^([^\/]+)(\/.*)$/) {
        $cmd = $1;
        my $optstr = $2;
        $opthash = $self->parse_cmd_opts($optstr);
    } elsif ($words[0] =~ /^\//) {
        my $optstr = shift(@words);
        $opthash = $self->parse_cmd_opts($optstr, $opthash);
    }
    $cli->say("flail_eval cmd=$cmd words=(@words)");
    my $cinfo;
    my $proc;
    $cmd = lc($cmd);
    return -1 if $cmd =~ /^quit$/;
    if ($cmd =~ /^!(.+)$/) {
        my $x = $1;
        unshift(@words, $x);
        $x = join(" ", @words);
        $self->do_shell_esc($x);
        return 0;
    } elsif ($cmd =~ /^\|(.+)$/) {
        my $x = $1;
        unshift(@words, $x);
        $x = join(" ", @words);
        $self->do_shell_pipe($x);
        return 0;
    } elsif ($cmd =~ /^,(.+)$/) {
        my $x = substr($line, 1);
        $cli->emit("[eval: $x]") unless $::Quiet;
        eval $x;
        $cli->emit("whoops: $@") if ($@);
        return 0;
    }
    $cli->say("... after processing, words=(@words)");
    $cinfo = $self->cmds->{$cmd};
    $proc = undef;
    $proc = $cinfo->[0] if defined($cinfo);
    if (defined($proc)) {
        eval {
            package main;
            local $::SIG{INT} = sub { die "flail_eval interrupted..."; };
            local $::SIG{TERM} = sub { die "flail_eval interrupted..."; };
            local $::SIG{QUIT} = sub { die "flail_eval interrupted..."; };
            local $::CMD = $cmd;
            local $::OPT = $opthash;
            local $::Verbose = 1 if $opthash->{verbose};
            local $::Quiet = 1 if ($opthash->{quiet} || $opthash->{q});
            &$proc(@words);
        };
        if ($@) {
            my $msg = "$@";
            chomp($msg);
            $msg =~ s/^(.*)\s+at\s\S+\sline\s\d+/$1/;
            $| = 1;
            $self->cli("\n$msg\n");
        }
    }
    $cli->emit("$cmd: undefined command - \"help\" for help") unless defined($proc);
    return 0;
}

sub interpret {
    my($self,$cli,$line) = @_;
    local $CLI = $cli;
    local $ME = $self;
    return flail_eval($line);
}

sub cleanup {
}

1;

__END__

=pod

=head1 AUTHOR

  attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

  (C) 2002-2006 by attila <attila@stalphonsos.com>.  all rights reserved.

  This code is released under a BSD license.  See the LICENSE file
  that came with the package.

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# time-stamp-line-limit: 40
# End:
##
