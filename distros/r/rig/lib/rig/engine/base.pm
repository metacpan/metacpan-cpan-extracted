package rig::engine::base;
{
  $rig::engine::base::VERSION = '0.04';
}
use strict;
use warnings;
use Carp;
use YAML::XS;
use Hook::LexWrap;
use version;
use Cwd;
use File::HomeDir;
use File::Spec;

sub new {
    my ($class,%args)=@_;
    bless \%args, $class;
}

sub import {
    my ($self, @tasks) = @_;
    #print Dump $self;
    my $pkg = caller;
    #print "===== $pkg\n";
    my $import;
    ( $import, @tasks )= $self->build_import( @tasks );

    #print "TASK=@tasks";
    #print "IMP=" . Dump $import;

    my @module_list = map { @{ $import->{$_}->{'use'} || [] } } @tasks;
    @module_list = $self->_group_modules( @module_list );
    my ($first_module, $last, @gotos);

    for my $module ( @module_list ) {
        no strict 'refs';
        my $name = $module->{name};
        my $direct_import = do {
            $name =~ /^\+(.+)$/ and $name=$1;
        };
        my $version = $module->{version};
        my $optional = $module->{optional};
        my @module_args = ref $module->{args} eq 'ARRAY' ? @{$module->{args}} : ();

        $self->_import_alias( $pkg, $module );

        #print " --require $name (version=$version, optional=$optional)\n";
        eval "require $name" or do {
            $optional and next;
            carp "rig: $name: $@";
        };
        $self->_check_versions( $name, $version );

        my $can_import = defined &{$name.'::import'};
        # some modules you just can't reach:
        if( !$can_import ) {
            my $module_args_str = "'".join(q{','}, @module_args)."'"
                if @module_args > 0;
            #print "   use $name $module_args_str\n";
            $module_args_str ||= '';
            eval "package $pkg; use $name $module_args_str;"; # for things like Carp
        }
        # modules with a + in front, at the user's request
        elsif( $direct_import ) {
            #print "  direct import for $name\n";
            $name->import(@module_args);
        }
        # default goto import method, pushed for later
        else {
            #print "  push goto import for $name\n";
            $first_module ||= $module;
            my $import_sub = $name . "::import";
            push @gotos, [ $name, $import_sub, \@module_args ];
        }
    }

    # wire up the goto chain
    for my $goto_data ( @gotos ) {
        no strict 'refs';
        my ($name, $import_sub, $margs ) = @{ $goto_data };
        my @module_args = @$margs;
        if( $last ) {
            unless( *{$last} ) {
                #print "no code for $last\n";
            } else {
                my $restore = $last;
                # save original
                my $original = *$restore{CODE};;
                # wrap the import
                #print "    wrap $last\n";
                wrap $restore,
                    post=>sub {
                        #print " - post run $import_sub, restore $restore: caller:" . caller . "\n";
                        no warnings;  # avoid redefined warnings TODO better control of redefines
                        *{$restore}=$original if $restore;
                        @_=($name, @module_args);
                        #print "   goto $import_sub( @module_args ) \n";
                        goto &$import_sub };
            }
        }
        $last = $import_sub;
    }
    $last = undef;

    # fire up the chain, if any
    if( $first_module ) {
        my @module_args = ref $first_module->{args} eq 'ARRAY' ? @{$first_module->{args}} : ();
        my $first_import = $first_module->{name}."::import";
        my $can_import = defined &{$first_import};
        return unless $can_import;
        @_=($first_module->{name}, @module_args);
        #print ">>first import $first_import @_\n";
        goto &$first_import;
    }
}

sub _has_rigfile_tasks {
    my ($self, $tasks ) = @_;
    my $need_to_parse = 0;  
    my @newtasks = map {
        unless( s/^\:// ) {
            $need_to_parse = 1;
        }
        $_;
    } @{ $tasks || [] };
    $tasks = \@newtasks;
    return $need_to_parse;
}

