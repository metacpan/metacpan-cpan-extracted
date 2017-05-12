package WWW::Scramble::Handler;
use Moose;
use MooseX::AttributeHelpers;
use Carp;
use HTML::TreeBuilder::XPath;

=head1 NAME

WWW::Scramble::Handler 

=head1 SYNOPSIS

Quick summary of what the module does.

=cut

has _xpath => (
    is      => 'ro',
    isa     => 'HTML::TreeBuilder::XPath',
    default => sub { HTML::TreeBuilder::XPath->new }
);
has xtitle =>
  ( is => 'rw', isa => 'Str', default => '//div[@id="ynwsart"]/*/h1' );
has xcontent =>
  ( is => 'rw', isa => 'Str', default => '//div[@id="ynwsartcontent"]' );
has assets => (
    metaclass => 'Collection::Hash',
    is        => 'rw',
    isa       => 'HashRef[Str]',
    default   => sub { {} },
    provides  => {
        exists    => 'exists_in_asset',
        get    => 'get_asset',
        set    => 'set_asset',
    }
);

=head1 FUNCTIONS

=head2 parse

=cut

sub parse {
    my ( $self, $raw ) = @_;
    croak "Empty Content" unless $raw;
    $self->_xpath->parse_content($raw) || croak "Parse error";
}

after 'set_asset' => sub {
    my ( $self ) = shift;
    $self->xtitle($self->get_asset('xtitle')) if ( $self->exists_in_asset('xtitle') );
    $self->xcontent($self->get_asset('xcontent')) if ( $self->exists_in_asset('xcontent') );
};

=head2 get_title

=cut

sub get_title {
    my ($self) = shift;
    return $self->_xpath->findnodes($self->xtitle );
}

=head2 get_content

=cut

sub get_content {
    my ($self) = shift;
    return $self->_xpath->findnodes($self->xcontent );
}

=head2 get_field

=cut

sub get_field {
    my ($self, $field, $node) = @_;
    return $node->findnodes($self->get_asset($field))
        if $node and 'HTML::Element' eq ref $node ;
    return $self->_xpath->findnodes($self->get_asset($field));
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
