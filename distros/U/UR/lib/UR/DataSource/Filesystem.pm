package UR::DataSource::Filesystem;

use UR;
use strict;
use warnings;
our $VERSION = "0.47"; # UR $VERSION;

use File::Basename;
use File::Path;
use List::Util;
use Scalar::Util;
use Errno qw(EINTR EAGAIN EOPNOTSUPP);

# lets you specify the server in several ways:
# path => '/path/name'
#    means there is one file storing the data
# path => [ '/path1/name', '/path2/name' ]
#    means the first tile we need to open the file, pick one (for load balancing)
# path => '/path/to/directory/'
#    means that directory contains one or more files, and the classes using
#    this datasource can have table_name metadata to pick the file
# path => '/path/$param1/${param2}.ext'
#    means the values for $param1 and $param2 should come from the input rule.
#    If the rule doesn't specify the param, then it should glob for the possible
#    names at that point in the filesystem
# path => '/path/&method/filename'
#    means the value for that part of the path should come from a method call
#    run as $subject_class_name->$method($rule)
# path => '/path/*/path/$name/
#    means it should glob at the appropriate time for the '*', but no use the
#    paths found matching the glob to infer any values

# maybe suppert a URI scheme like
# file:/path/$to/File.ext?columns=[a,b,c]&sorted_columns=[a,b]

# TODO
# * Support non-equality operators for properties that are part of the path spec


class UR::DataSource::Filesystem {
    is => 'UR::DataSource',
    has => [
        path                  => { doc => 'Path spec for the path on the filesystem containing the data' },
        delimiter             => { is => 'String', default_value => '\s*,\s*', doc => 'Delimiter between columns on the same line' },
        record_separator      => { is => 'String', default_value => "\n", doc => 'Delimiter between lines in the file' },
        header_lines          => { is => 'Integer', default_value => 0, doc => 'Number of lines at the start of the file to skip' },
        columns_from_header   => { is => 'Boolean', default_value => 0, doc => 'The column names are in the first line of the file' },
        handle_class          => { is => 'String', default_value => 'IO::File', doc => 'Class to use for new file handles' },
    ],
    has_optional => [
        columns               => { is => 'ARRAY', doc => 'Names of the columns in the file, in order' },
        sorted_columns        => { is => 'ARRAY', doc => 'Names of the columns by which the data file is sorted' },
    ],
    doc => 'A data source for treating files as relational data',
};

sub can_savepoint { 0;}  # Doesn't support savepoints

# Filesystem datasources don't have a "default_handle"
sub create_default_handle { undef }

sub _regex {
    my $self = shift;

    unless ($self->{'_regex'}) {
        my $delimiter = $self->delimiter;
        my $r = eval { qr($delimiter)  };
        if ($@ || !$r) {
            $self->error_message("Unable to interepret delimiter '".$self->delimiter.": $@");
            return;
        }
        $self->{'_regex'} = $r;
    }
    return $self->{'_regex'};
}


sub _logger {
    my $self = shift;
    my $varname = shift;
    if ($ENV{$varname}) {
        my $log_fh = UR::DBI->sql_fh;
        return sub { 
                   my $msg = shift;
                   my $time = time();
                   $msg =~ s/\b\$time\b/$time/g;
                   my $localtime = scalar(localtime $time);
                   $msg =~ s/\b\$localtime\b/$localtime/;

                   $log_fh->print($msg);
               };
    } else {
        return \&UR::Util::null_sub;
    }
}

# The behavior for handling the filehandles after fork is contained in
# the read_record_from_file closure.  There's nothing special for the
# data source to do
sub prepare_for_fork {
    return 1;
}
sub finish_up_after_fork {
    return 1;
}

# Like UR::BoolExpr::specifies_value_for, but works on either a BoolExpr
# or another object.  In the latter case, it returns true if the object's
# class has the given property
sub __specifies_value_for {
    my($self, $thing, $property_name) = @_;

    return $thing->isa('UR::BoolExpr')
            ? $thing->specifies_value_for($property_name)
            : $thing->__meta__->property_meta_for_name($property_name);
}

# Like UR::BoolExpr::value_for, but works on either a BoolExpr
# or another object.
sub __value_for {
    my($self, $thing, $property_name) = @_;

    return $thing->isa('UR::BoolExpr')
            ? $thing->value_for($property_name)
            : $thing->$property_name;
}

# Like UR::BoolExpr::subject_class_name, but works on either a BoolExpr
# or another object.
sub __subject_class_name {
    my($self, $thing) = @_;

    return $thing->isa('UR::BoolExpr')
            ? $thing->subject_class_name()
            : $thing->class;
}


sub _replace_vars_with_values_in_pathname {
    my($self, $rule_or_obj, $string, $prop_values_hash) = @_;

    $prop_values_hash ||= {};

    # Match something like /some/path/$var/name or /some/path${var}.ext/name
    if ($string =~ m/\$\{?(\w+)\}?/) {
        my $varname = $1;
        my $subject_class_name = $self->__subject_class_name($rule_or_obj);
        unless ($subject_class_name->__meta__->property_meta_for_name($varname)) {
            Carp::croak("Invalid 'server' for data source ".$self->id
                        . ": Path spec $string requires a value for property $varname "
                        . " which is not a property of class $subject_class_name");
        }
        my @string_replacement_values;

        if ($self->__specifies_value_for($rule_or_obj, $varname)) {
            my @property_values = $self->__value_for($rule_or_obj, $varname);
            if (@property_values == 1 and ref($property_values[0]) eq 'ARRAY') {
                @property_values = @{$property_values[0]};
            }
            # Make a listref that has one element per value for that property in the rule (in-clause
            # rules may have more than one value)
            # Each element has 2 parts, first is the value, second is the accumulated prop_values_hash
            # where we've added the occurance of this property havine one of the values
            @property_values = map { [ $_, { %$prop_values_hash, $varname => $_ } ] } @property_values;

            # Escape any shell glob characters in the values: [ ] { } ~ ? * and \
            # we don't want a property with value '?' to be a glob wildcard
            @string_replacement_values = map { $_->[0] =~ s/([[\]{}~?*\\])/\\$1/; $_ } @property_values;

        } else {
            # The rule doesn't have a value for this property.
            # Put a shell wildcard in here, and a later glob will match things
            # The '.__glob_positions__' key holds a list of places we've inserted shell globs.
            # Each element is a 2-element list: index 0 is the string position, element 1 if the variable name.
            # This is needed so the later glob expansion can tell the difference between globs
            # that are part of the original path spec, and globs put in here
            my @glob_positions = @{ $prop_values_hash->{'.__glob_positions__'} || [] };

            my $glob_pos = $-[0];
            push @glob_positions, [$glob_pos, $varname];
            @string_replacement_values = ([ '*', { %$prop_values_hash, '.__glob_positions__' => \@glob_positions} ]);
        }

        my @return = map {
                         my $s = $string;
                         substr($s, $-[0], $+[0] - $-[0], $_->[0]);
                         [ $s, $_->[1] ];
                     }
                     @string_replacement_values;

        # recursion to process the next variable replacement
        return map { $self->_replace_vars_with_values_in_pathname($rule_or_obj, @$_) } @return;

    } else {
        return [ $string, $prop_values_hash ];
    }
}

sub _replace_subs_with_values_in_pathname {
    my($self, $rule_or_obj, $string, $prop_values_hash) = @_;

    $prop_values_hash ||= {};
    my $subject_class_name = $self->__subject_class_name($rule_or_obj);

    # Match something like /some/path/&sub/name or /some/path&{sub}.ext/name
    if ($string =~ m/\&\{?(\w+)\}?/) {
        my $subname = $1;
        unless ($subject_class_name->can($subname)) {
            Carp::croak("Invalid 'server' for data source ".$self->id
                        . ": Path spec $string requires a value for method $subname "
                        . " which is not a method of class " . $self->__subject_class_name($rule_or_obj));
        }
 
        my @property_values = eval { $subject_class_name->$subname($rule_or_obj) };
        if ($@) {
            Carp::croak("Can't resolve final path for 'server' for data source ".$self->id
                        . ": Method call to ${subject_class_name}::${subname} died with: $@");
        }
        if (@property_values == 1 and ref($property_values[0]) eq 'ARRAY') {
            @property_values = @{$property_values[0]};
        }
        # Make a listref that has one element per value for that property in the rule (in-clause
        # rules may have more than one value)
        # Each element has 2 parts, first is the value, second is the accumulated prop_values_hash
        # where we've added the occurance of this property havine one of the values
        @property_values = map { [ $_, { %$prop_values_hash } ] } @property_values;

        # Escape any shell glob characters in the values: [ ] { } ~ ? * and \
        # we don't want a return value '?' or '*' to be a glob wildcard
        my @string_replacement_values = map { $_->[0] =~ s/([[\]{}~?*\\])/\\$1/; $_ } @property_values;

        # Given a pathname returned from the glob, return a new glob_position_list
        # that has fixed up the position information accounting for the fact that
        # the globbed pathname is a different length than the original spec
        my $original_path_length = length($string);
        my $glob_position_list = $prop_values_hash->{'.__glob_positions__'};
        my $subname_replacement_position = $-[0];
        my $fix_offsets_in_glob_list = sub {
               my $pathname = shift;
               # alter the position only if it is greater than the position of
               # the subname we're replacing
               return map { [ $_->[0] < $subname_replacement_position
                                  ? $_->[0]
                                  : $_->[0] + length($pathname) - $original_path_length,
                             $_->[1] ]
                          }
                          @$glob_position_list;
        };

        my @return = map {
                         my $s = $string;
                         substr($s, $-[0], $+[0] - $-[0], $_->[0]);
                         $_->[1]->{'.__glob_positions__'} = [ $fix_offsets_in_glob_list->($s) ];
                         [ $s, $_->[1] ];
                     }
                     @string_replacement_values;

        # recursion to process the next method call
        return map { $self->_replace_subs_with_values_in_pathname($rule_or_obj, @$_) } @return;

    } else {
        return [ $string, $prop_values_hash ];
    }
}

