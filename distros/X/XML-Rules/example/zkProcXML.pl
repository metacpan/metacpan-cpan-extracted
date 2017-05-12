use XML::Rules;
my $parser = XML::Rules->new(
	rules => {
#		process => sub { $_[1]->{name} => 1},
		process => sub { '@list' => $_[1]->{name}},
		_default => sub { $_[0] => $_[1]->{list}},
		config => 'pass no content',
	}
);
my $data = $parser->parse(\*DATA);

foreach my $host (sort keys %$data) {
	foreach my $proc (@{$data->{$host}}) {
		print "$host runs $proc\n";
	}
}

#use Data::Dumper;
#print Dumper($data);

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<config>

   <host1>
      <process name="proc1" />
      <process name="proc2" />
      <process name="proc3" />
      <process name="proc4" />
   </host1>

   <host2>
      <process name="proc5" />
      <process name="proc6" />
      <process name="proc7" />
      <process name="proc8" />
   </host2>

</config>
