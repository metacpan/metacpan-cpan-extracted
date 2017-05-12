package eris::log;

use Hash::Merge::Simple qw(clone_merge);
use Moo;
use Types::Common::Numeric qw(PositiveNum);
use Types::Standard qw(ArrayRef HashRef Maybe Str);
use Ref::Util qw(is_hashref);

use eris::dictionary;

use namespace::autoclean;

has raw => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);
has decoded => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);
has context => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);
has complete => (
    is      => 'rw',
    isa     => HashRef[HashRef],
    lazy    => 1,
    default => sub { {} },
);
has timing => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { [] },
);
has tags => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { [] },
);
has total_time => (
    is  => 'rw',
    isa => Maybe[PositiveNum],
);
has index => (
    is => 'rw',
    isa => Maybe[Str],
);
has type => (
    is => 'rw',
    isa => Maybe[Str],
);

my $dict;

sub set_decoded {
    my ($self,$name,$href) = @_;
    my $d = $self->decoded;

    return unless is_hashref($href);

    # Store the results
    foreach my $k (keys %{ $href }) {
        $d->{$k} = $href->{$k};
    }
    $self->add_context($name, $href);
}

{
    my %in_dict = ();
    sub add_context {
        my ($self,$name,$href) = @_;
        my $complete = $self->complete;

        unless( defined $href
                && is_hashref($href)
                && scalar keys %$href
        ) {
            return;
        }

        # Tag the message
        push @{ $self->tags }, $name;

        # Install the context
        $complete->{$name} = exists $complete->{$name} ? clone_merge( $complete->{$name}, $href ) : $href;

        # Grab our dictionary
        $dict ||= eris::dictionary->instance;

        # Complete merge
        my %ok = ();
        foreach my $k (keys %{ $href }) {
            if( !exists $in_dict{$k} ) {
                $in_dict{$k} = $dict->lookup($k);
            }
            next unless $in_dict{$k};

            $ok{$k} = $href->{$k};
        }
        my $ctx = clone_merge( $self->context, \%ok );
        $self->context($ctx);
    }
}

sub add_tags {
    my ($self,@tags) = @_;
    my %tags = map { $_ => 1 } @{ $self->tags };

    foreach my $t (@tags) {
        push @{ $self->tags }, $t unless exists $tags{$t};
        $tags{$t} = 1;
    }

    return $self;
}

sub add_timing {
    my ($self,%args) = @_;
    if( exists $args{total} ) {
        $self->total_time( delete $args{total} );
    }
    my $t = $self->timing;
    push @{ $t },
        map { +{ phase => $_, seconds => $args{$_} } }
        keys %args;
    return $self;
}

sub as_doc {
    my ($self,%args) = @_;

    # Default to just the context;
    my $doc = $args{complete} ? $self->complete : $self->context;

    # Add Metadata
    if( my $idx = $self->index ) {
        $doc->{_index} = $idx;
    }
    if( my $type = $self->type ) {
        $doc->{_type} = $type;
    }
    $doc->{timing} = $self->timing;
    $doc->{tags}   = $self->tags;
    $doc->{total_time} = $self->total_time if $self->total_time;

    return $doc;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
