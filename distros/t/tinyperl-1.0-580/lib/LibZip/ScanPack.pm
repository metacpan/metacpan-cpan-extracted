#############################################################################
## Name:        ScanPack.pm
## Purpose:     LibZip::ScanPack  ## This is a clone of Devel::Symdump!
## Author:      Graciliano M. P.
## Modified by:
## Created:     30/06/2002
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::ScanPack ;

use 5.003;
#use Carp ();
#use strict;
use vars qw($Defaults $VERSION *ENTRY);

$VERSION = '2.03';
# $Id: Symdump.pm,v 1.46 2002/04/18 20:09:38 k Exp $

$Defaults = {
	     'RECURS'   => 0,
	     'AUTOLOAD' => {
			    'packages'	=> 1,
			    'scalars'	=> 1,
			    'arrays'	=> 1,
			    'hashes'	=> 1,
			    'functions'	=> 1,
			    'ios'	=> 1,
			    'unknowns'	=> 1,
			   }
	    };

sub rnew {
    my($class,@packages) = @_;
    no strict "refs";
    my $self = bless {%${"$class\::Defaults"}}, $class;
    $self->{RECURS}++;
    $self->_doit(@packages);
}

sub new {
    my($class,@packages) = @_;
    no strict "refs";
    my $self = bless {%${"$class\::Defaults"}}, $class;
    $self->_doit(@packages);
}

sub _doit {
    my($self,@packages) = @_;
    @packages = ("main") unless @packages;
    $self->{RESULT} = $self->_symdump(@packages);
    return $self;
}

sub _symdump {
    my($self,@packages) = @_ ;
    my($key,$val,$num,$pack,@todo,$tmp);
    my $result = {};
    foreach $pack (@packages){
	no strict;
	while (($key,$val) = each(%{*{"$pack\::"}})) {
	    my $gotone = 0;
	    local(*ENTRY) = $val;
	    #### SCALAR ####
	    if (defined $val && defined *ENTRY{SCALAR}) {
		$result->{$pack}{SCALARS}{$key}++;
		$gotone++;
	    }
	    #### ARRAY ####
	    if (defined $val && defined *ENTRY{ARRAY}) {
		$result->{$pack}{ARRAYS}{$key}++;
		$gotone++;
	    }
	    #### HASH ####
	    if (defined $val && defined *ENTRY{HASH} && $key !~ /::/) {
		$result->{$pack}{HASHES}{$key}++;
		$gotone++;
	    }
	    #### PACKAGE ####
	    if (defined $val && defined *ENTRY{HASH} && $key =~ /::$/ &&
		    $key ne "main::" && $key ne "<none>::")
	    {
		my($p) = $pack ne "main" ? "$pack\::" : "";
		($p .= $key) =~ s/::$//;
		$result->{$pack}{PACKAGES}{$p}++;
		$gotone++;
		push @todo, $p;
	    }
	    #### FUNCTION ####
	    if (defined $val && defined *ENTRY{CODE}) {
		$result->{$pack}{FUNCTIONS}{$key}++;
		$gotone++;
	    }

	    #### IO #### had to change after 5.003_10
	    if ($] > 5.003_10){
		if (defined $val && defined *ENTRY{IO}){ # fileno and telldir...
		    $result->{$pack}{IOS}{$key}++;
		    $gotone++;
		}
	    } else {
		#### FILEHANDLE ####
		if (defined fileno(ENTRY)){
		    $result->{$pack}{IOS}{$key}++;
		    $gotone++;
		} elsif (defined telldir(ENTRY)){
		    #### DIRHANDLE ####
		    $result->{$pack}{IOS}{$key}++;
		    $gotone++;
		}
	    }

	    #### SOMETHING ELSE ####
	    unless ($gotone) {
		$result->{$pack}{UNKNOWNS}{$key}++;
	    }
	}
    }

    return (@todo && $self->{RECURS})
		? { %$result, %{$self->_symdump(@todo)} }
		: $result;
}

sub _partdump {
    my($self,$part)=@_;
    my ($pack, @result);
    my $prepend = "";
    foreach $pack (keys %{$self->{RESULT}}){
	$prepend = "$pack\::" unless $part eq 'PACKAGES';
	push @result, map {"$prepend$_"} keys %{$self->{RESULT}{$pack}{$part} || {}};
    }
    return @result;
}

# this is needed so we don't try to AUTOLOAD the DESTROY method
sub DESTROY {}

sub as_string {
    my $self = shift;
    my($type,@m);
    for $type (sort keys %{$self->{'AUTOLOAD'}}) {
	push @m, $type;
	push @m, "\t" . join "\n\t", map {
	    s/([\000-\037\177])/ '^' . pack('c', ord($1) ^ 64) /eg;
	    $_;
	} sort $self->_partdump(uc $type);
    }
    return join "\n", @m;
}

