package Text::CSV::Encoded::Coder::Base;
$Text::CSV::Encoded::Coder::Base::VERSION = '0.25';
# VERSION

use strict;
use warnings;

sub new {
    my $class = shift;
    my %opt   = @_;
    bless { %opt }, $class;
}


sub upgrade { 0; }


sub encode {
    my ( $self, $encoding, $str ) = @_;
    $str;
}


sub decode {
    my ( $self, $encoding, $str ) = @_;
    $str;
}


sub decode_fields_ref {
    my ( $self, $encoding, $arrayref ) = @_;
}


sub encode_fields_ref {
    my ( $self, $encoding, $arrayref ) = @_;
}


sub encode_check_value {
    $_[0]->{ encode_check_value } = $_[1] if @_ > 1;
    $_[0]->{ encode_check_value } || 0;
}


sub decode_check_value {
    $_[0]->{ decode_check_value } = $_[1] if @_ > 1;
    $_[0]->{ decode_check_value } || 0;
}


1;
__END__


=pod

=head1 NAME

Text::CSV::Encoded::Coder::Base - Interface for Text::CSV::Encoded coder base class

=head1 VERSION

version 0.25

=head1 SYNOPSIS

    package Text::CSV::Encoded::Coder::YourCoder;

    use base qw( Text::CSV::Encoded::Coder::Base );

    sub decode {
        ...
    }

    sub encode {
        ...
    }

    sub upgrade {
        ...
    }

    sub decode_fields_ref {
        ...
    }

    sub encode_fields_ref {
        ...
    }

=head1 DESCRIPTION

This module is used by L<Text::CSV::Encoded> internally.

=head1 INTERFACS

=head2 decode

    ( $self, $encoding, $str ) = @_;
    ....
    return $decoded_str;

Takes an encoding and a CSV string.
It must return a Perl string decoded in C<$encoding>.
In Perl 5.8 or later, if $enc is C<undef> or false, the encoding should be utf8.

=head2 encode

    ( $self, $encoding, $str ) = @_;
    ....
    return $encoded_str;

Takes an encoding and a Perl string.
It must return a CSV string encoded in C<$encoding>.
In Perl 5.8 or later, if $enc is C<undef> or false, the encoding should be utf8.

=head2 decode_fields_ref

    ( $self, $encoding, $arrayref ) = @_;

Takes an encoding and an array reference.
It must decoded each array entries in $encoding.

=head2 encode_fields_ref

    ( $self, $encoding, $arrayref ) = @_;

Takes an encoding and an array reference.
It must encoded each array entries in $encoding.

=head2 upgrade

    ( $self, $str ) = @_;

In Perl 5.8 or later, it is expected to do C<utf8::upgrade> against $str.
In older versions, this method may be meaningless and there is no need to implement.
See to L<utf8>.

=head2 encode_check_value

Setter/Getter for an argument passing to encode.

    $coder->encode_check_value( Encode::FB_PERLQQ );

=head2 decode_check_value

Setter/Getter for an argument passing to decode.

    $coder->encode_check_value( Encode::FB_PERLQQ );

=head1 EXAMPLE

Use with L<Jcode>.

    package Text::CSV::Encoded::Coder::Jcode;
    
    use strict;
    use base qw( Text::CSV::Encoded::Coder::Base );
    
    use Jcode ();
    
    my $Jcode = Jcode->new;
    
    my %alias = (
        'shiftjis' => 'sjis',
        'euc-jp'   => 'euc',
        'sjis'     => 'sjis',
        'euc'      => 'euc',
    );
    
    
    sub decode {
        my ( $self, $encoding, $str ) = @_;
        my $enc = $alias{ $encoding };
        $Jcode->set( $str, $enc )->euc;
    }
    
    
    sub encode {
        my ( $self, $encoding, $str ) = @_;
        my $enc = $alias{ $encoding };
        $Jcode->set( $str, 'euc' )->$enc();
    }
    
    
    sub decode_fields_ref {
        my ( $self, $encoding, $arrayref ) = @_;
        my $enc = $alias{ $encoding };
        for ( @$arrayref ) {
            $_ = $Jcode->set( $_, $enc )->euc;
        }
    }
    
    
    sub encode_fields_ref {
        my ( $self, $encoding, $arrayref ) = @_;
        my $enc = $alias{ $encoding };
        for ( @$arrayref ) {
            $_ = $Jcode->set( $_, 'euc' )->$enc();
        }
    }

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2013 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
