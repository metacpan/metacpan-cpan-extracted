package WWW::EZTV::Episode;
$WWW::EZTV::Episode::VERSION = '0.07';
use Moose;
with 'WWW::EZTV::UA';

# ABSTRACT: Show episode

has show     => is => 'ro', isa => 'WWW::EZTV::Show', required => 1;
has title    => is => 'ro', isa => 'Str', required => 1;
has url      => is => 'ro', isa => 'Mojo::URL', required => 1;
has links    =>
    is      => 'ro',
    handles => {
        find_link => 'first',
        has_links => 'size',
    };

has _parsed  => is => 'ro', lazy => 1, builder => '_parse';

has name     => is => 'ro', lazy => 1,
    default  => sub { shift->_parsed->{name} };

has season     => is => 'ro', lazy => 1,
    default  => sub { shift->_parsed->{season} };

has number     => is => 'ro', lazy => 1,
    default  => sub { shift->_parsed->{number} };

has version     => is => 'ro', lazy => 1,
    default  => sub { shift->_parsed->{version} };

has quality     => is => 'ro', lazy => 1,
    default  => sub { shift->_parsed->{quality} || 'standard' };

has size     => is => 'ro', lazy => 1,
    default  => sub { shift->_parsed->{size} };

sub _parse {
    my $title = shift->title;

    $title =~ /^\s*
      (?<name>.+?)
      \s+
      (?<chapter>
        S (?<season>\d+) E (?<number>\d+)
       |(?<season>\d+) x (?<number>\d+)
       |(?<number>\d+) of (?<total>\d+)
      )
      \s+
      (?<version>
        ((?<quality>\d+p)\s+)?
        (?<team>.*?)
      )
      (?:
        \s+
        \((?<size>
          \d+
          [^\)]+
        )\)
      )?
    \s*$/xi;

    return {
        name    => $+{name} || $title,
        chapter => $+{chapter},
        number  => ($+{number}||0) +0,
        season  => ($+{season}||0) +0,
        total   => ($+{total}||0) +0,
        version => $+{version} || '',
        quality => $+{quality} || 'standard',
        team    => $+{team},
        size    => $+{size}
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::EZTV::Episode - Show episode

=head1 VERSION

version 0.07

=head1 ATTRIBUTES

=head2 has_links

How many episodes has this show.

=head1 METHODS

=head2 find_link

Find first L<WWW::EZTV::Link> object matching the given criteria.
This method accept an anon function.

=head1 AUTHOR

Diego Kuperman <diego@freekeylabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Diego Kuperman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
