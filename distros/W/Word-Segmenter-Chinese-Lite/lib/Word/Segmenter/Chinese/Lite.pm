package Word::Segmenter::Chinese::Lite;

use 5.008008;
use strict;
use warnings;

use Encode;
use Word::Segmenter::Chinese::Lite::Dict qw(wscl_get_dict_default);

require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(wscl_seg wscl_set_mode);
our $VERSION = '0.08';

our $WSCL_MODE = 'dict';
our %WSCL_DICT;

sub wscl_set_mode {
    my $mode = shift;
    if ( $mode eq 'dict' or $mode eq 'obigram' or $mode eq 'unigram' ) {
        $WSCL_MODE = $mode;
    }
    return 0;
}

sub wscl_seg {
    my $str = shift;
    if ( $WSCL_MODE eq 'dict' ) {
        %WSCL_DICT = wscl_get_dict_default() unless defined $WSCL_DICT{'1'};
        return wscl_seg_dict($str);
    }
    if ( $WSCL_MODE eq 'obigram' ) {
        return wscl_seg_obigram($str);
    }
    if ( $WSCL_MODE eq 'unigram' ) {
        return wscl_seg_unigram($str);
    }
    return 0;
}

sub wscl_seg_unigram {
    my $w = shift;
    my @r = map { $_ = encode( 'utf8', $_ ) } split //, decode( 'utf8', $w );
    return @r;
}

sub wscl_seg_obigram {
    my $w = shift;
    my @r;
    for ( 0 .. length( decode( 'utf8', $w ) ) ) {
        my $tmp = encode( 'utf8', substr( decode( 'utf8', $w ), $_, 2 ) );
        push @r, $tmp;
    }
    return @r;
}

sub wscl_seg_dict {
    my $string = shift;
    my $real_max_length = shift || 9;

    my $line = decode( 'utf8', $string );
    my $len = length($line);
    return 0 if !$len or $len <= 0;

    my @result;
    my @eng = $line =~ /[A-Za-z0-9\-\_\:\.]+/g;
    unshift @result, @eng;

    while ( length($line) >= 1 ) {
        for ( 0 .. $real_max_length - 1 ) {
            my $len = $real_max_length - $_;
            my $w = substr( $line, $_ - $real_max_length );
            if ( defined $WSCL_DICT{$len}{$w} ) {
                unshift @result, encode( 'utf8', $w );
                $line =
                  substr( $line, 0, length($line) - ( $real_max_length - $_ ) );
                last;
            }

            if ( $_ == $real_max_length - 1 ) {
                $line = substr( $line, 0, length($line) - 1 );
            }
        }
    }
    return @result;
}

1;
__END__

=encoding utf8

=head1 NAME

Word::Segmenter::Chinese::Lite - Split Chinese into words

=head1 SYNOPSIS

  use Word::Segmenter::Chinese::Lite qw(wscl_seg wscl_set_mode);

  my @result = wscl_seg("中华人民共和国成立了oyeah");
  foreach (@result)
  {
    print $_, "\n";
  }
  # got:
  # 中华人民共和国
  # 成立
  # 了
  # oyeah

  wscl_set_mode("obigram");
  my @result = wscl_seg("中华人民共和国成立了");
  foreach (@result)
  {
    print $_, "\n";
  }
  # got:
  # 中华
  # 华人
  # 人民
  # 民共
  # 共和
  # 和国
  # 国成
  # 成立
  # 立了
  # 了

  wscl_set_mode("unigram");
  my @result = wscl_seg("中华人民共和国");
  foreach (@result)
  {
    print $_, "\n";
  }
  # got:
  # 中
  # 华
  # 人
  # 民
  # 共
  # 和
  # 国

=head1 METHODS

=head2 wscl_set_mode($mode)

Optional.

You can choose modes below.

"dict" : Default. 词典分词，本模块自带词典。

"unigram" : 一元分词。

"obigram" : Overlapping Bigram. 交叉二元分词。

=head2 wscl_seg($chinese_article, $max_word_length)

Main method.

Input a chinese article which want to de splited.

Output a list.

$chinese_article -- must be utf8 encoding

$max_word_length -- Optional

=head1 EXPORT

no method will be exported by default.

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
