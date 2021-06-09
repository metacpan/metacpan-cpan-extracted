package MARC::Moose::Lint::Checker::RulesFile;
# ABSTRACT: A class to 'lint' biblio record based on a rules file
$MARC::Moose::Lint::Checker::RulesFile::VERSION = '1.0.45';
use Moose;
use Modern::Perl;

with 'MARC::Moose::Lint::Checker';


has file => (is => 'ro', isa => 'Str', trigger => \&_set_file );

has rules => (is => 'rw', isa => 'HashRef');

has table => (is => 'rw', isa => 'HashRef', default => sub { {} });

has tablecheck => (is => 'rw', isa => 'HashRef', default => sub { {} });


sub _set_file {
    my $self = shift;

    my $file = $self->file;
    unless (-f $file) {
        say "$file: isn't a file";
        exit;
    }
    open my $fh, "<", $file;
    my @rules;
    my @parts;
    my $linenumber = 0;
    my %rules;
    my $analyze = sub {
        #say;
        my $tag = shift @parts;
        if ( $tag !~ /^([0-9]{3})[_|\+]*/ ) {
            say;
            say "Line $linenumber: Invalid tag portion";
            exit;
        }
        my $tag_digit = $1;
        my $is_control_field = $tag_digit lt '010';
        if ( (!$is_control_field && @parts < 3) || ($is_control_field && @parts > 1) ) {
            say;
            say "Line $linenumber: Invalid rule: wrong number of parts";
            exit;
        }
        my @rule = (
            $tag_digit,
            $tag =~ /_/ ? 1 : 0,
            $tag =~ /\+/ ? 1 : 0
        );

        if ( $is_control_field ) {
            push @rule, shift @parts;
        }
        else {
            push @rule, [ shift @parts, shift @parts ],
            [ map {
                s/^ *//; s/ *$//;
                my ($letter, $table, $regexp) =
                    /^([a-zA-Z0-9+_]+)\@([A-Z]*) *(.*)$/  ? ($1, $2, $3) :
                    /^([a-zA-Z0-9]+) +(.*)$/        ? ($1, 0, $2)  : ($_, 0, '');
                my $mandatory = $letter =~ /_/ ? 1 : 0;
                $letter =~ s/_//g;
                my $repeatable = $letter =~ /\+/ ? 1 : 0;
                $letter =~ s/\+//g;
                my @letter;
                push @letter, $letter, $mandatory, $repeatable, $table;
                push @letter, $regexp if $regexp;
                \@letter;
            } @parts ];
        }
        $rules{$tag_digit} = \@rule;

        @parts = ();
    };
    while (<$fh>) {
        $linenumber++;
        chop;
        s/ *$//;
        last if /^====/;

        if ( length($_) ) {
            push @parts, $_;
            next;
        }
        $analyze->();
    }
    $analyze->() if @parts;
    $self->rules( \%rules );

    my $code;
    if ( $_ && /^====/ ) {
        while (1) {
            if (/^==== *([A-Z]*) *(.*)$/) {
                ($code) = $1;
                for my $value ( split / +/, $2 ) {
                    say $_;
                    my $values = [ $code ];
                    my $tag = substr($value, 0, 3);
                    if ( $value = substr($value, 3) ) {
                        push @$values, substr($value, 0, 1);
                        $value = substr($value, 1);
                    }
                    if ( $value ) {
                        my ($from, $len) = split /,/, $value;
                        push @$values, $from, $len;
                    }
                    push @{ $self->tablecheck->{$tag} }, $values;
                };
            }
            else {
                $self->table->{$code}->{$_} = 1 if length($_) > 0;
            }
            while (<$fh>) {
                chop;
                last if defined $_;
            }
            last unless defined $_;
        }
    }
}


