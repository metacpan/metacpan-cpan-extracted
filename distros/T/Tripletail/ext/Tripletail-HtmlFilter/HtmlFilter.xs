/* ----------------------------------------------------------------------------
 * TL-HtmlFilter.xs
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2005 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id: HtmlFilter.xs 4923 2007-11-22 08:03:58Z hio $
 * ------------------------------------------------------------------------- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>

#ifdef _MSC_VER /* Microsoft Visual C++ */
#define strncasecmp(s1,s2,n) _strnicmp(s1,s2,n)
#endif
#ifndef PERL_MAGIC_taint
#define PERL_MAGIC_taint 't'
#endif

static const int FILT_INTEREST       = 0;
static const int FILT_TRACK          = 1;
static const int FILT_FILTER_TEXT    = 2;
static const int FILT_FILTER_COMMENT = 3;
static const int FILT_CONTEXT        = 4;
static const int FILT_HTML           = 5;
static const int FILT_OUTPUT         = 6;

static const int ELEM_NAME   = 0;
static const int ELEM_ATTRS  = 1;
static const int ELEM_ATTR_H = 2;
static const int ELEM_TAIL   = 3;

static void
_void__call_method__sv(SV* this_sv, const char* method, SV* arg1) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(this_sv);
	XPUSHs(arg1);
	PUTBACK;

	call_method(method, G_DISCARD);

	FREETMPS;
	LEAVE;
}

static SV*
_sv__call_method__void(SV* this_sv, const char* method) {
	SV* ret;

	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(this_sv);
	PUTBACK;

	call_method(method, G_SCALAR);

	SPAGAIN;
	ret = SvREFCNT_inc(POPs);
	PUTBACK;

	FREETMPS;
	LEAVE;

	return ret;
}

static SV*
_sv__call_method__sv(SV* this_sv, const char* method, SV* arg1) {
	SV* ret;

	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(this_sv);
	XPUSHs(arg1);
	PUTBACK;

	call_method(method, G_SCALAR);

	SPAGAIN;
	ret = SvREFCNT_inc(POPs);
	PUTBACK;

	FREETMPS;
	LEAVE;

	return ret;
}

static SV*
_get_from_this_as_sv(AV* this_av, int key) {
	SV** ret = av_fetch(this_av, key, 0);

	if (ret != NULL) {
		return *ret;
	}
	else {
		return &PL_sv_undef;
	}
}

static AV*
_get_from_this_as_av(AV* this_av, int key) {
	SV* sv = _get_from_this_as_sv(this_av, key);

	if (SvROK(sv)) {
		AV* ret = (AV*)SvRV(sv);

		if (SvTYPE(ret) == SVt_PVAV) {
			return ret;
		}
		else {
			return NULL;
		}
	}
	else {
		return NULL;
	}
}

static HV*
_get_from_this_as_hv(AV* this_av, int key) {
	SV* sv = _get_from_this_as_sv(this_av, key);

	if (SvROK(sv)) {
		HV* ret = (HV*)SvRV(sv);

		if (SvTYPE(ret) == SVt_PVHV) {
			return ret;
		}
		else {
			return NULL;
		}
	}
	else {
		return NULL;
	}
}

static bool
_get_from_this_as_bool(AV* this_av, int key) {
	SV* sv = _get_from_this_as_sv(this_av, key);

	return SvTRUE(sv);
}

static void
_set_sv_to_this(AV* this_av, int key, SV* sv) {
	SV** ret;
	
	ret = av_store(this_av, key, sv);
	if (ret == NULL) {
		SvREFCNT_dec(sv);
	}
}

static SV*
_lc_COW(SV* str) {
	/* str 内に大文字がある場合、それらを小文字にした SV* を新たに作っ
	 * て返す。無ければ参照カウントを 1 上げただけでコピーせずに返す。
	 * COW は Copy-On-Write の略。
	 */
	SV* ret = NULL;
	char* ret_cstr = NULL;
	
	STRLEN len;
	const char* cstr;
	STRLEN i;

	cstr = SvPV(str, len);
	for (i = 0; i < len; i++) {
		if (isUPPER(cstr[i])) {
			if (ret == NULL) {
				/* まだコピーしていなかった */
				STRLEN dummy;
				
				ret = newSVpvn(cstr, len);
				ret_cstr = SvPV(ret, dummy);
			}

			ret_cstr[i] = toLOWER(cstr[i]);
		}
	}

	if (ret == NULL) {
		/* 最後まで大文字が見付からなかった */
		return SvREFCNT_inc(str);
	}
	else {
		return ret;
	}
}

