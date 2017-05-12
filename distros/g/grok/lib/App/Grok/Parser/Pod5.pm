package App::Grok::Parser::Pod5;
BEGIN {
  $App::Grok::Parser::Pod5::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Parser::Pod5::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';
use File::Temp qw<tempfile>;

my %formatter = (
    text  => 'Pod::Text',
    ansi  => 'Pod::Text::Ansi',
    xhtml => 'Pod::Xhtml',
    pod   => 'Pod::Perldoc::ToPod',
);

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub render_file {
    my ($self, $file, $format) = @_;

    my $form = $formatter{$format};
    die __PACKAGE__ . " doesn't support the '$format' format" if !defined $form;
    eval "require $form";
    die $@ if $@;

    my $done = '';
    ## no critic (InputOutput::RequireBriefOpen)
    open my $out_fh, '>', \$done or die "Can't open output filehandle: $!";

    if ($form eq 'Pod::Perldoc::ToPod') {
        my ($temp_fh, $temp) = tempfile();
        my $pod = do { local $/ = undef; scalar <$file> };
        print $temp_fh $pod;
        $file = $temp;
    }
    else {
        binmode $out_fh, ':utf8' if $form ne 'Pod::Perldoc::ToPod';
    }

    $form->new->parse_from_file($file, $out_fh);
    close $out_fh;
    return $done;
}

sub render_string {
    my ($self, $string, $format) = @_;

    open my $handle, '<', \$string or die "Can't open input filehandle: $!";
    my $result = $self->render_file($handle, $format);
    close $handle;
    return $result;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Parser::Pod5 - A Pod 5 backend for grok

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
