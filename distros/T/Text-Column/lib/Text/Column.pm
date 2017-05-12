#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Text::Column;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.11';
$DATE = '2004/04/29';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(format_hash_table format_array_table);

######
# Format hash table
#
sub format_hash_table
{

    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($h_p, $width_p, $header_p) = @_;

    unless (ref($h_p) eq 'HASH') {
        warn "# Table to format must be an hash table\n";
        return undef;
    }
    
    my @array_table = ();
    my (@key_stack, @keys, $key, $entries_p, @entries, $entry);
    @keys = sort keys %$h_p;
    while( @keys ) {

       #######
       # Using the @array_column pre-fix from the previous interrupted
       # hash column
       # 
       # Since pushing pointers, instead of values, need to begin a
       # a brand new @array_column
       #
       my @array_column = (@key_stack) ? @{$key_stack[-1]} : ();
       $key = shift @keys; 
       push @array_column, $key;
       $entries_p = $h_p->{$key};
       if (ref($entries_p) eq 'ARRAY' ) {
           push @array_column,@$entries_p;
           push @array_table, \@array_column;
           next;
       }

       #######
       # Have a hash column. Remember where at for the
       # current column and sort the keys for the next
       # column.
       #
       if (ref($entries_p) eq 'HASH' ) {
           my @keep_keys = @keys;
           push @key_stack, (\@keep_keys, $h_p, \@array_column);
           $h_p = $entries_p;
           @keys = sort keys %$h_p;
           next;
       }

       push @array_table, \@array_column;
       unless(@keys) {
           pop @key_stack;
           $h_p =  pop @key_stack;
           @keys = @{pop @key_stack};
       }

   }

   Text::Column->format_array_table( \@array_table, $width_p, $header_p );
}


######
# Format an array table.
#
sub format_array_table
{

    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($a_p, $width_p, $header_p) = @_;

    unless (ref($a_p) eq 'ARRAY') {
        warn "# Table to format must be an array table\n";
        return undef;
    }
    
    ######
    # Format the inventory list
    #
    unless (ref($width_p) eq 'ARRAY') {
        warn "# Width  must be an array\n";
        return undef;
    }
    my @w = @$width_p;
    my $total=0;
    my (@dash, @header);
    foreach my $w (@w) {
        $total += $w;
        push @dash,'-' x $w;        

    }
    unshift @$a_p,[@dash];
    unshift @$a_p,[@$header_p];
    
    my ($type, $r_p, @r, $r, $r_total, $c, $size);
    my $str = "\n ";
    foreach $r_p (@$a_p) {
        
        unless (ref($r_p) eq 'ARRAY') {
            warn "# Rows in table to format must be an arrays\n";
            return undef;
        }

        @r = @$r_p;

        $r_total = 0;     
        foreach $r (@r) {
            $r_total += length( $r);   
        }

        #####
        # Mutlitple of single line
        #
        $type = ($total < $r_total) ? 1 :0;
        if ($type) {
            $str =~ s/(.*?)\s*$/$1/sg; # drop trailing white space
            $str .= "\n ";
        }

        while( $r_total ) {
            for( $c=0; $c < @w; $c++ ) {

                #######
                # Determine amount of row entry to use for column
                # 
                $size = length( $r[$c] );
                $size = ($w[$c] < $size) ? $w[$c] : $size;
                
                ########
                # Add row to column
                #  
                $str .= substr( $r[$c], 0, $size );
                if ($size < length( $r[$c] )) {
                    $r[$c] = substr( $r[$c], $size);
                }
                else {
                    $r[$c] = '';
                    $str .= ' ' x ($w[$c] - $size);
                }
                if($c < (@w - 1)) {
                    $str .= ' ';
                }
                else {
                    $str =~ s/(.*?)\s*$/$1/sg; # drop trailing white space
                    $str .= "\n ";
                }
            }

            $r[$c] = '' unless($c < @w);  # ran out of columns   

            $r_total = 0;     
            foreach $r (@r) {
                $r_total = length( $r);   
            }
        }


        if ($type) {
            $str =~ s/(.*?)\s*$/$1/sg; # drop trailing white space
            $str .= "\n ";
        }
    } 

    ######
    # Clean up table
    #    
    $str =~ s/^\s*(.*)\n\s*$/$1/s;  # drop leading trailing white space
    while( chomp $str ) { };  # single line feed at the end
    $str .= "\n";
    $str = ' ' . $str;
}

1

__END__

=head1 NAME
  
Text::Column - format tables from specific array and hash structures

