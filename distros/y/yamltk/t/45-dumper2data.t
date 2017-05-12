use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();



use Smart::Comments '###';
use Data::Dumper;



my @data = ( 
   { name => 'leo', age => 35, },
   { name => 'jim', age => 25, },
   { name => 'paul',  },  
   { name => 'marge', state => 'md', },
);



my $string = Dumper(\@data);


warn "# string:
$string
\n\n";

=pod


my $string = q/
$VAR1 = {
          'name' => 'leo',
          'age' => 35
        };
$VAR2 = {
          'name' => 'jim',
          'age' => 25
        };
$VAR3 = {
          'name' => 'paul'
        };
$VAR4 = {
          'name' => 'marge',
          'state' => 'md'
        };
/;

=cut
# how do we turn that into a arref



my $VAR1;
eval $string;

### $VAR1
lookin($VAR1);




sub lookin {
   my $in = shift;
   warn "Looking into '$in'\n";
   defined $in or warn "Nothing here.\n" and return;
   my $r= ref $in;
   $r and warn "# is ref '$r'\n";
   if ($r eq 'ARRAY'){
      my @r = @{$in};
      ### @r
   }
   elsif ( $r eq 'HASH' ){
      my %r = %{$in};
      ### %r
   }
   ok( scalar @$in,'scalar' );
   1;
   
}

sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


