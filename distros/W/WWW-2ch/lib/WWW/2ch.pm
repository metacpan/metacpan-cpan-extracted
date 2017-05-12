package WWW::2ch;

use strict;
our $VERSION = '0.07';

use UNIVERSAL::require;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( conf worker cache ua setting subject) );

use WWW::2ch::Setting;
use WWW::2ch::Subject;
use WWW::2ch::Dat;
use WWW::2ch::UserAgent;
use WWW::2ch::Cache;

sub new {
    my ($class, %conf) = @_;

    my $self = bless {}, $class;

    $self->{plugin} = $conf{plugin} || 'Base';
    $self->load_plugin;
    $self->conf($self->worker->gen_conf(\%conf));
    $self->ua( WWW::2ch::UserAgent->new($conf{ua}) );
    $self->cache( WWW::2ch::Cache->new($conf{cache}) );

    $self;
}

sub load_plugin {
    my ($self, $conf) = shift;

    my $module;
    if (-f $self->{plugin}) {
	open my $fh, $self->{plugin} or return;
	while (<$fh>) {
	    if (/^package (WWW::2ch::Plugin::.*?);/) {
		eval { require $self->{plugin} } or die $@;
		$module = $1;
		last;
	    }
	}
    } else {
	$module = $self->{plugin};
	$module =~ s/^WWW::2ch::Plugin:://;;
	$module = "WWW::2ch::Plugin::$module";
	$module->require or die $@;
    }
    $self->worker($module->new($self->conf));
}

sub encoding { $_[0]->worker->encoding }

sub load_setting {
    my $self = shift;

    return unless $self->conf->{setting};
    $self->setting( WWW::2ch::Setting->new($self, $self->conf->{setting}) )->load;
}

sub load_subject {
    my $self = shift;

    return unless $self->conf->{subject};
    $self->subject( WWW::2ch::Subject->new($self, $self->conf->{subject}) )->load;
}

sub parse_dat {
    my ($self, $data, $subject) = @_;

    $subject = { $subject } unless ref($subject);
    my $dat = WWW::2ch::Dat->new($self, $subject);
    $dat->dat($data);
    $dat->parse;
    $dat;
}

sub recall_dat {
    my ($self, $key) = @_;

    my $dat = WWW::2ch::Dat->new($self, {});
    $dat->key($key);
    $dat->get_cache;
    $dat->parse;
    $dat;
}

1;
__END__

=head1 NAME

WWW::2ch - scraping of a popular bbs of Japan. 

=head1 SYNOPSIS

  use WWW::2ch;

  my $bbs = WWW::2ch->new(url => 'http://live19.2ch.net/ogame/',
                          cache => '/tmp/www2ch-cache');
  $bbs->load_setting;
  $bbs->load_subject;
  foreach my $dat ($bbs->subject->threads) {
      $dat->load;
      my $one = $dat->res(1);
      print $dat->title . "\n";
      print '>>1: ' . $one->body;
      foreach my $res ($dat->reslist) {
        print $res->resid . ':' . $res->date . "\n";
        print $res->body_text . "\n";
      }
      last;
  }


  my $bbs = WWW::2ch->new(url => 'http://live19.2ch.net/test/read.cgi/ogame/1140947283/l50',
                          cache => '/tmp/www2ch-cache');
  my $dat = $bbs->subject->thread('1140947283');
  $dat->load;


  # dat in cash is taken out
  my $bbs = WWW::2ch->new(url => 'http://live19.2ch.net/ogame/',
			cache => '/home/ko/cpan/my/WWW-2ch/cache');
  my $dat = $bbs->recall_dat('1141300600');


  # parse dose dat from file
  my $bbs = WWW::2ch->new(url => 'http://live19.2ch.net/ogame/',
			cache => '/home/ko/cpan/my/WWW-2ch/cache');
  open my $fh, "test.dat" or return;
  my $data = join('', <$fh>);
  close($fh);
  my $dat = $bbs->parse_dat($data);

  # returns it with raw article data.
  $dat->dat;

  #plugin load
  my $bbs = WWW::2ch->new(url => 'http://example.jp/test/read.cgi/ogame/1140947283/l50',
                          cache => '/tmp/www2ch-cache',
                          plugin => 'ExampleJp');

  # plugin file load
  my $bbs = WWW::2ch->new(url => 'http://example.com/test/read.cgi/ogame/1140947283/l50',
                          cache => '/tmp/www2ch-cache',
                          plugin => '/usr/local/www-2ch/lib/ExampleCom.pm');


=head1 DESCRIPTION

It is suitable for the scraping of a popular bbs of Japan. 

other BBS and the news sites and other sites are also possible by the addition of the plugin for scraping. 

Please take care with the flood control to an excessive access. 


=head1 Method

=over 4

=item new(%option)

=head2 option

=over 4

=item * url

set the permalink of top page.

=item * cache

cache directory or Cache module object

=item * plugin

plugin name (default Base)

=back

=item encoding

encode name of plugin

=item load_setting

setting is read

=item load_subject

article list is read

=item parse_dat($data[, $subject])

parse does $data

=item recall_dat($key)

recall dat from cache file

=back

=head1 SEE ALSO

L<http://2ch.net/>, L<http://www.monazilla.org/>,
L<WWW::2ch::Subject>, L<WWW::2ch::Dat>, L<WWW::2ch::Res>

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
