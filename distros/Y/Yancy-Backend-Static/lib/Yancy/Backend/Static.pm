package Yancy::Backend::Static;
our $VERSION = '0.010';
# ABSTRACT: Build a Yancy site from static Markdown files

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'static:.',
#pod         read_schema => 1,
#pod     };
#pod     get '/*id', {
#pod         controller => 'yancy',
#pod         action => 'get',
#pod         schema => 'pages',
#pod         id => 'index', # Default to index page
#pod         template => 'default', # default.html.ep below
#pod     };
#pod     app->start;
#pod     __DATA__
#pod     @@ default.html.ep
#pod     % title $item->{title};
#pod     <%== $item->{html} %>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Yancy::Backend> allows Yancy to work with a site made up of
#pod Markdown files with YAML frontmatter, like a L<Statocles> site. In other
#pod words, this module works with a flat-file database made up of YAML
#pod + Markdown files.
#pod
#pod =head2 Schemas
#pod
#pod You should configure the C<pages> schema to have all of the fields
#pod that could be in the frontmatter of your Markdown files. This is JSON Schema
#pod and will be validated, but if you're using the Yancy editor, make sure only
#pod to use L<the types Yancy supports|Yancy::Help::Config/Types>.
#pod
#pod =head2 Limitations
#pod
#pod This backend should support everything L<Yancy::Backend> supports, though
#pod some list() queries may not work (please make a pull request).
#pod
#pod =head2 Future Developments
#pod
#pod This backend could be enhanced to provide schema for static files
#pod (CSS, JavaScript, etc...) and templates.
#pod
#pod =head1 GETTING STARTED
#pod
#pod To get started using this backend to make a simple static website, first
#pod create a file called C<myapp.pl> with the following contents:
#pod
#pod     #!/usr/bin/env perl
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'static:.',
#pod         read_schema => 1,
#pod     };
#pod     get '/*id', {
#pod         controller => 'yancy',
#pod         action => 'get',
#pod         schema => 'pages',
#pod         template => 'default',
#pod         layout => 'default',
#pod         id => 'index',
#pod     };
#pod     app->start;
#pod     __DATA__
#pod     @@ default.html.ep
#pod     % title $item->{title};
#pod     <%== $item->{html} %>
#pod     @@ layouts/default.html.ep
#pod     <!DOCTYPE html>
#pod     <html>
#pod     <head>
#pod         <title><%= title %></title>
#pod         <link rel="stylesheet" href="/yancy/bootstrap.css">
#pod     </head>
#pod     <body>
#pod         <main class="container">
#pod             %= content
#pod         </main>
#pod         <script src="/yancy/jquery.js"></script>
#pod         <script src="/yancy/bootstrap.js"></script>
#pod     </body>
#pod     </html>
#pod
#pod Once this is done, run the development webserver using C<perl myapp.pl
#pod daemon>:
#pod
#pod     $ perl myapp.pl daemon
#pod     Server available at http://127.0.0.1:3000
#pod
#pod Then open C<http://127.0.0.1:3000/yancy> in your web browser to see the
#pod L<Yancy> editor.
#pod
#pod =for html <img style="max-width: 100%" src="https://raw.githubusercontent.com/preaction/Yancy-Backend-Static/master/eg/public/editor-1.png">
#pod
#pod You should first create an C<index> page by clicking the "Add Item"
#pod button to create a new page and giving the page a C<path> of C<index>.
#pod
#pod =for html <img style="max-width: 100%" src="https://raw.githubusercontent.com/preaction/Yancy-Backend-Static/master/eg/public/editor-2.png">
#pod
#pod Once this page is created, you can visit your new page either by
#pod clicking the "eye" icon on the left side of the table, or by navigating
#pod to L<http://127.0.0.1:3000>.
#pod
#pod =for html <img style="max-width: 100%" src="https://raw.githubusercontent.com/preaction/Yancy-Backend-Static/master/eg/public/editor-3.png">
#pod
#pod =head2 Adding Images and Files
#pod
#pod To add other files to your site (images, scripts, stylesheets, etc...),
#pod create a directory called C<public> and put your file in there.  All the
#pod files in the C<public> folder are available to use in your website.
#pod
#pod To add an image using Markdown, use C<![](path/to/image.jpg)>.
#pod
#pod =head2 Customize Template and Layout
#pod
#pod The easiest way to customize the look of the site is to edit the layout
#pod template. Templates in Mojolicious can be in external files in
#pod a C<templates> directory, or they can be in the C<myapp.pl> script below
#pod C<__DATA__>.
#pod
#pod The layout your site uses currently is called
#pod C<layouts/default.html.ep>.  The two main things to put in a layout are
#pod C<< <%= title %> >> for the page's title and C<< <%= content %> >> for
#pod the page's content. Otherwise, the layout can be used to add design and
#pod navigation for your site.
#pod
#pod =head1 ADVANCED FEATURES
#pod
#pod =head2 Custom Metadata Fields
#pod
#pod You can add additional metadata fields to your page by adding them to
#pod your schema, like so:
#pod
#pod     plugin Yancy => {
#pod         backend => 'static:.',
#pod         read_schema => 1,
#pod         schema => {
#pod             pages => {
#pod                 properties => {
#pod                     # Add an optional 'author' field
#pod                     author => { type => [ 'string', 'null' ] },
#pod                 },
#pod             },
#pod         },
#pod     };
#pod
#pod These additional fields can be used in your template through the
#pod C<$item> hash reference (C<< $item->{author} >>).  See
#pod L<Yancy::Help::Config> for more information about configuring a schema.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>, L<Statocles>
#pod
#pod =cut

