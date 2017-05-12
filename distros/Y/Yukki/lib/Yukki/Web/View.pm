package Yukki::Web::View;
{
  $Yukki::Web::View::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

use MooseX::Params::Validate;
use Path::Class;
use Scalar::Util qw( blessed reftype );
use Spreadsheet::Engine;
use Template::Semantic;
use Text::MultiMarkdown;
use Try::Tiny;
use XML::Twig;

# ABSTRACT: base class for Yukki::Web views


has app => (
    is          => 'ro',
    isa         => 'Yukki::Web',
    required    => 1,
    weak_ref    => 1,
    handles     => 'Yukki::Role::App',
);


has markdown => (
    is          => 'ro',
    isa         => 'Text::MultiMarkdown',
    required    => 1,
    lazy_build  => 1,
    handles     => {
        'format_markdown' => 'markdown',
    },
);

sub _build_markdown {
    Text::MultiMarkdown->new(
        markdown_in_html_blocks => 1,
        heading_ids             => 0,
    );
}


has semantic => (
    is          => 'ro',
    isa         => 'Template::Semantic',
    required    => 1,
    lazy_build  => 1,
);

sub _build_semantic { 
    my $self = shift;

    my $semantic = Template::Semantic->new;

    # TODO Maybe nice to have?
    # $semantic->define_filter(markdown => sub { \ $self->format_markdown($_) });
    # $semantic->define_filter(yukkitext => sub { \ $self->yukkitext($_) });

    return $semantic;
}


sub render_page {
    my ($self, $template, $ctx, $vars) = validated_list(\@_,
        template   => { isa => 'Str', coerce => 1 },
        context    => { isa => 'Yukki::Web::Context' },
        vars       => { isa => 'HashRef', default => {} },
    );

    my $messages = $self->render(
        template => 'messages.html', 
        vars     => {
            '.error'   => [ map { +{ '.' => $_ } } $ctx->list_errors   ],
            '.warning' => [ map { +{ '.' => $_ } } $ctx->list_warnings ],
            '.info'    => [ map { +{ '.' => $_ } } $ctx->list_info     ],
        },
    );

    my ($main_title, $title);
    if ($ctx->response->has_page_title) {
        $title      = $ctx->response->page_title;
        $main_title = $ctx->response->page_title . ' - Yukki';
    }
    else {
        $title = $main_title = 'Yukki';
    }

    my $b = sub { $ctx->rebase_url($_[0]) };
    my %menu_vars = map {
        ("#nav-$_ .navigation" => [ map {
            { 'a' => $_->{label}, 'a@href' => $b->($_->{href}) },
        } $self->available_menu_items($ctx, $_) ])
    } $ctx->response->navigation_menu_names;

    $menu_vars{"#nav-$_ .navigation"} //= [] 
        for (@{ $self->app->settings->menu_names });

    my @scripts = $self->app->settings->all_scripts;
    my @styles  = $self->app->settings->all_styles;

    my $view      = $ctx->request->parameters->{view} // 'default';
    my $view_args = $self->app->settings->page_views->{ $view }
                 // { template => 'shell.html' };
    $view_args->{vars} //= {};

    return $self->render(
        template => $view_args->{template},
        vars     => {
            %{ $view_args->{vars} },
            'head script.local' => [ 
                map { { '@src'  => $b->($_) } } 
                    (@scripts, @{ $view_args->{vars}{'head script.local'} }) ],
            'head link.local'   => [ 
                map { { '@href' => $b->($_) } } 
                    (@styles, @{ $view_args->{vars}{'head link.local'} }) ],
            '#messages'   => $messages,
            'title'       => $main_title,
            '.masthead-title' => $title,
            %menu_vars,
            '#breadcrumb li' => [ map {
                { 'a' => $_->{label}, 'a@href' => $b->($_->{href}) },
            } $ctx->response->breadcrumb_links ],
            '#content'    => $self->render(template => $template, vars => $vars),
        },
    )->{dom}->toStringHTML;
}


sub available_menu_items {
    my ($self, $ctx, $name) = @_;

    return grep { 
        my $url = $_->{href}; $url =~ s{\?.*$}{};

        my $match = $self->app->router->match($url);
        return unless $match;
        my $access_level_needed = $match->access_level;
        $self->check_access(
            user       => $ctx->session->{user},
            repository => $match->mapping->{repository} // '-',
            needs      => $access_level_needed,
        );
    } $ctx->response->navigation_menu($name);
}


sub render_links {
    my ($self, $ctx, $links) = validated_list(\@_,
        context  => { isa => 'Yukki::Web::Context' },
        links    => { isa => 'ArrayRef[HashRef]' },
    );

    my $b = sub { $ctx->rebase_url($_[0]) };

    return $self->render(
        template => 'links.html',
        vars     => {
            'li' => [ map {
                { 'a' => $_->{label}, 'a@href' => $b->($_->{href}) },
            } @$links ],
        },        
    );
}


sub render {
    my ($self, $template, $vars) = validated_list(\@_,
        template   => { isa => 'Str', coerce => 1 },
        vars       => { isa => 'HashRef', default => {} },
    );
    
    my $template_file = $self->locate('template_path', $template);
    
    return $self->semantic->process($template_file, $vars);
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::View - base class for Yukki::Web views

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

This is the base class for all L<Yukki::Web> views.

=head1 ATTRIBUTES

=head2 app

This is the L<Yukki::Web> singleton.

=head2 markdown

This is the L<Text::MultiMarkdown> object for rendering L</yukkitext>. Do not
use.

Provides a C<format_markdown> method delegated to C<markdown>. Do not use.

=head2 semantic

This is the L<Template::Semantic> object that transforms the templates. Do not use.

=head1 METHODS

=head2 render_page

  my $document = $self->render_page({
      template => 'foo.html',
      context  => $ctx,
      vars     => { ... },
  });

This renders the given template and places it into the content section of the
F<shell.html> template.

The C<context> is used to render parts of the shell template.

The C<vars> are processed against the given template with L<Template::Semantic>.

=head2 available_menu_items

  my @items = $self->available_menu_items($ctx, 'menu_name');

Retrieves the navigation menu from the L<Yukki::Web::Response> and purges any links that the current user does not have access to.

=head2 render_links

  my $document = $self->render_links(\@navigation_links);

This renders a set of links using the F<links.html> template.

=head2 render

  my $document = $self->render({
      template => 'foo.html',
      vars     => { ... },
  });

This renders the named template using L<Template::Semantic>. The C<vars> are
used as the ones passed to the C<process> method.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
