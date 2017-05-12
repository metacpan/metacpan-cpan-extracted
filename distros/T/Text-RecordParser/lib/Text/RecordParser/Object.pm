package Text::RecordParser::Object;

use strict;
use warnings;
use version;

use base qw( Class::Accessor );

our $VERSION = version->new('1.4.0');

sub new {
    my ( $class, $field_names, $self ) = @_;
    $class->mk_ro_accessors( @$field_names );
    bless $self, $class;
    return $self;
}

1;

__END__

# ----------------------------------------------------------------

=pod

=head1 NAME

Text::RecordParser::Object - read delimited text files as objects

=head1 SYNOPSIS

  my $o = $p->fetchrow_object;
  my $name = $o->name;

=head1 METHOD

=head2 new

Just call "fetchrow_object" on a Text::RecordParser object to instantiate
an object.

=head1 DESCRIPTION

This module extends the idea of how you interact with delimited text
files, allowing you to enforce field names and identify field aliases
easily.  That is, if you are using the "fetchrow_hashref" method to
read each line, you may misspell the hash key and introduce a bug in
your code.  With this module, Perl will throw an error if you attempt
to read a field not defined in the file's headers.  Additionally, any
defined field aliases will be created as additional accessor methods.

As much as I like the full encapsulation of inside-out objects (e.g.,
as described in _Perl Best Practies_ by Damian Conway and provided by 
Class::Std), I couldn't figure out a way to dynamically create the 
class at runtime.  Besides, I figure this interface is only for those
who want to use the overhead of objects to enforce policy.  If you use
this module and still access the hash underneath the object, I can't 
really help you.

=head1 SEE ALSO

Class::Accessor.

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-10 Ken Youens-Clark.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

=cut
