package XAS::Logmon::Parser::XAS::Logs;

our $VERSION = '0.01';

use XAS::Lib::Regexp::Log::XAS;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim dotid db2dt',
  accessors => 'regex fields',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse {
    my $self = shift;
    my $line = shift;

    my %data;
    my $regex  = $self->regex;
    my $fields = $self->fields;

    if ((@data{@$fields}) = ($line =~ /$regex/)) {

        $data{'datetime'} = db2dt($data{'datetime'});
        $data{'message'}  = trim($data{'message'});
        $data{'type'}     = 'xas-logs';

        return \%data;

    }

    return undef;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $self = shift;
    my $config = shift;

    my @args;

    while (my ($key, $value) = each(%$config)) {

        push(@args, $key);
        push(@args, $value);

    }

    my $reg = XAS::Lib::Regexp::Log::XAS->new(@args);
    my @fields = $reg->capture;

    $self->{'regex'}  = $reg->regexp;
    $self->{'fields'} = \@fields;

    return $self;

}

1;

__END__

=head1 NAME

XAS::Logmon::Parser::XAS::Logs - A class to parse the XAS log files

=head1 SYNOPSIS

 use XAS::Logmon::Parser::XAS::Logs;

  my $parser = XAS::Logmon::Parser::XAS::Logs->new();

  if (my $data = $parser->parse($line)) {
 
  }

=head1 DESCRIPTION

This package will parse a line from a XAS log file.

=head1 METHODS

=head2 new

This method will initialize the class. It inherits from 
L<Regexp::Log|https://metacpan.org/pod/Regexp::Log>
and takes the same parameters. An optional format of ':tasks' will
return a regex that includes the "tasks" field. 

=head2 parse($line)

This method does the actual parsing. When done it will remove the trailing
new line from the "message" field and convert the "datetime" field into a
L<DateTime|https://metacpan.org/pod/DateTime> object. It returns a hash 
with the following fields:

  datetime level message

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon|XAS::Logmon>

=item L<XAS|XAS>

=item L<Regexp::Log|https://metacpan.org/pod/Regexp::Log>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
