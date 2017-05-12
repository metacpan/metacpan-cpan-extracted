package Xymon::DB::Schema::luHobbitPage;
use base qw(DBIx::Class::Core);


  __PACKAGE__->table('luHobbitPage');
  __PACKAGE__->add_columns(qw/Page Architecture/);
  __PACKAGE__->set_primary_key(qw/Page/);
  __PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::HashRef' );
  __PACKAGE__->has_many( HobbitPages => 'Xymon::DB::Schema::HobbitPages', 'Page' );
  1;
  
  
=head1 NAME

Xymon::DB::luHobbitPage - luHobbitPage Schema


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