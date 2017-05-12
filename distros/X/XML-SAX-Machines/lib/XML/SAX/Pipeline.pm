package XML::SAX::Pipeline;
{
  $XML::SAX::Pipeline::VERSION = '0.46';
}
# ABSTRACT: Manage a linear pipeline of SAX processors


use base qw( XML::SAX::Machine );


use strict;
use Carp;


sub new {
    my $proto = shift;
    my $options = @_ && ref $_[-1] eq "HASH" ? pop : {};

    my $stage_number = 0;
    my @machine_spec = map [ "Stage_" . $stage_number++, $_ ], @_;
    push @{$machine_spec[$_]}, $_ + 1 for 0..$#machine_spec-1 ;
    $machine_spec[0]->[0] = "Intake"   if @machine_spec;
    push @{$machine_spec[-1]}, "Exhaust" if @machine_spec;

    return $proto->SUPER::new( @machine_spec, $options );
}


1;

__END__

=pod

=head1 NAME

XML::SAX::Pipeline - Manage a linear pipeline of SAX processors

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use XML::SAX::Machines qw( Pipeline );   ## Most common way
    use XML::Fitler::Foo;

    my $m = Pipeline(
        XML::Filter::Foo->new,  ## Create it manually
        "XML::Filter::Bar",     ## Or let Pipeline load & create it
        "XML::Filter::Baz",
	{
	    ## Normal options
            Handler => $h,
	}
    );

    ## To choose the default parser automatically if XML::Filter::Foo
    ## does not implement a parse_file method, just pretend the Pipeline
    ## is a parser:
    $m->parse_file( "blah" );

    ## To feed the pipeline from an upstream processor, treat it like
    ## any other SAX filter:
    my $p = Some::SAX::Generator->new( Handler => $m );

    ## To read a file or the output from a subprocess:
    my $m = Pipeline( "<infile.txt" );
    my $m = Pipeline( "spew_xml |" );

    ## To send output to a file handle, file, or process:
    my $m = Pipeline( ...,  \*STDOUT );
    my $m = Pipeline( ..., ">outfile.txt" );
    my $m = Pipeline( ..., "| xmllint --format -" );

=head1 DESCRIPTION

An XML::SAX::Pipeline is a linear sequence SAX processors.  Events
passed to the pipeline are received by the C<Intake> end of the pipeline
and the last filter to process events in the pipeline passes the events
out the C<Exhaust> to the filter set as the pipeline's handler:

   +-----------------------------------------------------------+
   |                 An XML:SAX::Pipeline                      |
   |    Intake                                                 |
   |   +---------+    +---------+         +---------+  Exhaust |
 --+-->| Stage_0 |--->| Stage_1 |-->...-->| Stage_N |----------+----->
   |   +---------+    +---------+         +---------+          |
   +-----------------------------------------------------------+

As with all SAX machines, a pipeline can also create an ad hoc parser
(using L<XML::SAX::ParserFactory>) if you ask it to parse something and
the first SAX processer in the pipeline can't handle a parse request:

   +-------------------------------------------------------+
   |                 An XML:SAX::Pipeline                  |
   |                 Intake                                |
   | +--------+   +---------+         +---------+  Exhaust |
   | | Parser |-->| Stage_0 |-->...-->| Stage_N |----------+----->
   | +--------+   +---------+         +---------+          |
   +-------------------------------------------------------+

or if you specify an input file like so:

   my $m = Pipeline(qw(
       <input_file.xml
       XML::Filter::Bar
       XML::Filter::Baz
   ));

Pipelines (and machines) can also create ad hoc XML::SAX::Writer
instances when you specify an output file handle (as shown in the
SYNOPSIS) or an output file:

   my $m = Pipeline(qw(
       XML::Filter::Bar
       XML::Filter::Baz
       >output_file.xml
   ));

And, thanks to Perl's magic open (see L<perlopentut>), you can read
and write from processes:

   my $m = Pipeline(
       "gen_xml.pl |",
       "XML::Filter::Bar",
       "XML::Filter::Baz",
       "| consume_xml.pl",
   );

This can be used with an L<XML::SAX::Tap> to place a handy debugging
tap in a pipeline (or other machine):

   my $m = Pipeline(
       "<input_file.xml"
       "XML::Filter::Bar",
       Tap( "| xmllint --format -" ),
       "XML::Filter::Baz",
       ">output_file.xml",
   );

=head1 NAME

XML::SAX::Pipeline - Manage a linear pipeline of SAX processors

=head1 METHODS

See L<XML::SAX::Machine> for most of the methods.

=over

=item new

    my $pipeline = XML::SAX::Pipeline->new( @processors, \%options );

Creates a pipeline and links all of the given processors together.  Longhand
for Pipeline().

=back

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of the Artistic, GNU Public,
or BSD licenses, your choice.

=head1 AUTHORS

=over 4

=item *

Barry Slaymaker

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Barry Slaymaker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