use Mojo::Base -base;
use Mojo::File;
use Text::Markdown;
use YAML ();
use JSON::PP ();
use Yancy::Util qw( match order_by );
use Encode;

has schema =>;
has path =>;
has markdown_parser => sub { Text::Markdown->new };

sub new {
    my ( $class, $backend, $schema ) = @_;
    my ( undef, $path ) = split /:/, $backend, 2;
    return $class->SUPER::new( {
        path => Mojo::File->new( $path ),
        schema => $schema,
    } );
}

sub create {
    my ( $self, $schema, $params ) = @_;

    my $path = $self->path->child( $self->_id_to_path( $params->{path} ) );
    my $content = $self->_deparse_content( $params );
    if ( !-d $path->dirname ) {
        $path->dirname->make_path;
    }
    $path->spurt( $content );

    return $params->{path};
}

sub get {
    my ( $self, $schema, $id ) = @_;

    # Allow directory path to work. Must have a trailing slash to ensure
    # that relative links in the file work correctly.
    if ( $id =~ m{/$} && -d $self->path->child( $id ) ) {
        $id .= 'index.markdown';
    }
    else {
        # Clean up the input path
        $id =~ s/\.\w+$//;
        $id .= '.markdown';
    }

    my $path = $self->path->child( $id );
    #; say "Getting path $id: $path";
    return undef unless -f $path;

    my $item = eval { $self->_parse_content( $path->slurp ) };
    if ( $@ ) {
        warn sprintf 'Could not load file %s: %s', $path, $@;
        return undef;
    }
    $item->{path} = $self->_path_to_id( $path->to_rel( $self->path ) );
    return $item;
}

sub list {
    my ( $self, $schema, $params, $opt ) = @_;
    $params ||= {};
    $opt ||= {};

    my @items;
    my $total = 0;
    PATH: for my $path ( sort $self->path->list_tree->each ) {
        next unless $path =~ /[.](?:markdown|md)$/;
        my $item = eval { $self->_parse_content( $path->slurp ) };
        if ( $@ ) {
            warn sprintf 'Could not load file %s: %s', $path, $@;
            next;
        }
        $item->{path} = $self->_path_to_id( $path->to_rel( $self->path ) );
        next unless match( $params, $item );
        push @items, $item;
        $total++;
    }

    $opt->{order_by} //= 'path';
    my $ordered_items = order_by( $opt->{order_by}, \@items );

    my $start = $opt->{offset} // 0;
    my $end = $opt->{limit} ? $start + $opt->{limit} - 1 : $#items;
    if ( $end > $#items ) {
        $end = $#items;
    }

    return {
        items => [ @{$ordered_items}[ $start .. $end ] ],
        total => $total,
    };
}

sub set {
    my ( $self, $schema, $id, $params ) = @_;
    my $path = $self->path->child( $self->_id_to_path( $id ) );
    # Load the current file to turn a partial set into a complete
    # set
    my %item = (
        -f $path ? %{ $self->_parse_content( $path->slurp ) } : (),
        %$params,
    );

    if ( $params->{path} ) {
      my $new_path = $self->path->child( $self->_id_to_path( $params->{path} ) );
      if ( -f $path and $new_path ne $path ) {
         $path->remove;
      }
      $path = $new_path;
    }
    if ( !-d $path->dirname ) {
        $path->dirname->make_path;
    }
    my $content = $self->_deparse_content( \%item );
    #; say "Set to $path:\n$content";
    $path->spurt( $content );
    return 1;
}

