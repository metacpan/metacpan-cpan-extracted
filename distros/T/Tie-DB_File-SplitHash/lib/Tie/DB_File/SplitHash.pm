package Tie::DB_File::SplitHash;

use strict;
use warnings;

use DB_File;
use File::Path;
use File::Spec;
use Digest::SHA1 qw (sha1_hex);
use Fcntl qw (:flock);

require Exporter;
use vars qw ($VERSION @ISA @EXPORT $DB_HASH);

$VERSION = '1.07';
@ISA     = qw (Tie::Hash Exporter);
@EXPORT  = qw(
        $DB_HASH 
        DB_LOCK     DB_SHMEM        DB_TXN          HASHMAGIC
        HASHVERSION MAX_PAGE_NUMBER MAX_PAGE_OFFSET MAX_REC_NUMBER
        RET_ERROR   RET_SPECIAL     RET_SUCCESS     R_CURSOR
        R_DUP       R_FIRST         R_FIXEDLEN      R_IAFTER
        R_IBEFORE   R_LAST          R_NEXT          R_NOKEY
        R_NOOVERWRITE R_PREV        R_RECNOSYNC     R_SETCURSOR
        R_SNAPSHOT  __R_UNUSED); 
eval {
    # Make all Fcntl O_XXX constants available for importing
    require Fcntl;
    my @O = grep /^O_/, @Fcntl::EXPORT;
    Fcntl->import(@O);  # first we import what we want to export
    push(@EXPORT, @O);
};

###############################################################################

sub TIEHASH {
    my $class = shift;
    my $package = __PACKAGE__;
    my $self  = bless {},$class;
    my $parms = [@_];
    my $vars = {};
    $self->{$package} = $vars;

    $vars->{'-init_parms'} = $parms;
    my $n_parms = $#$parms + 1;
    if ($n_parms != 5) {
        require Carp;
        Carp::croak($package . "::init_hash() - incorrect number of calling parameters\n");
    }
    my $multi_n = pop @$parms;
    $vars->{'-multi_n'} = $multi_n;
    $vars->{'-dirname'} = $parms->[0];
    if (not ((-e $vars->{'-dirname'}) or (mkdir ($vars->{'-dirname'},0777)))) {
        require Carp;
        Carp::croak($package . '::TIEHASH - datafiles directory ' . $vars->{'-dirname'} . " does not exist and cannot be created.\n$!");
    }
    my $main_index_file  = File::Spec->catfile($vars->{'-dirname'}, 'index');
    shift @$parms;
    $multi_n--;
    my $errors=0;
    my $error_message = '';
    foreach my $f_part (0..$multi_n) {
        my $tied_hash = {};
        my $db_object = tie %$tied_hash,'DB_File',"${main_index_file}_${f_part}.db",@$parms;
        if (not defined $db_object) {
            $errors = $f_part + 1;
            $error_message = $!;
            last;
        }
        $vars->{'db'}->[$f_part]->{-object} = $db_object;
    }
    if ($errors) {
        delete $vars->{'db'};
        require Carp;
        Carp::croak ("Failed to open database: $error_message\n");
    }

    return $self;
}

#######################################################################

sub STORE {
    my $self = shift;
    my $package = __PACKAGE__;

    my ($key,$value) = @_;
    my $section = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->STORE(@_);
}

#######################################################################

sub FETCH {
    my $self = shift;
    my $package = __PACKAGE__;

    my ($key)  = @_;

    my $section   = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{-object};
    return $db_object->FETCH(@_);
}

#######################################################################

sub DELETE {
    my $self = shift;
    my $package = __PACKAGE__;
    
    my ($key) = @_;

    my $section   = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->DELETE(@_);
}

#######################################################################

sub CLEAR {
    my $self = shift;
    my $package = __PACKAGE__;

    my $list_of_dbs = $self->{$package}->{'db'};
    my $counter = 0;
    foreach my $database (@$list_of_dbs) {
        my $db_object = $database->{'-object'};
        $counter++;
        $db_object->CLEAR(@_);
    }
}

#######################################################################

sub EXISTS {
    my $self = shift;
    my $package = __PACKAGE__;
    
    my ($key) = @_;

    my $section   = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->EXISTS(@_);
}

#######################################################################

sub DESTROY {
    my $self = shift;
    my $package = __PACKAGE__;

    delete $self->{$package}->{'db'};
}

#######################################################################

sub FIRSTKEY {
    my $self = shift;
    my $package = __PACKAGE__;
    my $vars = $self->{$package};
    my $db_object = $vars->{'db'}->[0]->{'-object'};
    $vars->{-iteration_section} = 0;
    return $db_object->FIRSTKEY(@_);
}

#######################################################################

sub NEXTKEY {
    my $self = shift;
    my $package = __PACKAGE__;
    my $vars = $self->{$package};
    
    my ($key) = @_;

    my $section   = $vars->{'-iteration_section'};
    my $multi_n   = $vars->{'-multi_n'};
    my $db_object = $vars->{'db'}->[$section]->{'-object'};
    my $next_key;
    while (not defined $next_key) {
        $next_key = $db_object->NEXTKEY($key);
        if (not defined $next_key) {
            $section++;
            $vars->{-iteration_section} = $section;
            my $next_section = $vars->{'db'}->[$section];
            last unless (defined $next_section);
            $db_object = $next_section->{'-object'};
            $next_key = $db_object->FIRSTKEY;
        }
    }
    return $next_key;
}

#######################################################################

sub _section_hash {
    my $self = shift;
    my $package = __PACKAGE__;
    
    my ($key) = @_;

    $key = '' unless defined $key;
    my $sections    = $self->{$package}->{'-multi_n'};
    my $digest      = sha1_hex($key);
    my $section_n   = hex(substr($digest,0,2)) % $sections;
    return $section_n;
}

#######################################################################

sub put {
    my $self = shift;
    my $package = __PACKAGE__;

    my $parms = [];
    @$parms   = @_;
    my $key   = shift @$parms;
    my $section = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->put(@_);
}

#######################################################################

sub get {
    my $self = shift;
    my $package = __PACKAGE__;

    my $parms     = [@_];
    my $key       = shift @$parms;
    my $section   = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->get(@_);
}

#######################################################################

sub seq {
    my $self = shift;
    my $package = __PACKAGE__;

    my $parms     = [@_];
    my $key       = shift @$parms;
    my $section   = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->seq(@_);
}

#######################################################################

sub del {
    my $self = shift;
    my $package = __PACKAGE__;

    my $parms     = [@_];
    my $key       = shift @$parms;
    my $section   = $self->_section_hash($key);
    my $db_object = $self->{$package}->{'db'}->[$section]->{'-object'};
    return $db_object->del(@_);
}

#######################################################################

sub sync {
    my $self = shift;
    my $package = __PACKAGE__;

    foreach my $db (@{$self->{$package}->{'db'}}) {
        $db->{'-object'}->sync(@_);
    }
}

#######################################################################

sub fd {
    my $self = shift;
    my $package = __PACKAGE__;
    return $self->{$package}->{'db'}->[0]->{'-object'}->fd(@_);
}

#######################################################################

sub exists {
    return shift->EXISTS(@_);
}

#######################################################################

sub clear {
    return shift->CLEAR(@_);
}

#######################################################################

1;
