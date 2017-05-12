#!/usr/bin/env perl

=head1 NAME

Vitacilina - ¡Ah, qué buena medicina!

=head1 DESCRIPTION

A simple feeds engine exporter that uses YAML to get list of feeds and
TT as templating system. Some people would call it an aggregator. It was
intended to be a reliable Planet (L<http://planetplanet.org>)
alternative, then some development ideas evolved into rFeed (http://github.com/damog/rfeed).
Vitacilina runs on production services on a couple of systems.

=head1 SYNOPSIS

 use Vitacilina;

 my $v = Vitacilina->new(
   config => 'config.yaml',
   template => 'template.tt',
   output => 'output.html',
   limit => '20',
 );

 $v->render;

=head1 FILES

=head2 config

The C<config> parameter specifies the path to a YAML file specifying a list
of feeds. Use this format:

 http://myserver.com/myfeed:
   name: Some Cool Feed
 http://feeds.feedburner.com/InfinitePigTheorem:
   name: InfinitePigTheorem
 ...

=head2 template

A C<Template::Toolkit> file which will be taken as the template for
output. Format:

 [% FOREACH p IN data %]
  <a href="[% p.permalink %]">[% p.title %]</a>
   by <a href="[% p.channelUrl %]">[% p.author %]</a>
  <br />
 [% END %]

The C<data> is an ordered array with a bunch of hashes with the
simple data such as C<permalink>, C<title>, C<channelUrl>, C<author>,
etc.

=head2 output

File path where the output will be written.

=head1 EXAMPLES

Take a look at the C<examples/> directory for fully working example.

=head1 SEE ALSO

Git repository is located at L<http://github.com/damog/vitacilina>.
Also take a look at the Stereonaut! blog where similar
developments from the author are announced and sampled,
L<http://log.damog.net/>.

=head1 AUTHOR

David Moreno, david@axiombox.com. Alexandr Ciornii contributed with
patches.

=head1 COPYRIGHT

Copyright (C) 2009 by David Moreno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Vitacilina;

use 5.006;

use strict;
use warnings;


use URI;
use Template;
use XML::Feed;
use YAML::Syck;
use Data::Dumper;
use LWP::UserAgent;
use DateTime;

use Carp;

use Vitacilina::Config qw/$FORMAT $OUTPUT $TITLE $LIMIT/;

# Constant: VERSION
#
# Vitacilina version
our $VERSION = '0.2';

my $params = {
	required => [qw{config template}],
	optional => [qw/title format/],
};

# Function: new
#
# Vitacilina constructor
#
# Parameters:
#
#  config => [ path_to_file ] - YAML configuration file path for the feeds
#  template => [ path_to_file ] - TT file path
#  output => [ path_to_file  ] - HTML file path where the output will be written
#  limit => [ n ] - Number of items to display 
#  tt_absolute => [0|1] - TT absolute paths
#  tt_relative => [0|1] - TT relative paths, overrides <tt_absolute>
sub new {
	my($self, %opts) = @_;
	
	my $o = \%opts;

	my $filter = {
		title	=> $opts{filter}->{title} || '',
		content => $opts{filter}->{content} || '',
	};
	
	my $ua = LWP::UserAgent->new(
		agent => qq{Vitacilina $VERSION},
	);
	
	# welcome to retarded; please someone fix this
	my($rel, $abs);
	$opts{tt_absolute} ? $rel = 0 : $rel = 1;
	$opts{tt_relative} ? $abs = 0 : $abs = 1;

	return bless {
		ua				=> $ua,
		format			=> $opts{format} || $FORMAT,
		output			=> $opts{output} || $OUTPUT,
		config			=> $opts{config} || '',
		limit			=> $opts{limit} || $LIMIT,
		filter			=> { 
			title => qr/$filter->{title}/i,
			content => qr/$filter->{content}/i,
		},
		title 			=> $opts{title} || $TITLE,
		template		=> $opts{template} || '',
		tt_relative		=> $rel,
		tt_absolute		=> $abs,
	}, $self;
}

# Function: render
#
# Vitacilina launcher
sub render {
  my($self) = shift;

  my $tt = Template->new(
    RELATIVE => $self->tt_relative,
    ABSOLUTE => $self->tt_absolute,
  );

	Carp::croak("No YAML config file was defined!")
		unless $self->{config};

	Carp::croak("No TT file was defined!")
		unless $self->{template};

  $self->{feedsData} = $self->_feedsData;

  $tt->process(
    $self->template,
    {
      feeds => $self->_feeds,
      data => $self->_data,
      title => $self->title,
    },
    $self->output,
    binmode => ':utf8',
  ) or die $tt->error;

}

# Class variables accesors
sub config {
	my($self, $config) = @_;
	$self->{config} = $config if $config;
	$self->{config};
}

sub tt_relative {
	my($self, $tt) = @_;
	$self->{tt_relative} = $tt if $tt;
	$self->{tt_relative};
}

sub tt_absolute {
	my($self, $tt) = @_;
	$self->{tt_absolute} = $tt if $tt;
	$self->{tt_absolute};
}

sub title {
	my($self, $title) = @_;
	$self->{title} = $title if $title;
	$self->{title};
}

sub template {
	my($self, $t) = @_;
	$self->{template} = $t if $t;
	$self->{template};
}

sub limit {
	my($self, $l) = @_;
	$self->{limit} = $l if $l;
	$self->{limit};
}

sub format {
	my($self, $f) = @_;
	$self->{format} = $f if $f;
	$self->{format};
}

sub output {
	my($self, $o) = shift;
	$self->{output} = $o if $o;
	$self->{output};
}

# Internal method to get the feed information
sub _feeds {
	my($self) = shift;
	
	my @feeds;
	
	foreach my $f(@{$self->{feedsData}}) {
		push @feeds, {
			blogUrl => $f->{feed}->link,
			feedUrl => $f->{url},
			author => $f->{info}->{name},
		};
	}
	
	@feeds = sort { $a->{author} cmp $b->{author} } @feeds;
	
	return \@feeds;
		
}

# Internal method to get all posts and entries by the feeds
sub _feedsData {
	my($self) = shift;
	
	my $c = LoadFile($self->{config});

	my @feeds;

	while(my($k, $v) = each %{$c}) {
		next if $k eq 'Planet' or $k eq 'DEFAULT';
		
		my $res = $self->{ua}->get($k);
		
		unless($res->is_success) {
			print STDERR qq{ERROR: $k: $res->status_line\n};
			next;
		}
		
		my $feed = XML::Feed->parse(\$res->decoded_content);
		
		unless($feed) {
			print STDERR 
				'ERROR: ',
				XML::Feed->errstr, 
				': ',
				$k, "\n";
			next;
		};
		
		push @feeds, { feed => $feed, info => $v, url => $k };
	}
	return \@feeds;
}

# Internal method to get posts.
sub _data {
	my($self) = shift;
	
	foreach (@{$params->{required}}) {
		croak "No $_ was defined" unless $self->{$_};
	}
	
	my $c = LoadFile($self->{config});
	
	my @entries;
	
	FeedsData: foreach my $f(@{$self->{feedsData}}) {
		for($f->{feed}->entries) {
			
			my $content = $_->content->body || q{};
			my $title = $_->title || q{};
			
			if($content =~ $self->{filter}->{content} and $title =~ $self->{filter}->{title}) {
				push @entries, {
					author 			=> $f->{info}->{name} || '',
					face 			=> $f->{info}->{face} || '',
					content 		=> $content,
					title 			=> $title,
					date 			=> $_->issued || '',
					permalink 		=> $_->link || '',
					channelUrl 		=> $f->{feed}->link || '',
					date_modified 	=> $_->modified || '',
				}
			}
		}
	}

	my $zero = DateTime->from_epoch(epoch => 0);
		
	@entries = sort {
		($b->{date} || $b->{date_modified} || $zero)
		<=>
		($a->{date} || $b->{date_modified} || $zero)
	} @entries;
	
	delete @entries[$self->limit .. $#entries];
	
	return \@entries;
	
}

1;

# Eso es to-, eso es to-, eso es todo amigos.
