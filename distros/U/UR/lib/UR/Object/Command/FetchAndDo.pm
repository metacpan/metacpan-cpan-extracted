package UR::Object::Command::FetchAndDo;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;
use Data::Dumper;

class UR::Object::Command::FetchAndDo {
    is => 'Command',
    is_abstract => 1,
    has => [
        subject_class => {
            is => 'UR::Object::Type', 
            id_by => 'subject_class_name',
        }, 
        filter => {
            is => 'Text',  
            is_optional => 1,
            doc => 'Filter results based on the parameters.  See below for how to.'
        },
        _fields => {
            is_many => 1,
            is_optional => 1,
            doc => 'Methods which the caller intends to use on the fetched objects.  May lead to pre-fetching the data.'
        },
    ], 
};


########################################################################

sub help_detail {          
    my $class = shift;

    return $class->_filter_doc;
}

sub _filter_doc {          
    my $class = shift;

    my $doc = <<EOS;
Filtering:
----------
 Create filter equations by combining filterable properties with operators and
     values.
 Combine and separate these 'equations' by commas.  
 Use single quotes (') to contain values with spaces: name='genome institute'
 Use percent signs (%) as wild cards in like (~).
 Use backslash or single quotes to escape characters which have special meaning
     to the shell such as < > and &

Operators:
----------
 =  (exactly equal to)
 ~  (like the value)
 :  (in the list of several values, slash "/" separated)
    (or between two values, dash "-" separated)
 >  (greater than)
 >= (greater than or equal to)
 <  (less than)
 <= (less than or equal to)

Examples:
---------
EOS
    if (my $help_synopsis = $class->help_synopsis) {
        $doc .= " $help_synopsis\n";
    } else {
        $doc .= <<EOS
 lister-command --filter name=Bob --show id,name,address
 lister-command --filter name='something with space',employees\>200,job~%manager
 lister-command --filter cost:20000-90000
 lister-command --filter answer:yes/maybe
EOS
    }

    $doc .= <<EOS;

Filterable Properties: 
----------------------
EOS

    # Try to get the subject class name
    my $self = $class->create;
    if ( not $self->subject_class_name 
            and my $subject_class_name = $self->_resolved_params_from_get_options->{subject_class_name} ) {
        $self = $class->create(subject_class_name => $subject_class_name);
    }

    if ( $self->subject_class_name ) {
        if ( my @properties = $self->_subject_class_filterable_properties ) {
            my $longest_name = 0;
            foreach my $property ( @properties ) {
                my $name_len = length($property->property_name);
                $longest_name = $name_len if ($name_len > $longest_name);
            }

            for my $property ( @properties ) {
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
                $property_doc ||= ' (undocumented)';
                $property_doc =~ s/\n//gs;   # Get rid of embeded newlines

                my $data_type = $property->data_type || '';
                $data_type = ucfirst(lc $data_type);

                $doc .= sprintf(" %${longest_name}s  ($data_type): $property_doc\n",
                                $property->property_name);
            }
        }
        else {
            $doc .= sprintf(" %s\n", $self->error_message);
        }
    }
    else {
        $doc .= " Can't determine the list of filterable properties without a subject_class_name";
    }

    return $doc;
}

########################################################################

sub execute {  
    my $self = shift;    

    $self->_validate_subject_class
        or return;
    
    my $iterator = $self->_fetch
        or return;

    return $self->_do($iterator);
}

sub _validate_subject_class {
    my $self = shift;

    my $subject_class_name = $self->subject_class_name;
    $self->error_message("No subject_class_name indicated.")
        and return unless $subject_class_name;

    $self->error_message(
        sprintf(
            'This command is not designed to work on a base UR class (%s).',
            $subject_class_name,
        )
    )
        and return if $subject_class_name =~ /^UR::/;

    UR::Object::Type->use_module_with_namespace_constraints($subject_class_name);
    
    my $subject_class = $self->subject_class;
    $self->error_message(
        sprintf(
            'Can\'t get class meta object for class (%s).  Is this class a properly declared UR::Object?',
            $subject_class_name,
        )
    )
        and return unless $subject_class;
    
    $self->error_message(
        sprintf(
            'Can\'t find method (all_property_metas) in %s.  Is this a properly declared UR::Object class?',
            $subject_class_name,
        ) 
    )
        and return unless $subject_class->can('all_property_metas');

    return 1;
}

sub _subject_class_filterable_properties {
    my $self = shift;

    $self->_validate_subject_class
        or return;

    my %props = map { $_->property_name => $_ }
                    $self->subject_class->property_metas;

    return map { $_->[1] }                   # These maps are to get around a bug in perl 5.8
           sort { $a->[0] cmp $b->[0] }      # sort involving methdo calls inside the sort sub that
           map { [ $_->property_name, $_ ] } # might do sorts of their own
           grep { substr($_->property_name, 0, 1) ne '_' }  # Skip 'private' properties starting with '_'
           grep { ! $_->data_type or index($_->data_type, '::') == -1 }  # Can't filter object-type properties from a lister, right?
           values %props;
}

sub _hint_string {
    return;
}

sub _base_filter {
    return;
}

sub _complete_filter {
    my $self = shift;
    return join(',', grep { defined $_ } $self->_base_filter,$self->filter);
}

sub _fetch
{
    my $self = shift;
    my ($bool_expr, %extra) = UR::BoolExpr->resolve_for_string(
        $self->subject_class_name, 
        $self->_complete_filter, 
        $self->_hint_string
    );

    $self->error_message( sprintf('Unrecognized field(s): %s', join(', ', keys %extra)) )
        and return if %extra;
    
    if (my $i = $self->subject_class_name->create_iterator($bool_expr)) {
        return $i;
    }
    else {
        $self->error_message($self->subject_class_name->error_message);
        return;
    }
}

sub _do
{
    shift->error_message("Abstract class.  Please implement a '_do' method in your subclass.");
    return;
}

1;

=pod

=head1 NAME

UR::Object::Command::FetchAndDo - Base class for fetching objects and then performing a function on/with them.

=head1 SYNOPSIS

 package MyFecthAndDo;

 use strict;
 use warnings;

 use above "UR";

 class MyFecthAndDo {
     is => 'UR::Object::Command::FetchAndDo',
     has => [
     # other properties...
     ],
 };

 sub _do { # required
    my ($self, $iterator) = @_;

    while (my $obj = $iterator->next) {
        ...
    }

    return 1;
 }
 
 1;

=head1 Provided by the Developer

=head2 _do (required)

Implement this method to 'do' unto the iterator.  Return true for success, false for failure.

 sub _do {
    my ($self, $iterator) = @_;

    while (my $obj = $iterator->next) {
        ...
    }

    return 1;
 }

=head2 subject_class_name (optional)

The subject_class_name is the class for which the objects will be fetched.  It can be specified one of two main ways:

=over

=item I<by_the_end_user_on_the_command_line>

For this do nothing, the end user will have to provide it when the command is run.

=item I<by_the_developer_in the_class_declartion>

For this, in the class declaration, add a has key w/ arrayref of hashrefs.  One of the hashrefs needs to be subject_class_name.  Give it this declaration:

 class MyFetchAndDo {
     is => 'UR::Object::Command::FetchAndDo',
     has => [
         subject_class_name => {
             value => <CLASS NAME>,
             is_constant => 1,
         },
     ],
 };

=back

=head2 helps (optional)

Overwrite the help_brief, help_synopsis and help_detail methods to provide specific help.  If overwiting the help_detail method, use call '_filter_doc' to get the filter documentation and usage to combine with your specific help.

=cut

#$HeadURL: svn+ssh://svn/srv/svn/gscpan/distro/ur-bundle/trunk/lib/UR/Object/Command/FetchAndDo.pm $
#$Id: FetchAndDo.pm 47408 2009-06-01 03:53:45Z ssmith $#
