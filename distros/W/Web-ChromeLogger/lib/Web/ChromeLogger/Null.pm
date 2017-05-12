package Web::ChromeLogger::Null;
use strict;
use warnings;
use Carp ();

our $AUTOLOAD;
sub AUTOLOAD {
    no strict "refs"; ## no critic
    *{$AUTOLOAD} = sub {};
    return;
}

sub new {
    my $class = shift;
    bless {}, $class;
}

sub finalize {
    Carp::croak "Web::ChromeLogger::Null cannot finalize logs";
}

sub DESTROY {}

1;
__END__

=encoding utf-8

=head1 NAME

Web::ChromeLogger::Null - Dummy of Web::ChromeLogger

=head1 SYNOPSIS

    use Web::ChromeLogger::Null;

    get '/', sub {
        my $logger = Web::ChromeLogger::Null->new();
        $logger->info('hey!'); # NOP

        my $html = render_html();

        return [
            200,
            ['X-ChromeLogger-Data' => $logger->finalize()], # Throw exception
            $html,
        ];
    };

=head1 DESCRIPTION

Web::ChromeLogger::Null is a dummy of C<Web::ChromeLogger>.

This class provides methods that don't work anything.

=head1 METHODS

=over 4

=item C<< my $logger = Web::ChromeLogger::Null->new() >>

Returns instance of Web::ChromeLogger::Null.

=item C<< $logger->finalize() >>

Always throws exception.

=back

And other provided methods are the same as C<Web::ChromeLogger>, but they don't work anything.

=head1 SEE ALSO

C<Web::ChromeLogger>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

