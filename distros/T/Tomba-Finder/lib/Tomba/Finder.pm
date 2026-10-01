package Tomba::Finder;

use 5.026001;
use strict;
use warnings;
use parent 'Tomba::Client';

# Import all service modules so their methods are available
use Tomba::Account;
use Tomba::Domain;
use Tomba::Verifier;
use Tomba::Phone;
use Tomba::Count;
use Tomba::Status;
use Tomba::Sources;
use Tomba::Format;
use Tomba::Similar;
use Tomba::Technology;
use Tomba::Location;
use Tomba::Enrichment;
use Tomba::Reveal;
use Tomba::Keys;
use Tomba::Usage;
use Tomba::Logs;
use Tomba::Flag;
use Tomba::Leads;
use Tomba::LeadsList;
use Tomba::LeadsAttributes;
use Tomba::Bulk;

our $VERSION = '1.1.0';

#-------------------------------------------------------------------------------

=head1 NAME

Tomba::Finder - Perl client library for the Tomba.io Email Finder API

=head1 SYNOPSIS

  use Tomba::Finder;

  my $tomba = Tomba::Finder->new("ta_xxxxx", "ts_xxxxx");

  # Account info
  my $account = $tomba->Account();

  # Domain search
  my $results = $tomba->DomainSearch("tomba.io");

  # Email finder
  my $email = $tomba->EmailFinder("asana.com", "Dustin", "Moskovitz");

  # Email verifier
  my $verified = $tomba->EmailVerifier("b.mohamed@tomba.io");

  # Phone finder
  my $phone = $tomba->PhoneFinder({ email => 'm@wordpress.org' });

=head1 DESCRIPTION

This is the official Perl client library for the L<Tomba.io|https://tomba.io> Email Finder API,
allowing you to:

=over 4

=item * L<Domain Search|https://tomba.io/domain-search> - Search emails based on a website domain.

=item * L<Email Finder|https://tomba.io/email-finder> - Generate or retrieve the most likely email address from a domain name, first name and last name.

=item * L<Author Finder|https://tomba.io/author-finder> - Instantly discover email addresses of article authors.

=item * L<Enrichment|https://tomba.io/enrichment> - Find job title, company, location and social profiles from an email.

=item * L<Linkedin Finder|https://tomba.io/linkedin-finder> - Find email addresses from LinkedIn URLs.

=item * L<Email Verifier|https://tomba.io/email-verifier> - Check the deliverability of a given email address.

=item * L<Phone Finder|https://tomba.io/phone-finder> - Find phone numbers associated with an email or domain.

=item * L<Companies Search|https://docs.tomba.io/api/reveal#search-companies> - Search for companies using natural language or structured filters.

=back

See L<https://docs.tomba.io> for full API documentation.

This module acts as a unified facade. Each API group is also available as a
standalone module (L<Tomba::Account>, L<Tomba::Domain>, L<Tomba::Verifier>,
etc.) that inherits from L<Tomba::Client>.

=cut

#-------------------------------------------------------------------------------
# Email Finder
#-------------------------------------------------------------------------------

=head2 EmailFinder

  my $data = $tomba->EmailFinder("asana.com", "Dustin", "Moskovitz");

Generates or retrieves the most likely email address from a domain name, a first name and a last name.

See L<https://docs.tomba.io/api/finder#get-email-finder>

=cut

sub EmailFinder {
    my ($self, $domain, $first_name, $last_name, $opts) = @_;
    my $params = {
        domain     => $domain,
        first_name => $first_name,
        last_name  => $last_name,
    };
    if ($opts && ref($opts) eq 'HASH') {
        $params->{webhook_url} = $opts->{webhook_url} if exists $opts->{webhook_url};
    }
    return $self->call(Tomba::Client::FINDER_PATH, $params);
}

#-------------------------------------------------------------------------------
# Enrichment
#-------------------------------------------------------------------------------

=head2 Enrichment

  my $data = $tomba->Enrichment("b.mohamed@tomba.io");

The Enrichment API lets you look up person and company data based on an email.
Retrieve a person's name, location and social handles from an email.

See L<https://docs.tomba.io/api/enrichment#get-enrich>

=cut

sub Enrichment {
    my ($self, $email, $opts) = @_;
    my $params = {
        email => $email,
    };
    if ($opts && ref($opts) eq 'HASH') {
        $params->{webhook_url} = $opts->{webhook_url} if exists $opts->{webhook_url};
    }
    return $self->call(Tomba::Client::ENRICHMENT_PATH, $params);
}

#-------------------------------------------------------------------------------
# Author Finder
#-------------------------------------------------------------------------------

=head2 AuthorFinder

  my $data = $tomba->AuthorFinder("https://clearbit.com/blog/company-name-to-domain-api");

Generates or retrieves the most likely email address from a blog post URL.

See L<https://docs.tomba.io/api/finder#get-author-finder>

=cut

sub AuthorFinder {
    my ($self, $url, $opts) = @_;
    my $params = {
        url => $url,
    };
    if ($opts && ref($opts) eq 'HASH') {
        $params->{webhook_url} = $opts->{webhook_url} if exists $opts->{webhook_url};
    }
    return $self->call(Tomba::Client::AUTHOR_PATH, $params);
}

