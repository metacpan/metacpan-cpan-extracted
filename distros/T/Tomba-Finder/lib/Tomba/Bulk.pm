package Tomba::Bulk;

use strict;
use warnings;
use parent 'Tomba::Client';

=head1 NAME

Tomba::Bulk - Bulk operations for the Tomba.io API

=head1 SYNOPSIS

  use Tomba::Bulk;

  my $tomba = Tomba::Bulk->new("ta_xxxxx", "ts_xxxxx");
  my $bulks = $tomba->ListBulks("finder");

=head1 DESCRIPTION

Manage bulk operations: list, get, launch, delete, archive, rename, progress, and download.

Type can be: search, finder, verifier, enrich, author, linkedin, company,
phone-finder, phone-validator, similar.

=cut

my @VALID_TYPES = qw(search similar company finder enrich linkedin author verifier phone-finder phone-validator);

sub _validate_type {
    my ($type) = @_;
    die "Missing required parameter: 'type'\n" unless defined $type && length($type);
    unless (grep { $_ eq $type } @VALID_TYPES) {
        die "Invalid bulk type: \"$type\". Must be one of: " . join(", ", @VALID_TYPES) . "\n";
    }
}

#-------------------------------------------------------------------------------
# Bulk Operations
#-------------------------------------------------------------------------------

=head2 ListBulks

  my $data = $tomba->ListBulks("finder");
  my $data = $tomba->ListBulks("verifier", { page => 1, limit => 10 });

Retrieve a list of bulk operations for the given type.
Type can be: search, finder, verifier, enrich, author, linkedin, company,
phone-finder, phone-validator, similar.

See L<https://docs.tomba.io/api/bulks>

=cut

sub ListBulks {
    my ($self, $type, $params) = @_;
    _validate_type($type);
    return $self->call("/bulk/$type", $params);
}

=head2 CreateBulk

  my $data = $tomba->CreateBulk("finder", { emails => ["a@example.com"] });

Create a new bulk operation of the given type.
Type can be: search, finder, verifier, enrich, author, linkedin, company,
phone-finder, phone-validator, similar.

See L<https://docs.tomba.io/api/bulks>

=cut

sub CreateBulk {
    my ($self, $type, $body) = @_;
    _validate_type($type);
    return $self->post("/bulk/$type", $body);
}

=head2 GetBulk

  my $data = $tomba->GetBulk("finder", $bulk_id);

Retrieve details of a specific bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub GetBulk {
    my ($self, $type, $id) = @_;
    _validate_type($type);
    return $self->call("/bulk/$type/$id");
}

=head2 LaunchBulk

  my $data = $tomba->LaunchBulk("finder", $bulk_id);

Launch a bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub LaunchBulk {
    my ($self, $type, $id) = @_;
    _validate_type($type);
    return $self->put("/bulk/$type/$id", {});
}

=head2 DeleteBulk

  my $data = $tomba->DeleteBulk("finder", $bulk_id);

Delete a bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub DeleteBulk {
    my ($self, $type, $id) = @_;
    _validate_type($type);
    return $self->delete_request("/bulk/$type/$id/delete");
}

=head2 ArchiveBulk

  my $data = $tomba->ArchiveBulk("finder", $bulk_id);

Archive a bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub ArchiveBulk {
    my ($self, $type, $id) = @_;
    _validate_type($type);
    return $self->delete_request("/bulk/$type/$id/archive");
}

=head2 RenameBulk

  my $data = $tomba->RenameBulk("finder", $bulk_id, "New Name");

Rename a bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub RenameBulk {
    my ($self, $type, $id, $name) = @_;
    _validate_type($type);
    return $self->put("/bulk/$type/$id/rename", { name => $name });
}

=head2 BulkProgress

  my $data = $tomba->BulkProgress("finder", $bulk_id);

Get progress of a bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub BulkProgress {
    my ($self, $type, $id) = @_;
    _validate_type($type);
    return $self->call("/bulk/$type/$id/progress");
}

=head2 BulkDownload

  my $data = $tomba->BulkDownload("finder", $bulk_id);

Download results of a bulk operation.

See L<https://docs.tomba.io/api/bulks>

=cut

sub BulkDownload {
    my ($self, $type, $id) = @_;
    _validate_type($type);
    return $self->call_raw("/bulk/$type/$id/download");
}

1;
__END__

=head1 AUTHOR

Mohamed Ben rebia, E<lt>b.mohamed@tomba.ioE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Mohamed Benrebia <b.mohamed@tomba.io>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>
