use strict;
use Config;
my $PerlV = $Config{api_versionstring};

print "Input file:	$ARGV[0]\n";
print "Output file:	$ARGV[1]\n";

open INPUT, "<$ARGV[0]" or die "Can not read file $ARGV[0]\n";
open OUTPUT, ">$ARGV[1]" or die "Can not read file $ARGV[1]\n";
if  ($PerlV =~/5[_\.]8[_\.]0/){
  binmode(OUTPUT,":utf8") 
}else{
  binmode OUTPUT;
}

my @text_arr = <INPUT>;
my $text_str = "@text_arr";

my @LanguageName = qw ( ''
	Unicode::Indic::Devanagari
	Unicode::Indic::Bengali
	Unicode::Indic::Gurmukhi
	Unicode::Indic::Gujarati
	Unicode::Indic::Oriya
	Unicode::Indic::Tamil
	Unicode::Indic::Telugu
	Unicode::Indic::Kannada
	Unicode::Indic::Malayalam
);

my $mode = 0;
my $tolang;
my $buf;
my $uselang;

foreach my $ch (split (//, $text_str),' '){
  if ($mode == 0 and $ch ne '^'){
    print OUTPUT $ch;
    next;
  }
  if ($mode == 0 and  $ch eq '^'){
    $mode = 1;  # Start transliteration.
    next;
  }
  if ($mode == 2 and $ch eq '^'){
    print OUTPUT $uselang->translate($buf);
    $buf = '';
    $mode = 0 ; # End of transliteration text.
    next;
  }
  if ($mode == 1){
    my $lang = $ch;
    $lang = $LanguageName[$ch];
    eval "use $lang;";
    $uselang = $lang->new();
    $mode = 2;
    next;
  }
  if ($mode == 2 and $ch ne '^'){
    $buf .= $ch;
    next;
  }
}
__END__

=head1	NAME

	transliterate	-Perl program to transliterate Indic language HTML page contents from roman script encoding to corresponding UNICODE fonts.

=head1	SYNOPSIS

	transliterate.pl	<input file> <output file>

=head1	DESCRIPTION

	The HTML text is copied from input file to output file.
	During the process, parts of the input file text may be transliterated into Indic fonts. The format of the text string to be transliterated is controlled by the convention

	^<digit>text to be transliterated^

	where a <digit> has the corrospondence to an Indic language as defined bellow.

	1. Devanagari
	2. Bengali
	3. Gurumukhi
	4. Gujarati
	5. Oriya
	6. Tamil
	7. Telugu
	8. Kannada
	9. Malayalam


	Example:

	^7Sriraama jayaraama jaya jaya raama^
	The above string will be transliterated into UNICODE Telugu font.
	
=head1	AUTHOR

	Syamala Tadigadapa

=head1  COPYRIGHT

	Copyright (c) 2003, Syamala Tadigadapa. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)		