#-------------------------------------------------------------------------------
# Linkedin Finder
#-------------------------------------------------------------------------------

=head2 LinkedinFinder

  my $data = $tomba->LinkedinFinder("https://www.linkedin.com/in/alex-maccaw-ab592978");

Generates or retrieves the most likely email address from a LinkedIn URL.

See L<https://docs.tomba.io/api/finder#get-linkedin>

=cut

sub LinkedinFinder {
    my ($self, $url, $opts) = @_;
    my $params = {
        url => $url,
    };
    if ($opts && ref($opts) eq 'HASH') {
        $params->{webhook_url} = $opts->{webhook_url} if exists $opts->{webhook_url};
    }
    return $self->call(Tomba::Client::LINKEDIN_PATH, $params);
}

#-------------------------------------------------------------------------------
# Delegated methods from service modules
#-------------------------------------------------------------------------------

## no critic (Subroutines::RequireArgUnpacking)

# Account (from Tomba::Account)
sub Account           { return Tomba::Account::Account(@_) }

# Domain (from Tomba::Domain)
sub DomainSearch      { return Tomba::Domain::DomainSearch(@_) }

# Verifier (from Tomba::Verifier)
sub EmailVerifier     { return Tomba::Verifier::EmailVerifier(@_) }

# Phone (from Tomba::Phone)
sub PhoneFinder       { return Tomba::Phone::PhoneFinder(@_) }
sub PhoneValidator    { return Tomba::Phone::PhoneValidator(@_) }

# Count (from Tomba::Count)
sub Count             { return Tomba::Count::Count(@_) }

# Status (from Tomba::Status)
sub Status            { return Tomba::Status::Status(@_) }
sub Autocomplete      { return Tomba::Status::Autocomplete(@_) }

# Sources (from Tomba::Sources)
sub EmailSources      { return Tomba::Sources::EmailSources(@_) }

# Format (from Tomba::Format)
sub EmailFormat       { return Tomba::Format::EmailFormat(@_) }

# Similar (from Tomba::Similar)
sub Similar           { return Tomba::Similar::Similar(@_) }

# Technology (from Tomba::Technology)
sub Technology        { return Tomba::Technology::Technology(@_) }

# Location (from Tomba::Location)
sub GetLocation       { return Tomba::Location::GetLocation(@_) }

# Enrichment - Clearbit-compatible (from Tomba::Enrichment)
sub PersonFind        { return Tomba::Enrichment::PersonFind(@_) }
sub CompanyFind       { return Tomba::Enrichment::CompanyFind(@_) }
sub CombinedFind      { return Tomba::Enrichment::CombinedFind(@_) }

# Reveal (from Tomba::Reveal)
sub CompaniesSearch   { return Tomba::Reveal::CompaniesSearch(@_) }

# Keys (from Tomba::Keys)
sub ListKeys          { return Tomba::Keys::ListKeys(@_) }
sub GetKey            { return Tomba::Keys::GetKey(@_) }
sub CreateKey         { return Tomba::Keys::CreateKey(@_) }
sub ResetKey          { return Tomba::Keys::ResetKey(@_) }
sub DeleteKey         { return Tomba::Keys::DeleteKey(@_) }

# Usage (from Tomba::Usage)
sub Usage             { return Tomba::Usage::Usage(@_) }

# Logs (from Tomba::Logs)
sub Logs              { return Tomba::Logs::Logs(@_) }

# Flag (from Tomba::Flag)
sub ListFlags         { return Tomba::Flag::ListFlags(@_) }
sub CreateFlag        { return Tomba::Flag::CreateFlag(@_) }

# Leads (from Tomba::Leads)
sub ListLeads         { return Tomba::Leads::ListLeads(@_) }
sub GetLead           { return Tomba::Leads::GetLead(@_) }
sub CreateLead        { return Tomba::Leads::CreateLead(@_) }
sub UpdateLead        { return Tomba::Leads::UpdateLead(@_) }
sub DeleteLead        { return Tomba::Leads::DeleteLead(@_) }

# LeadsList (from Tomba::LeadsList)
sub ListLeadsLists    { return Tomba::LeadsList::ListLeadsLists(@_) }
sub GetLeadsList      { return Tomba::LeadsList::GetLeadsList(@_) }
sub CreateLeadsList   { return Tomba::LeadsList::CreateLeadsList(@_) }
sub UpdateLeadsList   { return Tomba::LeadsList::UpdateLeadsList(@_) }
sub DeleteLeadsList   { return Tomba::LeadsList::DeleteLeadsList(@_) }

# LeadsAttributes (from Tomba::LeadsAttributes)
sub ListAttributes    { return Tomba::LeadsAttributes::ListAttributes(@_) }
sub GetAttribute      { return Tomba::LeadsAttributes::GetAttribute(@_) }
sub CreateAttribute   { return Tomba::LeadsAttributes::CreateAttribute(@_) }
sub UpdateAttribute   { return Tomba::LeadsAttributes::UpdateAttribute(@_) }
sub DeleteAttribute   { return Tomba::LeadsAttributes::DeleteAttribute(@_) }

