#Template for writing a classify PlugIn for Combine
#See documentation at http://combine.it.lth.se/documentation/

package classifyPlugInTemplate; #Change to your own module name

use Combine::XWI; #Mandatory
use Combine::Config; #Optional if you want to use the Combine configuration system

#API:
#  a subroutine named 'classify' taking a XWI-object as in parameter
#    return values: 0/1
#        0: record fails to meet the classification criteria, ie ignore this record
#        1: record is OK and should be stored in the database, and links followed by the crawler
sub classify { 
  my ($self,$xwi) = @_;

  #utility routines to extract information from the XWI-object
  #URL (can be several):
   # $xwi->url_rewind;
   # my $url_str="";
   # my $t;
   # while ($t = $xwi->url_get) { $url_str .= $t . ", "; }

  #Metadata:
   #  $xwi->meta_rewind;
   #  my ($name,$content);
   #  while (1) {
   #    ($name,$content) = $xwi->meta_get;
   #    last unless $name;
   #    next if ($name eq 'Rsummary');
   #    next if ($name =~ /^autoclass/);
   #    $meta .= $content . " ";
   #  } 

  #Title:
   #  $title = $xwi->title;

  #Headings:
   #  $xwi->heading_rewind;
   #  my $this;
   #  while (1) {
   #    $this = $xwi->heading_get or last; 
   #    $head .= $this . " "; 
   #  }

  #Text:
   #  $this = $xwi->text;
   #  if ($this) {
   #    $text = $$this;
   #  }

###############################
#Apply your classification algorithm here
#  assign $result a value (0/1)
###############################

  #utility routines for saving detailed results (optional) in the database. These data may appear
  # in exported XML-records

  #Topic takes 5 parameters
  # $xwi->topic_add(topic_class_notation, topic_absolute_score, topic_normalized_score, topic_terms, algorithm_id);
  #  topic_class_notation, topic_terms, and algorithm_id are strings
  #    max length topic_class_notation: 50, algorithm_id: 25
  #  topic_absolute_score, and topic_normalized_score are integers
  #  topic_normalized_score and topic_terms are optional and may be replaced with 0, '' respectively

  #Analysis takes 2 parameters
  # $xwi->robot_add(name,value);
  # both are strings with max length name: 15, value: 20

    # return true (1) if you want to keep the record
    # otherwise return false (0)

  return $result;
}

1;
