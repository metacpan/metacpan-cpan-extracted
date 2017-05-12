# -*- mode: cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Muse-HTML-Importer.t'

use strict;
use warnings;
use utf8;
use File::Temp;
use Data::Dumper;
eval "use Text::Diff;";
my $use_diff;
if (!$@) {
    $use_diff = 1;
}

use Test::More tests => 52;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";
use Text::Amuse::Preprocessor::HTML qw/html_to_muse html_file_to_muse/;



my $html = '<p>
	Your text here... &amp; &quot; &ograve;</p>
<p>
Hello
</p>';

is(html_to_muse($html),
   "\n\nYour text here... & \" ò\n\nHello\n\n", "Testing a basic html");

is(html_to_muse('<pre>hello</pre>'), "\n<example>\nhello\n</example>\n");

is(html_to_muse("<pre>hello\nworld\n\nhello</pre>"), "\n<example>\nhello\nworld\n\nhello\n</example>\n");

is(html_to_muse("<i>hello there</i>"), "<em>hello there</em>", "Basic test works");
is(html_to_muse("<i>hello there</i>\n<em>hi</em>\n"), "<em>hello there</em> <em>hi</em>" , "Basic test works");
is(html_to_muse("<b>hello there</b>"), "<strong>hello there</strong>", "Basic test works");

foreach my $em (qw/em i u/) {
    is (html_to_muse("<p><$em>em</$em>\ni <$em>em</$em>\n\n</p><p>blabla</p>"),
        "\n\n<em>em</em> i <em>em</em>\n\nblabla\n\n", "$em => em");
}

foreach my $em (qw/strong b/) {
    is (html_to_muse("<p><$em>em</$em>\ni <$em>em</$em>\n\n</p><p>blabla</p>"),
        "\n\n<strong>em</strong> i <strong>em</strong>\n\nblabla\n\n", "$em => strong");
}

my %checks = (
              code => 'code',
              sup => 'sup',
              sub => 'sub',
              strike => 'del',
              del => 'del',
             );
foreach my $em (keys %checks) {
    is (html_to_muse("<p><$em>em</$em>\ni <$em>em</$em>\n\n</p><p>blabla</p>"),
        "\n\n<$checks{$em}>em</$checks{$em}> i <$checks{$em}>em</$checks{$em}>\n\nblabla\n\n", "$em => $checks{$em} ok");
}

$html = q{
<p>
My
<em>
test
</em>

<a href=""></a>

<a href="test">Me</a>

Hullo there
</p>
};
is html_to_muse($html), "\n\nMy <em>test</em> [[test][Me]] Hullo there\n\n";

$html = "
<p>
	&nbsp;</p>
<h1>
	This is




 a test</h1>
<p>
	&nbsp;</p>
<p>
	Hello &laquo;there&raquo;, with &agrave;&aelig;&aelig;\x{142}&euro;&para;&frac14;&frac12;&szlig;&eth;\x{111} some unicode</p>
<p>
	&nbsp;</p>
<blockquote>
	<p>
		A blockquote</p>
</blockquote>
<ol>
	<li>
		A list</li>
	<li>
		with another item</li>
	<li>
		another</li>
</ol>
<p>
	and</p>
<ul>
	<li>
		and a bullte list</li>
	<li>
		another item</li>
	<li>
		another</li>
</ul>
<p>
	A sub <sub>subscript&nbsp; </sub>and a <sup>superscript&nbsp; </sup>a <strike>strikeover </strike>an <em>emphasis&nbsp; </em>a <strong>double one&nbsp; </strong>and the <em><strong>bold italic</strong></em>.</p>
<p>
	&nbsp;</p>
<h2>
	Then the</h2>
<p>
	&nbsp;</p>
<h3>
	third</h3>
<h4>
	hello</h4>
<h5>
	fifth</h5>
<p>
	&nbsp;</p>
<h6>
	sixst</h6>
<p>
	&nbsp;</p>
<p>
	finally finished</p>
";

my $expected = '

<br>

* This is a test

<br>

Hello «there», with àææł€¶¼½ßðđ some unicode

<br>

<quote>

A blockquote

</quote>

 1. A list

 1. with another item

 1. another

and

 - and a bullte list

 - another item

 - another

A sub <sub>subscript</sub> and a <sup>superscript</sup> a <del>strikeover</del> an <em>emphasis</em> a <strong>double one</strong> and the <em><strong>bold italic</strong></em>.

<br>

* Then the

<br>

** third

*** hello

**** fifth

<br>

