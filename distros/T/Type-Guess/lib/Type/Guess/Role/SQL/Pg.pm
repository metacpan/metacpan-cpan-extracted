package Type::Guess::Role::SQL::Pg;

use Moo::Role;

sub to_sql {
    my $self = shift;
    my $type = ref $self->type ? $self->type->name : $self->type;

    return $self->integer_chars > 9 ? "BIGINT" : "INTEGER"              if $type eq "Int";
    return "TIMESTAMP"                                                  if $self->type eq 'DateTime';
    return sprintf "DECIMAL(%d,%d)", $self->length, $self->precision    if $type eq "Num";
    return sprintf "VARCHAR(%d)", $self->length                         if $type eq "Str" && $self->length < 1024;
    return "TEXT";
}

1;


=head2 TIMESTAMP

Postgres distinguishes TIMESTAMP (no timezone) and TIMESTAMP WITH TIME ZONE.
Type::Guess emits TIMESTAMP by default. If your application is timezone-aware,
cast manually or compose a role that overrides to_sql for DateTime to return
TIMESTAMP WITH TIME ZONE.

=cut

