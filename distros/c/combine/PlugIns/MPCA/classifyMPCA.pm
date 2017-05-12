package classifyMPCA;
####NOT TESTED##############

use Combine::XWI; #Mandatory
use Combine::Config; #Optional if you want to use the Combine configuration system

use Saa; #This comes from the MPCA suite. Make sure it's available to Perl
my $saa = new Saa();
my $wait=1;
my %MSG=('command'=>'call',
         'object'=>'classify',
         'function'=>'query'
         );

use Combine::Config;
my ($host,$port)=split(':',Combine::Config::Get('MPCAHostPort'));

#API:
#  a subroutine named 'classify' taking a XWI-object as in parameter
#    return values: 0/1
#        0: record fails to meet the classification criteria, ie ignore this record
#        1: record is OK and should be stored in the database, and links followed by the crawler
sub classify { 
  my ($self,$xwi) = @_;

  #utility routines to extract information from the XWI-object

  #Title:
  my $text = $xwi->title . ' ';

  #Metadata:
     $xwi->meta_rewind;
     my ($name,$content);
     while (1) {
       ($name,$content) = $xwi->meta_get;
       last unless $name;
       next if ($name eq 'Rsummary');
       next if ($name =~ /^autoclass/);
       $text .= $content . " ";
     } 

  #Headings:?
   #  $xwi->heading_rewind;
   #  my $this;
   #  while (1) {
   #    $this = $xwi->heading_get or last; 
   #    $head .= $this . " "; 
   #  }

  #Text:
    $this = $xwi->text;
    if ($this) {
      $text .= $$this;
    }

###############################
#Apply your classification algorithm here
#  assign $result a value (0/1)
###############################

    $MSG{'content'}="$text";
    my $pca = &_send_query(\%MSG);

    #print "PCA=$pca\n";

  #utility routines for saving detailed results (optional) in the database. These data may appear
  # in exported XML-records

  #Topic takes 5 parameters
  # $xwi->topic_add(topic_class_notation, topic_absolute_score, topic_normalized_score, topic_terms, algorithm_id);
  #  topic_class_notation, topic_terms, and algorithm_id are strings
  #    max length topic_class_notation: 50, algorithm_id: 25
  #  topic_absolute_score, and topic_normalized_score are integers
  #  topic_normalized_score and topic_terms are optional and may be replaced with 0, '' respectively
  $xwi->topic_add('ALL', 1000*$pca, 1000*$pca,'','mpca');

    # return true (1) if you want to keep the record
    # otherwise return false (0)
    if ($pca>0.5) {return 1;} else {return 0;}
}

sub _send_query
{
    my $msg=shift;

    # warn "query_client(): before queue()";

    $saa->queue($host, $port, $msg, 
                arb_name => undef, arb => undef) || die($saa->{'err'} . "\n");

    # warn "query_client(): after queue()";

    my($ok, $sent, $received, $pending);
    $received = []; $sent = [];
    while(scalar(@$sent) < 1)
    {
#       ($ok, $sent, $received, $pending) = $saa->process(0.01);
        ($ok, $sent, $received, $pending) = $saa->process(10);
        $ok || die($saa->{'err'} . "\n");
    }
    if($wait)
    {
        while(scalar(@$received) < 1)
        {
#           ($ok, $sent, $received, $pending) = $saa->process(0.01);
            ($ok, $sent, $received, $pending) = $saa->process(10);
            $ok || die($saa->{'err'} . "\n");
        }
    }
    if ($received->[0]->{msg}->{result} ne 'ok') {
        print "$received->[0]->{msg}->{'result-text'}\n";
        return 0.5; ########################??????????????
    }
    return $received->[0]->{msg}->{score};
}

1;