***** sixst

<br>

finally finished

';

compare_two_long_strings($html, $expected, "General overview");

$html = '<code class="inline"><a class="l_k" href="http://perldoc.perl.org/functions/print.html">print</a></code> function in Perl';

is(html_to_muse($html),
   '<code>[[http://perldoc.perl.org/functions/print.html][print]]</code>' . 
   ' function in Perl', "testing <a>");

# some things from libcom:

$html = '<p>I&#039;d been in town for about 24 hours when I got to the anarchist bookfair, and one of the first people I saw there was a man who sexually assaulted a friend of mine. At this point I realised that  discussions about safer spaces, sexual violence, and our response to these issues as a community aren&#039;t something I am going to be able to avoid any time soon. The shitty reality is that sexual assault, as well as sexist, racist, homophobic, transphobic, queerphobic and other socially conditioned, oppressive bullshit (intentional or not) is not unusual. As communists, we can all agree that this kind of behaviour is A Bad Thing, <a class="see-footnote" id="footnoteref1_n85wy2g" title="although some people may wish to defend their right to make racist, sexist, homophobic etc jokes, because we all know they&#039;re a communist and don&#039;t really mean it. Luckily, Polite Ire has taken the trouble to explain exactly why that&#039;s bullshit." href="#footnote1_n85wy2g">1</a> but the disagreement comes when we&#039;re talking about what we do about it.</p>';

$expected = "\n\nI'd been in town for about 24 hours when I got to the anarchist bookfair, and one of the first people I saw there was a man who sexually assaulted a friend of mine. At this point I realised that discussions about safer spaces, sexual violence, and our response to these issues as a community aren't something I am going to be able to avoid any time soon. The shitty reality is that sexual assault, as well as sexist, racist, homophobic, transphobic, queerphobic and other socially conditioned, oppressive bullshit (intentional or not) is not unusual. As communists, we can all agree that this kind of behaviour is A Bad Thing, [1] but the disagreement comes when we're talking about what we do about it.\n\n";

compare_two_long_strings($html, $expected, "links");

compare_two_long_strings("<html> <head><title>hello</title></head><body> <em> <strong> Hello </strong></em> </body></html>",
			 "hello <em><strong>Hello</strong></em>",
			 "testing simple random tags");


$html =<< 'EOF';
<div>
<blockquote class="bb-quote-body">Hi [REDACTED].<br />
I am writing to you on behalf of the 2012 NYC Anarchist Book fair Safe(r) Space Group to let you know that a request has been made that you not attend this year. The policy at the event, posted at http://www.anarchistbookfair.net/saferspace, is in place to create a supportive, non-threatening environment for all. This means that anyone may be asked to not attend. <span style="font-style:italic"><span style="font-weight:bold">No blame is placed, no decision is made</span></span>, we simply ask that you not attend to prevent anyone from feeling unsafe.<br />
We understand that being asked not to attend is not easy, and we don’t take it lightly. You may not know why you are being asked not to attend or who all is requesting this, or you may feel the situation is totally unfair. Our goal is not to decide right or wrong but to maintain safety at the fair. Some situations are gray and sometimes based on simple misunderstandings, but regardless of the reasons, no matter what your defense, we still ask that you not attend this years book fair. Not attending is not an admission of guilt. In fact, you not attending is a statement that you respect everyone’s safety at the fair and are taking a positive step to uphold that principle.<br />
<span style="font-style:italic"><span style="font-weight:bold">We also understand your need to know why you are being asked not to attend. However, the book fair is not the place to resolve conflict.</span></span> Please, do not approach anyone at the fair who you think is responsible for the request that you not attend, or anyone that you think may have made this request before the fair. This violates our commitment to keeping everyone safe.<br />
We realize that this email is formal. We chose to email you because we want to remain as neutral as possible in this position and situation, as well as to give you the space in which to process this request in whatever way is most comfortable and safe.<br />
<span style="font-style:italic"><span style="font-weight:bold">If you have any questions please don&#039;t hesitate to contact me.</span></span> Again, do not contact anyone without their consent, especially any survivors. <span style="font-style:italic"><span style="font-weight:bold">You can field all questions through me or I can put you in contact with other safer space members</span></span>.<br />
Thanks for helping us keep it safe,<br />
[REDACTED]/ NYC Anarchist Bookfair Safer Space Team</blockquote>
</div>
EOF

$expected =<< 'EOF';


<quote>
Hi [REDACTED].

