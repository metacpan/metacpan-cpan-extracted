package HTML::HTPL::Result;

use HTML::HTPL::Lib;
use HTML::HTPL::Sys qw(publish);
use Carp;
use strict qw(vars subs);
use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();

####
## Create a resultset

sub new {
    my $class = shift;
    my $origin = shift;
    my @fields = @_; 
    @fields = map {s/ /_/g; $_;} @fields;

    my $self = {'origin' => $origin,
		'more' => [],
                 'rows' => [],
                 'cursor' => 0,
                 'fields' => \@fields};
    bless $self, $class;
}

sub append {
    my ($self, $twin) = @_;
    my %hash;
    my @fields = @{$self->{'fields'}};
    @hash{@fields} = @fields;
    my @other = @{$twin->{'fields'}};
    foreach (@other) {
        next if $hash{$_};
        push(@{$self->{'fields'}}, $_);
    }
    push(@{$self->{'more'}}, $twin);
}

sub makehash {
    my $self = shift;
    my @values = @_;
    my @fields = @{$self->{'fields'}};
    my $hash = {};
    foreach (@fields) {
        $hash->{$_} = shift @values;
    }
    $hash;
}

sub lowputrow {
    my $self = shift;
    $self->{'rows'}->[$self->{'cursor'}] = $self->makehash(@_);
}

sub addrow {
    my $self = shift;
    $self->add($self->makehash(@_));
}

sub add {
    my ($self, $hash) = @_;
    push(@{$self->{'rows'}}, $hash);
}

sub fetch {
    my $self = shift;

    my $cursor;
    $cursor = $self->{'cursor2'};
    $cursor = $self->{'cursor'} unless ($cursor);
    $self->{'cursor'} = $cursor;

    $self->zapcols;

    return undef unless ($self->retrieve);

    $self->{'cursor2'} = $cursor + 1;

    1;
}

sub receive {
    my $self = shift;
    return $self->receivenext unless ($self->{'origin'});
    return $self->receivenext if $self->{'origin'}->eof;
    my $rec = $self->{'origin'}->fetch;
    return $self->receivenext unless ($rec);
    $self->add($rec) if (UNIVERSAL::isa($rec, 'HASH'));
    $self->addrow(@$rec) if (UNIVERSAL::isa($rec, 'ARRAY'));
    1;
}

sub receivenext {
    my $self = shift;
    for (;;) {
        return undef unless $self->loadnext;
        last unless $self->eof;
    }
    $self->sync;
    1;
}

sub loadnext {
    my $self = shift;
    my $twin = pop @{$self->{'more'}};
    return undef unless $twin;
    foreach (1 .. $twin->_rows) {
        $twin->sync($_ - 1);
	$self->add($twin->current);
    }

    $self->{'origin'} = $twin->{'origin'};
    push(@{$self->{'more'}}, @{$twin->{'more'}});
    1;
}

sub cache {
    my $self = shift;
    while ($self->receive) {}
}

sub sync {
    my ($self, $goto) = @_;

    my $cursor = $self->{'cursor'};
    $cursor = $self->{'cursor'} = $goto if defined($goto);

    while ($cursor >= $self->_rows) {
#        return undef unless ($self->{'origin'});
#        return undef if ($self->{'origin'}->eof);
        return undef unless ($self->receive);
    }
    return 1;
}

sub retrieve {
    my $self = shift;

#    my $cursor = $self->{'cursor'};

    return undef unless ($self->sync);

    my @fields = $self->cols;

    my ($key, $val);

    my %hash = %{$self->current};
    &HTML::HTPL::Lib'publish(%hash);
    &HTML::HTPL::Sys::sethash('result', %hash);
    1;
}

sub current {
    my $self = shift;
    $self->{'rows'}->[$self->{'cursor'}];
}

sub unfetch {
    my $self = shift;
    my $cursor;
    $cursor = $self->{'cursor2'};
    $cursor = $self->{'cursor'} unless ($cursor);
    $self->{'cursor'} = $cursor;

    $cursor--;
    return undef if ($cursor < 0);
    $self->{'cursor2'} = $cursor;
    $self->retrieve;
}

sub access {
    my ($self, $line) = @_;

    return undef if ($line < 0);
    while ($line >= $self->_rows) {
        return undef unless ($self->receive);
    }
    $self->{'cursor'} = $line;
    delete $self->{'cursor2'};
    $self->retrieve;
}

sub eof {
    my $self = shift;
    my $cursor;

    $cursor = $self->{'cursor2'};
    $cursor = $self->{'cursor'} unless ($cursor);
    return undef if ($cursor < $self->_rows);
    return undef if ($self->{'origin'} && !$self->{'origin'}->eof);
    return $self->eof if $self->loadnext;
    1;
}

