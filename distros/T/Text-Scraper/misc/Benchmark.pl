
use lib '../lib';

use Text::Embed;
use Template::Extract;
use Text::Scraper;
use LWP::Simple;
use Benchmark qw(:all);
use Data::Dumper;
use Devel::Size('total_size');

my $src1  = Text::Scraper->slurp("../t/PerlMonks.t.html");
my $src2  = $src1;
my ($t1, $d1);
my ($t2, $d2);

template_extract(); warn "1 ack!" unless $d1;
text_extract();     warn "2 ack!" unless $d2;

print "Template::Extract obj:  ", total_size($t1) ,"\n";
print "Template::Extract data: ", total_size($d1) ,"\n";
print "Text::Scraper     obj:  ", total_size($t2) ,"\n";
print "Text::Scraper     data: ", total_size($d2) ,"\n";

print "\nText::Scraper     %: ", ((Devel::Size::total_size($t2) / Devel::Size::total_size($t1)) * 100) ,"\n";

cmpthese($_, {template => \&template_extract, text => \&text_extract} ) foreach (100);

sub template_extract
{
    $t1 = Template::Extract->new();
    $d1 = $t1->extract($DATA{TEMPLATE_EXTRACT_TEMPLATE}, $src1);
}

sub text_extract
{
    $t2 = Text::Scraper->new(tmpl => $DATA{TEXT_EXTRACT_TEMPLATE});
    $d2 = $t2->scrape($src2);
}


__DATA__


__TEXT_EXTRACT_TEMPLATE__

  <tr class = "section_title" width = "100%" border = "1">
    <td class = "section_title" width = "100%">
      <?tmpl var section_title ?>
    </td>
  </tr>
  <tr>
    <td>

<?tmpl loop postings ?>

<tr class   = "post_head">
  <td>
    <a id  ="<?tmpl var post_id ?>" 
       name="<?tmpl var post_name ?>" 
       href="<?tmpl var post_href ?>"
    ><?tmpl var post_title ?></a><br /> 
    on <?tmpl var section-date ?>
  </td>
  <td valign = "top">
    <a HREF="<?tmpl var post_replies_link ?>"><?tmpl var post_replies_count ?></a>
  </td>
  <td valign = "top">
    by <a HREF="<?tmpl var post_author_link ?>"><?tmpl var post_author ?></a>
  </td>
</tr>
<tr>
  <td colspan = "3">
  <div class="vote"><?tmpl stuff post_vote_crap ?></div>
  </td>
</tr>
<tr class = "post_body">
  <td colspan = "2">

    <?tmpl var post_content ?>

  </td>
  <td><br />
    <a href= "<?tmpl var post_reply_link ?>"><font size = "2">&#091;Offer your reply&#093;</font></a>
  </td>
</tr>
<?tmpl end postings ?>

<!--  End Post  -->

      </table>
    </td>
  </tr>
</table>

__TEMPLATE_EXTRACT_TEMPLATE__

  <tr class = "section_title" width = "100%" border = "1">
[% FOREACH section %]
    <td class = "section_title" width = "100%">
      [% sectionTitle %]
    </td>
  </tr>
  <tr>
    <td>
[% ... %]
[% FOREACH postings %]
[% ... %]
<tr class   = "post_head">
  <td>
    <a id  ="[% postId %]" 
       name="[% postName %]" 
       href="[% postHref %]"
    >[% postTitle %]</a><br /> 
    on [% sectionDate %]
  </td>
  <td valign = "top">
    <a HREF="[% postRepliesLink %]">[% postRepliesCount %]</a>
  </td>
  <td valign = "top">
    by <a HREF="[% postAuthorLink %]">[% postAuthor %]</a>
  </td>
</tr>
<tr>
  <td colspan = "3">
  <div class="vote">[% ... %]</div>
  </td>
</tr>
<tr class = "post_body">
  <td colspan = "2">
[% postContent %]
  </td>
  <td><br />
    <a href= "[% postReplyLink %]"><font size = "2">&#091;Offer your reply&#093;</font></a>
  </td>
</tr>
[% ... %]
[% END %]
[% ... %]
[% END %]
[% ... %]
      </table>
    </td>
  </tr>
</table>

