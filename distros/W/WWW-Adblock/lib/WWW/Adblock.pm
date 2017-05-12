package WWW::Adblock;

use strict;
use warnings;
use 5.006;
use IO::File;
use WWW::Adblock::RegexFilter;

our $VERSION = "0.02";

=head1 NAME

WWW::Adblock - a simple implementation of Adblock Plus in Perl

=head1 SYNOPSIS

  use WWW::Adblock;
  my $adblock = WWW::Adblock->new();
  $adblock->load('/path/to/filters.txt');
  if ($adblock->filter('http://example.com/1x1.gif')) {
    # it matched a filter rule
  }

=head1 DESCRIPTION

This is a very simplified implementation of Adblock Plus (the popular browser extension) in Perl.  Currently it only supports URI filtering and does not implement the per-element blocking offered by the extension.

=head2 Methods

=head3 new

  my $adblock = WWW::Adblock->new();
  my $adblock = WWW::Adblock->new( filters => $target );

Creates a new object.  If C<$filters> is given it is passed to C<< $adblock->load >>.

=cut

# The constructor of an object is called new() by convention.  Any
# method may construct an object and you can have as many as you like.

sub new {
    my ( $class, %args ) = @_;

    my $self = bless( {}, $class );

    $self->{filters} = {};

    return $self;
}

=head3 load

  $adblock->load('/path/to/rules.txt');

Loads and parses a ruleset.  May be called multiple times, new rules are added to the existing ones.

=cut

sub load {
    my ( $self, $file ) = @_;

    my $rules = 0;

    my $fh = new IO::File $file, O_RDONLY;
    if ( defined $fh ) {
        foreach my $line (<$fh>) {
            chomp $line;

            next if exists $self->{filters}{$line};

            # The first line of the file
            if ( $line =~ m/^\[Adblock/ ) {
                next;

                # A comment line starts with !
            }
            elsif ( $line =~ m/^!/ ) {
                next;

                # Element hiding rules, currently unsupported
            }
            elsif ( $line =~
/^([^\/\*\|\@"]*?)#(?:([\w\-]+|\*)((?:\([\w\-]+(?:[$^*]?=[^\(\)"]*)?\))*)|#([^{}]+))$/
              )
            {
                next;

            }
            else {
                my $filter = WWW::Adblock::RegexFilter->new( 'text' => $line );
                if ( defined $filter ) {
                    $self->{filters}{$line} = $filter;
                    $rules++;
                }
            }
        }
        undef $fh;    # automatically closes the file
    }

    return $rules;
}

=head3 filter

  # Check a $uri
  $adblock->filter($uri);

  # Check a $uri that appeared on a page on $domain
  $adblock->filter($uri, $domain);

Checks a URI to see whether it matches any rules.  Returns 0 for no match, 1 for positive match, 2 for whitelist.

=cut

sub filter {
    my ( $self, $uri, $domain ) = @_;

    return 0 unless defined $uri;

    # TODO: Implement a results cache?  Would help with frequently
    #       hit filters

    foreach my $f ( keys %{ $self->{filters} } ) {
        my $filter = $self->{filters}{$f};
        my $result = $filter->matches( $uri, $domain );
        return $result if $result;
    }

    return 0;
}

=head1 AUTHOR

The idea for this code comes from Adblock Plus.  Find out more at http://adblockplus.org/en/.

Implementation in Perl by David Cannings <david@edeca.net>

=cut

=head1 COPYRIGHT / LICENSE

Copyright (c) 2010 David Cannings. All rights reserved.  
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

1;
