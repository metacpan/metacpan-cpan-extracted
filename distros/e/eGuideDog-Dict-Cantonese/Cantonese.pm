package eGuideDog::Dict::Cantonese;

use strict;
use warnings;
use utf8;
use Encode::CNMap;
use Storable;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use eGuideDog::Dict::Cantonese ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.41';


# Preloaded methods go here.

sub new() {
  my $self = {};
  $self->{jyutping} = {}; # The most probably phonetic symbol
  $self->{chars} = {}; # all phonetic symbols (array ref)
  $self->{words} = {}; # word phonetic symbols (array ref)
  $self->{word_index} = {}; # the first char to words (array ref)
  bless $self, __PACKAGE__;

  # load zhy_list
  my $dir = __FILE__;
  $dir =~ s/[.]pm$//;

  if(-e "$dir/Cantonese.dict") {
    my $dict = retrieve("$dir/Cantonese.dict");
    $self->{jyutping} = $dict->{jyutping};
    $self->{chars} = $dict->{chars};
    $self->{words} = $dict->{words};
    $self->{word_index} = $dict->{word_index};
  }

  return $self;
}

sub update_dict {
  my $self = shift;

  $self->{jyutping} = {};
  $self->{chars} = {};
  $self->{words} = {};
  $self->{word_index} = {};

  $self->import_unihan("Cantonese.txt");
  $self->import_zhy_list("zhy_list");

  my $dict = {jyutping => $self->{jyutping},
	      chars => $self->{chars},
	      words => $self->{words},
	      word_index => $self->{word_index},
	     };
  store($dict, "Cantonese.dict");
}

sub import_unihan {
  my ($self, $cantonese_txt) = @_;
  open(DATA_FILE, '<', $cantonese_txt);
  while(<DATA_FILE>) {
    chomp;
    my @line = split(/\s+/, $_);
    my $char = chr(hex($line[0]));
    my @phons = @line[1 .. $#line];
    if (not defined $self->{chars}->{$char}) {
      $self->{chars}->{$char} = \@phons;
    }
    my $char_simp = utf8_to_simputf8($char);
    if ($char_simp !~ /[?]/) {
      if (!defined $self->{chars}->{$char_simp}) {
	$self->{chars}->{$char_simp} = \@phons;
      }
    }
    my $char_trad = utf8_to_tradutf8($char);
    if ($char_trad !~ /[?]/) {
      if (!defined $self->{chars}->{$char_trad}) {
	$self->{chars}->{$char_trad} = \@phons;
      }
    }
  }
  close(DATA_FILE);
}

sub add_symbol {
  my ($self, $char, $symbol) = @_;

  if (not $self->{chars}->{$char}) {
    $self->{chars}->{$char} = [$symbol];
    return 1;
  } else {
    foreach (@{$self->{chars}->{$char}}) {
      if ($symbol eq $_) {
	return 0;
      }
    }
    $self->{chars}->{$char} = [@{$self->{chars}->{$char}}, $symbol];
    return 1;
  }
}

sub import_zhy_list {
  my ($self, $zhy_list) = @_;

  open(ZHY_LIST, '<:utf8', $zhy_list);
  while (my $line = <ZHY_LIST>) {
    if ($line =~ /^(.)\s([^\s]*)\s$/) {
      if ($1 && $2) {
	$self->{jyutping}->{$1} = $2;
	$self->add_symbol($1, $2);
      }
    } elsif ($line =~ /^[(]([^)]*)[)]\s([^\s]*)\s$/) {
      my @chars = split(/ /, $1);
      my @symbols = split(/[|]/, $2);
      if ($#chars != $#symbols) {
	warn "Dictionary error:" . "@chars" . "-" . "@symbols";
        next;
      }
      my $word = join("", @chars);
      if ($self->{word_index}->{$chars[0]}) {
	push(@{$self->{word_index}->{$chars[0]}}, $word);
      } else {
	$self->{word_index}->{$chars[0]} = [$word];
      }
      $self->{words}->{$word} = \@symbols;
      for (my $i = 0; $i <= $#chars; $i++) {
	$self->add_symbol($chars[$i], $symbols[$i]);
      }
    }
  }
  close(ZHY_LIST);

  # add numbers
  $self->{jyutping}->{"0"} = "ling4";
  $self->{jyutping}->{"1"} = "jat1";
  $self->{jyutping}->{"2"} = "ji6";
  $self->{jyutping}->{"3"} = "saam1";
  $self->{jyutping}->{"4"} = "sei3";
  $self->{jyutping}->{"5"} = "ng5";
  $self->{jyutping}->{"6"} = "luk6";
  $self->{jyutping}->{"7"} = "cat1";
  $self->{jyutping}->{"8"} = "baat3";
  $self->{jyutping}->{"9"} = "gau2";
}

