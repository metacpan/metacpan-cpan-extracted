=head1 NAME

WWW::Link::Tester::Base - base functions and settings for link testing functions

=head1 SYNOPSIS

   use WWW::Link::Tester::Base;

=head1 DESCRIPTION

Various settings and defaults are shared between the different
WWW::Link::Test::xxx modules.  This is a place to put them.

=cut

sub MAX_REDIRECTS {15;}

sub new () {
  my $proto=shift;
}
