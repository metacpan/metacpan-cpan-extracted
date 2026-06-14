package Type::Guess::Role::SQL::SQLite;

use Moo::Role;

sub to_sql {
    my $self = shift;
    my $type = ref $self->type ? $self->type->name : $self->type;
    return "INTEGER"                                        if $type eq "Int";
    return "DATETIME"                                       if $self->type eq 'DateTime';
    return "FLOAT"                                          if $type eq "Num";
    return sprintf "VARCHAR(%d)", $self->length             if $type eq "Str" && $self->length < 1024;
    return "TEXT";
}

1;

__DATA__
    return "DATETIME"                                       if $type eq "DateTime";

