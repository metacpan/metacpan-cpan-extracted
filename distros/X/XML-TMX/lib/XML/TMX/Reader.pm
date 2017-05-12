package XML::TMX::Reader;

use 5.010;
use warnings;
use strict;
use Exporter ();
use vars qw($VERSION @ISA @EXPORT_OK);

use XML::DT;
use XML::TMX::Writer;

$VERSION = '0.31';
@ISA = 'Exporter';
@EXPORT_OK = qw();

=encoding utf-8

=head1 NAME

XML::TMX::Reader - Perl extension for reading TMX files

=head1 SYNOPSIS

   use XML::TMX::Reader;

   my $reader = XML::TMX::Reader->new( $filename );

   $reader -> for_tu( sub {
       my $tu = shift;
       #blah blah blah
   });

   @used_languages = $reader->languages;

   $reader->to_html()

=head1 DESCRIPTION

This module provides a simple way for reading TMX files.

=head1 METHODS

The following methods are available:

=head2 C<new>

This method creates a new XML::TMX::Reader object. This process checks
for the existence of the file and extracts some meta-information from
the TMX header;

  my $reader = XML::TMX::Reader->new("my.tmx");

=cut

sub new {
    my ($class, $file) = @_;

    return undef unless -f $file;
    my $self = bless {
                      encoding => _guess_encoding($file),
                      filename => $file,
                      ignore_markup => 1,
                     } => $class;
    $self->_parse_header;
    return $self;
}

sub _guess_encoding {
    my $file = shift;
    my $encoding = 'UTF-8';
    open my $fh, "<", $file or die "can't open $file";
    my $line = <$fh>;
    if ($line =~ /encoding=['"]([^'"]+)['"]/) {
        $encoding = $1;
    }
    close $fh;
    return $encoding;
}

sub _parse_header {
    my $self = shift;

    my $header = "";
    {
        local $/ = "<body>";
        open my $fh, "<:encoding($self->{encoding})", $self->{filename} or die "$!";
        $header = <$fh>;
        close $fh;
    }

    $header =~ s/^.*(<header)/$1/s;
    $header =~ s/(<\/header>).*$/$1/s;

    $header =~ s!(<header[^/]+/>).*$!$1!s;

    dtstring($header => (
                         'header' => sub {
                             $self->{header}{$_} = $v{$_} for (keys %v);
                         },
                         'prop' => sub {
                             $v{type} ||= "_";
                             push @{$self->{header}{-prop}{$v{type}}}, $c;
                         },
                         'note' => sub {
                             push @{$self->{header}{-note}}, $c;
                         },
                        ));
}

=head2 C<ignore_markup>

This method is used to set the flag to ignore (or not) markup inside
translation unit segments. The default is to ignore those markup.

If called without parameters, it sets the flag to ignore the
markup. If you don't want to do that, use

  $reader->ignore_markup(0);

=cut

sub ignore_markup {
  my ($self, $opt) = @_;
  $opt = 1 unless defined $opt;
  $self->{ignore_markup} = $opt;
}

=head2 C<languages>

This method returns the languages being used on the specified
translation memory. Note that the module does not check for language
code correctness or existence.

=cut

sub languages {
    my $self = shift;
    my %languages = ();
    $self->for_tu({proc_tu => 100},
                  sub {
                      my $tu = shift;
                      for ( keys %$tu ) {
                          $languages{$_}++ unless m/^-/;
                      }
                  } );
    return keys %languages;
}

=head2 C<for_tu>

Use C<for_tu> to process all translation units from a TMX file.
This version iterates for all tu (one at the time)

The configuration hash is a reference to a Perl hash. At the moment
these are valid options:

=over

=item C<-verbose>

Set this option to a true value and a counter of the number of
processed translation units will be printed to stderr.

=item C<-output> | C<output>

Filename to output the changed TMX to. Note that if you use this
option, your function should return a hash reference where keys are
language names, and values their respective translation.

=item C<gen_tu>

Write at most C<gen_tu> TUs

=item C<proc_tu>

Process at most C<proc_tu> TUs

=item C<patt>

Only process TU that match C<patt>.

=item C<-raw>

Pass the XML directly to the method instead of parsing it.

=item C<-verbatim>

Use segment contents verbatim, without any normalization.

