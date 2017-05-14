/*JPERL Beta

  PERL Access routines in Java

  ---------------------------------------------------------------------
  Copyright (c) 1998, S Balamurugan, Texas Instruments India.
  All Rights Reserved.
  ---------------------------------------------------------------------

  Permission to  use, copy, modify, and  distribute this  software and
  its documentation for  NON-COMMERCIAL  purposes and without fee   is
  hereby granted provided that  this  copyright notice appears  in all
  copies.  Please  refer LICENCE  for  further  important  copyright
  and licensing information.

  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
  FOR  THE PROGRAM.  THE   PROGRAM IS  PROVIDED ON   AN "AS  IS" BASIS
  WITHOUT  WARRANTY OF  ANY     KIND, EITHER EXPRESSED   OR   IMPLIED,
  INCLUDING,  BUT   NOT   LIMITED  TO,   THE  IMPLIED   WARRANTIES  OF
  MERCHANTABILITY AND FITNESS FOR  A PARTICULAR PURPOSE. THE AUTHOR OR
  TEXAS INSTRUMENTS  SHALL NOT BE LIABLE FOR  ANY  DAMAGES SUFFERED BY
  LICENSEE AS  A RESULT   OF  USING, MODIFYING OR   DISTRIBUTING  THIS
  SOFTWARE OR ITS DERIVATIVES.

  ---------------------------------------------------------------------*/

#include <jni.h>
#include "jp.h"
#include <stdio.h>
#include "jperl.h"

int Debug(JNIEnv *env, jobject obj)
{
 jclass   cls = env->GetObjectClass(obj);
 jfieldID fid = env->GetStaticFieldID(cls,"debug","I");
 if (fid == 0) return 0;
 int debugflg = env->GetStaticIntField(cls,fid);
 return debugflg;
}

char **GetObjStrArr(JNIEnv *env, jobject obj, jobjectArray args, int &len)
{
 int length = env->GetArrayLength(args);

 int debug  = Debug(env, obj);
 if(debug) { printf("Args contained %d elements\n",length); fflush(stdout); }

 char **retargs = (char **)malloc(sizeof(char *)*length);

 for(int i = 0; i < length; i++)
    {
     jobject   argobj = env->GetObjectArrayElement(args,i);

     char *arg = (char *)env->GetStringUTFChars((jstring)argobj, 0);
     retargs[i] = (char *)malloc(sizeof(char)*strlen(arg));
     strcpy(retargs[i],arg);
     env->ReleaseStringUTFChars((jstring)argobj, arg);
     if(debug) { printf("Arg%d = %s\n",i,retargs[i]);  fflush(stdout); }
    }

 len = length;
 return retargs;
}

void ThrowRuntimeException(JNIEnv *env, jobject obj, char *msg)
{
 jclass newExcCls;
 newExcCls = env->FindClass("java/lang/RuntimeException");

 if (newExcCls == 0)
    {
     printf("Error: Cannot throw exception java/lang/RuntimeException\n");
     fflush(stdout);
     return;
    } 

 env->ThrowNew(newExcCls, msg);
}

JNIEXPORT void JNICALL Java_jp_PLInit  (JNIEnv *env, jobject obj, jstring S)
{
 char *filename = (char *)env->GetStringUTFChars(S,0);
 if (Debug(env,obj)) 
    { printf("Loading file %s\n",filename); fflush(stdout); }
 PLInit(filename);
 env->ReleaseStringUTFChars(S, filename);
}

JNIEXPORT void JNICALL Java_jp_PLClose (JNIEnv *env, jobject obj)
{
 if (Debug(env,obj)) 
    { printf("Resetting Perl and releasing memory\n"); fflush(stdout); }
 PLClose();
}

JNIEXPORT jstring JNICALL Java_jp_IPLCallS__Ljava_lang_String_2
  (JNIEnv *env, jobject obj, jstring fname)
{
 char *filename = (char *)env->GetStringUTFChars(fname,0);
 if (Debug(env,obj)) 
    { printf("Calling function %s\n",filename);  fflush(stdout); }

 char *ret;
 jstring javaret;

 if(PLCall(ret,filename,"") <= 0)
    javaret = env->NewStringUTF("");
 else
    javaret = env->NewStringUTF(ret);

 free(ret);
 env->ReleaseStringUTFChars(fname, filename);

 return javaret;
}