I am writing to you on behalf of the 2012 NYC Anarchist Book fair Safe(r) Space Group to let you know that a request has been made that you not attend this year. The policy at the event, posted at http://www.anarchistbookfair.net/saferspace, is in place to create a supportive, non-threatening environment for all. This means that anyone may be asked to not attend. <em><strong>No blame is placed, no decision is made</strong></em>, we simply ask that you not attend to prevent anyone from feeling unsafe.

We understand that being asked not to attend is not easy, and we don’t take it lightly. You may not know why you are being asked not to attend or who all is requesting this, or you may feel the situation is totally unfair. Our goal is not to decide right or wrong but to maintain safety at the fair. Some situations are gray and sometimes based on simple misunderstandings, but regardless of the reasons, no matter what your defense, we still ask that you not attend this years book fair. Not attending is not an admission of guilt. In fact, you not attending is a statement that you respect everyone’s safety at the fair and are taking a positive step to uphold that principle.

<em><strong>We also understand your need to know why you are being asked not to attend. However, the book fair is not the place to resolve conflict.</strong></em> Please, do not approach anyone at the fair who you think is responsible for the request that you not attend, or anyone that you think may have made this request before the fair. This violates our commitment to keeping everyone safe.

We realize that this email is formal. We chose to email you because we want to remain as neutral as possible in this position and situation, as well as to give you the space in which to process this request in whatever way is most comfortable and safe.

<em><strong>If you have any questions please don't hesitate to contact me.</strong></em> Again, do not contact anyone without their consent, especially any survivors. <em><strong>You can field all questions through me or I can put you in contact with other safer space members</strong></em>.

Thanks for helping us keep it safe,

[REDACTED]/ NYC Anarchist Bookfair Safer Space Team
</quote>

EOF

compare_two_long_strings($html, $expected, "<span thing>");

compare_two_long_strings("<sup>1</sup>", "<sup>1</sup>", "sup");

compare_two_long_strings(
			 "<div><i> <b> 1 </b> </i> <i> <b> 1 </b> </i></div>",
			 "\n\n<em><strong>1</strong></em>" . " " .
			 "<em><strong>1</strong></em>\n\n",
			"i and b");


$html = <<'HTML';

<ul class="bb-list" style="list-style-type:circle;">
<li>Doesn&#039;t detail allegations and could be confusing for the recipient</li>
<li>Doesn&#039;t give the recipient a right to reply or provide their side of the story</li>
<li>By providing anonymity to the person who requested the recipient be asked not to attend the bookfair, this letter paves the way for abuses of power and a slew of false allegations.</li>
</ul>
<p>I don&#039;t think the letter is without fault, nor do I think that people objecting to it are apologists for sexual assault by default, and I&#039;d like to make that quite clear. I decided to go and chat to the safer spaces team at the bookfair. They weren&#039;t some shadowy clique plotting people&#039;s downfall in a backroom somewhere, I met a few women sat at the very entrance to the main room, with a clear sign indicating who they were, and arm bands making them easily identifiable. They had formed a group called <a href="http://supportny.org/about/" class="bb-url">Support New York</a> who are<br />
<div class="bb-quote">Quote:<br />
<blockquote class="bb-quote-body">dedicated to healing the effects of sexual assault and abuse.  Our aim is to meet the needs of the survivor, to hold accountable those who  have perpetrated harm, and to maintain a larger dialogue within the community about consent, mutual aid, and our society’s narrow views of abuse. We came together in order to create our own safe(r) space and provide support for people of all genders, races, ages and orientations, separate from the police and prison systems that perpetuate these abuses</blockquote></div></p>

HTML

$expected =<< 'MUSE';


 - Doesn't detail allegations and could be confusing for the recipient

 - Doesn't give the recipient a right to reply or provide their side of the story

 - By providing anonymity to the person who requested the recipient be asked not to attend the bookfair, this letter paves the way for abuses of power and a slew of false allegations.

