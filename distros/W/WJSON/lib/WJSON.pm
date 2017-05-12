package WJSON;

use Moose;
use JSON;
use Encode;
use Tie::IxHash;
no warnings 'uninitialized';

our $VERSION = '0.08';

has 'json' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
        []
    }
);

has 'reference' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {
        {}
    }
);

has 'tmp' => (
    is => 'rw',
    isa => 'Str'
);

has 'encoding' => (
    is => 'rw',
    isa => 'Str',
    default => 'utf-8'
);

has 'variable' => (
    is => 'rw',
    isa => 'Str'
);

has 'ordering' => (
    is => 'rw',
    isa => 'Str',
    default => 0
);

sub Open {
    my ($self, $value) = @_;
    
    if ($value) {
        if($self->tmp){
            my $tmp = $self->tmp;
            unless (scalar(@{$self->reference->{$self->tmp}})) {
                my %hash;
                tie %hash, 'Tie::IxHash' if $self->ordering;
                $self->Object(\%hash);
            }
            $tmp .= '/' . $value;
            $self->tmp($tmp);
        }else{
            $self->tmp('/' . $value);
        }
        $self->reference->{$self->tmp} = [];
    }
}

sub Close {
    my ($self, $type) = @_;
    
    my $tmp = $self->tmp;
    $tmp =~ m!/([\w]*?)$!s;
    my $key = $1;
    $tmp =~ s/\/[\w]*?$//;
    $self->tmp($tmp);
    if ($self->tmp) {
        my $total = @{$self->reference->{$self->tmp}} || 1;
        if (scalar(@{$self->reference->{$tmp.'/'.$key}}) == 1) {
            my $result = $self->reference->{$tmp.'/'.$key}[0];
            if (ref($self->reference->{$self->tmp}[$total - 1]) eq 'HASH') {
                if ($type == 1) {
                    push(@{$self->reference->{$self->tmp}}, {$key => $result});
                }elsif($type == 2) {
                    $self->reference->{$self->tmp}[$total - 1]{$key} = [$result];
                }elsif($type == 3) {
                    push(@{$self->reference->{$self->tmp}}, {$key => [$result]});
                }else{
                    $self->reference->{$self->tmp}[$total - 1]{$key} = $result;
                }
            }else{
                my $t = 1;
                if ($self->reference->{$self->tmp}[$total - 1]) {
                    $t = scalar(@{$self->reference->{$self->tmp}[$total - 1]}) || 1;
                }
                if ($type == 1) {
                    push(@{$self->reference->{$self->tmp}[$total - 1]}, {$key => $result});
                }elsif($type == 2) {
                    $self->reference->{$self->tmp}[$total - 1][$t - 1]{$key} = [$result];
                }elsif($type == 3) {
                    push(@{$self->reference->{$self->tmp}[$total - 1]}, {$key => [$result]});
                }else{
                    if ($self->reference->{$self->tmp}[$total - 1][$t - 1]) {
                        $self->reference->{$self->tmp}[$total - 1][$t]{$key} = $result;
                    }else{
                        $self->reference->{$self->tmp}[$total - 1][$t - 1]{$key} = $result;
                    }
                }
            }
        }else{
            my $result = $self->reference->{$tmp.'/'.$key};
            $result = [$result] if scalar(@{$result}) <= 1 && $type =~ /(2|3)/;
            if (ref($self->reference->{$self->tmp}[$total - 1]) eq 'HASH') {
                if ($type == 1) {
                    push(@{$self->reference->{$self->tmp}}, {$key => $result});
                }elsif($type == 2) {
                    $self->reference->{$self->tmp}[$total - 1]{$key} = $result;
                }elsif($type == 3) {
                    push(@{$self->reference->{$self->tmp}}, {$key => $result});
                }else{
                    $self->reference->{$self->tmp}[$total - 1]{$key} = $result;
                }
            }else{
                my $t = 1;
                if ($self->reference->{$self->tmp}[$total - 1]) {
                    $t = scalar(@{$self->reference->{$self->tmp}[$total - 1]}) || 1;
                }
                if ($type == 1) {
                    push(@{$self->reference->{$self->tmp}[$total - 1]}, {$key => $result});
                }elsif($type == 2) {
                    $self->reference->{$self->tmp}[$total - 1][$t - 1]{$key} = $result;
                }elsif($type == 3) {
                    push(@{$self->reference->{$self->tmp}[$total - 1]}, {$key => $result});
                }else{
                    $self->reference->{$self->tmp}[$total - 1][$t - 1]{$key} = $result;
                }
            }
        }
    }else{
        my $total = scalar(@{$self->json}) || 1;
        if (scalar(@{$self->reference->{$tmp.'/'.$key}}) == 1) {
            my $result = $self->reference->{$tmp.'/'.$key}[0];
            if (ref($self->json->[$total - 1]) eq 'HASH') {
                if ($type == 1) {
                    push(@{$self->json}, {$key => $result});
                }elsif($type == 2) {
                    $self->json->[$total - 1]{$key} = [$result];
                }elsif($type == 3) {
                    push(@{$self->json}, {$key => [$result]});
                }else{
                    $self->json->[$total - 1]{$key} = $result;
                }
            }else{
                my $t = 1;
                if ($self->json->[$total - 1]) {
                    $t = scalar(@{$self->json->[$total - 1]}) || 1;
                }
                if ($type == 1) {
                    push(@{$self->json->[$total - 1]}, {$key => $result});
                }elsif($type == 2) {
                    $self->json->[$total - 1][$t - 1]{$key} = [$result];
                }elsif($type == 3) {
                    push(@{$self->json->[$total - 1]}, {$key => [$result]});
                }else{
                    $self->json->[$total - 1][$t - 1]{$key} = $result;
                }
            }
        }else{
            my $result = $self->reference->{$tmp.'/'.$key};
            $result = [$result] if scalar(@{$result}) <= 1 && $type =~ /(2|3)/;
            if (ref($self->json->[$total - 1]) eq 'HASH') {
                if ($type == 1) {
                    push(@{$self->json}, {$key => $result});
                }elsif($type == 2) {
                    $self->json->[$total - 1]{$key} = $result;
                }elsif($type == 3) {
                    $result = [$result] if scalar(@{$result}) <= 1;
                    push(@{$self->json}, {$key => $result});
                }else{
                    $self->json->[$total - 1]{$key} = $result;
                }
            }else{
                my $t = 1;
                if ($self->json->[$total - 1]) {
                    $t = scalar(@{$self->json->[$total - 1]}) || 1;
                }
                if ($type == 1) {
                    push(@{$self->json}, {$key => $result});
                 }elsif($type == 2) {
                    $self->json->[$total - 1]{$key} = $result;
                }elsif($type == 3) {
                    push(@{$self->json}, {$key => $result});
                }else{
                    $self->json->[$total - 1]{$key} = $result;
                }
            }
        }
    }
    delete($self->reference->{$tmp.'/'.$key});
}

