package HTML::HTPL::Flat;

use HTML::HTPL::Result;
use Text::ParseWords;
use HTML::HTPL::Txt;
use HTML::HTPL::Lib;
use Symbol;
use strict;
use vars qw(@ISA);

@ISA = qw(HTML::HTPL::Txt);

sub openflat {
    my ($filename, @fields) = @_;

    my ($phrase, @values);

    $hnd = &gensym;

    my $savedel = $/;
 
    &HTML::HTPL::Lib'opendoc($hnd, $filename);

    my $orig = new HTML::HTPL::Flat($hnd, \@fields, "");
    my $result = new HTML::HTPL::Result($orig, @fields);

    $result;
}

sub readln {
    my ($self, $line) = @_;
    my @values = split(/\r?\n/, $line);
    \@values;
}

1;
