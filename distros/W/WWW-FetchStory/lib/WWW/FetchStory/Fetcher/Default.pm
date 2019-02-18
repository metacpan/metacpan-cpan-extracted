package WWW::FetchStory::Fetcher::Default;
$WWW::FetchStory::Fetcher::Default::VERSION = '0.2004';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::Default - default fetching module for WWW::FetchStory

=head1 VERSION

version 0.2004

=head1 DESCRIPTION

This is the default story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head1 METHODS

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "Default fetcher (does not do much)";

    return $info;
} # info


=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic LiveJournal fetcher, and then refinements for particular
LiveJournal community, such as the sshg_exchange community.
This works as either a class function or a method.

This must be overridden by the specific fetcher class.

$priority = $self->priority();

$priority = WWW::FetchStory::Fetcher::priority($class);

=cut

sub priority {
    my $class = shift;

    return 0;
} # priority

=head2 allow

If this fetcher can be used for the given URL, then this returns
true.
This must be overridden by the specific fetcher class.

    if ($obj->allow($url))
    {
	....
    }

=cut

sub allow {
    my $self = shift;
    my $url = shift;

    return 1;
} # allow

1; # End of WWW::FetchStory::Fetcher
__END__