sub Array {
    my ($self, @values) = @_;
    
    if ($self->tmp) {
        push(@{$self->reference->{$self->tmp}}, [@values]);   
    }else{
        push(@{$self->json}, [@values]); 
    }
}

sub Object {
    my ($self, @values) = @_;
    
    if (ref($values[0]) eq 'HASH') {
        $self->HashObject(@values);
    }else{
        if (ref($self->reference->{$self->tmp}[0]) eq 'ARRAY') {
            my %hash;
            tie %hash, 'Tie::IxHash' if $self->ordering;
            %hash = \@values;
            push(@{$self->reference->{$self->tmp}[0]}, \%hash);   
        }else{
            if ($self->tmp) {
                my %hash;
                tie %hash, 'Tie::IxHash' if $self->ordering;
                %hash = @values;
                push(@{$self->reference->{$self->tmp}}, \%hash);   
            }else{
                my %hash;
                tie %hash, 'Tie::IxHash' if $self->ordering;
                if (ref(\@values) eq 'ARRAY') {
                    my $n = 0;
                    $n % 2 == 0 ? $hash{$values[$n]} = $values[$n+1] : undef, $n++ for (@values);
                    push(@{$self->json}, \%hash); 
                }else{
                    %hash = \@values;
                    push(@{$self->json}, \%hash);
                }
            }
        }
    }
}

sub HashObject {
    my ($self, @values) = @_;
    unless (ref($values[0]) eq 'HASH') {
        $self->Object(@values);
    }else{
        foreach my $row (@values){
            if ($self->reference->{$self->tmp}[0]) {
                if (ref($self->reference->{$self->tmp}[0]) eq 'ARRAY') {
                    push(@{$self->reference->{$self->tmp}[0]}, $row);
                }else{
                    push(@{$self->reference->{$self->tmp}}, $row);
                }
            }else{
                if ($self->tmp) {
                    push(@{$self->reference->{$self->tmp}}, $row);   
                }else{
                    push(@{$self->json}, $row); 
                }
            }
        }
    }
}

sub Header {
    return "application/json";
}

sub HeaderJS {
    return "application/javascript";
}

sub HeaderCGI {
    return "Content-type: application/json\n\n";
}

sub HeaderJSCGI {
    return "Content-type: application/javascript\n\n";
}


