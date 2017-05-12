#!/usr/bin/env perl

# Automatically generated file; changes will be lost!
# 
# source: lib/Text/Forge.pm

use utf8;
use Carp;
use autodie qw/ :all /;
# no warnings 'uninitialized';
use Test::Most;


$| = 1;

my $CLASS = 'Text::Forge';
my $SOURCE_PATH = 'lib/Text/Forge.pm';

# =begin testing
{
  use_ok $CLASS;
}



# =begin testing
{
  isa_ok $CLASS->new, $CLASS, 'constructor on class name';
  isa_ok $CLASS->new->new, $CLASS, 'constructor on instance';

  my $forge = $CLASS->new(charset => 'iso-8859-1');
  ok $forge, 'object created';
  is $forge->charset, 'iso-8859-1', 'method called from constructor';

  my @search = ('.', '/tmp');
  $forge = $CLASS->new(search_paths => \@search);
  is_deeply scalar $forge->search_paths, \@search,
    'method called from constructor with arrayref';
}



# =begin testing
{
  my @list = qw/ a b c /;
  is_deeply [ $CLASS->_list ], [], 'empty list';
  is_deeply [ $CLASS->_list(@list), ], \@list, '_list';
  is_deeply [ $CLASS->_list(\@list) ], \@list, '_list arrayref flattened';
  is_deeply [ $CLASS->_list(@list, \@list) ], [@list, @list], '_list multi';
}



# =begin testing
{
  no warnings 'once';

  my $forge = $CLASS->new;
  is_deeply [ $forge->search_paths ], \@Text::Forge::FINC,
    'search_paths, defaults to \@FINC';


  my @search = ('/tmp/view');
  $forge = $CLASS->new(search_paths => [@search, undef]);

  is_deeply [ $forge->search_paths ], \@search,
    'search_paths, list context';

  is_deeply scalar $forge->search_paths, \@search,
    'search_paths, scalar context';


  push @search, '/tmp/fallback';
  is_deeply [ $forge->search_paths(\@search) ], \@search,
    'search_paths, set';

  is_deeply [ $forge->search_paths ], \@search,
    'search_paths, list context';

  is_deeply scalar $forge->search_paths, \@search,
    'search_paths, scalar context';
}



# =begin testing
{
  no warnings 'once';

  my $forge = $CLASS->new;
  is $forge->cache, $Text::Forge::CACHE, 'cache, defaults to $CACHE';

  foreach (0, 1) {
    is $forge->cache($_), $_, "cache, set $_";
    is $forge->cache, $_, 'cache, get';
  }
}



# =begin testing
{
  no warnings 'once';

  my $forge = $CLASS->new;
  is $forge->charset, $Text::Forge::CHARSET,
    'charset, defaults to $CHARSET';

  my $charset= 'iso-8859-1';
  is $forge->charset($charset), $charset, "charset, set to '$charset'";
  is $forge->charset, $charset, 'charset, get';
}



# =begin testing
{
  my $forge = $CLASS->new;
  is $forge->layout, undef, 'layout, default undefined';

  my $layout = '/tmp/foo';
  is $forge->layout($layout), $layout, "layout, set to '$layout'";
  is $forge->layout, $layout, 'layout, get';
}



# =begin testing
{
  use File::Temp qw/ tempdir /;

  my $tmpdir = tempdir;
  chdir $tmpdir;
  mkdir 'templates';

  my $template_path = "$tmpdir/templates/home";
  open my $fh, '>', $template_path;
  print $fh "my path is $template_path";

  my $forge = $CLASS->new(search_paths => []);
  eval { $forge->_find_template('foo') };
  ok $@, '_find_template, no search paths defined';

  ok $forge->_find_template("$tmpdir/templates/home"),
    '_find_template, absolute path';

  $forge = $CLASS->new(search_paths => "$tmpdir/templates");
  ok $forge->_find_template('home'), '_find_template using search path';

  chdir "$tmpdir/templates";
  $forge = $CLASS->new(search_paths => []);
  ok $forge->_find_template('home'), '_find_template always searches cwd';
}



# =begin testing
{
  my $prefix = $CLASS->_namespace_prefix;

  is $CLASS->_namespace('/tmp'), "${prefix}::tmp", '_namespace';
  is $CLASS->_namespace('/tmp/F$<oo'), "${prefix}::tmp::F_24_3coo",
    '_namespace, escaped';
  is $CLASS->_namespace('/tmp/123/foo'), "${prefix}::tmp::_3123::foo",
    '_namespace, numeric';
}



