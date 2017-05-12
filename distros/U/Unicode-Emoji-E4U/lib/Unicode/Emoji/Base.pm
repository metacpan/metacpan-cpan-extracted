=head1 NAME

Unicode::Emoji::Base - Base class for Unicode::Emoji::* classes

=head1 DESCRIPTION

This is a base class for Unicode::Emoji::* classes.
You B<DO NOT> need to use this directly.

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Unicode::Emoji::E4U>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Unicode::Emoji::Base;
use XML::TreePP;
use Any::Moose;
has verbose => (is => 'rw', isa => 'Bool');
has datadir => (is => 'rw', isa => 'Str', lazy_build => 1);
has treepp  => (is => 'rw', isa => 'XML::TreePP', lazy_build => 1);

our $VERSION = '0.03';

our $DATADIR = 'http://emoji4unicode.googlecode.com/svn/trunk/data/';
# our $DATADIR = 'data/';

sub _build_datadir {
    $DATADIR;
}

our $TREEPP_OPT = {
    force_array =>  [qw(category subcategory e ann)],
    attr_prefix =>  '',
    utf8_flag   =>  1,
};

sub _build_treepp {
    my $self = shift;
    XML::TreePP->new(%$TREEPP_OPT);
}

our $CONFIG_COLUMNS = [qw(verbose datadir treepp)];

sub clone_config {
    my $self = shift;
    map { $_ => $self->{$_} } grep { exists $self->{$_} } @$CONFIG_COLUMNS;
}

package Unicode::Emoji::Base::File;
use Any::Moose;
extends 'Unicode::Emoji::Base';
has dataxml => (is => 'rw', isa => 'Str', lazy_build => 1);
has root    => (is => 'rw', isa => 'Ref', lazy_build => 1);

sub _build_dataxml {
    my $self = shift;
    my $datadir = $self->datadir;
    $datadir =~ s#/?$#/#;
    $datadir.$self->_dataxml;
}

sub _build_root {
    my $self = shift;

    # data/docomo/carrier_data.xml or
    # http://emoji4unicode.googlecode.com/svn/trunk/data/docomo/carrier_data.xml
    my $dataxml = $self->dataxml;

    # element class name
    my $elem_class = (ref $self).'::XML';
    my $save = $self->treepp->get('elem_class');
    $self->treepp->set(elem_class => $elem_class);

    # verbose message
    print STDERR $dataxml, "\n" if $self->verbose;

    # fetch and parse
    my $data;
    if ($dataxml =~ m#^https?://#) {
        $data = $self->treepp->parsehttp(GET => $dataxml);
    } else {
        $data = $self->treepp->parsefile($dataxml);
    }

    # restore
    $self->treepp->set(elem_class => $save);

    # root element
    my $root = (values %$data)[0];
    $root;
}

sub xmlfile { Carp::croak 'xmlfile not implemented: '.(ref $_[0]); }

sub index {
    my $self = shift;
    my $key  = shift;
    $self->{index} ||= {};
    return $self->{index}->{$key} if ref $self->{index}->{$key};

    my $list = $self->list;
    my @notnull = grep {ref $_} @$list;
    Carp::croak "Null list\n" unless scalar @notnull;

    my @translate = grep {defined $_->$key()} @notnull;
    Carp::croak "Invalid index key: $key" unless scalar @translate;

    # cache
    $self->{index}->{$key} = {map {$_->$key() => $_} @translate };
    $self->{index}->{$key};
}

sub find {
    my $self  = shift;
    my $key   = shift;
    my $val   = shift;
    my $index = $self->index($key) or return;
    return unless exists $index->{$val};
    $index->{$val};
}

package Unicode::Emoji::Base::File::Carrier;
use Any::Moose;
extends 'Unicode::Emoji::Base::File';
has list => (is => 'ro', isa => 'ArrayRef', lazy_build => 1);

sub _build_list {
    my $self = shift;
    my $list = $self->root->e;
    $list;
}

package Unicode::Emoji::Base::Emoji;
use Encode ();
use Any::Moose;
has unicode_hex => (is => 'rw', isa => 'Str', required => 1);
has unicode_string => (is => 'ro', isa => 'Str', lazy_build => 1);
has unicode_octets => (is => 'ro', isa => 'Str', lazy_build => 1);
has is_alt => (is => 'ro', isa => 'Bool', lazy_build => 1);

sub _build_unicode_string {
    my $self = shift;
    my $hex  = $self->unicode_hex or return;
    $hex =~ s/^[\>\*\+]//;
    return unless length $hex;
    join "" => map {chr hex $_} split /\+/, $hex;
}

sub _build_unicode_octets {
    my $self = shift;
    my $string = $self->unicode_string;
    Encode::encode_utf8($string);
}

sub _build_is_alt {
    my $self = shift;
    $self->unicode_hex =~ /^>/;
}

package Unicode::Emoji::Base::Emoji::CP932;
use Encode ();
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji';
has cp932_string => (is => 'ro', isa => 'Str', lazy_build => 1);
has cp932_octets => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_cp932_octets {
    my $self = shift;
    my $hex = $self->unicode_hex or return;
    $hex =~ s/^>//;
    join "" => map {pack(n=>$self->_unicode_to_cp932(hex $_))} split /\+/, $hex;
}

my $ENCODE_CP932 = Encode::find_encoding('cp932');
sub _build_cp932_string {
    my $self = shift;
    my $octets = $self->cp932_octets;
    $ENCODE_CP932->decode($octets);
}

__PACKAGE__->meta->make_immutable;
