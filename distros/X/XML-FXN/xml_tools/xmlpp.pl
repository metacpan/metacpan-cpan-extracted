#!/usr/bin/perl  -w

#
#  Copyright (c) 2002, DecisionSoft Limited All rights reserved.
#  Please see: 
#  http://software.decisionsoft.com/licence.html
#  for more information.
# 

# $Revision: 1.32 $
#
# xmlpp: XML pretty printing
#

# For custom attribute sorting create an attributeOrdering.txt file that
# lists each attributes separated by a newline in the order you would like
# them to be sorted separated by a newline. Then use the -s option.

use FileHandle;
use Fcntl;
use Getopt::Std;

use vars qw($opt_h $opt_H $opt_s $opt_z $opt_t $opt_e $opt_S $opt_c $opt_n);

my $indent=0;
my $textContent='';
my $lastTag=undef;
my $output;
my $inAnnotation = 0;


if (!getopts('nzhHsteSc') or $opt_h) {
    usage();
}

if ($opt_s){

# expect to find attributeOrdering.txt file in same directory
# as xmlpp is being run from
    
  my $scriptDir = $0;
  if ($scriptDir =~ m#/#){
    $scriptDir =~ s#/[^/]+$##;
  }
  else{
    $scriptDir =".";
  }
    
  # get attribute ordering from external file
  if (open(SORTLIST, "<$scriptDir/attributeOrdering.txt")) {
    @sortlist = <SORTLIST>;
    chomp @sortlist;
    close (SORTLIST);
    @specialSort = grep(/^\w+/, @sortlist);
  } 
  else {      
   print STDERR  "Could not open $scriptDir/attributeOrdering.txt: $!\nWARNING attribute sorting will only be alphabetic\n\n";
  }
}


# set line separator to ">" speeding up parsing of XML files
# with no line breaks 

$/ = ">";


my $sortAttributes = $opt_s;
my $newLineComments = $opt_c;
my $splitAttributes = $opt_t;
my $schemaHackMode = $opt_S;
my $normaliseWhiteSpace = $opt_n;

my $filename = $ARGV[0];
if ($opt_z && (!$filename or $filename eq '-')) {
    print STDERR "Error: I can't edit STDIN in place.\n";
    usage();
}

if (!$opt_z && scalar(@ARGV) > 1) {
    print STDERR "Warning: Multiple files specified without -z option\n"; 
}

my $fh;

my $stdin;

if (!$filename or $filename eq '-') {
    $fh=*STDIN;
    $stdin=1;
} else {
    $fh = open_next_file() or exit(1);
    $stdin=0;
}

