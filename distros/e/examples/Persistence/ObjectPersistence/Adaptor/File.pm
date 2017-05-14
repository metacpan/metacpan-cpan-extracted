package Adaptor::File;

use strict;
use Carp;
use Storable ();   # Don't want to import  any names

#---- Global variables
use vars qw(%global_adaptor_info $debugging %g_attr_names);
$debugging = 0;

sub new {
    @_ == 3 || croak 'Usage: File_Adaptor->new(file, config_file)';
    my ($pkg,$file, $config_file) = @_;


    my $rh_adaptor_info;
    foreach $rh_adaptor_info (values %global_adaptor_info) {
        if ($rh_adaptor_info->{'file'} eq $file) {
            croak "File \'$file\' has already been opened\n";
        }
    }
    _load_config_file($config_file);
    my $all_instances = load_all($file);
    $all_instances = {} unless defined($all_instances);
    my $this = \$all_instances;
    bless $this, $pkg;
    $global_adaptor_info{$this} = {'file' => $file};
    $this;
}

my %mapping_loaded = ();
sub _load_config_file {
    my ($file) = @_;
    return if (exists $mapping_loaded{$file});
    $mapping_loaded{$file}++;
    require $file; # for now.
}

sub delete {
    (@_ == 2) || (@_ == 3) ||
         croak  "Error: adaptor->delete (obj), or \n" .
                '       adaptor->delete (class, id)';
    my ($this, $id);
    $this = shift;
    if (@_ == 1) {
        my $obj = $_[0];
        ($id) = $obj->get_attributes('_id');
    } else {
        $id = $_[1];
    }
  
    my $all_instances = $$this;
    delete $all_instances->{$id};
}

sub store {    # adaptor->store($obj)
    (@_ == 2) || croak  'Usage adaptor->store ($obj_to_store)';
    my ($this, $obj_to_store) = @_;  # $this  is 'all_instances'
    my ($id) = $obj_to_store->get_attributes('_id');
    my $all_instances = $$this;
    if (!defined ($id )) {
        $id = $this->_get_next_id();
        $obj_to_store->set_attributes('_id'=> $id);
    }
    $all_instances->{$id} = $obj_to_store;
    $id;
}

sub get_attrs_for_class {
    my ($pkg) = @_;
}

sub flush {    # adaptor->flush();
    # Complements load_all()
    my $this = $_[0];
    my $all_instances = $$this;
    return if (!exists $global_adaptor_info{$this});

    my $file = $global_adaptor_info{$this}->{'file'};
    return unless defined $file;
    open (F, ">$file") || die "Error opening $file: $!\n";
    my ($id, $obj);
    while (($id, $obj) = each %$all_instances) {
        my $class = ref($obj);
        my @attrs = $obj->get_attributes(@{$g_attr_names{$class}});
        Storable::store_fd([$class, $id, @attrs], \*F);
    }
    close(F);
}

