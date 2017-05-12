use Test::More 'no_plan';
use File::Copy 'cp';
use Test::Legal::Util qw/ deannotate_copyright /;
use File::Find::Rule;

* is_annotated              = * Test::Legal::Util::is_annotated ;


my $msg = '# Copyright by  bottle';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';


my $num = my @files = ( "$dir/blue", "$dir/black", "$dir/red" );
note 'copy files';
cp $_ , $dir     for  map { (my $f=$_) =~ s{(/[^/]*$)}{/bak$1}; $f }  @files  ;
chmod 0750, "$dir/blue";

is is_annotated($_,$msg), 1, "$_: is_annotated"  for @files;

is deannotate_copyright( [@files], $msg), 3 ;  

note 'check1 for deannoted files';
is is_annotated($_,$msg), 0, "$_: is_annotated"  for @files;

is +((stat("$dir/blue"))[2] & 07777), 0750, 'mode bits' ;

unlink @files;
exit;

ok ! deannotate_copyright(['/tmp/hots']);