sub delete {
    my ( $self, $schema, $id ) = @_;
    return !!unlink $self->path->child( $self->_id_to_path( $id ) );
}

sub read_schema {
    my ( $self, @schemas ) = @_;
    my %page_schema = (
        type => 'object',
        title => 'Pages',
        required => [qw( path markdown )],
        'x-id-field' => 'path',
        'x-view-item-url' => '/{path}',
        'x-list-columns' => [ 'title', 'path' ],
        properties => {
            path => {
                type => 'string',
                'x-order' => 2,
            },
            title => {
                type => 'string',
                'x-order' => 1,
            },
            markdown => {
                type => 'string',
                format => 'markdown',
                'x-html-field' => 'html',
                'x-order' => 3,
            },
            html => {
                type => 'string',
            },
        },
    );
    return @schemas ? \%page_schema : { pages => \%page_schema };
}

sub _id_to_path {
    my ( $self, $id ) = @_;
    # Allow indexes to be created
    if ( $id =~ m{(?:^|\/)index$} ) {
        $id .= '.markdown';
    }
    # Allow full file paths to be created
    elsif ( $id =~ m{\.\w+$} ) {
        $id =~ s{\.\w+$}{.markdown};
    }
    # Anything else should create a file
    else {
        $id .= '.markdown';
    }
    return $id;
}

sub _path_to_id {
    my ( $self, $path ) = @_;
    my $dir = $path->dirname;
    $dir =~ s/^\.//;
    return join '/', grep !!$_, $dir, $path->basename( '.markdown' );
}

#=sub _parse_content
#
#   my $item = $backend->_parse_content( $path->slurp );
#
# Parse a file's frontmatter and Markdown. Returns a hashref
# ready for use as an item.
#
#=cut

sub _parse_content {
    my ( $self, $content ) = @_;
    my %item;

    my @lines = split /\n/, decode_utf8 $content;
    # YAML frontmatter
    if ( @lines && $lines[0] =~ /^---/ ) {

        # The next --- is the end of the YAML frontmatter
        my ( $i ) = grep { $lines[ $_ ] =~ /^---/ } 1..$#lines;

        # If we did not find the marker between YAML and Markdown
        if ( !defined $i ) {
            die qq{Could not find end of YAML front matter (---)\n};
        }

        # Before the marker is YAML
        eval {
            %item = %{ YAML::Load( join "\n", splice( @lines, 0, $i ), "" ) };
            %item = map {$_ => do {
              # YAML.pm 1.29 doesn't parse 'true', 'false' as booleans
              # like the schema suggests: https://yaml.org/spec/1.2/spec.html#id2803629
              my $v = $item{$_};
              $v = JSON::PP::false if $v and $v eq 'false';
              $v = JSON::PP::true if $v and $v eq 'true';
              $v
            }} keys %item;
        };
        if ( $@ ) {
            die qq{Error parsing YAML\n$@};
        }

        # Remove the last '---' mark
        shift @lines;
    }
    # JSON frontmatter
    elsif ( @lines && $lines[0] =~ /^{/ ) {
        my $json;
        if ( $lines[0] =~ /\}$/ ) {
            # The JSON is all on a single line
            $json = shift @lines;
        }
        else {
            # The } on a line by itself is the last line of JSON
            my ( $i ) = grep { $lines[ $_ ] =~ /^}$/ } 0..$#lines;
            # If we did not find the marker between YAML and Markdown
            if ( !defined $i ) {
                die qq{Could not find end of JSON front matter (\})\n};
            }
            $json = join "\n", splice( @lines, 0, $i+1 );
        }
        eval {
            %item = %{ JSON::PP->new()->utf8(0)->decode( $json ) };
        };
        if ( $@ ) {
            die qq{Error parsing JSON: $@\n};
        }
    }

    # The remaining lines are content
    $item{ markdown } = join "\n", @lines, "";
    $item{ html } = $self->markdown_parser->markdown( $item{ markdown } );

    return \%item;
}

