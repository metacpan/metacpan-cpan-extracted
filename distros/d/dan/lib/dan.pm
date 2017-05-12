package dan;

use 5.009005;
use strict;
use warnings;

use Encode qw(find_encoding);

our $VERSION = '0.551.2';

our $SINGLETON = bless { code => {} }, __PACKAGE__;

sub croak {
    require Carp;
    Carp::croak(__PACKAGE__ . ": @_");
}

my $LATIN1 = find_encoding('iso-8859-1')
    or croak("Can't load latin-1");

my $DEFAULT_ENCODING;
my $DEFAULT_UTF8HINTBITS;
my $utf8_hint_bits = 0x00800000;
my $is_DanThe;

sub import {
    my($class, %opts) = @_;

    if (exists $opts{the} && !$is_DanThe) {
        eval "package the; sub Dan { shift; return wantarray ? \@_ : \$_[0] } 1;";
        $is_DanThe++;
        return;
    }

    if (ref($opts{cat_decode} || '') eq 'CODE' && ! exists $opts{decode}) {
        $opts{decode} = sub { shift };
    }

    # set hinthash
    $^H{$class} = 'dan';

    # set option
    my $pkg = caller;
    $SINGLETON->{code}->{$pkg} = \%opts;

    # swapping to utf8 hint bits
    $DEFAULT_UTF8HINTBITS = 0;
    if ($opts{force} && $^H & $utf8_hint_bits) {
        $DEFAULT_UTF8HINTBITS = 1;
        $^H &= ~$utf8_hint_bits;
    }

    # swapping to encoding
    $DEFAULT_ENCODING = ${^ENCODING};
    ${^ENCODING} = $SINGLETON;
}

sub unimport {
    my $class = shift;
    undef $^H{$class};
    my $pkg = caller;
    delete $SINGLETON->{code}->{$pkg};

    if ($DEFAULT_UTF8HINTBITS) {
        $DEFAULT_UTF8HINTBITS = 0;
        $^H |= $utf8_hint_bits;
    }
    ${^ENCODING} = $DEFAULT_ENCODING || ${^ENCODING};
}


sub is_dan {
    my $level = $_[1] // 1;
    my $hinthash = (caller($level))[10];
    $hinthash->{"" . __PACKAGE__};
}

sub run {
    my($self, $mode, $str, %opts) = @_;
    my $level = $opts{level} // 1;
    my $pkg = (caller($level))[0];
    my $code = ($SINGLETON->{code}->{$pkg} || {})->{$mode} || '';
    return $code if $opts{wantcode};

    return '' unless ref($code) eq 'CODE';
    return $code->($str);
}

# for DATA / END section
sub name { $LATIN1->name }

sub decode {
    my $self = shift;
    if ($self->is_dan) {
        my($str) = @_;
        $self->run( decode => $str );
    } else {
        $LATIN1->decode(@_);
    }
}

sub cat_decode {
    my $self = shift;

    if ($self->is_dan) {
        my(undef, undef, $idx, $quot) = @_;
        my ( $rdst, $rsrc, $rpos ) = \@_[ 0, 1, 2 ];
        my $pos = $idx;
        while ((my $tmp = index $$rsrc, $quot, $pos) > 0) {
            $pos = $tmp + 1;
            last unless substr($$rsrc, $tmp - 1, 1) eq "\\";
        }
        $$rpos = $pos;

        my $capt = substr($$rsrc, $idx, ($pos - $idx) - 1);
        $$rdst = $self->run( cat_decode => $capt ) . $quot;
        1;
    } else {
        $LATIN1->cat_decode(@_);
    }
}

1;
__END__

=head1 NAME

dan - The literal unread

=head1 SYNOPSIS

  use dan;
  print "foo"; # not displaying
  no dan;
  print "foo"; # foo

  use dan the => 'Blogger';
  print Dan the 'Blogger';


it is possible to solve it with force though there are utf8 pragma and no compatibility. 

  use utf8;
  use dan force => 1;
  print "foo"; # not displaying
  no dan;
  print "foo"; # foo

=head1 DESCRIPTION

dan is not Dan Kogai.
dan the unread to literal strings.

it is a present for perl 20 years old and 5.10 release commemoration. 

=head1 OPTIONS

=over 4

=item cat_decode

  use dan cat_decode => sub {
      my $str = shift;
      $str =~ s/Jcode/Encode/;
      $str;
  };
  print "Jcode";# Encode

or

  use utf8;
  use dan force => 1, cat_decode => sub {
      my $str = shift;
      $str =~ s/Jcode/Encode/;
      $str;
  };
  print "Jcode";# Encode

=item force

  use utf8;
  use dan force => 1;
  print "foo"; # not displaying

=item the

  use dan the => 'Blogger';
  print Dan the 'Blogger';

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
