use strict;

use Test::More tests => 7;

use_ok "URI::Find::Schemeless::Stricter";

my @uris;
my $self = URI::Find::Schemeless::Stricter->new(
	sub { 
		push @uris, $_[0]->as_string; 
		return $_[1] 
	}
);
isa_ok $self, "URI::Find::Schemeless::Stricter";
isa_ok $self, "URI::Find";

my %tests = (
	"We have www.foo.com"  => ["http://www.foo.com/"],
	"And also blah.foo.com" => [],
	"At 10.1.2.1/"    => ["http://10.1.2.1/"],
	"or 10.1.2.1"     => [],
);

for my $t (keys %tests) {
	@uris = ();
	$self->find(\$t);
	is_deeply(\@uris, $tests{$t}, $t);
}
