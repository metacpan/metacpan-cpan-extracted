# NAME

WWW::Eksi - Interface for Eksisozluk.com

# DESCRIPTION

An interface for Eksisozluk, a Turkish social network.
Provides easy access to entries and lists of entries.

# SYNOPSIS

    use WWW::Eksi;
    my $e = WWW::Eksi->new;

    # Last week's most popular entries
    my @ghebe_fast = $e->ghebe;    # might get rate limited
    my @ghebe_slow = $e->ghebe(5); # add a politeness delay

    # Yesterday's most popular entries
    my @doludolu   = $e->doludolu(5);

    # Single entry
    my $entry   = $e->download_entry(1);

# METHODS

## new

Returns a new WWW::Eksi object.

## download\_entry($id)

Takes entry id as argument, returns its data (if available) as follows.

    {
      entry_url      => Str
      topic_url      => Str
      topic_title    => Str
      topic_channels => [Str]

      author_name    => Str
      author_url     => Str
      author_id      => Int

      body_raw       => Str
      body_text      => Str (html tags removed)
      body_processed => Str (html tags processed)
      fav_count      => Int
      create_time    => DateTime
      update_time    => DateTime
    }

## ghebe($politeness\_delay)

Returns an array of entries for top posts of last week.
Ordered from more popular to less popular.

## doludolu($politeness\_delay)

Returns an array of entries for top posts of yesterday.
Ordered from more popular to less popular.
This is an alternative list to DEBE, which is discontinued.

# AUTHOR

Kivanc Yazan `<kyzn at cpan.org>`

# CONTRIBUTORS

Mohammad S Anwar, `<mohammad.anwar at yahoo.com>`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kivanc Yazan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Content you reach by using this module might be subject to copyright
terms of Eksisozluk. See eksisozluk.com for details.
