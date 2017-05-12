package WWW::Bugzilla::Search;

$WWW::Bugzilla::Search::VERSION = '0.2';

use strict;
use warnings;
use WWW::Mechanize;
use Carp qw(croak carp);
use Params::Validate;
use vars qw($VERSION @ISA @EXPORT);
use WWW::Bugzilla;

=head1 NAME

WWW::Bugzilla::Search - Handles searching bugzilla bugs via WWW::Mechanize.

=head1 SYNOPSIS

    use WWW::Bugzilla::Search;

    # Login
    my $search = WWW::Bugzilla::Search->new(
        server => 'bugs.example.com',
        email => 'user@example.com',
        password => 'my_passwd',
    );

    $search->summary('This is my summary');
    my @bugs = $search->search();

=head1 DESCRIPTION

WWW::Bugzilla::Search provides an API to search for bugs in a Bugzilla database.  Any resulting bugs will be returned as instances of WWW::Bugzilla bugs.

=head1 INTERFACE

=head2 Multiple choice search criteria 

The following fields are multiple choice fields: 

classification, component, op_sys, priority, product, resolution, bug_severity, bug_status, target_milestone, version, hardware, rep_platform

Available options can be retrieved via:
    
    $search->field();

To choose a given value, use:
    
    $search->field('value');

=head2 Text search criteria

The following fields are avaiilable for text searching:

assigned_to, reporter, summary

To searc using a given field, use:

    $search->field('value');

=head2 Methods

=head3 search()

Searches Bugzilla with the defined criteria.  Returns a list of bugs that match the criteria.  Each bug is a seperate instance of WWW::Bugzilla

=head3 reset()

Resets all search criteria.

=over

=back

=cut 


#sub AUTOLOAD {
#    my $self = shift;
#    my $name = $AUTOLOAD;
#
#    warn Dumper($self->{'_fields'});
#    if ($self->{'_fields'}{$name}) {
#        $name =~ s/^WWW::Bugzilla::Search:://;
#        my $out =$self->_field_values($name);
#    #    warn Dumper($out);
#    }
#
#    if (@_) {
#        return $self->{$name} = shift;
#    } else {
#        if (defined($self->{$name})) {
#            return $self->{$name};
#        } else {
#            return;
#        }
#    }
#}

my $_SETUP;

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self  = {
        search_keys => {},
        protocol => '',
        server=> '',
    };
    bless $self, $class;

    if (!$_SETUP) {
        no strict 'refs';
        # accessors
        foreach my $field (qw(mech protocol server email password)) {
            *{ $class . '::' . $field } = sub { my ($self, $value) = @_; if (defined $value) { $self->{$field} = $value; } return $self->{$field} }
        }
        
        # search fields
        foreach my $field (qw(classification component op_sys priority product resolution bug_severity bug_status target_milestone version hardware rep_platform)) {
            *{ $class . '::' . $field } = sub {
                my ($self, $value) = @_; 
                if (defined $value) {
                    $self->{'search_keys'}{$field} = $value;
                    return $value;
                } else {
                    return $self->_field_values($field); 
                }
            }
        }

        # search fields that are used as accessors
        foreach my $field (qw(assigned_to reporter summary)) {
            *{ $class . '::' . $field } = sub { my ($self, $value) = @_; if (defined $value) { $self->{'search_keys'}{$field} = $value; } return $self->{'search_keys'}{$field} }
        }
        $_SETUP++;
    }

    if (@_) {
        my %conf = @_;
        while (my ($k, $v) = each %conf) {
            $self->$k($v);
        }
    }

    $self->protocol('http') if !$self->protocol();

    $self->{'mech'} = WWW::Mechanize->new();
    $self->_login();
    
    return $self;
}

sub _field_values {
    my ($self, $name) = @_;
    my $url = $self->protocol().'://'.$self->server().'/query.cgi?format=advanced';
    my $mech = $self->{'mech'};
    if ($mech->{'uri'} ne $url) {
        $mech->get( $url); 
    }
    $mech->form_name('queryform');

    my @values;

    my $form = $mech->current_form();
    foreach my $field ($form->inputs()) {
        if ($field->name && $field->name eq $name) {
            push (@values, grep { defined $_ }$field->possible_values());
        }
    }
    if (@values) {
        return grep { defined $_ } @values;
    }
    warn "no values for $name";
    return;
}

sub reset {
    my ($self) = @_;

    $self->{'search_keys'} = {};
}

