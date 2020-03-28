use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier qw(minify);

my $maxi = << "END";
<root>

  <keepblanks>



  </keepblanks>

</root>
END

my $minikeepblanks = << "END"; 
<root><keepblanks>



  </keepblanks></root>
END

chomp $maxi;
chomp $minikeepblanks;

is(minify($maxi, no_prolog => 1), $minikeepblanks, "Keep blanks in text nodes where parent has only one child (1)");

$maxi = << "END";
<root>

Not empty

  <keepblanks>



  </keepblanks>

Not empty

</root>
END

$minikeepblanks = << "END"; 
<root>

Not empty

  <keepblanks>



  </keepblanks>

Not empty

</root>
END


chomp $maxi;
chomp $minikeepblanks;

is(minify($maxi, no_prolog => 1), $minikeepblanks, "Keep blanks in text nodes where parent has only multiple child nodes but not empty (1)");

$maxi = << "END";
<root>

<!-- Comment -->

  <keepblanks>



  </keepblanks>

<!-- Comment -->

</root>
END

$minikeepblanks = << "END"; 
<root>

<!-- Comment -->

  <keepblanks>



  </keepblanks>

<!-- Comment -->

</root>
END


chomp $maxi;
chomp $minikeepblanks;

is(minify($maxi, no_prolog => 1, keep_comments => 1), $minikeepblanks, "Keep blanks in text nodes where parent has only multiple child nodes but not empty (2)");

$maxi = << "END";
<root> Not empty <!-- Comment -->  <!-- Comment --> <keepblanks> </keepblanks> <!-- Comment --> <!-- Comment --> </root>
END

my $minikeepcomments = << "END";
<root> Not empty <!-- Comment -->  <!-- Comment --> <keepblanks> </keepblanks> <!-- Comment --> <!-- Comment --> </root>
END

my $minidropcomments = << "END";
<root> Not empty    <keepblanks> </keepblanks></root>
END

chomp $maxi;
chomp $minikeepcomments;
chomp $minidropcomments;


is(minify($maxi, no_prolog => 1, keep_comments => 1), $minikeepcomments, "Keep comments, nothing can be done");
is(minify($maxi, no_prolog => 1, keep_comments => 0), $minidropcomments, "Remove comments therefore can clean some blanks");

done_testing;

