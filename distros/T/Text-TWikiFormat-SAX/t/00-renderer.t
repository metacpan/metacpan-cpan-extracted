#!/usr/bin/perl -w

# $Id: 00-renderer.t,v 1.1.1.1 2003/06/11 22:34:50 alex Exp $

use strict;

use lib qw(t);

use Test::More tests => 115;
use Test::Exception;
use XML::SAX::Writer;

my $samples = {
               multiline      => [ "start \\\n end", "start  end" ],
               normal         => [ "start end\n", "start end<br />"],
               normal_2       => [ "start end\nline 2", "start end<br />line 2"],
               normal_3       => [ "start end\n\nline 3", "start end<br /><br />line 3"],
               paragraph      => [ "start end\n\n \n\nstart end", "start end<br /><br /> <br /><br />start end"],
               strong         => [ "*text*", "<strong>text</strong>" ],
               strong_2       => [ " *text*", " <strong>text</strong>" ],
               strong_3       => [ "*text* ", "<strong>text</strong> " ],
               strong_4       => [ "x*text*", "x*text" ],
               strong_5       => [ "nop *start \\\n end* nop", "nop <strong>start  end</strong> nop" ],
               strong_6       => [ "*text*x", "<strong>text*x</strong>" ],
               strong_7       => [ "*text \n text*", "<strong>text <br /> text</strong>" ],
               strong_8       => [ "\n*text \n text*\n", "<br /><strong>text <br /> text</strong><br />" ],
               strong_9       => [ "(*text*)", "(<strong>text</strong>)" ],
               strong_10      => [ "*text*\n", "<strong>text</strong><br />" ],
               strong_11      => [ "*L*", "<strong>L</strong>" ],
               strong_extra_closing  => [ "nop *start \\\n end* end_2* nop", 
                                          "nop <strong>start  end</strong> end_2 nop" ],
               strong_extra_opening  => [ "nop *start *start_2\\\n end* nop", 
                                          "nop <strong>start <strong>start_2 end</strong> nop</strong>" ],
               strong_extra          => [ "nop *start *start_2 text end_3* end_2* end* nop",
                                          "nop <strong>start <strong>start_2 text end_3</strong> end_2</strong> end nop" ],
               headings       => [ "---+ heading 1\n---++ heading 2", "<h1>heading 1</h1><h2>heading 2</h2>"],
               headings_2     => [ "---+ heading *1*\n---++ heading *2* _italic_",
                                   "<h1>heading <strong>1</strong></h1><h2>heading <strong>2</strong> <em>italic</em></h2>"],
               headings_3     => [ "---++++++ heading 6", "<h6>heading 6</h6>"],
               headings_4     => [ "---++++++ *heading 6*", "<h6><strong>heading 6</strong></h6>"],
               headings_5     => [ "\n\n---+ *heading 6*\n\n", "<br /><br /><h1><strong>heading 6</strong></h1><br />"],
               em               => [ "nop _start \\\n end_ nop", "nop <em>start  end</em> nop" ],
               em_with_strong   => [ "nop _start \\\n*text* end_ nop", "nop <em>start <strong>text</strong> end</em> nop" ],
               em_strong_broken => [ "nop _start \\\n*text end_ nop", "nop <em>start <strong>text end</strong></em> nop" ],
               strong_em        => [ "nop __start \\\n end__ nop", "nop <strong><em>start  end</em></strong> nop" ],
               strong_em_2      => [ "nop __start _this not _ end__ nop", 
                                     "nop <strong><em>start <em>this not _ end</em></em></strong> nop" ],
               fixed            => [ "nop =start \\\n end= nop", "nop <code>start  end</code> nop" ],
               strong_fixed     => [ "nop ==start \\\n end== nop", "nop <strong><code>start  end</code></strong> nop" ],
               verbatim         => [ "<verbatim>*text*</verbatim>", "<pre>*text*</pre>" ],
               verbatim_2       => [ "<verbatim><tag>\n</verbatim>", "<pre>&lt;tag&gt;\n</pre>" ],
               verbatim_3       => [ "<verbatim>\n\n<tag>\n</verbatim>", "<pre>\n\n&lt;tag&gt;\n</pre>" ],
               verbatim_4       => [ "<verbatim><tag>_text_\n</verbatim>", "<pre>&lt;tag&gt;_text_\n</pre>" ],
               verbatim_5       => [ "<verbatim><tag>\\\n_text_\n</verbatim>", "<pre>&lt;tag&gt;_text_\n</pre>" ],
               verbatim_6       => [ "*text* <verbatim><tag>\\\n_text_\n</verbatim>", 
                                     "<strong>text</strong> <pre>&lt;tag&gt;_text_\n</pre>" ],
               verbatim_7       => [ "*text* <verbatim><tag>\n\\\n_text_\n</verbatim>", 
                                     "<strong>text</strong> <pre>&lt;tag&gt;\n_text_\n</pre>" ],
               verbatim_8       => [ "<verbatim><verbatim>_text_</verbatim>", "<pre><pre>_text_</pre></pre>" ],
               verbatim_9       => [ "<verbatim>_text_</verbatim></verbatim>", "<pre>_text_</pre>" ],
               verbatim_10      => [ "<verbatim>_text_</verbatim> text", "<pre>_text_</pre> text" ],
               verbatim_11      => [ "<verbatim><tag></verbatim>", "<pre>&lt;tag&gt;</pre>" ],
               verbatim_12      => [ "<verbatim>*text*<br></verbatim>", "<pre>*text*&lt;br&gt;</pre>" ],
               verbatim_13      => [ "<pre>&lt;verbatim&gt;
class CatAnimal { void purr() {
    &lt;code here&gt;
  }
}
&lt;/verbatim&gt;
</pre>", "<pre>&lt;verbatim&gt;
class CatAnimal { void purr() {
    &lt;code here&gt;
  }
}
&lt;/verbatim&gt;
</pre>"],
               pre              => [ "<pre>*text*<br></pre>", "<pre>*text*<br /></pre>" ],
               pre_1            => [ "<verbatim><pre>*text*<br></pre></verbatim>", 
                                     "<pre>&lt;pre&gt;*text*&lt;br&gt;&lt;/pre&gt;</pre>" ],
               pre_2            => [ "<pre>*text*<br></pre>", 
                                     "<pre>*text*<br /></pre>" ],
               pre_3            => [ "<pre>text&nbsp;text</pre>", "<pre>text&amp;nbsp;text</pre>" ],
               pre_4            => [ "<pre>text&lt;text</pre>", "<pre>text&lt;text</pre>" ],
               separator        => [ "--- *start end*---", "<hr /> <strong>start end*---</strong>" ],
               orderedlist      => [ "   1. point 1",
                                     "<ol><li>point 1</li></ol>" ],
               orderedlist_1    => [ "   1. point 1\n   2. point 2\n   3. point 3",
                                     "<ol><li>point 1</li><li>point 2</li><li>point 3</li></ol>" ],
               orderedlist_2    => [ "   1. point 1\ntext",
                                     "<ol><li>point 1</li></ol>text" ],
               orderedlist_3    => [ "   1. point 1\n   2. point 2\n   text",
                                     "<ol><li>point 1</li><li>point 2</li></ol>   text" ],
               orderedlist_4    => [ "   1. point *1*\n   2. *2* point\n_start\nend_",
                                     "<ol><li>point <strong>1</strong></li><li><strong>2</strong> point</li>".
                                     "</ol><em>start<br />end</em>" ],
               orderedlist_5   => [ "      1. point 1\n   2. point 2",
                                     "<ol><li>point 1</li></ol><ol><li>point 2</li></ol>" ],
               unorderedlist    => [ "   * point 1",
                                     "<ul><li>point 1</li></ul>" ],
               unorderedlist_1  => [ "   * point 1\n   * point 2\n   *. point 3",
                                     "<ul><li>point 1</li><li>point 2</li><li>point 3</li></ul>" ],
               unorderedlist_2  => [ "   * point 1\ntext",
                                     "<ul><li>point 1</li></ul>text" ],
               unorderedlist_3  => [ "   * point 1\n   * point 2\n   text",
                                     "<ul><li>point 1</li><li>point 2</li></ul>   text" ],
               unorderedlist_4  => [ "   * point *1*\n   * *2* point\n_start\nend_",
                                     "<ul><li>point <strong>1</strong></li><li><strong>2</strong> point</li>".
                                     "</ul><em>start<br />end</em>" ],
               mixedlist        => [ "   * point 1\n   1 point 2\n   *. point 3",
                                     "<ul><li>point 1</li></ul><ol><li>point 2</li></ol><ul><li>point 3</li></ul>" ],
               mixedlist_1      => [ "   1 *point 1*\n   * _point 2_\n   2 =point 3=",
                                     "<ol><li><strong>point 1</strong></li></ol>".
                                     "<ul><li><em>point 2</em></li></ul>".
                                     "<ol><li><code>point 3</code></li></ol>" ],
               mixedlist_2      => [ "\n   1 *point 1*\n   * _point 2_\n   2 =point 3=",
                                     "<br /><ol><li><strong>point 1</strong></li></ol>".
                                     "<ul><li><em>point 2</em></li></ul>".
                                     "<ol><li><code>point 3</code></li></ol>" ],
               nestedlist       => [ "   1 point 1\n      2 point 2\n      3. point 3",
                                     "<ol><li>point 1</li><ol><li>point 2</li><li>point 3</li></ol></ol>" ],
               nestedlist_1     => [ "   1 point 1\n      2 point 2\n         * point 3",
                                     "<ol><li>point 1</li><ol><li>point 2</li><ul><li>point 3</li></ul></ol></ol>" ],
               nestedlist_2     => [ "   1 point 1\n      2 point 2\n         * subpoint 1\n   3 point 3",
                                     "<ol><li>point 1</li><ol><li>point 2</li><ul><li>subpoint 1</li></ul></ol><li>point 3</li></ol>" ],
               nestedlist_3     => [ "   1 point 1\n      a) subpoint 2\n      * subpoint 1\n   3 point 3",
                                    "<ol><li>point 1</li><ol><li>subpoint 2</li></ol>".
                                    "<ul><li>subpoint 1</li></ul><li>point 3</li></ol>" ],
               nestedlist_4     => [ "*start *text*\n   1 point *1*\n      2 point _2_\n_text_ end*",
                                     "<strong>start <strong>text</strong><br />".
                                     "<ol><li>point <strong>1</strong></li><ol><li>point <em>2</em></li></ol></ol>".
                                     "<em>text</em> end</strong>" ],
               table            => [ "| text |",
                                     "<table><tr><td> text </td></tr></table>" ],
               table_1          => [ "|text|",
                                     "<table><tr><td>text</td></tr></table>" ],
               table_2          => [ "|col1|col2|",
                                     "<table><tr><td>col1</td><td>col2</td></tr></table>" ],
               table_3          => [ "\n|row1|row2|\n|row3|row4|\n",
                                     "<br /><table><tr><td>row1</td><td>row2</td></tr><tr><td>row3</td><td>row4</td></tr></table>" ],
               table_4          => [ "|_row1_|\n",
                                     "<table><tr><td><em>row1</em></td></tr></table>" ],
               table_5          => [ "|_row1_||\n|_row2|_row3|",
                                     "<table><tr><td colspan='2'><em>row1</em></td></tr>".
                                     "<tr><td><em>row2</em></td><td><em>row3</em></td></tr></table>" ],
               table_6          => [ "|_row1_\n|_row2\n",
                                     "|_row1<br />|_row2<br />" ],
               table_7          => [ "|_row1|||\n|_row2|\n",
                                     "<table><tr><td colspan='3'><em>row1</em></td></tr><tr>".
                                     "<td><em>row2</em></td></tr></table>" ],
               table_8          => [ "|   col1|col2|",
                                     "<table><tr><td align='right'>   col1</td><td>col2</td></tr></table>" ],
               table_9          => [ "|col1|  col2  |",
                                     "<table><tr><td>col1</td><td align='center'>  col2  </td></tr></table>" ],
               table_10          => [ "\n|_col1_|  *col2*  |\n",
                                      "<br /><table><tr><td><em>col1</em></td>".
                                      "<td align='center'>  <strong>col2</strong>  </td></tr></table>" ],
               table_11          => [ "\n----\n|_col1_|  *col2*  |\n",
                                      "<br /><hr /><br /><table><tr><td><em>col1</em></td>".
                                      "<td align='center'>  <strong>col2</strong>  </td></tr></table>" ],
               table_12          => [ "\n----\n|_col1_|(*col2*)|\n",
                                      "<br /><hr /><br /><table><tr><td><em>col1</em></td>".
                                      "<td>(<strong>col2</strong>)</td></tr></table>" ],
               table_13          => [ "\|11|12|13|14|15|16|\n|21|22|23|24|25|26|\n|31|32|33|34|35|36|",
                                      "<table>".
                                      "<tr><td>11</td><td>12</td><td>13</td><td>14</td><td>15</td><td>16</td></tr>".
                                      "<tr><td>21</td><td>22</td><td>23</td><td>24</td><td>25</td><td>26</td></tr>".
                                      "<tr><td>31</td><td>32</td><td>33</td><td>34</td><td>35</td><td>36</td></tr>".
                                      "</table>" ],
               table_14          => [ "\|11|12|13|14|15|16|\n|21|22|23|24|25|26|\n|31||||||",
                                      "<table>".
                                      "<tr><td>11</td><td>12</td><td>13</td><td>14</td><td>15</td><td>16</td></tr>".
                                      "<tr><td>21</td><td>22</td><td>23</td><td>24</td><td>25</td><td>26</td></tr>".
                                      "<tr><td colspan='6'>31</td></tr>".
                                      "</table>" ],
               link              => [ "[[link][text]]",
                                      "<a href='link'>text</a>" ],
               link_1            => [ "[[link]]",
                                      "<a href='link'>link</a>" ],
               link_2            => [ "*start [[link]] end*",
                                      "<strong>start <a href='link'>link</a> end</strong>" ],
               link_3            => [ "|col1|  [[link][text]]  |\n",
                                      "<table><tr><td>col1</td><td align='center'>  <a href='link'>text</a>  </td></tr></table>" ],
               link_4            => [ "[[http://www.google.com]]",
                                      "<a href='http://www.google.com'>http://www.google.com</a>" ],
               link_5            => [ "[[http://www.google.com/search?q=hello%20world#1]]",
                                      "<a href='http://www.google.com/search?q=hello%20world#1'>http://www.google.com</a>" ],
               link_6            => [ "|[[http://www.google.com/search?q=hello%20world#1]]|",
                                      "<table><tr><td><a href='http://www.google.com/search?q=hello%20world#1'>".
                                      "http://www.google.com</a></td></tr></table>" ],
               link_7            => [ "[[link][start end]]",
                                      "<a href='link'>start end</a>" ],
               link_8            => [ "[[#SquareBrackets][non-WikiWord links]]", "<a href='#SquareBrackets'>non-WikiWord links</a>"],
               link_9            => [ "located in the [[http://twiki.org/cgi-bin/view/Plugins][Plugins]] web on TWiki.org", 
                                      "located in the <a href='http://twiki.org/cgi-bin/view/Plugins'>Plugins</a> web on TWiki.org"],
               list_extra        => [ "   * point 1\n---+++ TWiki HTML Rendering\n   * point 2\n",
                                      "<ul><li>point 1</li></ul><h3>TWiki HTML Rendering</h3><ul><li>point 2</li></ul>" ],
               list_extra_2      => [ "   * point 1\n      * point 2\n---+++ TWiki HTML Rendering\n   * point 3\n   * point 4\n",
                                      "<ul><li>point 1</li><ul><li>point 2</li></ul></ul>".
                                      "<h3>TWiki HTML Rendering</h3>".
                                      "<ul><li>point 3</li><li>point 4</li></ul>" ],
               list_extra_3      => [ "   * point 1\n      * point 2\n---+++ TWiki HTML Rendering\n   * point 3\n   * point 4\n",
                                      "<ul><li>point 1</li><ul><li>point 2</li></ul></ul>".
                                      "<h3>TWiki HTML Rendering</h3>".
                                      "<ul><li>point 3</li><li>point 4</li></ul>" ],
               list_extra_4      => [ "   * point 1\n      * point 2\n   * point 3\n      * point 4\n      * point 5",
                                      "<ul><li>point 1</li><ul><li>point 2</li></ul>".
                                      "<li>point 3</li><ul><li>point 4</li><li>point 5</li></ul></ul>" ],
               list_extra_5      => [ "   * point 1\n      * point 2\n---+++ TWiki HTML Rendering\n",
                                      "<ul><li>point 1</li><ul><li>point 2</li></ul></ul>".
                                      "<h3>TWiki HTML Rendering</h3>" ],
               list_extra_6      => [ "   * point 1\n      * point 2\n---+++ TWiki HTML Rendering\n".
                                      "   * point 3\n      * point 4\n      * point 5",
                                      "<ul><li>point 1</li><ul><li>point 2</li></ul></ul>".
                                      "<h3>TWiki HTML Rendering</h3>".
                                      "<ul><li>point 3</li><ul><li>point 4</li><li>point 5</li></ul></ul>" ],
               list_extra_7      => [ "---+++ TWiki HTML Rendering\n   * point 1\n      * point 2",
                                      "<h3>TWiki HTML Rendering</h3><ul><li>point 1</li><ul><li>point 2</li></ul></ul>" ],
               list_extra_8      => [ "---+++ HTML and TWiki Usability
   * On collaboration pages, it's preferable NOT to use HTML, and to use [[#TWikiShorthand][TWiki shorthand]] instead - this keeps the text uncluttered and easy to edit.
   * %X% *NOTE:* TWiki is designed to work with a wide range of browsers and computer platforms, holding to HTML 3.2 compatibility in the standard installation - adding raw HTML, particularly browser-specific tags (or any other mark-up that doesn't degrade well) will reduce compatibility.
",
                                      "<h3>HTML and TWiki Usability</h3><ul><li>On collaboration pages, it&apos;s preferable NOT to use HTML, and to use <a href='#TWikiShorthand'>TWiki shorthand</a> instead - this keeps the text uncluttered and easy to edit.</li><li>%X% <strong>NOTE:</strong> TWiki is designed to work with a wide range of browsers and computer platforms, holding to HTML 3.2 compatibility in the standard installation - adding raw HTML, particularly browser-specific tags (or any other mark-up that doesn&apos;t degrade well) will reduce compatibility.</li></ul>" ],
               html              => [ '<A HREF="http://www.example.com">text</a>', "<a href='http://www.example.com'>text</a>" ],
               html_1            => [ '<A HREF="http://www.example.com">_text</a>', 
                                      "<a href='http://www.example.com'><em>text</em></a>" ],
               html_2            => [ '*start <A HREF="http://www.example.com">_text</a> end*',
                                      "<strong>start <a href='http://www.example.com'><em>text</em></a> end</strong>" ],
               html_3            => [ '|*start <A HREF="http://www.example.com">_text</a> end*|',
                                      "<table><tr><td><strong>start <a href='http://www.example.com'>".
                                      "<em>text</em></a> end</strong></td></tr></table>" ],
               html_4            => [ '|<A HREF="http://www.example.com">_text|',
                                      "<table><tr><td><a href='http://www.example.com'>".
                                      "<em>text</em></a></td></tr></table>" ],
               html_5            => [ '|<<A HREF="http://www.example.com">_text|',
                                      "<table><tr><td><a href='http://www.example.com'>".
                                      "<em>text</em></a></td></tr></table>" ],
               html_6            => [ 'text </td> _text|',
                                      "text  <em>text</em>" ],
               extra             => [ '<tr bgcolor="#ffffff">
<td valign="top">
 *Anchors:* <br>
 You can define a link reference inside a %WIKITOOLNAME% topic (called an anchor name) and link to that. To __define__ an anchor write =#AnchorName= at the beginning of a line. The anchor name must be a WikiWord. To __link to__ an anchor name use the =[<nop>[MyTopic#MyAnchor]]= syntax. You can omit the topic name if you want to link within the same topic.
</td></tr>', "<tr bgcolor='#ffffff'><td valign='top'> <strong>Anchors:</strong> <br /> You can define a link reference inside a %WIKITOOLNAME% topic (called an anchor name) and link to that. To <strong><em>define</em></strong> an anchor write <code>#AnchorName</code> at the beginning of a line. The anchor name must be a WikiWord. To <strong><em>link to</em></strong> an anchor name use the <code>[<nop />[MyTopic#MyAnchor]]</code> syntax. You can omit the topic name if you want to link within the same topic.<br /></td></tr>" ],
               extra_1           => [
                 '<font style="width: 60px; filter: dropShadow(color=white, offX=1, offY=1, positive=1);">Header</font>',
                 "<font style='width: 60px; filter: dropShadow(color=white, offX=1, offY=1, positive=1);'>Header</font>"]
              };

sub _fake_xml {
    return $_[0] ? sprintf "<wiki>%s</wiki>", $_[0] : "<wiki />";
}

require_ok('Text::TWikiFormat::SAX');

my $output = '';
my $parser = Text::TWikiFormat::SAX->new(
                 Handler => XML::SAX::Writer->new(
                     Output => \$output
                 )
             );
{
    foreach my $name (keys %$samples) {
        $parser->parse_string($samples->{$name}->[0]);
        is($output, _fake_xml($samples->{$name}->[1]), "testing $name");
    }
}

{
    lives_ok {
        $parser = Text::TWikiFormat::SAX->new(
                 onlink  => \&onlink_callback,
                 Handler => XML::SAX::Writer->new(
                     Output => \$output
                 )
             );
    } "Checking integrity of Text::WikiFormat::SAX with extra parameter 'onlink'";
    $parser->parse_string("*start [[link][text]] end*");
    is($output, _fake_xml("<strong>start <a href='link_link'>text_text</a> end</strong>"), "Checking returned text");

}

sub onlink_callback {
    my ($link, $text) = @_;
    is(1,1,"checking if inside callback method");
    return ($link."_link", $text."_text");
}
