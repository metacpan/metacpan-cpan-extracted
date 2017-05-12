use 5.006;
use strict;
use warnings;

package Test::Net::LDAP::Mock::Data;
use base qw(Test::Net::LDAP::Mixin);

use Net::LDAP;
use Net::LDAP::Constant qw(
    LDAP_SUCCESS
    LDAP_COMPARE_TRUE LDAP_COMPARE_FALSE
    LDAP_NO_SUCH_OBJECT LDAP_ALREADY_EXISTS
    LDAP_INVALID_DN_SYNTAX LDAP_PARAM_ERROR
    LDAP_INVALID_CREDENTIALS LDAP_INAPPROPRIATE_AUTH
);
use Net::LDAP::Entry;
use Net::LDAP::Filter;
use Net::LDAP::FilterMatch;
use Net::LDAP::Util qw(
    canonical_dn escape_dn_value ldap_explode_dn
);
use Scalar::Util qw(blessed);
use Test::Net::LDAP::Util;

my %scope = qw(base  0 one    1 single 1 sub    2 subtree 2);
my %deref = qw(never 0 search 1 find   2 always 3);
%scope = (%scope, map {$_ => $_} values %scope);
%deref = (%deref, map {$_ => $_} values %deref);

sub new {
    my ($class, $ldap) = @_;
    require Test::Net::LDAP::Mock::Node;
    
    my $self = bless {
        root => Test::Net::LDAP::Mock::Node->new,
        ldap => $ldap,
        schema => undef,
        bind_success => 0,
        password_mocked => 0,
        mock_bind_code => LDAP_SUCCESS,
        mock_bind_message => '',
    }, $class;
    
    $self->{ldap} ||= do {
        require Test::Net::LDAP::Mock;
        my $ldap = Test::Net::LDAP::Mock->new;
        $ldap->{mock_data} = $self;
        $ldap;
    };
    
    return $self;
}

sub root {
    shift->{root};
}

sub schema {
    my $self = shift;
    
    if (@_) {
        my $schema = $self->{schema};
        $self->{schema} = $_[0];
        return $schema;
    } else {
        return $self->{schema};
    }
}

sub ldap {
    my $self = shift;
    
    if (@_) {
        my $ldap = $self->{ldap};
        $self->{ldap} = $_[0];
        return $ldap;
    } else {
        return $self->{ldap};
    }
}

sub root_dse {
    my $self = shift;
    $self->ldap->root_dse(@_);
}

sub mock_root_dse {
    my $self = shift;
    my $root_node = $self->root;
    
    if (@_) {
        require Net::LDAP::RootDSE;
        my $old_entry = $root_node->entry;
        my $new_entry;
        
        if ($_[0] && blessed($_[0]) && $_[0]->isa('Net::LDAP::Entry')) {
            $new_entry = $_[0]->clone;
            $new_entry->dn('');
            
            unless ($new_entry->isa('Net::LDAP::RootDSE')) {
                bless $new_entry, 'Net::LDAP::RootDSE';
            }
        } else {
            $new_entry = Net::LDAP::RootDSE->new('', @_);
        }
        
        unless ($new_entry->get_value('objectClass')) {
            $new_entry->add(objectClass => 'top');
            # Net::LDAP::root_dse uses the filter '(objectclass=*)' to search
            # for the root DSE.
        }
        
        $root_node->entry($new_entry);
        return $old_entry;
    } else {
        return $root_node->entry;
    }
}

sub mock_bind {
    my $self = shift;
    my @values = ($self->{mock_bind_code}, $self->{mock_bind_message});
    
    if (@_) {
        $self->{mock_bind_code} = shift;
        $self->{mock_bind_message} = shift;
    }
    
    return wantarray ? @values : $values[0];
}

sub mock_password {
    my $self = shift;
    my $dn = shift or return;
    
    if (@_) {
        my $password = shift;
        $self->{password_mocked} = 1;
        my $node = $self->root->make_node($dn);
        return $node->password($password);
    } else {
        my $node = $self->root->get_node($dn) or return;
        return $node->password();
    }
}

