package Trickster::Template;

use strict;
use warnings;
use v5.14;

use Text::Xslate;
use File::Spec;
use Carp qw(croak);

sub new {
    my ($class, %opts) = @_;
    
    my $path = $opts{path} || ['templates'];
    my $cache_dir = $opts{cache_dir} || File::Spec->tmpdir;
    my $cache = exists $opts{cache} ? $opts{cache} : 1;
    
    my $xslate = Text::Xslate->new(
        path => $path,
        cache_dir => $cache_dir,
        cache => $cache,
        syntax => $opts{syntax} || 'TTerse',
        module => $opts{module} || ['Text::Xslate::Bridge::Star'],
        function => $opts{function} || {},
        warn_handler => sub {
            my $msg = shift;
            warn "Template warning: $msg\n";
        },
        die_handler => sub {
            my $msg = shift;
            croak "Template error: $msg";
        },
        %{$opts{xslate_options} || {}},
    );
    
    return bless {
        xslate => $xslate,
        layout => $opts{layout},
        default_vars => $opts{default_vars} || {},
    }, $class;
}

sub render {
    my ($self, $template, $vars) = @_;
    
    $vars ||= {};
    
    # Merge default vars
    my %merged_vars = (%{$self->{default_vars}}, %$vars);
    
    # Render the template
    my $content = $self->{xslate}->render($template, \%merged_vars);
    
    # Apply layout if specified
    if ($self->{layout} && !$merged_vars{no_layout}) {
        $content = $self->{xslate}->render($self->{layout}, {
            %merged_vars,
            content => $content,
        });
    }
    
    return $content;
}

sub render_string {
    my ($self, $template_string, $vars) = @_;
    
    $vars ||= {};
    
    # Merge default vars
    my %merged_vars = (%{$self->{default_vars}}, %$vars);
    
    return $self->{xslate}->render_string($template_string, \%merged_vars);
}

sub add_function {
    my ($self, $name, $code) = @_;
    
    croak "Function name required" unless $name;
    croak "Function code must be a code reference" unless ref($code) eq 'CODE';
    
    # This requires creating a new Xslate instance
    # Store for future reference
    $self->{custom_functions}{$name} = $code;
    
    return $self;
}

sub set_layout {
    my ($self, $layout) = @_;
    $self->{layout} = $layout;
    return $self;
}

sub set_default_vars {
    my ($self, $vars) = @_;
    $self->{default_vars} = { %{$self->{default_vars}}, %$vars };
    return $self;
}

# Helper method to integrate with Response
sub response_helper {
    my ($self) = @_;
    
    return sub {
        my ($res, $template, $vars, $status) = @_;
        
        my $html = $self->render($template, $vars);
        
        $res->status($status || 200);
        $res->content_type('text/html; charset=utf-8');
        $res->body($html);
        
        return $res;
    };
}

1;

__END__

=head1 NAME

Trickster::Template - Fast template engine for Trickster using Text::Xslate

=head1 SYNOPSIS

    use Trickster::Template;
    
    # Create template engine
    my $template = Trickster::Template->new(
        path => ['templates', 'views'],
        cache => 1,
        layout => 'layouts/main.tx',
    );
    
    # Render a template
    my $html = $template->render('user/profile.tx', {
        user => $user,
        title => 'User Profile',
    });
    
    # In your Trickster app
    $app->get('/profile', sub {
        my ($req, $res) = @_;
        my $html = $template->render('profile.tx', { name => 'Alice' });
        return $res->html($html);
    });

=head1 DESCRIPTION

Trickster::Template provides a fast, feature-rich template engine using
Text::Xslate. It supports layouts, custom functions, and integrates
seamlessly with Trickster applications.

=head1 FEATURES

=over 4

=item * Fast template rendering with Text::Xslate

=item * Layout support for consistent page structure

=item * Template caching for production performance

=item * Custom function registration

=item * Default variables across all templates

=item * Multiple template paths

=item * TTerse syntax (Template Toolkit-like)

=back

=head1 METHODS

=head2 new(%options)

Creates a new template engine instance.

Options:

=over 4

=item * path - Array ref of template directories (default: ['templates'])

=item * cache - Enable template caching (default: 1)

=item * cache_dir - Cache directory (default: system temp)

=item * layout - Default layout template

=item * syntax - Template syntax (default: 'TTerse')

=item * default_vars - Hash ref of default variables

=item * function - Hash ref of custom functions

=back

=head2 render($template, $vars)

Renders a template file with the given variables.

    my $html = $template->render('user.tx', { name => 'Alice' });

=head2 render_string($template_string, $vars)

Renders a template string directly.

    my $html = $template->render_string(
        'Hello [% name %]!',
        { name => 'Alice' }
    );

=head2 set_layout($layout)

Sets the default layout template.

    $template->set_layout('layouts/main.tx');

=head2 set_default_vars($vars)

Sets default variables available to all templates.

    $template->set_default_vars({
        app_name => 'My App',
        version => '1.0',
    });

=head1 TEMPLATE SYNTAX

Trickster::Template uses TTerse syntax by default (Template Toolkit-like):

    [% # Comments %]
    
    [% # Variables %]
    Hello [% name %]!
    
    [% # Conditionals %]
    [% IF user.is_admin %]
        <p>Admin panel</p>
    [% END %]
    
    [% # Loops %]
    [% FOR item IN items %]
        <li>[% item.name %]</li>
    [% END %]
    
    [% # Filters %]
    [% text | html %]
    [% url | uri %]
    
    [% # Include other templates %]
    [% INCLUDE 'header.tx' %]

=head1 LAYOUTS

Create a layout template (layouts/main.tx):

    <!DOCTYPE html>
    <html>
    <head>
        <title>[% title || 'My App' %]</title>
    </head>
    <body>
        [% content %]
    </body>
    </html>

Use in your templates:

    [% # This content will be wrapped in the layout %]
    <h1>Welcome [% user.name %]</h1>

Disable layout for specific renders:

    $template->render('page.tx', { no_layout => 1 });

=head1 CUSTOM FUNCTIONS

Register custom functions for use in templates:

    my $template = Trickster::Template->new(
        function => {
            format_date => sub {
                my $timestamp = shift;
                return localtime($timestamp)->strftime('%Y-%m-%d');
            },
            truncate => sub {
                my ($text, $length) = @_;
                return substr($text, 0, $length) . '...';
            },
        },
    );

Use in templates:

    [% format_date(post.created_at) %]
    [% truncate(post.body, 100) %]

=head1 SEE ALSO

L<Text::Xslate>, L<Trickster>, L<Trickster::Response>

=cut
