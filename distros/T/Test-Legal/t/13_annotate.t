use Test::More 'no_plan';
use File::Copy 'cp';
use Test::Legal::Util qw/ annotate_copyright /;
use File::Find::Rule;

*  default_copyright_notice = * Test::Legal::Util::default_copyright_notice;
* is_annotated              = * Test::Legal::Util::is_annotated ;


my $msg = '# Copyright (C) by  bottle';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

like default_copyright_notice(), qr/^# Copyright \(C\) \d{4}/o ;

my $num = my @files = ( "$dir/blank", "$dir/blank2", "$dir/apple" );
note 'copy files';
cp $_ , $dir     for  map { (my $f=$_) =~ s{(/[^/]*$)}{/bak$1}; $f }  @files  ;
chmod 0750, "$dir/blank2";


note 'now, annote them';
is  annotate_copyright([@files[0..1]], $msg), 2, "copyright  annotated"  ;
is  annotate_copyright($files[-1], $msg), 1, "copyright  annotated"  ;
note 'annote them again, and again';
ok !  annotate_copyright(\@files, $msg),  "copyright  annotated"  ;

note 'check1 for annoted files';
my @n= File::Find::Rule->file->grep(qr/\Q$msg/)->maxdepth(1)->in($dir);
is_deeply [sort @n], [sort @files];

note 'check2 for annoted files';
is is_annotated($_,$msg), 1, "$_: is_annotated only once"  for @files;

is +((stat("$dir/blank2"))[2] & 07777), 0750, 'mode bits' ;

unlink @files;
ok ! annotate_copyright(['/tmp/hots']);
