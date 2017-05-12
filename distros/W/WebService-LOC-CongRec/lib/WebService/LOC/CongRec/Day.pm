package WebService::LOC::CongRec::Day;
our $VERSION = '0.4';
use Moose;
with 'MooseX::Log::Log4perl';

use Data::Dumper;

=head1 DESCRIPTION

An issue of the Congressional Record from a single day on the thomas.loc.gov
website.  Something along the lines of:
http://thomas.loc.gov/cgi-bin/query/B?r111:@FIELD%28FLD003+h%29+@FIELD%28DDATE+20100924%29

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

=item date

The date that this page is from.

=cut

has 'date' => (
    is          => 'ro',
    isa         => 'DateTime',
    required    => 1,
);

=item house

Which house of Congress this page is from; (s)enate, (h)ouse, (e)xtension of remarks, (d)aily digest

=cut

has 'house' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item pages

Pages that are part of this day.

=cut

has 'pages' => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    auto_deref  => 1,
    lazy_build  => 1,
    builder     => '_build_pages',
);

=back

=head1 METHODS

=head3 _build_pages

Get an array of the pages from this day.

Note: these URLs are volatile, expiring 30 minutes after creation.

=cut

sub _build_pages {
    my ($self) = @_;
    my @pages;

    $self->mech->get($self->getURL);

    # Line looks like:
    # <B> 7 . </B> [desc] -- <a href="[url]">(Hou...)</a>
    # URL: /cgi-bin/query/D?r[congress]:[num]:./temp/~r[congress][random]::
    my $congress = WebService::LOC::CongRec::Util->getCongressFromYear($self->date->year);
    my $lineRegex = qr!<B>\ ?\d{1,3}\ \.\ </B>
                \ .+\ --\ 
                <a\ href="
                    (/cgi-bin/query/D\?r$congress:\d{1,3}:./temp/~r$congress.+::)
                ">\([HSD]
        !x;

    my @lines = split /\n/, $self->mech->content;
    foreach my $line (@lines) {
        if ($line =~ $lineRegex) {
            push @pages, $1;
        }
    }

    return \@pages;
}

=head3 getURL()

Get the Thomas URL for this day.

=cut

sub getURL {
    my ($self) = @_;

    # URL looks like
    # http://thomas.loc.gov/cgi-bin/query/B?r111:@FIELD(FLD003+s)+@FIELD(DDATE+20100924)
    my $url = 'http://thomas.loc.gov/cgi-bin/query/B?';

    $url .= 'r' . WebService::LOC::CongRec::Util->getCongressFromYear($self->date->year);
    $url .= ':@FIELD(FLD003+' . $self->house . ')';
    $url .= '+@FIELD(DDATE+' . $self->date->strftime('%Y%m%d') . ')';

    return $url;
}

1;
