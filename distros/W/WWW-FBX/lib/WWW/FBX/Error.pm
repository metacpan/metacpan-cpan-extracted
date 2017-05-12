package WWW::FBX::Error;
use 5.014001;
use Moose;
use Try::Tiny;
use Devel::StackTrace;

#Stringify using error sub
use overload '""' => \&error,
             'fallback' => 1;

use namespace::autoclean;


has fbx_error   => ( is => 'rw', predicate => 'has_fbx_error' );
has http_response   => ( isa => 'HTTP::Response', is => 'rw', required => 1, handles => [qw/code message/] );
has stack_trace     => ( is => 'ro', init_arg => undef, builder => '_build_stack_trace' );
has _stringified    => ( is => 'rw', init_arg => undef, default => undef );

sub _build_stack_trace {
    my $seen;
    my $this_sub = (caller 0)[3];
    Devel::StackTrace->new(frame_filter => sub {
        my $caller = shift->{caller};
        my $in_nt = $caller->[0] =~ /^WWW::Net::/ || $caller->[3] eq $this_sub;
        ($seen ||= $in_nt) && !$in_nt || 0;
    });
}

sub error {
    my $self = shift;

    return $self->_stringified if $self->_stringified;

    # Don't walk on $@
    local $@;

    my $error = $self->has_fbx_error && $self->fbx_error_text
      || $self->http_response->status_line;

    my ($location) = $self->stack_trace->frame(0)->as_string =~ /( at .*)/;
    return $self->_stringified($error . ($location || ''));
}

sub fbx_error_text {
    my $self = shift;


    return '' unless $self->has_fbx_error;
    my $e = $self->fbx_error;

    return try {
             exists $e->{msg} && $e->{msg};
    } || '';
}


sub fbx_error_code {
    my $self = shift;

    return $self->has_fbx_error
        && exists $self->fbx_error->{error_code}
        && $self->fbx_error->{error_code}
        || 0;
}

__PACKAGE__->meta->make_immutable;

no Moose;


1;
__END__

=encoding utf-8

=head1 NAME

WWW::FBX::Error - Freebox Error Handling

=head1 SYNOPSIS

    use WWW::FBX::Error;

=head1 DESCRIPTION

WWW::FBX::Error is FBX Error handling

=head1 LICENSE

Copyright (C) Laurent Kislaire.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Laurent Kislaire E<lt>teebeenator@gmail.comE<gt>

=cut

