use Test;
BEGIN {
  plan tests => 24;
}

use dTemplate;

ok(1);

$t = text dTemplate '<html>$BODY$</html>';

ok(1);

# Testing a simple compile output

$t->compile;

my $test_compiled =
  # variables:
  pack("L",1)." BODY \0".pack("L",0)."\0".
  # first chunk (text)
  pack("L",6).'<html>'.
  # first chunk (variable)
  '$BODY$'."\0".pack("L",0)."BODY\0\0\0\0".
  # second chunk (text)
  pack("L",7).'</html>'.
  # template end
  "\0";

ok $t->[dTemplate::Template::COMPILED], $test_compiled;

#open FILE,">test.out";
#print FILE $t->[dTemplate::Template::compiled];
#close FILE;
#open FILE,">test.out.exp";
#print FILE $test_compiled;
#close FILE;

$a = $t->parse( dummy => "123", BODY => "1111", dummm => "456");

ok($a, "<html>1111</html>");

$dTemplate::parse{BODY} = "Géza";

$b = $t->parse(fff => "333");

ok($b, "<html>Géza</html>");

$c = $t->parse( { BODY => "Abcdef", Bodrog => "Ahhh" });

ok($c, "<html>Abcdef</html>");

$t = text dTemplate '<html>$name******lc$<br>$code*uc$</html>';

$t->compile;

$dTemplate::parse{""} = sub { return shift; };

$a = $t->parse( name => "dLux" );

ok($a, '<html>dlux<br>$code*uc$</html>');

$b = $t->parse( name => "dLuxx", code => "dlx" );

ok($b, '<html>dluxx<br>DLX</html>');

