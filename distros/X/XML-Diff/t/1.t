# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 38;

use XML::LibXML;
use Algorithm::Diff qw(diff);

BEGIN { use_ok('XML::Diff') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $xml = {
           'update_text' => [
                              qq{
<a>
  <b>blah blah blah</b>
</a>
},
                              qq{
<a>
  <b>brah blah brah</b>
</a>
},
                             ],
           'update_text_add' => [
                                 qq{
<a>
  <b/>
  <c/>
</a>
},
                                 qq{
<a>
  <b>brah blah brah</b>
  <c/>
</a>
},
                                ],
           'update_text_remove' => [
                                    qq{
<a>
  <b>blah blah blah</b>
  <c/>
</a>
},
                                    qq{
<a>
  <b/>
  <c/>
</a>
},
                                   ],
           'update_text_chain' => [
                                   qq{
<a>
  a
  <b/>
  c
  <d/>
</a>
},
                                    qq{
<a>
  a
  <b/>
  x
  <d/>
</a>
},
                                   ],
              'update_text_chain2' => [
                                       qq{
<a>
  <a/>
  b
  <c/>
  d
</a>
},
                                       qq{
<a>
  <a/>
  b
  <c/>
  x
</a>
},
                                      ],
            'update_text_chain_mix' => [
                                        qq{
<a>
  <a/>
  b
  <c/>
  d
</a>
},
                                        qq{
<a>
  <a/>
  b
  <x/>
  f
  <c/>
  d
</a>
},
                                       ],
            'update_text_chain_add_start' => [
                                              qq{
<a>
  <a/>
  b
  <c/>
  d
</a>
},
                                              qq{
<a>
  a
  <a/>
  b
  <c/>
  d
</a>
},
                                             ],
            'update_text_chain_add_end' => [
                                            qq{
<a>a<a/>b<c/></a>
},
                                            qq{
<a>a<a/>b<c/>d</a>
},
                                           ],
            'update_attribute_add' => [
                                       qq{
<a>
  <b foo="bar">blah blah blah</b>
</a>
},
                                       qq{
<a>
  <b>blah blah blah</b>
</a>
},
                                      ],
            'update_attribute_delete' => [
                                          qq{
<a>
  <b>blah blah blah</b>
</a>
},
                                          qq{
<a>
  <b foo="bar">blah blah blah</b>
</a>
},
                                         ],
            'update_mixed' => [
                               qq{
<a>
  <b bar="foo" x="y">blah blah blah</b>
</a>
},
                               qq{
<a>
  <b foo="bar" x="z">blah brah blah</b>
</a>
},
                              ],
            'update_attribute_change' => [
                                          qq{
<a>
  <b foo="baz">blah blah blah</b>
</a>
},
                                          qq{
<a>
  <b foo="bar">blah blah blah</b>
</a>
},
                                         ],
            'add_at_end' => [
                             qq{
<a>
  <b/>
  <c/>
</a>
},
                             qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                             ],
            'add_at_start' => [
                               qq{
<a>
  <d/>
  <e/>
</a>
},
                               qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                              ],
            'add_in_the_middle' => [
                                    qq{
<a>
  <b/>
  <e/>
</a>
},
                                    qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                   ],
            'add_random' => [
                             qq{
<a>
  <c/>
  <e/>
</a>
},
                             qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                            ],
            'delete_at_end' => [
                                qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                qq{
<a>
  <b/>
  <c/>
</a>
},
                               ],
            'delete_at_start' => [
                                  qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                  qq{
<a>
  <d/>
  <e/>
</a>
},
                                 ],
            'delete_in_middle' => [
                                   qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                   qq{
<a>
  <a/>
  <e/>
</a>
},
                                  ],
            'delete_random' => [
                                qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                qq{
<a>
  <a/>
  <d/>
</a>
},
                               ],
            'add_delete' => [
                             qq{
<a>
  <c/>
  <d/>
  <e/>
</a>
},
                             qq{
<a>
  <b/>
  <c/>
  <d/>
</a>
},
                            ],
            'add_delete_random' => [
                                    qq{
<a>
  <b/>
  <d/>
  <e/>
</a>
},
                                    qq{
<a>
  <b/>
  <c/>
  <d/>
</a>
},
                                   ],
            'local_move_random' => [
                                    qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                    qq{
<a>
  <d/>
  <c/>
  <e/>
  <b/>
</a>
},
                                   ],
            'local_move_to_end_to_end' => [
                                           qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                           qq{
<a>
  <c/>
  <d/>
  <e/>
  <b/>
</a>
},
                                          ],
            'local_move_with_add' => [
                                      qq{
<a>
  <b/>
  <d/>
  <e/>
</a>
},
                                      qq{
<a>
  <c/>
  <d/>
  <e/>
  <b/>
</a>
},
                                     ],
            'local_move_with_delete' => [
                                         qq{
<a>
  <b/>
  <c/>
  <d/>
  <e/>
</a>
},
                                         qq{
<a>
  <c/>
  <e/>
  <b/>
</a>
},
                                        ],
            'tree_move_single_node' => [
                                        qq{
<a>
  <b/>
  <c/>
  <d>
    <x/>
  </d>
  <e/>
</a>
},
                                        qq{
<a>
  <b/>
  <c>
    <x/>
  </c>
  <d/>
  <e/>
</a>
},
                                       ],
            'tree_move_subtree' => [
                                    qq{
<a>
  <b/>
  <c/>
  <d>
    <x>
      <y/>
    </x>
    <z/>
  </d>
  <e/>
</a>
},
                                    qq{
<a>
  <b/>
  <c>
    <x>
      <y/>
    </x>
    <z/>
  </c>
  <d/>
  <e/>
</a>
},
                                   ],
            'tree_move_with_local_move' => [
                                            qq{
<a>
  <b/>
  <c/>
  <d>
    <x>
      <y/>
    </x>
    <z/>
  </d>
  <e/>
</a>
},
                                            qq{
<a>
  <b/>
  <d/>
  <c>
    <x>
      <y/>
    </x>
    <z/>
  </c>
  <e/>
</a>
},
                                           ],
            'tree_move_with_local_insert_and_delete' => [
                                            qq{
<a>
  <b/>
  <c/>
  <d>
    <x>
      <y/>
    </x>
    <z/>
  </d>
  <e/>
</a>
},
                                            qq{
<a>
  <b>
    <xy/>
  </b>
  <d/>
  <c>
    <x/>
    <z/>
  </c>
  <e/>
</a>
},
                                           ],
           'update_null_attribute' => [
                                       qq{
<a>
  <b zero="0" blank="">blah blah blah</b>
</a>
},
                                          qq{
<a>
  <b zero="0" blank="">blah blah blah</b>
</a>
},
                                         ],
           'update_randomized_attribute' => [
                                       qq{
<a>
  <b a="1" bb="2" ccc="3"/>
</a>
},
                                          qq{
<a>
  <b ccc="3" bb="2" a="1"/>
</a>
},
                                         ],
          };

my $test_file1 = 't/xml/test1.xml';
my $test_file2 = 't/xml/test2.xml';
# this excercises the different methods and input formats
instantiate();
load_file($test_file1);
load_string($test_file1);
load_libxml_doc($test_file1);
load_libxml_element($test_file1);

# this tests that our Diff and Patch work
test_xml( 'update_text' );
test_xml( 'update_text_add' );
test_xml( 'update_text_remove' );
test_xml( 'update_text_chain' );
test_xml( 'update_text_chain2' );
test_xml( 'update_text_chain_mix' );
test_xml( 'update_text_chain_add_start' );
test_xml( 'update_text_chain_add_end' );
test_xml( 'update_attribute_add' );
test_xml( 'update_attribute_delete' );
test_xml( 'update_attribute_change' );
test_xml( 'update_mixed' );
test_xml( 'add_at_end' );
test_xml( 'add_at_start' );
test_xml( 'add_in_the_middle' );
test_xml( 'add_random' );
test_xml( 'delete_at_end' );
test_xml( 'delete_at_start' );
test_xml( 'delete_in_middle' );
test_xml( 'delete_random' );
test_xml( 'add_delete' );
test_xml( 'add_delete_random' );
test_xml( 'local_move_random' );
test_xml( 'local_move_to_end_to_end' );
test_xml( 'local_move_with_add' );
test_xml( 'local_move_with_delete' );
test_xml( 'tree_move_single_node' );
test_xml( 'tree_move_subtree' );
test_xml( 'tree_move_with_local_move' );
test_xml( 'tree_move_with_local_insert_and_delete' );
test_xml_no_change( 'update_null_attribute' );
test_xml_no_change( 'update_randomized_attribute' );

exit;

sub instantiate {
  my $diff = XML::Diff->new();
  ok( defined $diff,'instatiated XML::Diff' );
}

sub load_file {
  my $test_file = shift;
  my $diff = XML::Diff->new();
  my $success;
  if( !-e $test_file ) {
    diag( "test file '$test_file' does not exist" );
  } elsif( defined $diff->_getDoc('old',$test_file) ) {
    $success = 1;
  }
  ok( $success, "load XML from file" );
}

sub load_string {
  my $test_file = shift;
  my $diff = XML::Diff->new();
  my $success;
  if( !-e $test_file ) {
    diag( "test file '$test_file' does not exist" );
  } else {
    open( FH, $test_file );
    my @test_string = <FH>;
    my $test_string = join('',@test_string);
    close FH;
    if( defined $diff->_getDoc('old',$test_string) ) {
      $success = 1;
    }
  }
  ok( $success, "load XML from string" );
}

sub load_libxml_doc {
  my $test_file = shift;
  my $diff = XML::Diff->new();
  my $success;
  if( !-e $test_file ) {
    diag( "test file '$test_file' does not exist" );
  } else {
    my $parser = XML::LibXML->new();
    if( !$parser ) {
      diag( "unable to create LibXML parser" );
    } else {
      $parser->keep_blanks(0);
      my $doc    = $parser->parse_file( $test_file );
      if( !$doc ) {
        diag( "unable to parse file '$test_file' with libXML" );
      } elsif( defined $diff->_getDoc('old',$doc) ) {
        $success = 1;
      }
    }
  }
  ok( $success, "load XML from XML::LibXML Document" );
}

sub load_libxml_element {
  my $test_file = shift;
  my $diff = XML::Diff->new();
  my $success;
  if( !-e $test_file ) {
    diag( "test file '$test_file' does not exist" );
  } else {
    my $parser = XML::LibXML->new();
    if( !$parser ) {
      diag( "unable to create LibXML parser" );
    } else {
      $parser->keep_blanks(0);
      my $doc    = $parser->parse_file( $test_file );
      if( !$doc ) {
        diag( "unable to parse file '$test_file' with libXML" );
      } else {
        my $root = $doc->documentElement();
        if( !$root ) {
          diag( "unable to get root element from XML::LibXML::Document" );
        } elsif( defined $diff->_getDoc('old',$root) ) {
          $success = 1;
        }
      }
    }
  }
  ok( $success, "load XML from XML::LibXML Element" );
}


sub test_xml {
  my $test_name = shift;
  my($old,$new) = @{$xml->{$test_name}};
  my $diff      = XML::Diff->new();
  my $diffgram  = $diff->compare(
                                 -old => $old,
                                 -new => $new,
                                );
  my $patched   = $diff->patch(
                               -old      => $old,
                               -diffgram => $diffgram,
                              );
  my $parser    = XML::LibXML->new();
  $parser->keep_blanks(0);
  # we force our XML through the parser so we know the differences aren't due
  # to formatting issues
  my $doc_old = $parser->parse_string( $old );
  my $doc_new = $parser->parse_string( $new );
  # we sort our attributes so that a text domain diff doesn't mistake
  # attribute mis-ordering for actual differences
  sort_attributes( $doc_old );
  sort_attributes( $doc_new );
  sort_attributes( $patched );
  my @target  = split(/\n/,$doc_new->toString(1));
  my @patched = split(/\n/,$patched->toString(1));
  my @diffs = diff( \@target, \@patched );

  my $success;
  if( ! @diffs ) {
    $success = 1;
  }
  ok( $success, "testing diff case '$test_name'" );
}

sub test_xml_no_change {
  my $test_name = shift;
  my($old,$new) = @{$xml->{$test_name}};
  my $diff      = XML::Diff->new();
  my $diffgram  = $diff->compare(
                                 -old      => $old,
                                 -new      => $new,
                                );
  my $root = $diffgram->documentElement();
  #print $root->toString(1),"\n";
  my $success;
  if( ! $root->hasChildNodes() ) {
    $success = 1;
  }
  ok( $success, "testing null diff case '$test_name'" );
}

sub sort_attributes {
  my $doc = shift;
  my $root = $doc->documentElement();
  dig_sort($root);
}

sub dig_sort {
  my $node = shift;
  if( $node->nodeType == 3 ) {
    return;
  } else {
    foreach my $child ( $node->childNodes() ) {
      dig_sort( $child );
    }
    my @attributes = $node->attributes();
    foreach (@attributes) {
      $node->removeAttribute( $_->nodeName );
    }
    foreach ( sort {$a->nodeName cmp $b->nodeName} @attributes ) {
      $node->setAttribute( $_->nodeName, $_->value );
    }
  }
}