sub _replace_glob_with_values_in_pathname {
    my($self, $string, $prop_values_hash) = @_;

    # a * not preceeded by a backslash, delimited by /
    if ($string =~ m#([^/]*?[^\\/]?(\*)[^/]*)#) {
        my $glob_pos = $-[2];

        my $path_segment_including_glob = substr($string, 0, $+[0]);
        my $remaining_path = substr($string, $+[0]);
        my @glob_matches = map { $_ . $remaining_path }
                               glob($path_segment_including_glob);

        my $resolve_glob_values_for_each_result;
        my $glob_position_list = $prop_values_hash->{'.__glob_positions__'};

        # Given a pathname returned from the glob, return a new glob_position_list
        # that has fixed up the position information accounting for the fact that
        # the globbed pathname is a different length than the original spec
        my $original_path_length = length($string);
        my $fix_offsets_in_glob_list = sub {
               my $pathname = shift;
               return map { [ $_->[0] + length($pathname) - $original_path_length, $_->[1] ] } @$glob_position_list;
        };

        if ($glob_position_list->[0]->[0] == $glob_pos) {
            # This * was put in previously by a $propname in the spec that wasn't mentioned in the rule

            my $path_delim_pos = index($path_segment_including_glob, '/', $glob_pos);
            $path_delim_pos = length($path_segment_including_glob) if ($path_delim_pos == -1);  # No more /s

            my $regex_as_str = $path_segment_including_glob;
            # Find out just how many *s we're dealing with and where they are, up to the next /
            # remove them from the glob_position_list because we're going to resolve their values
            my(@glob_positions, @property_names);
            while (@$glob_position_list
                   and
                  $glob_position_list->[0]->[0] < $path_delim_pos
            ) {
                my $this_glob_info = shift @{$glob_position_list};
                push @glob_positions, $this_glob_info->[0];
                push @property_names, $this_glob_info->[1];
            }
            # Replace the *s found with regex captures
            my $glob_replacement = '([^/]*)';
            my $glob_rpl_offset = 0;
            my $offset_inc = length($glob_replacement) - 1;  # replacing a 1-char string '*' with a 7-char string '([^/]*)'
            $regex_as_str = List::Util::reduce( sub {
                                                    substr($a, $b + $glob_rpl_offset, 1, $glob_replacement);
                                                    $glob_rpl_offset += $offset_inc;
                                                    $a;
                                                },
                                                ($regex_as_str, @glob_positions) );

            my $regex = qr{$regex_as_str};
            my @property_values_for_each_glob_match = map { [ $_, [ $_ =~ $regex] ] } @glob_matches;

            # Fill in the property names into .__glob_positions__
            # we've resolved in this iteration, and apply offset fixups for the
            # difference in string length between the pre- and post-glob pathnames

            $resolve_glob_values_for_each_result = sub {
                return map {
                               my %h = %$prop_values_hash;
                               @h{@property_names} = @{$_->[1]};
                               $h{'.__glob_positions__'} = [ $fix_offsets_in_glob_list->($_->[0]) ];
                               [$_->[0], \%h];
                           }
                           @property_values_for_each_glob_match;
            };

       } else {
           # This is a glob put in the original path spec
           # The new path comes from the @glob_matches list.
           # Apply offset fixups for the difference in string length between the
           # pre- and post-glob pathnames
           $resolve_glob_values_for_each_result = sub {
               return map { [
                                $_,
                                { %$prop_values_hash,
                                  '.__glob_positions__' => [ $fix_offsets_in_glob_list->($_) ]
                                }
                            ]
                          }
                          @glob_matches;
           };
       }

       my @resolved_paths_and_property_values = $resolve_glob_values_for_each_result->();

       # Recursion to process the next glob
       return map { $self->_replace_glob_with_values_in_pathname( @$_ ) }
                  @resolved_paths_and_property_values;

    } else {
        delete $prop_values_hash->{'.__glob_positions__'};
        return [ $string, $prop_values_hash ];
    }
}


sub resolve_file_info_for_rule_and_path_spec {
    my($self, $rule, $path_spec) = @_;

    $path_spec ||= $self->path;

    return map { $self->_replace_glob_with_values_in_pathname(@$_) }
           map { $self->_replace_subs_with_values_in_pathname($rule, @$_) }
               $self->_replace_vars_with_values_in_pathname($rule, $path_spec);
}


# We're overriding path() so the first time it's called, it will
# pick one from the list and then stay with that one for the life
# of the program
sub path {
    my $self = shift;

    unless ($self->{'__cached_path'}) {
        my $path = $self->__path();
        if (ref($path) and ref($path) eq 'ARRAY') {
            my $count = @$path;
            my $idx = $$ % $count;
            $self->{'_cached_path'} = $path->[$idx];
        } else {
            $self->{'_cached_path'} = $path;
        }
    }
    return $self->{'_cached_path'};
}

# Names of creation params that we should force to be listrefs
our %creation_param_is_list = map { $_ => 1 } qw( columns sorted_columns );
sub create_from_inline_class_data {
    my($class, $class_data, $ds_data) = @_;

    #unless (exists $ds_data->{'columns'}) {
        # User didn't specify columns in the file.  Assumme every property is a column, and in the same order
        # We'll have to ask the class object for the column list the first time there's a query
    #}

    my %ds_creation_params;
    foreach my $param ( qw( path delimiter record_separator columns header_lines
                            columns_from_header handle_class sorted_columns )
    ) {
        if (exists $ds_data->{$param}) {
            if ($creation_param_is_list{$param} and ref($ds_data->{$param}) ne 'ARRAY') {
                $ds_creation_params{$param} = \( $ds_data->{$param} );
            } else {
                $ds_creation_params{$param} = $ds_data->{$param};
            }
        }
    }

    my $ds_id = UR::Object::Type->autogenerate_new_object_id_uuid();
    my $ds_type = delete $ds_data->{'is'} || __PACKAGE__;
    my $ds = $ds_type->create( %ds_creation_params, id => $ds_id );
    return $ds;
}



sub _things_in_list_are_numeric {
    my $self = shift;

    foreach ( @{$_[0]} ) {
        return 0 if (! Scalar::Util::looks_like_number($_));
    }
    return 1;
}

