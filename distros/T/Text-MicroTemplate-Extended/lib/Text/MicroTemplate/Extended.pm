package Text::MicroTemplate::Extended;
use strict;
use warnings;
use base 'Text::MicroTemplate::File';

our $VERSION = '0.17';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{template_args} ||= {};
    $self->{extension}     ||= '.mt' unless defined $self->{extension};
    my $m = $self->{macro} ||= {};

    # install default macros to support template inheritance
    $m->{extends} = sub {
        $self->render_context->{extends} = $_[0];
    };

    my $super = '';
    $m->{super} = sub { $super };

    $m->{block} = sub {
        my ($name, $code) = @_;

        no strict 'refs';
        my $block;
        if (defined $code) {
            if ($self->render_context->{blocks}{$name}) {
                unshift @{ $self->render_context->{super}{$name}}, {
                    context_ref => ${"$self->{package_name}::_MTREF"},
                    code        => ref($code) eq 'CODE' ? $code : sub { return $code },
                };
            }

            $block = $self->render_context->{blocks}{$name} ||= {
                context_ref => ${"$self->{package_name}::_MTREF"},
                code        => ref($code) eq 'CODE' ? $code : sub { return $code },
            };
        }
        else {
            $block = $self->render_context->{blocks}{$name}
                or die qq[block "$name" does not define];
        }

        if (!$self->render_context->{extends}) {
            my $current_ref = ${"$self->{package_name}::_MTREF"};
            my $rendered = $$current_ref || '';

            $super = Text::MicroTemplate::encoded_string($self->_render_block($_))
                for (@{ $self->render_context->{super}{$name} || [] });

            $$current_ref = $rendered . $self->_render_block($block);
            $super = '';
        }
    };

    $m->{include} = sub {
        $self->include_file(@_);
    };

    for my $name (keys %{ $self->{macro} }) {
        unless ($name =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
            die qq{Invalid macro key name: "$name"};
        }

        no strict 'refs';
        no warnings 'redefine';
        my $code = $self->{macro}{$name};
        *{ $self->package_name . "::$name" }
            = ref $code eq 'CODE' ? $code : sub {$code};
    }

    $self;
}

sub template_args {
    my $self = shift;
    $self->{template_args} = $_[0] if @_;
    $self->{template_args};
}

sub extension {
    my $self = shift;
    $self->{extension} = $_[0] if @_;
    $self->{extension};
}

{
    no warnings 'once';
    *render  = \&render_file;
    *include = \&include_file;
}

sub render_file {
    my $self     = shift;
    my $template = shift;

    my $context = $self->render_context || {};
    $self->render_context($context);

    my $renderer = $self->build_file( $template . $self->extension );
    my $result;

    my $die_msg;
    {
        local $@;
        eval {
            $result = $renderer->(@_);

            my $tmpl = $self->{template};
            $_->{template_ref} ||= \$tmpl for values %{ $context->{blocks} };
        };
        $die_msg = $@;
    }
    unless ($die_msg) {
        if (my $parent = delete $context->{extends}) {
            $result = $self->render($parent);
        }
    }

    $self->render_context(undef);

    die $self->_error($die_msg, 0, $context->{caller} || '')
        if $die_msg;

    $result;
}

sub _render_block {
    my ($self, $block) = @_;

    no strict 'refs';

    my $block_ref   = $block->{context_ref};
    local ${"$self->{package_name}::_MTEREF"} = $block_ref;

    $$block_ref = '';
    my ($result, $die_msg);
    eval {
        $result = $block->{code}->() || $$block_ref || '';
    };
    if ($@) {
        my $context = $self->render_context;
        local $self->{template} = ${ $block->{template_ref} };
        die $self->_error($@, 0, $context->{caller});
    }

    $result;
}

sub include_file {
    my $self     = shift;
    my $template = shift;

    my $renderer = $self->build_file( $template . $self->extension );
    $renderer->(@_);
}

sub render_context {
    my $self = shift;
    $self->{render_context} = $_[0] if @_;
    $self->{render_context};
}

