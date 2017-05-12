package DataAccess::Broker;

use strict;
use warnings;

sub new {
    my ( $class, $href ) = @_;
    my $self->{super_log} = Log::Log4perl->get_logger(__PACKAGE__);
    bless $self, $class;

}

sub get_arg_dbc {
    my ( $self, $key, $value_aref ) = @_;
    my %arg_sel = (

        # key   table name    arg1    arg2
        mainform_data => [
            'Country',
            undef,
            { order_by => 'country' }
        ],
        langue => [
            'Langue',
             undef,
             {order_by => 'langue' }
         ],
        langues => ['Langue' ],
        speaks  => ['Speak' ],
        subform_data => [
            'Speak', 
            { countryid => $value_aref->[0] },
            { columns => ['countryid', 'langid', {langid1 => 'langid'}]}, 
        ],
        grid_data => [
            'Speak',
             { langid    => $value_aref->[0],
                countryid => { '!=' => $value_aref->[1] },
            },
             { columns => ['countryid', 'langid', {langid1 => 'langid'}]},
        ],
        countries => [ 'Country' ],

    );

    return $arg_sel{$key};
}

sub get_arg_rdb {
    my ( $self, $key, $value_aref ) = @_;

    my %arg_sel = (

        # key   table name    arg1    arg2
        mainform_data => [ 'Rdb::Country', { sort_by => 'country' } ],
        langue  => [ 'Rdb::Langue', { sort_by => 'langue' } ],
        langues => [ 'Rdb::Langue'],
        speaks  => [ 'Rdb::Speak' ],
        #the 3 arg is used in RdbDM->new not in the Manager->get_objects method
        subform_data => [ 'Rdb::Speak', { query => [ countryid => { eq => $value_aref->[0] } ] }, {alias=>{langid=>[qw(langid1)]} }],
        grid_data =>  [ 'Rdb::Speak', { query => [
                    langid    => { eq => $value_aref->[0] },
                    countryid => { ne => $value_aref->[1] }
                ]
            },
        ],
        countries => ['Rdb::Country'],
    );
    return $arg_sel{$key};
}

sub get_arg_sqla {
    my ( $self, $key, $value_aref ) = @_;
    # primary_key  => 'countryid',
    my %arg_sel = (

        # key   table name    arg1    arg2
        $key => {
            select_param => {
                -where => { -bool => "1=1" },
                -from  => $key
            },
        },
        mainform_data => {
            select_param => {
                -from     => "countries",
                -where    => "1=1",
                -order_by => [qw(+country)]
            }
        },
        langue => {
            select_param => {
                -from     => "langues",
                -where    => "1=1",
                -order_by => [qw(+langue)]
            },
        },

        subform_data => {
            select_param => {
                -columns => [qw(langid langid|langid1 countryid)],
                -from  => "speaks",
                -where => { countryid => $value_aref->[0] },

            },
        },
        grid_data => {
            select_param => {
                -from  => 'speaks',
                -where => {
                    langid    => $value_aref->[0],
                    countryid => { '!=' => $value_aref->[1] }
                },
               -columns => [qw(langid langid|langid1 countryid)],
            },
        },
    );

    return $arg_sel{$key};
}

sub get_arg_dbi {
    my ( $self, $key, $value_aref ) = @_;
    my %arg_sel = (
    $key => {
        sql=>{
            select => "*",
            from => $key,
            where => "1=1",
        },
    },
    mainform_data => {
            ai_primary_key  => ['countryid'],
            sql =>{
                 select   => "countryid, country, mainlangid",
            from     => "countries",
            where    => "1=1",
            order_by => "country",
            
            },
        },
  langue => {
    ai_primary_key => ['langid'],
        sql            => {
            select   => "langid, langue",
            from     => "langues",
            where    => "1=1",
            order_by => "langue",
        },
  },
  subform_data => {
  ai_primary_key => [qw(speaksid)],
        sql            => {
            select      => "speaksid, countryid, langid, langid as langid1",
            from        => "speaks",
            where       => "countryid = ?",
            bind_values => [ $value_aref->[0] ],
        },
    ro_fields =>[qw(langid1)],
  
  },
  grid_data => {
    ai_primary_key => [qw(speaksid)],
        sql            => {
            select      => "speaksid, countryid, langid, langid as langid1",
            from        => "speaks",
            where       => "langid = ? and countryid != ?",
            bind_values => [ $value_aref->[0], $value_aref->[1] ],
  
         },
         ro_fields =>[qw(langid1)],
  },
    );
    return $arg_sel{$key};
}

1;

__END__

=head1 NAME

DataAccess::Broker
DataAccess::[xxx]::Service

 - Paires of modules that encapsulate the xxxDataManager calls. The same form module is therefore used instead of a form module for each method of access.
-  [xxx] can be any of Sqla, Dbc, Dbi, Rdb depending on the model used to access the database.

=head1 VERSION

See Version in L<Wx::Perl::DbLinker>

=head1 SYNOPSIS

In the script that start the example

   use DataAccess::Dbi::Service;
   my $dbh    = DBI->connect("dbi:SQLite:dbname=./data/ex1",
   my $data = DataAccess::Dbi::Service->new({dbh =>  $dbh });
    my $app = Forms::Langues->new(
        { xrcfolder => "./xrc", data_broker => $data } );

In the form module

    my $dman = $self->{data_broker}->get_DM_for('mainform');

    sub on_field_changed {
         my ( $self, $value ) = @_;
         $self->{data_broker}->query_DM( $self->{subform}->get_data_manager,'subform', [$value]);


    }

Where mainform subform are keys that return the arguments for creating or querrying a DbiDataManager instance