do {
    $indent=0;
    $textContent='';
    $lastTag=undef;
    $output = '';
    my $re_name = "(?:[A-Za-z0-9_:][A-Za-z0-9_:.-]*)";
    my $re_attr = "(?:'[^']*'|\"[^\"]*\")";
    my $input;

    while ($input .= <$fh>) {
        while ($input) {
            if ($input =~ s/^<($re_name)((?:\s+$re_name\s*=\s*$re_attr)*\s*)(\/?)>(.*)$/$4/s ) {
                my %attr;
                my ($name,$attr,$selfclose) = ($1,$2,$3);
                while ($attr =~ m/($re_name)\s*=\s*($re_attr)/gs) {
                    my ($name,$value) = ($1,$2);
                    $value =~ s/^["'](.*)["']$/$1/s;
                    $attr{$name} = $value;
                }
                if ($opt_e) {
                    parseStart($name, 0, %attr);
                    if ($selfclose) { parseEnd($name) }
                } else {
                    parseStart($name, $selfclose, %attr);
                }
            } elsif ($input =~ s/^<\/($re_name)\s*>(.*)$/$2/s) {
                parseEnd($1);
            } elsif ($input =~ s/^<!--(.*?)-->(.*)$/$2/s) { 
                parseComment($1);
            } elsif ($input =~ s/^([^<]+)(.*)$/$2/s) {
                parseDefault($1);
            } elsif ($input =~ s/^(<\?[^>]*\?>)(.*)$/$2/s) {
                parsePI("$1\n");
            } elsif ($input =~ s/^(<\!DOCTYPE[^\[>]*(\[[^\]]*\])?[^>]*>)(.*)$/$3/s) {
                parseDoctype("$1");
            } else {
                last;
            }
        }
        if (eof($fh)) {
            last;
        }
    }


    if ($input) {
        $input =~ m/([^\n]+)/gs;
        print STDERR "WARNING: junk remaining on input: $1\n";
    }
    $fh->close();

    if (!$opt_z) {
        if(!$opt_H){ 
            print "$output\n"
        } else {
            print html_escape($output)."\n"
        }
    } else {
        if ($input) { 
            print STDERR "Not overwriting file\n";
        } else {
            open FOUT,"> $filename" or die "Cannot overwrite file: $!";
            if(!$opt_H){
                print FOUT "$output\n"
            } else {
                print FOUT html_escape($output)."\n"
            }
            close FOUT
        }
    }
} while (
    !$stdin && $opt_z && ($fh = open_next_file(\$filename))
  );
  


sub parseStart {
    my $s = shift;
    my $selfclose = shift;
    my %attr = @_;

    $textContent =~ s/\s+$//; 
    printContent($textContent);

    if($inAnnotation) {
        return;
    }

    if($schemaHackMode and $s =~ m/(^|:)annotation$/) {
        $inAnnotation = 1;
        $textContent = '';
        $lastTag = 1;
        return;
    }
    if (length($output)) {
        $output .= "\n";
    }

    $output .= "  " x $indent;
    $output .= "<$s";
    my @k = keys %attr;

    if ($sortAttributes && (scalar(@k) > 1) ){

      my @alphaSorted;
      my @needSpecialSort;
      my @final;
      my $isSpecial;

      # sort attributes alphabetically (default ordering)
      @alphaSorted = sort @k;

      # read through sorted list, if attribute doesn't have specified
      # sort order, push it onto the end of the final array (this maintains
      # alphabetic order). Else create a list that has attributes needing
      # special ordering.
      foreach $attribute (@alphaSorted){
        $isSpecial = 0;
        foreach $sortAttrib (@specialSort){
          if ($attribute eq $sortAttrib){
            push @needSpecialSort, $attribute;
            $isSpecial = 1;
          }
        }
        if (!$isSpecial){
          push @final, $attribute;
        }
      }

      # now read through the specialSort list backwards looking for
      # any match in the needSpecialSort list. Unshift this onto the 
      # front of the final array to maintain proper order.
      foreach my $attribute (reverse @specialSort){
        foreach (@needSpecialSort){
          if ($attribute eq $_){
            unshift @final, $attribute;
          }
        }
      }

      @k = @final;
    }

    foreach my $attr (@k) {
        # 
        # Remove (min|max)Occurs = 1 if schemaHackMode
        #
        if ($schemaHackMode and $attr =~ m/^(minOccurs|maxOccurs)$/ and $attr{$attr} eq "1") {
            next;
        }

        if ($splitAttributes) {
            $output .= "\n"."  " x $indent." ";
        }
        if ($attr{$attr} =~ /'/) {
            $output .= " $attr=\"$attr{$attr}\"";
        } else {
            $output .= " $attr='$attr{$attr}'";
        }
    }
    if ($splitAttributes and @k) {
        $output .= "\n"."  " x $indent;
    }
    if ($selfclose) {
        $output .= " />";
        $lastTag = 0;
    } else {
        $output .= ">";
        $indent++;
        $lastTag = 1;
    }
    $textContent = '';
}

sub parseEnd {
    my $s = shift;

    if($inAnnotation) {
        if($s =~ m/(^|:)annotation$/) {
            $inAnnotation = 0;
        }
        return;
    }

    if($normaliseWhiteSpace) {
        $textContent =~ s/^\s*(.*?)\s*$/$1/;
    }
    $indent--;
    printContent($textContent);
    if ($lastTag == 0) {
        $output .= "\n";
        $output .= "  " x $indent;
    } 
    $output .= "</$s>";
    $textContent = '';
    $lastTag = 0;
}

sub parseDefault {
    my $s = shift;
    if($inAnnotation) { return }
    $textContent .= "$s";
}

sub parsePI {
    my $s = shift;
    $output .= "$s";
}

sub parseDoctype {
    my $s = shift;
    if ($s =~ /^([^\[]*\[)([^\]]*)(\].*)$/ms) {
      $start = $1;
      $DTD = $2;
      $finish = $3;
      $DTD =~ s/\</\n  \</msg;
      $output .= "$start$DTD\n$finish\n";
    } else {
      $output .= "$s";
    }
}

sub parseComment {
    my $s = shift; 
    if($inAnnotation) { return }
    printContent($textContent,1);
    if ($s =~ /([^\<]*)(<.*>)(.*)/ms) {
      $start = $1;
      $xml = $2;
      $finish = $3;
      $xml =~ s/\</\n\</msg;
      $xml =~ s/(\n\s*\n?)+/\n/msg;
      $xml =~ s/^\s*//msg;
      $xml =~ s/\s*$//msg;
      $s = "$start\n$xml\n$finish";
    }
    $s =~ s/\n\s*$/\n  /msg;
    if ($newLineComments) {
        $output .= "\n<!--$s-->\n";
    } else {
        $output .= "<!--$s-->";
    }
    $textContent='';
}

sub printContent {
    my $s = shift;
    my $printLF = shift;
    my ($LF,$ret) = ("","");

    if ($s =~ m/\n\s*$/) {
        $LF = "\n"; 
    }
    if ($s =~ m/^[\s\n]*$/) {
        $ret = undef;
    } else {
        $output .= "$s";
        $ret = 1;
    }
    if ($printLF) {
        $output .= $LF;
    }
}


sub html_escape {
    my $s = shift;
    $s =~ s/&/&amp;/gsm;
    $s =~ s/</&lt;/gsm;
     $s =~ s/>/&gt;/gsm;
    return $s;
}

sub open_next_file {
    my $filename = shift;
    $$filename = shift @ARGV;
    while ($$filename and ! -f $$filename) {
        print STDERR "WARNING: Could not find file: $$filename\n";
        $$filename = shift @ARGV;
    }
    if(!$$filename) {
        return undef;
    }
    my $fh = new FileHandle;
    $fh->open("< $$filename") or die "Can't open $$filename: $!";
    return $fh;
}

sub usage {
    print STDERR <<EOF;
usage: $0 [ options ] [ file.xml ... ]

options:
  -h  display this help message
  -H  escape characters (useful for further processing)
  -t  split attributes, one per line (useful for diff)
  -s  sort attributes (useful for diff)
  -z  in place edit (zap)
  -e  expand self closing tags (useful for diff)
  -S  schema hack mode (used by xmldiff)
  -c  place comments on new line.
  -n  normalise whitespace (remove leading and trailing whitespace from nodes
      with text content.

EOF
    exit 1;
}

