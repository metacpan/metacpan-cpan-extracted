use Test::More 'no_plan';
use File::Copy 'cp';
use Test::Legal::Util qw/ deannotate_copyright /;

* is_annotated              = * Test::Legal::Util::is_annotated ;


my $msg = '# Copyright by  bottle';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';


my $num = my @files = ( "$dir/is-anno" );
note 'copy files';
cp $_ , $dir     for  map { (my $f=$_) =~ s{(/[^/]*$)}{/bak$1}; $f }  @files  ;

is is_annotated($_,), 1, "$_: is_annotated"  for @files;

exit;

unlink @files;