static bool
_strEQ_ignore_case(SV* str1, SV* str2) {
	STRLEN s1_len, s2_len;
	const char *s1, *s2;

	s1 = SvPV(str1, s1_len);
	s2 = SvPV(str2, s2_len);

	if (s1_len == s2_len && s1_len > 0 &&
		strncasecmp(s1, s2, s1_len) == 0) {

		return TRUE;
	}
	else {
		return FALSE;
	}
}

static void
_store_unary_attr(AV* this_av, const char* ptr, int len) {
	SV* str = newSVpvn(ptr, len);

	_set_sv_to_this(this_av, ELEM_TAIL, str);
}

static bool
_does_look_like_element(SV* sv_str) {
	STRLEN len;
	const char* str = SvPV(sv_str, len);

	if (len >= 1 && str[0] == '<') {
		return TRUE;
	}
	else {
		return FALSE;
	}
}

static SV*
_parse_html_comment(SV* str_sv) {
	/* return ($str =~ m/^<!--\s*(.+?)\s*-->$/) ? $1 : undef */
	STRLEN len;
	const char* str = SvPV(str_sv, len);

	/* 前から <!--\s* を削る */
	if (len < 4 || strnNE(str, "<!--", 4)) {
		return &PL_sv_undef;
	}
	str += 4; len -= 4;

	while (len && isSPACE(str[0])) {
		str++; len--;
	}

	/* 後ろから \s*--> を削る */
	if (len < 3 || strnNE(&str[len - 3], "-->", 3)) {
		return &PL_sv_undef;
	}
	len -= 3;

	while (len && isSPACE(str[len - 1])) {
		len--;
	}

	if (len == 0) {
		return &PL_sv_undef;
	}
	else {
		return newSVpvn(str, len);
	}
}

static void
_parse_close_elem(SV* elem_name, bool* close, SV** nameonly) {
	STRLEN len;
	const char* str = SvPV(elem_name, len);

	if (len >= 1 && str[0] == '/') {
		*close = TRUE;
		*nameonly = newSVpvn(&str[1], len - 1);
	}
	else {
		*close = FALSE;
		*nameonly = SvREFCNT_inc(elem_name);
	}
}

static bool
_is_matched(AV* matcher, SV* str_sv) {
	int i;

	for (i = 0; i < av_len(matcher) + 1; i++) {
		SV* m = *av_fetch(matcher, i, 0);

		if (SvROK(m)) {
			int matched;
			dSP;

			ENTER;
			SAVETMPS;

			PUSHMARK(SP);
			XPUSHs(str_sv);
			PUTBACK;

			call_sv(m, G_SCALAR);

			SPAGAIN;
			matched = POPi;
			PUTBACK;

			FREETMPS;
			LEAVE;

			if (matched) {
				return TRUE;
			}
		}
		else {
			STRLEN s1_len, s2_len;
			const char *s1, *s2;

			s1 = SvPV(m, s1_len);
			s2 = SvPV(str_sv, s2_len);

			/* warn("strncasecmp(\"%s\", \"%s\")", SvPV_nolen(m), SvPV_nolen(str_sv)); */

			if (s1_len == s2_len && s1_len > 0 &&
				strncasecmp(s1, s2, s1_len) == 0) {

				/* warn("MATCHED"); */
				return TRUE;
			}
		}
	}

	return FALSE;
}

static bool
_is_tainted_pv(SV* sv)
{
	MAGIC* mg;
	if( SvTYPE(sv)!=SVt_PVMG )
	{
		return FALSE;
	}
	if( !SvPOKp(sv) )
	{
		return FALSE;
	}
	mg = SvMAGIC(sv);
	if( mg==NULL )
	{
		return FALSE;
	}
	if( mg->mg_moremagic!=NULL )
	{
		return FALSE;
	}
	if( mg->mg_type!=PERL_MAGIC_taint )
	{
		return FALSE;
	}
	return TRUE;
}

