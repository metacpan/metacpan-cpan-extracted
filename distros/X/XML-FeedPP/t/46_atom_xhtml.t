# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 20;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
{
    my $sample = <<'EOT';
<?xml version="1.0" encoding="UTF-8" ?>
<feed xmlns="http://www.w3.org/2005/Atom">
   <title type="xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
     <xhtml:div>
       Less: <xhtml:em>&lt;</xhtml:em>
     </xhtml:div>
   </title>
   <entry>
    <content type="xhtml" xml:lang="en"
      xml:base="http://diveintomark.org/">
      <div xmlns="http://www.w3.org/1999/xhtml">
        <p><i>[Update: The Atom draft is finished.]</i></p>
      </div>
    </content>
  </entry>
  <entry>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">
        This is <b>XHTML</b> content.
      </div>
    </content>
  </entry>
  <entry>
    <content type="xhtml">
      <xhtml:div xmlns:xhtml="http://www.w3.org/1999/xhtml">
        This is <xhtml:b>XHTML</xhtml:b> content.
      </xhtml:div>
    </content>
  </entry>
  <entry>
    <content type="xhtml">
      <xh:div>
        This is <xh:b>XHTML</xh:b> content.
      </xh:div>
    </content>
  </entry>
</feed>
EOT

    my $feed = XML::FeedPP->new( $sample );

    my $title = $feed->title;
    is(ref $title, 'HASH', 'feed title is HASH');
    ok(! exists $title->{'xhtml:div'}, 'feed title does NOT have div');
    like($title->{'xhtml:em'}, qr/</, 'feed title /xhtml:div/xhtml:em');

    my $item;
    my $desc;
    my @entry = $feed->get_item;
    is( scalar(@entry), 4, 'feed get_item' );

    # entry 1
    $item = shift @entry;
    $desc = $item->description;
    is(ref $desc, 'HASH', 'entry 1 /content is HASH');
    ok(! exists $desc->{'div'}, 'entry 1 /content does NOT have /div');
    ok(exists $desc->{p}, 'entry 1 /content/div/p');
    is($desc->{-xmlns}, 'http://www.w3.org/1999/xhtml', 'entry 1 /content/div/@xmlns');
    is($desc->{p}->{i}, '[Update: The Atom draft is finished.]', 'entry 1 /content/div/p/i');

    # entry 2
    $item = shift @entry;
    $desc = $item->description;
    is(ref $desc, 'HASH', 'entry 2 /content is HASH');
    ok(! exists $desc->{'div'}, 'entry 2 /content does NOT have /div');
    is($desc->{-xmlns}, 'http://www.w3.org/1999/xhtml', 'entry 2 /content/div/@xmlns');
    is($desc->{b}, 'XHTML', 'entry 2 /content/div/b');

    # entry 3
    $item = shift @entry;
    $desc = $item->description;
    is(ref $desc, 'HASH', 'entry 3 /content is HASH');
    ok(! exists $desc->{'xhtml:div'}, 'entry 3 /content does NOT have /xhtml:div');
    is($desc->{'xhtml:b'}, 'XHTML', 'entry 3 /content/div/b');

    # entry 4
    $item = shift @entry;
    $desc = $item->description;
    is(ref $desc, 'HASH', 'entry 4 /content is HASH');
    ok(! exists $desc->{'xh:div'}, 'entry 4 /content does NOT have /xh:div');
    is($desc->{'xh:b'}, 'XHTML', 'entry 4 /content/div/b');
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
