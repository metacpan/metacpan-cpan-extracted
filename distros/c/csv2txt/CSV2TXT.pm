# csv2txt -- CSV to text
# Copyright (c) 2001-2002 SANFACE Software <sanface@sanface.com>.
# All rights reserved.
# http://www.sanface.com/csv2txt.html
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# TODO
# alignment: center, left, right for columns and rows
# decimal e.g. 0.00 for columns and rows
# repeat the first line at the begin of every new page
# module
#
package Text::CSV2TXT;

use strict;
no strict 'refs';
use vars qw($VERSION $Error);

$VERSION = '2.0';

sub new {
  my $func=shift;
  my $input=shift;
  my $delimiter=shift;
  my $alignment=shift;
  my $addblanks=shift;
  my $decimal=shift;

  $decimal.="f";
  my (@fields,@word);
  my ($i,$j);
  my $output = $input . ".txt";
  open (IN, "$input") || die "couldn't open input file $input\n";
  open (OUT, ">$output") || die "couldn't open input file $output\n";
  while (<IN>)
    {
    s/\n//;
    s/\r//;
    push @fields, [split/$delimiter/];
    }

  for ($j=0;$j<=$#{$fields[0]};$j++) {
    $word[$j]=length($fields[0][$j])
    }

  for ($i=0;$i<=$#fields;$i++) {
    for ($j=0;$j<=$#{$fields[$i]};$j++) {
      if ($i eq 0) {next}
      else {
        if (length($fields[$i][$j])>$word[$j]) {$word[$j]=length($fields[$i][$j])}
      }
    }
  }
    
  my ($leftchars,$rightchars);
  for ($i=0;$i<=$#fields;$i++) {
    for ($j=0;$j<=$#{$fields[$i]};$j++) {
      if ($decimal ne "f") {
        if ($fields[$i][$j]  =~ /\d+\.\d+$/) {
	  $fields[$i][$j]=sprintf("%.$decimal", $fields[$i][$j]);
	}
      }
      if ($alignment eq "left") {
        $fields[$i][$j].=" " x ($word[$j]-length($fields[$i][$j]) + $addblanks)
        }
      if ($alignment eq "right") {
	$fields[$i][$j]= " " x ($word[$j]-length($fields[$i][$j])+$addblanks) . $fields[$i][$j]
        }
      if ($alignment eq "center") {
 	$rightchars = ($word[$j]-length($fields[$i][$j])+$addblanks)/2 + ($word[$j]-length($fields[$i][$j])+$addblanks)%2*0.5;
 	$leftchars = $word[$j]-length($fields[$i][$j])+$addblanks-$rightchars;
	$fields[$i][$j]= " " x $leftchars . $fields[$i][$j] . " " x $rightchars;
        }
      print OUT "$fields[$i][$j]";
      }
    print OUT "\n";
    }
  close(IN);
  close(OUT);
  }

1;

=head1 NAME

CSV2TXT.pm - Version 2.0 13th December 2002

=head1 DESCRIPTION

CSV2TXT.pm is a PERL5 module to converter csv files to text files.

=head1 SYNOPSIS

    my $csv = Text::CSV2TXT->new(
        $input,              # the csv file
        $delimiter,          # csv delimiter
        $alignment,          # cell alignment
        $addblanks,          # blanks added at the end of every cell
        $decimal             # max decimal number
    );

Remember: you can fin the last release and the last documentation at
http://www.sanface.com/csv2txt.htm
Are you interested into cvs2pdf?
Try our shareware at http://www.sanface.com/csv2pdf.html

=head1 AUTHOR

     SANFACE Software sanface@sanface.com
     http://www.sanface.com/

=head1 COPYRIGHT

© SANFACE Software

All Rights Reserved. This program is free software. It may be used,
redistributed and/or modified under the same terms as Perl itself.

=cut
