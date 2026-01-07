package WWW::MetaForge::ArcRaiders::CLI::Cmd::Traders;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List traders from the ARC Raiders API

use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my $traders = $app->api->traders;

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode(
      [ map { $_->_raw } @$traders ]
    );
    return;
  }

  if (!@$traders) {
    print "No traders found.\n";
    return;
  }

  for my $trader (@$traders) {
    my $name = $trader->name // 'Unknown';
    my $inv_count = $trader->inventory ? scalar(@{$trader->inventory}) : 0;
    printf "%-30s  (%d items)\n", $name, $inv_count;
  }

  printf "\n%d trader(s) found.\n", scalar(@$traders);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Traders - List traders from the ARC Raiders API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  arcraiders traders
  arcraiders traders --json

=head1 DESCRIPTION

List all traders from the ARC Raiders API. Displays trader names and their
inventory counts in a simple table format.

Use the C<--json> flag (inherited from parent command) to output raw API data
as JSON instead of formatted text.

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
