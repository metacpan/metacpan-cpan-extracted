package Waft::JSON;

use 5.005;
use strict;

use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft 0.9907 ();

$VERSION = '0.03';
$VERSION = eval $VERSION;

sub compile_template {
    my ($self, $template, $template_file, $template_class) = @_;

    if (ref $template eq 'SCALAR') {
        $template = $$template;
    }

    $template
        =~ s{<% (?! \s*[\x0A\x0D]
                    =[A-Za-z]
                )
                \s* json \s* = (.*?)
             %>}{<% \$Waft::Self->output( \$Waft::Self->convert_json($1) ); %>}gxms;

    return $self->next(\$template, $template_file, $template_class);
}

sub convert_json { $_[0]->_make_json(@_[1 .. $#_]) }

sub _make_json {
    my ($self, @values) = @_;

    VALUE:
    for my $value (@values) {
        if ( not defined $value ) {
            $self->warn('Use of uninitialized value');

            next VALUE;
        }

        unless ( ref $value eq 'ARRAY' or ref $value eq 'HASH' ) {
            $self->warn('Use of unencodable value to JSON');

            next VALUE;
        }

        require JSON;
        $value = JSON->new->encode($value);
    }

    return wantarray ? @values : $values[0];
}

1;
__END__

=head1 NAME

Waft::JSON - JSON extensions for Waft

=encoding utf8

=head1 SYNOPSIS

    package MyWebApp;

    use Waft with => '::JSON'; # for Waft 0.9905 or later

or

    package MyWebApp;

    use base qw( Waft::JSON Waft );

=head1 DESCRIPTION

Waft テンプレートのアウトプットプロセスにおいて、JSON への変換機能を提供する。

=head1 TEMPLATE PROCESS

Waft では、テンプレートファイル内の "<%" と "%>" で囲まれた部分はスクリプト
レットとして処理され、Waft 標準では、"<%word="　などのエスケープ補助機能が
提供されている。

本モジュールは、新たに "<%json=" で指定できる、JSON への変換機能を提供する。
"<%json=" と "%>" で囲まれた部分は、JSON モジュールにより、JSON へ変換後、
出力される。

データがハッシュリファレンスの場合、

    <% my $data_hashref = { foo => 1, bar => 2 }; %>
    <%json= $data_hashref %>

    {"bar":2,"foo":1}

と出力され、データが配列リファレンスの場合、

    <% my $data_arrayref = [1, 2, 3, 4, 5]; %>
    <%json= $data_arrayref %>

    [1,2,3,4,5]

と出力される。
また、混在の場合も、

    <% my $data_hashref = { foo => 1, bar => [2, 3, 4] }; %>
    <%json= $data_hashref %>

    {"bar":[2,3,4],"foo":1}

のように出力される。

本機能は、Ajax リクエストへのレスポンス処理を想定して作成したものである。
JavaScript では、JSON はそのままオブジェクトとして解釈されるため、
Ajax のコールバック処理時のレスポンスデータとして扱いやすくなる。

Waft::JS や Waft::jQuery と組み合わせて使用すると、Ajax 開発の補助
となるはずである。

=back

=head1 AUTHOR

Shingo Murata, E<lt>murata@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Shingo Murata

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

