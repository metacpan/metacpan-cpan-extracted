package UR::Object::Command::List;
use strict;
use warnings;

use IO::File;
use Data::Dumper;
require Term::ANSIColor;
use UR;
use UR::Object::Command::List::Style;
use List::Util qw(reduce);
use Command::V2;
use Carp qw();

our $VERSION = "0.46"; # UR $VERSION;

class UR::Object::Command::List {
    is => 'Command::V2',
    has_input => [
        subject_class_name => {
            is => 'ClassName',
            doc => 'the type of object to list',
        },
        filter => {
            is => 'Text',
            is_optional => 1,
            doc => 'Filter results based on the parameters.  See below for details.',
            shell_args_position => 1,
        },
        show => {
            is => 'Text',
            is_optional => 1,
            doc => 'Specify which columns to show, in order.  Prefix with "+" or "^" to append/prepend to the default list.',
        },
        order_by => {
            is => 'Text',
            is_optional => 1,
            doc => 'Output rows are listed sorted by these named columns in increasing order.',
        },
    ],
    has_param => [
        style => {
            is => 'Text',
            is_optional => 1,
            valid_values => [qw/text csv tsv pretty html xml newtext/],
            default_value => 'text',
            doc => 'The output format.',
        },
        csv_delimiter => {
           is => 'Text',
           is_optional => 1,
           default_value => ',',
           doc => 'For the "csv" output style, specify the field delimiter for something besides a comma.',
        },
        noheaders => {
            is => 'Boolean',
            is_optional => 1,
            default => 0,
            doc => 'Include headers.  Set --noheaders to turn headers off.',
        },
    ],
    has_transient => [
        output => {
            is => 'IO::Handle',
            is_optional =>1,
            is_transient =>1,
            default => \*STDOUT,
            doc => 'output handle for list, defauls to STDOUT',
        },
        _fields => {
            is_many => 1,
            is_optional => 1,
            doc => 'Methods which the caller intends to use on the fetched objects.  May lead to pre-fetching the data.',
        },
    ],
    doc => 'lists objects matching the specified expression',
};

sub sub_command_sort_position { .2 };

sub create {
    my $class = shift;
    my $self = $class->SUPER::create(@_);

    if (defined($self->csv_delimiter)
        and ($self->csv_delimiter ne $self->__meta__->property_meta_for_name('csv_delimiter')->default_value)
        and ($self->style ne 'csv')
    ) {
        $self->error_message('--csv-delimiter is only valid when used with --style csv');
        return;
    }

    unless ( ref $self->output ){
        my $ofh = IO::File->new("> ".$self->output);
        $self->error_message("Can't open file handle to output param ".$self->output) and die unless $ofh;
        $self->output($ofh);
    }

    return $self;
}

sub _resolve_boolexpr {
    my $self = shift;

    my ($bool_expr, %extra) = UR::BoolExpr->resolve_for_string(
        $self->subject_class_name,
        $self->_complete_filter,
        $self->_hint_string,
        $self->order_by,
    );

    if (%extra) {
        Carp::croak(
            sprintf(
                'Cannot list for class %s because some items in the filter or show were not properties of that class: %s',
                $self->subject_class_name,
                join(', ', keys %extra)
            )
        );
    }

    return $bool_expr;
}


# Used by create() and execute() to distinguish whether an item from the show list
# is likely a property of the subject class or a more complicated expression that needs
# to be eval-ed later
sub _show_item_is_property_name {
    my($self, $item) = @_;
    return $item =~ m/^[\w\.]+$/;
}

sub execute {
    my $self = shift;

    my $subject_class_name = $self->subject_class_name;

    # ensure classes can be loaded from whatever namespace the subject class has
    # TODO: make the UR command open the door for the type loading below to hit 
    # all namespaces when _it_ is running only.  The ur commands are sw maint tools.
    my ($ns) = ($subject_class_name =~ /^(.*?)::/);
    eval "use $ns";
    my $subject_class = UR::Object::Type->get($subject_class_name);

    my @fields = $self->resolve_show_column_names;

    my $bool_expr = $self->_resolve_boolexpr();
    return unless (defined $bool_expr);

    # TODO: instead of using an iterator, get all the results back in a list and
    # have the styler use the list, since it needs all the results to space the columns
    # out properly anyway
    my $iterator = $self->create_iterator_for_results_from_boolexpr($bool_expr);

    $self->display_styled_results($iterator, \@fields);

    return 1;
}

sub resolve_show_column_names {
    my $self = shift;
    $self->_resolve_field_list;
}

sub create_iterator_for_results_from_boolexpr {
    my($self, $bx) = @_;
    my $iterator = $self->subject_class_name->create_iterator($bx);
    unless ($iterator) {
        $self->fatal_message($self->subject_class_name->error_message);
    }
    return $iterator;
}

