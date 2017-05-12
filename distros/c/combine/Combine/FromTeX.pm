# Copyright (c) 2000 Anders Ardoe
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# 			    NO WARRANTY
# 
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
# 
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 
# Copyright (c) 2000 Anders Ardoe

#A first shot at a LaTeX parser for Combine records
#Anders Ardoe 2000-06-11

package Combine::FromTeX;

use strict;

sub trans {
    my ($content, $xwi, $opt) = @_;
    return undef unless ref $xwi;
    $xwi->url_rewind;  # (BR)
    my $url = $xwi->url_get || return undef; # $xwi object must have url field
    my $rawtex = ${$xwi->content};

# Metadata mappings from LaTeX constructs to DC metadata
#Simple TeX constructs \<name>{...}
my %simple = (
    'title' => 'dc.title',
    'author' => 'dc.creator',
    'date' => 'dc.date',
    'keywords' => 'dc.subject'
);

#Compund TeX constructs \begin{<name>}...\end{<name>}
my %compound = (
    'abstract' => 'dc.description',
);

my %entities = (
  'aa' => 'å',
  'AA' => 'Å',
  '\"\{a\}' => 'ä',
  '\"a' => 'ä',
  '\"\{A\}' => 'Ä',
  '\"A' => 'Ä',
  '\ae' => 'æ',
  '\AE' => 'Æ',
  '\"\{o\}' => 'ö',
  '\"o' => 'ö',
  '\"\{O\}' => 'Ö',
  '\"O' => 'Ö',
  'o' => 'ø',
  'O' => 'Ø',
                );

my %dichars = (
  'a' => 'ä',
  'A' => 'Ä',
  'o' => 'ö',
  'O' => 'Ö',
                );

######debug
#    open(TMP,">t1.$$");
#    print TMP $rawtex;
#    close(TMP);
#############
# Remove TeX comments
    $rawtex =~ s/%.*?[\n\r]/ /g;
# Remove newlines
    $rawtex =~ s/[\n\r]/ /g;
# Compress spaces
    $rawtex =~ s/\s+/ /g;
#############debug
#    open(TMP,">t2.$$");
#    print TMP $rawtex;
#    close(TMP);
########

my $space;
my $ent;
my $char;
my $acc;

#TeX spaces
foreach $space ('~', '\\\\\\\\', '\\\\,') {
  $rawtex =~ s/$space/ /g;
}

#############debug
#    open(TMP,">t3.$$");
#    print TMP $rawtex;
#    close(TMP);
########

#Translate accented characters to iso
foreach $ent (keys(%entities)) {
  $rawtex =~ s/\{\\$ent\}/$entities{$ent}/g;
  $rawtex =~ s/\\$ent(\b)/$entities{$ent}$1/g;
}

#############debug
#    open(TMP,">t4.$$");
#    print TMP $rawtex;
#    close(TMP);
########

#'Standalone' dieresis
foreach $char (keys(%dichars)) {
    $rawtex =~ s/\\\"$char/$dichars{$char}/g;
}

#############debug
#    open(TMP,">t5.$$");
#    print TMP $rawtex;
#    close(TMP);
########

#remove accents
foreach $acc ("'", '´', '`', '^', '~') {
    $rawtex =~ s/\\$acc\{\\?(.)\}/$1/g;
}

#############debug
#    open(TMP,">t6.$$");
#    print TMP $rawtex;
#    close(TMP);
########

    my $name;
    my $abs;

foreach $name (keys(%simple)) {
    while ( $rawtex =~ /\\$name\{([^\}]+)\}/ig ) { #grooks on nested TeX constructs
	$xwi->meta_add($simple{$name},$1);
	if ( $name eq 'title' ) { $xwi->title($1); }
    }
}

foreach $name (keys(%compound)) {
    while ( $rawtex =~ /\\begin\{$name\}(.*?)\\end\{$name\}/ig ) {
	$abs=$1; $abs =~ s/^\s+//; $abs =~ s/\s+$//;
	$xwi->meta_add($compound{$name},$abs);
	if ( $compound{$name} eq 'dc.description' ) {$xwi->meta_add("Rsummary",$abs);}
    }
}

# Map following simple constructs to headings in WIR
    foreach $name ('part', 'chapter', '[^\{]*section') {
	while ( $rawtex =~ /\\$name\{([^\}]+)\}/ig ) {
	    $xwi->heading_add($1);
	}
    }

#Save raw TeX text
#    $xwi->text(\$rawtex);

#Remove TeX markup and save text (done by filtering through detex)
#    open(TEX,">/tmp/$$.tex");
#    print TEX $rawtex;
#    close(TEX);
#    open(TEXT,"bin/detex -n /tmp/$$.tex |");
#    my $text;
#    while (<TEXT>) { $text .= $_; }
#    close(TEXT);
#    unlink("/tmp/$$.tex");
#    $text =~ s/\s+/ /g;
#    $xwi->text(\$text);

    if ( $opt =~ /HTML/i ) {
      return &Combine::FromHTML::trans($content, $xwi, 'HTML');
  } elsif ( $opt =~ /Text/i ) {
      return &Combine::FromHTML::trans($content, $xwi, 'Text');
  } else { return $xwi; }
}

1; 

__END__

=head1 NAME

Combine::FromTeX.pm - TeX parser in combine package

=head1 AUTHOR

 Anders Ardø 2000-06-11

=cut
