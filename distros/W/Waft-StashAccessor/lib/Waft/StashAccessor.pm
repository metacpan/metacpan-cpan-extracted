package Waft::StashAccessor;

use 5.005;
use base 'Exporter';
use strict;
use vars qw( $VERSION @EXPORT );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Carp;
use Waft ();

$VERSION = '0.01';
$VERSION = eval $VERSION;

@EXPORT = qw( make_stash_accessor );

sub make_stash_accessor {
    my (@keys) = @_;
    my $option =   ref $keys[-1] eq 'HASH' ? pop @keys
                 :                           {};

    my $caller = caller;

    my $minlen = $option->{minlen};

    for my $key ( @keys ) {
        my $setter = sub {
            my ($self, $value) = @_;

            validate($value, $minlen);

            $self->stash($caller)->{$key} = $value;

            return;
        };

        my $getter = sub {
            my ($self) = @_;

            my $value = $self->stash($caller)->{$key};

            validate($value, $minlen);

            return $value;
        };

        no strict 'refs';
        *{ "${caller}::set_$key" } = $setter;
        *{ "${caller}::get_$key" } = $getter;
    }

    return;
}

sub validate {
    my ($value, $minlen) = @_;

    if ( $minlen ) {
        croak 'Use of uninitialized value' if not defined $value;
        croak 'Less than minimum length' if length $value < $minlen;
    }

    return;
}

1;
__END__

=head1 NAME

Waft::StashAccessor - Make accessor for Waft::stash

=encoding utf8

=head1 SYNOPSIS

    package MyWebApp;

    use base 'Waft';
    use Waft::StashAccessor;

    make_stash_accessor('foo');

    my $obj = __PACKAGE__->new;

    $obj->set_foo('bar'); # same as $obj->stash('MyWebApp')->{foo} = 'bar'

    print $obj->get_foo;  # same as print $obj->stash('MyWebApp')->{foo}

=head1 DESCRIPTION

C<Waft> の C<stash> へアクセスするためのメソッドを生成する。引数に C<stash> の
キーとなる文字列を受け取り、そのキーの先頭に set_、get_ を付加した文字列が
メソッドの名前となる。

set_* で C<stash> に格納し、get_ で C<stash> から取得する。

最後の引数にオプションを指定する事で、値に制約を設ける事ができる。

    make_stash_accessor('foo', { minlen => 1 }); # 文字数が 1文字以上である事

    $obj->set_foo('bar'); # ok
    $obj->set_foo('0');   # ok
    $obj->set_foo('');    # not ok
    $obj->set_foo(undef); # not ok

制約に違反した場合は例外を発生する。

=head2 EXPORT

=over 4

=item *

make_stash_accessor

Arguments: @keys, \%option?

C<stash> へのアクセサを生成するための関数。引数で指定された 1つのキー、
もしくは複数のキー毎に、setter と getter を生成する。

最後の引数がハッシュ変数のリファレンスの場合はオプションとして処理される。
オプション minlen を指定すると、最低長の制約を設ける事ができる。

=back

=head1 AUTHOR

Yuji Tamashiro, E<lt>yuji@tamashiro.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Yuji Tamashiro

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
