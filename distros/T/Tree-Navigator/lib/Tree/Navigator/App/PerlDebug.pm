=encoding utf8

=pod

TODO
  - add Pod/Pom/Web

=cut



package Tree::Navigator::App::PerlDebug;
use utf8;
use strict;
use warnings;
use Tree::Navigator;
use Plack 1.0004; # need 'harakiri mode' in HTTP::Server::PSGI
use Plack::Runner;
use Exporter qw/import/;

our @EXPORT_OK = qw/debug/;

sub debug {
    # create the navigator
    my $tn = Tree::Navigator->new(can_be_killed => 1);

    # each pair or arguments ($path => $ref) becomes a mount instruction
    while (@_ >= 2) {
      my ($path, $ref) = splice @_, 0, 2;
      $tn->mount($path => 'Perl::Ref' => {mount_point => {ref => $ref}});
    }

    # if one arg is remaining, it's an arrayref of options to Plack::Runner
    my $runner_options = shift || ["--access-log" => '/dev/null'];

    # tell about the objects being debugger
    my $debugged = join ", ", $tn->children;
    print STDERR "DEBUG STARTED; USE YOUR WEB BROWSER TO INSPECT $debugged\n";

    # mount Stack navigator
    $tn->mount(stack => 'Perl::StackTrace' => {mount_point => {}});

    # mount Class navigator
    $tn->mount(symdump => 'Perl::Symdump' => {mount_point => {}});

    # run the Web server
    my $runner = Plack::Runner->new;
    $runner->parse_options(@$runner_options);
    $runner->run($tn->to_app);

    # if reaching here, server has been killed by user
    print STDERR "END DEBUG SERVER, RESUMING NORMAL OPERATIONS\n";
}

1;


__END__

=head1 NAME

Tree::Navigator::App::PerlDebug - Navigating into memory of a running program

=head1 SYNOPSIS

  use Tree::Navigator::App::PerlDebug qw/debug/;
  
  ... # some code to be debugged
  
  # break here and inspect some data
  debug(self => $self, ENV => \%ENV, foo => $some_data);
  # now navigate to http:://localhost:5000
  
  ... # resume normal operations

=head1 DESCRIPTION

This module exports a single function called C<debug()>. Whenever this
function is called, the normal program execution flow stops, and a web
server is started, that allows you to browse through datastructures
and packages. By default, this server is located at
L<http://localhost:5000>. When you are done with debugging, click on
the B<"Stop debugging"> link, and the program will resume normal
execution.

This can also be used from within the Perl debugger : when at some breakpoint,
if you want to interactively browse through C<$self> and C<%ENV>, type something
like 

  DB<6> use Tree::Navigator::App::PerlDebug qw/debug/;
  DB<7> debug(self => $self, ENV => \%ENV);

and you will see

  DEBUG STARTED; USE YOUR WEB BROWSER TO INSPECT self, ENV
  HTTP::Server::PSGI::Mortal: Accepting connections at http://0:5000/

Use your favorite Web browser to inspect the data, then click
on the B<"Stop debugging"> link, and you are back in the Perl debugger :

  END DEBUG SERVER, RESUMING NORMAL OPERATIONS
  DB<8> 

=head1 FUNCTIONS

  debug(name1 => $ref1, name2 => $ref2, ..., \@server_options);

Arguments to C<debug()> are pairs of names and references; names will
label the root nodes displayed within the tree navigator, and 
references are the datastructures to browse.

Optionally, the last argument may be an arrayref of options
to be passed to the Web server, using the same syntax as for L<plackup>;
in particular, if you want a different port than the default 5000, 
use

  debug(name => $ref, ..., ["--port" => $port_number]);

=head1 SEE ALSO

L<Plack::Runner>, L<plackup>

=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

