package Tie::DuckDuckGo;

use 5.008_005;

use strict;
use warnings;

our $VERSION = '0.02';

use URI;
use HTML::TreeBuilder::XPath;
use HTTP::Tiny;
use Carp ();

# when tying, call the constructor with data type name
sub TIEARRAY  { shift->new('array',  @_) }
sub TIEHASH   { shift->new('hash',   @_) }
sub TIESCALAR { shift->new('scalar', @_) }

sub new {
    my ($class, $type, $query) = @_;

    # keep track of tied data type
    my $self = bless({type => $type}, $class);

    # for now i'm using a key _tie_ddg,
    # but maybe this can be simplified
    if ($type eq 'array') {
        $self->do_search('_tie_ddg', $query);
    }
    elsif ($type eq 'hash') {
        $self->do_search($query, $query);
    }
    else {
        ## $scalar = 1
        $self->do_search('_tie_ddg', $query, 1);
    }

    $self;
}

sub do_search {
    my ($self, $store_as, $query, $scalar) = @_;
    return unless defined $query;

    # do search
    my $uri = URI->new('https://duckduckgo.com/html/');
    $uri->query_form({ q => $query });

    my $resp = HTTP::Tiny->new->get($uri->as_string);
    my $tree = HTML::TreeBuilder::XPath->new_from_content($resp->{content});

    # build results
    my @results = $tree->findnodes(
        './/div[@id="content"]//div[@id="links"]
          //div[@class =~ /\bresults_links\b/]
          //div[@class =~ /\blinks_main\b/]'
    );

    my @save;
    for my $result (@results) {
        my ($link) = $result->findnodes('.//a[@class="large"]') or next;
        my ($snippet) = $result->findvalues('.//div[@class="snippet"]');

        push @save,
          { url   => $link->attr('href'),
            title => $link->as_text,
            snippet => $snippet,
          };
        last if $scalar; # only save one result for scalar type
    }

    $self->{data}{$store_as} = $scalar ? [$save[0]] : \@save;
}

sub FETCH {
    my ($self, $index) = @_;
    $index = 0 unless defined $index;

    # if we're accessing a hash, we may have not done the search already
    if ($self->{type} eq 'hash') {
        $self->do_search($index, $index) unless exists $self->{data}{$index};

        return $self->{data}{$index};
    }

    $self->{data}{_tie_ddg}[$index];
}

sub FETCHSIZE {
    my $self = shift;
    scalar @{ $self->{data}{_tie_ddg} };
}

sub SHIFT { shift @{shift->{data}{_tie_ddg}} }
sub POP   { pop   @{shift->{data}{_tie_ddg}} }

sub SPLICE {
    my ($self, $offset, $limit) = @_;

    # oops, I don't think we want to write anything to the list
    if (@_ > 3) {
        Carp::carp q,Can't replace search results with list!,;
        return;
    }

    splice(@{$self->{data}{_tie_ddg}}, $offset, $limit);
}

sub EXISTS {
    my ($self, $index) = @_;
    return exists($self->{data}{$index}) if $self->{type} eq 'hash';
    exists $self->{data}{_tie_ddg}[$index];
}

sub STORE   { Carp::carp q,Can't store search results to hash!, }
sub PUSH    { Carp::carp q,Can't push search results to array!, }
sub UNSHIFT { Carp::carp q,Can't unshift search results to array!, }

1;
__END__

=encoding utf-8

=head1 NAME

Tie::DuckDuckGo - Access DuckDuckGo search results via variables

=head1 SYNOPSIS

  use Tie::DuckDuckGo;

  # tie a scalar
  my $search;
  tie $search => 'Tie::DuckDuckGo' => 'perl';

  say $search->{url};
  say $search->{title};
  say $search->{snippet};

  # tie an array
  my @results;
  tie @results => 'Tie::DuckDuckGo' => 'perl';

  for (@results) {
    say $_->{url};
    say $_->{title};
    say $_->{snippet};
  }

  # tie a hash
  my %results;
  tie %results => 'Tie::DuckDuckGo';

  my $result = $results{reddit};
  say $_->{url} for @$result;

=head1 DESCRIPTION

I came across Darren Chamberlain's neat implementation of L<Tie::Google> and
though it would be fun to write a version for DuckDuckGo.

I haven't implemented all of the require methods for tie(). I plan to add those
in a future release.

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Curtis Brandt

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Tie::Google>

=cut