# Construct a closure to perform an operator test against the given value
# The closures return 0 is the test is successful, -1 if unsuccessful but
# the file's value was less than $value, and 1 if unsuccessful and greater.
# The iterator that churns through the file knows that if it's comparing an
# ID/sorted column, and the comparator returns 1 then we've gone past the
# point where we can expect to ever find another successful match and we
# should stop looking
my $ALWAYS_FALSE = sub { -1 };
sub _comparator_for_operator_and_property {
    my($self,$property,$operator,$value) = @_;

    no warnings 'uninitialized';  # we're handling ''/undef/null specially below where it matters

    if ($operator eq 'between') {
        if ($value->[0] eq '' or $value->[1] eq '') {
            return $ALWAYS_FALSE;
        }

        if ($property->is_numeric and $self->_things_in_list_are_numeric($value)) {
            if ($value->[0] > $value->[1]) {
                # Will never be true
                Carp::carp "'between' comparison will never be true with values ".$value->[0]," and ".$value->[1];
                return $ALWAYS_FALSE;
            }

            # numeric 'between' comparison
            return sub {
                       return -1 if (${$_[0]} eq '');
                       if (${$_[0]} < $value->[0]) {
                           return -1;
                       } elsif (${$_[0]} > $value->[1]) {
                           return 1;
                       } else {
                           return 0;
                       }
                   };
        } else {
            if ($value->[0] gt $value->[1]) {
                Carp::carp "'between' comparison will never be true with values ".$value->[0]," and ".$value->[1];
                return $ALWAYS_FALSE;
            }

            # A string 'between' comparison
            return sub {
                       return -1 if (${$_[0]} eq '');
                       if (${$_[0]} lt $value->[0]) {
                           return -1;
                       } elsif (${$_[0]} gt $value->[1]) {
                           return 1;
                       } else {
                           return 0;
                       }
                   };
        }

    } elsif ($operator eq 'in') {
        if (! @$value) {
            return $ALWAYS_FALSE;
        }

        if ($property->is_numeric and $self->_things_in_list_are_numeric($value)) {
            # Numeric 'in' comparison  returns undef if we're within the range of the list
            # but don't actually match any of the items in the list
            @$value = sort { $a <=> $b } @$value;  # sort the values first
            return sub {
                       return -1 if (${$_[0]} eq '');
                       if (${$_[0]} < $value->[0]) {
                           return -1;
                       } elsif (${$_[0]} > $value->[-1]) {
                           return 1;
                       } else {
                           foreach ( @$value ) {
                               return 0 if ${$_[0]} == $_;
                           }
                           return -1;
                       }
                   };

        } else {
            # A string 'in' comparison
            @$value = sort { $a cmp $b } @$value;
            return sub {
                       if (${$_[0]} lt $value->[0]) {
                           return -1;
                       } elsif (${$_[0]} gt $value->[-1]) {
                           return 1;
                       } else {
                           foreach ( @$value ) {
                               return 0 if ${$_[0]} eq $_;
                           }
                           return -1;
                       }
                   };

        }

    } elsif ($operator eq 'not in') {
        if (! @$value) {
            return $ALWAYS_FALSE;
        }

        if ($property->is_numeric and $self->_things_in_list_are_numeric($value)) {
            return sub {
                return -1 if (${$_[0]} eq '');
                foreach ( @$value ) {
                    return -1 if ${$_[0]} == $_;
                }
                return 0;
            }

        } else {
            return sub {
                foreach ( @$value ) {
                    return -1 if ${$_[0]} eq $_;
                }
                return 0;
            }
        }

    } elsif ($operator eq 'like') {
        # 'like' is always a string comparison.  In addition, we can't know if we're ahead
        # or behind in the file's ID columns, so the only two return values are 0 and 1

        return $ALWAYS_FALSE if ($value eq '');  # property like NULL is always false

        # Convert SQL-type wildcards to Perl-type wildcards
        # Convert a % to a *, and _ to ., unless they're preceeded by \ to escape them.
        # Not that this isn't precisely correct, as \\% should really mean a literal \
        # followed by a wildcard, but we can't be correct in all cases without including 
        # a real parser.  This will catch most cases.

        $value =~ s/(?<!\\)%/.*/g;
        $value =~ s/(?<!\\)_/./g;
        my $regex = qr($value);
        return sub {
                   return -1 if (${$_[0]} eq '');
                   if (${$_[0]} =~ $regex) {
                       return 0;
                   } else {
                       return 1;
                   }
               };

    } elsif ($operator eq 'not like') {
        return $ALWAYS_FALSE if ($value eq '');  # property like NULL is always false
        $value =~ s/(?<!\\)%/.*/;
        $value =~ s/(?<!\\)_/./;
        my $regex = qr($value);
        return sub {
                   return -1 if (${$_[0]} eq '');
                   if (${$_[0]} =~ $regex) {
                       return 1;
                   } else {
                       return 0;
                   }
               };


    # FIXME - should we only be testing the numericness of the property?
    } elsif ($property->is_numeric and $self->_things_in_list_are_numeric([$value])) {
        # Basic numeric comparisons
        if ($operator eq '=') {
            return sub {
                       return -1 if (${$_[0]} eq ''); # null always != a number
                       return ${$_[0]} <=> $value;
                   };
        } elsif ($operator eq '<') {
            return sub {
                       return -1 if (${$_[0]} eq ''); # null always != a number
                       ${$_[0]} < $value ? 0 : 1;
                   };
        } elsif ($operator eq '<=') {
            return sub {
                       return -1 if (${$_[0]} eq ''); # null always != a number
                       ${$_[0]} <= $value ? 0 : 1;
                   };
        } elsif ($operator eq '>') {
            return sub {
                       return -1 if (${$_[0]} eq ''); # null always != a number
                       ${$_[0]} > $value ? 0 : -1;
                   };
        } elsif ($operator eq '>=') {
            return sub {
                       return -1 if (${$_[0]} eq ''); # null always != a number
                       ${$_[0]} >= $value ? 0 : -1;
                   };
        } elsif ($operator eq 'true') {
            return sub {
                       ${$_[0]} ? 0 : -1;
                   };
        } elsif ($operator eq 'false') {
            return sub {
                       ${$_[0]} ? -1 : 0;
                   };
        } elsif ($operator eq '!=' or $operator eq 'ne') {
             return sub {
                       return 0 if (${$_[0]} eq '');  # null always != a number
                       ${$_[0]} != $value ? 0 : -1;
             }
        }

    } else {
        # Basic string comparisons
        if ($operator eq '=') {
            return sub {
                       return -1 if (${$_[0]} eq '' xor $value eq '');
                       return ${$_[0]} cmp $value;
                   };
        } elsif ($operator eq '<') {
            return sub {
                       ${$_[0]} lt $value ? 0 : 1;
                   };
        } elsif ($operator eq '<=') {
            return sub {
                       return -1 if (${$_[0]} eq '' or $value eq '');
                       ${$_[0]} le $value ? 0 : 1;
                   };
        } elsif ($operator eq '>') {
            return sub {
                       ${$_[0]} gt $value ? 0 : -1;
                   };
        } elsif ($operator eq '>=') {
            return sub {
                       return -1 if (${$_[0]} eq '' or $value eq '');
                       ${$_[0]} ge $value ? 0 : -1;
                   };
        } elsif ($operator eq 'true') {
            return sub {
                       ${$_[0]} ? 0 : -1;
                   };
        } elsif ($operator eq 'false') {
            return sub {
                       ${$_[0]} ? -1 : 0;
                   };
        } elsif ($operator eq '!=' or $operator eq 'ne') {
             return sub {
                       ${$_[0]} ne $value ? 0 : -1;
             }
        }
    }
}



sub _properties_from_path_spec {
    my($self) = @_;

    unless (exists $self->{'__properties_from_path_spec'}) {
        my $path = $self->path;
        $path = $path->[0] if ref($path);

        my @property_names;
        while($path =~ m/\G\$\{?(\w+)\}?/) {
            push @property_names, $1;
        }
        $self->{'__properties_from_path_spec'} = \@property_names;
    }
    return @{ $self->{'__properties_from_path_spec'} };
}


sub _generate_loading_templates_arrayref {
    my($self, $old_sql_cols) = @_;

    # Each elt in @$column_data is a quad:
    # [ $class_meta, $property_meta, $table_name, $object_num ]
    # Keep only the properties with columns (mostly just to remove UR::Object::id
    my @sql_cols = grep { $_->[1]->column_name }
                        @$old_sql_cols;

    my $template_data = $self->SUPER::_generate_loading_templates_arrayref(\@sql_cols);
    return $template_data;
}



sub _resolve_column_names_from_pathname {
    my($self,$pathname,$fh) = @_;

    unless (exists($self->{'__column_names_from_pathname'}->{$pathname})) {
        if (my $column_names_in_order = $self->columns) {
            $self->{'__column_names_from_pathname'}->{$pathname} = $column_names_in_order;

        } else {
            my $record_separator = $self->record_separator();
            my $line = $fh->getline();
            $line =~ s/$record_separator$//;  # chomp, but for any value
            # FIXME - to support record-oriented files, we need some replacement for this...
            my $split_regex = $self->_regex();
            my @headers = split($split_regex, $line);
            $self->{'__column_names_from_pathname'}->{$pathname} = \@headers;
        }
    }
    return $self->{'__column_names_from_pathname'}->{$pathname};
}


sub file_is_sorted_as_requested {
    my($self, $query_plan) = @_;

    my $sorted_columns = $self->sorted_columns || [];

    my $order_by_columns = $query_plan->order_by_columns();
    for (my $i = 0; $i < @$order_by_columns; $i++) {
        next if ($order_by_columns->[$i] eq '$.');  # input line number is always sorted
        next if ($order_by_columns->[$i] eq '__FILE__');

        return 0 if $i > $#$sorted_columns;
        if ($sorted_columns->[$i] ne $order_by_columns->[$i]) {
            return 0;
        }
    }
    return 1;
}