sub bof {
    my $self = shift;
    my $cursor;
    $cursor = $self->{'cursor2'};
    $cursor = $self->{'cursor'} unless ($cursor);

    return 1 unless ($cursor < 0);
    undef;
}

sub index {
    my $self = shift;
    $self->{'cursor'};
}

sub _rows {
    my $self = shift;

    $#{$self->{'rows'}} + 1;
}

sub rows {
    my $self = shift;
    $self->cache;
    $self->_rows;
}

sub none {
    my $self = shift;
    return undef if ($self->_rows || !$self->eof);
    1;
}

sub cols {
    my $self = shift;
    @{$self->{'fields'}};
}

sub getcol {
    my ($self, $number) = @_;

    my $cursor = $self->{'cursor'};

    my $field = $self->{'fields'}->[$number];

    return $self->get($field);
}

sub asrow {
    my $self = shift;
    my $hash = $self->current;

    map {$hash->{$_}} @{$self->{'fields'}};
}

sub get {
    my ($self, $col) = @_;
    my $rec = $self->current;
    $rec->{$col};
}

sub rewind {
    my $self = shift;
    $self->access(0);
}

sub filter {
    my ($self, $filter) = @_;
    my $new = $self->mimic;
    my $save = $self->index;
    &HTML::HTPL::Sys::pushvars($self->{'fields'});
    $self->rewind;
    while ($self->fetch) {
        $new->add($self->current) if (&$filter);
    }
    $self->access($save);
    &HTML::HTPL::Sys::popvars;
    $new;
}

sub mimic {
    my $self = shift;
    return new HTML::HTPL::Result(undef, $self->cols);
}

sub clone {
    my $self = shift;
    $self->filter(sub {1;});    
}

sub subset {
    my ($self, $from, $to) = @_;
    my $cnt = 0;
    my $ref = sub { $cnt++; $cnt >= $from && (!defined($to) || $cnt
        <= $to); };
    $self->filter($ref); 
}

sub unite {
    my ($self, $friend) = @_;
    my (@a, @b);
    @a = $self->cols;
    @b = $friend->cols;
    return undef unless ("@a" eq "@b");
    my $save = $friend->index;
    &HTML::HTPL::Sys::pushvars($self->{'fields'});
    $friend->rewind;
    while ($friend->fetch) {
        $self->addrow($friend->asrow);
    }
    $friend->access($save);
    &HTML::HTPL::Sys::popvars;
}

sub project ($@;@) {
    my ($self, @fields) = @_;
    my @r;
    my $save = $self->index;
    if (!$#fields && $fields[0] =~ /:/ && !UNIVERSAL::isa($fields[0], 'CODE')) {
        @fields = split(/:/, $fields[0]);
    }

    if (!$#fields && UNIVERSAL::isa($fields[0], 'ARRAY')) {
        @fields = @{$fields[0]};
    }
    &HTML::HTPL::Sys::pushvars($self->{'fields'});
    $self->rewind;
    my $ref = UNIVERSAL::isa($fields[0], 'CODE') ? $fields[0] : (
         !$#fields ? sub {my $self = shift; $self->get($fields[0]);} :
         sub {my $self = shift; [map {$self->get($_);} @fields];});
    while ($self->fetch) {
        push(@r, &HTML::HTPL::Sys::call($ref, $self));
    }
    $self->access($save);
    &HTML::HTPL::Sys::popvars;
    return (@r);
}

sub zapcols {
    my $self = shift;
    my @cols = $self->cols;
    foreach (@cols) {
        undef ${$HTML::HTPL::Lib'htpl_pkg . "'$_"};
    }
}

sub matrix {
    my $self = shift;
    my @fields = $self->cols;
    $self->project(@fields);
}

sub structured {
    my $self = shift;
    my @fields = $self->cols;
    my $code = sub {
        my $self = shift;
        my %hash = ();
        @hash{@fields} = map {$self->get($_);} @fields;
        \%hash;
    };
    $self->project($code);
}

sub astable {
    my $self = shift;
    require HTML::HTPL::Table;
    my $flag = shift;
    my $table = new HTML::HTPL::Table('cols' => scalar($self->cols), @_);
    if (UNIVERSAL::isa($flag, 'HTML::HTPL::Table')) {
        $table = $flag;
    } else {
        my $coderef = UNIVERSAL::isa($flag, 'CODE') ? $flag : sub {};
        $table->add(map {&$coderef; {'data' => $_, 'header' => 1};} $self->cols) if
          ($flag);
    }
    $table->load($self->matrix);
    return $table;
}

sub asxml {
    my ($self, $root, $rec) = @_;
    unless ($rec) {
        $rec = $root;
        $root = 'xml';
    }
    croak "Usage: asxml(['tree name',] 'record type name')" unless $rec;
    my $struct = {$rec => [$self->structured]};
    require XML::Simple;
    XML::Simple::XMLout($struct, 'rootname' => $root);
}

1;
