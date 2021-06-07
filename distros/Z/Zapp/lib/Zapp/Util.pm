package Zapp::Util;
# ABSTRACT: General utilities for Zapp

use Mojo::Base 'Exporter', -signatures;
use Text::Balanced qw( extract_delimited );
our @EXPORT_OK = qw(
    build_data_from_params get_path_from_schema get_slot_from_data
    get_path_from_data prefix_field rename_field parse_zapp_attrs
    ansi_colorize
);

#pod =sub build_data_from_params
#pod
#pod Build a data structure from the parameters in the given request,
#pod optionally with the given prefix. Parameter names are paths in the
#pod resulting data structure.
#pod
#pod     # ?name.first=Turanga&name.last=Leela
#pod     { name => { first => 'Turanga', last => 'Leela' } }
#pod
#pod     # ?crew[0]=Fry&crew[1]=Leela&crew[2]=Zoidberg%20Why%20Not
#pod     { crew => [ 'Fry', 'Leela', 'Zoidberg Why Not' ] }
#pod
#pod     # ?[0].name=Hubert&[0].age=160&[1].name=Cubert&[1].age=12
#pod     [ { name => 'Hubert', age => 160 }, { name => 'Cubert', age => 12 } ]
#pod
#pod =cut

sub build_data_from_params( $c, $prefix='' ) {
    my $data = '';
    # XXX: Move to Yancy (Util? Controller?)
    my $dot = $prefix ? '.' : '';
    my @params = grep /^$prefix(?:\[\d+\]|\Q$dot\E\w+)/, $c->req->params->names->@*;
    for my $param ( @params ) {
        my $value = $c->param( $param );
        my $path = $param =~ s/^$prefix//r;
        my $slot = get_slot_from_data( $path, \$data );
        $$slot = $value;
    }
    my @uploads = grep $_->name =~ /^$prefix(?:\[\d+\]|\.\w+)/, $c->req->uploads->@*;
    for my $upload ( @uploads ) {
        my $path = $upload->name =~ s/^$prefix//r;
        my $slot = get_slot_from_data( $path, \$data );
        $$slot = $upload;
    }
    return $data ne '' ? $data : undef;
}

#pod =sub get_slot_from_data
#pod
#pod Get a reference to the given path in the given data. Can be used to set values
#pod at paths.
#pod
#pod =cut

