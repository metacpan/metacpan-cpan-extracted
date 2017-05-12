# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use strict;
use warnings;

use Wombat::TestFixture;

my @scalars;
push @scalars, qw(application authorization characterEncoding connector);
push @scalars, qw(contentLength contentType handle protocol remoteAddr);
push @scalars, qw(remoteHost response scheme serverName serverPort);
push @scalars, qw(socket wrapper);

my $fixture = Wombat::TestFixture->new();

$fixture->setup('Wombat::Connector::RequestBase',
                isa => [qw(Wombat::Request Servlet::ServletRequest)],
                scalar => \@scalars,
                bool => [qw(secure)],
                hash => [qw(attributes)],
                array => [qw(locales)],
                table => [qw(parameters)]);

# characterEncoding set indirectly by setContentType()
$fixture->addTest('setCharacterEncoding/charset',
sub {
    my $fixture = shift;
    my $name = shift;
    my $request = shift;

    $request->setContentType('text/html; charset=US-ASCII');
    $fixture->ok($name,
                 $request->getContentType() eq 'text/html; charset=US-ASCII' &&
                 $request->getCharacterEncoding() eq 'US-ASCII');

    return 1;
});

# characterEncoding not set by setContentType()
$fixture->addTest('setCharacterEncoding/empty',
sub {
    my $fixture = shift;
    my $name = shift;
    my $request = shift;

    $request->setContentType('text/html');
    $fixture->ok($name,
                 $request->getContentType() eq 'text/html' &&
                 not $request->getCharacterEncoding());

    return 1;
});

# facade is set internally
$fixture->addTest('test_result_isa/facade',
                  { method => 'getRequest',
                    class => 'Wombat::Connector::RequestFacade' },
                  \&test_result_isa);

# inputHandle is set internally
$fixture->addTest('test_result_isa/inputHandle',
                  { method => 'getInputHandle',
                    class => 'Wombat::Connector::RequestHandle' },
                  \&test_result_isa);

# once getReader() is called, getInputHandle() throws an exception
$fixture->addTest('test_result_exception/inputHandle (illegal state)',
                  { method => 'getInputHandle',
                    prereq => sub { $_[0]->getReader() } },
                  \&test_result_exception);

# reader is set internally
$fixture->addTest('test_result_isa/reader',
                  { method => 'getReader',
                    class => 'Wombat::Connector::RequestHandle' }, # XXX
                  \&test_result_isa);

# once getInputHandle() is called, getReader() throws an exception
$fixture->addTest('test_result_exception/reader (illegal state)',
                  { method => 'getReader',
                    prereq => sub { $_[0]->getInputHandle() } },
                  \&test_result_exception);

# can't get a Reader if the characterEncoding is unsupported
$fixture->addTest('test_result_exception/reader (unsupported encoding)',
                  { method => 'getReader',
                    prereq => sub { $_[0]->setCharacterEncoding('DNE') } },
                  \&test_result_exception);

$fixture->run();

exit;
