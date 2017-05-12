package WWW::Session::Storage::File;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::Session::Storage::File - File storage engine for WWW::Session

=head1 DESCRIPTION

File backend for WWWW::Session

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

This module is used for storring serialized WWW::Session objects

Usage : 

    use WWW::Session::Storage::File;

    my $storage = WWW::Session::Storage::File->new({path => '/tmp/sessions'});
    ...
    
    $storage->save($session_id,$expires,$serialized_data);
    
    my $serialized_data = $storage->retrive($session_id);
    

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new WWW::Session::Storage::File object

This method accepts only one argument, a hashref that must contain a key named
"path" which defines the path where the sessions will be saved

=cut

sub new {
    my ($class,$params) = @_;
    
    die "You must specify the path where to save the sessions!" unless defined $params->{path};
    
    die "Cannot save sessions in folder '".$params->{path}."' because the folder does not exist!" unless -d $params->{path};
    
    my $self = {
                path => $params->{path}
               };
    
    bless $self, $class;
    
    return $self;
}

=head2 save

Stores the given information into the file

=cut
sub save {
    my ($self,$sid,$expires,$string) = @_;
    
    open(my $fh,">",$self->{path}."/".$sid);
    
    print $fh $expires . "\n";
    print $fh $string;
    
    close($fh);
}

=head2 retrieve

Retrieves the informations for a session, verifies that it's not expired and returns
the string containing the serialized data

=cut
sub retrieve {
    my ($self,$sid) = @_;
    
    my $filename = $self->{path}."/".$sid;
    
    return undef unless -f $filename;
    
    my @file_info = stat($filename);
    
    open(my $fh,"<",$self->{path}."/".$sid) || return undef;
    
    local $/ = "\n";
    
    my $expires= readline($fh);
    
    local $/ = undef;
    
    my $string = readline($fh);
    
    close($fh);
    
    #check if it didn't expire
    if ($expires != -1 && ($file_info[8] + $expires) < time() ) {
        unlink $filename;
        return undef;
    }
    
    return $string;
}

=head2 delete

Completely removes the session data for the given session id

=cut
sub delete {
    my ($self,$sid) = @_;
    
    my $filename = $self->{path}."/".$sid;
    
    if (-f $filename) {
        unlink($filename);
    }
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Session::Storage::File


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Session::Storage::File
