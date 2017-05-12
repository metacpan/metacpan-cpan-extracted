#! perl

use B::Generate;
use Inline C => <<"END";
int padinfo ( SV* padsv ) {
	AV* pad		= SvRV(padsv);
	fprintf( stderr, "pad %p\\n", pad );
	fprintf( stderr, "pad length %d\\n", av_len(pad) );
	return 0;
}
END
use optimizer callback => sub {
	my $op	= shift;
	if ($op->name eq 'gv') {	# this is fairly arbitrary to this test-case
		my $cv	= B::svref_2object( \&main::foo );
		my $pad	= ($cv->PADLIST->ARRAY)[1];
		print "***\t$pad\n";
		foreach my $attr (qw(FILL MAX OFF ARRAY AvFLAGS)) {
			print "\t$attr\t: " . join(', ', $pad->$attr()) . "\n";
		}
		padinfo( $pad );
	}
};

foo();
sub foo {
	my $a	= 5;
	print "hello\n";
}

