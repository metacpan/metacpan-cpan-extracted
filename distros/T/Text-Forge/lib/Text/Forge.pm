package Text::Forge;
# ABSTRACT: Templates with embedded Perl


#{{{ test


#}}}

use 5.16.0; # unicode eval
use strict;
use warnings;
use utf8;
use autodie qw/ :all /;
use Carp;
use Encode ();
use File::Spec ();
use HTML::Entities ();
use URI::Escape ();

our $VERSION = '6.02';

our @FINC = ('.'); # default search paths
our %FINC; # compiled template cache

our $CACHE = 1; # cache compiled templates by default

our $CHARSET = 'utf8';

our $INTERPOLATE = 0; # deprecated; leave off


# define template block operators
our %OPS;
{

  my $code = sub { qq{ $_[0]; } };

  %OPS = (
    '$' => sub { 
      qq{ print $_[0]; }
    },
  
    '%'  => $code,
    " "  => $code,
    "\n" => $code,
    "\r" => $code,
    "\t" => $code,
  
    '=' => sub {
      # Call method as function; faster
      qq{ print Text::Forge::escape_html(undef, $_[0]); } 
    },

    '?' => sub {
      # Call method as function; faster
      qq{ print Text::Forge::escape_uri(undef, $_[0]); }
    },

    '#' => sub { $_[0] =~ s/[^\r\n]//g; $_[0]; },
  );
}


#{{{ test


#}}}

sub new {
  my $class = shift;
  my %args = @_;
  
  $class = ref($class) || $class;
  my $self = bless {}, $class;

  while (@_) {
    my ($method, $args) = splice @_, 0, 2;
    $self->$method(ref $args eq 'ARRAY' ? @$args : $args);
  }

  return $self;
}


#{{{ test


#}}}

sub _list {
  my $class = shift;

  return map { ref $_ eq 'ARRAY' ? @$_ : $_ } @_;
}


#{{{ test


#}}}

sub search_paths {
  my $self = shift;

  if (@_) {
    $self->{search} = [
      grep { defined && length }
      $self->_list(@_) 
    ];
  }

  my $paths = exists $self->{search} ? $self->{search} : \@FINC;
  return wantarray ? @$paths : $paths;
}


#{{{ test


#}}}

sub cache {
  my $self= shift;

  $self->{cache} = shift if @_;
  return $self->{cache} // $CACHE;
}


#{{{ test


#}}}

sub charset {
  my $self= shift;

  $self->{charset} = shift if @_;
  return $self->{charset} // $CHARSET;
}


#{{{ test


#}}}

sub layout {
  my $self= shift;

  $self->{layout} = shift if @_;
  return $self->{layout};
}


#{{{ test


#}}}

sub _find_template {
  my $self = shift;
  my $path = shift;

  foreach my $search ($self->search_paths, undef) {
    my $fpath = File::Spec->rel2abs($path, $search);
    return $fpath if $fpath and -f $fpath;
  }

  my @search = $self->search_paths;
  croak "Can't locate template '$path' (search paths: @search)";
}


sub _namespace_prefix { 'TF' }


#{{{ test


#}}}

# From Apache::Registry
# Assumes: $fpath is absolute, normalized path as returned by _find_template()
sub _namespace {
  my $self = shift;
  my $fpath = shift;

  # Escape everything into valid perl identifiers
  $fpath =~ s/([^A-Za-z0-9_\/])/sprintf("_%02x", ord $1)/eg;

  # second pass cares for slashes and words starting with a digit
  $fpath =~
    s{ (/+)(\d?) }
     { '::' . (length $2 ? sprintf("_%02x", ord $2) : '') }egx;

  return $self->_namespace_prefix . $fpath;
}


#{{{ test


#}}}

# This parsing technique is discussed in perlop
sub _parse {
  my $class = shift;
  local $_ = shift;

  no warnings 'uninitialized';

  my @code;
  my $line = 0;
  LOOP: {
    # Match token
    if (/\G<%(.)(.*?)(?<!\\)%>([ \t\r\f]*\n)?/sgc) {
      exists $OPS{ $1 } or die "unknown forge token '$1' at line $line\n";

      # If the op is a linefeed we have to keep it to get line numbers right
      push @code, $OPS{'%'}->($1) if $1 eq "\n";

      push @code, $OPS{ $1 }->(map { s/\\%>/%>/g; $_ } "$2");
      push @code, $OPS{'%'}->($3) if length $3; # maintain line numbers 
      $line += "$1$2$3" =~ tr/\n//;
      redo LOOP;
    }

    # Match anything up to the beginning of a token
    if (/\G(.+?)(?<!\\)(?=<%)/sgc) {
      my $str = $1;
      $str =~ s/((?:\\.)|(?:\|))/$1 eq '|' ? '\\|' : $1/eg;
      push @code, $OPS{'$'}->($INTERPOLATE ? "qq|$str|" : "q|$str|");
      $line += $1 =~ tr/\n//;
      redo LOOP;
    }

    my $str = substr $_, pos;
    $str =~ s/((?:\\.)|(?:\|))/$1 eq '|' ? '\\|' : $1/eg;
    if (length $str) {
      push @code, $OPS{'$'}->($INTERPOLATE ? "qq|$str|" : "q|$str|");
    }
  }

  return join '', @code;
}


#{{{ test


#}}}

sub _named_sub {
  my($self, $package, $path, $code) = @_;

  return join '',
    "package $package;\n\n",
    "use strict;\n",
    "use Carp;\n\n",
    "sub run {\n",
    "  my \$self = shift;\n",
    qq{\n# line 1 "$path"\n},
    "  $code",
    "\n}\n",
    "\\&run;", # return reference to sub
  ;  
}


#{{{ test


#}}}

sub _anon_sub {
  my($self, $package, $path, $code) = @_;

  return join '',
    "return sub {\n",
    "  package $package;\n",
    "use strict;\n",
    "use Carp;\n\n",
    "  my \$self = shift;\n",
    qq{# line 1 "$path"\n},
    "  $code",
    "\n}\n",
  ;
}


#{{{ test


#}}}

# we isolate this to prevent closures in the new sub. better way?
sub _mksub { eval $_[0] }


#{{{ test


#}}}

sub _compile {
  my($self, $path) = @_;

  my $ref = ref $path;

  return $path if $ref eq 'CODE';

  if ($ref eq 'SCALAR') { # inline template?
    my $package = $self->_namespace($path);
    my $code = $self->_parse($$path);
    $code = $self->_anon_sub($package, $path, $code);
    #warn "\n\nCODE:\n$code\n\n";
    my $sub = Text::Forge::_mksub($code);
    croak "compilation of inline template failed: $@" if $@;

    # XXX Should we clear the cache if it becomes too large?
    $FINC{ $path } = $sub if $self->cache;
    return $sub;
  }

  my $fpath = $self->_find_template($path);
  my $package = $self->_namespace($fpath);

  my $charset = $self->charset;
  $charset = ":encoding($charset)" if $charset;

  open my $fh, "<$charset", $fpath;
  my $source = do { local $/; <$fh> };
  my $code = $self->_parse($source, $fpath);
  $code = $self->_named_sub($package, $fpath, $code);

  #warn "CODE\n#########################\n$code\n############################\n";
  my $sub = Text::Forge::_mksub($code);
  croak "compilation of forge template '$fpath' failed: $@" if $@;

  $FINC{ $path } = $sub if $self->cache;
  return $sub;
}


#{{{ test


#}}}

sub include {
  my $self = shift;
  my $path = shift;

  delete $FINC{ $path } unless $self->cache;

  my $sub = ref $path eq 'CODE' 
              ? $path
              : $FINC{ $path } || $self->_compile($path);

  $sub->($self, @_); 
}


#{{{ test


#}}}

sub content {
  my $self = shift;

  $self->{content} = join '', $self->_list(@_) if @_;
  return $self->{content}; 
}



#{{{ test


#}}}

sub capture {
  my $self = shift;

  my $charset = $self->charset;

  my $enc = $charset ? ":$charset" : '';

  my $content;
  {
    local *STDOUT;
    open STDOUT, ">$enc", \$content;
    my $ofh = select STDOUT;

    $self->include(@_);

    select $ofh;
  }

  return $charset ? Encode::decode($charset, $content) : $content;
}


#{{{ test


#}}}

sub content_for {
  my $self = shift;

  @_ or croak "no capture name supplied";

  $self->{captures} ||= {};

  return $self->{captures}{ shift() } if 1 == @_;

  while (@_) {
    my ($name, $val) = splice @_, 0, 2;
    my $type = ref $val;
    if ($type eq 'CODE') {
      $val = $self->capture($val);
    } elsif ($type eq 'ARRAY') {
      $val = join '', @$val;
    }
    $self->{captures}{ $name } .= $val;
  }
}


#{{{ test


#}}}

# Note that layouts may be called recursively.
sub _apply_layout {
  my $self = shift;
  my $layout = shift || $self->layout or return;

  local $self->{layout} = $layout;

  while (my $layout = $self->{layout}) {
    $self->{layout} = undef;
    local $_ = $self->{captures}{main} = $self->{content};
    eval { $self->{content} = $self->capture($layout) };
    croak "Layout '$layout' failed: $@" if $@;
  }
}


#{{{ test


#}}}

sub run {
  my $self = shift;

  $self->{content} = $self->capture(@_);
  $self->_apply_layout;

  return $self->{content} if defined wantarray;
}


#{{{ test


#}}}

sub escape_uri {
  my $class = shift;

  my @str = map {
    (ref $_ and eval { $_->can('as_uri') })
      ? $_->as_uri : URI::Escape::uri_escape_utf8($_)
  } @_;

  return wantarray ? @str : join '', @str;
}
*u = \&escape_uri;


#{{{ test


#}}}

{
  # "unsafe" chars and all ascii control chars except for tab,
  # line feed, and carriage return
  my $chars = q{<>&"'\x00-\x08\x0B\x0C\x0E-\x1F\x7F};

  sub escape_html {
    my $class = shift;

    my @str = map {
      (ref $_ and eval { $_->can('as_html') })
        ? $_->as_html : HTML::Entities::encode_entities($_, $chars)
    } @_;

    return wantarray ? @str : join '', @str;
  }
}
*h = \&escape_html;


#{{{ test


#}}}

# Deprecated
{
  no warnings qw/ prototype redefine /; # conflicts with core::send()

  sub send { 
    my $self = shift;
  
    print $self->run(@_)
  }
}


#{{{ test


#}}}

# Deprecated
use Method::Alias trap_send => 'run';


1;

=pod

=encoding UTF-8

=head1 NAME

Text::Forge - Templates with embedded Perl

=head1 VERSION

version 6.02

=head1 SYNOPSIS

  use Text::Forge;

  my $forge = Text::Forge->new;

  # template in external file
  print $forge->run('path/to/template');

  # template passed as reference
  print $forge->run(\'
    <% my $d = scalar localtime %>The date is <%= $d %>
  ');
  # Outputs: The date is Fri Nov 26 11:32:22 2010

=head1 DESCRIPTION

This module uses templates to generate documents dynamically. Templates
are normal text files with a bit of special syntax that allows Perl code
to be embedded.

The following tags are supported:

  <%  %> code block (no output)
  <%= %> interpolate, result is HTML escaped
  <%? %> interpolate, result is URI escaped
  <%$ %> interpolate, no escaping (let's be careful)
  <%# %> comment

All blocks are evaluated within the same lexical scope (so my
variables declared in one block are visible in subsequent blocks).

Code blocks contain straight Perl code; it is executed, but nothing
is output.

Interpolation blocks are evaluated and the result inserted into
the template.

Templates are compiled into normal Perl methods. They can
be passed arguments, as you might expect:

  print $forge->run(
    \'<% my %args = @_ %>Name is <%= $args{name} %>',
    name => 'foo'
  );

The $self variable is available within all templates, and is a reference
to the Text::Forge instance that is generating the document. This allows
subclasses to provide customization and context to templates.

Anything printed to standard output (STDOUT) becomes part of the template.

Any errors in compiling or executing a template raises an exception.
Errors should correctly reference the template line causing the problem.

If a block is followed solely by whitespace up to the next newline,
that whitespace (including the newline) will be suppressed from the output.
If you really want a newline, add another newline after the block.
The idea is that the blocks themselves shouldn't affect the formatting.

=for testing   use_ok $CLASS;

=begin testing

  isa_ok $CLASS->new, $CLASS, 'constructor on class name';
  isa_ok $CLASS->new->new, $CLASS, 'constructor on instance';

  my $forge = $CLASS->new(charset => 'iso-8859-1');
  ok $forge, 'object created';
  is $forge->charset, 'iso-8859-1', 'method called from constructor';

  my @search = ('.', '/tmp');
  $forge = $CLASS->new(search_paths => \@search);
  is_deeply scalar $forge->search_paths, \@search,
    'method called from constructor with arrayref';

=end testing

=for testing   my @list = qw/ a b c /;
  is_deeply [ $CLASS->_list ], [], 'empty list';
  is_deeply [ $CLASS->_list(@list), ], \@list, '_list';
  is_deeply [ $CLASS->_list(\@list) ], \@list, '_list arrayref flattened';
  is_deeply [ $CLASS->_list(@list, \@list) ], [@list, @list], '_list multi';

=begin testing

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

=end testing

=begin testing

  my $forge = $CLASS->new;
  is $forge->cache, $Text::Forge::CACHE, 'cache, defaults to $CACHE';

  foreach (0, 1) {
    is $forge->cache($_), $_, "cache, set $_";
    is $forge->cache, $_, 'cache, get';
  }

=end testing

=begin testing

  my $forge = $CLASS->new;
  is $forge->charset, $Text::Forge::CHARSET,
    'charset, defaults to $CHARSET';

  my $charset= 'iso-8859-1';
  is $forge->charset($charset), $charset, "charset, set to '$charset'";
  is $forge->charset, $charset, 'charset, get';

=end testing

=begin testing

  my $forge = $CLASS->new;
  is $forge->layout, undef, 'layout, default undefined';

  my $layout = '/tmp/foo';
  is $forge->layout($layout), $layout, "layout, set to '$layout'";
  is $forge->layout, $layout, 'layout, get';

=end testing

=begin testing

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

=end testing

=begin testing

  my $prefix = $CLASS->_namespace_prefix;

  is $CLASS->_namespace('/tmp'), "${prefix}::tmp", '_namespace';
  is $CLASS->_namespace('/tmp/F$<oo'), "${prefix}::tmp::F_24_3coo",
    '_namespace, escaped';
  is $CLASS->_namespace('/tmp/123/foo'), "${prefix}::tmp::_3123::foo",
    '_namespace, numeric';

=end testing

=begin testing

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
    local $Text::Forge::INTERPOLATE = 1;
 
    my $code = $CLASS->_parse('<% my $i = 5 %>hello $i there <% %> $i');
    is $code, ' my $i = 5 ;  print qq|hello $i there |;  ;  print qq| $i|; ',
      '_parse, interpolation enabled [DEPRECATED]';
  }

=end testing

=begin testing

  my $package = "${CLASS}::Test::NamedSub";
  my $code = "return 'foo'";

  my $template = $CLASS->_named_sub($package, '/tmp/test', $code);
  ok $template, '_named_sub, wrap template';

  my $sub = eval $template;
  ok !$@ && ref $sub eq 'CODE', '_named_sub, eval code';

  is $sub->(), 'foo', '_named_sub, call returned code reference';
  is $package->run(), 'foo', '_named_sub, call named sub';

=end testing

=begin testing

  my $package = "${CLASS}::Test::AnonSub";
  my $code = "return 'foo2'";

  my $template = $CLASS->_anon_sub($package, '/tmp/test2', $code);
  ok $template, '_anon_sub, wrap template';

  my $sub = eval $template;
  ok !$@ && ref $sub eq 'CODE', '_anon_sub, eval code';

  is $sub->(), 'foo2', 'call template';

=end testing

=begin testing

  my $mksub = eval { $CLASS->can('_mksub') };
  ok !$@ && ref $mksub eq 'CODE', '_mksub, get sub reference';

  my $rv = $mksub->("return 'foo'");
  is $rv, 'foo', '_mksub, eval code';

=end testing

=begin testing

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

=end testing

=begin testing

  use Scalar::Util qw/ refaddr /;

  my $forge = $CLASS->new(cache => 1);

  eval { $forge->include(\'') };
  ok !$@, 'include, inline template';

  is $forge->include(sub { return 12 }), 12, 'include, code reference';

  $forge->cache(0);
  is $forge->include(sub { return 22 }), 22, 'include, with caching off';

=end testing

=begin testing

  my $forge = $CLASS->new;
  is $forge->content, undef, 'content, initially undefined';
  
  $forge->content('test', [1, 2, 3]);
  is $forge->content, 'test123', 'content, set';

=end testing

=begin testing

  my $forge = $CLASS->new;
  $forge->charset('utf8');

  is $forge->capture(\'<% print "foo" %>'), 'foo', 'capture, inline template';

  is $forge->capture(sub { print 'foo' }), 'foo', 'capture, code ref';

  is $forge->capture(sub { print 'exposé, Zoë, à propos' }),
    'exposé, Zoë, à propos', 'capture, unicode';

  $forge->charset('');
  is $forge->capture(\'hi'), 'hi', 'capture, no charset set';

=end testing

=begin testing

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

=end testing

=begin testing

  my $forge = $CLASS->new;

  $forge->{content} = 'document';
  $forge->layout(\'<body><%= $self->content_for("main") %></body>');
  $forge->_apply_layout;
  is $forge->content, '<body>document</body>', '_apply_layout';

  $forge->layout(\'<body><% BAREWORD %></body>');
  eval { $forge->_apply_layout };
  ok $@, '_apply_layout, layout compile error should raise exception'; 

=end testing

=begin testing

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

=end testing

=begin testing

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

=end testing

=begin testing

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

=end testing

=begin testing

  my $output;
  {
    local *STDOUT;
    open STDOUT, '>', \$output;

    $CLASS->new->send(\'content');
  }

  is $output, 'content', 'send [DEPRECATED]';

=end testing

=for testing   is $CLASS->new->trap_send(\'foo'), 'foo', 'trap_send [DEPRECATED]';

=head1 METHODS 

=head2 new

Constructor. Returns a Text::Forge instance.

  my $forge = Text::Forge->new(%options);

=head2 run

Generate a template. The first argument is the template, which may be
either a file path or a reference to a scalar. Any additional arguments
are passed to the template.

  my $content = $forge->run('path/to/my/template', name => 'foo');

If a path is supplied and is not absolute, it will be searched for within
the list of L</search_paths>.

The generated output is returned.

=head2 cache

  my $forge = Text::Forge->new;
  $forge->cache(1);

Specifies whether templates should be cached. Defaults to true.

If caching is enabled, templates are compiled into subroutines once and
then reused.

If you want to ensure templates always reflect the latest changes
on disk (such as during development), set cache() to false.

If you want to maximize performance, set cache() to true.

=head2 charset

  my $forge = Text::Forge->new;
  $forge->charset('iso-8859-1');

Specifies the character encoding to use for templates.
Defaults to Unicode (utf8).

=head2 search_paths

The list of directories to search for relative template paths.

  my $forge = Text::Forge->new;
  $forge->search_paths('/app/templates', '.');

  # will look for /app/templates/header and ./header
  $forge->run('header');

=head2 content

Returns the result of the last call to run().

=head1 TEMPLATE METHODS

The following methods are intended for use I<within> templates. It's all the
same object though, so knock yourself out.

=head2 include

Include one template within another.

For example, if you want to insert a "header" template within another
template. Note that arguments can be passed to included templates and
values can be returned (like normal function calls).

  my $forge = Text::Forge->new;
  $forge->run(\'<% $self->include("header", title => 'Hi') %>Hello');

=head2 capture

Capture the output of a template.

Used to capture (but not necessarily include) one template within another.
For example:

  my $forge = Text::Forge->new;
  $forge->run(\'
    <% my $pagination = $self->capture(sub { %>
         Page 
         <ul>
           <% foreach (1..10) { %>
                <li><%= $_ %></li>
           <% } %>
         </ul>
    <% }) %>

    <h1>Title</h1>
    <%$ $pagination %>
    Results...
    <%$ $pagination %>
  ');

In this case the "pagination" content has been captured into the variable
$pagination, which is then inserted in multiple locations elsewhere in
the document.

=head2 content_for 

Capture the output into a named placeholder. Same as L</capture> except the
result in stored internally as $forge->{captures}{ $name }.

Note that multiple calls to content_for() with the same name are concatenated
together (not overwritten); this allows, for example, multiple calls
to something like content_for('head', ...), which are then aggregated and
inserted elsewhere in the document.

When called with two arguments, this method stores the specified content in
the named location:

  my $forge = Text::Forge->new;
  $forge->run(\'
    <h1>Title</h1>

    <% $self->capture_for('nav', sub { %>
         <ul>
           <li>...</li>
         </ul>
    <% }) %>
  ');

When called with one argument, it returns the previously stored content, if any:

  my $nav = $self->content_for('nav');

=head2 layout

Specifies a layout template to apply. Defaults to none.

If defined, the layout template is applied after the primary template
has been generated. The layout template may then "wrap" the primary template
with additional content.

For example, rather than have each template L</include> a separate header
and footer template explicitly, a layout() template can be used more
simply:

  my $forge = Text::Forge->new;
  $forge->layout(\'<html><body><%$ $_ %></body></html>');
  print $forge->run(\'<h1>Hello, World!</h1>');

  # results in:
  # <html><body><h1>Hello, World!</h1></body></html>

Within the layout, the primary template content is available as $_ (as well
as through $self->content_for('main')).

=head2 escape_html, h

Returns HTML encoded versions of its arguments. This method is used internally
to encode the result of <%= %> blocks, but can be used directly:

  my $forge = Text::Forge->new;
  print $forge->run(\'<% print $self->escape_html("<strong>") %>');
  # outputs: &lt;strong&gt;

The h() method is just an alias for convenience.

If a blessed reference is passed that provides an as_html() method, the
result of that method will be returned instead. This allows objects to
be constructed that keep track of their own encoding state.

=head2 escape_uri, u

Returns URI escaped versions of its arguments. This method is used internally
to encode the result of <%? %> blocks, but can be used directly:

  my $forge = Text::Forge->new;
  print $forge->run(\'<% print $self->escape_uri("name=foo") %>');
  # outputs: name%3Dfoo

The u() method is just an alias for convenience.

If a blessed reference is passed that provides an as_uri() method, the
result of that method will be returned instead. This allows objects to
be constructed that keep track of their own encoding state.

=head1 AUTHOR

Maurice Aubrey <maurice.aubrey@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Maurice Aubrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__



# vim: set foldmethod=marker:
