package XML::FeedWriter;

use strict;
use warnings;
use Carp;

our $VERSION = '0.06';

my %supported = (
  'RSS20'   => 'RSS20',
  'RSS 2.0' => 'RSS20',
  '2.0'     => 'RSS20',
  2         => 'RSS20',  # in case version specified as a number
);

sub new {
  my ($class, %options) = @_;

  my $version = delete $options{version} || '2.0';

  croak "not yet supported: $version" unless $supported{$version};

  my $package = __PACKAGE__.'::'.$supported{$version};
  eval "require $package;" or die $@;

  $package->new(%options);
}

1;

__END__

=head1 NAME

XML::FeedWriter - simple RSS writer

=head1 SYNOPSIS

    use XML::FeedWriter;

    # let's create a writer.

    my $writer = XML::FeedWriter->new(

      # specify type/version; RSS 2.0 by default
      version     => '2.0',

      # and channel info
      title       => 'feed title',
      link        => 'http://example.com',
      description => 'blah blah blah',
    );

    # add as many items as you wish (and spec permits).

    $writer->add_items(
      # each item should be a hash reference
      {
        title       => 'first post',
        description => 'plain text of the first post',
        link        => 'http://example.com/first_post',
        updated     => time(),  # will be converted to a pubDate
        creator     => 'me',  # alias for "dc:creator"
      },
      {
        title       => 'second post',
        description => '<p>html of the second post</p>',
        link        => 'http://example.com/second_post',
        pubdate     => DateTime->now, # will be formatted properly
        creator     => 'someone',
      },
    );

    # this will close several tags such as root 'rss'.

    $writer->close;

    # then, if you want to save the feed to a file

    $writer->save('path_to_file.xml');

    # or just use it as an xml string.

    my $string = $writer->as_string;

=head1 DESCRIPTION

This is yet another simple feed writer. Not for parsing. Just to write. And as of 0.01, it only can write an RSS 2.0 feed. Then, what's the point?

L<XML::RSS> does almost fine. But when you pass it a long html for description, you'll see a lot of C<&#x3C> and the likes. I don't like that.

XML::FeedWriter also converts date/time information to a required format. You don't need to prepare a properly formatted date/time string by yourself.

And I'm too lazy to specify well-known modules or their namespaces again and again. Several aliases are provided such as 'creator' => 'dc:creator'.

In short, if you want completeness, use L<XML::RSS> (or L<XML::Feed> in that sense). If you're lazy, XML::FeedWriter may be a good option.

=head1 METHODS

=head2 new

Creates a writer object (actually, this returns an object of a subordinate class according to the version you specified).

Required (channel) elements may vary in the future but you usually need to specify:

=over 4

=item version

RSS version. As of 0.01, only 2.0 and its aliases are supported, and will be set to 2.0 by default.

=item title

Feed title, which should match the name of your website.

=item link

URI of your website.

=item description

Feed description.

=back

You may specify as many channel elements as you wish.

Some minor elements may require hash/array references to specify extra attributes or child elements. Basically, a hash reference will be considered as child elements, and an array reference will be considered as a value of the elements plus a hash of attributes, but there're exceptions. See appropriate pod for details.

XML::FeedWriter also accepts C<encoding> option ('utf-8' by default) and C<no_cdata> option, if you really care.

=head2 add_items

Adds items to the feed. Each item should be a hash reference, and characters are expected to be C<Encode::decode>d perl strings.

=head2 close

Closes several known tags such as 'rss' and 'channel'.

=head2 save

Saves the feed to a file. The feed will be C<Encode::encode>d. So, if you really want to use octets while adding items, avoid this and save the result of C<as_string> by yourself.

=head2 as_string

Returns the feed as a string. This is supposed to be a (C<Encode::decode>d) perl string but actually this doesn't care if the string is flagged or not.

=head1 SEE ALSO

L<XML::FeedWriter::RSS20>

L<XML::RSS>, L<XML::Feed>, L<XML::Writer>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
