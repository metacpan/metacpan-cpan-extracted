use Modern::Perl;
use threads::lite qw/spawn self receive/;
use SmartMatch::Sugar;

sub child {
	require threads::lite;
	my $other = threads::lite::receiveq();
	say "Other is $other";
	while (<>) {
		chomp;
		say "read $_";
		$other->send(line => $_);
	}
}

my $self = self;
my $child = spawn({ monitor => 1 } , \&child);
$child->send($self);

say "Trying";
my $continue = 1;
while ($continue) {
	receive {
		say "Got @{$_}";
		when([ 'line', any ]) {
			my (undef, $line) = @{$_};
			say "received line: $line";
		}
		when([ 'exit', any, $child->id ]) {
			say "received end of file";
			$continue = 0;
		}
		default {
			die sprintf "Got unknown message: (%s)", join ", ", @_;
		}
	};
}
