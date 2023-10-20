package Thread::CSP;
$Thread::CSP::VERSION = '0.011';
use strict;
use warnings;

use 5.008001;

use XSLoader;
XSLoader::load('Thread::CSP');

1;

#ABSTRACT: Communicating sequential processes threading for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::CSP - Communicating sequential processes threading for Perl

=head1 VERSION

version 0.011

=head1 SYNOPSIS

 # in script.pl
 use Thread::CSP;
 my $input = Thread::CSP::Channel->new;
 my $output = Thread::CSP::Channel->new;
 Thread::CSP->spawn('Module', 'Module::function', $input, $output);

 while (<>) {
     $input->send($_);
     print $output->receive;
 }
 $input->send(undef);


 # in Module.pm
 package Module;
 sub function {
     my ($input, $output) = @_;
     while (defined(my $entry = $input->receive)) {
         $output->send(2 * $entry);
     }
 }
 1;

=head1 DESCRIPTION

This module implements share-nothing threads for perl. One crucial difference with C<threads.pm> threads is that the original thread will not be cloned except for the arguments that you pass on thread creation. L<Thread::CSP::Channel|Thread::CSP::Channel>s (also using cloning to get values across) are used for inter-thread communication; one or more channels will nearly always be such creation arguments.

Please note that B<at this stage this module is a research project>. In no way is API stability guaranteed. It is released for evaluation purposes only, not for production usage.

=head1 METHODS

=head2 spawn($module, $sub, @args)

Spawn a new thread. It will load $module and then run C<$sub> (fully-qualified function name) with C<@args> as arguments. It returns a L<Thread::CSP::Promise|Thread::CSP::Promise> that will finish when the thread is finished.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