=item C<-prop>

A hashref of properties to be B<added> to the TMX header block.

=item C<-note>

An arrayref of notes to be B<added> to the TMX header block.

=item C<-header>

A boolean value. If set to true, the heading tags (and closing tag) of
the TMX file are written. Otherwise, only the translation unit tags
are written.

=back

The function will receive two arguments:

=over

=item *

a reference to a hash which maps:

the language codes to the respective translation unit segment;

a special key "-prop" that maps property names to properties;

a special key "-note" that maps to a list of notes.

=item *

a reference to a hash which contains the attributes for those
translation unit tag;

=back

If you want to process the TMX and return it again, your function
should return an hash reference where keys are the languages, and
values their respective translation.


=cut

sub _merge_notes {
    my ($orig, $new) = @_;

    $orig //= [];
    $orig = [$orig] unless ref $orig eq "ARRAY";
    $new  = [$new]  unless ref $new  eq "ARRAY";

    push @$orig => grep { my $x = $_; !grep { $x eq $_} @$orig } @$new;

    return $orig;
}

sub _merge_props {
    my ($orig, $new) = @_;
    die "-prop should be hash" if $orig and ref $orig ne "HASH";
    die "-prop should be hash" if $new  and ref $new  ne "HASH";

    for my $key (keys %$new) {
        $orig->{$key} = _merge_notes($orig->{$key}, $new->{$key});
    }
    return $orig;
}

sub _compute_header {
    my ($current, $conf) = @_;
    my %header = %$current;
    if (exists($conf->{-note})) {
        $header{-note} = _merge_notes($header{-note}, $conf->{-note});
    }
    if (exists($conf->{-prop})) {
        $header{-prop} = _merge_props($header{-prop}, $conf->{-prop});
    }
    return \%header;
}

