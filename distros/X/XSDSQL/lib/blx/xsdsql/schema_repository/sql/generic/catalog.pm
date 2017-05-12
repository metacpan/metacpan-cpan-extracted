package blx::xsdsql::schema_repository::sql::generic::catalog;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);
use base qw( blx::xsdsql::ios::debuglogger);

sub _am { croak "abstract method\n"; }


sub _new {
	my ($class,%params)=@_;
	return bless \%params,$class;
}

sub new { _am;  }


sub get_name_maxsize { _am;  }

sub get_comment_maxsize { _am;  }

sub get_begin_comment { _am; }

sub get_end_comment {	_am;  }

sub command_terminator { _am;  }

sub get_max_columns_view { _am;  }

sub get_max_joins_view { _am; }

sub get_max_columns_table { _am; }

sub is_support_views { _am }


sub comment {
	my $self=shift;
	my $c=join('',grep(defined $_,@_));
	return $c if $c eq '';
	return $self->get_begin_comment().' '.substr($c,0,$self->get_comment_maxsize).' '.$self->get_end_comment();
}

sub get_comment {
	my ($self,%params)=@_;
	my $c=$self->get_attrs_value(qw(COMMENT));
	return '' unless $c;
	return $self->comment($c)
}




1;

__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::generic::catalog -  a catalog is a class with include the common methods from table class  and column class (for example the   max length of  a dictionary database name)

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::generic::catalog

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions

new - constructor

    PARAMS:
        COMMENT - an associated comment


get_name_maxsize  - return the max_size of a database dictionary name


get_comment_maxsize  - return the max_size of a comment


get_begin_comment  - return the characters that it's interpreted as  a begin comment


get_end_comment - return the characters that it's interpreted as  a end comment


command_terminator  - return the characters that it's interpreted as a command terminator


get_max_columns_view - return the max number of columns into a view


get_max_joins_view  - return the max number of joins into a view


is_support_views - return true if database support views with left join


comment  - return a text enclosed by  comment symbols

    the arguments are a text


get_comment - return a text value of the COMMENT attribute enclosed by comment characters


=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx:.xsdsql::generator for generate the schema of the database and blx::xsdsql::parser
for parse a xsd file (schema file)


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


