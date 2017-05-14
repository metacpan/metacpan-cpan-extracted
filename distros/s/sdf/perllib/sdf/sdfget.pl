# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SDFGET Support Library
#
# >>Copyright::
# Copyright (c) 1992-1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 04-Oct-97 ianc    Fixed bug with * in reports
# 10-Jul-97 marks   Initial writing
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides support for document extraction via
# {{CMD:sdfget}}. 
#
# >>Description::
# 
# This module is a collection of subroutines that are used for the
# processsing of special {{CMD:sdfget}} directives.
#
# >>Note::
# These directives are quite distinct and separate from{{CMD:sdf}}
# directives. 
# 
#
# >>!use Package; scope=PUBLIC
# >>Name::
# Sdfget
# 
# >>Description::
# The {{B:Sdfget}} package describes the interface to the data
# structures used in the extraction, storage and regeneration of
# embedded documentation within source code.
# 
package Sdfget;

# constants for the Sdfget package
%_ScopeList = (
'PUBLIC',    1,
'PROTECTED', 2,
'PRIVATE',   3
);

# >>!use Methods.new
# >>Name::
# new
# 
# >>Synopsis::
# create an instance of the {{B:Sdfget}} class
# 
# >>Description::
# {{Y:new}} creates an instance of the {{B:Sdfget}} class.
# 
# >>Return Values::
# returns a reference to the created {{B:Sdfget}} instance
# 
sub new {
    my $class = shift;
    my $this = {};
    bless $this;
}

# >>!use Methods.addText
# >>Name::
# addText
# 
# >>Parameters::
# {{B:$section}} - the section this text belongs to
# 
# {{B:@buffers}} - the list of buffers to which this key will apply
# 
# >>Description::
# 
sub addText {
    my ($this, $section, $textref, @buflist) = @_;
    my ($bufname, $bufref, $docref);

    for $bufname (@buflist) {
	if (!defined ($$this{$bufname})) {
	    $$this{$bufname} = new Sdfbuffer;
	}
	$bufref = $$this{$bufname};
	$bufref->Sdfbuffer::addText($section, @$textref);
    }
}

sub getScope {
    my ($this, $scope) = @_;
    return $_ScopeList{$scope};
}

sub getKeysDocs {
    my ($this, $bufname) = @_;
    my $bufref;

    $bufref = $$this{$bufname};
    return $$bufref{'key'}, $$bufref{'doc'};
}

sub printDict {
    my $this = shift;
    my $buf;
    my $bufref;

    for $buf (keys %$this) {
	print "Buffer: $buf...";
	$bufref = $$this{$buf};
	$bufref->Sdfbuffer::printBuffer();
    }
}



#
# >>!use main
# 
# >>Description::
# {{Y:UseArgs}} extracts the buffer names and the documentation
# scope from the {{E:!use}} directive line.
# 
# >>Parameter::
# {{B:$directive}} - the directive line to be parsed
# 
# >>Return Values::
# {{B:$doc_scope}} - the scope to which this documentation segment is
# applicable. 
# 
# {{B:@buffers}} - array of buffer names to which the documentation
# can be applied.
# 
sub UseArgs {
    local($directive) = @_; # the directive line being parsed
    local ($bufpart, $scopepart);
    local(@buffers) = ();
    local($buffers) = '';
    local($doc_scope) = 0;

    ($bufpart, $scopepart) = split (/;/, $directive);
    $bufpart =~ /^.*!use (.+)$/;
    $buffers = $1;
    @buffers = split(/,/, $buffers);
    if ($directive =~ /scope=(.+)$/){
	$doc_scope = $_ScopeList{$1};
    }
    else {
	$doc_scope = $_ScopeList{'PUBLIC'};
    }

    return ($doc_scope, @buffers);
}

# >>!use NextSection
# >>Description::
# {{Y:NextSection}} consume lines from the input stream up to
# the next {{E:"!use ..."}} entry.  When found, parse the line
# returning any found scope and buffer names.  Otherwise return a Null
# scope string and an empty buffer name list.
# 
sub NextSection {
    local($this, $istream) = @_;    # the input stream
    local($key);

    while (<$istream>) {
	if (/^!use (.+)/) {
	    return &UseArgs($_);
	}
    }

    # nothing found so return the set of the Null string
    # and an empty array
    return 0, ();
}

# >>!use main
# >>Description::
# {{Y:TrimDesc}} trims the newline characters from each description
# field in the buffers list
# 
sub TrimDesc {
    my ($this) = @_;
    my ($bufref, $buffer);

    for $buffer (keys %$this) {
	$bufref = $$this{$buffer};
	$bufref->Sdfbuffer::TrimDesc ();
    }
}


#### new package #####
package Sdfbuffer;

##### constants #####
$KeyIndex = 0;
$HashIndex = 1;

sub new {
    my $class = shift;
    my $this = {};
    bless $this;
}

sub addText {
    my ($this, $section, @desc) = @_;

    # If this is the first time this key has occurred,
    # append it to the "order found" list.
    if (!defined $this->{'doc'}{$section}) {
        push (@{ $this->{'key'} }, $section);
    }

    $this->{'doc'}{$section} .= join ('', @desc);
}

sub TrimDesc {
    my ($this) = @_;
    my ($docref, $section, $ch);

    $docref = $$this{'doc'};
    for $section (keys %$docref) {
	do {
	    $ch = chop($$docref{$section});
	} while $ch eq "\n";
	$$docref{$section} .= $ch;
    }
}

sub printBuffer {
    my $this = shift;
    my $lkey;
    my $keys = $$this{'key'};
    my $doc;
    
    for $lkey (@$keys){
	print "lkey: $lkey ";
    }
    print "\n";

    print "Documentation...\n";
    $doc = $$this{'doc'};
    for $lkey (keys %$doc) {
	print "lkey: $lkey\n$$doc{$lkey}\n";
    }
}

# package return value
1;
