package Waft::JS;

use 5.005;
use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft 0.9910 ();

$VERSION = '0.02';

$Waft::JS::Name = 'Waft.JS';

sub convert_text_part {
    my ($self, $text_part, $break) = @_;

    my @text_parts
        = split /\b \Q$Waft::JS::Name\E \. /xms, $text_part;

    my $code = $self->next( shift(@text_parts), $break );

    while ( @text_parts ) {
        my $text_part = shift @text_parts;

        ( my $method, $text_part ) = split / \b /xms, $text_part, 2;

        if ($method eq 'make_url' or $method eq 'url') {
            $code .= q{$__self->output_js_make_url_script;};
        }

        $code .= $self->next($text_part, $break);
    }

    return $code;
}

sub output_js_make_url_script {
    my ($self) = @_;

    my $base_url = $self->jsstr_escape($self->get_base_url);
    my $page = $self->jsstr_escape($self->page);

    my $v = q{};
    my $value_hashref = $self->value_hashref;
    while ( my ($key, $values_arrayref) = each %$value_hashref ) {
        $key = $self->jsstr_escape($key);
        my @values = map { qq{'$_'} } $self->jsstr_escape(@$values_arrayref);
        $v .= q{v['} . $key . q{'] = [} . join(q{, }, @values) . q{];};
    }

    my $javascript = qq{( function (page, keys, data) {
        var base_url = '$base_url';
        var query_string = '';

        if (page == undefined) page = 'default.html';
        else if (page == 'CURRENT') page = '$page';

        if (page != 'default.html') {
            query_string
                = '?p=' + encodeURIComponent(page).replace(/%20/g, '+');
        }

        var v = {}; $v

        if (keys == undefined)
        return base_url + query_string;

        if (keys.constructor == Object) {
            data = keys;
            keys = [];
        }
        else if (keys == 'ALL_VALUES') {
            keys = [];
            for ( var key in v ) {
                keys.push(key);
            }
        }

        var keep = {};

        for ( var i = 0; i < keys.length; i++ ) {
            if ( v[ keys[i] ] != undefined )
            keep[ keys[i] ] = v[ keys[i] ];
        }

        if ( data ) {
            for ( var key in data ) {
                keep[key] = data[key];
            }
        }

        var escape_space_percent_hyphen = function (val) {
            if ( typeof val != 'string' )
            return val;

            val = val.replace(/%/g, '%25');
            val = val.replace(/ /g, '%20');
            val = val.replace(/-/g, '%2D');

            return val;
        };

        keys = [];

        for ( var key in keep ) {
            keys.push(key);

            if (keep[key].constructor == Array) {
                var val = '';

                for ( var i = 0; i < keep[key].length; i++ ) {
                    val += '-' + escape_space_percent_hyphen(keep[key][i]);
                }

                keep[key] = val;
            }
            else {
                keep[key] = '-' + escape_space_percent_hyphen(keep[key]);
            }
        }

        keys.sort();

        var joined_values = '';

        for ( var i = 0; i < keys.length; i++ ) {
            if (joined_values != '') joined_values += ' ';

            joined_values += escape_space_percent_hyphen(keys[i])
                             + keep[ keys[i] ];
        }

        if (joined_values == '')
        return base_url + query_string;

        query_string += query_string == '' ? '?' : '&';

        query_string
            += 'v=' + encodeURIComponent(joined_values).replace(/%20/g, '+');

        return base_url + query_string;
    } )};

    $javascript =~ s/ (?: \x0D\x0A | [\x0A\x0D] ) \s* / /gxms;

    $self->output($javascript);

    return;
}

1;
__END__

=head1 NAME

Waft::JS - JavaScript extensions for Waft

=encoding utf8

=head1 SYNOPSIS

    package MyWebApp;

    use Waft with => '::JS'; # for Waft 0.9905 or later

or

    package MyWebApp;

    use base qw( Waft::JS Waft );

=head1 DESCRIPTION

Waft のアクションメソッドを起動する JavaScript API を提供する。

=head1 JavaScript API

=over 4

=item *

Waft.JS.url

Arguments: page, [keys], [data]

C<Waft> のメソッド C<url> と同様の動作を行う JavaScript 用のメソッド。

page には C<Waft> の C<page> を指定する。

keys には保持したい C<Waft> のオブジェクト変数のキーを配列で指定する。

data には追加したい C<Waft> のオブジェクト変数のキーと値のペアを
連想配列で指定する。

    <%
    $self->{page} = 0;
    $self->set_values( sort => qw( id ASC ) );
    %>
    Waft.JS.url('record.html', ['page', 'sort'], { id: 1 });

    mywebapp.cgi?p=record.html&v=id-1+page-0+sort-id-ASC

C<Waft.JS.url> は、実際は JavaScript のメソッドではなく、
C<Waft::convert_text_part> をオーバーライドする
C<Waft::JS::convert_text_part> がテンプレート処理時にスクリプトに
置き換えるためのフレーズである。

    Waft.JS.url

は、

    $self->output_js_make_url_script;

に置き換えられ、

    ( function (page, keys, data) { var base_url = ' ...

のように出力される。

=back

=head1 AUTHOR

Yuji Tamashiro, E<lt>yuji@tamashiro.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2009 by Yuji Tamashiro

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
