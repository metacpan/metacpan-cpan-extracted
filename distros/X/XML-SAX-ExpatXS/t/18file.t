use Test;
BEGIN { plan tests => 2 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

$parser->parse_uri('t/file.xml');

#warn "$handler->{start}:$handler->{end}";
ok($handler->{start}, 72);
ok($handler->{end}, 72);

package TestH;
#use Devel::Peek;

sub new { bless {start => 0, end => 0}, shift }


sub start_element {
    my ($self, $el) = @_;
    #warn("Start:$el->{Name}\n");
    #Dump($el);
    $self->{start}++;
}

sub end_element {
    my ($self, $el) = @_;
    #warn("End:$el->{Name}\n");
    #Dump($el);
    $self->{end}++;
}