# FIXME - this is a copy of parts of _generate_class_data_for_loading from UR::DS::RDBMS
sub _generate_class_data_for_loading {
    my ($self, $class_meta) = @_;

    my $parent_class_data = $self->SUPER::_generate_class_data_for_loading($class_meta);

    my @class_hierarchy = ($class_meta->class_name,$class_meta->ancestry_class_names);
    my $order_by_columns;
    do {
        my @id_column_names;
        for my $inheritance_class_name (@class_hierarchy) {
            my $inheritance_class_object = UR::Object::Type->get($inheritance_class_name);
            unless ($inheritance_class_object->table_name) {
                next;
            }
            @id_column_names =
                #map {
                #    my $t = $inheritance_class_object->table_name;
                #    ($t) = ($t =~ /(\S+)\s*$/);
                #    $t . '.' . $_
                #}
                grep { defined }
                map {
                    my $p = $inheritance_class_object->property_meta_for_name($_);
                    die ("No property $_ found for " . $inheritance_class_object->class_name . "?") unless $p;
                    $p->column_name;
                }
                map { $_->property_name }
                grep { $_->column_name }
                $inheritance_class_object->direct_id_property_metas;

            last if (@id_column_names);
        }
        $order_by_columns = \@id_column_names;
    };

    my(@all_table_properties, @direct_table_properties, $first_table_name, $subclassify_by);
    for my $co ( $class_meta, @{ $parent_class_data->{parent_class_objects} } ) {
        my $table_name = $co->table_name;
        next unless $table_name;

        $first_table_name ||= $co->table_name;
#        $sub_classification_method_name ||= $co->sub_classification_method_name;
#        $sub_classification_meta_class_name ||= $co->sub_classification_meta_class_name;
        $subclassify_by   ||= $co->subclassify_by;

        my $sort_sub = sub ($$) { return $_[0]->property_name cmp $_[1]->property_name };
        push @all_table_properties,
            map { [$co, $_, $table_name, 0 ] }
            sort $sort_sub
            grep { defined $_->column_name && $_->column_name ne '' }
            UR::Object::Property->get( class_name => $co->class_name );

        @direct_table_properties = @all_table_properties if $class_meta eq $co;
    }


    my $class_data = {
        %$parent_class_data,

        order_by_columns                    => $order_by_columns,
        direct_table_properties             => \@direct_table_properties,
        all_table_properties                => \@all_table_properties,
    };
    return $class_data;
}


# Needed for the QueryPlan's processing of order-by params
# Params are a list of the 4-tuples [class-meta, prop-meta, table-name, object-num]
sub _select_clause_columns_for_table_property_data {
    my $self = shift;


    return [ map { $_->[1]->column_name } @_ ];
}

# Used to populate the %value_extractor_for_column_name hash
# It should return a sub that, when given a row of data from the source,
# returns the proper data from that row.
#
# It's expected to return a sub that accepts ($self, $row, $fh, $filename)
# and return a reference to the right data.  In most cases, it'll just pluck
# out the $column_idx'th element from $@row, but we're using it
# to attach special meaning to the $. token
sub _create_value_extractor_for_column_name {
    my($self, $rule, $column_name, $column_idx) = @_;

    if ($column_name eq '$.') {
        return sub {
            my($self, $row, $fh, $filename) = @_;
            my $line_no = $fh->input_line_number();
            return \$line_no;
        };
    } elsif ($column_name eq '__FILE__') {
        return sub {
            my($self,$row,$fh,$filename) = @_;
            return \$filename;
        };
    } else  {
        return sub {
            my($self, $row, $fh, $filename) = @_;
            return \$row->[$column_idx];
        };
    }
}


