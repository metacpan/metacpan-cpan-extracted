package TheSchwartz::Simple::Job;
use strict;

sub new_from_array {
    my($class, $funcname, $arg) = @_;
    $class->new(
        funcname => $funcname,
        arg      => $arg,
    );
}

sub new {
    my $class = shift;
    my %param = ref $_[0] ? %{$_[0]} : @_;
    my $self = bless \%param, $class;

    $self->run_after( time ) unless defined $self->run_after;
    $self->grabbed_until( 0) unless defined $self->grabbed_until;

    $self;
}

sub _accessor {
    my $self = shift;
    my $col  = shift;
    $self->{$col} = shift if @_;
    $self->{$col};
}

sub as_hashref {
    my $self = shift;

    my %data;
    for my $col (qw( jobid funcid arg uniqkey insert_time run_after grabbed_until priority coalesce )) {
        $data{$col} = $self->{$col}
            if exists $self->{$col};
    }

    \%data;
}

sub jobid         { shift->_accessor('jobid', @_) }
sub funcid        { shift->_accessor('funcid', @_) }
sub arg           { shift->_accessor('arg', @_) }
sub uniqkey       { shift->_accessor('uniqkey', @_) }
sub insert_time   { shift->_accessor('insert_time', @_) }
sub run_after     { shift->_accessor('run_after', @_) }
sub grabbed_until { shift->_accessor('grabbed_until', @_) }
sub priority      { shift->_accessor('priority', @_) }
sub coalesce      { shift->_accessor('coalesce', @_) }

sub funcname      { shift->_accessor('funcname', @_) }

1;
