package MARC::Moose::Formater::AuthorityUnimarcToMarc21;
$MARC::Moose::Formater::AuthorityUnimarcToMarc21::VERSION = '1.0.49';
# ABSTRACT: Convert authority record from UNIMARC to MARC21
use Moose;

use Modern::Perl;

extends 'MARC::Moose::Formater';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;



# List of moved fields unchanged
my @unchanged;
push @unchanged, [$_, 500]  for 300..315;
push @unchanged, [317, 561],
                 [320, 504],
                 [321, 500],
                 [322, 508],
                 [323, 511],
                 [324, 500],
                 [328, 502],
                 [330, 520],
                 [332, 524],
                 [333, 521],
                 [337, 538],
                 [686, '084'];

# Tags with non-filing indicator (pos 1 or 2)
my $nonfiling_tags = [
    [ qw/130 630 730 740 830/ ],
    [ qw/240 242 243 245 440 830/ ],
];

# NSB/NSE characters
my $ns_characters = [
    [ "\x08", "\x09" ],
    [ "\x88", "\x89" ]
];


my $equivals = [
    [ qw/ 200 100 / ],
    [ qw/ 210 110 / ],
    [ qw/ 215 151 / ],
    [ qw/ 220 120 / ],
    [ qw/ 225 125 / ],
    [ qw/ 230 130 / ],
    [ qw/ 240 140 / ],
    [ qw/ 250 150 / ],
    [ qw/ 415 451 / ],
    [ qw/ 515 551 / ],
];

override 'format' => sub {
    my ($self, $unimarc) = @_;

    my $record = MARC::Moose::Record->new();

    $record->_leader("     nam a22     7a 4500");

    # First, copy as it is
    $record->append( grep { 1 } @{$unimarc->fields} );   

    for (@$equivals) {
        my ($from, $to) = @$_;
        for my $field ($record->field($from)) {
            $field->tag($to);
        }
    }

    # On intervertit $z et $y
    for my $field ( $record->field('1..|4..|5..') ) {
        $field->subf( [ map {
            my ($letter, $value) = @$_;
            $letter = $letter eq 'y' ? 'z' :
                      $letter eq 'z' ? 'y' : $letter;
            [ $letter, $value ];
        } @{$field->subf} ] );
    }

    # Clean non-filing characters in all fields
    for my $field (@{$record->fields}) {
        next if $field->tag lt '010';
        for (@{$field->subf} ) {
            next if $_->[0] !~ /[a-z0-9]/;
            $_->[1] =~ s/\x08|\x09//g;
        }
    }

    return $record;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Formater::AuthorityUnimarcToMarc21 - Convert authority record from UNIMARC to MARC21

=head1 VERSION

version 1.0.49

=head1 SYNOPSYS

Read a authorities UNIMARC ISO2709 file and dump it to STDOUT in text
transformed into MARC21:

 my $reader = MARC::Moose::Reader::File::Iso2709->new(
   file => 'authority-unimarc.iso' );
 my $formater = MARC::Moose::Formater::AuthorityUnimarcToMarc21->new();
 while ( my $unimarc = $reader->read() ) {
   my $marc21 = $formater->format($unimarc);
   print $marc21->as('Text');
 }

Same with shortcut:

 my $reader = MARC::Moose::Reader::File::Iso2709->new(
   file => 'authority-unimarc.iso' );
 while ( my $unimarc = $reader->read() ) {
   print $unimarc->as('AuthorityUnimarcToMarc21')->as('Text');
 }

=head1 COMMAND LINE

If you don't want to write a Perl script, you can use the L<marcmoose> command.
This way, you can for example convert a ISO 2709 authorities UNIMARC file named
C<unimarc.iso> into a ISO 2709 MARC21 file named C<marc.iso>:

  marcmoose --parser iso2709 --formater iso2709 --converter authorityunimarctomarc21
            --output marc.iso unimarc.iso

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
