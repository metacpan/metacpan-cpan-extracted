package Text::APL::WithCaching;

use strict;
use warnings;

use base 'Text::APL::Core';

sub _process {
    my $self = shift;
    my ($input, $context, $cb) = @_;

    if (my $cache = $self->_load_cache($context)) {
        if ($cache->{id} ne $context->id) {
            $cache->{sub_ref} =
              $self->SUPER::_compile($cache->{code}, $context);
        }

        return $cb->($self, $cache->{sub_ref});
    }

    $self->SUPER::_process(@_);
}

sub _compile {
    my $self = shift;
    my ($code, $context) = @_;

    my $sub_ref = $self->SUPER::_compile($code, $context);

    $self->_cache($code, $context, $sub_ref);

    return $sub_ref;
}

sub _load_cache {
    my $self = shift;
    my ($context) = @_;

    return unless defined $context->name;

    return unless exists $self->{cache}->{$context->name};

    return $self->{cache}->{$context->name};
}

sub _cache {
    my $self = shift;
    my ($code, $context, $sub_ref) = @_;

    return unless defined $context->name;

    $self->{cache}->{$context->name} = {
        id      => $context->id,
        code    => $code,
        sub_ref => $sub_ref
    };
}

1;
__END__

=pod

=head1 NAME

Text::APL::WithCaching - a version with caching support

=head1 DESCRIPTION

This is an inherited from L<Text::APL::Core> class that adds caching.

=cut
