# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 1
mb::use Perl::Module 5.00503 qw(foo bar boo);
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import(qw(foo bar boo)); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
mb::use Perl::Module 5.00503 qw();
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
mb::use Perl::Module 5.00503;
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503); Perl::Module->import; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
mb::use Perl::Module;
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->import; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
mb::use Perl::Module qw(foo bar boo);
END1
BEGIN { mb::require 'Perl::Module';  Perl::Module->import(qw(foo bar boo)); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
mb::use Perl::Module qw();
END1
BEGIN { mb::require 'Perl::Module'; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
mb::use Perl::Module;
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->import; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
mb::no Perl::Module 5.00503 qw(foo bar boo);
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->unimport(qw(foo bar boo)); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
mb::no Perl::Module 5.00503 qw();
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
mb::no Perl::Module 5.00503;
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503); Perl::Module->unimport; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
mb::no Perl::Module;
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->unimport; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
mb::no Perl::Module qw(foo bar boo);
END1
BEGIN { mb::require 'Perl::Module';  Perl::Module->unimport(qw(foo bar boo)); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
mb::no Perl::Module qw();
END1
BEGIN { mb::require 'Perl::Module'; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
mb::no Perl::Module;
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->unimport; };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
mb::use  # comment-1
 
# comment-2
  
 # comment-3
  # comment-4
   
Perl::Module   # comment-5
    
# comment-6
     
 # comment-7
  # comment-8
   # comment-9
      
5.00503    # comment-10
       
# comment-11
        
 # comment-12
  # comment-13
   # comment-14
    # comment-15
         
qw(foo bar boo);     # comment-16
          
# comment-17
           
 # comment-18
  # comment-19
   # comment-20
    # comment-21
            
END1
BEGIN { mb::require  # comment-1
 
# comment-2
  
 # comment-3
  # comment-4
   
'Perl::Module';   # comment-5
    
# comment-6
     
 # comment-7
  # comment-8
   # comment-9
      
Perl::Module->VERSION(5.00503);    # comment-10
       
# comment-11
        
 # comment-12
  # comment-13
   # comment-14
    # comment-15
         
 Perl::Module->import(qw(foo bar boo)); };     # comment-16
          
# comment-17
           
 # comment-18
  # comment-19
   # comment-20
    # comment-21
            
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
mb::use Perl::Module 5.00503 qw(;);
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import(qw(;)); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
mb::use Perl::Module 5.00503 qw(});
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import(qw(})); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
mb::use Perl::Module 5.00503 qw( ; } );
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import(qw( ; } )); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
mb::use Perl::Module 5.00503 (';','}');
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import((';','}')); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
mb::use Perl::Module 5.00503 qw( } ; );
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import(qw( } ; )); };
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
mb::use Perl::Module 5.00503 ('}',';');
END1
BEGIN { mb::require 'Perl::Module'; Perl::Module->VERSION(5.00503);  Perl::Module->import(('}',';')); };
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
