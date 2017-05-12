package Xymon::DB::Schema::virtAssetNo;


use base qw(DBIx::Class::Core);


  __PACKAGE__->table_class('DBIx::Class::ResultSource::View');
  


  __PACKAGE__->table('virtAssetNo');
  __PACKAGE__->result_source_instance->is_virtual(1);
  __PACKAGE__->result_source_instance->view_definition(
      "SELECT distinct assetno as assetno from host"
      );
  __PACKAGE__->add_columns(qw/assetno/);
  __PACKAGE__->result_source_instance->set_primary_key('assetno');
  __PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::HashRef' );
  
  
  1;

=head1 NAME

Xymon::DB::virtassetno - Virtual Assetno Schema


=head1 SYNOPSIS

	use Xymon::DB::Schema;
  

=head1 DESCRIPTION

see Xymon::DB::Schema


=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Xymon::DB::Schema, perl(1)

=cut