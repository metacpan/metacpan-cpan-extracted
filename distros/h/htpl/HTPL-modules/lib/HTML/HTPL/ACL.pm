package HTML::HTPL::ACL;
use Set::NestedGroups;
use Data::ACL;
use strict qw(subs vars);
use vars qw(@DDL);

@DDL = (<<'EOS'
CREATE TABLE group_matrix (
        member VARCHAR(30),
        group VARCHAR(30)
)
EOS
, <<'EOS'
CREATE TABLE users_t (
        user_id VARCHAR(30) PRIMARY KEY,
        crypt INT DEFAULT 0 NOT NULL,
        pass VARCHAR(30)
)
EOS
, <<'EOS');
CREATE TABLE policies_t (
        realm VARCHAR(30),
        priority INT,
        right CHAR(8),
        group VARCHAR(30),
        exception VARCHAR(30)
)
EOS

sub CreateDDL {
        my $dbh = shift;
        foreach (@DDL) {
                $dbh->do($_);
        }
}


sub new {
        my ($class, $dbh) = @_;
        my $sql = "SELECT member, group FROM group_matrix";
        my $sth = $dbh->prepare($sql) || &HTML::HTPL::Lib::htdie($DBI::errstr);
#        my $set = new Set::NestedGroups($sth); # Won't work with informix because of ->rows bug in DBD
	my $set = new Set::NestedGroups;
	$sth->execute || &HTML::HTPL::Lib::htdie($DBI::errstr);
	while (my ($member, $group) = $sth->fetchrow_array) {
		$set->add($member, $group);
	}
        my $acl = new Data::ACL($set); 
	
        $sql = "SELECT priority, realm, right, group, exception FROM policies_t ORDER BY priority";
        $sth = $dbh->prepare($sql) || &HTML::HTPL::Lib::htdie($DBI::errstr);
        $sth->execute || &HTML::HTPL::Lib::htdie($DBI::errstr);
        while (my @ary = $sth->fetchrow_array) {
		shift @ary; # INFORMIX requires ORDER BY field to be in SELECT
                $acl->AddPolicy(@ary);
        }
        my $self = {'acl' => $acl, 'dbh' => $dbh};
        bless $self, $class;
}

sub Login {
	my ($self, $user, $pass) = @_;
	$user =~ s/\s+$//;
	$user =~ s/^\s+//;
	my $htpl_pkg = $HTML::HTPL::Sys::htpl_pkg;
	delete ${"${htpl_pkg}::session"}{'username'};
	return undef unless $self->Login2($user, $pass);
	${"${htpl_pkg}::session"}{'username'} = $user;
}

sub Login2 {
        my ($self, $user, $password) = @_;
        my $dbh = $self->{'dbh'};
        my $sql = "SELECT crypt, pass FROM users_t WHERE user_id = '$user'";
        my $sth = $dbh->prepare($sql) || &HTML::HTPL::Lib::htdie($DBI::errstr);
        $sth->execute || &HTML::HTPL::Lib::htdie($DBI::errstr);
        my ($crypt, $pass) = $sth->fetchrow_array;
        return 0 unless (defined($crypt));
	$pass =~ s/^ $//; # Informix bug
        return 1 unless $pass;
        return ($pass eq $password) unless $crypt;
        my $enc = crypt($password, $pass);
        return ($enc eq $pass);
}

sub GetPassword {
        my ($self, $user) = @_;
        my $dbh = $self->{'dbh'};
        my $sql = "SELECT crypt, pass FROM users_t WHERE user_id = '$user'";
        my $sth = $dbh->prepare($sql) || &HTML::HTPL::Lib::htdie($DBI::errstr);
        $sth->execute || &HTML::HTPL::Lib::htdie($DBI::errstr);
        my ($crypt, $pass) = $sth->fetchrow_array;
        die "Password is encrypted" if $crypt;
        $pass;
}

sub SetPassword {
        my ($self, $user, $password, $crypt) = @_;
        my $dbh = $self->{'dbh'};
        my $sql = "UPDATE users_t SET pass = ? WHERE user_id = '$user'";
        my $sth = $dbh->prepare($sql) || &HTML::HTPL::Lib::htdie($DBI::errstr);
        $password = crypt($password, substr($password, 0, 2)) if $crypt;
        $sth->execute($password) || &HTML::HTPL::Lib::htdie($DBI::errstr);
}

sub AddUser {
        my ($self, $user, $password, $crypt) = @_;
	$crypt ||= 0;
        my $dbh = $self->{'dbh'};
        my $sql = "INSERT INTO users_t (user_id, pass) VALUES ('$user', ?)";
        my $sth = $dbh->prepare($sql) || &HTML::HTPL::Lib::htdie($DBI::errstr);
        $password = crypt($password, substr($password, 0, 2)) if $crypt;
        $sth->execute($password) || &HTML::HTPL::Lib::htdie($DBI::errstr);
}

sub AddRelation {
        my ($self, $member, $group) = @_;
        my $set = $self->{'acl'}->{'set'};
        $set->add($member, $group);
        my $dbh = $self->{'dbh'};
        my $sql = "INSERT INTO group_matrix (member, group) VALUES ('$member', '$group')";
        $dbh->do($sql);
}

sub DelRelation {
        my ($self, $member, $group) = @_;
        my $set = $self->{'acl'}->{'set'};
        $set->remove($member, $group);
        my $dbh = $self->{'dbh'};
        my $sql = "DELETE FROM group_matrix WHERE member = '$member' AND group = '$group'";
        $dbh->do($sql);
}

1;