sub create_iterator_closure_for_rule {
    my($self,$rule) = @_;

    my $class_name = $rule->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $rule_template = $rule->template;

    # We're defering to the class metadata here because we don't yet know the
    # pathnames of the files we'll be reading from.  If the columns_from_header flag
    # is set, then there's no way of knowing what the columns are until then
    my @column_names = grep { defined }
                       map { $class_meta->column_for_property($_) }
                       $class_meta->all_property_names;

    # FIXME - leaning on the sorted_columns property here means:
    # 1) It's useless when used where the path spec is a directory and
    #    classes have table_names, since each file is likely to have different
    #    columns
    # 2) If we ultimately end up reading from more than one file, all the files
    #    must be sorted in the same way.  It's possible the user has sorted each
    #    file differently, though in practice it would make for a lot of trouble
    my %column_is_sorted_descending;
    my @sorted_column_names = map { if (index($_, '-') == 0) {
                                        my $col = $_;
                                        substr($col, 0, 1, '');
                                        $column_is_sorted_descending{$col} = 1;
                                        $col;
                                    } else {
                                        $_;
                                    }
                              }
                              @{ $self->sorted_columns || [] };
    my %sorted_column_names = map { $_ => 1 } @sorted_column_names;
    my @unsorted_column_names = grep { ! exists $sorted_column_names{$_} } @column_names;

    my @rule_column_names_in_order;    # The order we should perform rule matches on - value is the name of the column in the file
    my @comparison_for_column;         # closures to call to perform the match - same order as @rule_column_names_in_order
    my %rule_column_name_to_comparison_index;

    my(%property_for_column, %operator_for_column, %value_for_column); # These are used for logging

    my $resolve_comparator_for_column_name = sub {
        my $column_name = shift;

        my $property_name = $class_meta->property_for_column($column_name);
        return unless $rule->specifies_value_for($property_name);

        my $operator = $rule->operator_for($property_name)
                     || '=';
        my $rule_value = $rule->value_for($property_name);

        $property_for_column{$column_name} = $property_name;
        $operator_for_column{$column_name} = $operator;
        $value_for_column{$column_name}    = $rule_value;

        my $comp_function = $self->_comparator_for_operator_and_property(
                                   $class_meta->property($property_name),
                                   $operator,
                                   $rule_value);

        push @rule_column_names_in_order, $column_name;
        push @comparison_for_column, $comp_function;
        $rule_column_name_to_comparison_index{$column_name} = $#comparison_for_column;
        return 1;
    };

    my $sorted_columns_in_rule_count;  # How many columns we can consider when trying "the shortcut" for sorted data
    my %column_is_used_in_sorted_capacity;
    foreach my $column_name ( @sorted_column_names ) {
        if (! $resolve_comparator_for_column_name->($column_name)
              and ! defined($sorted_columns_in_rule_count)
        ) {
            # The first time we don't match a sorted column, record the index
            $sorted_columns_in_rule_count = scalar(@rule_column_names_in_order);
        } else {
            $column_is_used_in_sorted_capacity{$column_name} = ' (sorted)';
        }
    }
    $sorted_columns_in_rule_count ||= scalar(@rule_column_names_in_order);

    foreach my $column_name ( @unsorted_column_names ) {
        $resolve_comparator_for_column_name->($column_name);
    }

    # sort them by filename
    my @possible_file_info_list = sort { $a->[0] cmp $b->[0] }
                                    $self->resolve_file_info_for_rule_and_path_spec($rule);

    my $table_name = $class_meta->table_name;
    if (defined($table_name) and $table_name ne '__default__') {
        # Tack the final file name onto the end if the class has a table name
        @possible_file_info_list = map { [ $_->[0] . "/$table_name", $_->[1] ] } @possible_file_info_list;
    }

    my $handle_class = $self->handle_class;
    my $use_quick_read = $handle_class eq 'IO::Handle';
    my $split_regex = $self->_regex();
    my $logger = $self->_logger('UR_DBI_MONITOR_SQL');
    my $record_separator = $self->record_separator;

    my $monitor_start_time = Time::HiRes::time();

    { no warnings 'uninitialized';
      $logger->("\nFILE: starting query covering " . scalar(@possible_file_info_list)." files:\n\t"
                . join("\n\t", map { $_->[0] } @possible_file_info_list )
                . "\nFILTERS: "
                . (scalar(@rule_column_names_in_order)
                     ? join("\n\t", map {
                                     $_ . $column_is_used_in_sorted_capacity{$_}
                                        . " $operator_for_column{$_} "
                                        . (ref($value_for_column{$_}) eq 'ARRAY'
                                                                     ? '[' . join(',',@{$value_for_column{$_}}) .']'
                                                                     : $value_for_column{$_} )
                                   }
                               @rule_column_names_in_order)
                     : '*none*')
                . "\n\n"
              );
    }

    my $query_plan = $self->_resolve_query_plan($rule_template);
    if (@{ $query_plan->{'loading_templates'} } > 1) {
        Carp::croak(__PACKAGE__ . " does not support joins.  The rule was $rule");
    }
    my $loading_template = $query_plan->{loading_templates}->[0];
    my @property_names_in_loading_template_order = @{ $loading_template->{'property_names'} };
    my @column_names_in_loading_template_order = map { $class_meta->column_for_property($_) }
                                                  @property_names_in_loading_template_order;

    my %property_name_to_resultset_index_map;
    my %column_name_to_resultset_index_map;
    for (my $i = 0; $i < @property_names_in_loading_template_order; $i++) {
        my $property_name = $property_names_in_loading_template_order[$i];
        $property_name_to_resultset_index_map{$property_name} = $i;
        $column_name_to_resultset_index_map{$class_meta->column_for_property($property_name)} = $i;
    }

    my @iterator_for_each_file;
    foreach ( @possible_file_info_list ) {
        my $pathname = $_->[0];
        my $property_values_from_path_spec = $_->[1];

        my @properties_from_path_spec = keys %$property_values_from_path_spec;
        my @values_from_path_spec     = values %$property_values_from_path_spec;

        my $pid = $$;    # For tracking whether there's been a fork()
        my $fh = $handle_class->new($pathname);
        unless ($fh) {
            $logger->("FILE: Skipping $pathname because it did not open: $!\n");
            next;   # missing or unopenable files is not fatal
        }

        my $column_names_in_order = $self->_resolve_column_names_from_pathname($pathname,$fh);
        # %value_for_column_name holds subs that return the value for that column.  For values
        # determined from the path resolver, save that value here.  Most other values get plucked out
        # of the line read from the file.  The remaining values are special tokens like $. and __FILE__.
        # These subs are used both for testing whether values read from the data source pass the rule
        # and for constructing the resultset passed up to the Context
        my %value_for_column_name;
        my %column_name_to_index_map;
        my $ordered_column_names_count = scalar(@$column_names_in_order);
        for (my $i = 0; $i < $ordered_column_names_count; $i++) {
            my $column_name = $column_names_in_order->[$i];
            next unless (defined $column_name);
            $column_name_to_index_map{$column_name} = $i;
            $value_for_column_name{$column_name}
                = $self->_create_value_extractor_for_column_name($rule, $column_name, $i);
        }
        foreach ( '$.', '__FILE__' ) {
            $value_for_column_name{$_} = $self->_create_value_extractor_for_column_name($rule, $_, undef);
            $column_name_to_index_map{$_} = undef;
        }
        while (my($prop, $value) = each %$property_values_from_path_spec) {
            my $column = $class_meta->column_for_property($prop);
            $value_for_column_name{$column} = sub { return \$value };
            $column_name_to_index_map{$column} = undef;
        }

        # Convert the column_name keys here to indexes into the comparison list
        my %column_for_this_comparison_is_sorted_descending =
                            map { $rule_column_name_to_comparison_index{$_} => $column_is_sorted_descending{$_} }
                            grep { exists $rule_column_name_to_comparison_index{$_} }
                            keys %column_is_sorted_descending;

        # rule properties that aren't actually columns in the file should be
        # satisfied by the path resolution already, so we can strip them out of the
        # list of columns to test
        my @rule_columns_in_order = map { $column_name_to_index_map{$_} }
                                    grep { exists $column_name_to_index_map{$_} }
                                    @rule_column_names_in_order;
        # And also strip out any items in @comparison_for_column for non-column data
        my @comparison_for_column_this_file = map { $comparison_for_column[ $rule_column_name_to_comparison_index{$_} ] }
                                              grep { exists $column_name_to_index_map{$_} }
                                              @rule_column_names_in_order;

        # Burn through the requsite number of header lines
        my $lines_read = $fh->input_line_number;
        my $throwaway_line_count = $self->header_lines;
        while($throwaway_line_count > $lines_read) {
            $lines_read++;
            scalar($fh->getline());
        }

        my $lines_matched = 0;

        my $log_first_fetch;
        $log_first_fetch = sub {
               $logger->(sprintf("FILE: $pathname FIRST FETCH TIME:  %.4f s\n\n", Time::HiRes::time() - $monitor_start_time));
               $log_first_fetch = \&UR::Util::null_sub;
           };
        my $log_first_match;
        $log_first_match = sub {
               $logger->("FILE: $pathname First match after reading $lines_read lines\n\n");
               $log_first_match = \&UR::Util::null_sub;
           };


        my $next_record;

        # This sub reads the next record (line) from the file, splits the line into
        # columns and puts the data into @$next_record
        my $record_separator_re = qr($record_separator$);
        my $read_record_from_file = sub {

            # Make sure some wise guy hasn't changed this out from under us
            local $/ = $record_separator;

            if ($pid != $$) {
                # There's been a fork() between the original opening and now
                # This filehandle is no longer valid to read from, but tell()
                # should still report the right position
                my $pos = $fh->tell();
                $logger->("FILE: reopening file $pathname and seeking to position $pos after fork()\n");
                my $fh = $handle_class->new($pathname);
                unless ($fh) {
                    $logger->("FILE: Reopening $pathname after fork() failed: $!\n");
                    return;   # behave if we're at EOF
                }
                $fh->seek($pos, 0);  # fast-forward to the old position
                $pid = $$;
            }

            my $line;
            READ_LINE_FROM_FILE:
            while(! defined($line)) {
                # Hack for OSX 10.5.
                # At EOF, the getline below will return undef.  Most builds of Perl
                # will also set $! to 0 at EOF so you can distinguish between the cases
                # of EOF (which may have actually happened a while ago because of buffering)
                # and an actual read error.  OSX 10.5's Perl does not, and so $!
                # retains whatever value it had after the last failed syscall, likely 
                # a stat() while looking for a Perl module.  This should have no effect
                # other platforms where you can't trust $! at arbitrary points in time
                # anyway
                $! = 0;
                $line = $use_quick_read ? <$fh> : $fh->getline();

                if ($line and $line !~ $record_separator_re) {
                    # Was a short read - probably at EOF
                    # If the record_separator is a multi-char string, and the last
                    # characters of $line are the first characters of the
                    # record_separator, it's likely (though not certain) that the right
                    # Thing to do is to remove the partial record separator.
                    for (my $keep_chars = length($record_separator); $keep_chars > 0; $keep_chars--) {
                        my $match_rs = substr($record_separator, 0, $keep_chars);
                        if ($line =~ m/$match_rs$/) {
                            substr($line, 0 - $keep_chars) = '';
                            last;
                        }
                    }
                }

                unless (defined $line) {
                    if ($! && ! $fh->eof()) {
                        redo READ_LINE_FROM_FILE if ($! == EAGAIN or $! == EINTR);
                        Carp::croak("read failed for file $pathname: $!");
                    }

                    # at EOF.  Close up shop and remove this fh from the list
                    #flock($fh,LOCK_UN);
                    $fh = undef;
                    $next_record = undef;

                    $logger->("FILE: $pathname at EOF\n"
                              . "FILE: $lines_read lines read for this request.  $lines_matched matches in this file\n"
                              . sprintf("FILE: TOTAL EXECUTE-FETCH TIME: %.4f s\n\n", Time::HiRes::time() - $monitor_start_time)
                            );
                    return;
                }
            }
            $lines_read++;

            $line =~ s/$record_separator$//;  # chomp, but for any value
            # FIXME - to support record-oriented files, we need some replacement for this...
            $next_record = [ split($split_regex, $line, $ordered_column_names_count) ];
        };

        my $number_of_comparisons = @comparison_for_column_this_file;

        # The file filter iterator.
        # This sub looks at @$next_record and applies the comparator functions in order.
        # If it passes all of them, it constructs a resultset row and passes it up to the
        # multiplexer iterator
        my $file_filter_iterator = sub {
            $log_first_fetch->();

            FOR_EACH_LINE:
            for(1) {
                $read_record_from_file->();

                unless ($next_record) {
                    # Done reading from this file
                    return;
                }

                for (my $i = 0; $i < $number_of_comparisons; $i++) {
                    my $comparison = $comparison_for_column_this_file[$i]->(
                                        $value_for_column_name{ $rule_column_names_in_order[$i] }->($self, $next_record, $fh, $pathname)
                                    );

                    if ( ( ($column_for_this_comparison_is_sorted_descending{$i} and $comparison < 0) or $comparison > 0)
                         and $i < $sorted_columns_in_rule_count
                    ) {
                        # We've gone past the last thing that could possibly match
                        $logger->("FILE: $pathname $lines_read lines read for this request.  $lines_matched matches\n"
                                  . sprintf("FILE: TOTAL EXECUTE-FETCH TIME: %.4f s\n", Time::HiRes::time() - $monitor_start_time));

                        #flock($fh,LOCK_UN);
                        return;

                    } elsif ($comparison) {
                        # comparison didn't match, read another line from the file
                        redo FOR_EACH_LINE;
                    }

                    # That comparison worked... stay in the for() loop for other comparisons
                }
            }
            # All the comparisons return '0', meaning they passed

            $log_first_match->();
            $lines_matched++;
            my @resultset = map { ref($_) ? $$_ : $_ }
                            map { ref($value_for_column_name{$_})
                                        ? $value_for_column_name{$_}->($self, $next_record, $fh, $pathname)
                                        : $value_for_column_name{$_}  # constant value from path spec
                                }
                            @column_names_in_loading_template_order;
            return \@resultset;
        };

        # Higher layers in the loading logic require rows from the data source to be returned
        # in ID order. If the file contents is not sorted primarily by ID, then we need to do
        # the less efficient thing by first reading in all the matching rows in one go, sorting
        # them by ID, then iterating over the results
        unless ($self->file_is_sorted_as_requested($query_plan)) {
            my @resultset_indexes_to_sort = map { $column_name_to_resultset_index_map{$_} }
                                         @{ $query_plan->order_by_columns() };
            $file_filter_iterator
                = $self->_create_iterator_for_custom_sorted_columns($file_filter_iterator, $query_plan, \%column_name_to_resultset_index_map);
        }

        push @iterator_for_each_file, $file_filter_iterator;
    }

    if (! @iterator_for_each_file) {
        return \&UR::Util::null_sub;  # No matching files
    } elsif (@iterator_for_each_file == 1) {
        return $iterator_for_each_file[0];  # If there's only 1 file, no need to multiplex
    }

    my @next_record_for_each_file;   # in the same order as @iterator_for_each_file

    my %column_is_numeric = map { $_->column_name => $_->is_numeric }
                            map { $class_meta->property_meta_for_name($_) }
                            map { $class_meta->property_for_column($_) }
                            map { index($_, '-') == 0 ? substr($_, 1) : $_ }
                            @{ $query_plan->order_by_columns };

    my @resultset_index_sort_sub
            = map { &_resolve_sorter_for( is_numeric => $column_is_numeric{$_},
                                          is_descending => $column_is_sorted_descending{$_},
                                          column_index => $property_name_to_resultset_index_map{$_});
                  }
                  @sorted_column_names;

    my %resultset_idx_is_sorted_descending = map { $column_name_to_resultset_index_map{$_} => 1 }
                                             keys %column_is_sorted_descending;
    my $resultset_sorter = sub {
        my($idx_a,$idx_b) = shift;

        foreach my $sort_sub ( @resultset_index_sort_sub ) {
            my $cmp = $sort_sub->($next_record_for_each_file[$idx_a], $next_record_for_each_file[$idx_b]);
            return $cmp if $cmp;  # done if they're not equal
        }
        return 0;
    };

    # This is the iterator returned to the Context, and knows about all the individual
    # file filter iterators.  It compares the next resultset from each of them and
    # returns the next resultset to the Context
    my $multiplex_iterator = sub {
        return unless @iterator_for_each_file;  # if they're all run out

        my $lowest_slot;
        for(my $i = 0; $i < @iterator_for_each_file; $i++) {
            unless(defined $next_record_for_each_file[$i]) {
                $next_record_for_each_file[$i] = $iterator_for_each_file[$i]->();
                unless (defined $next_record_for_each_file[$i]) {
                    # That iterator is exhausted, splice it out
                    splice(@iterator_for_each_file, $i, 1);
                    splice(@next_record_for_each_file, $i, 1);
                    return unless (@iterator_for_each_file);  # This can happen here if none of the files have matching data
                    redo;
                }
            }

            unless (defined $lowest_slot) {
                $lowest_slot = $i;
                next;
            }

            my $cmp = $resultset_sorter->($lowest_slot, $i);
            if ($cmp > 0) {
                $lowest_slot = $i;
            }
        }

        my $retval = $next_record_for_each_file[$lowest_slot];
        $next_record_for_each_file[$lowest_slot] = undef;
        return $retval;
    };

    return $multiplex_iterator;
}


