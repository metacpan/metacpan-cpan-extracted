#                              -*- Mode: Perl -*-
# $Basename: Server.pm $
# $Revision: 1.5 $
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sat Sep 28 13:53:36 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:38 1998
# Language        : CPerl
# Update Count    : 280
# Status          : Unknown, Use with caution!
#
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Server;
use vars qw($VERSION @ISA @EXPORT);
use WAIT::Config;
use IO::Socket;
use IO::Select;
use strict;
use sigtrap qw(handler IGNORE error-signals);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(server);

my($ver) = '$ProjectVersion: 18.1 $ ' =~ /([\d.]+)/; $VERSION = sprintf '%5.3f', $ver/10;

sub server {
  my %opt  = @_;
  my $port = $opt{port} || $WAIT::Config->{port} || 1404;

  my $lsn  = new WAIT::Handle(Reuse     => 1,
                              Listen    => 5,
                              LocalPort => $port,
                              Proto     => 'tcp');
  die "Could not connect to port $port: $!\n" unless defined $lsn;

  my $SEL  = new IO::Select( $lsn );
  my %CON;
  my $fh;
  my @ready;

  print "listening on port $port\n";
  
  while(1) {
    alarm(0);
    @ready = $SEL->can_read;
    #printf STDERR "=== %s %s\n", unpack ('b*', $SEL->[0]), join ':', @ready;
    #sleep 1;
  REQUEST:
    alarm(25);
    foreach $fh (@ready) {
      if($fh == $lsn) {
        my $new = $lsn->accept; # Create a new socket
        $CON{$new} = new WAIT::Server::Connection $new, $VERSION;
        $SEL->add($new);
      } else {
        my ($cmd, $func, @args, @cmd);
        my $fno = fileno($fh); 

        $cmd = $fh->getline();
        if ($cmd =~ /^post/i) {
/`/;
          my $buf =
            $cmd .
              join('', @{${*$fh}{'net_cmd_lines'}}) .
                ${*$fh}{'net_cmd_partial'};
          ($cmd) = ($buf =~ /^Command: (.*)$/m);
          ($cmd, @cmd) = (split (/:/, $cmd), 'quit');
          ${*$fh}{'net_cmd_partial'} = '';
/`/;
          $CON{$fh}->{http} = 1;
}
      COMMAND:
        for $cmd ($cmd, @cmd) {
          ($func, @args) = split ' ', $cmd;
          unless (fileno($fh)) {
            printf STDERR "Shuttig down $fh(%d)\n", $fno;
            delete $CON{$fh};
            $SEL->remove($fno);
            next REQUEST;
          }
          $func = lc($func);
          $func = $CON{$fh}->dispatch($func, @args);
          if ($func eq 'quit') {
            printf STDERR  "closed\n";
            $SEL->remove($fh);
            $CON{$fh}->close;
            delete $CON{$fh};
            last COMMAND;
          }
        }
      }
    }
  }
}

package WAIT::Handle;
use Net::Cmd;
use IO::Socket;
use vars qw(@ISA);
use strict;

@ISA = qw(Net::Cmd IO::Socket::INET);

# Snarfed from Net::Cmd; we don't expect an answer.
sub dataend
{
 my $cmd = shift;

 return 1
    unless(exists ${*$cmd}{'net_cmd_lastch'});

 if(${*$cmd}{'net_cmd_lastch'} eq "\015")
  {
   syswrite($cmd,"\012",1);
   print STDERR "\n"
    if($cmd->debug);
  }
 elsif(${*$cmd}{'net_cmd_lastch'} ne "\012")
  {
   syswrite($cmd,"\015\012",2);
   print STDERR "\n"
    if($cmd->debug);
  }

 print STDERR "$cmd>>> .\n"
    if($cmd->debug);

 syswrite($cmd,".\015\012",3);

 delete ${*$cmd}{'net_cmd_lastch'};

}

package WAIT::Server::Connection;
use strict;
use Sys::Hostname;
use Socket qw(AF_INET unpack_sockaddr_in);
use vars qw(%CMD %MSG %HELP);

my $HOST = hostname;
{
  no strict;
  local *stab = *WAIT::Server::Connection::;
  my ($key,$val);
  while (($key,$val) = each(%stab)) {
    next unless $key =~ /^cmd_(.*)/;
    local(*ENTRY) = $val;
    if (defined &ENTRY) {
      $CMD{$1} = \&ENTRY;
    }
  }
}


sub new {
  my $type = shift;
  my $fh   = shift;
  my $msg  = shift;
  my $self = {_fh => $fh};
  
  my $hersockaddr    = $fh->peername();
  my ($port, $iaddr) = unpack_sockaddr_in($hersockaddr);
  my $peer           = gethostbyaddr($iaddr, AF_INET);
  $self->{peer}      = $peer;
  $self->{database}  = 'DB';
  $self->{table}     = 'cpan';
  $self->{hits}      = 10;
  print "Connection from $peer\n";
  bless $self, $type;
  $self->msg(200, $msg);
  $self;
}

sub close {
  my $self = shift;

  $self->{_fh}->close;
}


sub dispatch {
  my $self = shift;
  my $cmd  = shift;

  print "$cmd @_\n";
  unless (exists $CMD{$cmd}) {
    $self->msg(500);
  } else {
    &{$CMD{$cmd}}($self, @_);
  }
  $cmd;
}

sub msg {
  my $self = shift;
  my $code = shift;
  my $msg  = $MSG{$code} || '';
  printf("%s %s %03d $msg\r\n", scalar(localtime(time)), $self->{peer}, $code, @_);
  $self->{_fh}->datasend(sprintf("%03d $msg\r\n", $code, @_));
}

