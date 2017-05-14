package WWWXML::Form::Template;
use strict;
use base 'CGI::FormBuilder::Template::HTML';

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);

    # keep engine instance and replace it with current package to intercept some calls
    $self->{_engine_real} = $self->{engine};
    $self->{engine} = $self;

    return $self;
}

sub param {
    my ($self, $param, $tag) = @_;

    # delete "bad" template variables (known)
    return if $param eq 'field' || $param eq 'fields' || substr($param, 0, 5) eq 'loop-';

    # replace dashes with underscores to avoid problems
    $param =~ s/-/_/g;

    # finally set param
    return $self->{_engine_real}->param($param => $tag);
}

sub output {
    my $self = shift;
    return $self->{_engine_real}->output(@_);
}

1;