=head1 SYNOPSIS
 
  #####
  # Subroutine interface
  #
  use Text::Column qw(format_hash_table format_array_table);

  $table = format_hash_table(\%hash, \@width, \@header);
  $table = format_array_table(\@array, \@width, \@header);

  #####
  # Object interface
  #
  use Text::Column;

  $table = Text::Column->format_hash_table(\%hash, \@width, \@header);
  $table = Text::Column->format_array_table(\@array, \@width, \@header);

=head1 DESCRIPTION

The methods in this module are used to generate formated tables from the
data in various specific array and hash structures.
These subroutines are used in test software. 
They are used to build simple inventory listings, 
tracebility listins and such for PODs.
Thus, the purpose is not to load them with a lot of word processing
features but to keep them bare bones with as little code as possible.
Feature creep is prohibited.
The last thing need is a blue screen for out of a 100,000 line
option ridden, ten layer deep objectize, word processor in
the test software.

=head1 SUBROUTINES

=head2 format_array_table

 $formated_table = format_array_table(\@array, \@width, \@header)

The I<format_array_table> method provides a formatted table suitable for inclusion in
a POD. The I<\@array> variable references an array of array references.
Each array reference in the top array is for a row array that
contains the items in column order for the row.
The I<\@width> variable references the width of each column in column order
while the I<\@header> references the table column names in column order. 

=head2 format_hash_table

 $table = format_hash_table(\%hash, \@width, \@header)

The I<format_hash_table> method provides a formatted table suitable for inclusion in
a POD. The I<\%array> variable references a hash of references to either arrays or hashes.
Each key is the first column of a row.
An array referenced by the hash value
contains the items in column order for the rest of the row.
The keys of a hash referenced by the hash value is
the items for the next column in the row.
Any other hash value signals the end of the row.
The I<format_hash_table> method always sort hash keys.

The I<\@width> variable references the width of each column in column order
while the I<\@header> references the table column names in column order. 

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Spec;

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     my $tt = 'Text::Column';

 =>     my $loaded = '';
 =>     my $template = '';
 =>     my %variables = ();
 =>     my $expected = '';
 => my $errors = $fp->load_package($tt)
 => $errors
 ''

 => my @array_table =  (
 =>    [qw(module.pm 0.01 2003/5/6 new)],
 =>    [qw(bin/script.pl 1.04 2003/5/5 generated)],
 =>    [qw(bin/script.pod 3.01 2003/6/8), 'revised 2.03']
 => );
 => $tt->format_array_table(\@array_table, [15,7,10,15],[qw(file version date comment)])
 ' file            version date       comment
  --------------- ------- ---------- ---------------
  module.pm       0.01    2003/5/6   new
  bin/script.pl   1.04    2003/5/5   generated
  bin/script.pod  3.01    2003/6/8   revised 2.03
 '

 => my %hash_table =  (
 =>    'module.pm' => [qw(0.01 2003/5/6 new)],
 =>    'bin/script.pl' => [qw(1.04 2003/5/5 generated)],
 =>    'bin/script.pod' => [qw(3.01 2003/6/8), 'revised 2.03']
 => );
 => $tt->format_hash_table(\%hash_table, [15,7,10,15],[qw(file version date comment)])
 ' file            version date       comment
  --------------- ------- ---------- ---------------
  bin/script.pl   1.04    2003/5/5   generated
  bin/script.pod  3.01    2003/6/8   revised 2.03
  module.pm       0.01    2003/5/6   new
 '

 => %hash_table =  (
 =>    'L<test1>' => {'L<requirement4>' => undef, 'L<requirement1>' => undef },
 =>    'L<test2>' => {'L<requirement3>' => undef },
 =>    'L<test3>' => {'L<requirement2>' => undef, 'L<requirement1>' => undef },
 => );
 => $tt->format_hash_table(\%hash_table, [20,20],[qw(test requirement)])
 ' test                 requirement
  -------------------- --------------------
  L<test1>             L<requirement1>
  L<test1>             L<requirement4>
  L<test2>             L<requirement3>
  L<test3>             L<requirement1>
  L<test3>             L<requirement2>
 '

=head1 QUALITY ASSURANCE

Running the test script C<Column.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Column.t> test script, C<Column.d> demo script,
and C<t::Text::Column> program module POD,
from the C<t::Text::Column> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Column.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Text::Column> program module
is in the distribution file
F<Text-Column-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirement Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::Text_Column|Docs::Site_SVD::Text_Column>

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=back

=cut

### end of file ###