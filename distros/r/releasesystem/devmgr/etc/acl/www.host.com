# www.host.com - release manager Access Control List
#
# id:publish_acl:publish_notify:owner_name:owner_email:description
#
# id	Project release area name
# publish_acl	Comma-separated list of webdev users allowed to release
# publish_notify Comma-separated list of e-mail addresses
# owner_name	Full name of project owner
# owner_email	E-mail address of project owner
# description	Short description of project
#
# Leading and trailing whitespace between fields and separators is ignored
# Line continuation via n is allowed
# test:keving, randyr:user@host.com:Kevin Greene:owner@host.com:Test project
#
# NOTE:  you DO NOT have to add idsweb as a release permission
###############################################################################
# id:publish_acl:publish_notify:owner_name:owner_email:description
test:keving,randyr:user@host.com:Kevin Greene:owner@host.com:Test project
