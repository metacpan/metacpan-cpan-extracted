#######################################################
#I am using XML::DT as below (the require is for selective module loading):
#######################################################
#
#require XML::DT; XML::DT->import ();
# Yes !!!

use strict;

use Data::Dumper;
use XML::DT;

my @order=qw(volume issue doi author f_page l_page artid epub ppub type);

my $M;

my %handler = (
   '-default'   => sub {$c},
   'article' => sub {
#           $v{issue} = $dtattributes[1]->{number};
#           $v{volume} = $dtattributes[2]->{number};
           $v{issue}  = father("number");
           $v{volume} = gfather("number");

           $M .= join(" :\t", @v{(@order)}) . "\n";
    },
 );

 dt ("ex11.5.xml", %handler);
 print  $M;

__END__

<main>
<volume number="27">
  <issue number="7">
   <article doi="10.1006/jmcc.1995.0129" artid="mc950129" f_page="1359" l_page="1367"
            type="xx" author="Juhani Knuuti, M." epub="" ppub="19950700" />
   <article doi="10.1006/jmcc.1995.0130" artid="mc950130" f_page="1369" l_page="1381"
            type="xx" author="Cross, H.R." epub="" ppub="19950700" />
  </issue>

  <issue number="8">
    <article doi="10.1006/jmcc.1995.0129" artid="mc950129" f_page="1359" l_page="1367"
            type="xx" author="Juhani Knuuti, M." epub="" ppub="19950700" />
    <article doi="10.1006/jmcc.1995.0130" artid="mc950130" f_page="1369" l_page="1381"
            type="xx" author="Cross, H.R." epub="" ppub="19950700" />
</issue>

