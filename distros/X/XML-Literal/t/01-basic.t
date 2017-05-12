use strict;
use Test::More tests => 7;
use ok 'XML::Literal' => sub {"!$_[0]!"};

my $var  = 'submit';
my $xml1 = <hr/>;   # simple element
my $xml2 = <input value='$var' />; # interpolation
my $xml3 = < <a href='/'> Some Text </a> >;
my $xml4 = <a href='/'\> Some Text \</a>;
my $xml5 = glob'
    <p><em>
        Some Text
    </em></p>
';

my $files = <*.moose.*>; # this is still shell glob

is $xml1, "!<hr/>!";
is $xml2, "!<input value='submit' />!";
is $xml3, "! <a href='/'> Some Text </a> !";
is $xml4, "!<a href='/'> Some Text </a>!";
is $xml5, "!
    <p><em>
        Some Text
    </em></p>
!";
is $files, undef;