sub get_slot_from_data( $path, $data ) {
    my $slot = $data;
    for my $part ( $path =~ m{((?:\w+|\[\d+\]))(?=\.|\[|$)}g ) {
        if ( $part =~ /^\[(\d+)\]$/ ) {
            my $part_i = $1;
            if ( !ref $$slot ) {
                $$slot = [];
            }
            $slot = \( $$slot->[ $part_i ] );
            next;
        }
        else {
            if ( !ref $$slot ) {
                $$slot = {};
            }
            $slot = \( $$slot->{ $part } );
        }
    }
    return $slot;
}

#pod =sub get_path_from_data
#pod
#pod Get the value for a given path out of the given data.
#pod
#pod =cut

sub get_path_from_data( $path, $data ) {
    my $slot = get_slot_from_data( $path, \$data );
    return $$slot;
}

#pod =sub get_path_from_schema
#pod
#pod Get the schema for a given path out of the given JSON Schema. Will traverse
#pod object C<properties> and array C<items> to find the schema.
#pod
#pod =cut

sub get_path_from_schema( $path, $schema ) {
    my $slot = $schema;
    for my $part ( $path =~ m{((?:\w+|\[\d*\]))(?=\.|\[|$)}g ) {
        if ( $part =~ /^\[\d*\]$/ ) {
            $slot = $slot->{ items };
            next;
        }
        else {
            $slot = $slot->{ properties }{ $part };
        }
    }
    return $slot;
}

#pod =sub prefix_field
#pod
#pod Add a prefix to any field in the given HTML or L<Mojo::DOM> object.
#pod Prefixes are added to the C<name> and C<id> attributes of any form inputs, and
#pod the C<for> attribute of any labels.
#pod
#pod =cut

sub prefix_field( $dom, $prefix ) {
    if ( ref $dom ne 'Mojo::DOM' ) {
        $dom = Mojo::DOM->new( $dom );
    }

    $dom->find( 'input,select,textarea' )->each(
        sub {
            my ( $el ) = @_;
            my $name = $el->attr( 'name' );
            my $joiner = $name =~ /^\[/ ? '' : '.';
            $el->attr( name => join $joiner, $prefix, $name );
            $el->attr( id => $el->attr( 'name' ) );
        },
    );
    $dom->find( 'label' )->each(
        sub {
            my ( $el ) = @_;
            my $for = $el->attr( 'for' );
            my $joiner = $for =~ /^\[/ ? '' : '.';
            $el->attr( for => join $joiner, $prefix, $for );
        },
    );

    return $dom;
}

#pod =sub rename_field
#pod
#pod Rename any form fields in the given HTML or L<Mojo::DOM> object using
#pod the provided mapping. This changes the field C<name> and C<id>
#pod attributes, and also the corresponding label C<for> attribute.
#pod
#pod =cut

sub rename_field( $dom, %map ) {
    if ( ref $dom ne 'Mojo::DOM' ) {
        $dom = Mojo::DOM->new( $dom );
    }

    $dom->find( 'input,select,textarea' )->each(
        sub {
            my ( $el ) = @_;
            my $name = $el->attr( 'name' );
            $el->attr( name => $name =~ s{$name}{$map{ $name } // $name}er );
            $el->attr( id => $el->attr( 'name' ) );
        },
    );
    $dom->find( 'label' )->each(
        sub {
            my ( $el ) = @_;
            my $for = $el->attr( 'for' );
            $el->attr( for => $for =~ s{$for}{$map{ $for } // $for}re );
        },
    );

    return $dom;
}

#pod =sub parse_zapp_attrs
#pod
#pod Parse special C<data-zapp> attributes in the given HTML or L<Mojo::DOM> object.
#pod These attributes add dynamic features to templates for L<Zapp::Task>, L<Zapp::Type>,
#pod or L<Zapp::Trigger>.
#pod
#pod =over
#pod
#pod =item data-zapp-if="<expression>"
#pod
#pod Display this element if the given C<< <expression> >> is true. The expression can
#pod contain string literals, data paths, and the following operators:
#pod
#pod     == != >  <  >= <=
#pod     eq ne gt lt ge le
#pod
#pod If the expression is true, the element is given the C<zapp-visible> class and
#pod will appear. Expressions are evaluated in Perl when rendering the template and
#pod in JavaScript when the user is modifying the form.
#pod
#pod =cut

# XXX: Add data-zapp-array here

sub parse_zapp_attrs( $dom, $data ) {
    if ( ref $dom ne 'Mojo::DOM' ) {
        $dom = Mojo::DOM->new( $dom );
    }

    $dom->find( '[data-zapp-if]' )->each(
        sub {
            my ( $el ) = @_;
            my ( $lhs, $op, $rhs ) = split /\s*(==|!=|>|<|>=|<=|eq|ne|gt|lt|ge|le)\s*/, $el->attr( 'data-zapp-if' ), 3;
            #; say "Expr: " . $el->attr( 'data-zapp-if' );
            #; say "LHS: $lhs; OP: $op; RHS: $rhs";
            if ( !$op ) {
                # Boolean LHS
                my ( $false, $path ) = $lhs =~ /^(!)?\s*(\S+)/;
                my $value = get_path_from_data( $path, $data );
                if ( ( !$false && $value ) || ( $false && !$value ) ) {
                    #; say "False: $false; Value: $value";
                    $el->attr( class => join ' ', $el->attr( 'class' ), 'zapp-visible' );
                }
            }
            else {
                my ( $lhs_value, $rhs_value );
                if ( $lhs_value = extract_delimited( $lhs ) ) {
                    $lhs_value =~ s/^['"`]|['"`]$//g;
                }
                else {
                    $lhs_value = get_path_from_data( $lhs, $data );
                }
                if ( $rhs_value = extract_delimited( $rhs ) ) {
                    $rhs_value =~ s/^['"`]|['"`]$//g;
                }
                else {
                    $rhs_value = get_path_from_data( $rhs, $data );
                }

                my %ops = (
                    map { $_ => eval "sub { shift() $_ shift() }" } qw( == != > < >= <= eq ne gt lt ge le ),
                );
                #; say "LHS: $lhs_value ($lhs); OP: $op; RHS: $rhs_value ($rhs)";
                if ( $ops{ $op } && $ops{ $op }->( $lhs_value, $rhs_value ) ) {
                    $el->attr( class => join ' ', $el->attr( 'class' )//(), 'zapp-visible' );
                }
            }
        },
    );

    return $dom;
}

# 256 colors
# 0x00-0x07:  standard colors (same as the 4-bit colours)
# 0x08-0x0F:  high intensity colors
# 0x10-0xE7:  6 × 6 × 6 cube (216 colors): 16 + 36 × r + 6 × g + b (0 ≤ r, g, b ≤ 5)
# 0xE8-0xFF:  grayscale from black to white in 24 steps

my %colors;
$colors{8} = {
    # Foreground     # Background
    30 => 'black',   40 => 'black',
    31 => 'maroon',  41 => 'maroon',
    32 => 'green',   42 => 'green',
    33 => 'olive',   43 => 'olive',
    34 => 'navy',    44 => 'navy',
    35 => 'purple',  45 => 'purple',
    36 => 'teal',    46 => 'teal',
    37 => 'silver',  47 => 'silver',
    90 => 'gray',    100 => 'gray',
    91 => 'red',     101 => 'red',
    92 => 'lime',    102 => 'lime',
    93 => 'yellow',  103 => 'yellow',
    94 => 'blue',    104 => 'blue',
    95 => 'fuchsia', 105 => 'fuchsia',
    96 => 'aqua',    106 => 'aqua',
    97 => 'white',   107 => 'white',
};

$colors{256} = {
    # First 15 colors are mapped from above
    ( map { $_ - 30 => $colors{8}{$_} } 30..37 ),
    ( map { $_ - 82 => $colors{8}{$_} } 90..97 ),
    # Next 216 are cubes calculated thusly
    (
        map { my $r = $_;
            map { my $g = $_;
                map { my $b = $_;
                    16 + 36*$r + 6*$g + $b => sprintf 'rgb(%d,%d,%d)', $r*36, $g*36, $b*36,
                } 0..5
            } 0..5
        } 0..5
    ),

    # Final 24 are shades of gray
    ( map { 232 + $_ => sprintf 'rgb(%d,%d,%d)', (8 + $_*10)x3 } 0..23 ),
};

#pod =sub ansi_colorize
#pod
#pod Apply ANSI coloring and formatting to the given text. This is used to render
#pod output from a program that uses ANSI escape sequences.
#pod
#pod     my $html = ansi_colorize( $stdout );
#pod
#pod =cut

sub ansi_colorize( $text ) {
    my @parts = split /\e\[([\d;]*)m/, $text;
    return $parts[0] if @parts == 1;
    my $output = shift @parts;
    my %context;
    while ( my $code = shift @parts ) {
        my @styles = split /;/, $code;
        if ( !@styles ) {
            @styles = ( 0 );
        }
        while ( my $style = shift @styles ) {
            # 0 reset
            if ( $style == 0 ) {
                %context = ();
            }
            # 1 bold
            elsif ( $style == 1 ) {
                $context{ bold } = 'font-weight: bold';
            }
            # 22 unbold
            elsif ( $style == 22 ) {
                delete $context{ bold };
            }
            # 4 underline
            elsif ( $style == 4 ) {
                $context{ underline } = 'text-decoration: underline';
            }
            # 24 not underlined
            elsif ( $style == 24 ) {
                delete $context{ underline };
            }
            # 30-37,90-97 foreground color
            elsif ( ( $style >= 30 && $style <= 37 ) || ( $style >= 90 && $style <= 97 ) ) {
                $context{ color } = 'color: ' . $colors{8}{ $style };
            }
            elsif ( $style == 38 ) {
                my $type = shift @styles;
                # 38;5 256-color
                if ( $type == 5 ) {
                    $context{ color } = 'color: ' . $colors{256}{ shift @styles };
                }
                # 38;2 RGB color (0-255)
                elsif ( $type == 2 ) {
                    my ( $r, $g, $b ) = splice @styles, 0, 3;
                    $context{ color } = sprintf 'color: rgb(%d,%d,%d)', $r, $g, $b;
                }
            }
            # 39 reset foreground
            elsif ( $style == 39 ) {
                delete $context{ color };
            }
            # 40-47,100-107 background color
            elsif ( ( $style >= 40 && $style <= 47 ) || ( $style >= 100 && $style <= 107 ) ) {
                $context{ background } = 'background: ' . $colors{8}{ $style };
            }
            elsif ( $style == 48 ) {
                my $type = shift @styles;
                # 48;5 256-color
                if ( $type == 5 ) {
                    $context{ background } = 'background: ' . $colors{256}{ shift @styles };
                }
                # 48;2 RGB color (0-255)
                elsif ( $type == 2 ) {
                    my ( $r, $g, $b ) = splice @styles, 0, 3;
                    $context{ background } = sprintf 'background: rgb(%d,%d,%d)', $r, $g, $b;
                }
            }
            # 49 reset background
            elsif ( $style == 49 ) {
                delete $context{ background };
            }
        }

        $output .= sprintf( '<span style="%s">', join '; ', sort values %context )
            . shift( @parts ) 
            . '</span>';
    }

    return $output;
}

1;

__END__

=pod

=head1 NAME

Zapp::Util - General utilities for Zapp

=head1 VERSION

version 0.004

=head1 SUBROUTINES

=head2 build_data_from_params

Build a data structure from the parameters in the given request,
optionally with the given prefix. Parameter names are paths in the
resulting data structure.

    # ?name.first=Turanga&name.last=Leela
    { name => { first => 'Turanga', last => 'Leela' } }

    # ?crew[0]=Fry&crew[1]=Leela&crew[2]=Zoidberg%20Why%20Not
    { crew => [ 'Fry', 'Leela', 'Zoidberg Why Not' ] }

    # ?[0].name=Hubert&[0].age=160&[1].name=Cubert&[1].age=12
    [ { name => 'Hubert', age => 160 }, { name => 'Cubert', age => 12 } ]

=head2 get_slot_from_data

Get a reference to the given path in the given data. Can be used to set values
at paths.

=head2 get_path_from_data

Get the value for a given path out of the given data.

=head2 get_path_from_schema

Get the schema for a given path out of the given JSON Schema. Will traverse
object C<properties> and array C<items> to find the schema.

=head2 prefix_field

Add a prefix to any field in the given HTML or L<Mojo::DOM> object.
Prefixes are added to the C<name> and C<id> attributes of any form inputs, and
the C<for> attribute of any labels.

=head2 rename_field

Rename any form fields in the given HTML or L<Mojo::DOM> object using
the provided mapping. This changes the field C<name> and C<id>
attributes, and also the corresponding label C<for> attribute.

=head2 parse_zapp_attrs

Parse special C<data-zapp> attributes in the given HTML or L<Mojo::DOM> object.
These attributes add dynamic features to templates for L<Zapp::Task>, L<Zapp::Type>,
or L<Zapp::Trigger>.

=over

=item data-zapp-if="<expression>"

Display this element if the given C<< <expression> >> is true. The expression can
contain string literals, data paths, and the following operators:

    == != >  <  >= <=
    eq ne gt lt ge le

If the expression is true, the element is given the C<zapp-visible> class and
will appear. Expressions are evaluated in Perl when rendering the template and
in JavaScript when the user is modifying the form.

=head2 ansi_colorize

Apply ANSI coloring and formatting to the given text. This is used to render
output from a program that uses ANSI escape sequences.

    my $html = ansi_colorize( $stdout );

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
