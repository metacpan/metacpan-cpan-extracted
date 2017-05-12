package Tree::Family::Person;
use strict;
use Data::Dumper;
use List::Util qw(min max);
use Sub::Installer;

=head1 NAME 

Tree::Family::Person

=head1 SYNOPSIS

 my $p = Tree::Family::Person->new(
    first_name => 'Fred',
    last_name   => 'Flintstone',
    birth_date  => '1901-09-01',
    death_date  => undef,
    gender      => 'male',
    birth_place => 'Bedrock');

 $p->spouse($wilma);

 $p->dad($papa);

 $p->mom($mama);

 for ($p->kids) {
    print $_->first_name;
 }
 
 $p->set(last_name => 'Smith');

=cut

our %globalHash; # a hash from IDs to hashes of info
our @Fields = qw(first_name middle_name last_name birth_date death_date birth_place gender id generation);
our @RelationFields = qw(spouse mom dad kids partners);
our $keyMethod = 'first_name'; # Change during testing (see below)

=head2 new

Create a new person

=cut

sub new {
    my ($class, %args) = @_;
    my $new_hash = {
        map { ($_ => $args{$_}) } @Fields
    };
    my $new_id = _new_id($new_hash) or die "couldn't make id for new object".Dumper($new_hash);
    my $id_copy = $new_id;
    $globalHash{$id_copy} = $new_hash;
    my $new_object = bless \$new_id, $class;
    $new_object->set(id => $id_copy);
    return $new_object;
}

#
# _delete_self
#
# remove a person
#
sub _delete_self {
    my $self = shift;
    delete $globalHash{$$self};
}

sub _new_id {
    return time.$$.( int ((rand 1) * 10000000)) if $keyMethod eq 'time_pid_rand';
    my $h = shift;
    my $val = ($h->{$keyMethod} || (int ((rand 1) * 10000).$$));
    $val =~ tr/a-zA-Z0-9//cd;
    my $i = 1;
    my $base = $val;
    while (exists($globalHash{$val})) {
        $val = $base.$i;
        $i++;
    }
    return $val;
}

=head2 first_name,middle_name,last_name,birth_date,death_date,birth_place,gender,id,generation

Accessors, mutators

=cut

for my $field (@Fields) {
    __PACKAGE__->install_sub({
        $field => sub {
            my $self = shift;
            $self->set($field => $_[0]) if @_==1;
            $self->get($field); 
        },
    });
}

=head2 full_name

first + middle + last

=cut

sub full_name {
    my $self = shift;
    return join ' ', grep defined, ($self->first_name,$self->middle_name, $self->last_name);
}

=head2 set

Set an attribute for a person (same as using mutators above)

$person->set(first_name => 'Joe');

=cut

sub set {
    my ($self,$key,$value) = @_;
    local $@;
    die "bad key $key" unless grep /^$key$/, @Fields, @RelationFields;
    $globalHash{$$self}{$key} = $value;
    delete $globalHash{$$self}{$key} if !defined($value);
}

=head2 get

Get an attribute

Same as using accessors above.

$person->get('first_name');

=cut

sub get {
    my ($self,$key) = @_;
    die "bad key $key" unless grep /^$key$/, @Fields, @RelationFields;
    die "no key to get" unless $key;
    $globalHash{$$self}{$key};
}

=head2 spouse

Get/set spouse

$fred->spouse($wilma)

=cut

sub spouse {
    my ($self,$spouse) = @_;
    return $self->get('spouse') unless @_==2;
    if ($spouse) {
        die "spouse is not a person" unless ref($spouse) eq 'Tree::Family::Person';
        $self->set('spouse' => $spouse);
        $spouse->set('spouse' => $self);
        return;
    }
    return unless $self->get('spouse');
    $self->get("spouse")->set('spouse' => undef);
    $self->set('spouse' => undef);
}

=head2 dad

Get/set dad

$luke->dad($darth)

=cut

sub dad {
    my ($self,$dad) = @_;
    return $self->get('dad') unless @_==2;
    if ($dad) {
        die "dad is not a person" unless ref($dad) eq 'Tree::Family::Person';
        $self->set(dad => $dad);
        $dad->add_kid($self);
        return;
    }
    my $old_dad = $self->get('dad');
    return unless $old_dad;
    $self->set('dad' => undef);
    $old_dad->delete_kid($self);
}

=head2 mom

Get/set mom

$pebbles->mom($wilma)

=cut

sub mom {
    my ($self,$mom) = @_;
    return $self->get('mom') unless @_==2;
    if ($mom) {
        die "mom is not a person" unless ref($mom) eq 'Tree::Family::Person';
        $self->set(mom => $mom);
        $mom->add_kid($self);
        return;
    }
    my $old_mom = $self->get('mom');
    return unless $old_mom;
    $self->set('mom' => undef);
    $old_mom->delete_kid($self);
}

=head2 add_kid

Add a kid to a person

 $carol->add_kid($jan);
 $carol->add_kid($marsha);
 $carol->add_kid($cindy);

=cut

sub add_kid {
    my ($self,$kid) = @_;
    die "not adding undef kid" unless defined $kid;
    return if grep { $_->id eq $kid->id } $self->kids;
    $self->set(kids => []) unless $self->get('kids');
    push @{ $self->get('kids') }, $kid;
}

=head2 delete_kid

Remove a kid from a person

$someone->remove_kid($annie)

=cut

sub delete_kid {
    my ($self, $which) = @_;
    die "no kids to delete" unless $self->get('kids');
    $self->set(kids => [ grep $_ ne $which, @{ $self->get('kids') }]);
    $which->mom(undef) if $self->gender && $self->gender eq 'f' && $which->mom;
    $which->dad(undef) if $self->gender && $self->gender eq 'm' && $which->dad;
}

=head2 kids

Return an array of kids

print $_->name for $mike->kids

=cut

sub kids {
    return @{ shift->get('kids') || [] };
}

=head2 has_partner

Did $a have any kids with $b?

print $a->has_partner($b) ? 'you betcha' : 'nope'

=cut

sub has_partner {
    my ($self,$who) = @_;
    return grep { $_->id eq $who->id } $self->partners;
}

#
# _add_partner, _delete_partner
#
sub _add_partner {
    my ($self, $partner) = @_;
    $self->set(partners => []) unless $self->get('partners');
    push @{ $self->get('partners') }, $partner unless $self->has_partner($partner);
    $partner->_add_partner($self) unless $partner->has_partner($self);
}

sub _delete_partner {
    my ($self, $which) = @_;
    die "no partners to delete" unless $self->get('partners');
    $self->set(partners => [ grep $_->id ne $which->id, @{ $self->get('partners') }]);
    $which->_delete_partner($self) if $which->has_partner($self);
}

=head2 partners

Get people with whom a person had kids.

=cut

sub partners {
    # _set_all_partners must have been called
    return @{ shift->get('partners') || [] };
}

=head2 find

Find a person based on their attributes

$class->find(first_name => "Bugs", last_name => "Bunny" );

=cut

sub find {
    my ($class, %args) = @_;
    my @list = values %globalHash;
    while (my ($key,$value) = each %args) {
        if (defined $value) {
            @list = grep defined($_->{$key}) && $_->{$key} eq $value, @list;
        } else {
            @list = grep !defined($_->{$key}), @list;
        }
    }
    return unless @list;
    return wantarray ? map { bless \(my $i = $_->{id}), $class } @list : 
                           bless \(my $j = $list[0]->{id}), $class;
}

# _clear_generations
# Remove all the generation attributes from the graph

sub _clear_generations {
    my $self = shift;
    delete $_->{generation} for values %globalHash;
}

#
# _set_all_generations
#
# Set all the generations recursively based on kids/parents
#

