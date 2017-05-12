package Text::MarkPerl;
our $VERSION = '0.01';
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(parse);

use Modern::Perl;
use Data::Pairs;
use English;
use Text::Balanced qw(extract_bracketed);
use HTML::Entities;

sub heading {
    my $text = shift;
    $text =~ /^(\#{1,6})(.+?)(\1)\n/;
    my $heading_size = length($1);
    print "<h$heading_size>$2</h$heading_size>\n";
}

sub striketext {
    my $text = shift;
    $text =~ /^\!\((.+?)\)/;
    print "<strike>$1</strike>";
}

sub strikeword {
    my $text = shift;
    $text =~ /^\!(\w+)/;
    print "<strike>$1</strike>";
}

sub underline {
    my $text = shift;
    $text =~ /^_(.+)_/;
    print "<u>$1</u>";

}

sub wordstrong {
    my $text = shift;
    $text =~ s/^\$//;
    print "<strong>$text</strong>";
}

sub textstrong {
    my $text = $_[0];
    $text =~ /^\$\{(.+?)\}/;
    print "<strong>$1</strong>";
}

sub wordemp {
    my $text = shift;
    $text =~ s/^\@//;
    print "<em>$text</em>";
}

sub textemp {
    my $text = shift;
    $text =~ /^\@\{(.+?)\}/;
    print "<em>$1</em>";
}

sub meta {
    my $text = shift;
    $text =~ /^\*\{(.+?)\}\{(.*?)\}\{(.+?)\}/;
    my $encoded = encode_entities($3);
    print "<$1 $2>$encoded</$1>";
}

sub neta {
    my $text = shift;
    $text =~ /^\%\{(.+?)\}\{(.+?)\}/;
    print "<$1 $2/>";
}

sub print_html_list {
    say "<ul>";
    my $list_ref = shift;
    foreach my $element ( @{$list_ref} ) {
        if ( ref $element ) {
            say "<li>";
            print_html_list($element);
            say "</li>";
        }
        else {
            say "  <li>$element</li>";
        }
    }
    say "</ul>";
}

my $tokenizers = Data::Pairs->new(
    [

        { meta => qr/^\*\{.+?\}\{.*?\}\{.*?\}/ },
        { meta => \&meta },

        { neta => qr/^\%\{.+?\}\{.+?\}/ },
        { neta => \&neta },

        { heading => qr/^(\#{1,6}).+?(\1)\n/ },
        { heading => \&heading },

        { strikeword => qr/^\!\w+/ },
        { strikeword => \&strikeword },

        { striketext => qr/^\!\(.+\)/ },
        { striketext => \&striketext },

        { underline => qr/^_.+_/ },
        { underline => \&underline },

        { wordstrong => qr/^\$\w+/ },
        { wordstrong => \&wordstrong },

        { textstrong => qr/^\$\{.+?\}/ },
        { textstrong => \&textstrong },

        { wordemp => qr/^\@\w+/ },
        { wordemp => \&wordemp },

        { textemp => qr/^\@\{.+?\}/ },
        { textemp => \&textemp },

        { word => qr/^\w+/ },
        {   word => sub { print @_ }
        },

        { space => qr/^[ ]/ },
        {   space => sub { print @_ }
        },

        { cr => qr/^[\n]/ },
        {   cr => sub { say "<br/>" }
        },

        { regular => qr/^./ },
        {   regular => sub { print encode_entities("@_") }
        },
    ]
);

sub parse {

    my $file = shift;
    my $out  = "";

TOP: while ($file) {

        #{ should be on an empty line
        if ( $file =~ /^q\{/ ) {
            my $substr = substr $file, 1;
            $substr = extract_bracketed( $substr, "{}" );
            if ( defined($substr) ) {
                say "<blockquote>";

                #removes { and newline
                my $substr_sub = substr $substr, 2, -2;
                my $substr_sub_encoded = encode_entities($substr_sub);
                print $substr_sub_encoded;

                say "\n</blockquote>";
                $file =~ s/^q$substr//;
                next TOP;
            }
            else {
                die "Incorrect blockquote";
            }
        }

        #{ should be on an empty line
        if ( $file =~ /^\{/ ) {
            my $substr = extract_bracketed( $file, "{}" );
            if ( defined($substr) ) {
                say "<pre><code>";

                #removes { and newline
                my $substr_sub = substr $substr, 2, -2;
                my $substr_sub_encoded = encode_entities($substr_sub);
                print $substr_sub_encoded;

                say "\n</pre></code>";
                $file =~ s/^$substr//;
                next TOP;
            }
            else {
                die "Incorrect code";
            }
        }

        #html list == perl list
        if ( $file =~ /^\[/ ) {
            my $substr = extract_bracketed( $file, "[]" );
            if ( defined($substr) ) {
                my $list_ref = eval "$substr";
                print_html_list $list_ref;
                $file =~ s/^$substr//;
                next TOP;
            }
            else {
                die "Incorrect list";
            }
        }

    MID: foreach my $key ( $tokenizers->get_keys() ) {
            my ( $rx, $sub ) = $tokenizers->get_values($key);

            if ( $file =~ $rx ) {
                $sub->($MATCH);
                $file = $POSTMATCH;
                next TOP;
            }
            else {
                next MID;
            }
        }
    }
}

=head1 NAME

Text::MarkPerl - A Perly markup language.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

You can use the script markperl.pl <filename> to print out
html text. Checkout the demo/* for the markup syntax.

=head1 AUTHOR

mucker, C<< <mukcer at gmx.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-markperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-MarkPerl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::MarkPerl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-MarkPerl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-MarkPerl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-MarkPerl>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-MarkPerl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 mucker.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Text::MarkPerl
