package Text::Editor::Easy::Syntax::Perl_glue;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Syntax::Perl_glue - Perl highlighting (will always be limited, perl is too dynamic...). Contexts are still not yet managed.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Syntax::Highlight::Perl::Improved ':FULL';
my $formatter = new Syntax::Highlight::Perl::Improved;

$formatter->define_substitution( 'Z' => 'Z&' );

my $subst_ref = $formatter->substitutions();

my %format = (
    'Comment_Normal'    => [ 'Za' => 'Z:' ],
    'Comment_POD'       => [ 'Zb' => 'Z:' ],
    'Directive'         => [ 'Zc' => 'Z:' ],
    'Label'             => [ 'Zd' => 'Z:' ],
    'Quote'             => [ 'Ze' => 'Z:' ],
    'String'            => [ 'Zf' => 'Z:' ],
    'Subroutine'        => [ 'Zg' => 'Z:' ],
    'Variable_Scalar'   => [ 'Zh' => 'Z:' ],
    'Variable_Array'    => [ 'Zi' => 'Z:' ],
    'Variable_Hash'     => [ 'Zj' => 'Z:' ],
    'Variable_Typeglob' => [ 'Zk' => 'Z:' ],
    'Whitespace'        => [ 'Zl' => 'Z:' ],
    'Character'         => [ 'Zm' => 'Z:' ],
    'Keyword'           => [ 'Zn' => 'Z:' ],
    'Builtin_Function'  => [ 'Zo' => 'Z:' ],
    'Builtin_Operator'  => [ 'Zp' => 'Z:' ],
    'Operator'          => [ 'Zq' => 'Z:' ],
    'Bareword'          => [ 'Zr' => 'Z:' ],
    'Package'           => [ 'Zs' => 'Z:' ],
    'Number'            => [ 'Zt' => 'Z:' ],
    'Symbol'            => [ 'Zu' => 'Z:' ],
    'CodeTerm'          => [ 'Zv' => 'Z:' ],
    'DATA'              => [ 'Zw' => 'Z:' ],
    'DEFAULT'           => [ 'Zx' => 'Z:' ],
);

$formatter->set_format(%format);

my %name;
for ( keys %format ) {
    my $element = $format{$_}[0];
    if ( $element =~ /Z(.)/ ) {
        $name{$1} = $_;
    }

    #print "name { $1 } = ", $name{$1}, "\n";
}

sub syntax {
    my ($text) = @_;

    my $print = 0;

    #  if ( $text =~ /0/ ) {
    #    $print = 1;
    #  }

    if ( !$text ) {
        return [ $text, "comment" ];
    }

    my @format = ();

    $formatter->reset();
    my $prg = $formatter->format_string($text);

    #print "$prg\n", $name{a}, "\n";;
    print "$prg\n" if $print;
    my $string  = 0;
    my $comment = 0;

    # Par défaut, format 'DEFAULT'
    my $format_courant = "";
  MATCH: while ( $prg =~ /(.*?)Z([^&]{1})/g ) {
        if ($comment) {

            #print "$1 : $name{a}\n";
            my $element = $1;
            $element =~ s/Z&/Z/g;
            print "$element\n" if $print;
            push @format, [ $element, $name{a} ];
        }
        else {
            if ( defined($1) ) {

                #print "$1 : ", $name{$format_courant}, "\n";
                my $element = $1;
                $element =~ s/Z&/Z/g;
                print "$element\n" if $print;
                push @format, [ $element, $name{$format_courant} ];
            }
        }

        if ( $2 eq ':' ) {
            if ( $format_courant eq "f" or $format_courant eq "a" ) {
                $string         = 0;
                $comment        = 0;
                $format_courant = "";
                next MATCH;
            }
            if ( $string or $comment ) {
                $format_courant = "a" if ($comment);
                $format_courant = "f" if ($string);
                next MATCH;
            }
            if ( $format_courant eq "" ) {
                die "Syntaxe highlight::perl à voir:\n\n$text\n\n, pos = ",
                  pos($text), "\n";
            }
            else {
                $format_courant = "";
            }
        }
        else {
            if ( $2 eq "f" or $2 eq "a" ) {
                $string  = 1 if ( $2 eq "f" );
                $comment = 1 if ( $2 eq "a" );
            }
            $format_courant = "$2";
        }
    }
    return @format;
}

=head1 FUNCTIONS

=head2 syntax

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
