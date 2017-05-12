package WSST::CodeTemplate;

use strict;
use Template;

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    
    my $self = {@_};
    $self->{tmpl_dirs} ||= [];
    $self->{vars} ||= {};
    
    bless($self, $class);
    
    return $self;
}

sub get {
    my $self = shift;
    my $key = shift;
    return $self->{vars}->{$key};
}

sub set {
    my $self = shift;
    %{$self->{vars}} = (%{$self->{vars}}, @_);
}

sub expand {
    my $self = shift;
    my $name = shift;
    my %local_vars = @_;
    
    my $tmpl = $self->new_template($name);
    
    my $vars = {%{$self->{vars}}, %local_vars};
    
    my $output;
    my $res = $tmpl->process($name, $vars, \$output);

    die "TemplateError: $name: " . $tmpl->error() unless $res;
    
    foreach my $key (keys %$vars) {
        next if exists $local_vars{$key};
        $self->{vars}->{$key} = $vars->{$key};
    }
    
    return $output;
}

sub new_template {
    my $self = shift;
    my $name = shift;

    my $conf = {
        INCLUDE_PATH => $self->{tmpl_dirs},
    };
    return Template->new($conf);
}

=head1 NAME

WSST::CodeTemplate - CodeTemplate class of WSST

=head1 DESCRIPTION

CodeTemplate is class encapsulating the Template Toolkit.

=head1 METHODS

=head2 new

Constructor.

=head2 get

Returns template variable of the specified name.

=head2 set

Set template variable.

=head2 expand

Expand the specified template file.

=head2 new_template

Create new Template object.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
