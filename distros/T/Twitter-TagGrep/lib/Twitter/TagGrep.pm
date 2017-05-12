package Twitter::TagGrep;

use strict;
use warnings;

our $VERSION = '1.0000';

sub prefix {
  my $self = shift;

  if (defined $_[0]) {
    $self->{prefix} = $_[0];
    undef $self->{tag_regex};
  }
  return $self->{prefix};
}

sub add_prefix {
  my $self = shift;

  $self->{prefix} = join '', $self->{prefix}, @_;
  undef $self->{tag_regex};
  return $self->{prefix};
}

sub tags {
  my $self = shift;

  if (@_) {
    if (ref $_[0] eq 'ARRAY') {
      $self->{tags} = $_[0];
    } else {
      $self->{tags} = [ @_ ];
    }
    undef $self->{tag_regex};
  }

  return @{$self->{tags}};
}

sub add_tag {
  my $self = shift;

  for my $tag (@_) {
    if (ref $tag eq 'ARRAY') {
      push @{$self->{tags}}, @$tag;
    } else {
      push @{$self->{tags}}, $tag;
    }
  }

  undef $self->{tag_regex};
  return @{$self->{tags}};
}


sub grep_tags {
  my $self = shift;
  my $timeline = shift;

  $self->_gen_tag_regex unless $self->{tag_regex};

  return reverse grep {
    my @tags = $_->{text} =~ /$self->{tag_regex}/gi;
    $_->{tags} = \@tags if @tags;
  } @$timeline;
}


sub new {
  my ($class, %params) = @_;

  my $self = {
              prefix    => defined $params{prefix} ? $params{prefix} : '#',
              tags      => [],
              tag_regex => undef,
             };
  bless $self, $class;

  $self->tags($params{tags}) if $params{tags};

  return $self;
}

sub _gen_tag_regex {
  my $self = shift;

  $self->{tag_regex} = '(?:\A|\s)[' . $self->prefix . ']('
                       . (join '|', $self->tags) . ')\b';

#  print $self->{tag_regex}, "\n";
}

=head1 NAME

Twitter::TagGrep - Find messages with selected tags in Twitter timelines

=head1 VERSION

Version 1.00


=head1 SYNOPSIS

    use Twitter::TagGrep;
    use Net::Twitter;

    my $twit = Net::Twitter->new( ... );

    my $tg = Twitter::TagGrep->new( prefix => '#!',
                                    tags => [ 'foo', 'bar' ] );

    my $timeline = $twit->friends_timeline;

    # Get tweets containing one or more of #foo, #bar, !foo, or !bar
    my @matches = $tg->grep_tags($timeline);

    for my $tweet (@matches) {
      print $tweet->{text}, "\n", join(', ', @{$tweet->{tags}}), "\n";
    }

=head1 METHODS

=over

=item C<new>

Initializes and returns a new Twitter::TagGrep object.

Takes the following optional parameters:

=over

=item C<prefix>

A string defining the set of tag prefixes to recognize.  Defaults to '#'
(hashtags) if not specified.

=item C<tags>

Either a single tag to search for or a reference to an array containing
any number of tags to search for.

=back

=item C<prefix>

If passed a parameter, replaces the set of recognized prefixes.

Returns the set of recognized prefixes as a single string value.

=item C<add_prefix>

Appends all parameters to the set of recognized prefixes and returns that
set.

=item C<tags>

If passed one or more parameters, sets the list of recognized tags.  Any
array references will add the contents of the referenced array, while other
parameters will be used as-is.

Returns an array of recognized tags.

=item C<add_tag>

As C<tags>, but appends to the list of tags rather than replacing it.

=item C<grep_tags>

Takes a single scalar parameter referencing a Twitter timeline as returned
by Net::Twitter's *_timeline functions.

Returns an array of tweets found within that timeline which contain at least
one instance of (any character found in the C<prefix> setting) followed by
(any string listed in the C<tags> setting).  This check is case-insensitive.

A list of tags found in each returned tweet is added to it under the "tags"
hash key.

The tag must normally stand alone as a word by itself, but can be matched as a
substring by using regular expression metacharacters in C<tags> values.
Wildcard searches may also be done in this fashion, such as using the value
"\w+" to locate all tweets containing one or more tags.

=back

=head1 AUTHOR

Dave Sherohman, C<< <dave at sherohman.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-twitter-taggrep at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Twitter-TagGrep>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Twitter::TagGrep


The latest version of this module may be obtained from

    git://sherohman.org/tag_grep


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Twitter-TagGrep>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Twitter-TagGrep>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Twitter-TagGrep>

=item * Search CPAN

L<http://search.cpan.org/dist/Twitter-TagGrep/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Sherohman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Twitter::TagGrep