# =begin testing
{
  my $code = $CLASS->_parse('hello');
  is $code, ' print q|hello|; ', '_parse, literal string';

  $code = $CLASS->_parse('hello|there|');
  is $code, ' print q|hello\|there\||; ',
    '_parse, literal string, pipes escaped';

  $code = $CLASS->_parse("<%\n my \$i = 0 %>");
  is $code, " \n;   my \$i = 0 ; ", '_parse, code block';

  $code = $CLASS->_parse('<%= "hello >>" %>');
  is $code, ' print Text::Forge::escape_html(undef,  "hello >>" ); ',
    '_parse, html block';

  $code = $CLASS->_parse('<%? "hello \%>" %>');
  is $code, ' print Text::Forge::escape_uri(undef,  "hello %>" ); ',
    '_parse, escaped closing tag';

  eval { $CLASS->_parse('<%Z "foo" %>') };
  ok $@, '_parse, unknown block type raises exception';

  $code = $CLASS->_parse(
    'hello |<%= "world" %> foo \<<% my $i = 0 %> zort\<'
  );
  is $code,
    (
      ' print q|hello \||; ' .
      ' print Text::Forge::escape_html(undef,  "world" ); ' .
      ' print q| foo \<|; ' .
      ' my $i = 0 ; ' .
      ' print q| zort\<|; '
    ),
    '_parse, complex multi-block'
  ;


  {
    no warnings 'once';
    local $Text::Forge::INTERPOLATE = 1;
 
    my $code = $CLASS->_parse('<% my $i = 5 %>hello $i there <% %> $i');
    is $code, ' my $i = 5 ;  print qq|hello $i there |;  ;  print qq| $i|; ',
      '_parse, interpolation enabled [DEPRECATED]';
  }
}



# =begin testing
{
  my $package = "${CLASS}::Test::NamedSub";
  my $code = "return 'foo'";

  my $template = $CLASS->_named_sub($package, '/tmp/test', $code);
  ok $template, '_named_sub, wrap template';

  my $sub = eval $template;
  ok !$@ && ref $sub eq 'CODE', '_named_sub, eval code';

  is $sub->(), 'foo', '_named_sub, call returned code reference';
  is $package->run(), 'foo', '_named_sub, call named sub';
  
}



# =begin testing
{
  my $package = "${CLASS}::Test::AnonSub";
  my $code = "return 'foo2'";

  my $template = $CLASS->_anon_sub($package, '/tmp/test2', $code);
  ok $template, '_anon_sub, wrap template';

  my $sub = eval $template;
  ok !$@ && ref $sub eq 'CODE', '_anon_sub, eval code';

  is $sub->(), 'foo2', 'call template';
  
}



# =begin testing
{
  my $mksub = eval { $CLASS->can('_mksub') };
  ok !$@ && ref $mksub eq 'CODE', '_mksub, get sub reference';

  my $rv = $mksub->("return 'foo'");
  is $rv, 'foo', '_mksub, eval code';
  
}



# =begin testing
{
  my $forge = $CLASS->new(cache => 1, charset => 'utf8');

  my $sub = $forge->_compile(\'foo');
  is ref $sub, 'CODE', '_compile, inline template';

  $forge->cache(0);
  $sub = $forge->_compile(\'foo');
  is ref $sub, 'CODE', '_compile, inline template with caching disabled';

  my $sub2 = $forge->_compile($sub);
  is ref $sub2, 'CODE', '_compile, returns code if passed code';

  eval { $forge->_compile(\'<% BAREWORD %>') };
  ok $@, '_compile, compile error should raise exception';
}



# =begin testing
{
  use Scalar::Util qw/ refaddr /;

  my $forge = $CLASS->new(cache => 1);

  eval { $forge->include(\'') };
  ok !$@, 'include, inline template';

  is $forge->include(sub { return 12 }), 12, 'include, code reference';

  $forge->cache(0);
  is $forge->include(sub { return 22 }), 22, 'include, with caching off';
  
}



# =begin testing
{
  my $forge = $CLASS->new;
  is $forge->content, undef, 'content, initially undefined';
  
  $forge->content('test', [1, 2, 3]);
  is $forge->content, 'test123', 'content, set';
}



