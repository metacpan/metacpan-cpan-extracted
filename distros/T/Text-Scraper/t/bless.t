
use Test;
use lib '../lib';

BEGIN { plan tests => 13 }

use Text::Scraper;
use Data::Dumper;
ok(1); 

my $tmpl = Text::Scraper->slurp(\*DATA);
my $src  = Text::Scraper->slurp("$0.html");
my $obj  = Text::Scraper->new(tmpl => $tmpl, syntax => MySyntax->new() );
my $data = $obj->scrape($src);


ok($_->isa('MyFoo')) foreach @{ $data->[0]{postings} };


#
#
#
package MySyntax;
use base 'Text::Scraper::Syntax';

sub define_class_branches
{
    my $self = shift;
    return ($self->SUPER::define_class_branches(), foo => 'MyFoo');
}

#
#
#
package MyFoo;
use base 'Text::Scraper::Branch';

sub on_data
{
    my ($self, $matches) = @_;
    @$matches = map {  $self->new(%$_)  } @$matches;
    return $matches;
}

package main;

__DATA__


  <tr class = "section_title" width = "100%" border = "1">
    <td class = "section_title" width = "100%">
      <?tmpl var section_title ?>
    </td>
  </tr>
  <tr>
    <td>

<?tmpl foo postings ?>

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