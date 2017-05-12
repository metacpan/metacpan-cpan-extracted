package HTML::HTPL::CSV;

use HTML::HTPL::Result;
use Text::ParseWords;
use HTML::HTPL::Txt;
use strict;
use vars qw(@ISA);
use Symbol;

@ISA = qw(HTML::HTPL::Txt);

sub parse ($$) {
    my ($delim, $line) = @_;
    if ($delim eq 'BLANK') {
        return split(/\s+/, $line);
    }
    parse_line($delim, undef, $line);
}
 
sub opencsv {
    my ($filename, $delimiter, @fields) = @_;

    my ($phrase, @values);

    my ($rowdel, $coldel, $savedel);
    $rowdel = "\n";

    if (UNIVERSAL::isa($delimiter, 'ARRAY')) {
        ($coldel, $rowdel) = @$delimiter;
        $delimiter = $coldel;
    }

    $delimiter ||= ',';
    $delimiter =~ s/^'(.*)'$/$1/;
    $delimiter = quotemeta($delimiter);

    my $hnd = &gensym;

    my $savedel = $/;
    $/ = $rowdel;
 
    &HTML::HTPL::Lib'opendoc($hnd, $filename);

    unless (@fields) {
        my $header = <$hnd>;
        chop $header;
        @fields = &parse($delimiter, $header);
    }

    $/ = $savedel;

    my $orig = new HTML::HTPL::CSV($hnd, $delimiter, $rowdel);
    my $result = new HTML::HTPL::Result($orig, @fields);


    $result;
}

sub readln {
    my ($self, $line) = @_;
    my $delimiter = $self->{'delimiter'};
    my @values = &parse($delimiter, $line);
    \@values;
}

sub new {
    my ($class, $hnd, $delimiter, $linedel) = @_;
    my $self = $class->SUPER::new($hnd, $linedel);
    $self->{'delimiter'} = $delimiter;
    $self;
}

1;
