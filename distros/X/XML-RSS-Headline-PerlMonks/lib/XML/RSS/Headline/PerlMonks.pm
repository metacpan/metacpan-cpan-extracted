package XML::RSS::Headline::PerlMonks;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.02';

use base 'XML::RSS::Headline';

sub item {
	my ($self,$item) = @_;
	$self->SUPER::item($item);

	my $key = "http://perlmonks.org/index.pl?node_id=393035"; 

	# seed with a default of unknown, this also keeps warnings happy.
	$self->category(    $item->{'category'}          || 'Unknown' );
	$self->authortitle( $item->{$key}{'authortitle'} || 'Unknown' );
	$self->node_id(     $item->{$key}{'node_id'}     || 'Unknown' );
	$self->author_user( $item->{$key}{'author_user'} || 'Unknown' );
	$self->createtime(  $item->{$key}{'createtime'}  || 'Unknown' );
}

sub authortitle {
	my ($self,$authortitle) = @_;
	$self->{'authortitle'} = $authortitle if $authortitle;
	return $self->{'authortitle'};
}

sub author_user {
	my ($self,$author_user) = @_;
	$self->{'author_user'} = $author_user if $author_user;
	return $self->{'author_user'};
}

sub createtime {
	my ($self,$createtime) = @_;
	$self->{'createtime'} = $createtime if $createtime;
	return $self->{'createtime'};
}

sub node_id {
	my ($self,$node_id) = @_;
	$self->{'node_id'} = $node_id if $node_id;
	return $self->{'node_id'};
}

sub category {
	my ($self,$category) = @_;
	$self->{'category'} = $category if $category;

	my %pretty = (
		'perlquestion'         => 'Seekers of Perl Wisdom',
		'perlmeditation'       => 'Meditations',
		'obfuscated'           => 'Obfuscation',
		'monkdiscuss'          => 'PerlMonks Discussion',
		'snippet'              => 'Snippets',
		'bookreview'           => 'Reviews',
		'modulereview'         => 'Reviews',
		'CUFP'                 => 'Cool Uses For Perl',
		'perlnews'             => 'Perl News',
		'categorized question' => 'Q&amp;A',
		'categorized answer'   => 'Q&amp;A',
		'QandASection'         => 'Q&amp;A',
		'sourcecode'           => 'Code',
		'poem'                 => 'Poetry',
	);
	
	return ( exists( $pretty{ $self->{'category'} } ) ) ? $pretty{ $self->{'category'} } : $self->{'category'};
}

1;
__END__

=head1 NAME

XML::RSS::Headline::PerlMonks - Subclass of XML::RSS::Headline for reading 
RSS feed from perlmonks.org

=head1 SYNOPSIS

  use XML::RSS::Feed;
  use XML::RSS::Headline::PerlMonks;
  use LWP::Simple qw(get);
	
  my $feed = XML::RSS::Feed->new(
      'name'   => 'newmonknodes',
	  'url'    => 'http://perlmonks.org/index.pl?node_id=30175;xmlstyle=rss',
	  'hlobj'  => 'XML::RSS::Headline::PerlMonks',
	  'tmpdir' => '/tmp', # for caching
  );

  while (1) {
    $feed->parse( get( $feed->url ) );
    for my $post ( $feed->late_breaking_news ) {
        print "New perlmonks posting from " . $post->authortitle . "\n";
        print "Category: " . $post->category . "\n";
        print "Subject: " . $post->headline . "\n";
        print "Link: " . $post->url . "\n\n";
    }
    sleep( $feed->delay );
  }
  	

=head1 DESCRIPTION

This module extends the base XML::RSS::Headline package which is used by XML::RSS::Feed
to parse and optionally cache the RSS feed from perlmonks.org. Optionally this module
can be used inside the POE::Component::RSSAggregator module as one of many feeds to monitor.

=head1 METHOD OVERRIDES

  item()

This overrides the item() method in XML::RSS::Headline and adds the parsing of item nodes
which use the perlmonks namespace.

=head1 NEW ATTRIBUTES

These are new attributes that come from nodes using the perlmonks namespace. With the 
exception of category(), they are all simple getter/setter methods. Category does some
translation from the perlmonks abbreviation for category to a prettier description as used
in perlmonks' menus

  category()
  authortitle()
  author_user()
  mode_id()
  createtime()

=head1 SEE ALSO

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<POE::Component::RSSAggregator>

L<http://perl.donshanks.com/modules>

=head1 BUGS AND SUPPORT

Please report any bugs or feature requests to
C<bug-xml-rss-headline-perlmonks [at] rt [dot] cpan [dot] org> or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-RSS-Headline-PerlMonks>.

=head1 ACKNOWLEDGEMENTS

Thanks to Jeff Bisbee for XML::RSS:Feed, it made my life so much simpler, to the monks at 
perlmonks.org, and my employer WhitePages.com for giving me time and resources to test things 
out.

=head1 AUTHOR

Don Shanks, E<lt>donshank [at] cpan [dot] orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Don Shanks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
