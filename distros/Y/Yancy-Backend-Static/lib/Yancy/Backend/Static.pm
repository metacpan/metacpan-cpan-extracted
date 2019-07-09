package Yancy::Backend::Static;
our $VERSION = '0.004';
# ABSTRACT: Build a Yancy site from static Markdown files

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'static:/home/doug/www/preaction.me',
#pod         read_schema => 1,
#pod     };
#pod     get '/*id',
#pod         controller => 'yancy',
#pod         action => 'get',
#pod         schema => 'page',
#pod         id => 'index', # Default to index page
#pod         template => 'page',
#pod         ;
#pod     app->start;
#pod     __DATA__
#pod     @@ page.html.ep
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

    # Allow directory path to work
    if ( -d $self->path->child( $id ) ) {
        $id =~ s{/$}{};
        $id .= '/index.markdown';
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

    return {
        items => order_by( $opt->{order_by} // 'path', \@items ),
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
    my $content = $self->_deparse_content( \%item );
    #; say "Set to $path:\n$content";
    if ( !-d $path->dirname ) {
        $path->dirname->make_path;
    }
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

    my @lines = split /\n/, $content;
    # YAML frontmatter
    if ( @lines && $lines[0] =~ /^---/ ) {
        shift @lines;

        # The next --- is the end of the YAML frontmatter
        my ( $i ) = grep { $lines[ $_ ] =~ /^---/ } 0..$#lines;

        # If we did not find the marker between YAML and Markdown
        if ( !defined $i ) {
            die qq{Could not find end of YAML front matter (---)\n};
        }

        # Before the marker is YAML
        eval {
            %item = %{ YAML::Load( join "\n", splice( @lines, 0, $i ), "" ) };
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
        map { $_ => $item->{ $_ } }
        grep { !/^(?:markdown|html|path)$/ }
        keys %$item;
    return YAML::Dump( \%data ) . "---\n". $item->{markdown};
}

1;

__END__

=pod

=head1 NAME

Yancy::Backend::Static - Build a Yancy site from static Markdown files

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'static:/home/doug/www/preaction.me',
        read_schema => 1,
    };
    get '/*id',
        controller => 'yancy',
        action => 'get',
        schema => 'page',
        id => 'index', # Default to index page
        template => 'page',
        ;
    app->start;
    __DATA__
    @@ page.html.ep
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

=head1 SEE ALSO

L<Yancy>, L<Statocles>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
