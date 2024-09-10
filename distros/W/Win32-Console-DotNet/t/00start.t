=pod

=head1 DESCRIPTION

Performs no real testing, but prints relevant information about the system it's 
being run on, such as the version numbers of dependencies, the values of 
important environment variables, etc.

=head1 SEE ALSO

L<Perl Testing in 2023|https://toby.ink/blog/2023/01/24/perl-testing-in-2023/>

L<TOBYINK/Type-Tiny/t/00-begin.t|https://metacpan.org/release/TOBYINK/Type-Tiny-2.004000/source/t/00-begin.t>

=head1 COPYRIGHT AND LICENCE

This script is copyright (c) 2013-2014, 2017-2023 by Toby Inkster.

This is a free script; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language system itself.

=cut

use 5.014;
use warnings;

use Test::More;
use Devel::StrictMode;

sub diag_version {
  my ($module, $version, $return) = @_;

  if ($module =~ /\//) {
    my @modules  = split /\s*\/\s*/, $module;
    my @versions = map diag_version($_, undef, 1), @modules;
    return @versions if $return;
    return diag sprintf('  %-43s %s', join("/", @modules), 
      join("/", @versions));
  }

  unless (defined $version) {
    eval "use $module ()";
    $version =  $module->VERSION;
  }

  if (!defined $version) {
    return 'undef' if $return;
    return diag sprintf('  %-40s    undef', $module);
  }

  my ($major, $rest) = split /\./, $version;
  $major =~ s/^v//;
  return "$major\.$rest" if $return;
  return diag sprintf('  %-40s % 4d.%s', $module, $major, $rest);
}
 

sub diag_env {
  require B;
  my $var = shift;
  return diag sprintf('  $%-40s   %s', $var, 
    exists $ENV{$var} ? B::perlstring($ENV{$var}) : "undef");
}

use constant MANUAL_TESTS => exists($ENV{MANUAL_TESTS})
                          && !$ENV{AUTOMATED_TESTING}
                          && !$ENV{NONINTERACTIVE_TESTING};
use constant _DEBUG => $ENV{EXTENDED_TESTING} 
                    && !$ENV{NDEBUG} 
                    && !$ENV{PERL_NDEBUG};

sub banner {
  diag( ' ' );
  diag( '# ' x 36 );
  diag( ' ' );
  diag( "  OS:            $^O" );
  diag( "  PERL:          $]" );
  diag( "  STRICT:        ", STRICT       ? "enabled" : "not enabled" );
  diag( "  MANUAL_TESTS:  ", MANUAL_TESTS ? "enabled" : "not enabled" );
  diag( "  DEBUG:         ", _DEBUG       ? "enabled" : "not enabled" );
  diag( ' ' );
  diag( '# ' x 36 );
}

banner();

while (<DATA>) {
  chomp;
    
  if (/^#\s*(.*)$/ or /^$/) {
    diag($1 || "");
    next;
  }

  if (/^\$(.+)$/) {
    diag_env($1);
    next;
  }

  if (/^perl$/) {
    diag_version("Perl", $]);
    next;
  }
    
  diag_version($_) if /\S/;
}

diag( ' ' );
diag( '# ' x 36 );
diag( ' ' );

pass;
done_testing;

__DATA__

Class::Accessor
Class::Method::Modifiers
namespace::sweep

Devel::Assert
Devel::StrictMode
IO::Handle/IO::Null
Type::Tiny/Types::Standard

Win32
Win32::API
Win32::Console
Win32API::File

$AUTOMATED_TESTING
$NONINTERACTIVE_TESTING
$PERL_STRICT
$EXTENDED_TESTING
$AUTHOR_TESTING
$RELEASE_TESTING

$NDEBUG
$PERL_NDEBUG
$MANUAL_TESTS
