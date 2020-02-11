package WWW::WebKit2::LocatorCSS;

use common::sense;
use Carp qw(croak);
use Moose;
use base 'WWW::WebKit2::Locator';

=head2 resolve_locator

=cut

sub resolve_locator {
    my ($self) = @_;

    my $locator = $self->locator_string;

    if (my ($css) = $locator =~ /^css=(.*)/) {
        return $css;
    }

    return $locator;
}

=head2 prepare_element

=cut

sub prepare_element {
    my ($self, $element_name) = @_;
    $element_name //= 'element';

    my $locator = $self->resolved_locator;

    my $count = $self->inspector->run_javascript($self->prepare_elements_search('length'));
    croak "css: $locator gave $count results" if $count != 1;

    return $self->prepare_elements .
        "$element_name = elements[0];";
}

=head2 prepare_elements

=cut

sub prepare_elements {
    my ($self) = @_;

    my $locator = $self->resolved_locator;

    my $search = "var elements = document.querySelectorAll('$locator');";

    return $search;
}

__PACKAGE__->meta->make_immutable;

1;