sub load_all {                  #  $all_instances = load_all($file);
    # complement of flush ()
    my $file = shift;
    return () if (! -e $file);
    open(F, $file) || croak "Unable to load $file: $!";
    # Global information first
    my ($class, $id, $obj, $rh_attr_names, @attrs, $all_instances);
    eval {
        while (1) {
            ($class, $id, @attrs) = @{Storable::retrieve_fd(\*F)};
            $obj = $all_instances->{$id};
            $obj = $class->new() unless defined($obj);
            $rh_attr_names = $g_attr_names{$class};
            $obj->set_attributes("_id" => $id,
                                 map {$rh_attr_names->[$_] => $attrs[$_]}
                                    (0 .. $#attrs));
            $all_instances->{$id} = $obj;
        }
    };
    $all_instances;
}



sub begin_transaction {
    my ($this) = @_;
    $this->flush();
}

sub commit_transaction {
    my ($this) = @_;
    $this->flush();
}

sub rollback_transaction {
    my ($this) = @_;
    my ($file) = $global_adaptor_info{$this}->{'file'};
    my $all_instances = load_all($file);
    ${$this} = $all_instances;
}

sub retrieve {
    my ($this, $class, $id) = @_;
    $$this->{$id};
}

sub retrieve_all {
    my ($this) = @_;
    values %$$this;
}

sub retrieve_where {
    my ($this, $class, $query) = @_;
    my $all_instances = $$this;

    # blank queries get everything
    return $this->retrieve_all() if ($query !~ /\S/);

    my ($boolean_expression, @attrs) = parse_query($query);
    # @attrs contains the attr. names used in the query
    # ("a", "b") translates to
    #    my ($a, $b) = $obj->get_attributes("a", "b");
    
    my $fetch_stmt = "my (" . join(",",map{'$' . $_} @attrs) . ") = " .
               "\$obj->get_attributes(qw(@attrs))";
    my (@retval);
    my $eval_str = qq{
        my \$dummy_key; my \$obj;
        while ((\$dummy_key, \$obj) = each \%\$all_instances) {
           next unless ref(\$obj) eq "$class";
           $fetch_stmt;
            push (\@retval, \$obj) if ($boolean_expression);
        }
    };
    ($debugging) && (print STDERR "EVAL:\n\t$eval_str\n");
    eval ($eval_str);
    if ($@) {
        print STDERR "Ill-formed query:\n\t$query\n";
        ($debugging) && (print STDERR $@);
    }
    @retval;
}


#-----------------------------------------------------------------
# Query evaluator

my %string_op = ( # Map from any operator to corresponding string op
              '=='  => 'eq',
              '<'  =>  'lt',
              '<=' =>  'le',
              '>'  =>  'gt',
              '>=' =>  'ge',
              '!=' =>  'ne',
              );

my $ANY_OP = '<=|>=|<|>|!=|==';      # Any comparison operator

sub parse_query {
    my ($query) = @_;
    # A query like (name = 'santa') && (num_helpers < 5) gets translated to 
    # a boolean expression:
    #   ($obj->{name} eq 'santa') && ($obj->{num_helpers} < 5);

    # Instead of parsing the expression, we just do a set of simple 
    # transformations to convert it to an eval'able Perl expression. 
    # These are the rules;
    # 1. A query term is <variable> <op> <value>  (e.g. name == 'santa')
    # 2. If query is blank, it should evaluate to 1
    # 3. <variable> mapped to '$obj->{<variable>}'
    # 4. If <value> is a *quoted* string, then <op> gets mapped to the 
    #    appropriate string op.


    # Rule 2.
    return 1 if ($query =~ /^\s*$/);

    # First squirrel away all instances of escaped quotes. We'll
    # restore them later. This way it doesn't get in the way when
    # we are processing rule 4.
    $query =~ s/\\[']/\200/g; 
    $query =~ s/\\["]/\201/g; 
    # Replace all '=' by '==' because it messes up the data inside the
    # object !
    # TBD: should not do this for '=' inside strings
    $query =~ s/([^!><=])=/$1 == /g;

    # Rule 3.
    my %attrs;
    $query =~
       s/(\w+)\s*($ANY_OP)/$attrs{$1}++, "\$$1 $2"/eg;

    # Rule 4.
    # Replace any comparison operator followed by a quoted string
    # with the appropriate string operator. A quoted string is 
    # a quote followed by sequence of non-quotes followed by a quote
    $query =~ s{
           ($ANY_OP)         (?# Any comparison operator)
           \s*               (?#  followed by zero or more spaces,)
           ['"]([^'"]*)['"]  (?#  then by a quoted string )
        }{
           $string_op{$1} . ' \'' . $2 . '\''
         }goxse;   # global, compile-once, extended, treat as single line, eval

    # Restore all escaped quote characters
    $query =~ s/\200/\\'/g;
    $query =~ s/\201/\\"/g; 
    ($query, keys %attrs);  
}

my $counter = 0;
# Calculate seconds since Jan 1, 1997 when counter was reset
my $counter_reset_time = time();

sub _get_next_id {  # adaptor->_get_next_id()
    if (++$counter > 99999) {
        # Assuming you can't create 99999 Perl objects in one second
        $counter_reset_time = time();
        $counter = 0;
    }
    sprintf("%09d%05d", $counter_reset_time, ++$counter);
}

1;