#
# This file is part of Text-CGILike
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Text::CGILike;

# ABSTRACT: Wrapper to create text file using the CGI syntax

use strict;
use warnings;
use Moo;
use Text::Format;
use Carp;

our $VERSION = '0.6';    # VERSION

my $_DEFAULT_CLASS;

has 'columns' => (
    is      => 'rw',
    default => sub {80},
);

sub DEFAULT_CLASS {
    return _self_or_default(shift);
}

sub start_html {
    my ( $self, @texts ) = _self_or_default(@_);
    my $text;
    if ( @texts > 1 ) {
        my %p = @texts;
        $text = $p{-title} || "";
    }
    else {
        ($text) = @texts;
    }
    $self->{_start_html} = $text;
    return $self->hr . $self->_center( "# ", " #", $text ) . $self->hr . "\n";
}

sub end_html {
    my ($self) = _self_or_default(@_);
    my $text = $self->{_start_html} || "END";
    return "\n" . $self->hr . $self->_center( "# ", " #", $text ) . $self->hr;
}

sub meta {

    #no meta in text
    return "";
}

sub h1 {
    my ( $self, $title ) = _self_or_default(@_);
    return $self->_left( "# ", $title ) . $self->br();
}

sub hr {
    my ($self) = _self_or_default(@_);

    return "#" x ( $self->columns ) . "\n";
}

sub br {
    return "\n";
}

sub center {
    my ( $self, $text ) = _self_or_default(@_);
    return $self->_center( '', '', $text );
}

sub ul {
    my ( $self, @li ) = _self_or_default(@_);
    return join( "", grep {defined} @li );
}

sub li {
    my ( $self, $li ) = _self_or_default(@_);
    my $TF
        = Text::Format->new(
        { firstIndent => 0, bodyIndent => 2, columns => $self->columns - 2 }
        );
    return "- " . $TF->format($li);
}

### PRIVATE ###

sub _self_or_default {
    my ( $may_class, @param ) = @_;
    if ( ref $may_class eq __PACKAGE__ ) {
        return ( $may_class, @param );
    }
    else {
        $_DEFAULT_CLASS ||= __PACKAGE__->new;
        return ( $_DEFAULT_CLASS, $may_class, @param );
    }
}

sub _center {
    my ( $self, $left_pad, $right_pad, $text ) = @_;
    $left_pad  = "" unless defined $left_pad;
    $right_pad = "" unless defined $right_pad;

    my $size = $self->columns - length($left_pad) - length($right_pad);
    my $TF   = Text::Format->new(
        { firstIndent => 0, bodyIndent => 0, columns => $size } );

    my @texts = $TF->format($text);
    return join(
        "",
        map {
            sprintf( $left_pad . "%-" . $size . "s" . $right_pad . "\n", $_ )
            }
            map {
            do { chomp; $_ }
            }
            map { $TF->center($_) } @texts
    );

}

sub _left {
    my ( $self, $left_pad, $text ) = @_;
    $left_pad = "" unless defined $left_pad;

    my $size = $self->columns - length($left_pad);
    my $TF   = Text::Format->new(
        { firstIndent => 0, bodyIndent => 0, columns => $size } );

    my @texts = $TF->format($text);
    return $left_pad . join( "" . $left_pad, @texts );

}

sub _expand_arr {
    my ( $tags, @arr ) = @_;
    my @res;
    for my $tag (@arr) {
        if ( substr( $tag, 0, 1 ) eq ':' ) {
            push @res, _expand_arr( $tags, @{ $tags->{$tag} } );
        }
        else {
            push @res, $tag;
        }
    }
    return @res;
}

my %EXPORT_MAP = (
    ':html2' => [
        'h1' .. 'h6', qw/p br hr ol ul li dl dt dd menu code var strong em
            tt u i b blockquote pre img a address cite samp dfn html head
            base body Link nextid title meta kbd start_html end_html
            input Select option comment charset escapeHTML/
    ],
    ':html3' => [
        qw/div table caption th td TR Tr sup Sub strike applet Param nobr
            embed basefont style span layer ilayer font frameset frame script small big Area Map/
    ],
    ':html4' => [
        qw/abbr acronym bdo col colgroup del fieldset iframe
            ins label legend noframes noscript object optgroup Q
            thead tbody tfoot/
    ],
    ':netscape' => [qw/blink fontsize center/],
    ':form'     => [
        qw/textfield textarea filefield password_field hidden checkbox checkbox_group
            submit reset defaults radio_group popup_menu button autoEscape
            scrolling_list image_button start_form end_form startform endform
            start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART/
    ],
    ':cgi' => [
        qw/param upload path_info path_translated request_uri url self_url script_name
            cookie Dump
            raw_cookie request_method query_string Accept user_agent remote_host content_type
            remote_addr referer server_name server_software server_port server_protocol virtual_port
            virtual_host remote_ident auth_type http append
            save_parameters restore_parameters param_fetch
            remote_user user_name header redirect import_names put
            Delete Delete_all url_param cgi_error/
    ],
    ':ssl'     => [qw/https/],
    ':cgi-lib' => [qw/ReadParse PrintHeader HtmlTop HtmlBot SplitParam Vars/],
    ':html'    => [qw/:html2 :html3 :html4 :netscape/],
    ':standard' => [qw/:html2 :html3 :html4 :form :cgi/],
    ':push' =>
        [qw/multipart_init multipart_start multipart_end multipart_final/],
    ':all' => [qw/:html2 :html3 :netscape :form :cgi :internal :html4/]
);

sub import {
    my ( $self, $to_import_str ) = @_;
    my @to_import = $to_import_str =~ /(:?\w+)/gx;
    my $caller    = caller;

    for my $sym ( _expand_arr( \%EXPORT_MAP, @to_import ) ) {
        unless ( $caller->can($sym) ) {
            my $meth = $self->can($sym) // sub {
                carp "Missing tag : ", $sym;
                return join( '', @_ );
            };

            {
                ## no critic qw(ProhibitNoStrict)
                no strict qw/refs/;
                *{"${caller}::$sym"} = $meth;
                ## use critic
            }
        }
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Text::CGILike - Wrapper to create text file using the CGI syntax

=head1 VERSION

version 0.6

=head1 OVERVIEW

CGI is an old module, and now we can create html or text with a simple template.

I have create this module to be able to format my email in html or text by just changing the module I use.

So I don't use template in that case, just a simple '--format=text/html'

=head1 ATTRIBUTES

=head2 DEFAULT_CLASS

To change columns using keywords

    require Text::CGILike;
    Text::CGILike->import(':standard');

    require Term::Size;
    my ($columns) = Term::Size::chars();
    $columns ||= 80;

    my ($TCGI) = Text::CGILike->DEFAULT_CLASS;
    $TCGI->columns($columns);

=head2 columns

number of columns to use by default

=head1 METHODS

=head2 DEFAULT_CLASS

This singleton is use if you don't instanciate Text::CGILike

=head2 start_html

Start the document, you can pass headers like CGI here. Only '-title' will be used.

    start_html('my title');
    start_html(-title => 'my title');

=head2 end_html

Finish the document.

    end_html;

=head2 meta

Completly ignore. no meta in brute text

=head2 h1

Create a box that define the bigger text.

    h1('my big text');

=head2 hr

Create a row of '#' (horizontal rule)

=head2 br

break line

=head2 center

center the text, and respect wrap of text

=head2 ul

create list

=head2 li

do list starting with an asterix '*'

=head2 import

Import tags. check L<CGI> for more information.

=head1 SEE ALSO

L<CGI>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/Text-CGILike/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
