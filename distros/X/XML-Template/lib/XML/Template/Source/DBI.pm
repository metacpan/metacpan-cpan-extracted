###############################################################################
# XML::Template::Source::DBI
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Source::DBI;
use base 'XML::Template::Base';


use base 'DBIx::Wrap';


=pod

=head1 NAME

XML::Template::DBI - A module for handling DBI sources.

=head1 SYNOPSIS

This module is used to handle access to DBI sources from XML::Template.

=head2 CONSTRUCTOR

  my $dbi = XML::Template::Source::DBI->new ($sourcename)
    || die XML::Template::Source::DBI->error ();

Given the source name, the constructor method C<new> retrieves source 
information from the XML::Template configuration file, creates a new DBI
connection to a database, and returns an object with which you can make 
database queries.

=cut

sub new {
  my $proto      = shift;
  my $sourcename = shift;

  my $class = ref ($proto) || $proto;

  my $self = $class->SUPER::new ();

  # Get source info.
  my $sourceinfo = $self->get_source_info ($sourcename);

  # Get password.
  open (PWDFILE, $sourceinfo->{pwdfile})
    || return $proto->error ('DBI', "Could not open password file '$sourceinfo->{pwdfile}' for data source '$sourcename': $!");
  my $pwd = <PWDFILE>;
  chomp $pwd;
  close PWDFILE;

  my $source = DBIx::Wrap->new (DSN		=> $sourceinfo->{dsn},
                                User		=> $sourceinfo->{user},
                                Password	=> $pwd)
    || return $proto->error ('DBI', DBIx::Wrap->error);
  bless ($source, $class);

  return $source;
}

=pod

=head1 PUBLIC METHODS

=head2 is_modified

  my $is_modified = $source->is_modified ($cache_mtime, $table);

This method returns C<1> if the table specified by the second parameter
has changed since C<cache_mtime>, the first parameter, or C<0> otherwise.  
C<cache_mtime> must be in unix time format.

=cut

sub is_modified {
  my $self = shift;
  my ($cache_mtime, $table) = @_;

  my ($table_status) = $self->show (Action	=> 'table_status',
                                    Table	=> $table,
                                    Format	=> 'unix');
#warn "$table: $table_status->{Update_time} <> $cache_mtime\n";
  return ($table_status->{Update_time} > $cache_mtime) ? 1 : 0;
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
