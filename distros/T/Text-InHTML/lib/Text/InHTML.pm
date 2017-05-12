package Text::InHTML;

use strict;
use warnings;
use version;our $VERSION = qv('0.0.4');

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    encode_plain encode_whitespace encode_perl encode_diff encode_html encode_css 
    encode_sql   encode_mysql      encode_xml  encode_dtd  encode_xslt encode_xmlschema
);
our %EXPORT_TAGS = ('common' => \@EXPORT_OK);

sub import {
    my ($me, @gimme) = @_;
    my %seen;
    @seen{ @EXPORT_OK } = ();
    for my $func (@gimme) {
        next if exists $seen{ $func };
        push @EXPORT_OK, $func if $func =~ m{^encode_\w+$};
    }
}

sub encode_whitespace {
    my ($string, $tabs) = @_;
    
    $tabs = 4 if !defined $tabs || $tabs !~ m/^\d+$/;
    my $spaces = ' ' x $tabs;
    
    $string =~ s{\n}{<br />\n}g;    
    $string =~ s{\t}{$spaces}g;
    $string =~ s{[ ]{5}}{&nbsp; &nbsp; &nbsp;}g;
    $string =~ s{[ ]{3}}{&nbsp; &nbsp;}g;
    $string =~ s{[ ]{2}}{&nbsp; }g;
    
    return $string;
}

sub encode_plain {
    my ($string, $tabs) = @_;
    require HTML::Entities;
    return Text::InHTML::encode_whitespace( 
        HTML::Entities::encode($string, '<>&"'), $tabs 
    );
}

sub AUTOLOAD {    
    my($string, $syntax, $tabs) = @_;
    
    $syntax = {} if !defined $syntax || ref $syntax ne 'HASH';    
    my ($format) = our $AUTOLOAD =~  m{encode_(\w+(-\w+)*)};

    die "Could not autoload $AUTOLOAD" if !$format; # only dies when they don't follow the rules    
    $format =~ s{_}{-}g;

    if(eval { require Syntax::Highlight::Universal; }) {
        my $hl = Syntax::Highlight::Universal->new();
        $syntax->{'pre_proc'}->($hl) if ref $syntax->{'callbacks'} eq 'CODE';
        return Text::InHTML::encode_whitespace(
            $hl->highlight($format, $string, $syntax->{'callbacks'}), $tabs
        );
    }
    
    return Text::InHTML::encode_plain( $string );
}

1;

__END__

=head1 NAME

Text::InHTML - Display plain text in HTML

=head1 SYNOPSIS

  use Text::InHTML;
  my $html = Text::InHTML::encode_plain($plain_text_text);
  my $syntax_higlighted_diff = Text::InHTML::encode_diff($plain_text_diff);

=head1 DESCRIPTION

In its simplest form it turns a plain text string into HTML that when rendered retains its whitespace without pre tags or pre-like css.
Also HTML is encoded so no HTML is rendered like it would be with pre tags. Useful for displaying source code or a text file on a web page exactly as-is.

More advanced useage includes syntax highlighting.

=head2 EXPORT

None by default.

Any encode_* is exportable

The tag :common does:
 encode_plain encode_whitespace encode_perl encode_diff encode_html encode_css 
 encode_sql   encode_mysql      encode_xml  encode_dtd  encode_xslt encode_xmlschema

=head1 Functions

=head2 encode_plain

Returns an HTML and whitespace encoded version of $plain_text_string

    encode_plain($plain_text_string);

$tabs is the number of spaces a tab should be considered to be, default is 4

    encode_plain($plain_text_string, $tabs);

=head2 encode_whitespace

Mostly a utility function, returns whitespace encoded version of $string

    encode_whitespace($tring);

$tabs is the number of spaces a tab should be considered to be, default is 4

    encode_whitespace($plain_text_string, $tabs);

=head2 encode_perl, encode_diff, encode_*

You can call Text::InHTML::encode_whatever(), where "whatever" is a "format" as listed under "Processing text" at L<Syntax::Highlight::Universal> 

Note: if the format has a dash, like "html-css" then you need to call it with an underscore in place of each - like so:

    Text::InHTML::encode_html_css()

and it will return HTML that is syntax highlighted (what L<Syntax::Highlight::Universal> does) *and* retains whitespace (what L<Syntax::Highlight::Universal> does not do)

    my $syntax_highlighted_source_code = Text::InHTML::encode_perl($string); 

    my $syntax_highlighted_source_code = Text::InHTML::encode_perl($string, $syntax);
    
    my $syntax_highlighted_source_code = Text::InHTML::encode_perl($string, $syntax, $tabs);    

    my $syntax_highlighted_source_code = Text::InHTML::encode_perl($string, undef, $tabs);

    my $syntax_highlighted_source_code = Text::InHTML::encode_perl($string, {}, $tabs);

$tabs is the number of spaces a tab should be considered to be, default is 4

If L<Syntax::Highlight::Universal> is installed, it calls L<Syntax::Highlight::Universal>'s highlight method with the given format, othersise it simply does encode_plain()

Additionally $syntax can be a hashref which gives you fine grained control over the L<Syntax::Highlight::Universal> object.

Its keys and values are as follows:

=over 4

=item * callbacks

Value is the same as L<Syntax::Highlight::Universal>'s highlight() method's 3rd argument.

=item * pre_proc

Value is a code ref whose only argument if the  L<Syntax::Highlight::Universal> object that will next be used to process the $string

=back

=head1 SEE ALSO

L<HTML::Entities>, L<Syntax::Highlight::Universal>

=head1 TIPS

=over 4

=item * Wrap the whole thing in a  div that's monospace styled and source code will look real nice!

=item * You'll need to use CSS to color in the highlighted syntax. The L<Syntax::Highlight::Universal> bundle has some samples and info on how to generate that CSS.

=back

=head1 TODO

Function(s) to facilitate javascript highlighters like google's syntax highlighter framework.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
