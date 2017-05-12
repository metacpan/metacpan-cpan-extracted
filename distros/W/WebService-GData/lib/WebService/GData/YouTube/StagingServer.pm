package WebService::GData::YouTube::StagingServer;

my $staging;
sub import { $staging=1 }
sub is_on { $staging }

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::StagingServer - switch to the staging server.

=head1 SYNOPSIS

    use WebService::GData::YouTube::StagingServer;
    use WebService::GData::YouTube;

    #all interaction will be done via the staging server
    #uncomment the use line to go back to live server
    
    my $yt = new WebService::GData::YouTube();


=head1 DESCRIPTION

!DEVELOPER RELEASE! API may change, program may break or be under optimized.


This package is just a flag that forces all the youtube related packages to use the staging server urls
instead of the live server.

You must use it before *any* YouTube::* related packages. Most of the time, the above SYNOPSYS will be all you have to do.

You should use this module on your own staging server (never on the live one!) to see 
if an upcoming API modifications could break your program.

See: L<http://apiblog.youtube.com/2008/11/all-worlds-stage.html> for further information.


=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut