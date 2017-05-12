package Zucchini::Types;
$Zucchini::Types::VERSION = '0.0.21';
{
  $Zucchini::Types::DIST = 'Zucchini';
}
use strict;
# ABSTRACT: Moo type definitions
use MooX::Types::MooseLike::Base;
use base qw(Exporter);
our @EXPORT_OK = ();
my $defs = [
{ 
  name => 'ZucchiniConfig', 
  test => sub { ref($_[0]) && 'Zucchini::Config' eq ref($_[0]) }, 
  message => sub { "$_[0] is not the type we want!" }
},
{ 
  name => 'NetFTP', 
  test => sub { ref($_[0]) && 'Net::FTP' eq ref($_[0]) }, 
  message => sub { "$_[0] is not the type we want!" }
},
{ 
  name => 'TemplateToolkit', 
  test => sub { ref($_[0]) && 'Template' eq ref($_[0]) }, 
  message => sub { "$_[0] is not the type we want!" }
},
];
MooX::Types::MooseLike::register_types($defs, __PACKAGE__);
# optionally add an 'all' tag so one can:
# use MyApp::Types qw/:all/; # to import all types
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

__END__

=pod

=encoding UTF-8

=head1 NAME

Zucchini::Types - Moo type definitions

=head1 VERSION

version 0.0.21

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
