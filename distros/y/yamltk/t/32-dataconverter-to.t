use Test::Simple 'no_plan';
use strict;
use Smart::Comments '###';
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();
use LEOCHARRE::DataConverter ':all';




my @data = (
   { name => 'leo', age => 35, },
   { name => 'jim', age => 25, },
   { name => 'paul',  },
   { name => 'marge', state => 'md', },
);



clear();


ok_part('prep');
my $dat;

$dat = q{
open( OUT, '>','t/data.garble') or die;
pirint OUT "garble garblefageight 842y 42\n";
print OUT "more agaggarble garblefageight 842y 42\n";
print OUT "sgag43 more agaggarble garblefageight 842y 42\n";
close OUT;
};
ok(
   save(
      't/data.garble',
      $dat
   ),
   'made garble');

ok(
   save(
      't/data.dumper', 
      data2dumper(\@data)
   ),
   'made dumper');

ok( 
   save(
      't/data.yaml', 
      data2yaml(\@data)
   ),
   'made yaml');

ok(
   save(
      't/data.csv',
      data2csv(\@data),
   ),
   'made csv',);





ok_part('string2data()');

for my $ext (qw/dumper yaml csv/){
   my $string = `cat t/data.$ext`;
   $string or die;
   
   printf STDERR "%s\n", '-'x80;
   my $data_type = data_type($string);
   ### $ext
   ### $data_type

   ok($data_type eq $ext,"data_type()");

  
   # load it
   my $data = string2data($string);
   ok( $data, 'string2data()');
   
   ok( ref $data eq 'ARRAY', 'is array ref'); 
   

}



ok_part("# GARBLES..");
for my $ext (qw/garble/){
   my $string = `cat t/data.$ext`;
   $string or die;

   printf STDERR "%s\n", '-'x80;

   my $data_type = data_type($string);
   ### $ext
   ### $data_type

   ok(!$data_type);
}










###############################################################################
# subs



sub clear { unlink map { "t/data.$_" } qw/storable dumper dump yaml csv garble/ }



sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


sub save {
   my ($path, $string)=@_;
   open(OUT,'>',$path) or die;
   print OUT $string;
   close OUT;
   1;
}