MODULE = Tripletail::HtmlFilter  PACKAGE = Tripletail::HtmlFilter
PROTOTYPES: ENABLE

void
next(SV* this_sv)
  PPCODE:
    {
		AV* this_av;
		SV* context;
		AV* html_av;
		AV* output;
		bool filter_comment;
		bool filter_text;
		bool track;
		bool interest;

		SV* ret_interested = &PL_sv_undef;
		
		this_av = (AV*)SvRV(this_sv);
		if (SvTYPE(this_av) != SVt_PVAV) {
			croak("Internal Error: $this is not an ARRAY ref");
		}

		context  = _get_from_this_as_sv(this_av, FILT_CONTEXT);
		html_av  = _get_from_this_as_av(this_av, FILT_HTML);
		output   = _get_from_this_as_av(this_av, FILT_OUTPUT);
		filter_comment = _get_from_this_as_bool(this_av, FILT_FILTER_COMMENT);
		filter_text    = _get_from_this_as_bool(this_av, FILT_FILTER_TEXT);
		track    = _get_from_this_as_bool(this_av, FILT_TRACK);
		interest = _get_from_this_as_bool(this_av, FILT_INTEREST);

		if (html_av == NULL) {
			croak("Internal Error: $this->{html} is not an ARRAY ref");
		}

		if (output == NULL) {
			croak("Internal Error: $this->{output} is not an ARRAY ref");
		}

		/* $this->[CONTEXT]->_flush($this); # 未確定の部分を確定する */
		_void__call_method__sv(context, "_flush", this_sv);

		/* while (@{$this->[HTML]}) { ... } */
		while (av_len(html_av) >= 0) { /* av_len は空の時に -1 */
			/* my $str = shift @{$this->[HTML]}; */
			SV* str_sv = av_shift(html_av);
			SV* comment;
			SV* interested = &PL_sv_undef;
			SV* parsed = &PL_sv_undef;

			if (!SvPOK(str_sv) && !_is_tainted_pv(str_sv) ) {
				croak("Internal Error: "
					  "$this->[HTML] contains an element other than string");
			}

			/* if ($str =~ m/^<!--\s*(.+?)\s*-->$/) { ... } */
			comment = _parse_html_comment(str_sv);
			if (comment != &PL_sv_undef && SvOK(comment)) {
				/* コメント
				 *
				 * if ($this->[FILTER_COMMENT]) {
				 *   $interested = $this->[CONTEXT]->newComment($1);
				 * }
				 */
				if (filter_comment) {
					interested = _sv__call_method__sv(
						context, "newComment", comment);
				}

				SvREFCNT_dec(comment);
			}
			else if (_does_look_like_element(str_sv)) {
				/* 要素
				 *
				 * if ($this->[TRACK] or $this->[INTEREST]) {
				 *   ($interested,$parsed) = $this->_next_elem($str);
				 * }
				 */
				if (track || interest) {
					int count;
					dSP;

					ENTER;
					SAVETMPS;

					PUSHMARK(SP);
					XPUSHs(this_sv);
					XPUSHs(str_sv);
					PUTBACK;

					count = call_method("_next_elem", G_ARRAY);

					SPAGAIN;

					if (count != 2) {
						croak("$this->_next_elem returned %d values", count);
					}

					parsed = SvREFCNT_inc(POPs);
					interested = SvREFCNT_inc(POPs);

					PUTBACK;
					FREETMPS;
					LEAVE;
				}
			}
			else {
				/* # テキスト
				 * if ($this->[FILTER_TEXT]) {
				 *   # 興味を持ってるときはオブジェクトにして返す. 
				 *   $interested = $this->[CONTEXT]->newText($str);
				 * }
				 */
				if (filter_text) {
					interested = _sv__call_method__sv(context, "newText", str_sv);
				}
			}

			/* if ($interested) { ... } */
			if (SvTRUE(interested)) {
				/* # この要素は興味を持たれている。
				 * $this->[CONTEXT]->_current($interested);
				 * return ($this->[CONTEXT], $interested);
				 */
				_void__call_method__sv(context, "_current", interested);
			}
			else {
				/* # そうでないなら出力に書いて次へ
				 * push(@{$this->[OUTPUT]},$parsed||$str);
				 */
				av_push(output, SvREFCNT_inc(
							SvTRUE(parsed) ? parsed : str_sv));
			}

			/* ここで str_sv と parsed がスコープから外れる */
			SvREFCNT_dec(str_sv);
			SvREFCNT_dec(parsed);

			if (SvTRUE(interested)) {
				ret_interested = sv_2mortal(interested);
				break;
			}
		}

		if (ret_interested != &PL_sv_undef && SvOK(ret_interested)) {
			XPUSHs(context);
			XPUSHs(ret_interested);
		}
	}

