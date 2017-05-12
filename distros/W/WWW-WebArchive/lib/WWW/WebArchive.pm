
#############################################################################
## $Id: WebArchive.pm 6702 2006-07-25 01:43:27Z spadkins $
#############################################################################

package WWW::WebArchive;

use vars qw($VERSION);
use strict;

use Cwd 'abs_path';
use File::Spec;

$VERSION = "0.50";

sub new {
    &App::sub_entry if ($App::trace);
    my ($this, @args) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    if ($#args == 0 && ref($args[0]) eq "HASH") {
        $self = { %{$args[0]} };
    }
    elsif ($#args >= 1 && $#args % 2 == 1) { # even number of args
        $self = { @args };
    }
    bless $self, $class;

    # Initialize agents to the individual archives
    my @archives = qw(WaybackMachine);
    my (@agents, %agent, $agent);
    foreach my $archive (@archives) {
        $class = "WWW::WebArchive::$archive";
        eval "use $class;";
        if ($@) {
             die $@;
        }
        $agent = $class->new(name => $archive, @args);
        $agent{$archive} = $agent;
        push(@agents, $agent);
    }
    $self->{archives} = \@archives;
    $self->{agents} = \@agents;
    $self->{agent} = \%agent;

    &App::sub_exit($self) if ($App::trace);
    return($self);
}

sub restore {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    my $url = $options->{url} || die "restore(): URL not provided";
    foreach my $agent (@{$self->{agents}}) {
        $agent->restore($options);
    }
    # merge the results
    &App::sub_exit() if ($App::trace);
}

=head1 NAME

WWW::WebArchive - Retrieve old versions of public web pages from various web archives (i.e. www.archive.org, Internet Archive's Wayback Machine, or Google's page cache)

=head1 SYNOPSIS

    NOTE: You probably want to use the "webarchive" command line utility rather than
    this API.  If you really want to use the API, you should look at how "webarchive"
    uses it as an example.

    #!/usr/bin/perl

    use WWW::WebArchive;
    my $webarchive = WWW::WebArchive->new();
    $webarchive->restore( { url => "http://www.website.com" } );

=head1 DESCRIPTION

WWW-WebArchive is a set of modules to retrieve old versions of public web pages
from various web archives.

  * http://www.archive.org - Internet Archive's Wayback Machine
  * http://www.google.com  - Google's page cache

This is useful if

 1. Your web server crashed and you didn't have complete backups
 2. A site (such as a valuable reference source) changed or went away
    and you want to restore an old version of the site to your local
    disk

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

1;