I don't think the letter is without fault, nor do I think that people objecting to it are apologists for sexual assault by default, and I'd like to make that quite clear. I decided to go and chat to the safer spaces team at the bookfair. They weren't some shadowy clique plotting people's downfall in a backroom somewhere, I met a few women sat at the very entrance to the main room, with a clear sign indicating who they were, and arm bands making them easily identifiable. They had formed a group called [[http://supportny.org/about/][Support New York]] who are

Quote:

<quote>
dedicated to healing the effects of sexual assault and abuse. Our aim is to meet the needs of the survivor, to hold accountable those who have perpetrated harm, and to maintain a larger dialogue within the community about consent, mutual aid, and our society’s narrow views of abuse. We came together in order to create our own safe(r) space and provide support for people of all genders, races, ages and orientations, separate from the police and prison systems that perpetuate these abuses
</quote>

MUSE

compare_two_long_strings($html, $expected, "lists and urls");

$html =     "<div>Hadsonovim <i>Zelenim dvorima[[#_ftn10][<b>[10]</b>]]</i></div>";
$expected = "\n\nHadsonovim <em>Zelenim dvorima[10]</em>\n\n";

compare_two_long_strings($html, $expected, "Footnote");
			 
$html = "<div>Coperto di insulti e non sapendo che pesci pigliare, da parte sua il curatore ha barbugliato qualcosa sulla differenza fra vecchia dittatura (brutta e cattiva come i suoi generali) e nuova democrazia (bella e buona come i suoi finanziamenti). Oppure sul fatto che tutti i libri sull'Argentina ricevono contributi dallo Stato, e quindi... </div>
<div>Tutto fiato sprecato. Non c'è stato nulla da fare, i toni si sono alzati ed i prodotti culturali esposti per essere venduti sono volati in aria. Nemmeno il tentativo di mettere da parte la merce stampata e proseguire limitandosi a fare una discussione sull'anarchico abruzzese ha funzionato, giacché il buon Prunetti voleva continuare a tenere banco. Zittito nuovamente, si stava consolando firmando autografi.</div>";

$expected =<< 'MUSE';


Coperto di insulti e non sapendo che pesci pigliare, da parte sua il curatore ha barbugliato qualcosa sulla differenza fra vecchia dittatura (brutta e cattiva come i suoi generali) e nuova democrazia (bella e buona come i suoi finanziamenti). Oppure sul fatto che tutti i libri sull'Argentina ricevono contributi dallo Stato, e quindi...

Tutto fiato sprecato. Non c'è stato nulla da fare, i toni si sono alzati ed i prodotti culturali esposti per essere venduti sono volati in aria. Nemmeno il tentativo di mettere da parte la merce stampata e proseguire limitandosi a fare una discussione sull'anarchico abruzzese ha funzionato, giacché il buon Prunetti voleva continuare a tenere banco. Zittito nuovamente, si stava consolando firmando autografi.

MUSE

compare_two_long_strings($html, $expected, "div test");

$html = "<div>Dobbiamo imparare a mordere, e mordere a fondo!</div><div>\x{a0}</div><div style=\"text-align: right; \">[<em>The Alarm</em>, Chicago, Vol. 1, n. 3 del dicembre 1915]</div><div>\x{a0}</div>";

$expected =<< 'MUSE';


Dobbiamo imparare a mordere, e mordere a fondo!

<br>

<right>
[<em>The Alarm</em>, Chicago, Vol. 1, n. 3 del dicembre 1915]
</right>

<br>

MUSE

compare_two_long_strings($html, $expected, "right align");

$html = '<div style="text-align: right; "><em>ma poiché per il momento tutte le strade ci sono precluse, </em></div>
<div style="text-align: right; "><em>dipende da noi trovare una via d\'uscita proprio a partire da qui, </em></div>
<div style="text-align: center; "><em>rifiutando in ogni occasione e su tutti i piani di cedere»</em></div>
<div> </div>
<div style="text-align: center; "><em>rifiutando in ogni occasione e su tutti i piani di cedere»</em></div>
<div> </div>';

$expected =<< 'MUSE';


<right>
<em>ma poiché per il momento tutte le strade ci sono precluse,</em>
</right>

<right>
<em>dipende da noi trovare una via d'uscita proprio a partire da qui,</em>
</right>

<center>
<em>rifiutando in ogni occasione e su tutti i piani di cedere»</em>
</center>

<br>

<center>
<em>rifiutando in ogni occasione e su tutti i piani di cedere»</em>
</center>

<br>

MUSE

compare_two_long_strings($html, $expected, "right and center");

$html = '<P ALIGN="RIGHT">[<em>La Rivolta</em>, Pistoia, anno I, n. 8 del 19 febbraio 1910]</P>';

$expected =<< 'MUSE';


<right>
[<em>La Rivolta</em>, Pistoia, anno I, n. 8 del 19 febbraio 1910]
</right>

MUSE

compare_two_long_strings($html, $expected, "right with align prop");

$html = q{<p class=MsoNormal style='text-align:justify'><span lang=ES-MX
style='font-size:11.0pt;font-family:Arial;color:black;mso-ansi-language:ES-MX'>Al
fin podemos presentar a nuestros lectores esta cuarta edición cibernética del
libro que con base en mucho trabajo, dedicación y cariño publicamos en nuestra
editorial, </span><span lang=ES-MX style='font-size:11.0pt;font-family:Arial;
mso-ansi-language:ES-MX'>Ediciones Antorcha<span style='color:black'>, el 25 de
junio de 1980.</span></span></p><pre>

this

code

is
   looking ok

</pre>};

$expected = q{

Al fin podemos presentar a nuestros lectores esta cuarta edición cibernética del libro que con base en mucho trabajo, dedicación y cariño publicamos en nuestra editorial, Ediciones Antorcha, el 25 de junio de 1980.

<example>

this

code

is
   looking ok

</example>
};

compare_two_long_strings($html, $expected, "ms-word garbage ok");

$html = q{
<p class=MsoNormal style='text-align:justify'><span style='font-size:10.0pt;
font-family:Arial'>&quot;Libertad ilimitada de propaganda, de opinión, de
prensa, de reunión pública o privada...Libertad absoluta para organizar asociaciones,
aunque sean con manifiestos fines inmorales...La libertad puede y debe
defenderse únicamente mediante la libertad: proponer su restricción con el
pretexto de que se la defiende es una peligrosa ilusión. Como la moral no tiene
otra fuente, ni otro objeto, ni otro estimulante que la libertad, todas las
restricciones a ésta, con el propósito de defender a aquélla, no han hecho más
que perjudicar a una y a otra.&quot;</span></p>
};

$expected = q{

"Libertad ilimitada de propaganda, de opinión, de prensa, de reunión pública o privada...Libertad absoluta para organizar asociaciones, aunque sean con manifiestos fines inmorales...La libertad puede y debe defenderse únicamente mediante la libertad: proponer su restricción con el pretexto de que se la defiende es una peligrosa ilusión. Como la moral no tiene otra fuente, ni otro objeto, ni otro estimulante que la libertad, todas las restricciones a ésta, con el propósito de defender a aquélla, no han hecho más que perjudicar a una y a otra."

};

compare_two_long_strings($html, $expected, "ms-word garbage ok");

$html = q{
<p class=MsoNormal style='text-align:justify'><span style='font-size:11.0pt;
font-family:Arial'>Pero, no interesa demasiado en este momento abundar en el
asunto<a name="_ftnref1"></a><a href="#_ftn1" title=""><span style='mso-bookmark:
_ftnref1'><span class=MsoFootnoteReference>[1]</span></span><span
style='mso-bookmark:_ftnref1'></span></a><span style='mso-bookmark:_ftnref1'></span>
y -a efectos de ahorrarnos la exposición detenida de reflexiones varias sobre
el punto- bien podemos nosotros ahora plegarnos a pies juntillas a buena parte
de las posiciones sostenidas por la izquierda uruguaya en torno al tema. Por lo
pronto, nos resulta enteramente condenable y digna del mayor de los desprecios
esa conducta propia de los anélidos que consiste en barrer la tierra con el
pecho y transformarse en el oscuro y genuflexo brazo ejecutor de los antojos
destemplados, las arbitrariedades sin cuento y los desplantes inmisericordes
del más poderoso de los Estados contemporáneos. Estamos dispuestos, por lo
tanto, a sostener en forma convencida y convincente que el gobierno uruguayo
fue estimulado por los Estados Unidos -vaya uno a saber cómo y exactamente a
cambio de qué-<a name="_ftnref2"></a><a href="#_ftn2" title=""><span
style='mso-bookmark:_ftnref2'><span class=MsoFootnoteReference>[2]</span></span><span
style='mso-bookmark:_ftnref2'></span></a><span style='mso-bookmark:_ftnref2'></span>
para adoptar la conducta diplomática que finalmente adoptó: proponer, en <st1:PersonName
ProductID="la Comisión" w:st="on">la Comisión</st1:PersonName> de Derechos
Humanos de las Naciones Unidas, la realización de una visita inspectiva del
organismo a efectos de registrar la situación por la que atraviesa tal
problemática en <st1:PersonName ProductID="la Cuba" w:st="on">la Cuba</st1:PersonName>
actual. </span></p>
};

$expected = q{

Pero, no interesa demasiado en este momento abundar en el asunto[1] y -a efectos de ahorrarnos la exposición detenida de reflexiones varias sobre el punto- bien podemos nosotros ahora plegarnos a pies juntillas a buena parte de las posiciones sostenidas por la izquierda uruguaya en torno al tema. Por lo pronto, nos resulta enteramente condenable y digna del mayor de los desprecios esa conducta propia de los anélidos que consiste en barrer la tierra con el pecho y transformarse en el oscuro y genuflexo brazo ejecutor de los antojos destemplados, las arbitrariedades sin cuento y los desplantes inmisericordes del más poderoso de los Estados contemporáneos. Estamos dispuestos, por lo tanto, a sostener en forma convencida y convincente que el gobierno uruguayo fue estimulado por los Estados Unidos -vaya uno a saber cómo y exactamente a cambio de qué-[2] para adoptar la conducta diplomática que finalmente adoptó: proponer, en la Comisión de Derechos Humanos de las Naciones Unidas, la realización de una visita inspectiva del organismo a efectos de registrar la situación por la que atraviesa tal problemática en la Cuba actual.

};

compare_two_long_strings($html, $expected, "ms-word garbage ok");
# print html_to_muse($html);


$html = q{
<table>

<tr>
<th> Header #1</th>

<th> Header #2</th>

</tr>

<tr valign="top" class="li_2">


<td><a href="/group/perl.cpan.testers.discuss/2016/03/msg3786.html">How to process a Build-Pre-req as a prereq and not a FAIL?</a></td>


<td width="130">3 <span class="lighter">messages</span></td>

<td width="250" class="small">


Blablaa <em>
bla
</em>
bla
</td>
<td width="120"> 5 Mar</td>
<!-- <td width="80" class="dimmed small">tid 3786</td> -->
</tr>
<tr valign="top" class="li_1">
<td><a href="/group/perl.cpan.testers.discuss/2016/03/msg3781.html">Re: Beware testing Perl6/ distributions ??? CPAN::Reporter::Smokerusers should upgrade</a></td>
<td width="130">5 <span class="lighter">messages</span></td>
<td width="250" class="small">
Blablaa <strong>
blaxXxX
</strong>
bla
</td>
<td width="120"> 2 Mar</td>
<!-- <td width="80" class="dimmed small">tid 3781</td> -->
</tr>
</table>
};

$expected = q{

 Header #1 || Header #2 ||
 [[/group/perl.cpan.testers.discuss/2016/03/msg3786.html][How to process a Build-Pre-req as a prereq and not a FAIL?]] | 3 messages | Blablaa <em>bla</em> bla | 5 Mar |
 [[/group/perl.cpan.testers.discuss/2016/03/msg3781.html][Re: Beware testing Perl6/ distributions ??? CPAN::Reporter::Smokerusers should upgrade]] | 5 messages | Blablaa <strong>blaxXxX</strong> bla | 2 Mar |

};

compare_two_long_strings($html, $expected, "table ok");

$html =<<'HTML';
<pre>



if (my $help  = shift(@ARGV)) {



    print "Can't  really  help  you...\n";


}
</pre>
HTML
$expected =<<'MUSE';

<example>

if (my $help  = shift(@ARGV)) {

    print "Can't  really  help  you...\n";

}

</example>
MUSE
compare_two_long_strings($html, $expected, "verbatim ok");

# showlines(html_to_muse($expected));



sub compare_two_long_strings {
    my ($xhtml, $xexpected, $testname, $debug) = @_;
    my $got = html_to_muse($xhtml, $debug);
    ok ($got eq $xexpected, $testname) or show_diff($got, $xexpected);
    my $tmpfh = File::Temp->new(TEMPLATE => "XXXXXXXXXX",
                                TMPDIR => 1,
                                UNLINK => 1,
                                SUFFIX => '.html');
    my $fname = $tmpfh->filename;
    diag "Using $fname\n";
    open (my $fh, '>:encoding(UTF-8)', $fname) or die $!;
    print $fh q{<!doctype html><html><head><meta charset="UTF-8"/></head><body>} . $xhtml . q{</body></html>};
    close $fh;
    $got = html_file_to_muse($fname);
    is ($got, $xexpected, $testname . ' (file)') or show_diff($got, $xexpected);
}


sub showlines {
  my $expected = shift;
  my $count = 0;
  foreach my $l (split /(\n)/, $expected) {
    diag "[$count] " . $l . "\n";
    $count++;
  }
}

sub show_diff {
    my ($got, $exp) = @_;
    if ($use_diff) {
        diag diff(\$exp, \$got, { STYLE => 'Unified' });
    }
    else {
        diag "GOT:\n$got\n\nEXP:\n$exp\n\n";
    }
}