# =begin testing
{
  my $forge = $CLASS->new;
  $forge->charset('utf8');

  is $forge->capture(\'<% print "foo" %>'), 'foo', 'capture, inline template';

  is $forge->capture(sub { print 'foo' }), 'foo', 'capture, code ref';

  is $forge->capture(sub { print 'exposé, Zoë, à propos' }),
    'exposé, Zoë, à propos', 'capture, unicode';

  $forge->charset('');
  is $forge->capture(\'hi'), 'hi', 'capture, no charset set';
}



# =begin testing
{
  my $forge = $CLASS->new;

  $forge->content_for('nav', 'foo');
  is $forge->content_for('nav'), 'foo', 'content_for, string';

  $forge->content_for('nav', 'zort');
  is $forge->content_for('nav'), 'foozort', 'content_for, content appended';

  $forge->content_for('nav', sub { print 'blort' });
  is $forge->content_for('nav'), 'foozortblort', 'content_for, code ref';

  $forge->content_for('nav', [qw/ a b c /]);
  is $forge->content_for('nav'), 'foozortblortabc', 'content_for, array ref';

  eval { $forge->content_for };
  ok $@, 'content_for, name required';
}



# =begin testing
{
  my $forge = $CLASS->new;

  $forge->{content} = 'document';
  $forge->layout(\'<body><%= $self->content_for("main") %></body>');
  $forge->_apply_layout;
  is $forge->content, '<body>document</body>', '_apply_layout';

  $forge->layout(\'<body><% BAREWORD %></body>');
  eval { $forge->_apply_layout };
  ok $@, '_apply_layout, layout compile error should raise exception'; 
}



# =begin testing
{
  my $forge = $CLASS->new;

  is $forge->run(\'content'), 'content', 'run, no blocks';
  $forge->run(\'content'); # call in null context for test coverage

  # with layout
  $forge->layout(\'<body><%$ $self->content_for("main") %></body>');
  is $forge->run(\'content'), '<body>content</body>', 'run, with layout';

  # nested layouts
  $forge->layout(\q{
    <% $self->layout(\'<body><%$ $self->content_for("main") \%></body>') %>
    <nav><%$ $self->content_for("main") %></nav>
  });
  my $content = $forge->run(\'menu');
  $content =~ s/^\s*//mg;
  is $content, "<body>\n<nav>menu</nav>\n</body>",
    'run, nested layouts';
}



# =begin testing
{
  {
    package Text::Forge::Test::Object;

    sub new { my $class = shift; bless { @_ }, ref($class) || $class }

    sub as_html { $_[0]->{content} }
    sub as_uri { $_[0]->{content} }
  }


  my $escaped = $CLASS->escape_uri('name=foo?<>');
  is $escaped, 'name%3Dfoo%3F%3C%3E', 'escape_uri, unsafe chars escaped';

  my @escaped = $CLASS->escape_uri('?foo', 'zort=');
  is_deeply \@escaped, ['%3Ffoo', 'zort%3D'], 'escape_uri, wantarray';

  my $o = Text::Forge::Test::Object->new(content => '?name=foo');
  is $CLASS->escape_uri($o), '?name=foo',
    'escape_uri, object provides uri-escaped content with as_uri()';
}



# =begin testing
{
  my $escaped = $CLASS->escape_html(
    q{<script type='text/javascript' id="xss">hi</script>}
  );
  is $escaped,
     '&lt;script type=&#39;text/javascript&#39; ' .
       'id=&quot;xss&quot;&gt;hi&lt;/script&gt;',
     'escape_html, unsafe chars escaped';

  my @escaped = $CLASS->escape_html('<foo', 'zort"');
  is_deeply \@escaped, ['&lt;foo', 'zort&quot;'], 'escape_uri, wantarray';

  my $o = Text::Forge::Test::Object->new(content => '<h1>Header</h1>');
  is $CLASS->escape_html($o), '<h1>Header</h1>',
    'escape_html, object provides html-escaped content with as_html()';
}



# =begin testing
{
  my $output;
  {
    local *STDOUT;
    open STDOUT, '>', \$output;

    $CLASS->new->send(\'content');
  }

  is $output, 'content', 'send [DEPRECATED]';
}



# =begin testing
{
  is $CLASS->new->trap_send(\'foo'), 'foo', 'trap_send [DEPRECATED]';
}


# prevent "semicolon seems to be missing" error if test block only has comment
;

Test::More::done_testing();

1;

