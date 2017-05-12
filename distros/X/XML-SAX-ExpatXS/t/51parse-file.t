use Test;
BEGIN { plan tests => 2 }
use XML::SAX::ExpatXS;
use IO::File;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $file = IO::File->new('t/file.xml');

$parser->parse_file($file);

#warn "$handler->{start}:$handler->{end}";
ok($handler->{start}, 72);
ok($handler->{end}, 72);

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

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