void
_next_elem(SV* this_sv, SV* str_sv)
PPCODE:
  {
	  AV* this_av;
	  SV* context;
	  AV* track;
	  AV* interest;
	  SV* elem;
	  SV* elem_name;
	  SV* interested = &PL_sv_undef;
	  SV* parsed     = &PL_sv_undef;

	  this_av = (AV*)SvRV(this_sv);
	  if (SvTYPE(this_av) != SVt_PVAV) {
		  croak("Internal Error: $this is not an ARRAY ref");
	  }

	  context  = _get_from_this_as_sv(this_av, FILT_CONTEXT);
	  track    = _get_from_this_as_av(this_av, FILT_TRACK);
	  interest = _get_from_this_as_av(this_av, FILT_INTEREST);

	  /* my $elem = $this->[CONTEXT]->newElement->parse($str); */
	  elem = _sv__call_method__void(context, "newElement");
	  _void__call_method__sv(elem, "parse", str_sv);

	  /* my $elem_name = $elem->name; */
	  /* 直接 name から取り出している事に注意 */
	  do {
		  AV* elem_av = (AV*)SvRV(elem);
		  SV** ret;
		  
		  if (SvTYPE(elem_av) != SVt_PVAV) {
			  croak("$elem is not an ARRAY ref");
		  }

		  ret = av_fetch(elem_av, ELEM_NAME, 0);
		  elem_name = (ret == NULL ? &PL_sv_undef : SvREFCNT_inc(*ret));
	  } while (0);

	  /* if (defined $elem_name) { ... } */
	  if (elem_name != &PL_sv_undef && SvOK(elem_name)) {
		  /* my ($close,$nameonly) = $elem_name =~ /^(\/?)(.*)/; */
		  bool close;
		  SV* nameonly;

		  if (!SvPOK(elem_name) && !_is_tainted_pv(elem_name) ) {
			  croak("$elem->name returned non-string");
		  }

		  _parse_close_elem(elem_name, &close, &nameonly);

		  /* if ($this->[TRACK] and $is_matched->($this->[TRACK], $nameonly)) { ... } */
		  if (track != NULL && _is_matched(track, nameonly)) {
			  /* $parsed = $elem; */
			  parsed = SvREFCNT_inc(elem);

			  /* if ($close) {
			   *     $this->[CONTEXT]->removein($nameonly);
			   * }
			   * else {
			   *     $this->[CONTEXT]->addin($nameonly => $parsed);
			   * }
			   */
			  do {
				  dSP;

				  ENTER;
				  SAVETMPS;

				  PUSHMARK(SP);
				  XPUSHs(context);
				  XPUSHs(nameonly);
				  if (!close) {
					  XPUSHs(parsed);
				  }
				  PUTBACK;

				  call_method(close ? "removein" : "addin", G_DISCARD);
				  
				  FREETMPS;
				  LEAVE;
			  } while (0);
		  }

		  /* if ($this->[INTEREST] and $is_matched->($this->[INTEREST], $elem_name)) { ... } */
		  if (interest != NULL && _is_matched(interest, elem_name)) {
			  /* $interested = $elem; */
			  interested = SvREFCNT_inc(elem);
		  }

		  /* ここで nameonly がスコープを外れる */
		  SvREFCNT_dec(nameonly);
	  }

	  /* ここで elem と elem_name がスコープを外れる */
	  SvREFCNT_dec(elem_name);
	  SvREFCNT_dec(elem);

	  /* ($interested,$parsed); */
	  XPUSHs(sv_2mortal(interested));
	  XPUSHs(sv_2mortal(parsed));
  }


MODULE = Tripletail::HtmlFilter  PACKAGE = Tripletail::HtmlFilter::Element
PROTOTYPES: ENABLE