sub Print {
    my ($self, $type) = @_;
    
    my $result = undef;
    if (scalar(@{$self->json}) <= 1) {
        if (ref($self->json->[0]) eq 'ARRAY') {
            if (scalar(@{$self->json->[0]}) <= 1) {
                $result = ${$self->json}[0][0];
            }else{
                $result = ${$self->json}[0];
            }
        }else{
            $result = ${$self->json}[0];
        }
    }else{
        $result = $self->json;
    }
    
    $result = [$result] if $type;
    
    if ($self->variable) {
        return 'var ' . $self->variable . ' = ' . encode $self->encoding, JSON->new->encode($result) . ';';
    }else{
        return  $result ? encode $self->encoding, JSON->new->encode($result) : '';
    }
}

1;

__END__

=encoding utf8

=head1 NAME

WJSON - Write JSON with simplicities

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

    use WJSON;
    
    my $json = new WJSON;
    $json->Object(
        key_1 => 'value_1',
        key_2 => 'value_2',
        key_3 => 'value_3',
    );
    print $json->Print;
    
=head1 ATTRIBUTES

=head2 encoding

    set encoding, default utf-8
    
=cut

=head2 variable

    set variable and return var variable = {}
    
=cut

=head2 ordering

    set ordering with 1 or true and return json order by position
    
=cut

=head1 METHODS

=head2 Open

    Open object or array
    
=cut
    
=head2 Close

    Close object or array, set 1 to separates of reference, set 2 to add value within of array,
    set 3 is 1 and 2 together

=cut

=head2 Object

    Create object with prototyped set of key/value (properties)

=cut

=head2 HashObject

    Create hash object with prototyped set of {key/value} (properties)

=cut

=head2 Array

    Create array, set of value

=cut

=head2 Header

    Return "application/json"
    
=head2 HeaderJS

    Return "application/javascript"
    
=head2 HeaderCGI

    Return "Content-type: application/json\n\n";
    
=head2 HeaderJSCGI

    Return "Content-type: application/javascript\n\n";

=cut

=head2 Print

    Print JSON

=cut

=head1 EXAMPLES

=head2 Example 1

    my $json = new WJSON(encoding => 'iso-8859-1');
    $json->Array('value_1', 'value_2', 'value_3');
    print $json->Print;
    
Result JSON

    ["value_1", "value_2", "value_3"]
    
=cut

=head2 Example 2

    my $json = new WJSON;
    $json->encoding('iso-8859-1');
    $json->Object(
        key_1 => 'value_1',
        key_2 => 'value_2',
        key_3 => 'value_3',
    );
    print $json->Print;
    
Result JSON

    {
        "key_3": "value_3",
        "key_1": "value_1",
        "key_2": "value_2"
    }
    
=cut

=head2 Example 3

    my $json = new WJSON;
    $json->HashObject(
        {
            key_1 => 'value_1',
            key_2 => 'value_2',
            key_3 => 'value_3',
        }
    );
    print $json->Print;
    
Result JSON

    {
        "key_3": "value_3",
        "key_1": "value_1",
        "key_2": "value_2"
    }
    
=cut

=head2 Example 4

    my $json = new WJSON;
    $json->Open('Data');
        $json->Object(
            key_1 => 'value_1',
            key_2 => 'value_2',
            key_3 => 'value_3',
        );
    $json->Close;
    print $json->Print;
    
Result JSON

    {
        "Data": {
            "key_3": "value_3",
            "key_1": "value_1",
            "key_2": "value_2"
        }
    }
    
=cut

=head2 Example 5

    my $json = new WJSON;
    $json->Open('Data');
        $json->Object(
            key_1 => 'value_1',
            key_2 => 'value_2',
            key_3 => 'value_3',
        );
        $json->Object(
            key_1 => 'value_1',
            key_2 => 'value_2',
            key_3 => 'value_3',
        );
    $json->Close;
    print $json->Print;
    
Result JSON

    {
        "Data": [{
            "key_3": "value_3",
            "key_1": "value_1",
            "key_2": "value_2"
        }, {
            "key_3": "value_3",
            "key_1": "value_1",
  ut          "key_2": "value_2"
        }]
    }
    
=cut

=head2 Example 6

    my $json = new WJSON;
    $json->Open('Data');
        $json->Array('value_1', 'value_2', 'value_3');
    $json->Close;
    print $json->Print;
    
Result JSON

    {
        "Data": ["value_1", "value_2", "value_3"]
    }
    
=cut