sub get_jyutping {
  my ($self, $str) = @_;

  if (not utf8::is_utf8($str)) {
    if (not utf8::decode($str)) {
      warn "$str is not in utf8 encoding.";
      return undef;
    }
  } elsif (not $str) {
    return undef;
  }

  if (wantarray) {
    my @jyutping;
    for (my $i = 0; $i < length($str); $i++) {
      my $char = substr($str, $i, 1);
      my @words = $self->get_words($char);
      my $longest_word = '';
      foreach my $word (@words) {
	if (index($str, $word) == 0) {
	  if (length($word) > length($longest_word)) {
	    $longest_word = $word;
	  }
	}
      }
      if ($longest_word) {
	push(@jyutping, @{$self->{words}->{$longest_word}});
	$i += $#{$self->{words}->{$longest_word}};
      } else {
	push(@jyutping, $self->{jyutping}->{$char});
      }
    }
    return @jyutping;
  } else {
    my $char = substr($str, 0, 1);
    my @words = $self->get_words($char);
    my $longest_word = '';
    foreach my $word (@words) {
      if (index($str, $word) == 0) {
	if (length($word) > length($longest_word)) {
	  $longest_word = $word;
	}
      }
    }
    if ($longest_word) {
      return $self->{words}->{$longest_word}->[0];
    } else {
      return $self->{jyutping}->{$char};
    }
  }
}

sub get_words {
  my ($self, $char) = @_;

  if ($self->{word_index}->{$char}) {
    return @{$self->{word_index}->{$char}};
  } else {
    return ();
  }
}

sub is_multi_phon {
  my ($self, $char) = @_;
  return $#{$self->{chars}->{$char}};
}

sub get_multi_phon {
  my ($self, $char) = @_;
  if ($self->{chars}->{$char}) {
    return @{$self->{chars}->{$char}};
  } else {
    return undef;
  }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=encoding utf8

=head1 NAME

eGuideDog::Dict::Cantonese - an informal Jyutping dictionary.

=head1 SYNOPSIS

  use utf8;
  use eGuideDog::Dict::Cantonese;

  binmode(stdout, 'utf8');
  my $dict = eGuideDog::Dict::Cantonese->new();
  my @symbols = $dict->get_multi_phon("长");
  print "长(all pronunciation): @symbols\n"; # cong2 zoeng2 coeng4 - cong2 should be a mistake in dictionary. This kind of mistake is common and the dictionary is far from perfect.
  my $symbol = $dict->get_jyutping("长");
  print "长(default pronunciation): $symbol\n"; # 长: coeng4
  $symbol = $dict->get_jyutping("长辈");
  print "长辈的长: $symbol\n"; # zoeng2
  @symbols = $dict->get_jyutping("粤拼");
  print "粤拼: @symbols\n"; # 粤拼: jyut6 ping3
  my @words = $dict->get_words("长");
  print "Some words begin with 长: @words\n";

=head1 DESCRIPTION

This module is for looking up Jyutping of Cantonese characters or words. It's edited by a programmer not a linguistician. There are many mistakes. So don't take it serious. It's a part of the eGuideDog project (http://e-guidedog.sf.net).

=head2 EXPORT

None by default.

=head1 METHODS

=head2 new()

Initialize dictionary.

=head2 get_jyutping($str)

Return an array of jyutping phonetic symbols of all characters in $str if it is in an array context.

Return a string of jyutping phonetic symbol of the first character if it is not in array context. If it's a multi-phonetic-symbol character, the default symbol will be output.

=head2 get_words($char)

Return an array of words which are begined with $char. This list of words contains multi-phonetic-symbol characters and the symbol used in the word is not the default one.

=head2 is_multi_phon($char)

Return non-zero if $char is multi-phonetic-symbol character. The returned value plus 1 is the number of phonetic symbols the character has.

Return 0 if $char is single-phonetic-symbol character.

=head2 get_multi_phon($char)

Return an array of phonetic symbols of $char.

=head1 SEE ALSO

L<eGuideDog::Dict::Mandarin>, L<http://e-guidedog.sf.net>

=head1 AUTHOR

Cameron Wong, E<lt>hgn823-perl at yahoo.com.cnE<gt>

=head1 COPYRIGHT AND LICENSE

=over 2

=item of the Module

Copyright 2008 by Cameron Wong

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=item Some of the dictionary data is from Unihan

Copyright (c) 1996-2006 Unicode, Inc. All Rights reserved.

  Name: Unihan database
  Unicode version: 5.0.0
  Table version: 1.1
  Date: 7 July 2006

=back

=cut
