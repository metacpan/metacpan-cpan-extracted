# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package Uplug::Web::Process::Stack;

use strict;
use Fcntl qw(:DEFAULT :flock);

use Uplug::Web::Process::Lock;


my $DEFAULTMAXFLOCKWAIT=5;


sub new{
    my $class=shift;
    my $self={};
    bless $self,$class;
    $self->setFile($_[0]);
    $self->setFlockWait($_[1]);
    return $self;
}



sub setFile{
    my $self=shift;
    my $file=shift;
    if (not -e $file){
	sysopen (F,$file,O_CREAT);
	close F;
#	system "chmod g+w $file";
	system "chmod o+w $file";
    }
    $self->{FILE}=$file;
}

sub getFile{
    my $self=shift;
    return $self->{FILE};
}

sub setFlockWait{
    my $self=shift;
    my $wait=shift;
    if ($wait){$self->{MAXFLOCKWAIT}=$wait;}
    else{$self->{MAXFLOCKWAIT}=$DEFAULTMAXFLOCKWAIT;}
}


sub open{
    my $self=shift;
    my $lock=shift;                   # open with file locking!

    if (not -e $self->{FILE}){return 0;}
    open $self->{FH},"+<$self->{FILE}";
    my $fh=$self->{FH};

    if ($lock){
	if (not $self->lock()){       # lock the file
	    close $fh;
	    return 0;
	}
    }
    $self->{STATUS}='open';
    return 1;
}

sub lock{
    my $self=shift;
    if (nflock($self->{FILE},$self->{MAXLOCKWAIT})){
	$self->{LOCKED}=1;
	return 1;
    }
    return 0;
}

sub unlock{
    my $self=shift;
    nunflock($self->{FILE});          # release lock!
    delete $self->{LOCKED};
    return 1;
}


sub openFlock{
    my $self=shift;

    my $fh=$self->{FH};
    if (not -e $self->{FILE}){return 0;}
    open $self->{FH},"+<$self->{FILE}";
    my $sec=0;
    while (not flock($self->{FH},2)){
	$sec++;sleep(1);
	if ($sec>$self->{MAXFLOCKWAIT}){
	    close $self->{FH};
	    return 0;
	}
    }
    $self->{STATUS}='open';
    return 1;
}

sub close{
    my $self=shift;

    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	truncate($fh,tell($fh));
	close $fh;
	$self->{STATUS}='closed';
    }
    if ($self->{LOCKED}){
	nunflock($self->{FILE});          # release lock!
	delete $self->{LOCKED};
    }
}

sub read{
    my $self=shift;

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){         # if the stack is not opend yet:
	if (not $self->open()){return 0;}   #   open it!
	$NeedToClose=1;                     #   but close it afterwards again!
    }
    my $fh=$self->{FH};                     # get the file handle
    seek ($fh,0,0);                         # go to the beginning of the file
    my @content=<$fh>;                      # and read from it
    if ($NeedToClose){$self->close();}      # close the stack if we opened it

    return wantarray ? @content : join "@content";
}


sub write{
    my $self=shift;
    my $content=shift;

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){
	if (not $self->open('lock')){return 0;}  # open in lock-mode
	$NeedToClose=1;
    }
    if (not $self->{LOCKED}){
	if (not $self->lock()){return 0;}
    }
    my $fh=$self->{FH};
    seek ($fh,0,0);
    if (ref($content) eq 'ARRAY'){print $fh @{$content};}
    else{print $fh $content;}
    if ($NeedToClose){$self->close();}
    return 1;
}


sub push{
    my $self=shift;
    my $text=join(':',@_);

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){
	if (not $self->open('lock')){return 0;}  # open in lock-mode
	$NeedToClose=1;
    }
    if (not $self->{LOCKED}){
	if (not $self->lock()){return 0;}
    }
    my @content=$self->read();
    push (@content,$text."\n");
    $self->write(\@content);
    if ($NeedToClose){$self->close();}
    return 1;
}


sub pop{
    my $self=shift;

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){
	if (not $self->open('lock')){return undef;}  # open in lock-mode
	$NeedToClose=1;
    }
    if (not $self->{LOCKED}){
	if (not $self->lock()){return undef;}
    }
    my @content=$self->read();
    my $text=pop (@content);
    $self->write(\@content);
    if ($NeedToClose){$self->close();}
    chomp($text);
    return wantarray ? split(/\:/,$text) : $text;
}



sub unshift{
    my $self=shift;
    my $text=join(':',@_);

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){
	if (not $self->open('lock')){return 0;}  # open in lock-mode
	$NeedToClose=1;
    }
    if (not $self->{LOCKED}){
	if (not $self->lock()){return 0;}
    }
    my @content=$self->read();
    unshift (@content,$text."\n");
    $self->write(\@content);
    if ($NeedToClose){$self->close();}
    return 1;
}


sub shift{
    my $self=shift;

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){
	if (not $self->open('lock')){return undef;}  # open in lock-mode
	$NeedToClose=1;
    }
    if (not $self->{LOCKED}){
	if (not $self->lock()){return undef;}
    }
    my @content=$self->read();
    my $text=shift (@content);
    $self->write(\@content);
    if ($NeedToClose){$self->close();}
    chomp($text);
    return wantarray ? split(/\:/,$text) : $text;
}

sub remove{
    my $self=shift;
    my @data=@_;
    map($_=quotemeta($_),@data);
    my $pattern='^'.join(':',@data).'(\:|\Z)';

    my $NeedToClose=0;
    if ($self->{STATUS} ne 'open'){
	if (not $self->open('lock')){return 0;}  # open in lock-mode
	$NeedToClose=1;
    }
    if (not $self->{LOCKED}){
	if (not $self->lock()){return 0;}
    }
    my @content=$self->read();
    @content=grep($_!~/$pattern/,@content);
    $self->write(\@content);
    if ($NeedToClose){$self->close();}
    return 1;
}


sub find{
    my $self=shift;
    my @data=@_;
    map($_=quotemeta($_),@data);

    my $pattern='^'.join(':',@data).'(\:|\Z)';
    my @content=$self->read();
    my @match=grep($_=~/$pattern/,@content);
    chomp($match[0]);
    return wantarray ? split(/\:/,$match[0]) : $match[0];
}