sub _deparse_content {
    my ( $self, $item ) = @_;
    my %data =
        map { $_ => do {
        my $v = $item->{ $_ };
          JSON::PP::is_bool($v) ? $v ? 'true' : 'false' : $v
        }}
        grep { !/^(?:markdown|html|path)$/ }
        keys %$item;
    return ( %data ? YAML::Dump( \%data ) . "---\n" : "") . ( $item->{markdown} // "" );
}

1;

__END__

=pod

=head1 NAME

Yancy::Backend::Static - Build a Yancy site from static Markdown files

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'static:.',
        read_schema => 1,
    };
    get '/*id', {
        controller => 'yancy',
        action => 'get',
        schema => 'pages',
        id => 'index', # Default to index page
        template => 'default', # default.html.ep below
    };
    app->start;
    __DATA__
    @@ default.html.ep
    % title $item->{title};
    <%== $item->{html} %>

=head1 DESCRIPTION

This L<Yancy::Backend> allows Yancy to work with a site made up of
Markdown files with YAML frontmatter, like a L<Statocles> site. In other
words, this module works with a flat-file database made up of YAML
+ Markdown files.

=head2 Schemas

You should configure the C<pages> schema to have all of the fields
that could be in the frontmatter of your Markdown files. This is JSON Schema
and will be validated, but if you're using the Yancy editor, make sure only
to use L<the types Yancy supports|Yancy::Help::Config/Types>.

=head2 Limitations

This backend should support everything L<Yancy::Backend> supports, though
some list() queries may not work (please make a pull request).

=head2 Future Developments

This backend could be enhanced to provide schema for static files
(CSS, JavaScript, etc...) and templates.

=head1 GETTING STARTED

To get started using this backend to make a simple static website, first
create a file called C<myapp.pl> with the following contents:

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'static:.',
        read_schema => 1,
    };
    get '/*id', {
        controller => 'yancy',
        action => 'get',
        schema => 'pages',
        template => 'default',
        layout => 'default',
        id => 'index',
    };
    app->start;
    __DATA__
    @@ default.html.ep
    % title $item->{title};
    <%== $item->{html} %>
    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
    <head>
        <title><%= title %></title>
        <link rel="stylesheet" href="/yancy/bootstrap.css">
    </head>
    <body>
        <main class="container">
            %= content
        </main>
        <script src="/yancy/jquery.js"></script>
        <script src="/yancy/bootstrap.js"></script>
    </body>
    </html>

Once this is done, run the development webserver using C<perl myapp.pl
daemon>:

    $ perl myapp.pl daemon
    Server available at http://127.0.0.1:3000

Then open C<http://127.0.0.1:3000/yancy> in your web browser to see the
L<Yancy> editor.

=for html <img style="max-width: 100%" src="https://raw.githubusercontent.com/preaction/Yancy-Backend-Static/master/eg/public/editor-1.png">

You should first create an C<index> page by clicking the "Add Item"
button to create a new page and giving the page a C<path> of C<index>.

=for html <img style="max-width: 100%" src="https://raw.githubusercontent.com/preaction/Yancy-Backend-Static/master/eg/public/editor-2.png">

Once this page is created, you can visit your new page either by
clicking the "eye" icon on the left side of the table, or by navigating
to L<http://127.0.0.1:3000>.

=for html <img style="max-width: 100%" src="https://raw.githubusercontent.com/preaction/Yancy-Backend-Static/master/eg/public/editor-3.png">

=head2 Adding Images and Files

To add other files to your site (images, scripts, stylesheets, etc...),
create a directory called C<public> and put your file in there.  All the
files in the C<public> folder are available to use in your website.

To add an image using Markdown, use C<![](path/to/image.jpg)>.

=head2 Customize Template and Layout

The easiest way to customize the look of the site is to edit the layout
template. Templates in Mojolicious can be in external files in
a C<templates> directory, or they can be in the C<myapp.pl> script below
C<__DATA__>.

The layout your site uses currently is called
C<layouts/default.html.ep>.  The two main things to put in a layout are
C<< <%= title %> >> for the page's title and C<< <%= content %> >> for
the page's content. Otherwise, the layout can be used to add design and
navigation for your site.

=head1 ADVANCED FEATURES

=head2 Custom Metadata Fields

You can add additional metadata fields to your page by adding them to
your schema, like so:

    plugin Yancy => {
        backend => 'static:.',
        read_schema => 1,
        schema => {
            pages => {
                properties => {
                    # Add an optional 'author' field
                    author => { type => [ 'string', 'null' ] },
                },
            },
        },
    };

These additional fields can be used in your template through the
C<$item> hash reference (C<< $item->{author} >>).  See
L<Yancy::Help::Config> for more information about configuring a schema.

=head1 SEE ALSO

L<Yancy>, L<Statocles>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Mohammad S Anwar Wojtek Bażant

=over 4

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Wojtek Bażant <wojciech.bazant+ebi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
