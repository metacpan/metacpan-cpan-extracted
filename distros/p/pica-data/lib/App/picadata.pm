package App::picadata;
use v5.14.1;

our $VERSION = '2.07';

use Getopt::Long qw(GetOptionsFromArray :config bundling);
use Pod::Usage;
use PICA::Data   qw(pica_parser pica_writer pica_annotation);
use PICA::Patch  qw(pica_diff pica_patch);
use PICA::Schema qw(field_identifier);
use PICA::Schema::Builder;
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Scalar::Util qw(reftype);
use JSON::PP;
use List::Util qw(any all);
use Text::Abbrev;
use Term::ANSIColor;

my %TYPES = (
    bin    => 'Binary',
    dat    => 'Binary',
    binary => 'Binary',
    extpp  => 'Binary',
    ext    => 'Binary',
    plain  => 'Plain',
    pp     => 'Plain',
    import => 'Import',
    plus   => 'Plus',
    norm   => 'Plus',
    normpp => 'Plus',
    xml    => 'XML',
    ppxml  => 'PPXML',
    pixml  => 'PIXML',
    json   => 'JSON',
    ndjson => 'JSON',
);

my %COLORS = (
    tag        => 'magenta',
    occurrence => 'magenta',
    code       => 'red',
    value      => 'green'
);

sub new {
    my ($class, @argv) = @_;

    my $terminal = -t *STDIN;                             ## no critic
    my $command  = (!@argv && $terminal) ? 'help' : '';

    my $number = 0;
    if (my ($i) = grep {$argv[$_] =~ /^-(\d+)$/} (0 .. @argv - 1)) {
        $number = -(splice @argv, $i, 1);
    }

    my $noAnnotate = grep {$_ eq '-A'} @argv;

    my @path;

    my $opt = {
        number  => \$number,
        help    => sub {$command = 'help'},
        version => sub {$command = 'version'},
        build   => sub {$command = 'build'},
        count   => sub {$command = 'count'},     # for backwards compatibility
        path    => \@path,
        modify  => [],
    };

    my %cmd = abbrev
        qw(convert get count levels fields filter subfields sf explain validate build diff patch help version modify join);
    if ($cmd{$argv[0]}) {
        $command = $cmd{shift @argv};
        $command =~ s/^sf$/subfields/;
    }

    GetOptionsFromArray(
        \@argv,       $opt,           'from|f=s', 'to|t:s',
        'schema|s=s', 'annotate|A|a', 'abbrev|B', 'build|b',
        'unknown|u!', 'count|c',      'order|o',  'path|p=s',
        'level|l:i',  'number|n:i',   'color|C',  'mono|M',
        'help|h|?',   'version|V',
    ) or pod2usage(2);

    $opt->{number}   = $number;
    $opt->{annotate} = 0 if $noAnnotate;
    $opt->{color}
        = !$opt->{mono} && ($opt->{color} || -t *STDOUT);    ## no critic

    delete $opt->{$_} for qw(count build help version);

    if ($command eq 'modify') {
        die "missing path argument!\n" unless @argv;
        push @{$opt->{modify}}, parse_path(shift @argv);
        my $value = shift @argv;
        die "missing value argument!\n" unless defined $value;
        utf8::decode($value);
        push @{$opt->{modify}}, $value;
    }

    my $pattern = '[012.][0-9.][0-9.][A-Z@.](\$[^|]+|/[0-9.-]+)?';
    while (@argv && $argv[0] =~ /^$pattern(\s*\|\s*($pattern)?)*$/) {
        push @path, shift @argv;
    }

    @path = map {parse_path($_)}
        grep {$_ ne ""} map {split /\s*[\|,]\s*/, $_} @path;
    if (@path && all {$_->subfields ne ""} @path) {
        $command = 'get' unless $command;
    }

    $opt->{order} = 1 if $command =~ /(diff|patch|levels)/;

    unless ($command) {
        if ($opt->{schema} && !$opt->{annotate}) {
            $command = 'validate';
        }
        elsif ($opt->{abbrev}) {
            $command = 'build';
        }
        else {
            $command = 'convert';
        }
    }

    if ($command =~ /validate|explain|fields|subfields/ && !$opt->{schema}) {
        if ($ENV{PICA_SCHEMA}) {
            $opt->{schema} = $ENV{PICA_SCHEMA};
        }
        elsif ($command =~ /validate|explain/) {
            $opt->{error}
                = "$command requires an Avram Schema (via option -s or environment variable PICA_SCHEMA)";
        }
    }

    $opt->{annotate} = 1 if $command eq 'diff';
    $opt->{annotate} = 0 if $command eq 'patch';

    if ($opt->{schema}) {
        $opt->{schema} = load_schema($opt->{schema});
        $opt->{schema}{ignore_unknown} = $opt->{unknown};

        if ($command eq 'explain' && !@path && !@argv && $terminal) {
            while (my ($id, $field) = each %{$opt->{schema}{fields} || {}}) {
                push @path, parse_path($id);

                # see <https://github.com/gbv/k10plus-avram-api/issues/12>
                my $sf
                    = ref $field->{subfields} eq 'HASH'
                    ? $field->{subfields}
                    : {};
                push @path, map {parse_path("$id\$$_")} keys %$sf;
            }
        }
    }

    # all path expressions have been initialized as PICA::Path objects
    $opt->{path} = \@path;

    if ($command =~ qr{diff|patch}) {
        unshift @argv, '-' if @argv == 1;
        $opt->{error} = "$command requires two input files" if @argv != 2;

        if ($command eq 'diff') {

            # only Plain and JSON support annotations
            $opt->{to} = 'plain' unless $TYPES{lc $opt->{to}} eq 'JSON';
        }
    }

    $opt->{input} = @argv ? \@argv : ['-'];

    if (my $name = $opt->{from}) {
        $opt->{from} = $TYPES{lc $opt->{from}}
            or $opt->{error} = "unknown serialization type: $name";
    }

    # default output format
    unless ($opt->{to}) {
        if ($command =~ /(convert|levels|filter|diff|patch|modify|join)/) {
            $opt->{to} = $opt->{from};
            $opt->{to} ||= $TYPES{lc $1}
                if $opt->{input}->[0] =~ /\.([a-z]+)$/;
            $opt->{to} ||= 'plain';
        }
        elsif ($command eq 'validate' && $opt->{annotate}) {
            $opt->{to} = 'plain';
        }
    }

    if (my $name = $opt->{to}) {
        $opt->{to} = $TYPES{lc $opt->{to}}
            or $opt->{error} = "unknown serialization type: $name";
    }

    $opt->{command} = $command;

    bless $opt, $class;
}