=head2 Example 7

    my $json = new WJSON;
    $json->Object(
        key_1 => 'value_1',
        key_2 => 'value_2',
        key_3 => 'value_3',
    );
    $json->Object(
        key_1 => 'value_1',
        key_2 => 'value_2',
        key_3 => 'value_3',
    );
    $json->Open('Data');
        $json->Open('SubData');
            $json->Object(
                key_1 => 'value_1',
                key_2 => 'value_2',
                key_3 => 'value_3',
            );
            $json->Object(
                key_1 => 'value_1',
                key_2 => 'value_2',
                key_3 => 'value_3',
            );
        $json->Close;
        $json->Array(['value_1', 'value_2', 'value_3'], ['value_4', 'value_5']);
        $json->Array(['value_6', 'value_7']);
    $json->Close;
    $json->Array(['value_1', 'value_2', 'value_3'], ['value_4', 'value_5']);
    print $json->Print;
    
Result JSON

    [{
            "key_3": "value_3",
            "key_1": "value_1",
            "key_2": "value_2"
        }, {
            "key_3": "value_3",
            "key_1": "value_1",
            "key_2": "value_2",
            "Data": [{
                    "SubData": [{
                        "key_3": "value_3",
                        "key_1": "value_1",
                        "key_2": "value_2"
                    }, {
                        "key_3": "value_3",
                        "key_1": "value_1",
                        "key_2": "value_2"
                    }]
                },
                ["value_1", "value_2", "value_3"],
                ["value_4", "value_5"], "value_6", "value_7"
            ]
        },
        ["value_1", "value_2", "value_3"],
        ["value_4", "value_5"]
    ]
    
=cut

=head2 Example 8

    my $json = new WJSON;
    $json->variable('json');
    $json->Object(
        key_1 => 'Formulário',
        key_2 => 'value_2',
        key_3 => 'value_3',
    );
    print $json->Print;
    
Result JSON

    var json = {
        "key_3": "value_3",
        "key_1": "Formulário",
        "key_2": "value_2"
    };

=cut

=head2 Example 9

    my $json = new WJSON;
    $json->Open('glossary');
        $json->Object(
            title => 'example glossary'
        );
        $json->Open('GlossDiv');
            $json->Object(
                title => 'S'
            );
            $json->Open('GlossList');
                $json->Object(
                    GlossSee => 'markup'
                );
                $json->Open('GlossEntry');
                    $json->Object(
                        ID => 'SGML',
                        SortAs => 'SGML',
                        GlossTerm => 'Standard Generalized Markup Language',
                        Acronym => 'SGML',
                        Abbrev => 'ISO 8879:1986',
                    );
                    $json->Open('GlossDef');
                        $json->Object(
                            para => 'A meta-markup language, used to create markup languages such as DocBook.'
                        );
                        $json->Open('GlossSeeAlso');
                            $json->Array('GML', 'XML');
                        $json->Close;
                    $json->Close;
                $json->Close;
            $json->Close;
        $json->Close;
    $json->Close;
    print $json->HeaderCGI;
    print $json->Print;
    
Result JSON

    {
        "glossary": {
            "GlossDiv": {
                "GlossList": {
                    "GlossEntry": {
                        "GlossDef": {
                            "para": "A meta-markup language, used to create markup languages such as DocBook.",
                            "GlossSeeAlso": ["GML", "XML"]
                        },
                        "GlossTerm": "Standard Generalized Markup Language",
                        "ID": "SGML",
                        "SortAs": "SGML",
                        "Acronym": "SGML",
                        "Abbrev": "ISO 8879:1986"
                    },
                    "GlossSee": "markup"
                },
                "title": "S"
            },
            "title": "example glossary"
        }
    }
    
=cut
    
=head2 Example 10
    
    my $json = new WJSON;
    $json->Open('menu');
        $json->Object(
            id => 'file',
            value => 'File',
        );
        $json->Open('popup');
            $json->Open('menuitem');
                $json->Object(
                    {
                        value => 'New',
                        onclick => 'CreateNewDoc()'
                    },
                    {
                        value => 'Open',
                        onclick => 'OpenDoc()'
                    },
                    {
                        value => 'Close',
                        onclick => 'CloseDoc()'
                    }
                );
            $json->Close;
        $json->Close;
    $json->Close;
    print $json->HeaderCGI;
    print $json->Print;
    
Result JSON

    {
        "menu": {
            "value": "File",
            "popup": {
                "menuitem": [{
                    "value": "New",
                    "onclick": "CreateNewDoc()"
                }, {
                    "value": "Open",
                    "onclick": "OpenDoc()"
                }, {
                    "value": "Close",
                    "onclick": "CloseDoc()"
                }]
            },
            "id": "file"
        }
    }

=cut

=head1 AUTHOR

Lucas Tiago de Moraes, C<< <lucastiagodemoraes@gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WJSON

You can also look for information at:

=head2 Github

L<https://github.com/lucas1/WJSON>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Lucas Tiago de Moraes.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut