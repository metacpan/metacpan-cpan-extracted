package WWW::MetaForge::ArcRaiders::CLI;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: CLI application for MetaForge ARC Raiders API

use Moo;
use WWW::MetaForge::ArcRaiders;
use Getopt::Long qw(:config pass_through);
use namespace::clean;
use MooX::Cmd;

has debug => (
  is      => 'ro',
  default => sub { $ENV{WWW_METAFORGE_ARCRAIDERS_DEBUG} // 0 },
);

has no_cache => (
  is      => 'ro',
  default => sub { $ENV{WWW_METAFORGE_ARCRAIDERS_NO_CACHE} // 0 },
);

has json => (
  is      => 'ro',
  default => sub { $ENV{WWW_METAFORGE_ARCRAIDERS_JSON} // 0 },
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  # Parse global options from @ARGV before MooX::Cmd processes it
  my ($debug, $no_cache, $json);
  GetOptions(
    'debug|d'    => \$debug,
    'no-cache'   => \$no_cache,
    'json|j'     => \$json,
  );

  my $args = $class->$orig(@args);
  $args->{debug}    = $debug    if $debug;
  $args->{no_cache} = $no_cache if $no_cache;
  $args->{json}     = $json     if $json;

  return $args;
};

has api => (
  is      => 'lazy',
  builder => '_build_api',
);

sub _build_api {
  my ($self) = @_;
  return WWW::MetaForge::ArcRaiders->new(
    debug     => $self->debug,
    use_cache => !$self->no_cache,
  );
}

sub execute {
  my ($self, $args, $chain) = @_;

  # No subcommand given - show help
  if (!@$chain || @$chain == 1) {
    print "metaforge-arcraiders - CLI for MetaForge ARC Raiders API\n\n";
    print "Usage: metaforge-arcraiders <command> [options]\n\n";
    print "Commands:\n";
    print "  items    List all items (or search)\n";
    print "  item     Show details for a single item\n";
    print "  quests   List all quests\n";
    print "  quest    Show details for a single quest\n";
    print "  arcs     List all ARCs\n";
    print "  arc      Show details for a single arc\n";
    print "  events   Show event timers\n";
    print "  event    Show details for a single event\n";
    print "  traders  List all traders\n";
    print "\nOptions:\n";
    print "  -d, --debug     Enable debug output\n";
    print "  -j, --json      Output as JSON\n";
    print "  --no-cache      Disable caching\n";
    print "\nExamples:\n";
    print "  metaforge-arcraiders items --search Ferro\n";
    print "  metaforge-arcraiders item ferro-i\n";
    print "  metaforge-arcraiders items --page 3\n";
    print "  metaforge-arcraiders quests --all\n";
    print "  metaforge-arcraiders quest a-bad-feeling\n";
    print "  metaforge-arcraiders events\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI - CLI application for MetaForge ARC Raiders API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use WWW::MetaForge::ArcRaiders::CLI;
  WWW::MetaForge::ArcRaiders::CLI->new_with_cmd;

=head1 DESCRIPTION

Main CLI class for the ARC Raiders API client. Uses L<MooX::Cmd> for
subcommand handling.

=head1 ATTRIBUTES

=head2 debug

Enable debug output. Use C<--debug> or C<-d> flag, or set via
C<WWW_METAFORGE_ARCRAIDERS_DEBUG> environment variable.

=head2 no_cache

Disable response caching. Use C<--no-cache> flag, or set via
C<WWW_METAFORGE_ARCRAIDERS_NO_CACHE> environment variable.

=head2 json

Output results as JSON. Use C<--json> or C<-j> flag, or set via
C<WWW_METAFORGE_ARCRAIDERS_JSON> environment variable.

=head2 api

L<WWW::MetaForge::ArcRaiders> instance.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-metaforge>

  git clone https://github.com/Getty/p5-www-metaforge.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
