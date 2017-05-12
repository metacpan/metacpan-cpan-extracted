package Validate::SPF;

# ABSTRACT: Validates SPF text string

use strict;
use warnings;
use Exporter 'import';
use Validate::SPF::Parser;

our $VERSION = '0.005'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

our @EXPORT = ();
our @EXPORT_OK = qw(
    validate
);


sub validate {
    my ( $text ) = @_;

    unless ( $text ) {
        return wantarray ? ( 0, 'no SPF string' ) : 0;
    }

    my $parser = Validate::SPF::Parser->new;

    my $parsed = $parser->parse( $text );

    my $is_valid = $parsed ? 1 : 0;
    my $error = $is_valid
                    ? undef
                    : $parser->error->{text} . ": '" . $parser->error->{context} . "'"
                    ;

    return wantarray ? ( $is_valid, $error ) : $is_valid;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Validate::SPF - Validates SPF text string

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Validate::SPF qw( validate );

    my $spf_text = 'v=spf1 +a/24 mx mx:mailer.example.com ip4:192.168.0.1/16 -all';

    print $spf_text . "\n";
    print ( validate( $spf_text ) ? 'valid' : 'NOT valid' ) . "\n";

=head1 DESCRIPTION

This module implements basic SPF validation.

B<This is ALPHA quality software. The API may change without notification!>

=head1 FUNCTIONS

=head2 validate

Parse and validate SPF string..

=head1 EXPORTS

Module does not export any symbols by default.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<RFC 7208: Sender Policy Framework (SPF) for Authorizing Use of Domains in Email, Version 1|http://tools.ietf.org/html/rfc7208>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/Wu-Wu/Validate-SPF/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