sub for_tu {
    my $self = shift;
    my $conf = { -header => 1 };
    my $i = 0;

    ref($_[0]) eq "HASH" and $conf = {%$conf , %{shift(@_)}};

    my $code = shift;
    die "invalid processor" unless ref($code) eq "CODE";

    local $/;

    my $outputingTMX = 0;
    my $tmx;
    my $data;
    my $gen=0;
    my %h = (
             -type => { tu => 'SEQ', tuv => 'SEQ' },
             tu  => sub {
                 my $tu;
                 for my $va (@$c) {
                     if ($va->[0] eq "-prop") {
                         push @{$tu->{$va->[0]}{$va->[1]}}, $va->[2]
                     } elsif ($va->[0] eq "-note") {
                         push @{$tu->{$va->[0]}}, $va->[1]
                     } else {
                         $tu->{$va->[0]} = $va->[1]
                     }
                 }
                 my ($ans, $v) = $code->($tu, \%v);

                 # Check if the user wants to create a TMX and
                 # forgot to say us
                 if (!$outputingTMX && $ans && ref($ans) eq "HASH") {
                     $outputingTMX = 1;
                     $tmx = XML::TMX::Writer->new();
                     if ($conf->{-header}) {
                         my $header = _compute_header($self->{header}, $conf);
                         $tmx->start_tmx(encoding => $self->{encoding}, %$header);
                     }
                 }
                 # Add the translation unit
                 if ($ans && ref($ans) eq "HASH") {
                     $gen++;
                     %v = %$v if ($v && ref($v) eq "HASH");

                     my %ans = (%v, %$ans);
                     $ans{"-n"}=$i if $conf->{n} ;
                     $tmx->add_tu(-verbatim => $conf->{-verbatim}, %ans);
                 }
             },

             tuv  => sub {
                 my $tuv;
                 for my $v (@$c) {
                     if ($v->[0] eq "-prop") {
                         push @{$tuv->{$v->[0]}{$v->[1]}}, $v->[2]
                     } elsif ($v->[0] eq "-note") {
                         push @{$tuv->{$v->[0]}}, $v->[1]
                     } elsif ($v->[0] eq "-cdata") {
                         $tuv->{-iscdata} = 1;
                         $tuv->{-seg} = $v->[1];
                     } else {
                         $tuv->{-seg} = $v->[0];
                     }
                 }
                 [ $v{lang} || $v{'xml:lang'} || "_" => $tuv ]
             },
             prop => sub { ["-prop", $v{type} || "_", $c] },
             note => sub { ["-note" , $c] },
             seg  => sub {
                 return ($v{iscdata}) ? [ -cdata => $c ] : [ $c ]
             },
             -cdata => sub { 
                father->{'iscdata'} = 1; $c },
             hi   => sub { $self->{ignore_markup}?$c:toxml },
             ph   => sub { $self->{ignore_markup}?$c:toxml },
            );


    $/ = "\n";

    $h{-outputenc} = $h{-inputenc} = $self->{encoding};

    my $resto = "";
    ## Go through the header...
    open X, "<encoding($self->{encoding})" ,$self->{filename} or die "cannot open file $self->{filename}\n";
    while (<X>) {
        if (/^\xFF\xFE/) {
            die("UTF16 encoding not supported; try 'iconv -f unicode -t utf8 tmx' before\n");
        }
        next if /^\s*$/;
        last if /<body\b/;
    }

    if (m!(.*?)(<body.*?>)(.*)!s) {
        $resto = $3;
    }


    # If we have an output filename, user wants to output a TMX
    $conf->{-output} = $conf->{output} if defined($conf->{output});
    if (defined($conf->{-output})) {
        $outputingTMX = 1;
        $tmx = XML::TMX::Writer->new();
        if ($conf->{-header}) {
            my $header = _compute_header($self->{header}, $conf);
            $tmx->start_tmx(encoding => $self->{encoding},
                            -output  => $conf->{-output},
                            %$header);
        }
    }

    $/ = "</tu>";
    $conf->{-verbose}++ if $conf->{verbose};
    print STDERR "." if $conf->{-verbose};
    while (<X>) {
        ($_ = $resto . $_ and $resto = "" ) if $resto;
        last if /<\/body>/;
        $i++;
        print STDERR "\r$i" if $conf->{-verbose} && !($i % 10);
        last if defined $conf->{proc_tu} && $i > $conf->{proc_tu} ;
        last if defined $conf->{gen_tu}  && $gen > $conf->{gen_tu};
        next if defined $conf->{patt}    && !m/$conf->{patt}/     ;
        ####
        # This can't be done. Not sure why it was being done.
        # So, please, unless you know the implications for tagged crpora
        # do not uncomment it.
        #       s/\>\s+/>/;
        undef($data);
        if ($conf->{'-raw'}) {
            my $ans = $code->($_);
            if ($conf->{-output}) {
                $ans->{"-n"}=$i if $conf->{n} ;
                $tmx->add_tu(-raw => $ans);
            }
        } else {
            eval { dtstring($_, %h) } ; ## dont die in invalid XML
            warn $@ if $@;
        }
    }
    print STDERR "\r$i\n" if $conf->{-verbose};
    close X;


    $tmx->end_tmx if $conf->{-header} && $outputingTMX;
}

=head2 C<to_html>

Use this method to create a nice HTML file with the translation
memories. Notice that this method is not finished yet, and relies on
some images, on some specific locations.

=cut

sub to_html {
  my $self = shift;
  my %opt = @_;
  $self->for_tu(sub {
                    my ($langs, $opts) = @_;
                    my $ret = "<table>";
                    for (keys %$langs) {
                        next if /^-/;
                        $ret .= "<tr><td style=\"vertical-align: top\">";
                        if ($opt{icons}) {
                            $ret .= "<img src=\"/icons/flags/".lc($_).".png\" alt=\"$_\"/>"
                        } else {
                            $ret .= "$_"
                        }
                        $ret .= "</td><td>$langs->{$_}{-seg}</td></tr>\n"
                    }
                    $ret .= "<tr><td></td></tr></table>";
                    $ret;
                }
               );
}

sub for_tu2 {
    warn "Please update your code to use 'for_tu'\n";
    &for_tu;
}

=head2 C<for_tu2>

deprecated. use C<for_tu>

=head1 SEE ALSO

L<XML::Writer(3)>, TMX Specification L<https://www.gala-global.org/oscarStandards/tmx/tmx14b.html>

=head1 AUTHOR

Alberto Simões, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

Paulo Jorge Jesus Silva, E<lt>paulojjs@bragatel.ptE<gt>

J.João Almeida, E<lt>jj@di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2012 by Projecto Natura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
