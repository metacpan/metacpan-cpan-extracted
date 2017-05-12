package Text::CSV::Encoded;
$Text::CSV::Encoded::VERSION = '0.25';
use strict;
use warnings;
use Carp ();

# VERSION


BEGIN {
    require Text::CSV;
    if ( Text::CSV->VERSION < 1.06 ) {
        Carp::croak "Base class Text::CSV version is less than 1.06.";
    }
    my $backend = Text::CSV->backend;
    my $version = Text::CSV->backend->VERSION;
    if ( ( $backend =~ /XS/ and $version >= 0.99 ) or ( $backend =~ /PP/ and $version >= 1.30 ) ) {
        eval q/ sub automatic_UTF8 { 1; } /; # parse/getline return strings (UNICODE)
    }
    else {
        eval q/ sub automatic_UTF8 { 0; } /;
    }
}

use base qw( Text::CSV );


my $DefaultCoderClass = $] >= 5.008 ? 'Text::CSV::Encoded::Coder::Encode'
                                    : 'Text::CSV::Encoded::Coder::Base';
my @Attrs;


BEGIN {
    @Attrs = qw(
        encoding
        encoding_in       encoding_out
        encoding_io_in    encoding_io_out
        encoding_to_parse encoding_to_combine
    );
}


sub import {
    my ( $class, %args ) = @_;

    return unless %args;

    if ( exists $args{ coder_class } ) {
        $DefaultCoderClass = $args{ coder_class };
    }

}


sub new {
    my $class = shift;
    my $opt   = shift || {};
    my %opt;

    $opt->{binary} = 1;

    for my $attr ( @Attrs, 'encoding', 'coder_class' ) {
        $opt{ $attr }  = delete $opt->{ $attr } if ( exists $opt->{ $attr } );
    }

    my $self = $class->SUPER::new( $opt ) || return;

    if ( my $coder_class = ( $opt{coder_class} || $DefaultCoderClass ) ) {
        $self->coder_class( $coder_class );
    }
    else {
        Carp::croak "Coder class is not specified.";
    }

    for my $attr ( @Attrs, 'encoding' ) {
        $self->$attr( $opt{ $attr } ) if ( exists $opt{ $attr } );
    }

    $self;
}


#
# Methods
#

sub combine {
    my $self   = shift;
    my @fields = @_;

    $self->coder->decode_fields_ref( $self->encoding, \@fields ) if ( $self->encoding );

    unless ( $self->encoding_out ) {
        return $self->SUPER::combine( @fields );
    }

    my $ret = $self->encode( $self->encoding_out, \@fields );

    $self->{_STRING} = \$ret if ( $ret );

    return $self->{_STATUS};
}


sub parse {
    my $self = shift;
    my $ret;

    if ( $self->encoding_in ) {
        $ret  = $self->decode( $self->encoding_in, $_[0] );
    }
    else {
        $ret = [ $self->fields ] if $self->SUPER::parse( @_ );
    }

    if ( $ret ) {
        $self->coder->encode_fields_ref( $self->encoding, $ret ) if ( $self->encoding );
        $self->{_FIELDS} = $ret;
    }

    return $self->{_STATUS};
}


#
# IO style
#

sub print { # to CSV
    my ( $self, $io, $cols ) = @_;

    $self->coder->decode_fields_ref( $self->encoding,      $cols ) if ( $self->encoding );
    $self->coder->encode_fields_ref( $self->encoding_out,  $cols );

    $self->SUPER::print( $io, $cols );
}


sub getline { # from CSV
    my ( $self, $io ) = @_;
    my $cols = $self->SUPER::getline( $io );

    if ( my $binds = $self->{_BOUND_COLUMNS} ) {
        for my $val ( @$binds ) {
            $$val = $self->coder->decode( $self->encoding_in, $$val );
            $$val = $self->coder->encode( $self->encoding,    $$val ) if ( $self->encoding );
        }
        return $cols;
    }

    return unless $cols;

    $self->coder->decode_fields_ref( $self->encoding_in, $cols );
    $self->coder->encode_fields_ref( $self->encoding,    $cols ) if ( $self->encoding );

    $cols;
}


