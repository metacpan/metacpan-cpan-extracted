package Typist::Template::Tags;
use strict;
use warnings;

use Typist::Template::Context qw( pass_tokens_else );

use vars qw( $VERSION );
$VERSION = 0.34;

my $PREFIX = Typist->instance->prefix;

sub import {
    Typist::Template::Context->add_tag(SetVar => \&var_handler);
    Typist::Template::Context->add_tag(GetVar => \&var_handler);
    Typist::Template::Context->add_container_tag(SetVarBlock => \&var_handler);
    Typist::Template::Context->add_conditional_tag(If => \&conditional_handler);
    Typist::Template::Context->add_conditional_tag(
                                               Unless => \&conditional_handler);
    Typist::Template::Context->add_conditional_tag(
                                                IfOne => \&conditional_handler);
    Typist::Template::Context->add_conditional_tag(
                                          UnlessEmpty => \&conditional_handler);
    Typist::Template::Context->add_conditional_tag(
                                           UnlessZero => \&conditional_handler);
    Typist::Template::Context->add_container_tag(Else => \&pass_tokens_else)
      ;    # right thing?
    Typist::Template::Context->add_container_tag(Include => \&include);
    Typist::Template::Context->add_container_tag(Ignore => sub { '' });
}

sub var_handler {
    my ($ctx, $args, $cond) = @_;
    my $tag = $ctx->stash('tag');
    return
      $ctx->error(
                  Typist->translate(
                                   "You used a [_1] tag without any arguments.",
                                   "<$PREFIX$tag>"
                  )
      )
      unless keys %$args && $args->{name};
    if ($tag eq 'SetVar') {
        my $val = defined $args->{value} ? $args->{value} : '';
        $ctx->var($args->{name}, $val);
        return '';
    } elsif ($tag eq 'GetVar') {
        my $val =
          defined $ctx->var($args->{name})
          ? $ctx->var($args->{name})
          : $args->{default};
        return $ctx->error("Uninitialized value in <$tag>.")
          unless defined $val;
        return $val;
    } elsif ($tag eq 'SetVarBlock') {
        my $builder = $ctx->stash('builder');
        my $tokens  = $ctx->stash('tokens');
        defined(my $out = $builder->build($ctx, $tokens, $cond))
          or return $ctx->error($builder->errstr);
        $ctx->var($args->{name}, $out);
        return '';
    }
}

sub conditional_handler {
    my ($ctx, $args, $cond) = @_;
    my $tag = $ctx->stash('tag');
    $ctx->error($PREFIX . "$tag requires a 'name' or 'tag' argument.")
      if defined $args->{name} || defined $args->{tag};
    my $val;
    if (defined $args->{name}) {
        $val = $ctx->var($args->{name}) || '';
    } else {
        $args->{tag} =~ s/^$PREFIX//;
        my $handler = $ctx->handler_for($args->{tag});
        $ctx->stash('tag', $args->{tag});
        if (defined($handler)) {
            my $value = $handler->($ctx, {%$args});
            if (defined($value) && $value ne '') {    # want to include "0" here
                $val = $ctx->pass_tokens($ctx, $args, $cond);
            } else {
                $val = $ctx->pass_tokens_else($ctx, undef, $cond);
            }
        } else {
            $val = $ctx->pass_tokens_else($ctx);
        }
        $ctx->unstash('tag');
    }
    if ($tag eq 'Unless') {
        return !$val;
    } elsif ($tag eq 'UnlessEmpty') {
        return $val ne '';
    } elsif ($tag eq 'UnlessZero') {
        return $val != 0;
    } elsif ($tag eq 'IfOne') {
        return $val == 1;
    } else {    # If
        return $val;
    }
}

sub include {    # file only. option to run through builder??? IncludeModule?
    my ($arg, $cond) = @_[1, 2];
    my $file = $arg->{file};
    require File::Spec;
    my @paths =
      ($file, map File::Spec::catfile($_, $file), Typist->instance->tmpl_path);
    my $path;
    for my $p (@paths) {
        $path = $p, last if -e $p && -r _;
    }
    return $_[0]
      ->error(Typist->translate("Can't find included file '[_1]'", $path))
      unless $path;
    local *FH;
    open FH, $path
      or return
      $_[0]->error(
            Typist->translate(
                           "Error opening included file '[_1]': [_2]", $path, $!
            )
      );
    my $c = '';
    local $/;
    $c = <FH>;
    close FH;
    $c;
}

1;

=head1 NAME

Typist::Template::Tag - Standard template tags plugin

=head1 TAGS

NOTE: These tags will be prefixed with the value from
C<prefix> in the instance of L<Typist>. By default this is
'MT'

=over

=item SetVar

=item GetVar

=item SetVarBlock

=item If

=item Unless

=item IfOne

=item UnlessEmpty

=item UnlessZero

=item Else

=item Include

=item Ignore

=back

=head1 TO DO

Add <MTLoop name="context_name" offset="" limit=""></MTLoop>

How does this connect up with the stash or vars though?

=end
