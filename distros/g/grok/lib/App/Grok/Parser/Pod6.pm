package App::Grok::Parser::Pod6;
BEGIN {
  $App::Grok::Parser::Pod6::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Parser::Pod6::VERSION = '0.26';
}

# blows up if we use strict before this, damn source filter
use Perl6::Perldoc::Parser;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub render_file {
    my ($self, $file, $format) = @_;

    if ($format !~ /^(?:ansi|text|xhtml)$/) {
        die __PACKAGE__ . " doesn't support the '$format' format";
    }
    eval "require Perl6::Perldoc::To::\u$format";
    die $@ if $@;

    my $method = "to_$format";
    return Perl6::Perldoc::Parser->parse($file, {all_pod=>'auto'})
                                 ->report_errors()
                                 ->$method();
}

sub render_string {
    my ($self, $string, $format) = @_;

    open my $handle, '<', \$string or die "Can't open input filehandle: $!";
    binmode $handle, ':utf8';
    my $result = $self->render_file($handle, $format);
    close $handle;
    return $result;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Parser::Pod6 - A Pod 6 backend for grok

=head1 METHODS

=head2 C<new>

This is the constructor. It currently takes no arguments.

=head2 C<render_file>

Takes two arguments, a filename and the name of an output format. Returns
a string containing the rendered document. It will C<die> if there is an
error.

=head2 C<render_string>

Takes two arguments, a string and the name of an output format. Returns
a string containing the rendered document. It will C<die> if there is an
error.

=head1 AUTHOR

Hinrik Örn Sigurðsson, L<hinrik.sig@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Hinrik Örn Sigurðsson

C<grok> is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the file F<LICENSE>
that came with this distribution.

=cut