#
# decode/encode style
#

sub decode {
    my ( $self, $enc, $text ) = @_;

    if ( @_ == 2 ) {
        $text = $enc, $enc = '';
    }

    $self->coder->upgrade( $text ) unless ( $enc ); # as unicode

    return unless ( defined $text );
    return unless ( $self->SUPER::parse( $text ) );

    return $enc ? [ map { $self->coder->decode( $enc, $_ ) } $self->fields() ] : [ $self->fields() ];
}


sub encode {
    my ( $self, $enc, $array ) = @_;

    if ( @_ == 2 ) {
        $array = $enc, $enc = '';
    }

    return unless ( defined $array and ref $array eq 'ARRAY' );
    return unless ( $self->SUPER::combine ( @$array ) );

    return $enc ? $self->coder->encode( $enc, $self->string() ) : $self->string();
}


# Internal

sub _load_coder_class {
    my ( $class, $coder_class ) = @_;
    (my $file = "$coder_class.pm") =~ s{::}{/}g;

    eval { require $file };

    if ( $@ ) {
        Carp::croak $@;
    }

    $coder_class;
}


# Accessors

BEGIN {
    for my $method ( qw( encoding encoding_in encoding_out ) ) {
        eval qq|
            sub $method {
                my ( \$self, \$encoding ) = \@_;
                if ( \@_ > 1 ) {
                    \$self->{ $method } = \$encoding;
                    return \$self;
                }
                else {
                    \$self->{ $method };
                }
            }
        |;
    }
}


*encoding_io_in  = *encoding_to_parse   = *encoding_in;
*encoding_io_out = *encoding_to_combine = *encoding_out;


sub coder {
    my $self = shift;
    $self->{coder} ||= $self->coder_class->new( automatic_UTF8 => $self->automatic_UTF8, @_ );
}


sub coder_class {
    my ( $self, $coder_class ) = @_;

    return $self->{coder_class} if ( @_ == 1 );

    $self->_load_coder_class( $coder_class );
    $self->{coder_class} = $coder_class;
    $self;
}


1;
__END__

=pod

=head1 NAME

Text::CSV::Encoded - Encoding aware Text::CSV.

=head1 VERSION

version 0.25

=head1 SYNOPSIS

    # Here in Perl 5.8 or later
    $csv = Text::CSV::Encoded->new ({
        encoding_in  => "iso-8859-1", # the encoding comes into   Perl
        encoding_out => "cp1252",     # the encoding comes out of Perl
    });

    # parsing CSV is regarded as input
    $csv->parse( $line );      # $line is a iso-8859-1 encoded string
    @columns = $csv->fields(); # they are unicode data

=for readme stop

    # combining list is regarded as output
    $csv->combine(@columns);   # they are unicode data
    $line = $csv->string();    # $line is a cp1252 encoded string

    # if you want for returned @columns to be encoded in $encoding
    #   or want for combining @columns to be assumed in $encoding
    $csv->encoding( $encoding );

    # change input/output encodings
    $csv->encoding_in('shiftjis')->encoding_out('utf8');
    $csv->eol("\n");

    open (my $in,  "sjis.csv");
    open (my $out, "output.csv");

    # change an encoding from shiftjis to utf8

    while( my $columns = $csv->getline( $in ) ) {
        $csv->print( $out, $columns );
    }

    close($in);
    close($out);

    # simple shortcuts
    # (regardless of encoding_in/out and encoding)

    $uni_columns = $csv->decode( 'euc-jp', $line );         # euc-jp => unicode
    $line        = $csv->encode( 'euc-jp', $uni_columns );  # unicode => euc-jp

    # pass check value to coder class
    $csv->coder->encode_check_value( Encode::FB_PERLQQ );

=for readme start

=head1 DESCRIPTION

This module inherits L<Text::CSV> and is aware of input/output encodings.

=begin :readme

=head1 INSTALLATION 

This module sources are hosted on github 
https://github.com/singingfish/Text-CSV-Encoded 
and uses C<Dist::Zilla> to generate the distribution. It can be 
istalled:

=over

=item directly

 cpanm https://github.com/singingfish/Text-CSV-Encoded.git

