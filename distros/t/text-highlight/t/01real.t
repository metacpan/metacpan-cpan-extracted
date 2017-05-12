use Test;

BEGIN { plan tests => 8 }

use Text::Highlight;

my $o = Text::Highlight->new(wrapper => "<pre>%s</pre>\n");

ok(1);

my $html = <<'EOHTML';
<html>
<head>
        <title>Hello World!</title>
</head>
<!-- Hello World! -->
<body>
<h2>Hello World!</h2>
<p class="center">
        <i>World, this is me, saying "hello!"</i>
</p>
</body>
</html>
EOHTML

my $java = <<'EOJAVA';
//hello world!
public class HelloWorld
{
  public static final void main( String args[] )
  {
     System.out.println("Hello World");
  }
}
EOJAVA

my $perl = <<'EOPERL';
#hello world!
print "Hello World!\n";
EOPERL

my $cpp = <<'EOCPP';
#include <iostream>

/*
block
*/
//line
int main(void)
{
	cout << "Hello World!" << endl;
	return 0;
}
EOCPP

my $css = <<'EOCSS';
body
{
	background-color: #0060A0; /* Win2k default blue backgroundish */
	color: white;
}

a:link { color: yellow }
a:visited { color: #BAD1EA } /* lighter grey-blue */
a:hover { color: #00FF00 }   /* bright, nasty green */
a:active { color: #FF8080F } /* I don't remember */

ul
{
	list-style: circle outside;
}
EOCSS

my $php = <<'EOPHP';
<?
	#Hello World!
	echo "Hello World!"
?>
EOPHP

my $sql = <<'EOSQL';
SELECT count(*) FROM tblFoo WHERE col = 'value';
INSERT INTO tblFoo (column) SELECT count(*) FROM tblFoo2;
EOSQL

####################### HIGHLIGHTED CODE ##############################

my $html_h = <<'EOH';
<pre>&lt;<span class="key1">html</span>&gt;
&lt;<span class="key1">head</span>&gt;
        &lt;<span class="key1">title</span>&gt;Hello World!&lt;/<span class="key1">title</span>&gt;
&lt;/<span class="key1">head</span>&gt;
<span class="comment">&lt;!-- Hello World! --&gt;</span>
&lt;<span class="key1">body</span>&gt;
&lt;<span class="key1">h2</span>&gt;Hello World!&lt;/<span class="key1">h2</span>&gt;
&lt;<span class="key1">p</span> <span class="key2">class</span>=<span class="string">"center"</span>&gt;
        &lt;<span class="key1">i</span>&gt;World, this is me, saying <span class="string">"hello!"</span>&lt;/<span class="key1">i</span>&gt;
&lt;/<span class="key1">p</span>&gt;
&lt;/<span class="key1">body</span>&gt;
&lt;/<span class="key1">html</span>&gt;
</pre>
EOH

my $java_h = <<'EOH';
<pre><span class="comment">//hello world!</span>
<span class="key1">public</span> <span class="key1">class</span> HelloWorld
{
  <span class="key1">public</span> <span class="key1">static</span> <span class="key1">final</span> <span class="key1">void</span> main( <span class="key2">String</span> args[] )
  {
     <span class="key2">System</span>.out.println(<span class="string">"Hello World"</span>);
  }
}
</pre>
EOH

my $perl_h = <<'EOH';
<pre><span class="comment">#hello world!</span>
<span class="key2">print</span> <span class="string">"Hello World!\n"</span>;
</pre>
EOH

my $cpp_h = <<'EOH';
<pre>#<span class="key2">include</span> &lt;iostream&gt;

<span class="comment">/*
block
*/</span>
<span class="comment">//line</span>
<span class="key1">int</span> main(<span class="key1">void</span>)
{
	<span class="key1">cout</span> &lt;&lt; <span class="string">"Hello World!"</span> &lt;&lt; endl;
	<span class="key1">return</span> <span class="number">0</span>;
}
</pre>
EOH

my $css_h = <<'EOH';
<pre>body
{
	<span class="key1">background-color</span>: #0060A0; <span class="comment">/* Win2k default blue backgroundish */</span>
	<span class="key1">color</span>: <span class="key2">white</span>;
}

a:link { <span class="key1">color</span>: <span class="key2">yellow</span> }
a:visited { <span class="key1">color</span>: #BAD1EA } <span class="comment">/* lighter grey-blue */</span>
a:hover { <span class="key1">color</span>: #00FF00 }   <span class="comment">/* bright, nasty green */</span>
a:active { <span class="key1">color</span>: #FF8080F } <span class="comment">/* I don't remember */</span>

ul
{
	<span class="key1">list-style</span>: <span class="key2">circle</span> <span class="key2">outside</span>;
}
</pre>
EOH

my $php_h = <<'EOH';
<pre>&lt;?
	<span class="comment">#Hello World!</span>
	<span class="key2">echo</span> <span class="string">"Hello World!"</span>
?&gt;
</pre>
EOH

my $sql_h = <<'EOH';
<pre><span class="key1">SELECT</span> <span class="key4">count</span>(*) <span class="key1">FROM</span> tblFoo <span class="key1">WHERE</span> col = <span class="string">'value'</span>;
<span class="key1">INSERT</span> <span class="key1">INTO</span> tblFoo (column) <span class="key1">SELECT</span> <span class="key4">count</span>(*) <span class="key1">FROM</span> tblFoo2;
</pre>
EOH

ok($o->highlight('HTML', $html, 'simple'), $html_h);
ok($o->highlight('Java', $java), $java_h);
ok($o->highlight('Perl', $perl), $perl_h);
ok($o->highlight('CPP',  $cpp),  $cpp_h);
ok($o->highlight('CSS',  $css),  $css_h);
ok($o->highlight('PHP',  $php),  $php_h);
ok($o->highlight('SQL',  $sql),  $sql_h);
