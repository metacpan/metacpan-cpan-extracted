package Text::YAWikiFormater;

use 5.006;
use strict;
use warnings;

use HTML::Entities qw(encode_entities);
use JSON qw(from_json);

our $VERSION = '0.50';

my %plugins = (
    toc    => \&_handle_toc,
    image  => \&_handle_image,

    restore_code_block  => \&_restore_code_block,
  );

my %namespaces = (
    wp  => { prefix => 'http://en.wikipedia.org/', category=>':' },
		gs	=> { prefix => 'http://www.google.com/search?q=' },
  );

my %closed = (
    b    => qr{(?:(?<!\s)\*\*|\*\*(?!\s))}msix,
    i    => qr{(?<!:)//},
    u    => qr{__},
    del  => qr{(?<!\-)\-\-(?!\-)},
    tt  => qw{''},

    heads  => [qr[^(?=!{1,6}\s)]msix, qr[$]msix, \&_header_id, undef,"\n"],

    code  => [qr[^\{\{\{$]msix,qr[^\}\}\}$]msix, \&_escape_code],

    blockquote  => [qr{^&gt;\s}msix, qr{^(?!&gt;)}msix, qr{^&gt;\s}msix, '',"\n"],

    lists  => [qr{^(?=[\*\#]+\s)}msix, qr{(?:^(?![\*\#\s])|\z)}msix, \&_do_lists],

    links    => [qr{(?=\[\[)}, qr{(?<=\]\])},\&_do_links],
    links2  => [qr{\s(?=http://)}, qr{\s},\&_do_links],

    br    => [qr{^(?=$)}msix, qr[$]msix, sub { "<br/><br/>",'',''}],

    comments  => [qr{/\*}msix, qr{\*/}msix, sub{ '','',''}],
  );

my %nonclosed = (
    hr  => qr{^[-\*]{3,}\s*?$}msix,
  );

my @do_first = qw( code lists );

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  die "body is a mandatory parameter" unless $self->{body};

  return $self;
}

sub urls {
  my $self= shift;
  my $body = $self->{body};

  return unless $body;

  my @links = $body =~m{(\[\[(?:\S[^\|\]]*)(?:\|(?:[^\]]+))?\]\])}g;
  push @links, $body =~m{\s(https?://\S+)\s}g;

  my $links = $self->{_links} ||= {};

  LINK:
  for my $lnk ( @links ) {
    next if $links->{$lnk};

    my $hlnk = $links->{$lnk} ||= {};

    if ($lnk =~ m{\Ahttps?://}) {
      %$hlnk = ( title => $lnk, href => $lnk, _class => 'external' );
      next LINK;
    }
    
    ($lnk) = $lnk =~ m{\A\[\[(.*)\]\]\z}g;
    my ($label,$link) = split qr{\|}, $lnk, 2;
    unless ($link) {
      $link = $label;
      if ( $link =~ m{.*[\>\:]([^\>]+)\z} ) {
        $label = $1;
      }
    }

    $hlnk->{title} = $label;
    $hlnk->{original_to} = $link;
    if ($link =~ m{\Ahttps?://} ) {
      $hlnk->{_class} = 'external';
      $hlnk->{href}    = $link;
      next LINK;
    }

    my ($base,$categ) = ('','/');
    if ( $link =~ m{\A(\w+):} ) {
      my ($namespace,$lnk) = split qr{:}, $link, 2;
      $link = $lnk;
      if ( my $nmsp = $namespaces{ $namespace } ){
        if (ref $nmsp eq 'HASH' ) {
          $base   = $nmsp->{prefix}   if $nmsp->{prefix};
          $categ   = $nmsp->{category} if $nmsp->{category};
        } elsif (ref $nmsp eq 'CODE') {
          ($base, $categ, $lnk) = $nmsp->($namespace,$link);
          if ( $lnk and $lnk =~ m{\Ahttps?://} ) {
            $hlnk->{href} = $lnk;
            $hlnk->{_class}='external';
            next LINK;
          } elsif ( $lnk ) {
            $link = $lnk;
          }
        }

      } else {
        warn "Unknow namespace: $namespace on $lnk\n";
      }
    }
    
    if ( $categ ) {
      $link =~ s{\>}{$categ}g;
    }
    if ( $base ) {
      $link = $base.$link;
    }
    unless ( $link =~ m{\Ahttps?://} ) {
      $link = urify( $link );
    }
    $hlnk->{href} = $link;
  }

  return wantarray ? %{$self->{_links}} : $self->{_links};
}

sub urify {
  my $link = shift;
  my $reg = shift || "^\\w\\-\\/\\s\\#";

  $link =~ s{\s*>\s*}{/}g unless $link =~ m{/};

  $link = encode_entities( $link, $reg );
  $link =~ s{\s+}{-}g;
  while (my ($ent)=$link=~/\&(\#?\w+);/) {
    my $ec=$ent=~/(acute|grave|circ|uml|ring|slash|tilde|cedil)$/i?
      substr($ent,0,1):'_';
    $link=~s/\&$ent;/$ec/ig;
  }
  $link="\L$link";
  $link=~s/\_+$//g;
  $link=~s/\_+/\_/g;

  return $link;
}

sub set_links {
  my ($self, $links) = @_;

  $self->{_links} = $links;

  return;
}

sub format {
  my $self = shift;
  my $body = $self->{body};

  delete $self->{__headers};
  delete $self->{__toc};

  my %done = ();

  $body =~ s{&}{&amp;}g;
  $body =~ s{<}{&lt;}g;
  $body =~ s{>}{&gt;}g;

  # closed tags
  for my $tag ( @do_first, keys %closed ) {
    next if $done{ $tag }++;

    my ($re1, $re2, $re3, $re4, $re5, $re6)
      = ref $closed{ $tag } eq 'ARRAY'
      ? @{ $closed{ $tag } }
      : ( $closed{ $tag } );

    if (!$re2) {
      my $in = 0;
      while ( $body =~ m{$re1}msix ) {
        my $tg = $in ? "</$tag>" :"<$tag>";
        $body=~s{$re1}{$tg}msix;
        $in = 1 - $in;
      }
      $body.="</$tag>" if $in;
    } else {
      while ($body =~ m{$re1(.*?)$re2}msix) {
        my $in = $1;
        my ($t1,$t2) = ("<$tag>","</$tag>");
        if (ref $re3 eq 'Regexp') {
          $re4 //= '';
          $in =~ s{ $re3 }{$re4}msixg;
        } elsif (ref $re3 eq 'CODE') {
          ($t1,$in,$t2) = $re3->($self, $t1, $in, $t2);
        }
        $re5 //= '';
        $body =~ s{$re1(.*?)$re2}{$t1$in$t2$re5}smxi;
      }
    }
  }

  for my $tag ( keys %nonclosed ) {
    my ($re1) = ($nonclosed{ $tag } );

    $body =~ s{ $re1 }{<$tag />}msixg;
  }

  while ($body =~ m[(?<!\{)\{\{(\w+)(?:[:\s](.+))?\}\}(?!\})]msix) {
    my ($plugin, $params) = ($1,$2);
    $params = _parse_plugin_params($params);

    my $res = '';
    if ( $plugins{$plugin} ){
      $res = $plugins{ $plugin }->( $self, $plugin, $params ) // '';
    }

    $body =~ s[(?<!\{)\{\{(\w+)(?:[:\s](.+))?\}\}(?!\})][$res]msix;
  }

  while ($body =~ m[\/\+\+(\w+)(?:[:\s*](.+))?\+\+\/]msix) {
    my ($plugin, $params) = ($1,$2);
    $params=~s{\A\s*}{};
    my @params = split qr{\s*,\s*}, $params;

    my $res = '';
    if ( $plugins{$plugin} ){
      $res = $plugins{ $plugin }->( $self, $plugin, @params ) // '';
    }

    $body =~ s[\/\+\+(\w+)(?:[:\s*](.+))?\+\+\/][$res]msix;
  }
  
  return $body;
}

sub register_namespace {
  my $class = shift;

  my ($namespace, $info, $override) = @_;

	$namespaces{ $namespace } = $info
		if $override or !$namespaces{ $namespace };
}

sub register_plugin {
	my $class = shift;

	my ($pluginname, $pluginref, $override) = @_;

	$plugins{ $pluginname } = $pluginref
		if $override or !$plugins{ $pluginname };
}

sub _header_id {
  my $self = shift;
  my $headers   = $self->{__headers}       ||= {};
  my $headnames  = $self->{__headnames}     ||= {};
  my $toc       = $self->{__toc}           ||= [];
  my ($t1, $in, $t2) = @_;

  my ($type) = $in =~ m{^(!{1,6})\s};
  $in =~ s{^!*\s}{};

  $t1 = 'h'.length($type);
  $t2 = "</$t1>";
  $t1 = "<$t1>";

  my $id = urify($in, "^\\w\\-\\s");

  if ($headers->{$id}) {
    my $cnt = 1;
    $cnt++ while $headers->{"${id}_$cnt"};
    $id .= "_$cnt";
  }

  $headnames->{$id} = $in;
  $headers->{$id}   = substr($t1, 2, 1);
  push @$toc, $id;

  substr($t1, -1, 0, " id='$id'");

  return $t1, $in, $t2;
}

sub _escape_code {
  my $self = shift;

  my ($t1, $in, $t2) = @_;

  $in=~s{\n}{<br/>\n}gs;

  $self->{__codecnt}++;
  $self->{__codeblock}->{$self->{__codecnt}} = $in;

  return '',"/++restore_code_block: $self->{__codecnt}++/", '';
}

sub _do_lists {
  my $self = shift;

  my ($t1, $in, $t2) = @_;

  my @lines = split qr{\n}ms, $in;
  $in = '';
  my $cl = '';
  my $item;
  for my $ln (@lines) {
    if ( $ln !~ m{^\s} ) {
      if ($item) {
        $in .= "<li>$item</li>\n";
        $item = '';
      }
      my ($nl,$l) = $ln =~ m{^([\*\#]+)\s+(.*)$};
      $ln = $l;
      my $close = '';
      my $start = -1;
      if ($nl ne $cl) {
        for my $i (0..length($cl)-1) {
          next if !$close and substr($cl,$i,1) eq substr($nl, $i, 1);
          $start = $i unless $close;
          $close = (substr($cl,$i,1) eq '#' ? "</ol>" : "</ul>").$close;
        }
        $start = length($cl) if $start == -1;
        $in.=$close."\n" if $close;
        for my $i ($start..length($nl)-1) {
          $in.= substr($nl, $i, 1) eq '#'?"<ol>":"<ul>";
        }
        $cl = $nl;
      }
    }
    $item .= $ln;
  }
  if ($item) {
    $in .= "<li>$item</li>\n";
  }
  if ($cl) {
    for my $i (reverse 0..length($cl)-1) {
      $in.=substr($cl,$i,1) eq '#' ? "</ol>" : "</ul>";
    }
    $in.="\n";
  }

  return '',$in,'';
}

sub _do_links {
  my $self = shift;

  my (undef, $link, undef) = @_;

  $self->urls() unless $self->{_links} and $self->{_links}->{$link};

  my $lnk = $self->{_links}->{$link} || {};

  my ($t1,$t2) = ('','</a>');

  $t1 = "<a href='$lnk->{href}'";
  my $class = $lnk->{class} || $lnk->{_class} || '';
  if ( $class ) {
    $t1.=" class='$class'";
  }
  $t1.='>';

  return $t1, $lnk->{title}, $t2;
}

sub _handle_toc {
  my ($self) = shift;

  my $toc       = $self->{__toc};
  my $headers   = $self->{__headers};
  my $headnames  = $self->{__headnames};

  my $res = "\n";
  for my $head (@$toc) {
    $res.='*'x$headers->{$head};
    
    $res.=' ';
    $res.='[['.$headnames->{$head}.'|#'.$head."]]\n";
  }
  $res.="\n";

  my $wf = (ref $self)->new(body => $res);
  $res = $wf->format();

  $res = "<div class='toc'>$res</div>";

  return $res;
}

sub _handle_image {
  my ($self, $plugin, $params) = @_;
  my $src;

  if (ref $params eq 'ARRAY') {
    $src = shift @$params;
    if (@$params and ref $params->[0] eq 'HASH') {
      $params = $params->[0];
    } else {
      $params = { @$params };
    }
  } else {
    $src = delete $params->{src};
  }

  return '<!-- no src - incorrect params? -->' unless $src;

  if ($src =~ m{\Ahttps?://} and $self->{image_filter}) {
    $src = $self->{image_filter}->($src, $params);
  } elsif ($self->{image_mapper}) {
    $src = $self->{image_mapper}->($src, $params);
  }

  return '<!-- image filtered/not mapped -->' unless $src;

  my $res = "<img src='$src'";
  if ( $params->{size} ) {
    my ($w,$h) = $params->{size} =~ m{\A\d+x\d+\z};

    if ($w and $h) {
       $params->{width}   ||= $w;
      $params->{height} ||= $h;
       delete $params->{size};
    }
  }
  for my $attr ( qw(alt title heigth width) ) {
    next unless $params->{ $attr };
    my $av = $params->{ $attr };
    $av =~ s{&}{&amp;}g;
    $av =~ s{<}{&gt;}g;
    $av  =~ s{>}{&lt;}g;
    $av =~ s{'}{&#39;}g;
    $res.=" $attr='$av'";
  }

  $res.=' />';

  #MAYBETODO: support for caption, to allow to frame the images
  # and add a legend under the image.

  return $res;
}

sub _restore_code_block {
  my ($self, $plugin, $block) = @_;

  my $res = $self->{__codeblock}->{$block};

  return "<code>$res</code>";
}

sub _parse_plugin_params {
  my $paramstr = shift;

  return [] unless $paramstr;

  unless ($paramstr =~ m(\A\s*[\{\[]) ) {
    $paramstr = '['.$paramstr.']';
  }

  my $params = eval {
      from_json( $paramstr, { utf8 => 1 })
    } or do print STDERR "Error Parsing params: $paramstr ==> $@\n";
    #MAYBETODO: export this error somehow? silent it?
    # exporting it may be useful - specially while previewing
    # the result.

  return $params;
}

1;
__END__
=head1 NAME

Text::YAWikiFormater - The great new Text::YAWikiFormater!

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Text::YAWikiFormater;

    my $wiki = Text::YAWikiFormater->new( body => $wikitext );

    my $html = $wiki->format();

=head1 METHODS

=head2 new(body => $wikitext)

Creates the YAWikiFormater object. It accepts the parameters:

=over 4

=item B<body>

body is the wiki text you want to transform into HTML. This parameter
is mandatory.

=back

=head2 $wiki->urls( )

B<urls> extracts all the recognized links from the wikitext and returns
an data structure that you can use to change the parameters that will be
used to generate the final <a> tags on the generated HTML

  my %links = $wiki->urls();
  for my $lnk (value %links) {
    if ($lnk->{_class} eq 'external'
        and $lnk->{href}=~m{wikipedia\.org}) {
      $lnk->{class} = 'external_wikipedia';
      $lnk->{title}.=' (Wikipedia)';
    }
  }
  $wiki->set_links( \%links );

The returned hash contains the link definition text (from your body)
as keys and hashes with the data that will be used to create the <a>
tags as values. On those hashes the following keys are supported:

=over 4

=item B<href>

the url the link will link to (really, the href of the <a> tag).

=item B<class>

the css class that will be used for this link - this is never ser
by C<Text::YAWikiFormater> - it set I<_class> instead, and uses that
if I<class> is not set. _class is set to C<external> for any links
starting with http:// or https://

=item B<title>

I<title> is the content of the link.

=back

=head2 $wiki->set_links( \%links );

B<set_links> is the companion of B<urls( )>. It allows you to update
the changes you made on the structure returned by urls back in the
object, before calling B<format>.

=head2 $url = urify($text)

B<urify> is the method used internally to transform wiki titles into wiki
urls - it is export to allow to allow the same algorithm to be used
by any application that uses the TYAWF to generate URLs from text (title
of documents, for instance).

=head2 $html = $wiki->format( )

B<format> does all the work - well, centralizes it at least. format gets
body from the $wiki object, transforms it and returns the resulting HTML
code.

=head2 CLASS->register_namespace( $namespace, $info, $override );

B<register_namespace> allow to register namespaces for links.

  Text::YAWikiFormater->register_namespace(
      'gs', # for google search
      { prefix => 'http://www.google.com/search?q=' },
      0
    );

This code would allow to create links like C<gs:Some Search>, and that
would link to the google search results page for "Some Search".

B<$info> can be a CODE ref or a HASH ref.

=over 4

=item B<CODE>ref

When $info is a coderef, it will be called with the link to expand and is
expected to return C<$base, $category, $link>. where:

=over 4

=item B<$base>

B<$base> is the base for the URL we want to link to.

=item B<$category>

B<$category> is the category separator, in case that is supported by the
website represented by the namespace.

=item B<$link>

B<$link> can can a relative or an asbolute URL to the resource you want
to link to. if C<$link> is an absolute URL, starting with http(s)://
the other two values will be ignored and the returned $link will be used.

=back

  Text::YAWikiFormater->register_namespace(
    'tiny',
    sub {
      my ($namespace,$url) = @_;

      #generate or get from cache tinyURL

      return (undef, undef, $tinyurl);
    },
    0
  );

=item B<HASH>ref

When B<$info> is a HASHref, the following keys are supported on that hashref:

=over 4

=item B<prefix>

B<prefix> is the base url that will be used to generate the links.

=item B<category>

B<category> is the category separator. For instance, on Wikipedia, it would
be ':'.

This allow you to always use '>' as the category separator in your wiki
text and later have that replaced for you to the correct separator needed
for you linked website.

=back

=back

=head2 CLASS->register_plugin( $name, $handler, $override );

register_plugin allow to extend YAWikiFormater syntax, and to add any
type of functionality into the wiki syntax itself.

Text::YAWikiFormater (B<TYAWF>) allows for plugins using the following
syntax in the wiki text:

  {{plugintag: params }}

So, when you register a plugin, you are just creating an entry in the
resolution table between your plugintag and the CODEref that implements
that plugin.

If your plugin doesn't need paramters, it will be called on the wikitext
just with:

  {{yourplugin}}

B<params>, when existing, must be a list of valid JSON elements. If it is
a JSON object ({}), it will be used, otherwise it will be transformed
into a JSON array (by adding '[' in the begining and ']' on the end).

  Text::YAWikiFormater->register_plugin(
      'youtube',
      sub {
        my ($wiki, $plugin, $params) = @_;

        return "<embed ...></embed>";
      },
      0
    );

=head1 WIKI SYNTAX

=head2 headers

TYAWF supports six levels of headers (h1..h6).

Headers are defined using ! in the begining of the line.

  ! header 1
  !! header 2
  !!! header 3
  !!!! header 4
  !!!!! header 5
  !!!!!! header 6

=head2 bold, italic, ...

TYAWF supports bold, italic, underline, strike, and monospaced.

  **bold**
  //italic//
  __underline__
  --deleted--
  ''monospaced''

=head2 code

TYAWF supports also code blocks - to define a code block use {{{ and }}}

  {{{
    my $wiki = Text::YAWikiFormater->new( body => $wikitext );
  }}}

  None of the wiki formating works inside of code blocks.

  {{{
    **bold** should be bold, but not inside a code block.
  }}}

=head2 blockquote

TYAWF also have support for blockquote. You can create blockquotes starting
each line of the quote with '> '.

  > this will be a blockquote

Multiple levels are supported:

  > This is a quote quoting another quote
  > > and this is the quote quoted in the quote.
  >
  > And this is something else
  >

=head2 lists

TYAWF supports unordered lists:

  * some item
  * some other item

as well as ordered lists

  # item 1
  # item 2

you can use multiple levels and mix the types:

  * some item
  ** some sub item
  * some ordered items
  *# item 1
  *# item 2
  *## item 2.1

=head2 links

TYAWF supports links from full urls:

  http://www.google.com

As well as creating links using [[ | ]] syntax. TYAWF linking system is
tought to be a Wiki linking system, simple, expandable and flexible.

So, lets start with the simple:

  [[Some Page Title]]

This will create a link to some-page-title, the place where is expectable
that the page with that title is stored.

B<Note>: This page is in the same directory as the current page. That's
because TYAWF also support categories and allows to link to pages in
different categories using a similar syntax:

  [[Subcategory > Some Other Page]]

This will link to subcategory/some-other-page - still, a page of a
subcategory of the current category.

  [[> Main Category > SubCategory > Some Page]]

This would create a link to /main-category/subcategory/some-page - this
time  URL relative to the root of the site.

Whenever possible, while generating URLs TYAWF will strip the accents
and use the base letters on the URLs.

But, some times, you want to have a different title on your link
than the title of the page you want to link to - for those cases
TYAWF gives you the option to specify both the title and the link:

  [[Syntax|/wiki/syntax]]
 
This would create a link to /wiki/syntax with the title Syntax. You can
use the same syntax to link to external websites:

  [[Google Search|http://www.google.com]]

And this is before introducting the namespaces - the still missing piece.
TYAWF also support namespaces, that work like alias for other websites.

By default TYAWF defines namespaces for wikipedia (wp) and google
search (gs), so these are valid links:

  [[wp:Portal>Arts]]

  [[gs:Text YAWikiFormater]]

See above L<register_namespace> on how to register more namespaces.

=head2 images

TYAWF also supports images, and those are implemented using the syntax
for the plugins - it's simple to do that way as we already would support
parameters on the plugins, and those are interesting for images.

  {{image: "/path/to/image.png" }}

  {{image: "/path/to/image.png", size="400x250", alt="Some alternative text" }}

Images plugin supports the following parameters:

=over 4

=item * size, width and heigth

B<size> is expected to be {width}x{height}. It doesn't override the values
of either width or height if they also exist.

=item * alt

=item * title

=back

=head2 toc

toc will generate a list with link to all the headers on the wikitext.

  {{toc}}

It doesn't take any parameters.

=head2 plugins

As you can guess from both B<image> and B<toc>, both implemented as if they
where plugins, the syntax to call plugins is:

  {{pluginname: params }}

The params are options. you should refer to the plugins documentation
to find out which parameters they support - when someone implements
any plugins.

=head1 WHY, BUT WHY?

ok, now that the documentation is over, I'm sure there are some of you
who may ask I do we need, in the good perl tradition, Yet Another Wiki
Formater.

The main reason is that I didn't like the syntax of any of those I tested.


=head1 AUTHOR

Marco Neves, C<< <perl-cpan at fwd.avidmind.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-yawikiformater at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-YAWikiFormater>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::YAWikiFormater

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-YAWikiFormater>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-YAWikiFormater>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-YAWikiFormater>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-YAWikiFormater/>

=back


=head1 ACKNOWLEDGEMENTS

I would like to acknowledge that I got a lot of ideas from a lot of
projects, probably the one I got more from was dokuwiki, even if in
some cases I did exactly the oposite of what they do.

=head1 MAYBE TODO

=over 4

=item a few plugins

Plugin to add webvideos (youtube, dailymotion, etc), maybe a few more - give
me ideas.

=item a few more tests

Even if the basics of the syntax is covered by the current few tests, a
few things are surelly not being tested yet - also I'm sure that with
time we will be able to find a few test cases that break the formater -
we'll need to create tests for thoses and fix them.

Send me the tests and I'll fix them.

=item webapp using TYAWF

That's actually the pet project I was working on when I started this one.
It'll be online soon, I hope - yes, it will be opensource as well.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Neves.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

