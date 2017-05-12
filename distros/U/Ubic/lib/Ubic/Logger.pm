package Ubic::Logger;
$Ubic::Logger::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: very simple logging functions


use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

use parent qw(Exporter);
our @EXPORT = qw( INFO ERROR );

sub INFO {
    print '[', scalar(localtime), "]\t", @_, "\n";
}

sub ERROR {
    my @message = ('[', scalar(localtime), "]\t", @_, "\n");
    if (-t STDOUT) {
        print RED(@message);
    }
    else {
        print @message;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Logger - very simple logging functions

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::Logger;
    INFO("hello");
    ERROR("Fire! Fire!");

=head1 FUNCTIONS

=over

=item B<INFO(@data)>

Log something.

=item B<ERROR(@data)>

Log some error.

Message will be red if writing to terminal.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