sub as_HTML {
    my $self = shift;
    my($type,@m);
    push @m, "<TABLE>";
    for $type (sort keys %{$self->{'AUTOLOAD'}}) {
	push @m, "<TR><TD valign=top><B>$type</B></TD>";
	push @m, "<TD>" . join ", ", map {
	    s/([\000-\037\177])/ '^' .
		pack('c', ord($1) ^ 64)
		    /eg; $_;
	} sort $self->_partdump(uc $type);
	push @m, "</TD></TR>";
    }
    push @m, "</TABLE>";
    return join "\n", @m;
}

sub diff {
    my($self,$second) = @_;
    my($type,@m);
    for $type (sort keys %{$self->{'AUTOLOAD'}}) {
	my(%first,%second,%all,$symbol);
	foreach $symbol ($self->_partdump(uc $type)){
	    $first{$symbol}++;
	    $all{$symbol}++;
	}
	foreach $symbol ($second->_partdump(uc $type)){
	    $second{$symbol}++;
	    $all{$symbol}++;
	}
	my(@typediff);
	foreach $symbol (sort keys %all){
	    next if $first{$symbol} && $second{$symbol};
	    push @typediff, "- $symbol" unless $second{$symbol};
	    push @typediff, "+ $symbol" unless $first{$symbol};
	}
	foreach (@typediff) {
	    s/([\000-\037\177])/ '^' . pack('c', ord($1) ^ 64) /eg;
	}
	push @m, $type, @typediff if @typediff;
    }
    return join "\n", @m;
}

sub inh_tree {
    my($self) = @_;
    return $self->{INHTREE} if ref $self && defined $self->{INHTREE};
    my($inherited_by) = {};
    my($m)="";
    my(@isa) = grep /\bISA$/, LibZip::ScanPack->rnew->arrays;
    my $isa;
    foreach $isa (sort @isa) {
	$isa =~ s/::ISA$//;
	my($isaisa);
	no strict 'refs';
	foreach $isaisa (@{"$isa\::ISA"}){
	    $inherited_by->{$isaisa}{$isa}++;
	}
    }
    my $item;
    foreach $item (sort keys %$inherited_by) {
	$m .= "$item\n";
	$m .= _inh_tree($item,$inherited_by);
    }
    $self->{INHTREE} = $m if ref $self;
    $m;
}

sub _inh_tree {
    my($package,$href,$depth) = @_;
    return unless defined $href;
    $depth ||= 0;
    $depth++;
    if ($depth > 100){
	warn "Deep recursion in ISA\n";
	return;
    }
    my($m) = "";
    # print "DEBUG: package[$package]depth[$depth]\n";
    my $i;
    foreach $i (sort keys %{$href->{$package}}) {
	$m .= qq{\t} x $depth;
	$m .= qq{$i\n};
	$m .= _inh_tree($i,$href,$depth);
    }
    $m;
}

sub isa_tree{
    my($self) = @_;
    return $self->{ISATREE} if ref $self && defined $self->{ISATREE};
    my(@isa) = grep /\bISA$/, LibZip::ScanPack->rnew->arrays;
    my($m) = "";
    my($isa);
    foreach $isa (sort @isa) {
	$isa =~ s/::ISA$//;
	$m .= qq{$isa\n};
	$m .= _isa_tree($isa)
    }
    $self->{ISATREE} = $m if ref $self;
    $m;
}

sub _isa_tree{
    my($package,$depth) = @_;
    $depth ||= 0;
    $depth++;
    if ($depth > 100){
	warn "Deep recursion in ISA\n";
	return;
    }
    my($m) = "";
    # print "DEBUG: package[$package]depth[$depth]\n";
    my $isaisa;
    no strict 'refs';
    foreach $isaisa (@{"$package\::ISA"}) {
	$m .= qq{\t} x $depth;
	$m .= qq{$isaisa\n};
	$m .= _isa_tree($isaisa,$depth);
    }
    $m;
}

AUTOLOAD {
    my($self,@packages) = @_;
    unless (ref $self) {
	$self = $self->new(@packages);
    }
    no strict "vars";
    (my $auto = $AUTOLOAD) =~ s/.*:://;

    $auto =~ s/(file|dir)handles/ios/;
    my $compat = $1;

    unless ($self->{'AUTOLOAD'}{$auto}) {
	#Carp::croak("invalid LibZip::ScanPack method: $auto()");
    }

    my @syms = $self->_partdump(uc $auto);
    if (defined $compat) {
	no strict 'refs';
	if ($compat eq "file") {
	    @syms = grep { defined(fileno($_)) } @syms;
	} else {
	    @syms = grep { defined(telldir($_)) } @syms;
	}
    }
    return @syms; # make sure now it gets context right
}

1;


