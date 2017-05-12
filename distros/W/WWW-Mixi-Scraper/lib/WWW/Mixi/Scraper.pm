package WWW::Mixi::Scraper;

use strict;
use warnings;

our $VERSION = '0.34';

use String::CamelCase qw( decamelize );
use Module::Find;

use WWW::Mixi::Scraper::Mech;
use WWW::Mixi::Scraper::Utils qw( _uri );

sub new {
  my ($class, %options) = @_;

  my $mode = delete $options{mode};
     $mode = ( $mode && uc $mode eq 'TEXT' ) ? 'TEXT' : 'HTML';

  my $mech = WWW::Mixi::Scraper::Mech->new(%options);

  my $self = bless { mech => $mech, mode => $mode }, $class;

  no strict   'refs';
  no warnings 'redefine';
  foreach my $plugin ( findsubmod 'WWW::Mixi::Scraper::Plugin' ) {
    my ($name) = decamelize($plugin) =~ /(\w+)$/;
    $self->{$name} = $plugin;
    *{"$class\::$name"} = sub {
      my $self = shift;
      my $package = $self->{$name};
      return $package if ref $package;
      eval "require $package" or die $@;
      $self->{$name} = $package->new( mech => $mech, mode => $mode );
    };
  }

  $self;
}

sub parse {
  my ($self, $uri, %options) = @_;

  $uri = _uri($uri) unless ref $uri eq 'URI';

  my $path = $uri->path;
  $path =~ s|^/||;
  $path =~ s|\.pl$||;

  unless ( $self->can($path) ) {
    warn "You don't have a proper plugin to handle $path";
    return;
  }

  foreach my $key ( $uri->query_param ) {
    next if exists $options{$key};
    $options{$key} = $uri->query_param($key);
  }
  $self->$path->parse( %options );
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper - yet another mixi scraper

=head1 SYNOPSIS

    use WWW::Mixi::Scraper;
    my $mixi = WWW::Mixi::Scraper->new(
      email => 'foo@bar.com', password => 'password',
      mode  => 'TEXT'
    );

    my @list = $mixi->parse('http://mixi.jp/new_friend_diary.pl');
    my @list = $mixi->new_friend_diary->parse;

    my @list = $mixi->parse('http://mixi.jp/new_bbs.pl?page=2');
    my @list = $mixi->new_bbs->parse( page => 2 );

    my $diary = $mixi->parse('/view_diary.pl?id=0&owner_id=0');
    my $diary = $mixi->view_diary->parse( id => 0, owner_id => 0 );

    my @comments = @{ $diary->{comments} };

    # for testing
    my $html = read_file('/some/where/mixi.html');
    my $diary = $mixi->parse('/view_diary.pl', html => $html );
    my $diary = $mixi->view_diary->parse( html => $html );

=head1 DESCRIPTION

This is yet another 'mixi' (the largest SNS in Japan) scraper, powered by Web::Scraper. Though APIs are different and incompatible with precedent WWW::Mixi, I'm loosely trying to keep correspondent return values look similar as of writing this (this may change in the future).

WWW::Mixi::Scraper is also pluggable, so if you want to scrape something it can't handle now, add your WWW::Mixi::Scraper::Plugin::<PLfileBasenameInCamel>, and it'll work for you.

=head1 DIFFERENCES BETWEEN TWO

WWW::Mixi has much longer history and is full-stack. The data it returns tended to be more complete, fine-tuned, and raw in many ways (including encoding). However, it tended to suffer from minor html changes as it heavily relies on regexes, and as of writing this (July 2008), it's been broken for months due to a major cosmetic change of mixi in October, 2007.

In contrast, WWW::Mixi::Scraper hopefully tends to survive minor html changes as it relies on XPath/CSS selectors. And basically it uses decoded perl strings, not octets. It's smaller, and pluggable. However, its data is more or less pre-processed and tends to lose some aspects such as proper line breaks. Also, it may be easier to be polluted with garbages. And it may be harder to understand and maintain scraping rules.

Anyway, though a bit limited, ::Scraper is the only practical option right now.

=head1 IF YOU WANT MORE

If you want more features, please send me a patch, or a pull request from your github fork. Just telling me where you want to scrape would be ok but it may take a longer time to implement especially when it's new or less popular and I don't have enough samples.

=head1 ON Plagger::Plugin::CustomFeed::MixiScraper

Usually you want to use this with L<Plagger>, but unfortunately, the current CPAN version of Plagger (0.7.17) doesn't have the above plugin. You can always get the latest version of the plugin from the Plagger's official repository at github (L<http://github.com/miyagawa/plagger/tree/master>). See Plagger's official site (L<http://plagger.org/>) for instructions to update your Plagger and install extra plugins.

=head1 METHODS

=head2 new

creates an object. You can pass an optional hash. Important keys are:

=over 4

=item email, password

the ones you use to login.

=item mode

WWW::Mixi::Scraper has changed its policy since 0.08, and now it returns raw HTML for some of the longer texts like user's profile or diary body by default. However, this may cause various kind of problems. If you don't like HTML output, set this 'mode' option to 'TEXT', then it returns pre-processed texts as before.

=item cookie_jar

would be passed to WWW::Mechanize. If your cookie_jar has valid cookies for mixi, you don't need to write your email/password in your scripts.

=back

Other options would be passed to Mech, too.

=head2 parse

takes a uri and returns scraped data, which is mainly an array, sometimes a hash reference, or possibly something else, according to the plugin that does actual scraping. You can pass an optional hash, which eventually override query parameters of the uri. An exception is 'html', which wouldn't go into the uri but provide raw html string to the scraper (mainly to test).

=head1 TO DO

More scraper plugins, various levels of caching, password obfuscation, some getters of minor information such as pager, counter, and image/thumbnail sources, and maybe more docs?

Anyway, as this is a 'scraper', I don't include 'post' related methods here. If you insist, use WWW::Mechanize object hidden in the stash, or WWW::Mixi.

=head1 SEE ALSO

L<WWW::Mixi>, L<Web::Scraper>, L<WWW::Mechanize>, L<Plagger>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
