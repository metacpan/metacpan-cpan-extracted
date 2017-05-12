use strict;
use XML::Rules;

my $xml = <<'*END*';
<doc>
 <book>
  <name>Valka s mloky</name>
  <author>Karel Capek</author>
  <description>It's really <b>something</b> and I have to <u>underline it</u>.</description>
 </book>
 <book>
  <name>Predtucha</name>
  <author>Pujmanova</author>
  <description>It's really a <u>stupid</u> pointless book.
Confront <link id="12345">this one</link>. And don't read this one please!
  </description>
 </book>
</doc>
*END*

my $parser = new XML::Rules (
	rules => [
		_default => 'content',
		u => sub {my $str = $_[1]->{_content}; $str =~ tr/ /_/; return '_'.$str.'_'},
		b => sub {my $str = $_[1]->{_content}; return '*'.$str.'*'},
		link => sub { qq{<a href="http://www.books.com/find_book.pl?id=$_[1]->{id}">$_->{_content}</a>} },
		book => sub {
			my $desc = $_[1]->{description};
			$desc =~ s/\n/\n\t/g;
			print "Book: $_[1]->{name}\nAuthor: $_[1]->{author}\nDescription: $desc\n\n";
		},
	],
);

$parser->parsestring($xml);

