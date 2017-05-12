package Waft::jQuery;

use 5.005;
use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft 0.9910 ();

$VERSION = '0.02';

$Waft::jQuery::Name = 'Waft.jQuery';

sub convert_text_part {
    my ($self, $text_part, $break) = @_;

    my @text_parts
        = split /\b \Q$Waft::jQuery::Name\E \. /xms, $text_part;

    my $code = $self->next( shift(@text_parts), $break );

    while ( @text_parts ) {
        my $text_part = shift @text_parts;

        ( my $method, $text_part ) = split / \b /xms, $text_part, 2;

        if ($method eq 'get') {
            $code .= q{$__self->output_jquery_request_script('get');};
        }
        elsif ($method eq 'post') {
            $code .= q{$__self->output_jquery_request_script('post');};
        }

        $code .= $self->next($text_part, $break);
    }

    return $code;
}

sub output_jquery_request_script {
    my ($self, $method) = @_;

    my $page = $self->jsstr_escape($self->page);
    my $joined_values
        = $self->jsstr_escape( $self->join_values('ALL_VALUES') );
    my $url = $self->jsstr_escape($self->url);

    my $javascript = qq{( function (action, data, callback, type) {
        if ( jQuery.isFunction(data) ) {
            callback = data;
            data = {};
        }
        else if (data == undefined) {
            data = {};
        }

        var waft_v_tag = jQuery('input:hidden[name=\\'v\\']').get(0);

        data['s'] = '$page';
        data['v'] = waft_v_tag ? jQuery(waft_v_tag).val() : '$joined_values';
        data[action] = '';

        return jQuery.$method('$url', data, callback, type);
    } )};

    $javascript =~ s/ (?: \x0D\x0A | [\x0A\x0D] ) \s* / /gxms;

    $self->output($javascript);

    return;
}

sub output_jquery_sync_script {
    my ($self) = @_;

    $self->output($self->make_jquery_sync_script);

    return;
}

sub make_jquery_sync_script {
    my ($self) = @_;

    my $joined_values
        = $self->jsstr_escape( $self->join_values('ALL_VALUES') );
    my $javascript
        = qq{jQuery('input:hidden[name=\\'v\\']').val('$joined_values');};

    return $javascript;
}

sub jquery_sync_script { $_[0]->make_jquery_sync_script(@_[1 .. $#_]) }

1;
__END__

=head1 NAME

Waft::jQuery - jQuery extensions for Waft

=encoding utf8

=head1 SYNOPSIS

    package MyWebApp;

    use Waft with => '::jQuery'; # for Waft 0.9905 or later

or

    package MyWebApp;

    use base qw( Waft::jQuery Waft );

=head1 DESCRIPTION

Waft のアクションメソッドを起動する Ajax API を提供する。

=head1 Ajax API

=over 4

=item *

Waft.jQuery.get

Arguments: action, [data], [callback], [type]

jQuery の Ajax API C<jQuery.get> を拡張する API。Waft の C<page> と
オブジェクト変数を C<jQuery.get> に埋め込んで実行する。

C<jQuery.get> の引数 C<url> の代わりに C<action>（SUBMIT の名前）を受け取る。

    <form action="<% = $self->url %>" method="GET">
    <input type="submit" name="on" />
    </form>

    <script>
    Waft.jQuery.get('on'); // same as above
    </script>

引数 data、callback、type は C<jQuery.get> と同様に処理される。

    Waft.jQuery.get( 'on', { id: 1 }, function (data) {
        jQuery('#status').html(data);
    }, 'html' );

C<Waft.jQuery.get> は実際には JavaScript のメソッドではなく、
C<Waft::convert_text_part> をオーバーライドする
C<Waft::jQuery::convert_text_part> がテンプレート処理時にスクリプトに
置き換えるためのフレーズである。

    Waft.jQuery.get

は、

    $self->output_jquery_request_script('get');

に置き換えられ、

    ( function (action, data, callback, type) { if ( jQuery.isFunction(dat ...

のように出力される。

=item *

Waft.jQuery.post

Arguments: action, [data], [callback], [type]

jQuery の Ajax API C<jQuery.post> を拡張する API。
仕様は API C<Waft.jQuery.get> と同じ。

=back

=head1 METHODS

=over 4

=item *

output_jquery_sync_script

メソッド C<Waft.jQuery.get> もしくは C<Waft.jQuery.post> で起動した
Waft のアクションメソッド内でオブジェクト変数を変更した場合に、
レスポンスにこのメソッドの出力を加える事でオブジェクト変数の内容を
反映させる事ができる。

    <script><% $self->output_jquery_sync_script; %></script>

=item *

jquery_sync_script

メソッド C<output_jquery_sync_script> が出力するスクリプトを取得する。

    my $jquery_sync_script = $self->jquery_sync_script;

    $self->output("<script>$jquery_sync_script</script>");

=back

=head1 AUTHOR

Yuji Tamashiro, E<lt>yuji@tamashiro.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2009 by Yuji Tamashiro

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