sub search {
    my ($self) = @_;
    my $mech = $self->{'mech'};
    my $login_page = $self->protocol().'://'.$self->server().'/query.cgi?format=advanced';
    $mech->get( $login_page ); 
    $mech->form_name('queryform');

    foreach my $key (keys %{ $self->{'search_keys'} }) {
        my $value =  $self->{'search_keys'}{$key};
        if ($key eq 'summary') {
            $mech->field('short_desc', $value, 1);
        } elsif ($key eq 'assigned_to') {
            $mech->field('email1', $value);
            $mech->field('emailtype1', 'regexp') if (ref($value) eq 'Regexp');
        } elsif ($key eq 'reporter') {
            $mech->field('email2', $value);
            $mech->field('emailtype2', 'regexp') if (ref($value) eq 'Regexp');
            $mech->tick('emailreporter2', 1);
            map($mech->untick($_, 1), qw(emailqa_contact2 emailassigned_to2 emailcc2));
        } else {
            if ($self->_field_values($key)) {
                # ghetto hack.  Grr, Mechanize is making each of the form elements a seperate entry.
                my $i = 1;
                foreach my $input ($mech->current_form()->inputs()) {
                    next if (defined $input->name && $input->name ne $key);
                    foreach my $val ($input->possible_values) {
                        next if !defined $val;
                        if ($value eq $val) {
                            $input->value($value);
                           # $mech->field($key, $value, $i);
                        }
                    }
                    $i++;
                }
            } else {
                $mech->field($key, $self->{'search_keys'}{$key});
            }
        }
    }

    $mech->submit();
    my @bugs;
    foreach my $link ($mech->links()) {
        if ($link->url() =~ /^show_bug\.cgi\?id=(\d+)$/) {
            push (@bugs, WWW::Bugzilla->new( 'server' => $self->{'server'}, 'email' => $self->{'email'}, 'password' => $self->{'password'}, 'bug_number' => $1, 'use_ssl' => ($self->protocol() eq 'https') ? 1 : 0));
        }
    }
    return @bugs;
}

# based on the current page, set the current form to the first form with a specified field
sub _get_form_by_field {
    my ($self, $field) = @_;
    croak("invalid field") if !$field;

    my $mech = $self->{'mech'};
    my $i = 1;
    foreach my $form ($mech->forms()) {
        if ($form->find_input($field)) {
            $mech->form_number($i);
            return 1;
        }
        $i++;
    }
    return;
}

sub _login {
    my $self = shift;
    my $mech = $self->{'mech'};
    my $login_page = $self->protocol().'://'.$self->server().'/query.cgi?GoAheadAndLogIn=1';
    $mech->get( $login_page ); 

    # bail unless OK or Redirect happens
    croak("Cannot open page $login_page") unless ( ($mech->status == '200') or ($mech->status == '404') );
    croak("Login form is missing") if !$self->_get_form_by_field('Bugzilla_login');
    $mech->field('Bugzilla_login', $self->email());
    $mech->field('Bugzilla_password', $self->password());
    $mech->submit_form();
    $mech->get( $login_page );
    croak("Login failed") if $self->_get_form_by_field('Bugzilla_login');
}

=head1 BUGS, IMPROVEMENTS

There may well be bugs in this module.  Using it as I have, I just have not run
into any.  In addition, this module does not support ALL of Bugzilla's
features.  I will consider any patches or improvements, just send me an email
at the address listed below.
 
=head1 AUTHOR

Written by:
    Brian Caswell (bmc@shmoo.com)

Portions taken from WWW::Bugzilla, originally written by:
    Matthew C. Vella (the_mcv@yahoo.com)

=head1 LICENSE
                                                                      
  WWW::Bugzilla::Search - Module providing API to search Bugzilla bugs.
  Copyright (C) 2006 Brian Caswell (bmc@shmoo.com)

  Portions Copyright (C) 2003 Matthew C. Vella (the_mcv@yahoo.com)
                                                                    
  This module is free software; you can redistribute it and/or modify it
  under the terms of either:
                                                                      
  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,                                                                      
  or
                                                                      
  b) the "Artistic License" which comes with this module.
                                                                      
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
  the GNU General Public License or the Artistic License for more details.
                                                                      
  You should have received a copy of the Artistic License with this
  module, in the file ARTISTIC.  If not, I'll be glad to provide one.
                                                                      
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  USA

=cut

1;
