package Text::Handlebars;
our $AUTHORITY = 'cpan:DOY';
$Text::Handlebars::VERSION = '0.05';
use strict;
use warnings;
# ABSTRACT: http://handlebarsjs.com/ for Text::Xslate

use Text::Xslate 2.0000;
use base 'Text::Xslate';

use Scalar::Util 'weaken';
use Try::Tiny;


sub default_helpers {
    my $class = shift;
    return {
        with => sub {
            my ($context, $new_context, $options) = @_;
            return $options->{fn}->($new_context);
        },
        each => sub {
            my ($context, $list, $options) = @_;
            return join '', map { $options->{fn}->($_) } @$list;
        },
        if => sub {
            my ($context, $conditional, $options) = @_;
            return $conditional
                ? $options->{fn}->($context)
                : $options->{inverse}->($context);
        },
        unless => sub {
            my ($context, $conditional, $options) = @_;
            return $conditional
                ? $options->{inverse}->($context)
                : $options->{fn}->($context);
        },
    };
}

sub default_functions {
    my $class = shift;
    return {
        %{ $class->SUPER::default_functions(@_) },
        %{ $class->default_helpers },
    };
}

sub options {
    my $class = shift;

    my $options = $class->SUPER::options(@_);

    $options->{compiler} = 'Text::Handlebars::Compiler';
    $options->{helpers} = {};

    return $options;
}

sub _register_builtin_methods {
    my $self = shift;
    my ($funcs) = @_;

    weaken(my $weakself = $self);
    $funcs->{'(render_string)'} = sub {
        my ($to_render, $vars) = @_;
        return $weakself->render_string($to_render, $vars);
    };
    $funcs->{'(make_block_helper)'} = sub {
        my ($vars, $code, $raw_text, $else_raw_text, $hash) = @_;

        my $options = {};
        $options->{fn} = sub {
            my ($new_vars) = @_;
            $new_vars = {
                %{ canonicalize_vars($new_vars) },
                '..' => $vars,
            };
            return $weakself->render_string($raw_text, $new_vars);
        };
        $options->{inverse} = sub {
            my ($new_vars) = @_;
            $new_vars = {
                %{ canonicalize_vars($new_vars) },
                '..' => $vars,
            };
            return $weakself->render_string($else_raw_text, $new_vars);
        };
        $options->{hash} = $hash;

        return sub { $code->(@_, $options); };
    };

    for my $helper (keys %{ $self->{helpers} }) {
        $funcs->{$helper} = $self->{helpers}{$helper};
    }
}

sub _compiler {
    my $self = shift;

    if (!ref($self->{compiler})) {
        my $compiler = $self->SUPER::_compiler(@_);
        $compiler->define_helper(keys %{ $self->{helpers} });
        $compiler->define_helper(keys %{ $self->default_helpers });
        return $compiler;
    }
    else {
        return $self->SUPER::_compiler(@_);
    }
}

sub render_string {
    my $self = shift;
    my ($string, $vars) = @_;

    return $self->SUPER::render_string($string, canonicalize_vars($vars));
}

sub render {
    my $self = shift;
    my ($name, $vars) = @_;

    return $self->SUPER::render($name, canonicalize_vars($vars));
}

sub canonicalize_vars {
    my ($vars) = @_;
    if (ref($vars) && ref($vars) eq 'HASH') {
        return $vars;
    }
    else {
        return { '.' => $vars };
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Handlebars - http://handlebarsjs.com/ for Text::Xslate

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Text::Handlebars;

  my $handlebars = Text::Handlebars->new(
      helpers => {
          fullName => sub {
              my ($context, $person) = @_;
              return $person->{firstName}
                   . ' '
                   . $person->{lastName};
          },
      },
  );

  my $vars = {
      author   => { firstName => 'Alan', lastName => 'Johnson' },
      body     => "I Love Handlebars",
      comments => [{
          author => { firstName => 'Yehuda', lastName => 'Katz' },
          body   => "Me too!",
      }],
  };

  say $handlebars->render_string(<<'TEMPLATE', $vars);
  <div class="post">
    <h1>By {{fullName author}}</h1>
    <div class="body">{{body}}</div>

    <h1>Comments</h1>

    {{#each comments}}
    <h2>By {{fullName author}}</h2>
    <div class="body">{{body}}</div>
    {{/each}}
  </div>
  TEMPLATE

produces

  <div class="post">
    <h1>By Alan Johnson</h1>
    <div class="body">I Love Handlebars</div>

    <h1>Comments</h1>

    <h2>By Yehuda Katz</h2>
    <div class="body">Me Too!</div>
  </div>

=head1 DESCRIPTION

This module subclasses L<Text::Xslate> to provide a parser for
L<Handlebars|http://handlebarsjs.com/> templates. In most ways, this module
functions identically to Text::Xslate, except that it parses Handlebars
templates instead.

Text::Handlebars accepts an additional constructor parameter of C<helpers> to
define Handlebars-style helper functions. Standard helpers are identical to
functions defined with the C<function> parameter, except that they receive the
current context implicitly as the first parameter (since perl doesn't have an
implicit C<this> parameter). Block helpers also receive the context as the
first parameter, and they also receive the C<options> parameter as a hashref.
As an example:

  sub {
      my ($context, $items, $options) = @_;

      my $out = "<ul>";

      for my $item (@$items) {
          $out .= "<li>" . $options->{fn}->($item) . "</li>";
      }

      return $out . "</ul>\n";
  },

defines a simple block helper to generate a C<< <ul> >> list.

Text::Handlebars also overrides C<render> and C<render_string> to allow using
any type of data (not just hashrefs) as a context (so rendering a template
consisting of only C<{{.}}> works properly).

=head1 BUGS/CAVEATS

=over 4

=item *

The auto-indenting behavior for partials is not yet implemented, due to
limitations in Text::Xslate.

=item *

The C<data> parameter for C<@foo> variables when calling
C<< $options->{fn}->() >> is not supported, because I don't understand its
purpose. If someone wants this functionality, feel free to let me know, and
tell me why.

=back

Please report any bugs to GitHub Issues at
L<https://github.com/doy/text-handlebars/issues>.

=head1 SEE ALSO

L<http://handlebarsjs.com/>

L<Text::Xslate>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Text::Handlebars

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Text-Handlebars>

=item * Github

L<https://github.com/doy/text-handlebars>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Handlebars>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Handlebars>

=back

=for Pod::Coverage default_helpers
  default_functions
  options
  render_string
  render
  canonicalize_vars

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