sub end {
  my $self = shift;
  $self->{_fh}->dataend;
}


require WAIT::Query::Wais;
require WAIT::Database;
use Fcntl;

my %DB;                         # cache Databas handles
sub DATABASE {
  my $dn = shift;

  return $DB{$dn} if exists $DB{$dn};
  $DB{$dn} = WAIT::Database->open(name      => $dn,
                                  directory => $WAIT::Config->{'WAIT_home'},
                                  mode      => O_RDONLY);
  return $DB{$dn};
}

my %TB;                         # cache Table handles
sub TABLE {
  my ($dbname, $tname) = @_;

  return $TB{$dbname.$tname} if exists $TB{$dbname.$tname};
  my $db = DATABASE($dbname);

  $TB{$dbname.$tname} = $db->table(name => $tname);
  $TB{$dbname.$tname};
}


# helpers
sub result {
  my $self   = shift;
  my $hit    = shift;
  my $did;

  # http uses raw document id's
  if ($self->{http}) {
    return $hit;
  }
  unless ($self->{result}) {
    $self->msg(404);
    return;
  }
  unless ($did = $self->{result}->[$hit-1]) {
    $self->msg(405);
    return;
  }
  return $did;
}

sub table {
  my $self   = shift;
  
  TABLE($self->{database}, $self->{table});
}

sub output {
  my $self = shift;

  $self->{_fh}->datasend(@_);
}


# The commands

sub cmd_help {
  my $self = shift;

  $self->msg(100);
  for (sort keys %CMD) {
    $self->output(sprintf("%-15s %s\r\n", $_, $HELP{$_}||''));
  }
  $self->end;
}

sub cmd_quit {
  my $self = shift;
  $self->msg(205);
}

sub cmd_database {
  my $self   = shift;
  my $dbname = shift || $self->{database};


  if (DATABASE($dbname)) {
    delete $self->{'result'};
    $self->{database} = $dbname;
    $self->msg(201, $dbname);
  } else {
    $self->msg(401, $dbname);
  }
}

sub cmd_table {
  my $self   = shift;
  my $table  = shift || $self->{'table'};
  my $dbname = $self->{'database'};

  if (TABLE($dbname, $table)) {
    delete $self->{'result'};
    $self->{'table'} = $table;
    $self->msg(202, $table);
  } else {
    $self->msg(402, $table);
  }
}

sub cmd_hits {
  my $self   = shift;
  my $hits   = shift;

  if ($hits) {
    $self->{hits} = $hits;
    $self->msg(204, $hits);
  } else {
    $self->msg(501);
  }
}

sub cmd_info {
  my $self   = shift;
  my $hit    = shift;

  my $did    = $self->result($hit);
  return unless $did;
  
  my $tb     = $self->table;

  my %rec    = $tb->fetch($did);
  $self->msg(207, $did);
  for (keys %rec) {
    $self->{_fh}->datasend(sprintf("%-15s %s\n", $_, $rec{$_}));
  }
  $self->end;
}

sub cmd_get {
  my $self   = shift;
  my $hit    = shift;
  my $did    = $self->result($hit);

  return unless $did;
  my $tb     = $self->table;
  my %rec    = $tb->fetch($did);
  my $key    = $rec{docid};

  $key = $tb->dir . '/' . $key if $key =~ m(^data/);

  my $text   = $tb->fetch_extern($key);
  
  $self->msg(206, $did);
  $self->output($text);
  $self->output("\n") unless $text =~ /\n$/;
  $self->end;
}

sub cmd_search {
  my $self   = shift;
  my $query  = join ' ', @_;
  my $tb     = $self->table;

  my $wq = eval {WAIT::Query::Wais::query($tb, $query)};
  unless ($wq) {
    $self->msg(403);
    return;
  }
  my %hits = $wq->execute();
  my @did = sort {$hits{$b} <=> $hits{$a}}keys %hits;

  # sanity check. this is expensive and should be obsolete!
  # @did =  grep $tb->fetch($_), @did;

  $self->{'result'} = \@did;
  my $all_hits  = scalar @did;
  my $send_hits = $all_hits;

  if ($send_hits > $self->{hits}) {
    $send_hits = $self->{hits};
  }
  $self->msg(203, $all_hits, $send_hits);
  my $i;
  
  for ($i=1;$i<=$send_hits;$i++) {
    my $did = $did[$i-1];
    my %rec = $tb->fetch($did);
    $self->{_fh}->datasend(sprintf("%2d %5.3f %s\n",
                                   $self->{http}?$did:$i,
                                   $hits{$did},
                                   $rec{headline}));
  }
  $self->end();
}

# read status messages
my $line;
while (defined ($line = <DATA>)) {
  chomp($line);
  my ($cmd, $msg) = split ' ', $line, 2;
  last unless $cmd;
  $HELP{$cmd} = $msg;
}
while (defined ($line = <DATA>)) {
  chomp($line);
  next unless $line =~ /^\d/;
  my ($code, $msg) = split ' ', $line, 2;
  $MSG{$code} = $msg;
}


1;

__DATA__
help     -                    display this help message
database name                 set database name
table    name                 set table name
search   query                submitt query
get      number               fetch full text of hit with number
info     number               display info record of hit with number
format   text|html|term
hits     number               set maximum hits displayed to number
quit

100 help message follows
200 WAIT server %s ready
205 closing connection - goodbye!
201 database %s selected
401 could not open database %s
202 table %s selected
203 query returnes %d hits, %d hits follow
204 will return %d hits
207 record %d follows
206 text of record %d follows
402 could not open table %s
403 syntax error in query
404 use search first
405 no such hit
500 command not recognized
501 command syntax error
502 access restriction or permission denied
503 program fault - command not performed
1;
