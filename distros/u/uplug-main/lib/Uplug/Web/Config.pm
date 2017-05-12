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

#
# dump perl-hashs to config-files
#

package Uplug::Web::Config;

use strict;
use Data::Dumper;
use Uplug::Web::Process::Lock;

our $DEFAULTMAXFLOCKWAIT=5;

sub DESTROY{
    $_[0]->close();
}

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
	open F,">$file";
	close F;
	system "chmod g+w $file";
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

    my $fh=$self->{FH};
    if (not -e $self->{FILE}){return 0;}

##------------------------------------------------------
## file locking with flock
##
#    open $self->{FH},"+<$self->{FILE}";
#    my $sec=0;
#    while (not flock($self->{FH},2)){
#	$sec++;sleep(1);
#	if ($sec>$self->{MAXFLOCKWAIT}){
#	    close $self->{FH};
#	    return 0;
#	}
#    }
##------------------------------------------------------
##
## file locking with nflock in Uplug::Web::Process::Lock
##

    if (not &nflock($self->{FILE},$self->{MAXFLOCKWAIT})){
	print STDERR "# Uplug::Web::Config - can't get exclusive lock for $self->{FILE}!\n";
	return 0;
    }
    open $self->{FH},"+<$self->{FILE}";

##------------------------------------------------------

    $self->{STATUS}='open';
    return 1;
}

sub close{
    my $self=shift;

    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	truncate($fh,tell($fh));
	close $fh;
	##
	## unlocking the file if nflock was used!
	##
	&nunflock($self->{FILE});
	$self->{STATUS}='closed';
    }
}

sub read{
    my $self=shift;
    my $config;

    if ($self->{STATUS} ne 'open'){
	if (not $self->open()){return undef;}
    }
    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	my @content=<$fh>;
	$config=eval join ('',@content);
    }
    if (ref($config) ne 'HASH'){$config={};}
    return $config;
}

sub write{
    my $self=shift;
    my $content=shift;

    if (ref($content) ne 'HASH'){return 0;}
    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	seek ($fh,0,0);
	print $fh Dumper($content);
	truncate($fh,tell($fh));
	return 1;
    }
    return 0;
}

