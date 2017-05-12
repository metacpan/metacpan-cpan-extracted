<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/TR/WD-xsl">
  <xsl:template match="/">
    <html><head><title>Welcome to XML::EP!</title></head>
    <body bgcolor="#ffffff">
    <h1>Welcome to XML::EP!</h1>
    <p>If you are reading my name and email address below, all worked
    fine and you have successfully installed XML::EP:</p>
    <table>
      <tr><th>Name</th><td><xsl:value-of select="address/name"/></td></tr>
      <tr><th>Email</th><td><xsl:value-of select="address/email"/></td></tr>
    </table>
    <p>Please consider to support XML::EP by donating some work. This
    could include:</p>
    <ul>
      <li>Writing documentation. Remember, other people will have the
      same problems that you had.</li>
      <li>Working on the stylesheet processor. As far as I know, it's
      unsupported. You might like to contact the authors,
      <a href="mailto:gjosten@sci.kun.nl">Geert Josten</a> and
      <a href="mailto:egonw@sci.kun.nl">Egon Willighagen</a>.</li>
      <li>Develop an SQL processor, a Tamino processor, an LDAP processor
      (see <a href="http://xml.apache.org/cocoon/">Cocoon</a> for details) an
      <a href="http://perl.apache.org/embperl/">EmbPerl</a>,
      <a href="http://www.masonhq.com/">Mason</a>,
      <a href="http://www.nodeworks.com/asp/">Apache::ASP</a> or
      <a href="ftp://ftp.funet.fi/pub/languages/perl/CPAN/authors/id/JWIED/">HTML::EP</a>
      processor that mimick the corresponding EHTML systems.</li>
      <li>Port XML::EP to mod_perl, ISAPI, NSAPI or whatever else.</li>
      <li>Develop cache support for XML::EP, to speed it up</li>
      <li>Implement your own ideas for the controller.</li>
    </ul>
    </body></html>
  </xsl:template>
</xsl:stylesheet>