sub check {
    my ($self, $record) = @_;

    my @warnings = ();
    my $tag;        # Current tag
    my @fields;     # Array of fields;
    my $i_field;    # Indice in the current array of fields
    my $append = sub {
        my @text = ($tag);
        push @text, "($i_field)" if @fields > 1;
        push @text, ": ", shift;
        push @warnings, join('', @text);
    };
    my $fields_by_tag = { '000' => [ $record->leader ] };
    for my $field ( @{$record->fields} ) {
        $fields_by_tag->{$field->tag} ||= [];
        push @{$fields_by_tag->{$field->tag}}, $field;
    }

    # Find out unknown fields
    my $rules = $self->rules;
    {
        my @unknown;
        for $tag ( keys %$fields_by_tag ) {
            push @unknown, $tag unless $rules->{$tag};
        }
        for (@unknown) {
            $tag = $_;
            $append->('Unknown tag');
        }
    }

    for my $rule ( values %$rules ) {
        # Test if a mandatory field is missing, and if a non-repeatable field
        # is repeated
        my ($mandatory, $repeatable);
        ($tag, $mandatory, $repeatable) = @$rule;
        my $fields = $fields_by_tag->{$tag};
        unless ($fields) {
            @fields = ();
            $append->("missing mandatory field") if $mandatory;
            next;
        }
        @fields = @$fields;
        $append->("non-repeatable field")  if !$repeatable && @fields > 1;

        # Test tables
        if ( my $checks = $self->tablecheck->{$tag} ) {
            for my $check ( @$checks ) {
                my ($code, $check_letter, $from, $len) = @$check;
                my $table = $self->table->{$code};
                unless ($table) {
                    say "Unknown table specified in rules file: $table";
                    exit;
                }
                $i_field = 1;
                for my $field ( @fields ) {
                    for ( @{$field->subf} ) {
                        my ($letter, $value ) = @$_;
                        next if $letter ne $check_letter;
                        if ( length($from) > 0 ) {
                            my $val = substr($value, $from);
                            next unless $val;
                            $val = substr($val, 0, $len);
                            unless ( exists $table->{$val} ) {
                                $append->("subfield \$$letter, position $from,$len, invalid coded value: '$val'");
                            }
                        }
                        else {
                            unless ( exists $table->{$value} ) {
                                $append->("subfield \$$letter, invalid coded value (without from): '$value'");
                            }
                        }
                    }
                }
            }
        }

        $i_field = 1;

        # Control field & leader
        if ( $tag lt '010' ) {
            my $regexp;
            (undef, undef, undef, $regexp) = @$rule;
            if ( $regexp ) {
                if ( $tag eq '000') {
                    $append->("invalid leader, doesn't match /$regexp/")
                        if $record->leader !~ /$regexp/;
                }
                else {
                    for my $field (@fields) {
                        $append->("invalid value, doesn't match /$regexp/")
                            if $field->value !~ /$regexp/;
                        $i_field++;
                    }
                }
            }
            next;
        }

        # Standard field
        my ($ind, $subf);
        (undef, undef, undef, $ind, $subf) = @$rule;
        for my $field (@fields) {
            next if ref($field) ne 'MARC::Moose::Field::Std';
            for (my $i=1; $i <=2 ; $i++) {
                my $value = $i == 1 ? $field->ind1 : $field->ind2;
                my $regexp = $ind->[$i-1];
                $regexp =~ s/#/ /g;
                $regexp =~ s/,/|/g;
                $append->("invalid indicator $i '$value' , must be " . $ind->[$i-1])
                    if $value !~ /$regexp/;
            }
            # Search subfields which shouldn't be there
            my @forbidden;
            for (@{$field->subf}) {
                my ($letter, $value) = @$_;
                next unless $letter;
                next if grep { $_->[0] =~ $letter } @$subf;
                push @forbidden, $letter;
            }
            $append->("forbidden subfield(s): " . join(', ', @forbidden))
                if @forbidden;

            for (@$subf) {
                my ($letters, $mand, $repet, $table, $regexp) = @$_;
                for my $letter (split //, $letters) {
                    my @values = $field->subfield($letter);
                    $append->("\$$letter mandatory subfield is missing")
                        if @values == 0 && $mand;
                    $append->("\$$letter is repeated") if @values > 1 && !$repet;
                    my $i = 1;
                    my $multi = @values > 1;
                    for my $value (@values) {
                        if ( $table && ! $self->table->{$table}->{$value} ) {
                            $append->(
                                "subfield \$$letter" .
                                ($multi ? "($i)" : "") .
                                " contains '$value' not in $table table");
                        }
                        if ( $regexp && $value !~ /$regexp/ ) {
                            $append->(
                                "invalid subfield \$$letter" .
                                ($multi ? "($i)" : "") .
                                ", should be $regexp");
                        }
                        $i++;
                    }
                }
            }
            $i_field++;
        }
    }

    sort @warnings;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Lint::Checker::RulesFile - A class to 'lint' biblio record based on a rules file

=head1 VERSION

version 1.0.45

=head1 DESCRIPTION

A MARC biblio record, MARC21, UNIMARC, whatever, can be validated against
rules. Rules check various conditions:

=over

=item *

B<Unknown tag> - If a field is present in a record but is not specified by its
tag in a validation rule, a warning is emitted saying that this field has an
I<Unknown tag>. This way all tags which are not specifically defined in
validation rules are identified.

B<Unknown letter> - If a subfield is present in a field but is not specified by
its letter in a validation rule, a warning is emitted saying that this subfield
has an I<Unknown letter>. This way all subfields which are not specifically
defined in validation rules are identified.

=item *

B<Mandatory field> - When a validation rule defines that a field is mandatory,
if this field is not found in a record, a warning is emitted saying that this
field is I<missing>.

B<Mandatory subfield> - When a validation rule defines that a subfield is
mandatory, if this subfield is not found in a field, a warning is emitted saying
that this subfield is I<missing>.

=item *

B<Repeatable field> - When a validation rule specify that a field is not
repeatable, if this field is repeated in a record, a warning is emitted saying
that this field is L<non repeatable>.

=item *

B<Repeatable subfield> - When a validation rule specify that a subfield is not
repeatable, if this subfield is repeated in a field, a warning is emitted
saying that this subfield is L<non repeatable>.

=item *

B<Indicator values> - Authorised values for indicators 1 and 2 are specified in
validation rule. When a field uses another value, a warning is emitted saying
I<invalid indicator value>.

=item *

B<Field content> - The content of a field, control field value, or subfield
value, can be tested on a regular expression. This way it's possible to check
that a field comply to a specific format. C<.{3}> will accept values with 3
characters length. C<[0-9]{8}> will accept digit-only value with 8 digits. And
this regular expression will validate UNIMARC 100 code field:

 ^[0-9]{8}[a-ku][0-9 ]{8}[abcdeklu ]{3}[a-huyz][01 ][a-z]{3}[a-cy][01|02|03|04|05|06|07|08|09|10|11|50]{2}

=item *

B<Validation tables> - Validation tables can be specified. For example, table
of ISO language codes. Field/subfield content can be validated against a table
in order to identify unauthorised values. When such a value is found, a warning
is emitted saying that I<this value> is not in I<this table>.

=back

=head1 ATTRIBUTES

=head2 file

Name of the file containing validation rules based on which a biblio record can
be validated.

=head1 METHODS

=head2 check( I<record> )

This method checks a biblio record, based on the current 'lint' object. The
biblio record is a L<MARC::Moose::Record> object. An array of validation
errors/warnings is returned. Those errors are just plain text explanation on
the reasons why the record doesn't comply with validation rules.

=head1 SYNOPSYS

 use MARC::Moose::Record;
 use MARC::Moose::Reader::File::Iso2709;
 use MARC::Moose::Lint::Checker::RulesFile;

 # Read an ISO2709 file, and dump found errors
 my $reader = MARC::Moose::Reader::File::Iso2709->new(
     file => 'biblio.mrc' );
 my $lint = MARC::Moose::Lint::Checker::RulesFile->new(
     file => 'unimarc.rules' );
 while ( my $record = $reader->read() ) {
     if ( my @result = $lint->check($record) ) {
         say "Biblio record #", $record->field('001')->value;
         say join("\n", @result), "\n";
     }
 }

=head1 VALIDATION RULES

Validation rules are defined in a textual form. The file is composed of two
parts: (1) B<field rules>, (2) B<validation tables>.

=over

=item B<(1) Field rules>

Define validation rules for each tag. A blank line separates tags. For
example:

 102+
 #
 #
 abc+i@CTRY ^[a-z]{3}$
 2+

Line 1 contains the field tag. If a + is present, the field is repeatable. If a
_ is present, the field is mandatory. For I<control fields> (tag under 010), an
optional second line can contain a regular expression on which validating field
content. For <standard fields>, line 2 and 3 contains a regular expression on
which indicators 1 and 2 are validated. # means a blank indicator. Line 4 and
the following define rules for validating subfields. A first part contains
subfield's letters, and + (repeatable) and/or _ (mandatory), followed by an
optional validation table name begining with @. A blank separates the first
part from the second part. The second part contains a regular expression on
which subfield content is validated.

=item B<(2) Validation tables>

This part of the file allows to define several validation tables. The table
name begins with C<==== TABLE NAME> in uppercase. Then each line is a code in
the validation table.

This could be:

 ==== LANG 100a22,3 101a

In this case, the table will be used to validate coded values in coded fields.
In this example, the language table will check 100$a subfield, position 22,
length 3, and 101$a. A table must contain all possible values. It not possible
to use regular expressions. If you can have a blank value, you need a line
containing juste a blank.

=back

This is for example, a simplified standard UNIMARC validation rules file:

 000
 .{5}[cdnop][abcdefgijklmr][aimsc][ 012]

 001_

 005
 \d{14}\.\d

 100_
 #
 #
 a ^[0-9]{8}[a-ku][0-9 ]{8}[abcdeklu ]{3}[a-huyz][01 ][a-z]{3}[a-cy][01|02|03|04|05|06|07|08|09|10|11|50]{2}

 101_
 0|1|2
 #
 abcdfghij+@LANG ^[a-z]{3}$

 200_
 0|1
 #
 a_+
 bcdefghi+
 v
 z5+

 ==== CTRY
 AF
 AL
 DZ
 GG
 GN
 GW
 GY
 HT
 HM
 VE
 VN
 VG
 VI
 ZM
 ZW

 ==== LANG 100a22,3 101a
 aar
 afh
 afr
 afa
 ain
 aka
 akk

=head1 SEE ALSO

=over 4

=item *

L<MARC::Moose>

=item *

L<MARC::Moose::Lint::Processor>

=back

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
