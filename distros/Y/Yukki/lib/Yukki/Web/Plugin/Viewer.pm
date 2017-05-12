package Yukki::Web::Plugin::Viewer;
{
  $Yukki::Web::Plugin::Viewer::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::Plugin';

use Yukki::Error qw( http_throw );

# ABSTRACT: plugin for custom page viewers


has format_helpers => (
    is          => 'ro',
    isa         => 'HashRef[Str]',
    required    => 1,
    default     => sub { +{
        'show view' => 'show_view_link',
    } },
);

with 'Yukki::Web::Plugin::Role::FormatHelper';


sub show_view_link {
    my ($self, $params) = @_;

    my $ctx  = $params->{context};
    my $file = $params->{file};
    my $view = $params->{arg};

    my $repo = $file->repository_name;
    my $page = $file->full_path;

    my $view_info = $self->app->settings->page_views->{$view};

    unless ($view_info) {
        warn "no such view as '$view' configured in yukki.conf";
        return '';
    }

    my $args = "?view=$view";
       $args = '' if $view eq 'default';

    $ctx->response->add_navigation_item([ qw( page page_bottom ) ] => {
        label => $view_info->{label},
        href  => join('/', 'page/view', $repo, $page)
                . $args,
        sort  => $view_info->{sort},
    });

    return '';
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin::Viewer - plugin for custom page viewers

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  {{show view:slides}}

=head1 DESCRIPTION

This allows the author to create links to custom views that inject additional scripts and/or stylesheets into the view page.

=head1 ATTRIBUTES

=head2 format_helpers

Provides the viewer link.

=head1 METHODS

=head2 show_view_link

Adds the view back into navigation if it is normally hidden.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
