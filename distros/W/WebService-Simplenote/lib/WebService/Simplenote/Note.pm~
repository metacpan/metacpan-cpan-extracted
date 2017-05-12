package WebService::Simplenote::Note;

# ABSTRACT: represents an individual note

# TODO: API support for tags

use v5.10;
use Moose;
use MooseX::Types::DateTime qw/DateTime/;
use WebService::Simplenote::Note::Meta::Types;
use WebService::Simplenote::Note::Meta::Attribute::Trait::NotSerialised;
use Method::Signatures;
use DateTime;
use JSON qw//;
use Log::Any qw//;
use namespace::autoclean;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    
    if ( @_ == 1 && !ref $_[0] ) {
        my $note = JSON->new->utf8->decode($_[0]);
        return $class->$orig( $note );
    }
    else {
        return $class->$orig(@_);
    }
};

has logger => (
    is       => 'ro',
    isa      => 'Object',
    lazy     => 1,
    required => 1,
    default  => sub { return Log::Any->get_logger },
    traits   => [qw/NotSerialised/],
);

# set by server
has key => (
    is  => 'rw',
    isa => 'Str',
);

# set by server
has [ 'sharekey', 'publishkey' ] => (
    is  => 'ro',
    isa => 'Str',
);

has title => (
    is  => 'rw',
    isa => 'Str',
);

has deleted => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);

# XXX should default to DateTime->now?
has [ 'createdate', 'modifydate' ] => (
    is     => 'rw',
    isa    => DateTime,
    coerce => 1,
);

# set by server
has [ 'syncnum', 'version', 'minversion' ] => (
    is  => 'rw',
    isa => 'Int',
);

has tags => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_tag     => 'push',
        join_tags   => 'join',
        has_tags    => 'count',
        has_no_tags => 'is_empty',
    },
);

has systemtags => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[SystemTags]',
    default => sub { [] },
    handles => {
        set_markdown => [ push  => 'markdown' ],
        is_markdown  => [ first => sub { /^markdown/ } ],
        set_pinned   => [ push  => 'pinned' ],
        join_systags   => 'join',
        has_systags    => 'count',
        has_no_systags => 'is_empty',
    },
);

# XXX: always coerce to utf-8?
has content => (
    is      => 'rw',
    isa     => 'Str',
    trigger => \&_get_title_from_content,
);

method serialise {
    $self->logger->debug('Serialising note using: ', JSON->backend);
    my $json = JSON->new;
    $json->allow_blessed;
    $json->convert_blessed;
    my $serialised_note = $json->utf8->encode($self);

    return $serialised_note;
}

method TO_JSON {
    my %hash;
    for my $attr ( $self->meta->get_all_attributes ) {
        next if $attr->does('NotSerialised');
        my $reader = $attr->get_read_method;
        if (defined $self->$reader) {
            $hash{$attr->name} = $self->$reader;
        }
    }

    # convert dates, if present
    if (exists $hash{createdate}) {
        $hash{createdate} = $self->createdate->epoch;
    }
    
    if (exists $hash{modifydate}) {
        $hash{modifydate} = $self->modifydate->epoch;
    }
    
    return \%hash;
}

sub _get_title_from_content {
    my $self = shift;

    my $content = $self->content;

    # First line is title
    $content =~ /(.+)/;
    my $title = $1;

    # Strip prohibited characters
    # XXX preferable encoding scheme?
    chomp $title;

    # non-word chars to space
    $title =~ s/\W/ /g;

    # trim leading and trailing spaces
    $title =~ s/^\s+//;
    $title =~ s/\s+$//;

    $self->title( $title );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

  use WebService::Simplenote::Note;

  my $note = WebService::Simplenote::Note->new(
      content => "Some stuff",
  );

  printf "[%s] %s\n %s\n",
      $note->modifydate->iso8601,
      $note->title,
      $note->content;
  }

=head1 DESCRIPTION

This class represents a note suitable for use with Simplenote. You should read the 
L<Simplenote API|http://simplenoteapp.com/api/> docs for full details

=head1 METHODS

=over

=item WebService::Simplenote::Note->new($args)

The minimum required attribute to set is C<content>.

=item add_tag($str)

Push a new tag onto C<tags>.

=item set_markdown

Shortcut to set the C<markdown> system tag.

=item set_pinned

Shortcut to set the C<pinned> system tag.

=back

=head1 ATTRIBUTES

=over

=item logger

L<Log::Any> logger

=item key

Server-set unique id for the note.

=item title

Simplenote doens't use titles, so we autogenerate one from the first line of content.

=item deleted

Boolean; is this note in the trash?

=item createdate/modifydate

Datetime objects

=item tags

Arrayref[Str]; user-generated tags.

=item systemtags

Arrayref[Str]; special tags.

=item content

The body of the note