sub build {
    my $self = shift;

    my $context = $self->render_context;
    $context->{code}   = $self->code;
    $context->{caller} = sub {
        my $i = 0;
        while (my @c = caller(++$i)) {
            return "$c[1] at line $c[2]" if $c[0] ne __PACKAGE__;
        }
        '';
    }->();

    $context->{args} = '';
    for my $key (keys %{ $self->template_args || {} }) {
        unless ($key =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
            die qq{Invalid template args key name: "$key"};
        }

        if (ref($self->template_args->{$key}) eq 'CODE') {
            $context->{args} .= qq{my \$$key = \$self->template_args->{$key}->();\n};
        }
        else {
            $context->{args} .= qq{my \$$key = \$self->template_args->{$key};\n};
        }
    }

    $context->{blocks} ||= {};

    my $die_msg;
    {
        local $@;
        if (my $builder = $self->eval_builder()) {
            return $builder;
        }
        $die_msg = $self->_error($@, 0, $context->{caller});
    }
    die $die_msg;
}

sub eval_builder {
    my ($self) = @_;

    local $SIG{__WARN__} = sub {
        print STDERR $self->_error(shift, 0, $self->render_context->{caller});
    };

    eval <<"...";
package $self->{package_name};
sub {
    $self->{render_context}{args}
# line 1
    Text::MicroTemplate::encoded_string(($self->{render_context}{code})->(\@_));
}
...
}

1;

__END__

=head1 NAME

Text::MicroTemplate::Extended - Extended MicroTemplate

=head1 SYNOPSIS

    use Text::MicroTemplate::Extended;
    
    my $mt = Text::MicroTemplate::Extended->new(
        include_path  => ['/path/to/document_root'],
        template_args => { c => $c, stash => $c->stash, },
    );
    
    $mt->render('content'); # render file: /path/to/document_root/content.mt

=head1 DESCRIPTION

L<Text::MicroTemplate::Extended> is an extended template engine based on L<Text::MicroTemplate::File>.

=head1 EXTENDED FEATURES

=head2 Template inheritance

Most notable point of this extended module is Template inheritance.
This concept is used in Python's Django framework.

Template inheritance allows you to build a base "skeleton" template that contains all the common elements of your site and defines blocks that child templates can override.

It's easiest to understand template inheritance by starting with an example:

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
        <link rel="stylesheet" href="style.css" />
        <title><? block title => sub { ?>My amazing site<? } ?></title>
    </head>
    
    <body>
        <div id="sidebar">
            <? block sidebar => sub { ?>
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/blog/">Blog</a></li>
            </ul>
            <? } ?>
        </div>
    
        <div id="content">
            <? block content => sub {} ?>
        </div>
    </body>
    </html>

This template, which we'll call base.mt, defines a simple HTML skeleton document that you might use for a simple two-column page. It's the job of "child" templates to fill the empty blocks with content.

In this example, the C<<? block ?>> tag defines three blocks that child templates can fill in. All the block tag does is to tell the template engine that a child template may override those portions of the template.

A child template might look like this:

    ? extends 'base'
    
    <? block title => sub { ?>My amazing blog<? } ?>
    
    ? block content => sub {
    ? for my $entry (@$blog_entries) {
        <h2><?= $entry->title ?></h2>
        <p><?= $entry->body ?></p>
    ? } # endfor
    ? } # endblock

The C<<? extends ?>> tag is the key here. It tells the template engine that this template "extends" another template. When the template system evaluates this template, first it locates the parent -- in this case, "base.mt".

At that point, the template engine will notice the three C<<? block ?>> tags in base.mt and replace those blocks with the contents of the child template. Depending on the value of blog_entries, the output might look like:

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
        <link rel="stylesheet" href="style.css" />
        <title>My amazing blog</title>
    </head>
    
    <body>
        <div id="sidebar">
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/blog/">Blog</a></li>
            </ul>
        </div>
    
        <div id="content">
            <h2>Entry one</h2>
            <p>This is my first entry.</p>
    
            <h2>Entry two</h2>
            <p>This is my second entry.</p>
        </div>
    </body>
    </html>

Note that since the child template didn't define the sidebar block, the value from the parent template is used instead. Content within a C<<? block ?>> tag in a parent template is always used as a fallback.

You can use as many levels of inheritance as needed. One common way of using inheritance is the following three-level approach:

=over 4

=item 1.

Create a base.mt template that holds the main look-and-feel of your site.

=item 2.

