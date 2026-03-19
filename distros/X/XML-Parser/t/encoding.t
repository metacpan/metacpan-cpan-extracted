BEGIN { print "1..14\n"; }
END { print "not ok 1\n" unless $loaded; }
use XML::Parser;
$loaded = 1;
print "ok 1\n";

################################################################
# Check encoding

my $xmldec = "<?xml version='1.0' encoding='x-sjis-unicode' ?>\n";

my $docstring = <<"End_of_doc;";
<\x8e\x83>\x90\x46\x81\x41\x98\x61\x81\x41\x99\x44
</\x8e\x83>
End_of_doc;

my $doc = $xmldec . $docstring;

my @bytes;
my $lastel;

sub text {
    my ( $xp, $data ) = @_;

    push( @bytes, unpack( 'U0C*', $data ) );    # was fixed 5.10
}

sub start {
    my ( $xp, $el ) = @_;

    $lastel = $el;
}

my $p = XML::Parser->new( Handlers => { Start => \&start, Char => \&text } );

$p->parse($doc);

my $exptag = ( $] < 5.006 )
  ? "\xe7\xa5\x89"    # U+7949 blessings 0x8e83
  : chr(0x7949);

my @expected = (
    0xe8, 0x89, 0xb2,    # U+8272 beauty    0x9046
    0xe3, 0x80, 0x81,    # U+3001 comma     0x8141
    0xe5, 0x92, 0x8c,    # U+548C peace     0x9861
    0xe3, 0x80, 0x81,    # U+3001 comma     0x8141
    0xe5, 0x83, 0x96,    # U+50D6 joy       0x9944
    0x0a
);

if ( $lastel eq $exptag ) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}

if ( @bytes != @expected ) {
    print "not ok 3\n";
}
else {
    my $i;
    for ( $i = 0; $i < @expected; $i++ ) {
        if ( $bytes[$i] != $expected[$i] ) {
            print "not ok 3\n";
            exit;
        }
    }
    print "ok 3\n";
}

$lastel = '';

$p->parse( $docstring, ProtocolEncoding => 'X-SJIS-UNICODE' );

if ( $lastel eq $exptag ) {
    print "ok 4\n";
}
else {
    print "not ok 4\n";
}

# Test the CP-1252 Win-Latin-1 mapping

$docstring = qq(<?xml version='1.0' encoding='WINDOWS-1252' ?>
<doc euro="\x80" lsq="\x91" rdq="\x94" />
);

my %attr;

sub get_attr {
    my ( $xp, $el, @list ) = @_;
    %attr = @list;
}

$p = XML::Parser->new( Handlers => { Start => \&get_attr } );

eval { $p->parse($docstring) };

if ($@) {
    print "not ";    # couldn't load the map
}
print "ok 5\n";

if (   $attr{euro} ne ( $] < 5.006 ? "\xE2\x82\xAC" : chr(0x20AC) )
    or $attr{lsq} ne ( $] < 5.006 ? "\xE2\x80\x98" : chr(0x2018) )
    or $attr{rdq} ne ( $] < 5.006 ? "\xE2\x80\x9D" : chr(0x201D) ) ) {
    print "not ";
}
print "ok 6\n";

# Test windows-1251 (Cyrillic)
# 0xC0 = U+0410 (А), 0xE0 = U+0430 (а), 0xC1 = U+0411 (Б)

$docstring = qq(<?xml version='1.0' encoding='windows-1251' ?>
<doc a="\xC0" b="\xE0" c="\xC1" />
);

%attr = ();
$p = XML::Parser->new( Handlers => { Start => \&get_attr } );
eval { $p->parse($docstring) };

if ($@) {
    print "not ";    # couldn't load the map
}
print "ok 7\n";

if (   $attr{a} ne chr(0x0410)
    or $attr{b} ne chr(0x0430)
    or $attr{c} ne chr(0x0411) ) {
    print "not ";
}
print "ok 8\n";

# Test koi8-r (Cyrillic)
# 0xC1 = U+0430 (а), 0xE1 = U+0410 (А), 0xC2 = U+0431 (б)

$docstring = qq(<?xml version='1.0' encoding='koi8-r' ?>
<doc a="\xC1" b="\xE1" c="\xC2" />
);

%attr = ();
$p = XML::Parser->new( Handlers => { Start => \&get_attr } );
eval { $p->parse($docstring) };

if ($@) {
    print "not ";    # couldn't load the map
}
print "ok 9\n";

if (   $attr{a} ne chr(0x0430)
    or $attr{b} ne chr(0x0410)
    or $attr{c} ne chr(0x0431) ) {
    print "not ";
}
print "ok 10\n";

# Test windows-1255 (Hebrew)
# 0xE0 = U+05D0 (alef), 0xE1 = U+05D1 (bet), 0xE2 = U+05D2 (gimel)

$docstring = qq(<?xml version='1.0' encoding='windows-1255' ?>
<doc a="\xE0" b="\xE1" c="\xE2" />
);

%attr = ();
$p = XML::Parser->new( Handlers => { Start => \&get_attr } );
eval { $p->parse($docstring) };

if ($@) {
    print "not ";    # couldn't load the map
}
print "ok 11\n";

if (   $attr{a} ne chr(0x05D0)
    or $attr{b} ne chr(0x05D1)
    or $attr{c} ne chr(0x05D2) ) {
    print "not ";
}
print "ok 12\n";

# Test ibm866 (DOS Cyrillic)
# 0x80 = U+0410 (А), 0x81 = U+0411 (Б), 0xA0 = U+0430 (а)

$docstring = qq(<?xml version='1.0' encoding='ibm866' ?>
<doc a="\x80" b="\x81" c="\xA0" />
);

%attr = ();
$p = XML::Parser->new( Handlers => { Start => \&get_attr } );
eval { $p->parse($docstring) };

if ($@) {
    print "not ";    # couldn't load the map
}
print "ok 13\n";

if (   $attr{a} ne chr(0x0410)
    or $attr{b} ne chr(0x0411)
    or $attr{c} ne chr(0x0430) ) {
    print "not ";
}
print "ok 14\n";