sub display_styled_results {
    my($self, $iterator, $fields) = @_;

    my $style_module_name = __PACKAGE__ . '::' . ucfirst $self->style;
    my $style_module = $style_module_name->new(
        iterator => $iterator,
        show => $fields,
        csv_delimiter => $self->csv_delimiter,
        noheaders => $self->noheaders,
        output => $self->output,
    );
    $style_module->format_and_print;
}

sub _resolve_field_list {
    my $self = shift;

    if ( my $show = $self->show ) {
        if (substr($show,0,1) =~ /([\+\^\-])/) {
            # if it starts with any of the special characters, combine with the default
            my $default = $self->__meta__->property('show')->default_value;
            unless ($default) {
                $default = join(",", map { $_->property_name } $self->_properties_for_class_to_document($self->subject_class_name));
            }
            $show = join(',',$default,$show);
        }

        my @show;
        my $expr;
        my @parts = (split(/,/, $show));
        my $append_prepend_or_omit = '+';
        my $prepend_count = 0;
        for my $item (@parts) {
            if ($item =~ /^([\+\^\-])/) {
                if ($1 eq '^') {
                    $prepend_count = 0;
                }
                $append_prepend_or_omit = $1;
                $item = substr($item,1);
            }
            if ($self->_show_item_is_property_name($item) and not defined $expr) {
                if ($append_prepend_or_omit eq '+') {
                    # append
                    push @show, $item;
                }
                elsif ($append_prepend_or_omit eq '^') {
                    # prepend
                    splice(@show, $prepend_count, 0, $item);
                    $prepend_count++;
                }
                elsif ($append_prepend_or_omit eq '-') {
                    # omit
                    @show = grep { $_ ne $item } @show;
                }
                else {
                    die "unrecognized operator in show string: $append_prepend_or_omit";
                }
            }
            else {
                if ($expr) {
                    $expr .= ',' . $item;
                }
                else {
                    $expr = '(' . $item;
                }
                my $o;
                if (eval('sub { ' . $expr . ')}')) {
                    push @show, $expr . ')';
                    #print "got: $expr<\n";
                    $expr = undef;
                }
            }
        }
        if ($expr) {
            die "Bad expression: $expr\n$@\n";
        }
        return @show;
    }
    else {
        return map { $_->property_name } $self->_properties_for_class_to_document($self->subject_class_name);
    }
}

sub _filter_doc {
    my $class = shift;
    my $doc = <<EOS;
 Filtering:
 ----------
 Restrict which items are listed by adding a filter.
     job=Captain

 Quotes are needed only when spaces or special words are involved.
 Sylistically, use " on the outer expression, and ' around field values:
     "age>18"            # > is a special character
     name='Bob Jones'    # spaces in a field value

 Standard and/or predicated logic is supported (like in SQL).
     "name='Bob Jones' and job='Captain' and age>18"
     "name='Betty Jones' and (score < 10 or score > 100)"

 The "like" operator uses "%" as a wildcard:
     "name like '%Jones'"

 The "not" operator negates the condition:
     "name not like '%Jones'"

 Use square brackets for "in" clauses.
     "name like '%Jones' and job in [Captain,Ensign,'First Officer']"

 Use a dot (".") to indirectly access related data (joins):
     "age<18 and father.address.city='St. Louis'"
     "previous_order.items.price > 100"

 A shorthand filter form allows many queries to be written more concisely:
    regular:    "name = 'Jones' and age between 18-25 and happy in ['yes','no','maybe']"
    shorthand:  name~%Jones,age:18-25,happy:yes/no/maybe

    Shorthand Key:
    --------------
    ,  " and "
    =  exactly equal to
    ~  "like" the value
    :   "between" two values, dash "-" separated
    :  "in" the list of several values, slash "/" separated
    !  "not" operator can be combined with any of the above
EOS

    if (my $help_synopsis = $class->help_synopsis) {
        $doc .= "\n Examples:\n ---------\n";
        $doc .= " $help_synopsis\n";
    }

    # Try to get the subject class name
    my $self = $class->create;
    if ( not $self->subject_class_name
            and my $subject_class_name = $self->_resolved_params_from_get_options->{subject_class_name} ) {
        $self = $class->create(subject_class_name => $subject_class_name);
    }

    my @properties = $self->_properties_for_class_to_document($self->subject_class_name);
    my @filterable_properties   = grep { ! $_->data_type or index($_->data_type, '::') == -1 } @properties;
    my @relational_properties = grep {   $_->data_type and index($_->data_type, '::') >=  0 } @properties;

    my $longest_name = 0;
    foreach my $property ( @properties ) {
        my $name_len = length($property->property_name);
        $longest_name = $name_len if ($name_len > $longest_name);
    }

    my @data;
    if ( ! $self->subject_class_name ) {
        $doc .= " Can't determine the list of properties without a subject_class_name.\n";
    } elsif ( ! @properties ) {
        $doc .= sprintf(" %s\n", $self->error_message);
    } else {
        if (@filterable_properties) {
            push @data, 'Simple Properties:';
            for my $property ( @filterable_properties ) {
                push @data, [$property->property_name, $self->_doc_for_property($property, $longest_name)];
            }
        }

        if (@relational_properties) {
            push @data, 'Complex Properties (support dot-syntax):';
            for my $property ( @relational_properties ) {
                my $name = $property->property_name;
                my @doc = $self->_doc_for_property($property,$longest_name);
                push @data, [$name, $doc[0]];
                for my $n (1..$#doc) {
                    push @data, ['', $doc[$n]];
                }
            }
        }
    }
    my @lines = $class->_format_property_doc_data(@data);
    { no warnings 'uninitialized';
        $doc .= join("\n ", @lines);
    }

    $self->delete;
    return $doc;
}

