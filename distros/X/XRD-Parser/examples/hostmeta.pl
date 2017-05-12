use XRD::Parser;

my $parser = XRD::Parser->hostmeta('gmail.com');
$parser->consume;
my $data = $parser->graph->as_stream;
while (my $st = $data->next)
{
	print $st->as_string . "\n";
}
