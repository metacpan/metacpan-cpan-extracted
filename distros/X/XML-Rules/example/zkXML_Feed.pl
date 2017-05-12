use XML::Rules;

my $parser = XML::Rules->new(
  stripspaces => 7,
  rules => {
    _default => '',
    'Header,Content' => 'content',
    'Article' => 'as array no content',
    'Feed' => 'pass',
  }
);

my $data = $parser->parse(\*DATA);
use Data::Dumper;
print Dumper($data);

__DATA__
<Feed>
 <Article>
  <Header>Hello world</Header>
  <Content>Blah blah blah blah.</Content>
  <Bogus>.dfgd fgs dfg qwet sdfg dfgh</Bogus>
 </Article>
 <Article>
  <Header>The end</Header>
  <Content>Tjadydadyda.</Content>
  <Other>.dfgd fgs dfg qwet sdfg dfgh</Other>
 </Article>
</Feed>
