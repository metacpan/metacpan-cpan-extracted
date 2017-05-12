package XML::FeedWriter::Test::RSS20::Channel;

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
  my ($class, $elem, $arg, $expected) = @_;

  my $writer;
  eval { $writer = XML::FeedWriter->new( $class->_channel_fixture,
    $elem => $arg,
  )};
  return $@ if $@;
  $writer->close;

  my $got = $class->xs->parse_string( $writer->as_string );
  my $exp = $class->xs->parse_string('<test>'.$expected.'</test>');

  is_deeply
    $got->{rss}{channel}{$elem} => $exp->{test}{$elem}, $class->test_name;
}

sub initialize {
  my $class = shift;

  eval { require XML::Simple };
  return $class->skip_this_class('requires XML::Simple 2.17')
    if $@ or $XML::Simple::VERSION lt "2.17";

  $class->xs( XML::Simple->new( ForceArray => 0, KeepRoot => 1 ) );
}

sub basic : Test(5) {
  my $class = shift;

  my $writer = XML::FeedWriter->new( $class->_channel_fixture() );

  isa_ok $writer => 'XML::FeedWriter::RSS20';

  $writer->close;

  my $string = $writer->as_string;

  # should not be a scalar (or blessed) reference
  ok $string && !ref $string, 'has some output';

  my $file = 't/test.xml';
  unlink $file if -f $file;

  ok !-f $file, "make sure there's no file of the name";
  $writer->save($file);
  ok -f $file, 'now we have the file';

  local $/;
  open my $fh, '<', $file;
  my $saved = <$fh>;
  close $fh;

  is decode_utf8( $saved ) => $string, 'and content looks fine';

  unlink $file;
}

sub channel_error : Test(3) {
  my $class = shift;

  foreach my $elem (qw( link title description )) {
    my $error = $class->_test( $elem => undef );
    ok $error =~ /is required/, $class->test_name . ": $elem";
  }
}

sub channel_pubdate_plain_epoch : Test {
  my $class = shift;

  $class->_test( pubDate => 1215423575, <<'EXPECTED');
<pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
EXPECTED
}

sub channel_pubdate_epoch : Test {
  my $class = shift;

  $class->_test( pubDate => { epoch => 1215423575 }, <<'EXPECTED');
<pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
EXPECTED
}

sub channel_pubdate : Test {
  my $class = shift;

  my $arg = {
    year => 2008, month => 7, day => 7,
    hour => 9, minute => 39, second => 35,
  };
  $class->_test( pubDate => $arg, <<'EXPECTED');
<pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
EXPECTED
}

sub channel_pubdate_object : Test {
  my $class = shift;

  my $dt = DateTime->from_epoch( epoch => 1215423575 );
  $class->_test( pubDate => $dt, <<'EXPECTED');
<pubDate>Mon, 07 Jul 2008 09:39:35 -0000</pubDate>
EXPECTED
}

sub channel_category_single : Test {
  my $class = shift;

  $class->_test( category => 'category', <<'EXPECTED');
<category>category</category>
EXPECTED
}

sub channel_category_multiple : Test {
  my $class = shift;

  my $arg = [qw( category1 category2 )];
  $class->_test( category => $arg, <<'EXPECTED');
<category>category1</category>
<category>category2</category>
EXPECTED
}

sub channel_category_multiple_with_domain : Test {
  my $class = shift;

  my $arg = [ ['category1', domain => 'domain'], 'category2' ];
  $class->_test( category => $arg, <<'EXPECTED');
<category domain="domain">category1</category>
<category>category2</category>
EXPECTED
}

sub channel_cloud : Test {
  my $class = shift;

  my $arg = {
    domain => 'example.com',
    path => '/rpc',
    port => '80',
    protocol => 'xml-rpc',
    registerProcedure => 'cloud.notify',
  };

  $class->_test( cloud => $arg, <<'EXPECTED');
<cloud domain="example.com" path="/rpc" port="80" protocol="xml-rpc" registerProcedure="cloud.notify" />
EXPECTED
}

sub channel_image : Test {
  my $class = shift;

  my $arg = {
    link => 'http://example.com/',
    title => 'title',
    url => 'http://example.com/image.gif',
    description => 'image description',
    height => 32,
    width => 96,
  };

  $class->_test( image => $arg, <<'EXPECTED');
<image>
 <link>http://example.com/</link>
 <title>title</title>
 <url>http://example.com/image.gif</url>
 <description>image description</description>
 <height>32</height>
 <width>96</width>
</image>
EXPECTED
}

sub channel_image_error : Test(3) {
  my $class = shift;

  my $arg = {
    link => 'http://example.com/',
    title => 'title',
    url => 'http://example.com/image.gif',
  };

  foreach my $elem (qw( link title url )) {
    my %hash = %{ $arg };
    delete $hash{$elem};
    my $error = $class->_test( image => \%hash );
    ok $error =~ /is required/, $class->test_name . ": $elem";
  }
}

sub channel_skipdays : Test {
  my $class = shift;

  my $arg = [qw( Saturday Sunday )];

  $class->_test( skipDays => $arg, <<'EXPECTED');
<skipDays>
  <day>Saturday</day>
  <day>Sunday</day>
</skipDays>
EXPECTED
}

sub channel_skiphours : Test {
  my $class = shift;

  my $arg = [qw( 1 2 3 )];

  $class->_test( skipHours => $arg, <<'EXPECTED');
<skipHours>
  <hour>1</hour>
  <hour>2</hour>
  <hour>3</hour>
</skipHours>
EXPECTED
}

sub channel_textinput : Test {
  my $class = shift;

  my $arg = {
    link => 'http://example.com/textinput',
    title => 'title',
    name => 'query',
    description => 'image description',
  };

  $class->_test( textinput => $arg, <<'EXPECTED');
<textinput>
 <link>http://example.com/textinput</link>
 <title>title</title>
 <name>query</name>
 <description>image description</description>
</textinput>
EXPECTED
}

sub channel_textinput_error : Test(4) {
  my $class = shift;

  my $arg = {
    link => 'http://example.com/textinput',
    title => 'title',
    name => 'query',
    description => 'image description',
  };

  foreach my $elem (qw( link title name description )) {
    my %hash = %{ $arg };
    delete $hash{$elem};
    my $error = $class->_test( textinput => \%hash );
    ok $error =~ /is required/, $class->test_name . ": $elem";
  }
}

1;