=item from CPAN

 cpan Text::CSV::Encoded
 cpanm https://github.com/singingfish/Text-CSV-Encoded

=item maualy cloninig the repository:

 git clone https://github.com/singingfish/Text-CSV-Encoded.git
 cd https://github.com/singingfish/Text-CSV-Encoded
 perl Makefile.PL
 make
 make test
 make install

=back

=for readme plugin requires

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=end :readme

=for readme stop

=head1 ENCODINGS

Acceptable names of encodings (C<encoding_in>, C<encoding_out> and C<encoding>)
are depend upon its coder class (see to L</CODER CLASS>). But these names should
be based on L<Encode> supported names. See to L<Encode::Supported> and L<Encode::Alias>.

=head1 METHODS

=head2 new

    $csv = Text::CSV::Encoded->new();

    Text::CSV::Encoded->error_diag unless $csv; # report error message

Creates a new Text::CSV::Encoded object. It can take all options of L<Text::CSV>.
Of course, C<binary> option is always on.

If Text::CSV::Encoded fails in constructing, you can get an error message using C<error_diag>.
See to L<Text::CSV/error_diag>.

The following options are supported by this method:

=over

=item encoding

The encoding of list data in below cases.

  * list data returned by fields() after successful parse().
  * list data consumed by combine().
  * list reference returned by getline().
  * list reference taken by print().

See to L</encoding>.

=item encoding_in

=item encoding_io_in

=item encoding_to_parse

The encoding for pre-parsing CSV strings. See to L</encoding_in>.

C<encoding_io_in> is an alias to C<encoding_in>. If both C<encoding_in>
and C<encoding_io_in> are set at the same time, the C<encoding_in>
takes precedence.

C<encoding_to_parse> is an alias to C<encoding_in>. If both C<encoding_in>
and C<encoding_to_parse> are set at the same time, the C<encoding_in>
takes precedence.

=item encoding_out

=item encoding_io_out

=item encoding_to_combine

The encoding for combined CSV strings. See to L</encoding_out>.

C<encoding_io_out> is an alias to C<encoding_out>. If both C<encoding_out>
and C<encoding_io_out> are set at the same time, the C<encoding_out>
takes precedence.

C<encoding_to_combine> is an alias to C<encoding_out>. If both C<encoding_out>
and C<encoding_io_out> are set at the same time, the C<encoding_out>
takes precedence.

=item coder_class

A name of coder class that really decodes and encodes data.

=back

=head2 encoding_in

    $csv = $csv->encoding_in( $encoding );

The accessor to an encoding for pre-parsing CSV strings.
If no encoding is given, returns current C<$encoding>, otherwise the object itself.

    $encoding = $csv->encoding_in()

In C<parse> or C<getline>, the C<$csv> will assume CSV data as the given
encoding. If C<encoding_in> is not specified or is set with false value (L<undef>),
it will assume input CSV strings as Unicode (not UTF-8) when L<Text::CSV::Encoded::Coder::Encode> is used.

    $csv->encoding_in( undef );
    # assume as Unicode when Text::CSV::Encoded::Coder::Encode is used.

If you pass a list reference that contains multiple encodings to the method,
the working are depend upon the coder class.
For example, if you use the coder class with L<Text::CSV::Encoded::Coder::EncodeGuess>,
it might guess the encoding from the given list.

    $csv->coder_class( 'Text::CSV::Encoded::Coder::EncodeGuess' );
    $csv->encoding_in( ['shiftjis', 'euc-jp', 'iso-20022-jp'] );

See to L</Coder Class> and L<Text::CSV::Encoded::Coder::EncodeGuess>.

=head2 encoding_out

    $csv = $csv->encoding_out( $encoding );

The accessor to an encoding for converting combined CSV strings.
If no encoding is given, returns current C<$encoding>, otherwise the object itself.

    $encoding = $csv->encoding_out();

In C<combine> or C<print>, the C<$csv> will return a result string encoded in the
given encoding. If C<encoding_out> is not specified or is set with false value,
it will return a result string as Unicode (not UTF-8).

    $csv->encoding_out( undef );
    # return as Unicode when Text::CSV::Encoded::Coder::Encode is used.

