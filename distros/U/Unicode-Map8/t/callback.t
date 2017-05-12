
eval {require Unicode::CharName;};
if ($@) {
    print "1..0\n";
    exit;
}

print "1..2\n";

{
    package My;
    use Unicode::Map8;
    @ISA=qw(Unicode::Map8);

    sub unmapped_to16
    {
	my($self, $code) = @_;
	"ABCD";
    }

    sub unmapped_to8
    {
	my($self, $code) = @_;
	"<" . Unicode::CharName::uname($code) . ">";
    }

}

$m = My->new("no");

print "not " unless $m->to16("lær") eq "\0lABCD\0r";
print "ok 1\n";

#print $m->to8("\0a\0]\0b\0c\0}"), "\n";

print "not " unless $m->to8("\0a\0]\0b\0c\0}") eq "a<RIGHT SQUARE BRACKET>bc<RIGHT CURLY BRACKET>";
print "ok 2\n";

