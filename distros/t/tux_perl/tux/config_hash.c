/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: config_hash.c,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

#include <stdio.h>
#include <string.h>
#include "config_hash.h"

#define MAX_LINE_LENGTH 1024

#define IS_BLANK(c) ((c)==' '||(c)=='\t')
#define IS_ALPHA(c) ( ((c)>='0'&&(c)<='9') || ((c)>='a'&&(c)<='z') || \
                      ((c)>='A'&&(c)<='Z') || ((c)=='_'))
#define PRINTABLE_STRING(s) ((s)==NULL?"<NULL>":(s))

int clear_node(hash_node *node)
{
  if(node==NULL)
    return 1;

  node->parent=NULL;
  node->prev=NULL;
  node->next=NULL;
  node->name=NULL;

  return 0;
}

hash_variable * new_variable(void)
{
  hash_variable *v=(hash_variable*)malloc(sizeof(hash_variable));
  clear_node(HASH_NODE(v));
  NODE_TYPE(v)=HASH_NODE_TYPE_VARIABLE;
  v->value=NULL;
  
  return v;
}

void free_node(hash_node * node)
{
  free(NODE_NAME(node));
}

void free_variable(hash_variable *var)
{
  free_node(HASH_NODE(var));
  free(var->value);
}

hash_folder * new_folder(void)
{
  hash_folder * f=(hash_folder*)malloc(sizeof(hash_folder));
  clear_node(HASH_NODE(f));

  NODE_TYPE(f)=HASH_NODE_TYPE_FOLDER;
  f->first_child=NULL;

  return f;
}

void free_folder(hash_folder * folder)
{
  hash_node *node,*next;

  if(folder == NULL)
    return;
  
  for(node=folder->first_child;node!=NULL;node=next){
    next=NODE_NEXT(node);
    switch(NODE_TYPE(node)){
    case HASH_NODE_TYPE_VARIABLE:
      free_variable(HASH_VARIABLE(node));
      break;
    case HASH_NODE_TYPE_FOLDER:
      free_folder(HASH_FOLDER(node));
      break;
    }
  }
  free_node(HASH_NODE(folder));
}
  

    
hash_node * append_child(hash_folder * folder, hash_node * node)
{
  hash_node *slibing;

  if(folder==NULL || node==NULL)
    return NULL;

  NODE_PARENT(node)=HASH_NODE(folder);
  NODE_NEXT(node)=NULL;
  if((slibing=folder->first_child)==NULL){
    folder->first_child=node;
    NODE_PREV(node)=NULL;
  }else{
    while(NODE_NEXT(slibing)!=NULL)
      slibing=NODE_NEXT(slibing);
    NODE_NEXT(slibing)=node;
    NODE_PREV(node)=slibing;
  }

  return node;
}

int parse_new_folder(char * line, char * name)
{
  char *p,*pname,*pend;

  if(line==NULL || name==NULL)
    return 0;

  for(p=line;IS_BLANK(*p);p++)
    ;

  if(*p!='<')
    return 0;

  p++;
  while(IS_BLANK(*p))
    p++;
  
  if(!IS_ALPHA(*p))
    return 0;

  pname=p;
  while(IS_ALPHA(*p))
    p++;
  pend=p;

  while(IS_BLANK(*p))
    p++;

  if(*p!='>')
    return 0;

  *pend='\0';
  strncpy(name,pname,MAX_LINE_LENGTH);

  return 1;
}

int parse_end_folder(char * line, char * name)
{
  char *p,*pname,*pend;

  if(line==NULL || name==NULL)
    return 0;

  for(p=line;IS_BLANK(*p);p++)
    ;

  if(*p!='<')
    return 0;

  p++;
  while(IS_BLANK(*p))
    p++;

  if(*p!='/')
    return 0;

  p++;
  while(IS_BLANK(*p))
    p++;

  if(!IS_ALPHA(*p))
    return 0;

  pname=p;
  while(IS_ALPHA(*p))
    p++;
  pend=p;

  while(IS_BLANK(*p))
    p++;

  if(*p!='>')
    return 0;  

  *pend='\0';
  if(strcmp(name,pname)==0)
    return 1;

  return 0;
}