void
parse(SV* this_sv, SV* str_sv)
CODE:
  if( SvROK(this_sv) && str_sv!=&PL_sv_undef && (SvPOK(str_sv) || _is_tainted_pv(str_sv)) )
  {
    STRLEN len;
    const char* str = SvPV(str_sv,len);
    AV* this_av = (AV*)SvRV(this_sv);
    if( SvTYPE(this_av)==SVt_PVAV && len>=2 )
    {
      STRLEN pos,i;
      /* s/^<//; */
      pos = str[0]=='<' ? 1 : 0;

      /* (s/^\s*(\/?\w+)//) and ($this->[NAME] = $1); */
      while( pos<len && isSPACE(str[pos]) )
      {
        ++pos;
      }
      i = pos<len && str[pos]=='/' ? pos+1 : pos;
      while( i<len && isALNUM(str[i]) )
      {
        ++i;
      }
      if( i!=pos )
      {
		/* 直接 name に入れている事に注意 */
		_set_sv_to_this(this_av, ELEM_NAME, newSVpvn(str+pos,i-pos));
        pos = i;
      }
      
      /*
        while(1) {
            (s/([\w:\-]+)\s*=\s*"([^"]*)"//)     ? ($this->attr($1 => $2)) :
              (s/([\w:\-]+)\s*=\s*'([^']*)'//)   ? ($this->attr($1 => $2)) :
                (s/([\w:\-]+)\s*=\s*([^\s>]+)//) ? ($this->attr($1 => $2)) :
                  (s~(\w+|/)~~)                  ? ($this->end($1)) :
                    last;
        }
        \w* (-:[\w:-]+)?  \s* = \s* " [^"]*   "
        \w* (-:[\w:-]+)?  \s* = \s* ' [^']*   '
        \w* (-:[\w:-]+)?  \s* = \s*   [^\s>]*   
        ^1  ^2          ^3          ^4        ^5
        1:name_start, 2:unary_end, 3:name_end
        4:value_start, 5:value_end
      */
      for( ; i<len; pos=i )
      {
        int pos_name_start, pos_name_end;
        int pos_value_start, pos_value_end;
        int pos_unary_end;
        assert( i==pos );
        if( isSPACE(str[i]) )
        {
          ++i;
          continue;
        }
        pos_name_start = i;
        while( i<len && isALNUM(str[i]) ) ++i;
        pos_unary_end = i;
        while( i<len && (isALNUM(str[i])||str[i]==':'||str[i]=='-') ) ++i;
        pos_name_end = i;
        if( i==pos )
        {
          while( i<len && !(isALNUM(str[i])||str[i]==':'||str[i]=='-'||str[i]=='/') )
          {
            ++i;
          }
          if( i<len && str[i]=='/' )
          {
            _store_unary_attr(this_av,"/",1);
            ++i;
          }
          if( i==pos )
          {
            break;
          }
          continue;
        }
        while( i<len && isSPACE(str[i]) ) ++i;
        if( i>=len || str[i]!='=' )
        { /* unary attr */
          if( pos_unary_end-pos_name_start!=0 )
          {
            _store_unary_attr(this_av,str+pos_name_start,pos_unary_end-pos_name_start);
            i = pos_unary_end;
          }
          continue;
        }
        ++i; /* skip '=' */
        while( i<len && isSPACE(str[i]) ) ++i;
        if( i>=len )
        { /* unary attr */
          if( pos_unary_end-pos_name_start!=0 )
          {
            _store_unary_attr(this_av,str+pos_name_start,pos_unary_end-pos_name_start);
            i = pos_unary_end;
          }
          continue;
        }else if( str[i]=='\"' || str[i]=='\'' )
        {
          const char endmark = str[i];
          pos_value_start = ++i;
          while( i<len && str[i]!=endmark ) ++i;
          if( i>=len )
          { /* unary attr */
            if( pos_unary_end-pos_name_start!=0 )
            {
              _store_unary_attr(this_av,str+pos_name_start,pos_unary_end-pos_name_start);
              i = pos_unary_end;
            }
            continue;
          }
          pos_value_end = i++;
        }else
        {
          pos_value_start = i;
          while( i<len && (!isSPACE(str[i]) && str[i]!='>') ) ++i;
          pos_value_end = i;
        }
        {
          /* $this->attr($name => $value); */
          ENTER;
          SAVETMPS;
          PUSHMARK(sp);
          XPUSHs(this_sv);
          XPUSHs(sv_2mortal(newSVpvn(str+pos_name_start, pos_name_end-pos_name_start)));
          XPUSHs(sv_2mortal(newSVpvn(str+pos_value_start, pos_value_end-pos_value_start)));
          PUTBACK;
          call_method("attr", G_DISCARD);
          SPAGAIN;
          PUTBACK;
          FREETMPS;
          LEAVE;
        }
      }
    }
  }
  XPUSHs(this_sv);

