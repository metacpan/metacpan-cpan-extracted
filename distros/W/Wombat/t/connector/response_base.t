# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use strict;
use warnings;

use Wombat::TestFixture;

# TODO: setLocale sets characterEncoding
# XXX: flushBuffer, reset, resetBuffer, write

my @scalars;
push @scalars, qw(application bufferSize connector contentLength);
push @scalars, qw(contentType handle locale request);

my $fixture = Wombat::TestFixture->new();

$fixture->setup('Wombat::Connector::ResponseBase',
                isa => [qw(Wombat::Response Servlet::ServletResponse)],
                scalar => \@scalars,
                bool => [qw(included)]);

# can't set bufferSize if content in buffer
$fixture->addTest('test_result_exception/setBufferSize (content in buffer)',
                  { method => 'setBufferSize',
                    prereq => sub { $_[0]->write('hi') } },
                  \&test_result_exception);

# can't set bufferSize if response is committed
$fixture->addTest('test_result_exception/setBufferSize (response committed)',
                  { method => 'setBufferSize',
                    prereq =>
                    sub { $_[0]->write('hi') && $_[0]->flushBuffer() } },
                  \&test_result_exception);

# committed flag is set internally
$fixture->addTest('bool_get_true/isCommitted', 'committed',
                  \&test_bool_get_true);
$fixture->addTest('bool_get_false/isCommitted', 'committed',
                  \&test_bool_get_false);

# contentCount is set internally
$fixture->addTest('scalar_get/getContentCount', 'contentCount',
                  \&test_scalar_get);

# isError() does not take an argument
$fixture->addTest('bool_get_true/isError', 'error', \&test_bool_get_true);
$fixture->addTest('bool_get_false/isError', 'error', \&test_bool_get_false);
$fixture->addTest('bool_set_true/isError', 'error', \&test_bool_set_true);

# facade is set internally
$fixture->addTest('test_result_isa/facade',
                  { method => 'getResponse',
                    class => 'Wombat::Connector::ResponseFacade' },
                  \&test_result_isa);

# characterEncoding set indirectly by setContentType()
$fixture->addTest('setCharacterEncoding/charset',
sub {
    my $fixture = shift;
    my $name = shift;
    my $response = shift;

    $response->setContentType('text/html; charset=US-ASCII');
    $fixture->ok($name,
                 $response->getContentType() eq
                 'text/html; charset=US-ASCII' &&
                 $response->getCharacterEncoding() eq 'US-ASCII');

    return 1;
});

# characterEncoding not set by setContentType()
$fixture->addTest('setCharacterEncoding/empty',
sub {
    my $fixture = shift;
    my $name = shift;
    my $response = shift;

    $response->setContentType('text/html');
    $fixture->ok($name,
                 $response->getContentType() eq 'text/html' &&
                 $response->getCharacterEncoding() eq 'ISO-8859-1');

    return 1;
});

# outputHandle is set internally
$fixture->addTest('test_result_isa/outputHandle',
                  { method => 'getOutputHandle',
                    class => 'Wombat::Connector::ResponseHandle' },
                  \&test_result_isa);

# once getWriter() is called, getOutputHandle() throws an exception
$fixture->addTest('test_result_exception/outputHandle (illegal state)',
                  { method => 'getOutputHandle',
                    prereq => sub { $_[0]->getWriter() } },
                  \&test_result_exception);

# writer is set internally
$fixture->addTest('test_result_isa/writer',
                  { method => 'getWriter',
                    class => 'Wombat::Connector::ResponseHandle' }, # XXX
                  \&test_result_isa);

# once getOutputHandle() is called, getWriter() throws an exception
$fixture->addTest('test_result_exception/writer (illegal state)',
                  { method => 'getWriter',
                    prereq => sub { $_[0]->getOutputHandle() } },
                  \&test_result_exception);

# can't get a Writer if the characterEncoding is unsupported
$fixture->addTest('test_result_exception/writer (unsupported encoding)',
                  { method => 'getWriter',
                    prereq =>
                    sub { $_[0]->setContentType('foo; charset=DNE') } },
                  \&test_result_exception);

$fixture->run();

exit;
