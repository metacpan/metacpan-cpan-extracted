use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;
use Text::Amuse::Functions qw/muse_format_line
                              muse_fast_scan_header/;
use File::Temp;


plan tests => 22;

is(muse_format_line(html => q{<em>ciao</em>bella<script">}),
   "<em>ciao</em>bella&lt;script&quot;&gt;");
is(muse_format_line(ltx => "<em>ciao</em>bella</script>"),
   q{\emph{ciao}bella<\Slash{}script>});

is(muse_format_line(html => "[1] hello [1] [2]"), "[1] hello [1] [2]");
is(muse_format_line(ltx => "[1] hello [1] [2]"), "[1] hello [1] [2]");

is(muse_format_line(html => "*(hello)* **«hello»**"), "<em>(hello)</em> <strong>«hello»</strong>");
is(muse_format_line(ltx => "*(hello)* **«hello»**"), "\\emph{(hello)} \\textbf{«hello»}");

is(muse_format_line(html => "* ***hello***"),
   "* <strong><em>hello</em></strong>");
is(muse_format_line(ltx => "* ***hello***"),
   '* \textbf{\emph{hello}}');


is(muse_format_line(html => "[1] [[http://pippo.org][mylink]]"),
   q{[1] <a class="text-amuse-link" href="http://pippo.org">mylink</a>});
is(muse_format_line(ltx => "[1] [[http://pippo.org][mylink]]"),
  q([1] \href{http://pippo.org}{mylink}));


my $body  =<<'BODY';
#author Pippo ć đ Đ à
#title Ciao ć đ Đ à is a long title
#random Random

Here the body starts


BODY

my $expected = {
             random => 'Random',
             title => "Ciao \x{107} \x{111} \x{110} \x{e0} is a long title",
             author => "Pippo \x{107} \x{111} \x{110} \x{e0}",
            };

test_directive($body, $expected);


$body =<<'BODY';
#author Pippo ć đ Đ à

#title Ciao ć đ Đ à
is a long title
#random Random

here the body start ć đ Đ à
BODY

diag "Testing line breaks";
test_directive($body, $expected);

$body =<<'BODY';
#author     Pippo          
ć
đ
Đ
à

#title    Ciao ć đ Đ à           
          is a long title             

#random        Random                 

here the body start ć đ Đ à
BODY

diag "Testing stripping";
test_directive($body, $expected);

eval {
    test_directive($body, $expected, 1);
};
ok($@, "Wrong format handled dies");
ok($@ =~ m/^Wrong format 1 at/, "Error code ok");

diag "Testing formats";

$body =<<'BODY';
#author     Pippo          
ć
*đ*
Đ
à

#title    Ciao ć đ Đ à           
          is a *long* title             

#random        ***Random***                 

here the body starts....
BODY

$expected = {
             random => '<strong><em>Random</em></strong>',
             title => "Ciao \x{107} \x{111} \x{110} \x{e0} is a <em>long</em> title",
             author => "Pippo \x{107} <em>\x{111}</em> \x{110} \x{e0}",
};

test_directive($body, $expected, "html");

$expected = {
             random => '\\textbf{\\emph{Random}}',
             title => "Ciao \x{107} \x{111} \x{110} \x{e0} is a \\emph{long} title",
             author => "Pippo \x{107} \\emph{\x{111}} \x{110} \x{e0}",
};


test_directive($body, $expected, "ltx");

$body =<<'BODY';
#author     "Pippo" & 'Pluto'          
ć
*đ*
<Đ>
à

#title    Ciao ć đ Đ à           
          is a *long* title             

#random        ***Random***                 

here the body starts....
BODY

$expected = {
             random => '<strong><em>Random</em></strong>',
             title => "Ciao \x{107} \x{111} \x{110} \x{e0} is a <em>long</em> title",
             author => "&quot;Pippo&quot; &amp; &#x27;Pluto&#x27; \x{107} <em>\x{111}</em> &lt;\x{110}&gt; \x{e0}"
            };

test_directive($body, $expected, "html");

$body =<<'BODY';
#author     {Pippo} & \Pluto| # ^ _          
ć
*đ*
<Đ>
à

#title    Ciao ć đ Đ à           
          is a *long* title             

#random        ***Random***                 

here the body starts....
BODY

$expected = {
             random => '\\textbf{\\emph{Random}}',
             title => "Ciao \x{107} \x{111} \x{110} \x{e0} is a \\emph{long} title",
             author => "\\{Pippo\\} \\& \\textbackslash{}Pluto\\textbar{} \\# \\^{} \\_ \x{107} \\emph{\x{111}} <\x{110}> \x{e0}"
            };

test_directive($body, $expected, "ltx");

test_directive("ciao\n\n" x 100, {});
test_directive("ciao\n" x 100, {});


$body =<<'BODY';
#author 0
#title 0

0.0
BODY

$expected = {
             author => 0,
             title => 0,
            };

test_directive($body, $expected);

sub write_file {
    my ($file, @strings) = @_;
    open (my $fh, ">:encoding(UTF-8)", $file) or die "$file: $!";
    print $fh @strings;
    close $fh;
}

sub test_directive {
    my ($string, $directives, $format) = @_;
    my $tmp = File::Temp->new();
    my $fname = $tmp->filename;
    diag "Using $fname\n";
    write_file($fname, $string);
    my $dirs = muse_fast_scan_header($fname, $format);
    is_deeply($dirs, $directives, "Correctly parsed")
      or print Dumper($dirs, $expected);
}