SV*
attr(SV* this_sv, SV* key, ...)
PROTOTYPE: $$;$
CODE:
  {
	  AV* this_av;
	  SV* lc_key;
	  HV* attr_h;

	  this_av = (AV*)SvRV(this_sv);
	  if (SvTYPE(this_av) != SVt_PVAV) {
		  croak("Internal Error: $this is not an ARRAY ref");
	  }

	  /*
	  if (not defined $key) {
		  die __PACKAGE__."#attr: ARG[1] is not defined.\n";
	  }
	  elsif (ref $key) {
		  die __PACKAGE__."#attr: ARG[1] is a Ref. [$key]\n";
	  }
	  */
	  if (key == &PL_sv_undef || !SvOK(key)) {
		  croak("Tripletail::HtmlFilter::Element#attr: ARG[1] is not defined.\n");
	  }
	  else if (SvROK(key)) {
		  croak("Tripletail::HtmlFilter::Element#attr: ARG[1] is a Ref. [%s]\n",
				SvPV_nolen(key));
	  }

	  lc_key = _lc_COW(key);

	  attr_h = _get_from_this_as_hv(this_av, ELEM_ATTR_H);
	  if (attr_h == NULL) {
		  croak("Internal error: $this->[ATTR_H] is not a HASH ref");
	  }

	  /* if (@_) { ... } */
	  if (items > 2) {
		  /*
		  my $val = shift;

		  if (ref $val) {
			  die __PACKAGE__."#attr: ARG[2] is a Ref. [$val]\n";
		  }
		  */
		  SV* val = ST(2);
		  AV* attrs;

		  if (SvROK(val)) {
			  croak("Tripletail::HtmlFilter::Element#attr: ARG[2] is a Ref. [%s]\n",
					SvPV_nolen(val));
		  }

		  attrs = _get_from_this_as_av(this_av, ELEM_ATTRS);
		  if (attrs == NULL) {
			  croak("Internal error: $this->[ATTRS] is not a ARRAY ref");
		  }

		  if (val != &PL_sv_undef && SvOK(val)) {
			  /*
			  # この属性が既にあるなら上書き。無ければ末尾に追加。
			  my $lc_key = lc $key;
			
			  if (my $old = $this->[ATTR_H]{$lc_key}) {
			    $old->[1] = $val;
			  }
			  else {
				my $pair = [$key, $val];
				push @{$this->[ATTRS]}, $pair;
				$this->[ATTR_H]{$lc_key} = $pair;
			  }
			  */
			  HE* old_ent;

			  old_ent = hv_fetch_ent(attr_h, lc_key, 0, 0);
			  if (old_ent != NULL && HeVAL(old_ent) != &PL_sv_undef && 
				  SvOK(HeVAL(old_ent))) {

				  /* $old->[1] = $val; */
				  AV* old_av;
				  SV** ret;

				  if (!SvROK(HeVAL(old_ent))) {
					  croak("Internal error: non-ARRAY element in ATTR_H: %s",
							SvPV_nolen(HeVAL(old_ent)));
				  }

				  old_av = (AV*)SvRV(HeVAL(old_ent));
				  if (SvTYPE(old_av) != SVt_PVAV) {
					  croak("Internal error: non-ARRAY element in ATTR_H: %s",
							SvPV_nolen(HeVAL(old_ent)));
				  }

				  if (av_len(old_av) != 1) {
					  croak("Internal error: pair with an invalid length");
				  }

				  ret = av_store(old_av, 1, SvREFCNT_inc(val));
				  if (ret == NULL) {
					  SvREFCNT_dec(val);
				  }
			  }
			  else {
				  /*
				  my $pair = [$key, $val];
				  push @{$this->[ATTRS]}, $pair;
				  $this->[ATTR_H]{$lc_key} = $pair;
				  */
				  AV* pair_av = newAV();
				  SV* pair;
				  HE* ret;

				  av_extend(pair_av, 1); /* $pair_av[1] が存在するように */
				  av_push(pair_av, SvREFCNT_inc(key));
				  av_push(pair_av, SvREFCNT_inc(val));

				  pair = newRV_inc((SV*)pair_av);
				  av_push(attrs, pair);

				  pair = newRV_noinc((SV*)pair_av);
				  ret = hv_store_ent(attr_h, lc_key, pair, 0);
				  if (ret == NULL) {
					  SvREFCNT_dec(pair);
				  }
			  }
		  }
		  else {
			  /*
			  # この属性を消去
			  if (my $old = $this->[ATTR_H]{lc $key}) {
				  delete $this->[ATTR_H]{$key};
				
				  @{$this->[ATTRS]} = grep {
					  lc($_->[0]) ne lc($key);
				  } @{$this->[ATTRS]};
			  }
			  */
			  HE* old_ent;

			  old_ent = hv_fetch_ent(attr_h, lc_key, 0, 0);
			  if (old_ent != NULL) {
				  AV* new_attrs = newAV();
				  int i;
				  
				  hv_delete_ent(attr_h, lc_key, G_DISCARD, HeHASH(old_ent));

				  av_extend(new_attrs, av_len(attrs) - 1);
				  for (i = 0; i <= av_len(attrs); i++) {
					  SV* old_elem_sv;
					  AV* old_elem;
					  SV* old_key;

					  old_elem_sv = *av_fetch(attrs, i, 0);
					  if (!SvROK(old_elem_sv)) {
						  croak("Internal error: non-ARRAY in $this->[ATTRS]: %s",
								SvPV_nolen(old_elem_sv));
					  }
					  
					  old_elem = (AV*)SvRV(old_elem_sv);
					  if (SvTYPE(old_elem) != SVt_PVAV) {
						  croak("Internal error: non-ARRAY in $this->[ATTRS]: %s",
								SvPV_nolen(old_elem_sv));
					  }

					  if (av_len(old_elem) != 1) {
						  croak("Internal error: pair with an invalid length");
					  }

					  old_key = *av_fetch(old_elem, 0, 0);

					  if (!_strEQ_ignore_case(old_key, key)) {
						  av_push(new_attrs, SvREFCNT_inc(old_elem_sv));
					  }
				  }

				  _set_sv_to_this(this_av, ELEM_ATTRS, newRV_noinc((SV*)new_attrs));
			  }
		  }

		  RETVAL = SvREFCNT_inc(val);
	  }
	  else {
		  /*
		  if (my $pair = $this->[ATTR_H]{lc $key}) {
			$pair->[1];
		  }
		  else {
			  undef; # 存在しない
		  }
		  */
		  HE* ent;

		  ent = hv_fetch_ent(attr_h, lc_key, 0, 0);
		  if (ent != NULL && HeVAL(ent) != &PL_sv_undef && SvOK(HeVAL(ent))) {
			  AV* pair_av;
			  SV* ret;

			  if (!SvROK(HeVAL(ent))) {
				  croak("Internal error: non-ARRAY element in ATTR_H: %s",
						SvPV_nolen(HeVAL(ent)));
			  }

			  pair_av = (AV*)SvRV(HeVAL(ent));
			  if (SvTYPE(pair_av) != SVt_PVAV) {
				  croak("Internal error: non-ARRAY element in ATTR_H: %s",
						SvPV_nolen(HeVAL(ent)));
			  }

			  if (av_len(pair_av) != 1) {
				  croak("Internal error: pair with an invalid length");
			  }

			  ret = *av_fetch(pair_av, 1, 0);
			  RETVAL = SvREFCNT_inc(ret);
		  }
		  else {
			  RETVAL = &PL_sv_undef;
		  }
	  }

	  /* ここで lc_key がスコープから外れる */
	  SvREFCNT_dec(lc_key);
  }
OUTPUT:
  RETVAL

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