sub parser_from_input {
    my ($self, $in, $format) = @_;

    if ($in eq '-') {
        $in = *STDIN;
        binmode $in, ':encoding(UTF-8)';
    }
    else {
        die "File not found: $in\n" unless -e $in;
    }

    $format ||= $self->{from};
    $format ||= $TYPES{lc $1} if $in =~ /\.([a-z]+)$/;

    return pica_parser($format || 'plain', $in);
}

sub load_schema {
    my ($schema) = @_;
    my $json;
    if ($schema =~ qr{^https?://}) {
        require HTTP::Tiny;
        my $res = HTTP::Tiny->new->get($schema);
        die "HTTP request failed: $schema\n" unless $res->{success};
        $json = $res->{content};
    }
    else {
        open(my $fh, "<", $schema)
            or die "Failed to open schema file: $schema\n";
        $json = join "\n", <$fh>;
    }
    return PICA::Schema->new(JSON::PP->new->decode($json));
}

sub run {
    my ($self)  = @_;
    my $command = $self->{command};
    my $schema  = $self->{schema};
    my @pathes  = @{$self->{path} || []};

    # commands that don't parse any input data
    if ($self->{error}) {
        pod2usage($self->{error});
    }
    elsif ($command eq 'help') {
        pod2usage(
            -verbose  => 99,
            -sections => "SYNOPSIS|COMMANDS|OPTIONS|DESCRIPTION|EXAMPLES"
        );
    }
    elsif ($command eq 'version') {
        say $PICA::Data::VERSION;
        exit;
    }
    elsif ($command eq 'explain') {
        $self->explain($schema, $_) for @pathes;
        unless (@pathes) {
            while (<STDIN>) {
                if ($_ =~ /^([^0-9a-z]\s+)?([^ ]+)/) {
                    my $path = eval {parse_path($_)};
                    if ($path) {
                        $self->explain($schema, $path);
                    }
                    else {
                        warn "invalid PICA Path: $_\n";
                    }

                }
            }
        }
        exit;
    }

    # initialize writer and schema builder
    my $writer;
    if ($self->{to}) {
        $writer = pica_writer(
            $self->{to},
            color    => ($self->{color} ? \%COLORS : undef),
            schema   => $schema,
            annotate => $self->{annotate},
        );
    }
    binmode *STDOUT, ':encoding(UTF-8)';

    my $builder
        = $command =~ /(build|fields|subfields|explain)/
        ? PICA::Schema::Builder->new($schema ? %$schema : ())
        : undef;

    my $joined = $command eq 'join' ? PICA::Data->new : undef;

    # additional options
    my $number  = $self->{number};
    my $level   = $self->{level};
    my $stats   = {records => 0, holdings => 0, items => 0, fields => 0};
    my $invalid = 0;

    my @getFields    = grep {$_->subfields eq ""} @pathes;
    my @getSubfields = grep {$_->subfields ne ""} @pathes;

    my $process = sub {
        my $record = shift;

        if ($command eq 'get' && @getSubfields) {
            say $_
                for map {@{$record->match($_, split => 1) // []}}
                @getSubfields;
        }

        $record = $record->sort if $self->{order};

        if ($command eq 'filter' && @pathes) {
            my @values
                = map {@{$record->match($_, split => 1) // []}} @pathes;
            return unless @values;
        }
        else {
            # reduce record to selected fields
            $record->{record} = $record->fields(@getFields) if @getFields;
        }
        return if $record->empty;

        if ($command eq 'modify') {
            if ($self->{annotate}) {

                # can't annotate an already annoted record
                pica_annotation($_, undef) for @{$record->{record}};
            }
            my $before = [map {[@$_]} @{$record->{record}}];    # deep copy
            my @modify = @{$self->{modify}};

            while (@modify) {
                my $path  = shift @modify;
                my $value = shift @modify;
                $record->update($path, $value);
            }

            if ($self->{annotate}) {
                $record = pica_diff($before, $record, keep => 1);
            }
        }

        # TODO: also validate on other commands?
        if ($command eq 'validate') {
            my @errors = $schema->check(
                $record,
                ignore_unknown => !$self->{unknown},
                annotate       => $self->{annotate}
            );
            if (@errors) {
                unless ($self->{annotate}) {
                    say(defined $record->{_id} ? $record->{_id} . ": $_" : $_)
                        for @errors;
                }
                $invalid++;
            }
        }

        if ($joined) {
            push @{$joined->{record}}, @{$record->{record}};
        }
        elsif ($writer) {
            $writer->write($record);
        }
        $builder->add($record) if $builder;

        if ($command eq 'count') {
            $stats->{holdings}
                += grep {@{$_->fields('1...')}} @{$record->holdings};
            $stats->{items}  += grep {!$_->empty} @{$record->items};
            $stats->{fields} += @{$record->{record}};
        }
        $stats->{records}++;
    };

    if ($command eq 'diff') {
        my @parser = map {$self->parser_from_input($_)} @{$self->{input}};
        while (1) {
            my $a = $parser[0]->next;
            my $b = $parser[1]->next;
            if ($a or $b) {
                $writer->write(pica_diff($a || [], $b || []));
            }
            else {
                last;
            }
            last if $number && $number <= ++$stats->{record};
        }
    }
    elsif ($command eq 'patch') {
        my $parser = $self->parser_from_input($self->{input}[0]);

        # TODO: allow to read diff in PICA/JSON
        my $patches = $self->parser_from_input($self->{input}[1], 'plain');
        my $diff;
        while (my $record = $parser->next) {
            $diff = $patches->next || $diff;    # keep latest diff
            die "Missing patch to apply in $self->{input}[1]\n" unless $diff;

            my $changed = eval {pica_patch($record, $diff)};
            if (!$changed || $@) {
                warn $@;
            }
            else {
                $writer->write($changed || []);
            }

            last if $number && $number <= ++$stats->{record};
        }
    }
    else {
        my $split = $command eq 'levels' || ($level // -1) >= 0;
    RECORD: foreach my $in (@{$self->{input}}) {
            my $parser = $self->parser_from_input($in);
            while (my $next = $parser->next) {
                for ($split ? $next->split($level) : $next) {
                    $process->($_);
                    last RECORD if $number and $stats->{records} >= $number;
                }
            }
        }
    }

    if ($writer) {
        $writer->write($joined->sort) if $joined;
        $writer->end();
    }

    if ($command eq 'count') {
        $stats->{invalid} = $invalid;
        say $stats->{$_} . " $_"
            for grep {$stats->{$_}} qw(records invalid holdings items fields);
    }
    elsif ($command =~ /(sub)?fields/) {
        my $fields = $builder->schema->{fields};
        for my $id (sort keys %$fields) {
            if ($command eq 'fields') {
                $self->document($id, $self->{abbrev} ? 0 : $fields->{$id});
            }
            else {
                my $sfs = $fields->{$id}->{subfields} || {};
                for (keys %$sfs) {
                    $self->document("$id\$$_",
                        $self->{abbrev} ? 0 : $sfs->{$_});
                }
            }
        }
    }
    elsif ($command eq 'build') {
        $schema = $builder->schema;
        print JSON::PP->new->indent->space_after->canonical->convert_blessed
            ->encode($self->{abbrev} ? $schema->abbreviated : $schema);
    }

    exit !!$invalid;
}

sub parse_path {
    eval {PICA::Path->new($_[0])} || die "invalid PICA Path: $_[0]\n";
}

sub explain {
    my ($self, $schema, $path) = @_;

    if ($path->stringify =~ /[.]/) {
        warn "Fields with wildcards cannot be explained yet!\n";
        return;
    }

    my $tag = $path->fields;

    my ($firstocc) = grep {$_ > 0} split '-', $path->occurrences;
    my $id = field_identifier($schema, [$tag, $firstocc]);

    my $def = $schema->{fields}{$id};
    if (defined $path->subfields && $def) {
        my $sfdef = $def->{subfields} || {};
        for (split '', $path->subfields) {
            $self->document("$id\$$_", $sfdef->{$_}, 1);
        }
    }
    else {
        $self->document($id, $def, 1);
    }
}

sub document {
    my ($self, $id, $def, $warn) = @_;

    my $writer
        = pica_writer('plain', color => ($self->{color} ? \%COLORS : undef));

    if ($def) {
        my $status = ' ';
        if ($def->{required}) {
            $status = $def->{repeatable} ? '+' : '.';
        }
        else {
            $status = $def->{repeatable} ? '*' : 'o';
        }

        my ($field, $subfield) = split '\$', $id;
        $writer->write_identifier([split '/', $field]);
        if (defined $subfield) {
            $writer->write_subfield($subfield, '');
        }
        print "\t";
        print $self->{color} ? colored($status, $COLORS{value}) : $status;

        my $doc = "\t" . $def->{label} // '';
        utf8::decode($doc);
        say $doc =~ s/[\s\r\n]+/ /mgr;
    }
    elsif (!$self->{unknown}) {
        if ($warn) {
            warn "$id\t?\n";
        }
        else {
            say $id;
        }
    }
}

=head1 NAME

App::picadata - Implementation of picadata command line application.

=head1 DESCRIPTION

This package implements the L<picadata> command line application.

=head1 COPYRIGHT AND LICENSE

Copyright 2020- Jakob Voss

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