You must not pass a list reference to C<encoding_out>, unlike C<encoding_in> or C<encoding>.

=head2 encoding

    $csv = $csv->encoding( $encoding );
    $encoding = $csv->encoding();

The accessor to an encoding for list data in the below cases.

  * list data returned by fields() after successful parse().
  * list data consumed by combine().
  * list reference returned by getline().
  * list reference taken by print().

In other word, in C<parse> and C<getline>, C<encoding> is an encoding of the returned list.
And in C<combine> and C<print>, it is assumed as an encoding for the passing list data.

If C<encoding> is not specified or is set with false value (C<undef>),
the field data will be regarded as Unicode (when L<Text::CSV::Encoded::Coder::Encode> is used).

    # ex.) a souce code is encoded in euc-jp, and print to stdout in shiftjis.
    @fields = ( .... );
    $csv->encoding('euc-jp')
        ->encoding_to_combine('shiftjis') # same as encoding_out
        ->combine( @fields ); # from euc-jp to shift_jis

    print $csv->string;

    $csv->encoding('shiftjis')
        ->encoding_to_parse('shiftjis') # same as encoding_in
        ->parse( $csv->string ); # from shift_jis to shift_jis

    print join(", ", $csv->fields );

If you pass a list reference contains multiple encodings to the method,
The working are depend upon the coder class. For example,
L<Text::CSV::Encoded::EncodeGuess> might guess the encoding from the given list.

    $csv->coder_class( 'Text::CSV::Encoded::Coder::EncodeGuess' );
    $csv->encoding( ['ascii', 'ucs2'] )->combine( @cols );

See to L</Coder Class> and L<Text::CSV::Encoded::Coder::EncodeGuess>.

=head2 parse/combine/getline/print

    $csv->parse( $encoded_string );
    @unicode_array = $csv->fields();

    $csv->combine( @unicode_array );
    $encoded_string = $csv->string;

    $unicode_arrayref = $csv->getline( $io );
    # get arrayref contains unicode strings
    $csv->print( $io, $unicode_arrayref );
    # print $io with string encoded in $csv->encoded_in.

    $encoded_arrayref = $csv->getline( $io => $encoding )
    # directly encoded in $encoding.

Here is the relation of C<encoding_in>, C<encoding_out> and C<encoding>.

    # CSV string        =>  (getline/parsed)  =>     Perl array
    #           assumed as                  encoded in
    #                encoding_in                encoding


    # Perl array        =>  (print/combined)  =>     CSV string
    #           assumed as                  encoded in
    #               encoding                    encoding_out

If you want to treat Perl array data as Unicode in Perl5.8 and later,
don't specify C<encoding> (or set C<undef> into C<encoding>).

=head2 decode

    $arrayref = $csv->decode( $encoding, $encoded_string );

    $arrayref = $csv->decode( $string );

A short cut method to convert CSV to Perl.
Without C<$encoding>, C<$string> is assumed as a Unicode.

The returned value status is depend upon its coder class.
With L<Text::CSV::Encoded::Coder::Encode>, C<$arrayref> contains Unicode strings.

=head2 encode

    $encoded_string = $csv->encode( $encoding, $arrayref );

    $string = $csv->encode( $arrayref );

A short cut method to convert Perl to CSV.
With L<Text::CSV::Encoded::Coder::Encode>, C<$arrayref> is assumed to contain Unicode strings.

Without C<$encoding>, return as is.

=head2 coder_class

    $csv = $csv->coder_class( $classname );
    $classname = $csv->coder_class();

Returns the coder class name. See to L</CODER CLASS>.

=head2 coder

    $coder = $csv->coder();

Returns a coder object.

=head2 automtic_UTF8

In L<Text::CSV_XS> version 0.99 and L<Text::CSV_PP> version 1.30 or later,
They return UNICODE stinrgs in case of parsing utf8 encoded text.
Backend module has that feature, automatic_UTF8 returns true.
(This method is for internal code.)

=head1 CODER CLASS

Text::CSV::Encoded delegates the encoding converting process to another module.
Since version 5.8, Perl standardly has L<Encode> module. So the default coder
module L<Text::CSV::Encoded::Coder::Encode> also uses it. In this case,
you don't have to take care of it.

