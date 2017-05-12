package XML::FeedWriter::Test::RSS20::Item;

use strict;
use warnings;
use Test::Classy::Base;
use XML::FeedWriter;
use DateTime;
use Encode;

__PACKAGE__->mk_classdata( 'xs' );

sub _channel_fixture {(
  version     => '2.0',
  title       => 'title',
  link        => 'http://example.com/',
  description => 'description',
)}

sub _test {
  my ($class, $items, $expected) = @_;

  my $writer = XML::FeedWriter->new( $class->_channel_fixture );

  eval { $writer->add_items( @{ $items || [] } ); };
  return $@ if $@;

  $writer->close;

  my $got = $class->xs->parse_string( $writer->as_string );
  my $exp = $class->xs->parse_string('<test>'.$expected.'</test>');

  is_deeply
    $got->{rss}{channel}{item} => $exp->{test}{item},
    $class->test_name;
}

sub initialize {
  my $class = shift;

  eval { require XML::Simple };
  return $class->skip_this_class('requires XML::Simple 2.17')
    if $@ or $XML::Simple::VERSION lt "2.17";

  $class->xs( XML::Simple->new( ForceArray => 0, KeepRoot => 1 ) );
}

sub item_pubdate_plain_epoch : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    pubDate => 1215423575,
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
</item>
EXPECTED
}

sub item_pubdate_epoch : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    pubDate => { epoch => 1215423575 },
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
</item>
EXPECTED
}

sub item_pubdate : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    pubDate => {
      year => 2008, month => 7, day => 7,
      hour => 9, minute => 39, second => 35,
    },
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
</item>
EXPECTED
}

sub item_pubdate_object : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    pubDate => DateTime->from_epoch( epoch => 1215423575 ),
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
</item>
EXPECTED
}

sub item_category_single : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    category => 'category',
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <category>category</category>
</item>
EXPECTED
}

sub item_category_multiple : Test {
  my $class = shift;

  my $arg = [qw( category1 category2 )];
  my @item = ({
    title => 'title',
    category => $arg,
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <category>category1</category>
  <category>category2</category>
</item>
EXPECTED
}

sub item_category_multiple_with_domain : Test {
  my $class = shift;

  my $arg = [ ['category1', domain => 'domain'], 'category2' ];
  my @item = ({
    title => 'title',
    category => $arg,
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <category domain="domain">category1</category>
  <category>category2</category>
</item>
EXPECTED
}

sub item_enclosure : Test {
  my $class = shift;

  my $arg = {
    length => 0,
    type => 'audio/mpeg',
    url  => 'http://example.com/sample.mp3',
  };
  my @item = ({
    title => 'title',
    enclosure => $arg,
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <enclosure length="0" type="audio/mpeg" url="http://example.com/sample.mp3" />
</item>
EXPECTED
}

sub item_enclosure_error : Test(3) {
  my $class = shift;

  my $arg = {
    length => 0,
    type => 'audio/mpeg',
    url  => 'http://example.com/sample.mp3',
  };
  foreach my $elem (qw( length type url )) {
    my %hash = %{ $arg };
    delete $hash{$elem};

    my @item = ({
      title => 'title',
      enclosure => \%hash,
    });

    my $error = $class->_test( \@item );
    ok $error =~ /is required/, $class->test_name . ": $elem";
  }
}

sub item_guid : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    guid  => 'http://example.com/permalink',
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <guid>http://example.com/permalink</guid>
</item>
EXPECTED
}

sub item_guid_is_permalink : Test {
  my $class = shift;

  my @item = ({
    title => 'title',
    guid  => [ 'not a permalink', isPermaLink => 'false' ]
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <guid isPermaLink="false">not a permalink</guid>
</item>
EXPECTED
}

sub item_source : Test {
  my $class = shift;

  my $arg = [
    'title',
    url  => 'http://example.com/sample.mp3',
  ];
  my @item = ({
    title => 'title',
    source => $arg,
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <title>title</title>
  <source url="http://example.com/sample.mp3">title</source>
</item>
EXPECTED
}

sub item_description : Test {
  my $class = shift;

  my @item = ({
    description => 'description',
  });

  $class->_test( \@item, <<'EXPECTED');
<item>
  <description><![CDATA[description]]></description>
</item>
EXPECTED
}

1;