Create a base_SECTIONNAME.mt template for each "section" of your site. For example, base_news.mt, base_sports.mt. These templates all extend base.mt and include section-specific styles/design.

=item 3.

Create individual templates for each type of page, such as a news article or blog entry. These templates extend the appropriate section template.

=back

This approach maximizes code reuse and makes it easy to add items to shared content areas, such as section-wide navigation.

Here are some tips for working with inheritance:

=over 4

=item *

If you use C<<? extends ?>> in a template, it must be the first template tag in that template. Template inheritance won't work, otherwise.

=item *

More C<<? block ?>> tags in your base templates are better. Remember, child templates don't have to define all parent blocks, so you can fill in reasonable defaults in a number of blocks, then only define the ones you need later. It's better to have more hooks than fewer hooks.

=item *

If you find yourself duplicating content in a number of templates, it probably means you should move that content to a C<<? block ?>> in a parent template.

=item *

If you need to get the content of the block from the parent template, the C<< <?= super() ?> >> variable will do the trick. This is useful if you want to add to the contents of a parent block instead of completely overriding it. Data inserted using C<< <?= super() ?> >> will not be automatically escaped, since it was already escaped, if necessary, in the parent template.

=item *

For extra readability, you can optionally give a name to your C<<? } # endblock ?>> tag. For example:

    <? block content => sub { ?>
    ...
    <? } # endblock content ?>

In larger templates, this technique helps you see which C<<? block ?>> tags are being closed.

=back

Finally, note that you can't define multiple C<<? block ?>> tags with the same name in the same template. This limitation exists because a block tag works in "both" directions. That is, a block tag doesn't just provide a hole to fill -- it also defines the content that fills the hole in the parent. If there were two similarly-named C<<? block ?>> tags in a template, that template's parent wouldn't know which one of the blocks' content to use.

=head2 Named template arguments

L<Text::MicroTemplate::Extended> has new template_args option.
Using this option, You can pass named template arguments to your tamplate like:

    my $mf = Text::MicroTemplate::Extended->new(
        template_args => { foo => 'bar', },
        ...
    );

Then in template:

    <?= $foo ?>

This template display 'bar'.

C<template_args> also supports CodeRef as its value life below:

    my $mf = Text::MicroTemplate::Extended->new(
        template_args => { foo => sub { $self->get_foo() } },
        ...
    );

In template, you can C<<?= $foo ?>> to show C<$foo> value. this value is set by calling C<< $self->get_foo >> in template process time.

This feature is useful to set variable does not exists when template object is created.

=head2 Macro

Similar to named arguments, but this feature install your subroutine to template instead of variables.

    my $mh = Text::MicroTemplate::Extended->new(
        macro => {
            hello => sub { return 'Hello World!' },
        },
        ...
    );

And in template:

    <?= hello() ?> # => 'Hello World'

=head2 extension option

There is another new option 'extension'. You can specify template file extension.

If this option is set, you don't have to set extension with render method:

    $mf->render_file('template'); # render template.mt

Default value is '.mt'.

=head2 replace render method

For supporting template inheritance, it is no longer possible to implement original render method. Because extends function requires filename.

So in this module, render method acts same as render_file.

    $mf->render('template');
    $mf->render_file('template');

=head1 METHODS

=head2 new (%options)

    my $mf = Text::MicroTemplate::Extended->new(
        extension     => '.mt',
        template_args => { c => $c, stash => $c->stash },
    );

Create new L<Text::MicroTemplate::Extended> object.

Available options are:

=over 4

=item extension

Template file extension. (Default: '.mt')

=item template_args

Hash Reference of template args.

=item macro

Hash Reference of macros

=back

See L<Text::MicroTemplate::File> for more options.

=head2 render ($template_name, @args)

=head2 render_file ($template_name, @args)

Render $template_name and return result.

=head2 include ($template_name, @args)

=head2 include_file ($template_name, @args)

Render $template_name and return result.

Difference between include and render is that render treats extends and block macros and supports template inheritance but include not.
But render method does not work in template.

    <?= $self->render('template') ?> # does not work!

Instead of above, use:

    <?= $self->include('template') ?>
    
    # or just
    
    <?= include('template') ?>

=head1 INTERNAL METHODS

=head2 build

=head2 eval_builder

=head2 template_args

=head2 extension

=head2 render_context

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

Process flymake-proc finished
