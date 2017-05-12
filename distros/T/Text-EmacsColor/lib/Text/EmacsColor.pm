package Text::EmacsColor;
use Mouse;
use File::Temp;
use Path::Class;
use File::ShareDir;
use Text::EmacsColor::Result;

sub dist_file(@) {
    return File::ShareDir::dist_file('Text-EmacsColor', file(@_)->stringify);
}

use namespace::clean -except => 'meta';

our $VERSION = '0.03';

has 'emacs_command' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    default    => sub {
        'emacs --batch --eval',
          # or 'emacsclient --eval',
    },
);

sub format {
    my ($self, $code, $mode) = @_;

    my $fh = File::Temp->new();
    my $filename  = $fh->filename;
    print {$fh} $code;

    $mode = $mode ? qq{"$mode"} : 'NIL';

    my $cmd = $self->emacs_command;
    my $htmlize = dist_file 'lisp', 'htmlize.el';
    my $driver  = dist_file 'lisp', 'driver.el';

    my $html =
      qx "$cmd '(progn
                  (load-file \"\Q$htmlize\E\")
                  (load-file \"\Q$driver\E\")
                  (print
                    (Text::EmacsColor-htmlize \"\Q$filename\E\" $mode)))' 2>/dev/null";

    $html =~ s/(^"|"$)//g;
    my %fixes = (
        n   => "\n",
        '"' => '"',
        "\\" => "\\",
    );
    $html =~ s/\\(.)/$fixes{$1}/g;
    return Text::EmacsColor::Result->new( full_html => $html );
}

1;

__END__

=head1 NAME

Text::EmacsColor - syntax-highlight code snippets with Emacs

=head1 SYNOPSIS

    my $colorer = Text::EmacsColor->new;

    my $html = $colorer->format(
        'my $foo = 42', # code
        'cperl',        # the emacs mode to use (cperl, lisp, haskell, ...)
    );

By default, emacs will exec in --batch mode.  If you want to use emacsclient
or pass other options to emacs, specify the emacs_command initarg:

    my $colorer = Text::EmacsColor->new( emacs_command => 'emacsclient --eval' );

Note that C<$html>, the return value of C<format>, is an instance of
L<Text::EmacsColor::Result|Text::EmacsColor::Result>.  It stringifies
to the HTML-ified text that emacs returns, but also provides other
functionality.  See L<Text::EmacsColor::Result> for more details.

=head1 TODO

auto-detect running emacs and use it

=head1 REPOSITORY

L<http://github.com/jrockway/text-emacscolor>

=head1 SEE ALSO

L<Text::VimColor|Text::VimColor>

Emacs' highlighting is way better, but this is where I got the name
from.

My C<cperl-mode> is the most up-to-date Perl highligher for emacs; get
it from L<http://github.com/jrockway/cperl-mode>.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008 Jonathan Rockway

This module is Free Software, you may redistribute it under the same
terms as Perl itself.
