use Config;
use File::Basename qw(basename dirname);
($file = basename($0)) =~ s/\.PL$//;

open TEMPLATE, $file 
  or die "Can't open template file '$file':\n$!";
my $template = join '', <TEMPLATE>;
close TEMPLATE;
$template =~ s/^(#!.*\n|)/$Config{startperl} -w\n/;

print "Creating binary bin/$file...\n";
chdir(dirname($0));
open BIN, ">$file" or die "Can't create $file: $!";
print BIN $template;
close BIN;
chmod(0755, $file);

