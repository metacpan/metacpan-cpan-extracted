package Yeb::Plugin::JSON;
BEGIN {
  $Yeb::Plugin::JSON::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Yeb Plugin for JSON response
$Yeb::Plugin::JSON::VERSION = '0.101';
use Moo;
use JSON::MaybeXS;

has app => ( is => 'ro', required => 1, weak_ref => 1 );

my @json_attrs_untouched = qw(
  ascii latin1 binary pretty indent space_before space_after
  relaxed canonical filter_json_object filter_json_single_key_object
  shrink max_depth max_size 
);

for (@json_attrs_untouched) {
  has $_ => (
    is => 'ro',
    predicate => 'has_'.$_,
  );
}

my @json_attrs_enabled = qw(
  utf8 allow_nonref convert_blessed allow_blessed
);

for (@json_attrs_enabled) {
  has $_ => (
    is => 'ro',
    default => sub { 1 },
  );
}

my @json_attrs = ( @json_attrs_untouched, @json_attrs_enabled );

has json => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ( $self ) = @_;
    my $json = JSON::MaybeXS->new;
    for my $attr (@json_attrs) {
      my $has_attr = 'has_'.$attr;
      if (!$self->can($has_attr) || $self->$has_attr) {
        $json->$attr($self->$attr);
      }
    }
    return $json;
  },
);

has json_class => (
  is => 'ro',
  lazy => 1,
  default => sub { (ref $_[0]->json) },
);

has true => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->json_class->true },
);

has false => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->json_class->false },
);

sub get_vars {
  my ( $self, $user_vars ) = @_;
  my %stash = %{$self->app->cc->stash};
  my %user = defined $user_vars ? %{$user_vars} : ();
  return $self->app->merge_hashs(
    $self->app->cc->export,
    \%user
  );
}

sub BUILD {
  my ( $self ) = @_;
  $self->app->register_function('json',sub {
    my $user_vars = shift;
    my $vars = $self->get_vars($user_vars);
    $self->app->cc->content_type('application/json');
    $self->app->cc->body($self->json->encode($vars));
    $self->app->cc->response;
  });
  $self->app->register_function('true',sub { $self->true });
  $self->app->register_function('false',sub { $self->false });
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::JSON - Yeb Plugin for JSON response

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  package MyYeb;

  use Yeb;

  BEGIN {
    plugin 'JSON';
  }

  r "/" => sub {
    ex key => 'value';
    json { other_key => 'value' };
  };

  1;

=encoding utf8

=head1 FRAMEWORK FUNCTIONS

=head2 json

=head1 SUPPORT

IRC

  Join #web-simple on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb-plugin-json
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb-plugin-json/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