# Constructors for subs to sort appropriately
sub _resolve_sorter_for {
    my %params = @_;

    my $col_idx = $params{'column_index'};

    my $is_descending = (exists($params{'is_descending'}) && $params{'is_descending'})
                       ||
                        (exists($params{'is_ascending'}) && $params{'is_ascending'});
    my $is_numeric = (exists($params{'is_numeric'}) && $params{'is_numeric'})
                    ||
                     (exists($params{'is_string'}) && $params{'is_string'});
    if ($is_descending) {
        if ($is_numeric) {
            return sub($$) { $_[1]->[$col_idx] <=> $_[0]->[$col_idx] };
        } else {
            return sub($$) { $_[1]->[$col_idx] cmp $_[0]->[$col_idx] };
        }
    } else {
        if ($is_numeric) {
            return sub($$) { $_[0]->[$col_idx] <=> $_[1]->[$col_idx] };
        } else {
            return sub($$) { $_[0]->[$col_idx] cmp $_[1]->[$col_idx] };
        }
    }
}

# Higher layers in the loading logic require rows from the data source to be returned
# in ID order. If the file contents is not sorted primarily by ID, then we need to do
# the less efficient thing by first reading in all the matching rows in one go, sorting
# them by ID, then iterating over the results
sub _create_iterator_for_custom_sorted_columns {
    my($self, $iterator_this_file, $query_plan, $column_name_to_resultset_index_map) = @_;

    my @matching;
    while (my $row = $iterator_this_file->()) {
        push @matching, $row;   # save matches as [id, rowref]
    }

    unless (@matching) {
        return \&UR::Util::null_sub;   # Easy, no matches
    }

    my $class_meta = $query_plan->class_name->__meta__;
    my %column_is_numeric = map { $_->column_name => $_->is_numeric }
                            map { $class_meta->property_meta_for_name($_) }
                            map { $class_meta->property_for_column($_) }
                            map { index($_, '-') == 0 ? substr($_,1) : $_ }
                            @{ $query_plan->order_by_columns };

    my @sorters;
    {   no warnings 'numeric';
        no warnings 'uninitialized';
        @sorters =  map { &_resolve_sorter_for(%$_) }
                    map { my $col_name = $_;
                          my $descending = 0;
                          if (index($col_name, '-') == 0) {
                             $descending = 1;
                             substr($col_name, 0, 1, '');  # remove the -
                          }
                          my $col_idx = $column_name_to_resultset_index_map->{$col_name};
                          { column_index => $col_idx, is_descending => $descending, is_numeric => $column_is_numeric{$col_name} };
                      }
                  @{ $query_plan->order_by_columns };
    }

    my $sort_by_order_by_columns;
    if (@sorters == 1) {
        $sort_by_order_by_columns = $sorters[0];
    } else {
        $sort_by_order_by_columns
            = sub($$) {
                foreach (@sorters) {
                    if (my $rv = $_->(@_)) {
                        return $rv;
                    }
                }
                return 0;
            };
    }
    @matching = sort $sort_by_order_by_columns
                @matching;

    return sub {
                return shift @matching;
            };
}


sub initializer_should_create_column_name_for_class_properties {
    1;
}


# The string used to join fields of a row together when writing
#
# Since the 'delimiter' property is interpreted as a regex in the reading
# code, we'll try to be smart about making a real string from that.
#
# subclasses can override this to provide a different implementation
sub column_join_string {
    my $self = shift;

    my $join_pattern = $self->delimiter;

    # make some common substitutions...
    if ($join_pattern eq '\s*,\s*') {
        # The default...
        return ', ';
    }

    $join_pattern =~ s/\\s*//g;  # Turn 0-or-more whitespaces to nothing
    $join_pattern =~ s/\\t/\t/;  # tab
    $join_pattern =~ s/\\s/ /;   # whitespace

    return $join_pattern;
}


