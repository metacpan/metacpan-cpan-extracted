#!/usr/bin/perl
use strict;



my @old = qw/getPage getPages newPage deletePage editPage getPageList getAuthors getCategories newCategory suggestCategories uploadFile newPost editPost getPost getRecentPosts getCategories newMediaObject deletePost getTemplate setTemplate getUsersBlogs/;
my %old;
@old{@old}=();
my @new = qw/getUsersBlogs getPage getPages newPage deletePage editPage getPageList getAuthors getCategories getTags newCategory deleteCategory suggestCategories uploadFile getCommentCount getPostStatusList getPageStatusList getPageTemplates getOptions setOptions getComment getComments deleteComment editComment newComment getCommentStatusList newPost editPost getPost getRecentPosts getCategories newMediaObject deletePost getTemplate setTemplate getUsersBlogs/;
my %new;
@new{@new}=();


my @not_in_old;
for my $new (@new){
   exists $old{$new} and next;
   push @not_in_old, $new;
}

@not_in_old = sort @not_in_old;

warn "not in old list:\n";
print "@not_in_old\n";