sub _doc_for_property {
    my $self = shift;
    my $property = shift;
    my $longest_name = shift;

    my $doc;

    my $property_doc = $property->doc;
    unless ($property_doc) {
        eval {
            foreach my $ancestor_class_meta ( $property->class_meta->ancestry_class_metas ) {
                my $ancestor_property_meta = $ancestor_class_meta->property_meta_for_name($property->property_name);
                if ($ancestor_property_meta and $ancestor_property_meta->doc) {
                    $property_doc = $ancestor_property_meta->doc;
                    last;
                }
            }
        };
    }
    $property_doc ||= '';
    $property_doc =~ s/\n//gs;   # Get rid of embeded newlines

    my $data_type = $property->data_type;
    my $data_class = eval { $property->_data_type_as_class_name };

    if ($data_type and $data_class eq $data_type) {
        my @has = $self->_properties_for_class_to_document($data_class);
        my @labels;
        for my $pmeta (@has) {
            my $name = $pmeta->property_name;
            my $type = $pmeta->data_type;
            if ($type and $type =~ /::/) {
                push @labels, "$name\[.*\]";
            }
            else {
                push @labels, $name;
            }
        }
        return (
            ($property_doc ? $property_doc : ()), 
            " see <man $data_class> for more details",
            ' has: ' . join(", ", @labels),
            '',
        );
    }
    else {
        $data_type ||= 'Text';
        $data_type = (index($data_type, '::') == -1) ? ucfirst(lc $data_type) : $data_type;
        if ($property_doc) {
            $property_doc = '(' . $data_type . '): ' . $property_doc;
        }
        else {
            $property_doc = '(' . $data_type . ')';
        }
        return $property_doc;
    }
}

sub _format_property_doc_data {
    my ($class, @data) = @_;

    my @names = map { $_->[0] } grep { ref $_ } @data;
    my $longest_name = reduce { length($a) > length($b) ? $a : $b } @names;
    my $w = length($longest_name);

    my @lines;
    for my $data (@data) {
        if (ref $data) {
            push @lines, sprintf(" %${w}s  %s", $data->[0], $data->[1]);
        } else {
            push @lines, ' ', $data, '-' x length($data);
        }
    }
    
    return @lines;
}

sub _properties_for_class_to_document {
    my $self = shift;
    my $target_class_name = shift;

    my $target_class_meta = $target_class_name->__meta__;
    my @id_by = $target_class_meta->id_properties;

    my @props = $target_class_meta->properties;

    no warnings;
    # These final maps are to get around a bug in perl 5.8 sort
    # involving method calls inside the sort sub that may
    # do sorts of their own
    return 
        map { $_->[1] }
        sort { $a->[1]->position_in_module_header <=> $b->[1]->position_in_module_header or $a->[0] cmp $b->[0] }
        map { [ $_->property_name, $_ ] }
        grep {
            substr($_->property_name, 0, 1) ne '_'
            and not $_->implied_by
            and not $_->is_transient
            and not $_->is_deprecated
        }
        @props;
}

sub _base_filter {
    return;
}

sub _complete_filter {
    my $self = shift;
    return join(',', grep { defined $_ } $self->_base_filter,$self->filter);
}

sub help_detail {
    my $self = shift;
    return join(
        "\n",
        $self->_style_doc,
        $self->_filter_doc,
    );
}

sub _style_doc {
    return <<EOS;
 Listing Styles:
 ---------------
 text - table like
 pretty - objects listed singly with color enhancements
 html - html table
 xml - xml document using elements
 tsv - tab separated values
 csv - comma (or other character) separated values*

 --csv-delimiter can be used tospecify another delimiter besides a comma for "csv"
EOS
}

sub _hint_string {
    my $self = shift;
    my @show_parts = grep { $self->_show_item_is_property_name($_) } $self->_resolve_field_list();
    return join(',',@show_parts);
}


1;