sub _sync_database {
    my $self = shift;
    my %params = @_;

    unless (ref($self)) {
        if ($self->isa("UR::Singleton")) {
            $self = $self->_singleton_object;
        }
        else {
            Carp::croak("Cannot call _sync_database as a class method on a non-singleton class");
        }
    }

$DB::single=1;
    my $changed_objects = delete $params{'changed_objects'};

    my $path_spec = $self->path;

    # First, bin up the changed objects by their class' table_name
    my %objects_for_path;
    foreach my $obj ( @$changed_objects ) {
        my @path = $self->resolve_file_info_for_rule_and_path_spec($obj, $path_spec);
        if (!@path) {
            $self->error_message("Couldn't resolve destination file for object "
                                  .$obj->class." ID ".$obj->id.": ".Data::Dumper::Dumper($obj));
            return;
        } elsif (@path > 1) {
            $self->error_message("Got multiple filenames when resolving destination file for object "
                                 . $obj->class." ID ".$obj->id.": ".join(', ', @path));
        }
        $objects_for_path{ $path[0]->[0] } ||= [];
        push @{ $objects_for_path{ $path[0]->[0] } }, $obj;
    }

    my %objects_for_pathname;
    foreach my $path ( keys %objects_for_path ) {
        foreach my $obj ( @{ $objects_for_path{$path} } ) {
            my $class_meta = $obj->__meta__;
            my $table_name = $class_meta->table_name;
            my $pathname = $path;
            if (defined($table_name) and $table_name ne '__default__') {
                $pathname .= '/' . $table_name;
            }
            $objects_for_pathname{$pathname} ||= [];
            push @{ $objects_for_pathname{$pathname} }, $obj;
        }
    }

    my %column_is_sorted_descending;
    my @sorted_column_names =   map { if (index($_, '-') == 0) {
                                        my $s = $_;
                                        substr($s, 0, 1, '');
                                        $column_is_sorted_descending{$s} = $s;
                                      } else {
                                        $_;
                                      }
                                    }
                                @{ $self->sorted_columns() || [] };

    my $handle_class = $self->handle_class;
    my $use_quick_read = $handle_class->isa('IO::Handle');

    my $join_string = $self->column_join_string;
    my $record_separator = $self->record_separator;
    my $split_regex = $self->_regex();
    local $/;   # Make sure some wise guy hasn't changed this out from under us
    $/ = $record_separator;

    my $logger = $self->_logger('UR_DBI_MONITOR_SQL');
    my $total_save_time = Time::HiRes::time();
    $logger->("FILE: Saving changes to ".scalar(keys %objects_for_pathname) . " files:\n\t"
                . join("\n\t", keys(%objects_for_pathname)) . "\n\n");

    foreach my $pathname ( keys %objects_for_pathname ) {
        my $use_quick_rename;
        my $containing_directory = File::Basename::dirname($pathname);
        unless (-d $containing_directory) {
            File::Path::mkpath($containing_directory);
        }
        if (-w $containing_directory) {
            $use_quick_rename = 1;
        } elsif (! -w $pathname) {
            Carp::croak("Cannot save to file $pathname: Neither the directory nor the file are writable");
        }

        my $read_fh = $handle_class->new($pathname);

        # Objects going to the same file should all be of a common class
        my $class_meta = $objects_for_pathname{$pathname}->[0]->__meta__;

        my @property_names_that_are_sorted = map { $class_meta->property_for_column($_) }
                                            @sorted_column_names;
        # Returns true of the passed-in object has a change in one of the sorted columns
        my $object_has_changed_sorted_column = sub {
                my $obj = shift;
                foreach my $prop ( @property_names_that_are_sorted ) {
                    if (UR::Context->_get_committed_property_value($obj, $prop) ne $obj->$prop) {
                        return 1;
                    }
                }
                return 0;
        };

        my $column_names_in_file = $self->_resolve_column_names_from_pathname($pathname, $read_fh);
        my $column_names_count = @$column_names_in_file;
        my %column_name_to_index;
        for (my $i = 0; $i < @$column_names_in_file; $i++) {
            $column_name_to_index{$column_names_in_file->[$i]} = $i;
        }
        # This lets us take a hash slice of the object and get a row for the file
        my @property_names_in_column_order = map { $class_meta->property_for_column($_) }
                                             @$column_names_in_file;

        my %column_name_is_numeric = map { $_->column_name => $_->is_numeric }
                                     map { $class_meta->property_meta_for_name($_) }
                                     map { $class_meta->property_for_column($_) }
                                     @$column_names_in_file;

        my $insert = [];
        my $update = {};
        my $delete = {};
        foreach my $obj ( @{ $objects_for_pathname{$pathname} } ) { 
            if ($obj->isa('UR::Object::Ghost')) {
                # This should be removed from the file
                my $original = $obj->{'db_committed'};
                my $line = join($join_string, @{$original}{@property_names_in_column_order}) . $record_separator;
                $delete->{$line} = $obj;

            } elsif ($obj->{'db_committed'}) {
                # this is a changed object
                my $original = $obj->{'db_committed'};

                if ($object_has_changed_sorted_column->($obj)) {
                    # One of hte sorted columns has changed.  Model this as a delete and insert
                    push @$insert, [ @{$obj}{@property_names_in_column_order} ];
                    my $line = join($join_string, @{$original}{@property_names_in_column_order}) . $record_separator;
                    $delete->{$line} = $obj;
                } else {
                    # This object is changed since it was read in the file
                    my $original_line = join($join_string, @{$original}{@property_names_in_column_order}) . $record_separator;
                    my $changed_line = join($join_string, @{$obj}{@property_names_in_column_order}) . $record_separator;
                    $update->{$original_line} = $changed_line;
                }

            } else {
                # This object is new and should be added to the file
                push @$insert, [ @{$obj}{@property_names_in_column_order} ];
            }
        }

        my %column_is_sorted_descending;
        my @sorted_column_names =   map { if (index($_, '-') == 0) {
                                              my $s = $_;
                                              substr($s, 0, 1, '');
                                              $column_is_sorted_descending{$s} = $s;
                                            } else {
                                              $_;
                                            }
                                          }
                                @{ $self->sorted_columns() || [] };

        my $row_sort_sub;
        if (@sorted_column_names) {
            my @comparison_subs = map { &_resolve_sorter_for(is_numeric => $column_name_is_numeric{$_},
                                                             is_descending => $column_is_sorted_descending{$_},
                                                             column_index => $column_name_to_index{$_})
                                      }
                                  @sorted_column_names;

            $row_sort_sub = sub ($$) {
                    foreach my $comparator ( @comparison_subs ) {
                        my $cmp = $comparator->($_[0], $_[1]);
                        return $cmp if $cmp;
                    }
                    return 0;
            };

            # Put the rows-to-insert in sorted order
            my @insert_sorted = sort $row_sort_sub @$insert;
            $insert = \@insert_sorted;
        }

        my $write_fh = $use_quick_rename
                        ? File::Temp->new(DIR => $containing_directory)
                        : File::Temp->new();
        unless ($write_fh) {
            Carp::croak("Can't save changes for $pathname: Can't create temporary file for writing: $!");
        }
       
        my $monitor_start_rime = Time::HiRes::time();
        my $time = time();
        $logger->(sprintf("\nFILE: SYNC DATABASE AT %s [%s].  Started transaction for %s to temp file %s\n",
                          $time, scalar(localtime($time)), $pathname, $write_fh->filename));

        # Write headers to the new file
        for (my $i = 0; $i < $self->header_lines; $i++) {
            my $line = $use_quick_read ? <$read_fh> : $read_fh->getline();
            $write_fh->print($line);
        }

        my $line;
        READ_A_LINE:
        while(1) {
            unless ($line) {
                $line = $use_quick_read ? <$read_fh> : $read_fh->getline();
                last unless defined $line;
            }

            if (@sorted_column_names and scalar(@$insert)) {
                # There are sorted things waiting to insert
                my $chomped = $line;
                $chomped =~ s/$record_separator$//;  # chomp, but for any value
                my $row = [ split($split_regex, $chomped, $column_names_count) ];
                my $cmp = $row_sort_sub->($row, $insert->[0]);
                if ($cmp > 0) {
                    # write the object's data
                    no warnings 'uninitialized';  # Some of the object's data may be undef
                    my $new_row = shift @$insert;
                    my $new_line = join($join_string, @$new_row) . $record_separator;

                    $logger->("FILE: INSERT >>$new_line<<\n");

                    $write_fh->print($new_line);
                    # Don't undef the last line read, meaning it could still be written to the output...
                    next READ_A_LINE;
                }
            }

            if (my $obj = delete $delete->{$line}) {
                $logger->("FILE: DELETE >>$line<<\n");

            } elsif (my $changed = delete $update->{$line}) {
                $logger->("FILE: UPDFATE replace >>$line<< with >>$changed<<\n");
                $write_fh->print($changed);

            } else {
                # This line form the file was unchanged in the app
                $write_fh->print($line);
            }
            $line = undef;
        }

        if (keys %$delete) {
            $self->warning_message("There were " . scalar( keys %$delete)
                                   . " deleted " . $class_meta->class_name
                                   . " objects that did not match data in file $pathname");
        }
        if (keys %$update) {
            $self->warning_message("There were " . scalar( keys %$delete)
                                   . " updated " . $class_meta->class_name
                                   . " objects that did not match data in file $pathname");
        }

        # finish out by writing the rest of the new data
        foreach my $new_row ( @$insert ) {
            no warnings 'uninitialized';   # Some of the object's data may be undef
            my $new_line = join($join_string, @$new_row) . $record_separator;
            $logger->("FILE: INSERT >>$new_line<<\n");
            $write_fh->print($new_line);
        }

        my $changed_objects = $objects_for_pathname{$pathname};
        unless ($self->_set_specified_objects_saved_uncommitted( $changed_objects )) {
            Carp::croak("Error setting objects to a saved state after syncing");
        }
        # These closures will keep $write_fh in scope and delay their removal until
        # commit() or rollback().  Call these with no args to commit, and one arg (doesn't
        # matter what) to roll back
        my $commit = $use_quick_rename 
                    ? sub {
                            if (@_) {
                                $self->_set_specified_objects_saved_rolled_back($changed_objects);
                            } else {
                                my $temp_filename = $write_fh->filename;
                                $logger->("FILE: COMMIT rename $temp_filename => $pathname\n");
                                unless (rename($temp_filename, $pathname)) {
                                    $self->error_message("Can't rename $temp_filename to $pathname: $!");
                                    return;
                                }
                                $self->_set_specified_objects_saved_committed($changed_objects);
                            }
                            return 1;
                        }
                    : 
                      sub {
                            if (@_) {
                                $self->_set_specified_objects_saved_rolled_back($changed_objects);
                            } else {
                                my $temp_filename = $write_fh->filename;
                                $logger->("FILE: COMMIT copy " . $temp_filename . " => $pathname\n");
                                my $read_fh = IO::File->new($temp_filename);
                                unless ($read_fh) {
                                    $self->error_message("Can't open file $temp_filename for reading: $!");
                                    return;
                                }
                                my $copy_fh = IO::File->new($pathname, 'w');
                                unless ($copy_fh) {
                                    $self->error_message("Can't open file $pathname for writing: $!");
                                    return;
                                }

                                while(<$read_fh>) {
                                    $copy_fh->print($_);
                                }
                                $copy_fh->close();
                                $read_fh->close();
                                $self->_set_specified_objects_saved_committed($changed_objects);
                            }
                            return 1;
                        };

        $write_fh->close();

        $self->{'__saved_uncommitted'} ||= [];
        push @{ $self->{'__saved_uncommitted'} }, $commit;

        $time = time();
        $logger->("\nFILE: SYNC DATABASE finished ".$write_fh->filename . "\n");
    }

    $logger->(sprintf("Saved changes to %d files in %.4f s\n",
                      scalar(@{ $self->{'__saved_uncommitted'}}), Time::HiRes::time() - $total_save_time));
    return 1;
}

