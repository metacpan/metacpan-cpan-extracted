package WebService::Google::Closure::Response;

use Moose;
use MooseX::Types::Moose qw( ArrayRef Str Int );
use JSON;

use WebService::Google::Closure::Types qw( ArrayRefOfWarnings ArrayRefOfErrors Stats );

has format => (
    is         => 'ro',
    isa        => Str,
    trigger    => sub { my $self = shift; die "Bad format - only json" unless $self->format eq 'json' },
);

has content => (
    is         => 'ro',
    isa        => Str,
    trigger    => \&_set_content,
);

has code => (
    is         => 'ro',
    isa        => Str,
    predicate  => 'has_code',
    writer     => '_set_compiledCode',
);

has warnings => (
    is         => 'ro',
    isa        => ArrayRefOfWarnings,
    init_arg   => undef,
    predicate  => 'has_warnings',
    writer     => '_set_warnings',
    coerce     => 1,
);

has errors => (
    is         => 'ro',
    isa        => ArrayRefOfErrors,
    init_arg   => undef,
    predicate  => 'has_errors',
    writer     => '_set_errors',
    coerce     => 1,
);

has stats => (
    is         => 'ro',
    isa        => Stats,
    init_arg   => undef,
    predicate  => 'has_stats',
    writer     => '_set_statistics',
    coerce     => 1,
);

has is_success => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_is_success {
    my $self = shift;
    if ( $self->has_errors ) {
        return 0;
    }
    return 1;
}

sub _set_content {
    my $self = shift;

    my $json = JSON->new();
    my $content = $json->decode( $self->content );
    foreach my $key ( keys %{ $content } ) {
        next unless $content->{ $key };
        my $set = '_set_' . $key;
        $self->$set( $content->{ $key } );
    }
}

# bail out on server errors
sub _set_serverErrors {
    my ($self, $err) = @_;

    my $text = '';
    foreach my $e ( @{ $err } ) {
        $text .= $e->{ error };
    }
    die $text;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

WebService::Google::Closure::Response - Response object from compiling Javascript with Closure

=head1 SYNOPSIS

    my $res = WebService::Google::Closure->new(
      js_code => $js_code,
    )->compile;

    if ( $res->is_success ) {
        print "Shenanigans ahead:\n";
        print $res->code;
    }
    else {
        foreach my $err ( @{ $res->errors } ) {
             $txt .= sprintf("%s line (%d) char [%d].\n",
                             $err->text,
                             $err->lineno,
                             $err->charno);
        }
        die $txt;
    }

=head1 METHODS

=head2 $response->is_success

Boolean saying if the compilation was successful or not.

=head2 $response->code

Returns a string with the compiled javascript code.

=head2 $response->has_warnings

Boolean saying if the compilation generated any warnings

=head2 $response->warnings

An array reference of L<WebService::Google::Type::Warning> objects.

=head2 $response->has_errors

Boolean saying if the compilation generated any errors

=head2 $response->errors

An array reference of L<WebService::Google::Type::Error> objects.

=head2 $response->has_stats

Boolean saying if statistics are available

=head2 $response->stats

A L<WebService::Google::Type::Stats> object.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Magnus Erixzon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
