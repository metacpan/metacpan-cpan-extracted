use strict;
use XML::Rules;

my $member;
my $parser = XML::Rules->new(
	stripspaces => 7,
	rules => {
		_default => 'content',
		mem => sub {
			print join( '|', ++$member, map {(my $s = $_[1]->{$_}) =~ s/\|//; $s} qw(member add1 add2 add3 suburb state pcode)), "\n";
			return;
		}
	},
);

$parser->parse(\*DATA);

__DATA__
<root>
   <mem>
     <member>member</member>
     <add1>add1</add1>
     <add2>add2</add2>
     <add3>add3</add3>
     <suburb>suburb</suburb>
     <state>state</state>
     <pcode>pcode</pcode>
   </mem>
   <mem>
     <member>other</member>
     <add1>ADD1</add1>
     <add2>ADD2</add2>
     <add3>ADD3</add3>
     <suburb>suburb 2</suburb>
     <state>state</state>
     <pcode>pcode</pcode>
   </mem>
</root>
