use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

$parser->parse_uri('t/file2.xml');

#warn "$handler->{start}:$handler->{end}";
ok($handler->{start} == 26 and $handler->{end} == 26);

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

sub characters {
    my ($self, $char) = @_;
    #warn("Char:$char->{Data}\n");
    #Dump($el);
}
