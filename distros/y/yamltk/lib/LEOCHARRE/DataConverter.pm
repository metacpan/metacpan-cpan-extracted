package LEOCHARRE::DataConverter;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);
use Exporter;
use Smart::Comments '###';



use YAML;
use Data::Dumper;
use Text::CSV::Slurp;

use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(data_type data2yaml data2csv data2dumper dumper2data yaml2data csv2data string2data);
%EXPORT_TAGS = ( all => \@EXPORT_OK );


sub data_type {
   my $string = $_[0];

   if ($string=~/^---\n/){
      return 'yaml';
   }   

   if ($string=~/^\$VAR\d = /){
      return 'dumper';
   }   

   # is it a csv
   my $is_csv;
   if( my @lines = split( /\n/,$string) ){
      my $delimited_lines;
      my $not_delimited_lines;
      my $delimiter =',';
      for (@lines){
         if ($_=~/^#/){ next }

         if ($_=~/\w/){
            if ($_=~/\Q$delimiter\E/){
               $delimited_lines++;
            }
            else {
               $not_delimited_lines++;
            }    
         }
      }   
      if ($delimited_lines and !$not_delimited_lines){
         return 'csv';
      }   
   }   
   return;

}



# figure it out ! :-)
sub string2data {
   my $string = $_[0];
   ref $string and die('data must be stringified, not ref');

   if ( my $type = data_type($string) ){
      ### type is: $type
      ($type eq 'csv') 
         and return csv2data($string);
      ($type eq 'yaml') 
         and return yaml2data($string);
      ($type eq 'dumper')
         and return dumper2data($string);

      ### dunno what to do with : $type
      return;
   }

   

   return;
}




sub _allkeys { # get all keys present in all hashes in the array ref
   my $aref_of_hashes=$_[0];
   my %keys;
   for my $href (@$aref_of_hashes){
      map { $keys{$_}++ } keys %$href;
   }
   sort keys %keys;
}


sub data2csv {
   my $ref = $_[0];
   ref $ref or die;
   #my $opts = $_[1];
   #
   my @fields = _allkeys($ref);
   
   my $string = Text::CSV::Slurp->create( input => $ref, field_order => [@fields] );
   return $string;
}

sub data2yaml {
   my $ref = $_[0];
   ref $ref or die;
   my $string = YAML::Dump($ref);
   return $string;
}

sub data2dumper {
   my $ref = $_[0];
   ref $ref or die;

   my $string = Data::Dumper::Dumper($ref);
   #my $string = Data::Dumper->Dump($ref);
   return $string;
}

sub csv2data {
   my $string = $_[0];
   ref $string and die("Cannot be ref, must be stringified");
   my $data = Text::CSV::Slurp->load( string => $string );
   return $data;
}

sub dumper2data { # TODO  use heuristcs to see if it's a series of vars or just one
   my $string = $_[0];
   ref $string and die("Cannot be ref, must be stringified");

   # may be $VAR1, $VAR2 etc or just $VAR1
   my $VAR1;
   my $VAR2;
   eval $string;
   defined $VAR2 and die("will not parse more than one var in dumper");
   return $VAR1;  
}

sub yaml2data {
   my $string = $_[0];
   ref $string and die("Cannot be ref, must be stringified");
   my @data = YAML::Load($string);
   [@data];
}
   



















1;

__END__

=pod

=head1 NAME

LEOCHARRE::DataConverter

=head1 SUBS


=head2 data2csv()

=head2 data2dumper()

=head2 data2yaml()

=head2 data_type()


=head2 dumper2data()

=head2 string2data()

=head2 yaml2data()

=head2 csv2data()


=head1 BUGS

Please contact the AUTHOR for any issues, suggestions, bugs etc.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) Leo Charre. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This means that you can, at your option, redistribute it and/or modify it under either the terms the GNU Public License (GPL) version 1 or later, or under the Perl Artistic License.

See http://dev.perl.org/licenses/

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Use of this software in any way or in any form, source or binary, is not allowed in any country which prohibits disclaimers of any implied warranties of merchantability or fitness for a particular purpose or any disclaimers of a similar nature.

IN NO EVENT SHALL I BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT LIMITED TO, LOST PROFITS) EVEN IF I HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE

=cut



