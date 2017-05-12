<start_html>
Hello World
<block name="include0">
<p>
Hello World Include Library
</block>
<block name="include1">
<p>
${hello}
<p>
<perl method="hello"/>
</block>
<end_html>
__PERL__
sub hello { \'Hello World Include Perl Method' }