int parse_variable(char * line, char * name, char * value)
{
  char *p,*pname,*pnameend,*pvalue,*pvalueend;

  if(line==NULL || name==NULL || value==NULL)
    return 0;

  for(p=line;IS_BLANK(*p);p++)
    ;

  if(!IS_ALPHA(*p))
    return 0;

  pname=p;
  while(IS_ALPHA(*p))
    p++;
  pnameend=p;

  if(!IS_BLANK(*p))
    return 0;

  while(IS_BLANK(*p))
    p++;

  pvalue=p;
  do{
    while(*p!='\0' && *p!='\r' && *p!='\n' && !IS_BLANK(*p))
      p++;
    pvalueend=p;
    while(IS_BLANK(*p))
      p++;
  }while(*p!='\0' && *p!='\r' && *p!='\n');

  *pnameend='\0';
  *pvalueend='\0';

  strncpy(name,pname,MAX_LINE_LENGTH);
  strncpy(value,pvalue,MAX_LINE_LENGTH);

  return 1;
}

hash_node * find_node(hash_node * first, const char *name)
{
  hash_node * p;

  if( first==NULL || name==NULL )
    return NULL;

  for(p=first;p!=NULL;p=NODE_NEXT(p)){
    if(NODE_NAME(p)!=NULL && strcmp(NODE_NAME(p),name)==0)
      return p;
  }

  return NULL;
}

hash_folder * read_hash(const char * filename)
{
  FILE * fp;
  hash_folder *root,*current_folder;
  hash_node *lash_slibing;
  char line[MAX_LINE_LENGTH+1],name[MAX_LINE_LENGTH+1],
    value[MAX_LINE_LENGTH+1];

  if(filename==NULL){
    fprintf(stderr,"Filename is NULL!\n");
    return NULL;
  }
  if((fp=fopen(filename,"r"))==NULL){
    fprintf(stderr,"Failed to open file: %s\n",filename);
    return NULL;
  }

  root=new_folder();

  current_folder=root;

  while(fgets(line,MAX_LINE_LENGTH,fp)!=NULL){
    if(parse_new_folder(line,name)){
      // new folder
      hash_folder *f=new_folder();
      NODE_NAME(f)=strdup(name);
      append_child(current_folder,HASH_NODE(f));
      current_folder=f;
    }else if(parse_variable(line,name,value)){
      // new variable
      hash_variable *v=new_variable();
      NODE_NAME(v)=strdup(name);
      v->value=strdup(value);
      append_child(current_folder,HASH_NODE(v));
    }else if(parse_end_folder(line,NODE_NAME(current_folder))){
      // close folder
      current_folder=HASH_FOLDER(NODE_PARENT(current_folder));
    }
  }

  fclose(fp);
  return root;
}

int dump_node(hash_node * node)
{
  hash_variable * var;
  hash_folder * folder;
  hash_node * child;

  if(node==NULL)
    return 1;
  switch(NODE_TYPE(node)){
  case HASH_NODE_TYPE_VARIABLE:
    var=HASH_VARIABLE(node);
    printf("VAR %s %s\n",PRINTABLE_STRING(NODE_NAME(var)),
	   PRINTABLE_STRING(var->value));
    break;
  case HASH_NODE_TYPE_FOLDER:
    folder=HASH_FOLDER(node);
    printf("FOLDER %s\n",PRINTABLE_STRING(NODE_NAME(folder)));
    for(child=folder->first_child;
	child!=NULL;
	child=NODE_NEXT(child))
      dump_node(child);
    printf("END %s\n",PRINTABLE_STRING(NODE_NAME(folder)));
    break;
  }
  return 0;
}

char * get_value(hash_folder * folder, const char * name)
{
  hash_node * node;

  if(folder==NULL || name==NULL)
    return NULL;

  for(node=folder->first_child;node!=NULL;node=NODE_NEXT(node))
    if(IS_VARIABLE(node) && strcmp(NODE_NAME(node),name)==0)
      return HASH_VARIABLE(node)->value;

  return NULL;
}