sub build_import {
    my ($self,@tasks)=@_;
    my $parser = $self->{parser} or croak "rig: missing a parser";
    my $profile = $self->_has_rigfile_tasks( \@tasks) ? $parser->parse( $self->{file} ) : {};
    #my $profile = $parser->parse( $self->{file} ) || {};
    my $ret = {};
    for my $task_name ( @tasks ) {
        $profile->{$task_name} ||= $self->_load_task_module( $task_name );# if _is_module_task($_);
        confess "rig $_ not found in " . $parser->file 
            unless exists $profile->{$task_name}; 
        my $task = $profile->{$task_name};
        confess "rig: content format for '$task_name' not supported: " . ref($task)
            unless ref $task eq 'HASH';
        for my $section_id ( keys %$task ) {
            my $section = $task->{$section_id};
            my $section_sub = 'section_' . $section_id;
            my $res = eval { $self->$section_sub( $section ) };
            die $@ if $@;
            #print "###$task_name=$section_id=$res\n";
            $res and $ret->{$task_name}->{$section_id} = $@ ? $section : $res;
        }
    }
    ( $ret, @tasks ) = $self->_also_merge_tasks( $ret, @tasks );
    return $ret, @tasks;
}

sub _also_merge_tasks {
    my ($self, $rig, @tasks ) =@_;
    return $rig unless ref $rig eq 'HASH';
    my %also_augment;
    for my $task_name ( @tasks ) {
        my $also = $rig->{$task_name}->{also} ;
        next unless ref $also eq 'ARRAY';
        my ($also_rig,@also_tasks) = $self->build_import( @$also );
        push @{ $also_augment{$task_name} }, @also_tasks;
        next unless ref $also_rig eq 'HASH';
        for my $also_task ( keys %$also_rig ) {
            # add to the task list
            exists $rig->{$also_task}
                or $rig->{$also_task} = $also_rig->{$also_task}; 
        }
    }
    @tasks = map { 
        if( exists $also_augment{$_} ) {
            ( $_, @{ $also_augment{$_} } );
        } else {
            $_;
        }
    } @tasks;
    return $rig, @tasks;
}

sub section_also {
    my ($self, $section ) = @_;
    #confess 'rig: invalid "also" section. Should be a comma-separated list <task1>, <task2>...'
        #unless ref $section eq 'SCALAR';
    my @also = split /,\s*/,$section;
    return \@also; 
}

sub section_use {
    my ($self, $section ) = @_;
    confess 'rig: invalid "use" section. Should be an array'
        unless ref $section eq 'ARRAY';
    return [ map {
        if( ref eq 'HASH' ) {
            my %hash = %$_;
            my $module = [keys %hash]->[0]; # ignore the rest
            my ($name,$version) = split / /, $module;
            my $optional = substr($name, 0,1) eq '?';
            $optional and $name=substr($name,1);
            my ($subs, $alias) = $self->_split_sub_alias( $hash{$module} );
            +{
                name     => $name,
                version  => $version,
                optional => $optional,
                args     => $subs,
                alias    => $alias,
            }
        } else {
            my ($name,$version) = split / /;
            my $optional = substr($name, 0,1) eq '?';
            $optional and $name=substr($name,1);
            +{
                name => $name,
                version => $version,
                optional => $optional,
            }
        }
    } @$section
    ]
}

sub _import_alias {
    my ($self, $pkg, $module ) = @_;
    return unless exists $module->{alias};
    return unless ref $module->{alias} eq 'HASH';
    no strict 'refs';
    for my $orig ( keys %{ $module->{alias} } ) {
        my $suppress = substr($orig,length($orig)-1) eq '!';
        my @alias = keys %{ $module->{alias}->{$orig} || {} };
        next unless @alias > 0;
        my $orig_sub = $pkg . '::' .
            ( $suppress ? substr($orig,0,length($orig)-1) : $orig );
        # create aliases in packages
        for my $alias ( @alias ) {
            *{$pkg . '::' . $alias } = \&$orig_sub;
        }
        # delete original
        $suppress and do {
            require Sub::Delete;
            Sub::Delete::delete_sub( $orig_sub );
        }
    }
}