sub _set_all_generations {
    # Sets a generation tag in each person, starting with ourselves.
    my ($self, $value) = @_;
    return if defined($self->get('generation'));
    Carp::confess("missing generation") unless defined($value);
    $self->set(generation => $value);
    $self->dad->_set_all_generations($value - 1) if $self->dad;
    $self->mom->_set_all_generations($value - 1) if $self->mom;
    $_->_set_all_generations($value + 1) for $self->kids;
    $self->spouse->_set_all_generations($value)  if $self->spouse;
}

=head2 all

Get all people

Tree::Family::Person->all

=cut

sub all {
    my $class = shift;
    return map { bless \(my $o = $_->{id}), $class } values %globalHash;
}

=head2 partners_and_spouse

Get a list of all people with whom a person had kids, and their spouse (if
they have one)

=cut

sub partners_and_spouse {
    my $self = shift;
    return ($self->partners, ($self->spouse() ? $self->spouse() : ()));
}

sub _clear_all_partners {
    delete $_->{partners} for values %globalHash;
}

sub _set_all_partners {
    my $class = shift;
    # A partner is someone you have had a kid with who is not your spouse.
    for my $person ($class->all) {
        if (   $person->dad
            && $person->mom
            && (!$person->mom->spouse() || $person->mom->spouse() ne $person->dad)
            && !grep { $_ eq $person->dad } $person->mom->partners
          ) {
            $person->mom->_add_partner($person->dad);
            $person->dad->_add_partner($person->mom);
        }
    }
}

=head2 min_generation, max_generation

The min/max numeric generation

=cut

sub min_generation {
    for (values %globalHash) {
        die "missing generation for $_\n".Dumper(\%globalHash) unless defined($_->{generation});
    }
    return min map $_->{generation}, values %globalHash;
}

sub max_generation {
    return max map $_->{generation}, values %globalHash;
}

=head2 Freeze, Toast

Used for storage by Data::Dumper.

=cut

sub Freeze {
    my $self = shift;
    #warn "freezing $$self";
    my %i = map { $_ => $self->get($_) } @Fields;
    for (@RelationFields) {
        next if /kids|partners/i;
        next unless $self->$_;
        $i{$_} = ( $self->$_->isa('REF') ? ${ $self->$_ }->{id} : ${ $self->$_ } );
    }
    for ($self->kids) {
        push @{ $i{kids} }, ( $_->isa('REF') ? $$_->{id} : $$_ );
    }
    for ($self->partners) {
        push @{ $i{partners} },( $_->isa('REF') ? $$_->{id} : $$_ );
    }
    return bless \%i, "Tree::Family::Person";
    # return value is ignored; you can't replace the object.
}

sub Toast {
    my $self = shift;
    my $class = ref $self;
    my $data = $self;
    my %i = map { $_ => $data->{$_} } @Fields;
    for (@RelationFields) {
        next if /kids|partners/i;
        next unless $data->{$_};
        my $tmp = $data->{$_};
        $i{$_} = ref $tmp && $tmp->isa('REF') ? bless \(my $id = $tmp->{id}), $class : bless \$tmp, $class;
    }
    for (@{ $data->{kids} || [] } ) {
        push @{ $i{kids} }, ref $_ && $_->isa('REF') ? bless \(my $c = $_), $class : bless \$_, $class;
    }
    for (@{ $data->{partners} || [] } ) {
        push @{ $i{partners} }, ref $_ && $_->isa('REF') ? bless \(my $c = $_), $class : bless \$_, $class;
    }
    my $id = $data->{id};
    $globalHash{$id} = \%i;
    $self = \$id;
    return bless $self, $class;
}

#sub DESTROY {
#    my $self = shift;
#    warn "destroying $$self ";
    #for (values %globalHash) {
    #    next unless $_ && ref($_) eq 'Tree::Family::Person';
    #    $_->set('spouse' => undef);
    #    $_->set('dad'    => undef);
    #    $_->set('mom'    => undef);
    #}
#    delete $globalHash{$$self} if exists($globalHash{$$self});
#}

1;

