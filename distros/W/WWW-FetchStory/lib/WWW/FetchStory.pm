use strict;
use warnings;

package WWW::FetchStory;
$WWW::FetchStory::VERSION = '0.2602';
=head1 NAME

WWW::FetchStory - Fetch a story from a fiction website

=head1 VERSION

version 0.2602

=head1 SYNOPSIS

    use WWW::FetchStory;

    my $obj = WWW::FetchStory->new(%args);

    my %story_info = $obj->fetch_story(urls=>\@urls);

=head1 DESCRIPTION

This will fetch a story from a fiction website, intelligently
dealing with the formats from various different fiction websites
such as fanfiction.net; it deals with multi-file stories,
and strips all the extras from the HTML (such as navbars and javascript)
so that all you get is the story text and its formatting.

=head2 Fetcher Plugins

In order to tidy the HTML and parse the pages for data about the story,
site-specific "Fetcher" plugins are required.

These are in the namespace 'WWW::FetchStory::Fetcher'; a fetcher for the Foo site
would be called 'WWW::FetchStory::Fetcher::Foo'.

=cut

use WWW::FetchStory::Fetcher;
use Module::Pluggable instantiate => 'new',
search_path => ['WWW::FetchStory::Fetcher'],
sub_name => 'fetchers';

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = WWW::FetchStory->new();

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    # ---------------------------------------
    # Fetchers
    # find out what fetchers are available, and group them by priority
    $self->{fetch_pri} = {};
    my @fetchers = $self->fetchers();
    foreach my $fe (@fetchers)
    {
	my $priority = $fe->priority();
	my $name = $fe->name();
	if ($self->{debug})
	{
	    print STDERR "fetcher=$name($priority)\n";
	}
	if (!exists $self->{fetch_pri}->{$priority})
	{
	    $self->{fetch_pri}->{$priority} = [];
	}
	push @{$self->{fetch_pri}->{$priority}}, $fe;
    }

    return ($self);
} # new

=head2 fetch_story

    my %story_info = fetch_story(
				 urls=>\@urls,
				 verbose=>0,
				 toc=>0);

=cut
sub fetch_story ($%) {
    my $self = shift;
    my %args = (
	urls=>undef,
	verbose=>0,
	toc=>0,
	@_
    );

    my $fetcher;
    my $first_url = $args{urls}[0];
    foreach my $pri (reverse sort keys %{$self->{fetch_pri}})
    {
	foreach my $fe (@{$self->{fetch_pri}->{$pri}})
	{
	    if ($fe->allow($first_url)
                # the URL might be a file, check rurl
                    or (-f $first_url and $args{rurl} and $fe->allow($args{rurl}))
            )
            {
		$fetcher = $fe;
		warn "Fetcher($pri): ", $fe->name(), "\n" if $args{verbose};
		last;
	    }
	}
	if (defined $fetcher)
	{
	    last;
	}
    }
    if (defined $fetcher)
    {
	$fetcher->init(%{$self});
	return $fetcher->fetch(%args);
    }

    return undef;
} # fetch_story

=head2 list_fetchers

    my %fetchers = list_fetchers();

=cut
sub list_fetchers ($%) {
    my $self = shift;
    my %args = (
	verbose=>0,
	@_
    );

    my %fetchers = ();
    my @all_fetchers = $self->fetchers();
    foreach my $fe (@all_fetchers)
    {
	$fetchers{$fe->name()} = $fe->info();
    }
    return %fetchers;

} # list_fetchers

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of Text::ParseStory
__END__