sub commit {
    my $self = shift;
    if (! ref($self) and $self->isa('UR::Singleton')) {
        $self = $self->_singleton_object;
    }

    if ($self->{'__saved_uncommitted'}) {
        foreach my $commit ( @{ $self->{'__saved_uncommitted'}}) {
            $commit->();
        }
    }
    delete $self->{'__saved_uncommitted'};

    return 1;
}


sub rollback {
    my $self = shift;
    if (! ref($self) and $self->isa('UR::Singleton')) {
        $self = $self->_singleton_object;
    }

    if ($self->{'__saved_uncommitted'}) {
        foreach my $commit ( @{ $self->{'__saved_uncommitted'}}) {
            $commit->('rollback');
        }
    }
    delete $self->{'__saved_uncommitted'};

    return 1;
}


1;

__END__

=pod

=head1 NAME

UR::DataSource::Filesystem - Get and save objects to delimited text files

=head1 SYNOPSIS

  # Create an object for the data file
  my $people_data = UR::DataSource::Filesystem->create(
      columns => ['person_id','name','age','street_address'],
      sorted_columns => ['age','person_id'],
      path => '/var/lib/people/$state/$city/people.txt',
      delimiter        => "\t", # between columns in the file
      record_separator => "\n", # between lines in the file
  );

  # Define an entity class for the people in the file
  class MyProgram::Person {
      id_by => 'person_id',
      has => [
          name           => { is => 'String' },
          age            => { is => 'Number' },
          street_address => { is => 'String' },
          city           => { is => 'String' },
          state          => { is => 'String' },
      ],
      data_source_id => $people_data->id,
  };

  # Get all people that live in any city named Springfield older than 40
  my @springfielders = MyProgram::Person->get(city => 'Springfield', 'age >' => 40);

=head1 DESCRIPTION

A Filesystem data source object represents one or more files on the filesystem.
In the simplest case, the object's 'path' property names a file that stores
the data.  

=head2 Properties

These properties determine the configuration for the data source.

=over 4

=item path <string>

path is a string representing the path to the files.  Besides just being a
simple pathname to one file, the string can also be a specification of
many similar files, or a directory containing multiple files.  See below
for more information about 'path'

=item record_separator <string>

The separator between lines in the file.  This gets stored in $/ before calling
getline() to read data.  The default record_separator is "\n".

=item delimiter <string>

The separator between columns in the file.  It is used to construct a regex
with qr() to split() a line into a list of values.  The default delimiter
is '\s*,\s*', meaning that the file is separated by commas.  Another common
value would be "\t" for tabs.

=item columns <ARRAY>

A listref of column names in the file.  Just as SQL tables have columns,
Filesystem files also have named columns so the system knows how to read
the file data into object properties.  A Filesystem data source does
not need to specify named columns if the 'columns_from_header' property
is true.

Classes that use the Filesystem data source attach their properties to the
data source's columns via the 'column_name' metadata.  Besides the columns
directly named in the 'columns' list, two additional column-like tokens may
be used as a column_name: '__FILE__' and '$.'.  __FILE__ means the object's
property will hold the name of the file the data was read from.  $. means the
value will be the input line number from the file.  These are useful when
iterating over the contents of a file.  Since these two fake columns are
always considered "sorted", it makes reading from the file faster in some
cases.  See the 'sorted_columns' discussion below for more information.

=item sorted_columns <ARRAY>

A listref of column names that the file is sorted by, in the order of the
sorting.  If a column is sorted in descending order, put a minus (-) in front
of the name.  If the file is sorted by multiple columns, say first by last_name
and then by first_name, then include them both:

  sorted_columns => ['last_name','first_name']

The system uses this information to know when to stop reading if a query is
done on a sorted column.  It's also used to determine whether a query done
on the data source matches the sort order of the file.  If not, then the
data must be gathered in two passes.  The first pass finds records in the
file that match the filter.  After that, the matching records are sorted
in the same way the query is requesting before returning the data to the
Context.

The Context expects incoming data to always be sorted by at least the
class' ID properties.  If the file is unsorted and the caller wants to be
able to iterate over the data, then it is common to have the class' ID
properties specified like this:

  id_by => [
      file => { is => 'String', column_name => '__FILE__' },
      line => { is => 'Integer', column_name => '$.' },
  ]

Otherwise, it will need to read in the whole file and sort the contents
before returning the first row of data from its iterator.

=item columns_from_header <boolean>

If true, the system will read the first line of the file to determine what the
column names are.

=item header_lines <integer>

The number of lines at the top of the file that do not contain entity data.
When the file is opened, this number of lines are skipped before reading
data.  If the columns_from_header flag is true, the header_lines value should
be at least 1.

=item handle_class <string>

Which class to use for reading and writing to the file.  The default is
IO::File.  Any other value must refer to a class that has the same interface
as IO::File, in particular: new, input_line_number, getline, tell, seek and
print.

=back

=head2 Path specification

Besides referring to just one file on the filesystem, the path spec is a
recipe for finding files in a directory tree.  If a class using a Filesystem
data source does not have 'table_name' metadata, then the path specification
must resolve to file names.  Alternatively, classes may specify their
'table_name' which is interpreted as a file within the directory indicated
by the path specification.

Three kinds of special tokens can also appear in a file spec:

=over 4

=item $property

When querying, the system will extract the value (or values, for an in-clause)
of $property from the BoolExpr when constructing the pathname.  If the
BoolExpr does not have a value for that property, then the system will do a
shell glob to find the possible values.  For example, given this path spec
and query:

  path => '/var/people/$state/$city/people.txt'
  my @people = MyProgram::People->get(city => 'Springfield', 'age >' => 40);

it would find the data files using the glob expression

  /var/people/*/Springfield/people.txt

It also knows that any objects coming from the file

  /var/people/CA/Springfield/people.txt

must have the value 'CA' for their 'state' property, even though that
information is not in the contents of the file.

When committing changes back to the file, the object property values are
used to determine which file it should be saved to.

The property name can also be wrapped in braces:

  /var/people/${state}_US/city_${city}/people.txt

=item &method

The replacement value is resolved by calling the named method on the subject
class of the query.  The method is called like this:

  $replacement = $subject_class->$method( $boolexpr_or_object);

During a query, the method is passed a BoolExpr; during a commit, the method
is passed an object.  It must return a string.

The method name can also be wrapped in braces:

  /&{resolve_prefix}.dir/people.txt

=item *, ?

Literal shell glob wildcards are honored when finding files, but their values
are not used to supply values to objects.

=back

=head2 Environment Variables

If the environment variable $UR_DBI_MONITOR_SQL is true, then the Filesystem
data source will print information about the queries it runs.

=head1 INHERITANCE

  UR::DataSource

=head1 SEE ALSO

UR, UR::DataSource

=cut
