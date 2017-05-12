package XML::OPML::LibXML::Outline;
use strict;
use warnings;

our $AUTOLOAD;

sub new_from_elem {
    my($class, $elem) = @_;
    bless { elem => $elem }, $class;
}

sub attr {
    my($self, $attr) = @_;
    $self->{elem}->getAttribute($attr);
}

sub is_container {
    my $self = shift;
    $self->{elem}->hasChildNodes;
}

sub children {
    my $self = shift;
    map XML::OPML::LibXML::Outline->new_from_elem($_),
        $self->{elem}->getChildrenByLocalName('outline');
}

sub AUTOLOAD {
    my $self = shift;
    (my $attr = $AUTOLOAD) =~ s/.*:://;
    $attr =~ s/_(\w)/uc($1)/eg;
    $self->attr($attr);
}

1;

