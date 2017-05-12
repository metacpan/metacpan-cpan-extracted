package Yukki::Web::Plugin::YukkiText;
{
  $Yukki::Web::Plugin::YukkiText::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::Plugin';

# ABSTRACT: format text/yukki files using markdown, etc.

use Text::MultiMarkdown;
use Try::Tiny;


has html_formatters => (
    is          => 'ro',
    isa         => 'HashRef[Str]',
    required    => 1,
    default     => sub { +{
        'text/yukki'    => 'yukkitext',
    } },
);

with 'Yukki::Web::Plugin::Role::Formatter';


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
        strip_metadata          => 1,
    );
}


sub yukkilink {
    my ($self, $params) = @_;

    my $file       = $params->{file};
    my $ctx        = $params->{context};
    my $repository = $file->repository_name;
    my $link       = $params->{link};
    my $label      = $params->{label};

    $link =~ s/^\s+//; $link =~ s/\s+$//;

    my ($repo_name, $local_link) = split /:/, $link, 2 if $link =~ /:/;
    if (defined $repo_name and defined $self->app->settings->{repositories}{$repo_name}) {
        $repository = $repo_name;
        $link       = $local_link;
    }
    
    # If we did not get a label, make the label into the link
    if (not defined $label) {
        ($label) = $link =~ m{([^/]+)$};
        $link = $self->app->munge_label($link);
    }

    my @base_name;
    if ($file->full_path) {
        $base_name[0] = $file->full_path;
        $base_name[0] =~ s/\.yukki$//g;
    }

    $link = join '/', @base_name, $link if $link =~ m{^\./};
    $link =~ s{^/}{};
    $link =~ s{/\./}{/}g;

    $label =~ s/^\s*//; $label =~ s/\s*$//;

    my $b = sub { $ctx->rebase_url($_[0]) };

    my $link_repo = $self->model('Repository', { name => $repository });
    my $link_file = $link_repo->file({ full_path => $link });

    my $class = $link_file->exists ? 'exists' : 'not-exists';
    return qq{<a class="$class" href="}.$b->("page/view/$repository/$link").qq{">$label</a>};
}


sub yukkiplugin {
    my ($self, $params) = @_;

    my $ctx         = $params->{context};
    my $plugin_name = $params->{plugin_name};
    my $arg         = $params->{arg};

    my $text;

    my @plugins = $self->app->format_helper_plugins;
    PLUGIN: for my $plugin (@plugins) {
        my $helpers = $plugin->format_helpers;
        if (defined $helpers->{ $plugin_name }) {
            $text = try {
                my $helper = $helpers->{ $plugin_name };
                $plugin->$helper({
                    context     => $ctx,
                    file        => $params->{file},
                    helper_name => $plugin_name,
                    arg         => $arg,
                });
            }
            
            catch {
                warn "Plugin Error: $_";
            };

            last PLUGIN if defined $text;
        }
    }

    $text //= "{{$plugin_name:$arg}}";
    return $text;
}


sub yukkitext {
    my ($self, $params) = @_;

    my $file       = $params->{file};
    my $position   = 0 + ($params->{position} // -1);
    my $repository = $file->repository_name;
    my $yukkitext  = $file->fetch;

    $yukkitext =~ s[(.{$position}.*?)$][$1<span id="yukkitext-caret">&nbsp;</span>]sm
        if $position >= 0;

    # Yukki Links
    $yukkitext =~ s{ 
        (?<!\\)                 # \ will escape the link
        \[\[ \s*                # [[ to start it

            (?: ([\w]+) : )?    # repository: is optional
            ([^|\]]+) \s*       # link/to/page is mandatory

            (?: \|              # | to split link from label
                ([^\]]+)        # a pretty label (needs trimming)
            )?                  # is optional

        \]\]                    # ]] to end
    }{ 
        $self->yukkilink({ 
            %$params, 
            
            repository => $1 // $repository, 
            link       => $2, 
            label      => $3,
        });
    }xeg;

    # Handle escaped links, hide the escape
    $yukkitext =~ s{ 
        \\                      # \ will escape the link
        (\[\[ \s*               # [[ to start it

            (?: [\w]+ : )?      # repository: is optional
            [^|\]]+ \s*         # link/to/page is mandatory

            (?: \|              # | to split link from label
                [^\]]+          # a pretty label (needs trimming)
            )?                  # is optional

        \]\])                    # ]] to end
    }{$1}gx;

    # Yukki Plugins
    $yukkitext =~ s{
        (?<!\\)                 # \ will escape the plugin
        \{\{ \s*                # {{ to start it

            ([^:]+) :           # plugin_name: is required

            (.*?)               # plugin arguments

        \}\}                    # }} to end
    }{
        $self->yukkiplugin({
            %$params,

            plugin_name => $1,
            arg         => $2,
        });
    }xegms;

    # Handle the escaped plugin thing
    $yukkitext =~ s{
        \\                      # \ will escape the plugin
        (\{\{ \s*               # {{ to start it

            [^:]+ :             # plugin_name: is required

            .*?                 # plugin arguments

        \}\})                   # }} to end
    }{$1}xgms;

    my $formatted = '<div>' . $self->format_markdown($yukkitext) . '</div>';

    # Just in case markdown mangled the caret marker:
    $formatted =~ s[&lt;span id="yukkitext-caret"&gt;&amp;nbsp;&lt;/span&gt;]
                   [<span id="yukkitext-caret">&nbsp</span>];

    return $formatted;
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin::YukkiText - format text/yukki files using markdown, etc.

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  # Plugins are not used directly...

  my $repo = $self->model('Repository', { name => 'main' });
  my $file = $repo->file({ full_path => "some-file.yukki' });
  my $html = $file->fetch_formatted($ctx);

=head1 DESCRIPTION

Yukkitext formatting is based on Multi-Markdown, which is an extension to regular markdown that adds tables, metadata, and a few other tidbits. In addition to this, yukkitext adds linking using double-bracket notation:

  [[ A Link ]]
  [[ ./A Sub-Page Link ]]
  [[ ./A Sub-Dir/Sub-Page Link ]]
  [[ ./a-sub-dir/sub-page-link.pdf | Sub-Page PDF ]]

This link format is based loosely upon the format used by MojoMojo, which I was using prior to developing Yukki.

It also adds support for format helpers usinga  double-curly brace notation:

  {{attachment:Path/To/Attachment.pdf}}
  {{=:5 + 5}}

=head1 ATTRIBUTES

=head2 html_formatters

This returns the yukkitext formatter for "text/yukki".

=head2 markdown

This is the L<Text::MultiMarkdown> object for rendering L</yukkitext>. Do not
use.

Provides a C<format_markdown> method delegated to C<markdown>. Do not use.

=head1 METHODS

=head2 yukkilink

Used to help render yukkilinks. Do not use.

=head2 yukkiplugin

Used to render plugged in markup. Do not use.

=head2 yukkitext

  my $html = $view->yukkitext({
      context    => $ctx,
      repository => $repository_name,
      page       => $page,
      file       => $file,
  });

Yukkitext is markdown plus some extra stuff. The extra stuff is:

  [[ main:/link/to/page.yukki | Link Title ]] - wiki link
  [[ /link/to/page.yukki | Link Title ]]      - wiki link
  [[ /link/to/page.yukki ]]                   - wiki link

  {{attachment:file.pdf}}                     - attachment URL

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
