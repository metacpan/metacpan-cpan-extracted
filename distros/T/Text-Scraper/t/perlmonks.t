
use Test;
use lib '../lib';

BEGIN { plan tests => 5 }

use Text::Scraper;
ok(1); 

my $tmpl = Text::Scraper->slurp(\*DATA);
my $src  = Text::Scraper->slurp("$0.html");
my $obj  = Text::Scraper->new(tmpl => $tmpl);
my $data = $obj->scrape($src);

ok( $data->[0]{section_title}               eq "New Questions" );
ok( $data->[0]{postings}[10]{post_title}    eq "problems using SQL::Statement" );
ok( $data->[2]{section_title}               eq "New Cool Uses for Perl" );
ok( $data->[2]{postings}[1]{post_title}     eq "iTunes and Windows and Perl == Bliss" );

__DATA__


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
    on <?tmpl var section_date ?>
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

    <?tmpl var post_content(\S.*?\S) ?>

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