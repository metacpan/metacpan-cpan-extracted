

use lib '../lib/';
use Test;

BEGIN { plan tests => 3 }

use Text::Scraper;
ok(1);

my $tmpl = Text::Scraper->slurp(\*DATA);
my $src  = Text::Scraper->slurp("$0.html");
my $obj  = Text::Scraper->new(tmpl => $tmpl);
my $data = $obj->scrape($src);

ok( $data->[0]{submissions}[0]{name} eq "Symbol-Values-1.01" );
ok( $data->[6]{submissions}[0]{name} eq "Sort-External-0.10_7" );

__DATA__

    <div class=path><center><table><tr>
    <?tmpl stuff a ?>
    <td class=datecell><span><big><b> <?tmpl var date-string ?> </b></big></span></td>
    <?tmpl stuff b ?>
    </tr></table></center></div>

    <ul>
    <?tmpl loop submissions ?>
     <li><a href="<?tmpl var link ?>"><?tmpl var name ?></a>
      <?tmpl if desc ?>
      <small> -- <?tmpl var description ?></small>
      <?tmpl end desc ?>
     </li>
    <?tmpl end submissions ?>
     </ul>
 