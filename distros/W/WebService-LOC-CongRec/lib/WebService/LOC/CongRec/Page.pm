package WebService::LOC::CongRec::Page;
our $VERSION = '0.4';
use Moose;
with 'MooseX::Log::Log4perl';

use HTML::TokeParser;
use Data::Dumper;

=head1 DESCRIPTION

A single page from the Congressional Record on THOMAS.

The URL is not persistent, but is along the lines of:
http://thomas.loc.gov/cgi-bin/query/D?r111:15:./temp/~r111h782Bg::

=cut

=head1 ATTRIBUTES

=over 1

=item mech

A WWW::Mechanize object that we can use to grab the page from Thomas.

=cut

has 'mech' => (
    is          => 'rw',
    isa         => 'Object',
    required    => 1,
);

=item url

The page URL.

=cut

has 'url' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item pageID

This page's ID.

=cut

has 'pageID' => (
    is      => 'rw',
    isa     => 'Str',
);

=item summary

This page's summary.

=cut

has 'summary' => (
    is      => 'rw',
    isa     => 'Str',
);

=item content

This page's content.

=cut

has 'content' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=back

=cut

sub BUILD {
    my ($self) = @_;

    $self->mech->get($self->url);
    eval { $self->mech->follow_link(text => 'Printer Friendly Display'); };

    my $p = HTML::TokeParser->new(\$self->mech->content);

    # Set the summary
    my $text = '';
    while (my $t = $p->get_token) {
        my ($ttype, $ttag) = ($t->[0], $t->[1]);
        if ($ttype eq 'S' && $ttag eq 'center') {
            $text = $p->get_trimmed_text("/$ttag");
        }
        elsif ($ttype eq 'E' && $ttag eq 'center') {
            if ($self->summary) {
                $text =~ s/\[Page: ([HSE]\d{1,6})\] .*$/$1/;
                $self->pageID($text);
                $self->log->debug("pageID: $text");
            }
            else {
                $self->summary($text);
                $self->log->debug("Summary: $text");
            }
            $text = '';
            last if $self->summary && $self->pageID;
        }
    }

    # Set the page content
    $text = '';
    while ($p->get_token('p')) {
        my $x = $p->get_trimmed_text;
        last if $x eq 'END'; # The "Printer Friendly" page end is clearly identified.
        $x =~ s/\xA0//g; # Unprintable character that may sometimes crop up.
        next if $x =~ /^$/; # Skip blank lines.
        $text .= "$x\n"; # Append the latest text.
    }
    $self->content($text);
    $self->log->debug(sprintf("Content: (%d) %s...", length($text), substr($text, 0, 50)));

    # Return to the previous page.
    $self->mech->back;
}

1;