In older Perl, the default is L<Text::CSV::Encoded::Coder::Base>. It does nothing.
So you have to make a coder module using your favorite converting module, for example,
L<Unicode::String> or L<Jcode> and so on.

Please check L<Text::CSV::Encoded::Coder::Base> and L<Text::CSV::Encoded::Coder::Encode>
to make such a module.

In calling L<Text::CSV::Encoded>, you can set another coder module with C<coder_class>;

  use Text::CSV::Encoded coder_class => 'YourCoder';

This will call C<YourCoder> module in runtime.

=head2 Use Encode module

Perl 5.8 or later, L<Text::CSV::Encoded> use L<Text::CSV::Encoded::Coder::Encode>
as its backend engine. You can set C<encoding_in>, C<encoding_out> and C<encoding>
with L<Encode> supported encodings. See to L<Encode::Supported> and L<Encode::Alias>.

Without C<encoding> (or set C<undef>), C<parse>/C<getline>/C<getline_hr> return
list data whose entries are C<Unicode> strings.
On the contrary, C<combine>/C<print> take data as C<Unicode> string list.

About the extra methods C<decode> and C<encode>. C<decode> returns C<Unicode> string list
and C<encode> takes C<Unicode> string list. But If no C<$encoding> is passed to C<encode>,
it returns a non-Unicode CSV string for non-Unicode list data.

=head2 Use Encode::Guess module

If you don't know definitely input CSV data encoding (for parse/getline),
L<Text::CSV::Encoded::Coder::EncodeGuess> may be useful to you.
It inherits from L<Text::CSV::Encoded::Coder::Encode>, so you can treate methods and
attributes as same as L<Text::CSV::Encoded::Coder::Encode>. And it provides a guessing
fucntion with L<Encode::Guess>.

When it is backend coder class, C<encoding_in> and C<encoding> can take a encoding list reference,
and then it might guess the encoding from the given list.

    $csv->encoding_in( ['shiftjis', 'euc-jp'] )->parse( $sjis_or_eucjp_encoded_csv_string );

It is important to remember the guessing feature is not always successful.

Or, the method can be applied to C<encoding>.
For exmaple, you want to convert data from Microsoft Excel to CSV.

    use Text::CSV::Encoded  coder_class => 'Text::CSV::Encoded::Coder::EncodeGuess';
    use Spreadsheet::ParseExcel;

    my $csv = Text::CSV::Encoded->new( eol => "\n" );
    $csv->encoding( ['ucs2', 'ascii'] ); # guessing ucs2 or ascii?
    $csv->encoding_out('shiftjis'); # print in shift_jis

    my $excel = Spreadsheet::ParseExcel::Workbook->Parse( $file );
    my $sheet = $excel->{Worksheet}->[0];

    for my $row ( $sheet->{MinRow} .. $sheet->{MaxRow} ) {
        my @fields;
        for my $col ( $sheet->{MinCol} ..  $sheet->{MaxCol} ) {
            my $cell = $sheet->{Cells}[$row][$col];
            push @fields, $cell->{Val};
        }
        $csv->print( \@fields );
    }

In this case, guessing for list data.
After combining, you may have a need to clear C<encoding>.
Again remember that the feature is not always successful.

In addtion, Microsoft Excel data converting is a carefult thing.
See to L<Text::CSV_XS/CAVEATS>.

=head2 Use XXX module

Someone might make a new coder module in older version Perl...
There is an example with L<Jcode> in L<Text::CSV::Encoded::Coder::Base> document.

=head1 TODO

=over

=item More sophisticated tests - Welcome!

=item Speed

=back

=head1 SEE ALSO

L<Text::CSV>, L<Text::CSV_XS>, L<Encode>, L<Encode::Guess>, L<utf8>,
L<Text::CSV::Encoded::Coder::Base>,
L<Text::CSV::Encoded::Coder::Encode>,
L<Text::CSV::Encoded::Coder::EncodeGuess>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

The basic idea for this module and suggestions were given by H.Merijn Brand.
He and Juerd advised me many points about documents and sources.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2013 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
