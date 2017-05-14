#! perl -w
package AuditLog;
use Exporter;
@AuditLog::ISA=qw(Exporter);
@CGI::EXPORT_OK=qw(message init close);

use FileHandle;
use strict;

my $auditFH = undef;

sub init {
   my $file = @_[0];
   $auditFH = new FileHandle("$file", "a+");
   unless ($auditFH) {die "Can't write to AuditLog '$file' - $!"};
}

sub close {
   close $auditFH;
}

sub message($) {
   my ($message) = @_;

   die "AuditLog not initialised" unless (defined($auditFH)) ; # TODO: maybe shouldn't die here

   my $timestamp = '['.scalar(localtime()).']';
   $message =~ s/^/$timestamp /gm;
   $message .= "\n";

   print $auditFH $message;
   flush $auditFH;
}

sub printAsHtml { # this can get very big so don't store in variable.
   my $file = @_[0];
   my $fh = new FileHandle("$file", "r");
   unless ($fh) {warn "Can't read AuditLog '$file' - $!"};

   print "<PRE>";
   while (<$fh>) {
     print $_."<BR>";
   }
   print "</PRE>";
   close $fh;

}

DESTROY {
   AuditLog::close();
}

1;

