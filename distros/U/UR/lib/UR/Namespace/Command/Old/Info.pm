package UR::Namespace::Command::Old::Info;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has => [
        subject => {
            is_optional => 1,
            is_many => 1,
            shell_args_position => 1
        }
    ]
);


sub help_brief {
    "Outputs description(s) of UR entities such as classes and tables to stdout";
}

sub is_sub_command_delegator { 0;}


sub execute {
my($self, $params) = @_;

    my $namespace = $self->namespace_name;
    # FIXME why dosen't require work here?
    eval "use  $namespace";
    if ($@) {
        $self->error_message("Failed to load module for $namespace: $@");
        return;
    }

    # Loop through each command line parameter and see what kind of thing it is
    # create a view and display it
    my @class_aspects = qw( );
    my @table_aspects = qw( );
    my %already_printed;

    my %views;
    foreach my $item ( $self->subject ) {
        my @meta_objs = ();

        if ($item eq $namespace or $item =~ m/::/) {
            # Looks like a class name?  
            my $class_meta = eval { UR::Object::Type->get(class_name => $item)};
            push(@meta_objs, $class_meta) if $class_meta;

        } else {

            push @meta_objs, ( UR::DataSource::RDBMS::Table->get(table_name => $item, namespace => $namespace) );
            push @meta_objs, ( UR::DataSource::RDBMS::Table->get(table_name => uc($item), namespace => $namespace) );
            push @meta_objs, ( UR::DataSource::RDBMS::Table->get(table_name => lc($item), namespace => $namespace) );

            push @meta_objs, map { ( $_ and UR::DataSource::RDBMS::Table->get(table_name => $_->table_name, namespace => $namespace) ) }
                                 ( UR::DataSource::RDBMS::TableColumn->get(column_name => $item, namespace => $namespace),
                                   UR::DataSource::RDBMS::TableColumn->get(column_name => uc($item), namespace => $namespace),
                                   UR::DataSource::RDBMS::TableColumn->get(column_name => lc($item), namespace => $namespace)
                                 );

        }
    
        ## A property search requires loading all the classes first, at least until class
        ## metadata is in the meta DB
        # Something is making this die, so I'll comment it out for now
        #$namespace->get_material_class_names;
        #my @properties = UR::Object::Property->get(property_name => $item);
        #next unless @properties;
        #push @meta_objs, UR::Object::Type->get(class_name => [ map { $_->class_name }
        #                                                            @properties ]);

        foreach my $obj ( @meta_objs ) {
            next unless $obj;
            next if ($already_printed{$obj}++);

            $views{$obj->class} ||= UR::Object::View->create(
                                          subject_class_name => $obj->class,
                                          perspective => 'default',
                                          toolkit => 'text',
                                       );
 

            my $view = $views{$obj->class};
            $view->subject($obj);
            $view->show();
            print "\n";
        }
   
    }
}

    
1;
