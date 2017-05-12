    use lib '../lib';    

    use Text::Scraper;

    use LWP::Simple;
    use Data::Dumper;

    my $tmpl = Text::Scraper->slurp(\*DATA);
    my $src  = get('http://search.cpan.org/recent') || die $!;
    
    my $obj  = Text::Scraper->new(tmpl => $tmpl);
    my $data = $obj->scrape($src);

    print "Newest Submission: ", $data->[0]{submissions}[0]{name},  "\n\n";
    print "Scraper model:\n",    Dumper($obj),                      "\n\n";
    print "Parsed  model:\n",    Dumper($data) ,                    "\n\n";

    __DATA__

    <div class=path><center><table><tr>
    <?tmpl stuff pre_nav ?>
    <td class=datecell><span><big><b> <?tmpl var date_string ?> </b></big></span></td>
    <?tmpl stuff post_nav ?>
    </tr></table></center></div>

    <ul>
    <?tmpl loop submissions ?>
     <li><a href="<?tmpl var link ?>"><?tmpl var name ?></a>
      <?tmpl if has_description ?>
      <small> -- <?tmpl var description ?></small>
      <?tmpl end has_description ?>
     </li>
    <?tmpl end submissions ?>
     </ul>