# Bulk (from Tomba::Bulk)
sub ListBulks         { return Tomba::Bulk::ListBulks(@_) }
sub GetBulk           { return Tomba::Bulk::GetBulk(@_) }
sub LaunchBulk        { return Tomba::Bulk::LaunchBulk(@_) }
sub DeleteBulk        { return Tomba::Bulk::DeleteBulk(@_) }
sub ArchiveBulk       { return Tomba::Bulk::ArchiveBulk(@_) }
sub RenameBulk        { return Tomba::Bulk::RenameBulk(@_) }
sub BulkProgress      { return Tomba::Bulk::BulkProgress(@_) }
sub BulkDownload      { return Tomba::Bulk::BulkDownload(@_) }

## use critic

1;
__END__

=head1 METHODS SUMMARY

=head2 Core Methods

=over 4

=item * C<Account()> - Get account information

=item * C<DomainSearch($domain)> - Search emails by domain

=item * C<Count($domain)> - Get email count for a domain

=item * C<Status($domain)> - Check domain status (webmail/disposable)

=item * C<Autocomplete($search)> - Auto-complete company names

=item * C<EmailFinder($domain, $first_name, $last_name)> - Find an email address

=item * C<Enrichment($email)> - Enrich data from an email

=item * C<AuthorFinder($url)> - Find author email from a blog post URL

=item * C<LinkedinFinder($url)> - Find email from LinkedIn URL

=item * C<EmailVerifier($email)> - Verify email deliverability

=item * C<EmailSources($email)> - Find email sources on the web

=item * C<PhoneFinder($params)> - Find phone numbers

=item * C<PhoneValidator($phone, $country_code)> - Validate a phone number

=item * C<EmailFormat($domain)> - Get email format patterns

=item * C<GetLocation($domain)> - Get employee location breakdown

=item * C<Similar($domain)> - Find similar domains

=item * C<Technology($domain)> - Get technologies used by a domain

=item * C<PersonFind($email)> - Clearbit-compatible Person API

=item * C<CompanyFind($domain)> - Clearbit-compatible Company API

=item * C<CombinedFind($email)> - Clearbit-compatible Combined API

=item * C<CompaniesSearch($body)> - Search companies (POST)

=item * C<Usage()> - Check monthly requests

=item * C<Logs()> - Get request logs

=back

=head2 Keys Management

=over 4

=item * C<ListKeys()> - List API keys

=item * C<GetKey($key_id)> - Get a specific API key

=item * C<CreateKey()> - Create a new API key

=item * C<ResetKey($key_id)> - Reset an API key

=item * C<DeleteKey($key_id)> - Delete an API key

=back

=head2 Flags

=over 4

=item * C<ListFlags($params)> - List submitted flags

=item * C<CreateFlag($body)> - Report incorrect data

=back

=head2 Leads Management

=over 4

=item * C<ListLeads($params)> - List leads

=item * C<GetLead($lead_id)> - Get a specific lead

=item * C<CreateLead($body)> - Create a new lead

=item * C<UpdateLead($lead_id, $body)> - Update a lead

=item * C<DeleteLead($lead_id)> - Delete a lead

=back

=head2 Leads Lists

=over 4

=item * C<ListLeadsLists()> - List leads lists

=item * C<GetLeadsList($list_id)> - Get a specific leads list

=item * C<CreateLeadsList($body)> - Create a leads list

=item * C<UpdateLeadsList($list_id, $body)> - Update a leads list

=item * C<DeleteLeadsList($list_id)> - Delete a leads list

=back

=head2 Lead Attributes

=over 4

=item * C<ListAttributes()> - List lead attributes

=item * C<GetAttribute($attribute_id)> - Get a specific attribute

=item * C<CreateAttribute($body)> - Create a lead attribute

=item * C<UpdateAttribute($attribute_id, $body)> - Update a lead attribute

=item * C<DeleteAttribute($attribute_id)> - Delete a lead attribute

=back

=head2 Bulk Operations

=over 4

=item * C<ListBulks($type, $params)> - List bulk operations

=item * C<GetBulk($type, $id)> - Get a specific bulk operation

=item * C<LaunchBulk($type, $id)> - Launch a bulk operation

=item * C<DeleteBulk($type, $id)> - Delete a bulk operation

=item * C<ArchiveBulk($type, $id)> - Archive a bulk operation

=item * C<RenameBulk($type, $id, $name)> - Rename a bulk operation

=item * C<BulkProgress($type, $id)> - Get bulk operation progress

=item * C<BulkDownload($type, $id)> - Download bulk results

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tomba::Finder

You can also look for information at:

=over 4

=item * Official API documentation: L<https://docs.tomba.io>

=item * GitHub: L<https://github.com/tomba-io/perl>

=back

Sample codes under examples/ folder.

=head1 AUTHOR

Mohamed Ben rebia, E<lt>b.mohamed@tomba.ioE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Mohamed Benrebia <b.mohamed@tomba.io>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
