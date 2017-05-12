package warnings::regex::recompile;
$VERSION = 0.01;

use 5.006;
use warnings;
use strict; 

=head1 NAME

warnings::regex::recompile - Get Warnings about regex/pattern recompilation in Perl code.

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

warnings::regex::recompile gives Warnings with the line numbers if any regex/patten is getting recompiled in Perl code .

It is Prgamatic module, so one can use it like this;

use warnings::regex::recompile;

Example,
#strings.pl

my @regexps = qw( foo bar baz );
my @strings = qw( abc def ghi );

for my $string (@strings) {

   for my $regex (@regexps) {

      $string =~ /$regex/
   
   }

}

In this case, warning will be like this,

[ WARNING : Pattern bar is getting re-compiled on 7 in strings.pl. You are advised to use qr// operator, which boost the speed/performance of your code. ]

[ WARNING : Pattern baz is getting re-compiled on 7 in strings.pl. You are advised to use qr// operator, which boost the speed/performance of your code. ]

[ WARNING : Pattern foo is getting re-compiled on 7 in strings.pl. You are advised to use qr// operator, which boost the speed/performance of your code. ]



This module also figure out the variable name if the variable has dynamic regex. for exa:

#Time.pl
my $a = "abcdefghijklmnopqrstuvwxyz"; 
my $b = 1; 

for (1..1000) { 
	
	$b = ($b + 1) % 10; 
	
	#print "b : $b\n";
		
	$a =~ s/$b a//; 
} 

In this case, warning will be like this,

[ WARNING : Variable $b is getting re-compiled on 19 in Time.pl. You are advised to use qr// operator, which boost the speed/performance of your code. ]

#Module gives [NO WARNINGS !!!] if there is no regex/pattern getting recompiled.


=cut

my ($filename, %hash1, %hash2); 
my $data ="";


my $deli_pat = qr/[\|\!\~\^\'\"\:\<\&\#\%\@\?\$\{\/]/;
my $non_word_or_space_sep = qr/[\W\s]+/;
  

=head1 SUBROUTINES/METHODS

=head2 scan

=cut
  
sub scan{

$filename = $0;

##open file to read data and extract data to parse and compile by eval. 

open my $fh, "$filename" or die "$filename couldn't open $!\n";


while(my $line = <$fh>){

next if $line=~/^\s*(?:use|require)/;
	
$data .="$line";

}

close $fh;



  END{ 
##execute function which use re 'debug' on the *$data*.

execute($data); #subroutine to open and read *debug* file.

check_recompilation();


#Print the warning with line numbers and advise to use qr//operator to prevent recompiling which boost the speed/performance of the code. 

if(scalar %hash2){
 
print_warning($filename);

}
else
{
 
print "[ NO WARNING !!! ]\n";
 
}

}
	
	 }


=head2 execute

=cut


sub execute{

my $data = shift;

use re 'debug';

open STDERR, ">debug.re" or die "debug.re couldn't open $!\n";

eval $data;

}


=head2 check_recompilation

=cut


sub check_recompilation{
	
open my $fh, "debug.re" or die"debug.re couldn't open\n";	 

my $debugbuf = join'', <$fh>; close $fh; #print $debugbuf; 

#Compiling REx "[a-z]+"

$debugbuf =~s{Compiling\s+REx\s+\"(.+?)\"}{
	
my ($regex) = $1;	

#print "$regex\n";


if(exists $hash1{$regex}){
	
#print "ONE : $regex\n";	
	
$hash2{$regex} = 2;	 #print $hash2{$regex},"\n";


}else
{

#print "TWO :  $regex\n";
	
$hash1{$regex} = 1;

}


}sgeix;


return $debugbuf;

}


=head2 print_warning

=cut


sub print_warning{

my $filename = shift;

#print $filename;

##open file to read data and to check the pattern name and print the warning with the line numbers.

open my $fh, "$filename" or die "$filename couldn't open $!\n";

my $line_no =0;

while(my $line = <$fh>){

$line_no++;	

next if $line=~/^\s*#/;

#print "$line_no : $line\n";



foreach my $key(keys %hash2){

#/[a-z]+ [A-z]+/
#[a-z]{1,}
#[a-z]{1,}[0-9]\/

#print "$key\n";
#Change in in Pattern  according to modifier used , so that pattern in *debug.re* could match with the Pattern in Perl file.
#here there is problem with open culry brace({).


#Caution : i shudnt use *$deli_pat* here.

#$key=~s{(?<!\\)([\/\!\~\^\'\"\:\<\&\#\%\@\$]|(?:\?(?!\:)))}{\\$1}sx;

$key=~s{(?<!\\)([\/\!\~\^\'\"\<\&\#\%\#\@\$]|(?:\?(?!\:))|(?:(?!\:)\:))}{\\$1}sx;


#print "$key\n";

###For Dynamic regex which consist in Perl Varaibles.

my $dynkey = $key;


#print "$dynkey\n";

#$b a

##split the line on Nonword character or space to get the variable name from code/perl file.

my($variable,$pat) = split"$non_word_or_space_sep", $dynkey;

#print "$variable : $pat\n";

#$b a




my ($type,$dynpat);

if($variable && $pat){

($type,$dynpat)=$line=~/([\$\@\%\{\}\_]+)([A-z][A-z0-9\_]*)$non_word_or_space_sep$pat\b/; 


}

#print "$type : $dynpat\n";

#print "$variable : $pat : $dynpat\n";

		

###For Constant regex.



#print "VARPAT : $varpat\n";

if($line=~/($deli_pat)\Q$key\E(?:\1|\}|\>)/ || $line=~/\Q$key\E\s+/ || $line=~/\s+\Q$key\E/){

print "[ WARNING : Pattern $key is getting re-compiled on $line_no in $filename. You are advised to use qr// operator, which boost the speed/performance of your code. ]\n\n";	
	
}elsif($variable && $pat && $type && $dynpat && $line=~/\Q$type\E\b$dynpat\b/)
{
 
if($dynpat){
  
print "[ WARNING : Variable $type$dynpat is getting re-compiled on $line_no in $filename. You are advised to use qr// operator, which boost the speed/performance of your code. ]\n\n";	

} 


last; 

}


 }

 }



close $fh;
	
	
}




sub import {


   $^H{"warnings::regex::recompile"} = 1;
 
 
   my($package) = (caller(1))[0];


   return warnings::regex::recompile::scan;
   
}



sub unimport {
 
    $^H{"warnings::regex::recompile"} = 0;


}
 


=head1 EXPORT

Since this is Pragmatic module, it doesn't Export any subroutine.

=head1 NOTES

This module doesn't recognise free form regex's which has spaces in it. exa: 

regex = /
  
     regex
    re1  #

re2

/x;

=head1 AUTHOR

Kiran Rajendrasa Pawar, C<< <pawark86 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-warnings::regex::recompile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=warnings::regex::recompile>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc warnings::regex::recompile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=warnings::regex::recompile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/warnings::regex::recompile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/warnings::regex::recompile>

=item * Search CPAN

L<http://search.cpan.org/dist/warnings::regex::recompile/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Kiran Rajendrasa Pawar.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of warnings::regex::recompile