sub _result_entry {
    my ($self, $input_entry, $arg) = @_;
    my $attrs = $arg->{attrs} || [];
    $attrs = [] if grep {$_ eq '*'} @$attrs;
    my $output_entry;
    
    if (@$attrs) {
        $output_entry = Net::LDAP::Entry->new;
        $output_entry->dn($input_entry->dn);
        
        $output_entry->add(
            map {$_ => [$input_entry->get_value($_)]} @$attrs
        );
    } else {
        $output_entry = $input_entry->clone;
    }
    
    $output_entry->changetype('modify');
    return $output_entry;
}

sub _error {
    my $self = shift;
    $self->ldap->_error(@_);
}

sub _mock_message {
    my $self = shift;
    $self->ldap->_mock_message(@_);
}

sub bind {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    require Net::LDAP::Bind;
    my $mesg = $self->_mock_message('Net::LDAP::Bind' => $arg);
    
    if ($self->{password_mocked} && exists $arg->{password}) {
        my $dn = $arg->{dn};
        
        if (!defined $dn) {
            return $self->_error($mesg, LDAP_INAPPROPRIATE_AUTH, 'No password, did you mean noauth or anonymous ?');
        }
        
        $dn = ldap_explode_dn($dn, casefold => 'lower')
            or return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
        
        my $node = $self->root->get_node($dn)
            or return $self->_error($mesg, LDAP_NO_SUCH_OBJECT, '');
        
        unless (defined $node->password && defined $arg->{password}
                && $node->password eq $arg->{password}) {
            return $self->_error($mesg, LDAP_INVALID_CREDENTIALS, '');
        }
    }
    
    if (my $code = $self->{mock_bind_code}) {
        my $message = $self->{mock_bind_message} || '';
        
        if (ref $code eq 'CODE') {
            # Callback
            my @result = $code->($arg);
            ($code, $message) = ($result[0] || LDAP_SUCCESS, $result[1] || $message);
        }
        
        if (blessed $code) {
            # Assume $code is a LDAP::Message
            ($code, $message) = ($code->code, $message || $code->error);
        }
        
        if ($code != LDAP_SUCCESS) {
            return $self->_error($mesg, $code, $message);
        }
    }
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

sub unbind {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg =  $self->_mock_message('Net::LDAP::Unbind' => $arg);
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

sub abandon {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg =  $self->_mock_message('Net::LDAP::Abandon' => $arg);
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

sub search {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    
    require Net::LDAP::Search;
    my $mesg = $self->_mock_message('Net::LDAP::Search' => $arg);
    
    # Configure params
    my $base = $arg->{base} || '';
    $base = ldap_explode_dn($base, casefold => 'lower');
    
    unless ($base) {
        return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
    }
    
    my $filter = $arg->{filter};
    
    if (defined $filter && !ref($filter) && $filter ne '') {
        my $f = Net::LDAP::Filter->new;
        
        unless ($f->parse($filter)) {
            return $self->_error($mesg, LDAP_PARAM_ERROR, 'Bad filter');
        }
        
        $filter = $f;
    } else {
        $filter = undef;
    }
    
    my $scope = defined $arg->{scope} ? $arg->{scope} : 'sub';
    $scope = $scope{$scope};
    
    unless (defined $scope) {
        return $self->_error($mesg, LDAP_PARAM_ERROR, 'invalid scope');
    }
    
    my $callback = $arg->{callback};
    
    # Traverse tree
    $mesg->{entries} = [];
    my $base_node = $base ? $self->root->get_node($base) : $self->root;
    
    unless ($base_node) {
        return $self->_error($mesg, LDAP_NO_SUCH_OBJECT, '');
    }
    
    $callback->($mesg) if $callback;
    
    $base_node->traverse(sub {
        my ($node) = @_;
        my $entry = $node->entry;
        my $schema = $self->schema;
        
        if ($entry && (!$filter || $filter->match($entry, $schema))) {
            my $result_entry = $self->_result_entry($entry, $arg);
            push @{$mesg->{entries}}, $result_entry;
            $callback->($mesg, $result_entry) if $callback;
        }
    }, $scope);
    
    return $mesg;
}

sub compare {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg = $self->_mock_message('Net::LDAP::Compare' => $arg);
    
    my $dn = (ref $arg->{dn} ? $arg->{dn}->dn : $arg->{dn});
    
    unless ($dn) {
        return $self->_error($mesg, LDAP_PARAM_ERROR, 'No DN specified');
    }
    
    my $dn_list = ldap_explode_dn($dn, casefold => 'lower');
    
    unless ($dn_list) {
        return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
    }
    
    my $attr = exists $arg->{attr}
        ? $arg->{attr}
        : exists $arg->{attrs} #compat
            ? $arg->{attrs}[0]
            : "";

    my $value = exists $arg->{value}
        ? $arg->{value}
        : exists $arg->{attrs} #compat
            ? $arg->{attrs}[1]
            : "";
    
    my $node = $self->root->get_node($dn_list);
    
    unless ($node && $node->entry) {
        return $self->_error($mesg, LDAP_NO_SUCH_OBJECT, '');
    }
    
    my $entry = $node->entry;
    
    my $filter = bless {
        equalityMatch => {
            attributeDesc => $attr,
            assertionValue => $value,
        }
    }, 'Net::LDAP::Filter';
    
    $mesg->{resultCode} = $filter->match($entry, $self->schema)
        ? LDAP_COMPARE_TRUE : LDAP_COMPARE_FALSE;
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

sub add {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg = $self->_mock_message('Net::LDAP::Add' => $arg);
    
    my $dn = ref $arg->{dn} ? $arg->{dn}->dn : $arg->{dn};
    
    unless ($dn) {
        return $self->_error($mesg, LDAP_PARAM_ERROR, 'No DN specified');
    }
    
    my $dn_list = ldap_explode_dn($dn, casefold => 'lower');
    
    unless ($dn_list) {
        return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
    }
    
    my $node = $self->root->make_node($dn);
    
    if ($node->entry) {
        return $self->_error($mesg, LDAP_ALREADY_EXISTS, '');
    }
    
    my $entry;
    
    if (ref $arg->{dn}) {
        $entry = $arg->{dn}->clone;
    } else {
        $entry = Net::LDAP::Entry->new(
            $arg->{dn},
            @{$arg->{attrs} || $arg->{attr} || []}
        );
    }
    
    if (my $rdn = $dn_list->[0]) {
        $entry->delete(%$rdn);
        $entry->add(%$rdn);
    }
    
    $entry->changetype('add');
    $node->entry($entry);
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

my %opcode = (add => 0, delete => 1, replace => 2, increment => 3);

sub modify {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg = $self->_mock_message('Net::LDAP::Modify' => $arg);
    
    my $dn = (ref $arg->{dn} ? $arg->{dn}->dn : $arg->{dn});
    
    unless ($dn) {
        return $self->_error($mesg, LDAP_PARAM_ERROR, 'No DN specified');
    }
    
    my $dn_list = ldap_explode_dn($dn, casefold => 'lower');
    
    unless ($dn_list) {
        return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
    }
    
    my $node = $self->root->get_node($dn_list);
    
    unless ($node && $node->entry) {
        return $self->_error($mesg, LDAP_NO_SUCH_OBJECT, '');
    }
    
    my $entry = $node->entry;
    
    if (exists $arg->{changes}) {
        for (my $j = 0; $j < @{$arg->{changes}}; $j += 2) {
            my $op = $arg->{changes}[$j];
            my $chg = $arg->{changes}[$j + 1];
            
            unless (defined $opcode{$op}) {
                return $self->_error($mesg, LDAP_PARAM_ERROR, "Bad change type '$op'");
            }
            
            $entry->$op(@$chg);
        }
    } else {
        for my $op (keys %opcode) {
            my $chg = $arg->{$op} or next;
            my $opcode = $opcode{$op};
            my $ref_chg = ref $chg;
            
            if ($opcode == 3) {
                # $op eq 'increment'
                if ($ref_chg eq 'HASH') {
                    for my $attr (keys %$chg) {
                        my $incr = $chg->{$attr};
                        
                        $entry->replace(
                            $attr => [map {$_ + $incr} $entry->get_value($attr)]
                        );
                    }
                } elsif ($ref_chg eq 'ARRAY') {
                    for (my $i = 0; $i < @$chg; $i += 2) {
                        my ($attr, $incr) = ($chg->[$i], $chg->[$i + 1]);
                        next unless defined $incr;
                        
                        $entry->replace(
                            $attr => [map {$_ + $incr} $entry->get_value($attr)]
                        );
                    }
                } elsif (!$ref_chg) {
                    $entry->replace(
                        $chg => [map {$_ + 1} $entry->get_value($chg)]
                    );
                }
            } elsif ($ref_chg eq 'HASH') {
                $entry->$op(%$chg);
            } elsif ($ref_chg eq 'ARRAY') {
                if ($opcode == 1) {
                    # $op eq 'delete'
                    $entry->$op(map {$_ => []} @$chg);
                } else {
                    $entry->$op(@$chg);
                }
            } elsif (!$ref_chg) {
                $entry->$op($chg => []);
            }
        }
    }
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

sub delete {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg = $self->_mock_message('Net::LDAP::Delete' => $arg);
    
    my $dn = (ref $arg->{dn} ? $arg->{dn}->dn : $arg->{dn});
    
    unless ($dn) {
        return $self->_error($mesg, LDAP_PARAM_ERROR, 'No DN specified');
    }
    
    my $dn_list = ldap_explode_dn($dn, casefold => 'lower');
    
    unless ($dn_list) {
        return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
    }
    
    my $node = $self->root->get_node($dn_list);
    
    unless ($node && $node->entry) {
        return $self->_error($mesg, LDAP_NO_SUCH_OBJECT, '');
    }
    
    $node->entry(undef);
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

sub moddn {
    my $self = shift;
    my $arg = &Net::LDAP::_dn_options;
    my $mesg = $self->_mock_message('Net::LDAP::ModDN' => $arg);
    
    my $dn = (ref $arg->{dn} ? $arg->{dn}->dn : $arg->{dn});
    
    unless ($dn) {
        return $self->_error($mesg, LDAP_PARAM_ERROR, 'No DN specified');
    }
    
    my $dn_list = ldap_explode_dn($dn, casefold => 'lower');
    
    unless ($dn_list) {
        return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid DN');
    }
    
    my $old_rdn = $dn_list->[0];
    my $old_node = $self->root->get_node($dn_list);
    
    unless ($old_node && $old_node->entry) {
        return $self->_error($mesg, LDAP_NO_SUCH_OBJECT, '');
    }
    
    # Configure new RDN
    my $new_rdn;
    my $rdn_changed = 0;
    
    if (defined(my $new_rdn_value = $arg->{newrdn})) {
        my $new_rdn_list = ldap_explode_dn($new_rdn_value, casefold => 'lower');
        
        unless ($new_rdn_list) {
            return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid new RDN');
        }
        
        $new_rdn = $new_rdn_list->[0];
        $rdn_changed = 1;
    } else {
        $new_rdn = $dn_list->[0];
    }
    
    # Configure new DN
    if (defined(my $new_superior = $arg->{newsuperior})) {
        $dn_list = ldap_explode_dn($new_superior, casefold => 'lower');
        
        unless ($dn_list) {
            return $self->_error($mesg, LDAP_INVALID_DN_SYNTAX, 'invalid newSuperior');
        }
        
        unshift @$dn_list, $new_rdn;
    } else {
        $dn_list->[0] = $new_rdn;
    }
    
    my $new_dn = canonical_dn($dn_list, casefold => 'lower');
    
    # Create new node
    my $new_node = $self->root->make_node($dn_list);
    
    if ($new_node->entry) {
        return $self->_error($mesg, LDAP_ALREADY_EXISTS, '');
    }
    
    # Set up new entry
    my $new_entry = $old_node->entry;
    $old_node->entry(undef);
    
    $new_entry->dn($new_dn);
    
    if ($rdn_changed) {
        if ($arg->{deleteoldrdn}) {
            $new_entry->delete(%$old_rdn);
        }
        
        $new_entry->delete(%$new_rdn);
        $new_entry->add(%$new_rdn);
    }
    
    $new_node->entry($new_entry);
    
    if (my $callback = $arg->{callback}) {
        $callback->($mesg);
    }
    
    return $mesg;
}

1;
