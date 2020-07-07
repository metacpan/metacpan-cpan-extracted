# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

open(FILE,">@{[__FILE__]}.1"   ); print FILE q{ 1 }; close(FILE);
open(FILE,">@{[__FILE__]}.2"   ); print FILE q{ 1 }; close(FILE);
open(FILE,">@{[__FILE__]}.3"   ); print FILE q{ 1 }; close(FILE);
if ($^O =~ /MSWin32/) { 
    open(FILE,">@{[__FILE__]}.1表\"); print FILE q{ 1 }; close(FILE);
    open(FILE,">@{[__FILE__]}.2表\"); print FILE q{ 1 }; close(FILE);
    open(FILE,">@{[__FILE__]}.3表\"); print FILE q{ 1 }; close(FILE);
}

@test = (
# 1
    sub { chdir($FindBin::Bin); @_ = mb::eval(q{ <*.1 *.2 *.3> }); scalar(@_) == 3 },
    sub { chdir($FindBin::Bin); mb::eval(q{ @_ = <*.1 *.2 *.3>; scalar(@_) == 3 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('"*.1" "*.2" "*.3"'); scalar(@_) == 3 },
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('"*.1" "*.2" "*.3"'); $_[0] =~ /\.1$/ },
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('"*.1" "*.2" "*.3"'); $_[1] =~ /\.2$/ },
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('"*.1" "*.2" "*.3"'); $_[2] =~ /\.3$/ },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('*.1 *.2 *.3'); scalar(@_) == 3 },
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('*.1 *.2 *.3'); $_[0] =~ /\.1$/ },
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('*.1 *.2 *.3'); $_[1] =~ /\.2$/ },
    sub { chdir($FindBin::Bin); @_ = mb::dosglob('*.1 *.2 *.3'); $_[2] =~ /\.3$/ },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('"*.1表" "*.2表" "*.3表"'); scalar(@_) == 3   }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('"*.1表" "*.2表" "*.3表"'); $_[0] =~ /\.1表$/ }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('"*.1表" "*.2表" "*.3表"'); $_[1] =~ /\.2表$/ }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('"*.1表" "*.2表" "*.3表"'); $_[2] =~ /\.3表$/ }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('*.1表 *.2表 *.3表'); scalar(@_) == 3   }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('*.1表 *.2表 *.3表'); $_[0] =~ /\.1表$/ }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('*.1表 *.2表 *.3表'); $_[1] =~ /\.2表$/ }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ chdir($FindBin::Bin); @_ = mb::dosglob('*.1表 *.2表 *.3表'); $_[2] =~ /\.3表$/ }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub { chdir('..'); },
    sub { mb::_unlink("@{[__FILE__]}.1"   ); },
    sub { mb::_unlink("@{[__FILE__]}.2"   ); },
    sub { mb::_unlink("@{[__FILE__]}.3"   ); },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::_unlink("@{[__FILE__]}.1表\"); },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::_unlink("@{[__FILE__]}.2表\"); },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::_unlink("@{[__FILE__]}.3表\"); },
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
