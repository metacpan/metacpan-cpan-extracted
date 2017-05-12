#
# (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
#

open F,"c:\\My Temporary Files\\etools98.tex";

my $body = undef;
my $type = "TeX";
my $author = $undef;
while(<F>) {
  $type="LATeX" if(m!documentclass!);
  if(m!\@!) {
    s!^.*[ \t{]([A-z0-9._-]+@[A-z0-9._-]+)[ \t}e].*$!$1!g;
    $author = " by $_";
  }
}
close F;

print "$type document$author";