sub _split_sub_alias {
    my ($self, $subs) = @_;
    return ($subs,undef) unless ref $subs eq 'ARRAY';
    my %alias;
    my @subs;
    for my $sub_item ( @$subs ) {
        my @parts = split / /, $sub_item;
        # store original import name
        push @subs, $parts[0];
        # reference the aliases
        @{ $alias{ $parts[0] } }{ @parts[1..$#parts ] } = ();
    }
    return (\@subs, \%alias);
}

sub _load_task_module {
    my $self = shift;
    my $task = shift;
    my $module = 'rig::task::' . $task;
    my $load_sub = $module . '::rig';
    no strict 'refs';
    unless( defined &{$load_sub} ) {
        eval "require $module"
            or confess "rig: could not require module '$module' for task '$task' ($load_sub): $@";
    }
    return &$load_sub($task);
}

sub _check_versions {
    my ($self, $name, $version) = @_;
    no strict q/refs/;
    my $current = ${$name.'::VERSION'}; 
    return unless defined $current && defined $version;
    croak "rig: version error: required module $name $version, but found version $current"
        if version->parse($current) < version->parse($version); 
}

sub _unimport {
    my ($class, @args) = @_;
    my $pkg = caller;
    #print "$pkg\n";
    my $import = $class->build_import( @args );
    #die Dump $import;
    my @module_list = map { @{ $import->{$_} } } @args;
    my ($first_module, $last);
    for my $module ( reverse @module_list ) {
        no strict 'refs';
        my $name = $module->{name};
        my @module_args = ref $module->{args} eq 'ARRAY' ? @{$module->{args}} : ();

        my $can_import = defined &{$name.'::unimport'};
        unless( $can_import ) {
            my $module_args_str = "'".join(q{','}, @module_args)."'"
                if @module_args > 0;
            eval "package $pkg; no $name $module_args_str;"; # for things like Carp
        } else {
            $first_module ||= $module;
            my $import_sub = $name . "::import";
            if( $last ) {
                unless( *{$last} ) {
                    #print "no code for $last\n";
                } else {
                    my $restore = $last;
                    # save original
                    my $original = *$restore{CODE};;
                    # wrap the import
                    #print "    wrap $last\n";
                    wrap $restore,
                        post=>sub {
                            #print " - post run $import_sub, restore $restore\n";
                            *{$restore}=$original if $restore;
                            @_=($name, @module_args);
                            goto &$import_sub };
                }
            }
            $last = $import_sub;
        }
    }
    $last = undef;
    if( $first_module ) {
        # start the chain, if any
        my @module_args = ref $first_module->{args} eq 'ARRAY' ? @{$first_module->{args}} : ();
        my $first_import = $first_module->{name}."::unimport";
        my $can_import = defined &{$first_import};
        return unless $can_import;
        @_=($first_module->{name}, @module_args);
        goto &$first_import;
    }
}

sub _group_modules {
    my $self = shift;
    my %ret;
    for my $module ( @_ ) {
        my $name = delete $module->{name};
        $ret{$name}{name} = $name;
        # args
        push @{ $ret{ $name }{args} }, @{$module->{args} || [] };
        # alias
        for my $alias ( keys %{ $module->{alias} } ) {
            $ret{ $name }{alias}{ $alias } = $module->{alias}->{$alias};
        }
        # version
        $ret{$name}{version} = $module->{version}
            if ( defined $module->{version} && defined $ret{$name}{version} && $module->{version} > $ret{$name}{version} ) 
                || ! defined $ret{$name}{version}; 
        # optional
        $ret{$name}{optional} = $module->{optional}
            if ( defined $module->{optional} && defined $ret{$name}{optional} && $module->{optional} > $ret{$name}{optional} )
                || ! defined $ret{$name}{optional}; 

    }
    #print YAML::Dump \%ret;
    return map { $ret{$_} } keys %ret;
}

1;

=head1 NAME

rig::engine::base - Default engine for rig

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Here is were all the dirty work is done. 

No moving parts inside. Instantiate this class if needed. 

=head1 METHODS

=head2 import

Imports modules into the caller package.

=head2 build_import

Creates the import sequence.

=head2 new

Creates a new engine instance.

=head2 section_also

Handles the 'also' section.

=head2 section_use

Handles the 'use' section.

=cut 
