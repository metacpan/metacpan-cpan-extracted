package Xymon::DB::Schema::host;


use base qw(DBIx::Class::Core);


  __PACKAGE__->table('host');
  __PACKAGE__->add_columns(qw/hostname location assetno serialno contractno 
  								rack posn opsys opsysversion brand model storage 
  								cputype cpucount cpuspeed ramsize console alom switch 
  								description owner hobbit ServiceClass HobbitOptions backupyn
  								decommission connectedto controller assettype recordstatus 
  								supportgroup dependancies InstalledApps maintamt 
  								assetvalue installdate maintdate maitstartdate 
  								poweruporder verifystatus architecture backupserver 
  								backupstartdate masterserver routerip locationrouter 
  								nonessential cremyn/);
  __PACKAGE__->set_primary_key('hostname');
  __PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::HashRef' );
  __PACKAGE__->has_many( applications => 'Xymon::DB::Schema::Application', 'hostname' );
  __PACKAGE__->has_many( hobbitpages => 'Xymon::DB::Schema::HobbitPages', 'Hostname' );
  __PACKAGE__->belongs_to( LuLocation => 'Xymon::DB::Schema::LuLocation', 'location');
  1;

=head1 NAME

Xymon::DB::host - host Schema


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