$dTemplate::ENCODERS{reverse} = sub {
    join("", reverse split( //,$_[0]));
};

$dTemplate::ENCODERS{check_equal} = sub { my ($variable, $param) = @_;
    return $variable eq $param ? "true" : "false";
};

$t = text dTemplate 'Encodertest: $test*uc*reverse$';

$a = $t->parse( test => "Roxette" );

ok($a, 'Encodertest: ETTEXOR');

$t = text dTemplate 'Sprintftest: $data%05s*uc$';

$a = $t->parse( data => "hu" );

ok($a, 'Sprintftest: 000HU');

$t = text dTemplate 'Printf encoder test: $data*uc*printf/05s$';

$a = $t->parse( data => "uk" );

ok($a, 'Printf encoder test: 000UK');

$t = text dTemplate 'Hash test: $hash.key1*uc$ - $hash.key2.key3$';

$a = $t->parse( hash => { key1 => "bela", key2 => { key3 => "whooa" }});

ok($a, 'Hash test: BELA - whooa');

# test if magical hashes are working

use Tie::Hash;
tie %tied_hash, 'Tie::StdHash';

$tied_hash{key3} = "working!";

$x = bless ({ key1 => "tied hashes are", key2 => \%tied_hash }, "main" );

$b = $t->parse(hash => $x);

ok($b, 'Hash test: TIED HASHES ARE - working!');

$tied_hash{hash} = { key1 => "next test", key2 => { key3 => "ok" } };

$c = $t->parse( \%tied_hash );

ok($c, 'Hash test: NEXT TEST - ok');

# changing template placeholder special character

{
    local $dTemplate::START_DELIMITER     =  '<%\s*';
    local $dTemplate::VAR_PATH_SEP        =  '\/';
    local $dTemplate::ENCODER_PARAM_START = '\(';
    local $dTemplate::ENCODER_PARAM_END   = '\)';
    local $dTemplate::END_DELIMITER       =  '\s*%>';
    local $dTemplate::PRINTF_SEP          =  '\s*%%\s*';
    local $dTemplate::ENCODER_SEP         =  '\s*@\s*';
    $t3 = text dTemplate 'new template vars:<% text1/wow %% 6s @ lc %> Whoa! '.
        '<% text1/test @ check_equal(TEST!) %>';
    $t3->compile;
}

$a = $t3->parse(
    text1 => { wow => "WHO", test => "TEST!" },
);

ok($a,'new template vars:   who Whoa! true');

# recursion in template

$t = text dTemplate 'This is the frame of the internal template BEGIN ( $VAL$ ) END';

$t2 = text dTemplate 'internal data: $number$';

$a = $t->parse(
    VAL => sub {
        $t2->parse( number => 156 );
    }
);

ok($a,'This is the frame of the internal template BEGIN ( internal data: 156 ) END');

$dTemplate::NOTASSIGNED_MODE=0;

# testing parse{''}

$t = dTemplate->new( text => 'Test for dTemplate::parse{""}: $text.text2.text3*uc$' );
$dTemplate::parse{""} = sub {
    my ($variable) = $_[0] =~ /^\$(.*?)(?:\*|$)/;
    my @varpath = @{ $_[1] };
    return "test_$variable-".join(",",@varpath);
};

$a = $t->parse();

ok ($a, 'Test for dTemplate::parse{""}: test_text.text2.text3-text,text2,text3');

$dTemplate::NOTASSIGNED_MODE=1;

$a = $t->parse();

ok ($a, 'Test for dTemplate::parse{""}: TEST_TEXT.TEXT2.TEXT3-TEXT,TEXT2,TEXT3');

delete $dTemplate::parse{""};
$dTemplate::NOTASSIGNED_MODE=undef;

# testing sub-ref: 

$t = dTemplate->new( text => 'Test for sub-in-hash: $text.text2.text3*lc$' );

$a = $t->parse(
    text => {
        text2 => sub {
            return "Hello ".join(" ",@{$_[1]})."!";
        }
    }
);

ok ($a, 'Test for sub-in-hash: hello text text2 text3!');

# test by Dennis Boylan
my $t = dTemplate->new( text => 'TEST5 $Y*eq/5*if/OK$');

$dTemplate::parse{""} = sub {
    my ($param, $short, $self) = @_;
    if ($self != $t) { # third parameter is "self"
        return "BAD";
    }
    if ($short->[0] eq "Y") {
        return 5;
    }
    return "";
};

$dTemplate::NOTASSIGNED_MODE = 1;

$a = $t->parse( X=>1, X5=> 2);

ok ($a, "TEST5 OK");

$dTemplate::NOTASSIGNED_MODE = 0;

# Local parsehash test (1)

my $t = new dTemplate(text => 'VARPRE $VARIABLE*uc$ VARPOST');

$dTemplate::parse{VARIABLE} = "global parsing";
$t->parsehash->{VARIABLE} = "local parsing";

$a = $t->parse();

ok ($a, "VARPRE LOCAL PARSING VARPOST");

# Local parsehash test (2)

# $t is from the previous test

$dTemplate::parse{VARIABLE} = "global parsing";
delete $t->parsehash->{VARIABLE};

$a = $t->parse();

ok ($a, "VARPRE GLOBAL PARSING VARPOST");

# Local parsehash test (3)

# $t is from the previous test

$dTemplate::parse{VARIABLE} = "global parsing";
$t->parsehash->{VARIABLE} = undef;

$a = $t->parse();

ok ($a, "VARPRE  VARPOST");

# Local parsehash test (4)

# $t is from the previous test

$dTemplate::parse{VARIABLE} = "global parsing";
$t->parsehash->{VARIABLE} = sub { "local sub parsing" };
$t->parsehash->{VAR2} = "glagla";
$t->parsehash->{VAR4} = "glagla";
$t->parsehash->{VAR7} = "glagla";

$a = $t->parse();

ok ($a, "VARPRE LOCAL SUB PARSING VARPOST");

# Local parsehash "" test (1)

my $t = new dTemplate(text => 'VARPRE $VARIABLE*uc$ VARPOST');

delete $dTemplate::parse{VARIABLE};
$t->parsehash = { 
    "" => sub { "local fallback parsing" },
    VAR2 => "glaglagla",
    VAR3 => "glaglagla",
    VAR7 => "glaglagla",
};

{
    local $dTemplate::NOTASSIGNED_MODE = 1;
    $a = $t->parse();
}


ok ($a, "VARPRE LOCAL FALLBACK PARSING VARPOST");


