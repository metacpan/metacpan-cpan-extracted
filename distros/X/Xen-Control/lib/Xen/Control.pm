package Xen::Control;

=head1 NAME

Xen::Control - control and fetch information about xen domains

=head1 SYNOPSIS

    my $xen = Xen::Control->new();
    my @domains = $xen->ls;

=head1 DESCRIPTION

This is a wrapper module interface to Xen `xm` command.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Carp::Clan 'croak';
use Xen::Domain;

use base 'Class::Accessor::Fast';

our $XM_COMMAND         = 'sudo xm';
our $RM_COMMAND         = 'sudo rm';
our $HIBERNATION_FOLDER = '/var/tmp';

=head1 PROPERTIES

    xm_cmd
    rm_cmd
    hibernation_folder

=head2 xm_cmd

Holds the command that is used execute xm command. By default it is `sudo xm`.

=head2 rm_cmd

Holds the command that is executed to remove xen state files after beeing
restored. default is `sudo rm`.

=head2 hibernation_folder

Holds the folder where hibernation domain files will be stored.

=cut

__PACKAGE__->mk_accessors(qw{
    xm_cmd
    rm_cmd
    hibernation_folder
});

=head1 XM_METHODS

C<xm> calling methods methods.

=head2 create($domain_name)

Starts domain with C<$domain_name>. If the domain is hibernated the the
function calls C<restore> otherwise
C<< $self->xm('create', $domain_name.'.cfg') >>.

=cut

sub create {
    my $self        = shift;
    my $domain_name = shift;
    
    croak 'pass domain name'
        if not defined $domain_name;
    
    if (-f $self->hibernated_filename($domain_name)) {
        $self->restore($domain_name);
        return;
    }
    
    $self->xm('create', $domain_name.'.cfg');
}


=head2 ls

=head2 list

Returns an array of L<Xen::Domain> objects representing curently running
Xen machines.

=cut

*ls = *list;

sub list {
    my $self = shift;
    
    my @xm_ls = $self->xm('list');
    shift @xm_ls;
    
    my @domains;
    foreach my $domain_line (@xm_ls) {
        chomp $domain_line;
        if ($domain_line !~ /^([-_\w]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([-a-z]+)\s+([0-9.]+)$/) {
            warn 'badly formated domain line - "'.$domain_line.'"';
            next;
        }
        
        push @domains, Xen::Domain->new(
            'name'  => $1,
            'id'    => int($2),
            'mem'   => int($3),
            'vcpus' => int($4),
            'state' => $5,
            'times' => $6,
        );
    }
    
    return @domains;
}


=head2 save($domain_name)

Hibernate domain named $domain_name. If the name is is not set - undef, will
hibernate all domains.

=cut

sub save {
    my $self        = shift;
    my $domain_name = shift;
    
    if (not defined $domain_name) {
        foreach my $domain ($self->ls) {
            # skip domain zero
            next if $domain->id == 0;
            
            die 'domain with id '.$domain->id.' has a "undef" name'
                if not defined $domain->name;
            
            $self->save($domain->name);
        }
        
        return;
    }
    
    $self->xm('save', $domain_name, $self->hibernated_filename($domain_name));
    
    return;
}


=head2 restore($domain_name)

Wakeup hibernated domain named $domain_name. If the name is is not set - undef, will
wakeup all hibernated domains.

=cut

sub restore {
    my $self        = shift;
    my $domain_name = shift;
    
    if (not defined $domain_name) {
        foreach my $h_domain_name ($self->hibernated_domains) {
            die 'domain with "undef" name'
                if not defined $h_domain_name;
            
            $self->restore($h_domain_name);
        }
        
        return;
    }
    
    $self->xm('restore', $self->hibernated_filename($domain_name));
    
    # remove state file of restored machine
    my $rm_cmd = $self->rm_cmd.' '.$self->hibernated_filename($domain_name);
    `$rm_cmd`;
    
    return;
}


=head2 shutdown($domain_name)

Shutdown domain named $domain_name. If the name is is not set - undef, will
shutdown all domains.

=cut

sub shutdown {
    my $self        = shift;
    my $domain_name = shift;
    
    if (not defined $domain_name) {
        $self->xm('shutdown', '-a');
        
        return;
    }
    
    $self->xm('shutdown', $domain_name);
    
    return;
}


=head2 xm(@args)

Execute C<< $self->xm_cmd >> with @args and return the output.
Dies if the execution fails.

=cut

sub xm {
    my $self = shift;
    my @args = map { quotemeta($_) } @_;
    
    my $xm_cmd = $self->xm_cmd.' '.join(' ', @args);
    my @output = `$xm_cmd`;
    
    die 'failed to execute "'.$xm_cmd.'"' if (($? >> 8) != 0);
    
    return @output;
}


=head1 METHODS

Other object methods, mostly for internal usage.

=head2 new()

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new({
        'xm_cmd' => $XM_COMMAND,
        'rm_cmd' => $RM_COMMAND,
        'hibernation_folder' => $HIBERNATION_FOLDER,
        @_
    });
    
    return $self;
}


=head2 hibernated_filename($domain_name)

Returns filename with path of the C<$domain_name> domain.

=cut

sub hibernated_filename {
    my $self        = shift;
    my $domain_name = shift;
    
    croak 'set domain_name'
        if not defined $domain_name;
    
    return $self->hibernation_folder.'/'.$domain_name.'.xen';
}


=head2 hibernated_domains()

Search through C<< $self->hibernation_folder >> for files that end up with
C<.xen> extension and return their names without the extension. So the
return value is an array of hibernated domain names.

=cut

sub hibernated_domains {
    my $self = shift;
    
    my $hfolder = $self->hibernation_folder;
    
    opendir(my $tmp_folder, $hfolder)
        or die 'failed to open "'.$hfolder.'" - '.$!;
    
    my @domain_names =
        map  { substr($_, 0, -4) }                                 # remove .xen from the filename
        grep { $_ =~ m/^[-_\w]+[.]xen$/ and -f $hfolder.'/'.$_ }   # just files with .xen extension
        readdir($tmp_folder);
    
    closedir($tmp_folder);
    
    return @domain_names;
}



1;


__END__

=head1 TODO

Try IPC::System::Simple instead of ``.

=head1 LINKS

Subversion repository L<https://cle.sk/repos/pub/cpan/Xen-Control/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xen-control at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Xen-Control>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Xen::Control

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Xen-Control>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Xen-Control>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Xen-Control>

=item * Search CPAN

L<http://search.cpan.org/dist/Xen-Control>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