JNIEXPORT jstring JNICALL Java_jp_IPLCallS__Ljava_lang_String_2_3Ljava_lang_String_2
  (JNIEnv *env, jobject obj, jstring fname, jobjectArray args)
{
 char **retargs;
 int  length;

 retargs = GetObjStrArr(env, obj, args, length);
 if (retargs == NULL)
    ThrowRuntimeException(env,obj,"Cannot process arguments");

 char *AS;
 char *filename = (char *)env->GetStringUTFChars(fname,0);
 if (Debug(env,obj)) 
    { printf("Calling function %s\n",filename);  fflush(stdout); }
 int ct = PLCall(AS,filename,"%S",length,retargs);
 env->ReleaseStringUTFChars(fname, filename);

 if (ct <= 0)
    ThrowRuntimeException(env,obj,"No arguments returned");

 jstring  javaret = env->NewStringUTF(AS);
 free(AS);
 return javaret;
}

JNIEXPORT jobjectArray JNICALL Java_jp_IPLCallA
  (JNIEnv *env, jobject obj, jstring fname, jobjectArray args)
{
 char **retargs;
 int  length;
 int  debug = Debug(env,obj);

 retargs = GetObjStrArr(env, obj, args, length);
 if (retargs == NULL)
    ThrowRuntimeException(env,obj,"Cannot process arguments");

 char **AS;
 char *filename = (char *)env->GetStringUTFChars(fname,0);
 if (debug) 
    { printf("Calling function %s\n",filename);  fflush(stdout); }
 int ct = PLCall(AS,filename,"%S",length,retargs);
 env->ReleaseStringUTFChars(fname, filename);

 if(debug) { printf("Returned %d of values\n",ct); fflush(stdin); }

 if (ct <= 0)
    ThrowRuntimeException(env,obj,"No arguments returned");

 jclass strclass = env->FindClass("java/lang/String");
 if (strclass == 0)
     return NULL;

 jobjectArray retarray = env->NewObjectArray(ct,strclass,NULL);
 for(int i=0;i<ct;i++)
    {
     if(debug) { printf("Returned %d=%s\n",i,AS[i]); fflush(stdin); }
     jstring strarg = env->NewStringUTF(AS[i]);
     env->SetObjectArrayElement(retarray,i,strarg);
     free(AS[i]);
    }

 free(AS);
 return retarray;
}

JNIEXPORT jobjectArray JNICALL Java_jp_IPLEval 
(JNIEnv *env, jobject obj, jstring exp)
{
 char **AS;
 char *command = (char *)env->GetStringUTFChars(exp,0);
 if (debug)
    { printf("Evaluating %s\n",command);  fflush(stdout); }
 int ct = PLEval(AS,command);
 env->ReleaseStringUTFChars(exp, command);

 if(debug) { printf("Returned %d of values\n",ct); fflush(stdin); }

 if (ct <= 0)
    ThrowRuntimeException(env,obj,"No arguments returned");

 jclass strclass = env->FindClass("java/lang/String");
 if (strclass == 0)
     return NULL;

 jobjectArray retarray = env->NewObjectArray(ct,strclass,NULL);
 for(int i=0;i<ct;i++)
    {
     if(debug) { printf("Returned %d=%s\n",i,AS[i]); fflush(stdin); }
     jstring strarg = env->NewStringUTF(AS[i]);
     env->SetObjectArrayElement(retarray,i,strarg);
     free(AS[i]);
    }

 free(AS);
 return retarray;
}

JNIEXPORT void JNICALL Java_jp_IPLLoadLibrary
  (JNIEnv *env, jobject obj, jstring modulename)
{
 char *filename = (char *)env->GetStringUTFChars(modulename,0);
 if (Debug(env,obj)) 
    { printf("Loading module %s\n",filename);  fflush(stdout); }
 PLLoadModule(filename);
 env->ReleaseStringUTFChars(modulename, filename);
}
