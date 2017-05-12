# NAME

Text::Forge - Templates with embedded Perl

# VERSION

version 6.02

# SYNOPSIS

    use Text::Forge;

    my $forge = Text::Forge->new;

    # template in external file
    print $forge->run('path/to/template');

    # template passed as reference
    print $forge->run(\'
      <% my $d = scalar localtime %>The date is <%= $d %>
    ');
    # Outputs: The date is Fri Nov 26 11:32:22 2010

# DESCRIPTION

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

# METHODS 

## new

Constructor. Returns a Text::Forge instance.

    my $forge = Text::Forge->new(%options);

## run

Generate a template. The first argument is the template, which may be
either a file path or a reference to a scalar. Any additional arguments
are passed to the template.

    my $content = $forge->run('path/to/my/template', name => 'foo');

If a path is supplied and is not absolute, it will be searched for within
the list of ["search\_paths"](#search_paths).

The generated output is returned.

## cache

    my $forge = Text::Forge->new;
    $forge->cache(1);

Specifies whether templates should be cached. Defaults to true.

If caching is enabled, templates are compiled into subroutines once and
then reused.

If you want to ensure templates always reflect the latest changes
on disk (such as during development), set cache() to false.

If you want to maximize performance, set cache() to true.

## charset

    my $forge = Text::Forge->new;
    $forge->charset('iso-8859-1');

Specifies the character encoding to use for templates.
Defaults to Unicode (utf8).

## search\_paths

The list of directories to search for relative template paths.

    my $forge = Text::Forge->new;
    $forge->search_paths('/app/templates', '.');

    # will look for /app/templates/header and ./header
    $forge->run('header');

## content

Returns the result of the last call to run().

# TEMPLATE METHODS

The following methods are intended for use _within_ templates. It's all the
same object though, so knock yourself out.

## include

Include one template within another.

For example, if you want to insert a "header" template within another
template. Note that arguments can be passed to included templates and
values can be returned (like normal function calls).

    my $forge = Text::Forge->new;
    $forge->run(\'<% $self->include("header", title => 'Hi') %>Hello');

## capture

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

## content\_for 

Capture the output into a named placeholder. Same as ["capture"](#capture) except the
result in stored internally as $forge->{captures}{ $name }.

Note that multiple calls to content\_for() with the same name are concatenated
together (not overwritten); this allows, for example, multiple calls
to something like content\_for('head', ...), which are then aggregated and
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

## layout

Specifies a layout template to apply. Defaults to none.

If defined, the layout template is applied after the primary template
has been generated. The layout template may then "wrap" the primary template
with additional content.

For example, rather than have each template ["include"](#include) a separate header
and footer template explicitly, a layout() template can be used more
simply:

    my $forge = Text::Forge->new;
    $forge->layout(\'<html><body><%$ $_ %></body></html>');
    print $forge->run(\'<h1>Hello, World!</h1>');

    # results in:
    # <html><body><h1>Hello, World!</h1></body></html>

Within the layout, the primary template content is available as $\_ (as well
as through $self->content\_for('main')).

## escape\_html, h

Returns HTML encoded versions of its arguments. This method is used internally
to encode the result of <%= %> blocks, but can be used directly:

    my $forge = Text::Forge->new;
    print $forge->run(\'<% print $self->escape_html("<strong>") %>');
    # outputs: &lt;strong&gt;

The h() method is just an alias for convenience.

If a blessed reference is passed that provides an as\_html() method, the
result of that method will be returned instead. This allows objects to
be constructed that keep track of their own encoding state.

## escape\_uri, u

Returns URI escaped versions of its arguments. This method is used internally
to encode the result of <%? %> blocks, but can be used directly:

    my $forge = Text::Forge->new;
    print $forge->run(\'<% print $self->escape_uri("name=foo") %>');
    # outputs: name%3Dfoo

The u() method is just an alias for convenience.

If a blessed reference is passed that provides an as\_uri() method, the
result of that method will be returned instead. This allows objects to
be constructed that keep track of their own encoding state.

# AUTHOR

Maurice Aubrey <maurice.aubrey@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Maurice Aubrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
