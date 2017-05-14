package Math::ExprEval;

#  version:  1.0
#  date:     12/18/2001

#  this package evaluates an expression.  it has three objectives:
#
#    efficiency
#
#    extensibility
#
#    user friendly error messages

#  it's features include:
#  
#      standard data types, arithmetic and boolean operators, conditionals,
#      pattern matching
#  
#      user-defined data types
#  
#      user-defined binary operators and prefix unary operators
#  
#      over-loaded binary operators and prefix unary operators
#  
#      calls to user-provided perl functions
#  
#      a mode for syntax checking only
#  
#      optimized re-evaluation of expressions
#  
#      multiple symbol tables

#
#  most of the generated parsers are very poor at giving good error
#  messages.  since the goal of this package is just to parse
#  expressions, it was decided not to use a generated parser.
#  (this also increases the efficiency since the grammar for the expression
#  doesn't need to be parsed before actually parsing the expression.)
#
#  the general structure of expressions is pretty standard.  in order
#  to provide useful extensibility, various features have been included.
#  a mechanism is provided for calling user-provided functions from
#  within an expression.  additional data types can be added.
#  additional unary and binary operators can also be added.
#  standard operators can be over-loaded to work with the additional
#  data types.  (the test script has examples of how these
#  features can be used.)
#
#  a syntax checking only mode can be requested.
#
#  an additional feature is that the list of tokens created when
#  evaluating an expression can be returned and used in subsequent
#  evaluations of the expression with different values for the variables.
#
#  the basic error messages are defined in variables.  this allows
#  for the calling program to remap user error messages it receives
#  to other phrasings or even other languages.  additional
#  developer error messages are also returned when error occurs.
#  (look at the results of the test script for examples of the
#  various messages).

#  the evalExpression function can be called recursively.

#  names of keywords, variables and constants are generally case-insensitive.

#  the package includes:
#
#      evalExpression
#	  evaluates an expression in a string
#      getValue
#	  gets a value within the expression
#      getSimpleValue
#	  gets a simple value in an expression
#      getFunctionValue
#	  creates a function call and returns the value
#      evalOperators
#	  evaluates a string of operators
#      lookAheadNextToken
#	  gets the lookahead information for the next token
#      getNextToken
#	  gets the next token
#      scanNextToken
#	  scans the expression string for the next token
#      tokenInfo
#	  creates a string with token information
#      valueInfo
#         creates a string with value information
#      exprEvalError
#	  handles an error in the expression.
#
#  s. luebking  phoenixL@aol.com
#


#
#   BASIC GRAMMAR OF EXPRESSIONS
#

#   expressionvalue	   ::= boolresult
#                            | stringresult
#                            | sum
#                            | ternary
#                            ;
#   
#   boolresult	   	   ::= boolproduct
#                            | boolresult OR boolproduct
#                            ;
#   
#   boolproduct	   	   ::= boolterm
#                            | extendedcomparison
#                            | boolproduct AND boolterm
#                            | boolproduct AND extendedcomparison
#                            ;
#   
#   extendedcomparison 	   ::= comparison
#                            | extendedcomparison EQ boolterm
#                            | extendedcomparison NE boolterm
#                            ;
#   
#   comparison     	   ::= comparevalue LT comparevalue
#                            | comparevalue LE comparevalue
#                            | comparevalue EQ comparevalue
#                            | comparevalue NE comparevalue
#                            | comparevalue GT comparevalue
#                            | comparevalue GE comparevalue
#                            | boolterm EQ boolterm
#                            | boolterm NE boolterm
#                            | stringresult MATCH pattern
#                            | stringresult NOMATCH pattern
#                            ;
#   
#   boolterm	   	   ::= BOOLCONSTANT
#                            | BOOLVAR
#                            | functioncall
#                            | LPAR boolresult RPAR
#                            | NOT boolterm
#                            | LPAR ternary RPAR
#                            ;
#   
#   comparevalue	   ::= stringresult
#                            | sum
#                            ;
#   
#   pattern		   ::= stringresult
#                            ;
#   
#   stringresult	   ::= string
#                            | stringresult ADD string	
#                            | stringresult ADD term
#                            ;
#   
#   string		   ::= STRINGCONSTANT
#                            | NAMEDCONSTANT
#                            | STRINGVAR
#                            | LPAR stringresult RPAR
#                            | functioncall
#                            | LPAR ternary RPAR
#                            ;
#   
#   sum		   	   ::= product
#                            | sum ADD product
#                            | sum SUB product
#                            ;
#   
#   product		   ::= term
#                            | product MUL term
#                            | product DIV term
#                            | product MOD term
#                            ;
#   
#   term		   ::= ADD term
#                            | SUB term
#                            | LPAR sum RPAR
#                            | NUMERICCONSTANT
#                            | NAMEDCONSTANT
#                            | NUMERICVAR
#                            | functioncall
#                            | LPAR ternary RPAR
#                            ;
#   
#   functioncall	   ::= IDENTIFIER LPAR RPAR
#                            | IDENTIFIER LPAR parameterlist RPAR
#                            ;
#   
#   parameterlist	   ::= parameter
#                            | parameterlist COMMA parameter
#                            ;
#   
#   parameter	   	   ::= boolresult
#                            | stringresult
#                            | sum
#                            | ternary
#   		             ;
#   
#   ternary  	   	   ::= ternarycondition QUESTIONMARK ternaryvalue COLON ternaryvalue
#   		             ;
#   
#   ternarycondition       ::= boolresult
#                            | ternary
#   		             ;
#   
#   ternaryvalue 	   ::= boolresult
#                            | stringresult
#                            | sum
#                            | ternary
#   		             ;



$VERSION = "1.0";

require 5.003;


#
#------------------------------------------------------------------------------
#
#  BEGIN function
#

BEGIN
{

  my $token;
  my $tokenLength;


#
#   types for tokens.
#

  $tokenTypeEnd = 1;
  $tokenTypeIdentifier = 2;
  $tokenTypeString = 3;
  $tokenTypeNumber = 4;
  $tokenTypeExprValue = 5;
            #  the value for this token type is an array containing
	    #  an expression value type, e.g. $exprValueBoolType,
	    #  followed by the actual value which can be a number,
	    #  string, hash table, array, etc.
  $tokenTypeLpar = 6;
  $tokenTypeRpar = 7;
  $tokenTypeComma = 8;
  $tokenTypeQuestionMark = 9;
  $tokenTypeColon = 10;
  $tokenTypeError = 11;
            #  used to return error messages from user token function.
	    #  the value is the error message string.
  $tokenTypeFunctionCall = 12;
  $tokenTypeUnaryOperator = 13;
  $tokenTypeIgnore = 14;


# the token type for a binary operator is the operator's precedence

  $minTokenTypeBinaryOperator = 20;
  $tokenTypeBoolOrOperator = $minTokenTypeBinaryOperator + 1;
  $tokenTypeBoolAndOperator = $minTokenTypeBinaryOperator + 2;
  $tokenTypeComparator = $minTokenTypeBinaryOperator + 3;
  $tokenTypeAdditiveOperator = $minTokenTypeBinaryOperator + 4;
  $tokenTypeMultiplicativeOperator = $minTokenTypeBinaryOperator + 5;

  $minTokenTypeUserBinaryOperator = $minTokenTypeBinaryOperator + 50;


#
#   table of types for tokens.
#

  %tokenTypeTable
    = (
        "("	=>	$tokenTypeLpar,
        ")"	=>	$tokenTypeRpar,
        ","	=>	$tokenTypeComma,
        "?"	=>	$tokenTypeQuestionMark,
        ":"	=>	$tokenTypeColon,
        "!"	=>	$tokenTypeUnaryOperator,
        "||"	=>	$tokenTypeBoolOrOperator,
        "&&"	=>	$tokenTypeBoolAndOperator,
        "=="	=>	$tokenTypeComparator,
        "!="	=>	$tokenTypeComparator,
        "<"	=>	$tokenTypeComparator,
        ">"	=>	$tokenTypeComparator,
        "<="	=>	$tokenTypeComparator,
        ">="	=>	$tokenTypeComparator,
        "=~"	=>	$tokenTypeComparator,
        "!~"	=>	$tokenTypeComparator,
        "+"	=>	$tokenTypeAdditiveOperator,
        "-"	=>	$tokenTypeAdditiveOperator,
        "*"	=>	$tokenTypeMultiplicativeOperator,
        "/"	=>	$tokenTypeMultiplicativeOperator,
        "%"	=>	$tokenTypeMultiplicativeOperator,
      );

  $maxTableTokenLength = 0;
  foreach $token (keys %tokenTypeTable)
  {
    $tokenLength = length($token);
    $maxTableTokenLength
      = (($maxTableTokenLength >= $tokenLength)
           ? $maxTableTokenLength : $tokenLength);
  }


#
#  types for expression values
#

  $exprValueNumericType = 1;
  $exprValueStringType = 2;
  $exprValueBoolType = 3;
  $exprValueErrorType = 4;
              #  used to return error messages from user operator function.
	      #  the value is the error message string.
  $exprValueNullType = 5;
              #  used as expression type when syntax checking only is requested
  $minExprUserAbstractType = 10;

  %valueTypeNameTable
     = (
          $exprValueNumericType		=> "numeric",
          $exprValueStringType		=> "string",
          $exprValueBoolType		=> "bool",
          $exprValueErrorType		=> "error",
          $exprValueNullType		=> "null",
       );
  

#
#   table of standard named constants
#

  %namedConstantTable
    = (
        "TRUE"	=>	[$exprValueBoolType, "t"],
        "FALSE"	=>	[$exprValueBoolType, ""],
      );


#
#  messages
#

  $msg_boolean_value_expected_after_operator
     = "boolean value expected after operator";
  $msg_boolean_value_expected_before_operator
    = "boolean value expected before operator";
  $msg_boolean_value_expected_next
    = "boolean value expected next";
  $msg_boolean_value_expected_before
    = "boolean value expected before";
  $msg_error_occurred_when_executing_modulo
    = "error occurred when executing '%'";
  $msg_error_occurred_when_executing_divide
    = "error occurred when executing '/'";
  $msg_function_may_be_unknown_no_value_returned_for_function_call
    = "function may be unknown (no value returned for function call)";
  $msg_incorrectly_specified_number
    = "incorrectly specified number";
  $msg_missing_close_quote
    = "missing close quote";
  $msg_no_function_declared_for_handling_function_calls
    = "no function declared for handling function calls";
  $msg_number_expected_after_operator
    = "number expected after operator";
  $msg_number_expected_before_operator
    = "number expected before operator";
  $msg_numeric_value_expected_next
    = "numeric value expected next";
  $msg_operator_not_evaluated_by_function
    = "operator not evaluated by function";
  $msg_string_expected_after_operator
    = "string expected after operator";
  $msg_string_expected_before_operator
    = "string expected before operator";
  $msg_string_or_number_expected_after_operator
    = "string or number expected after operator";
  $msg_string_or_number_expected_before_operator
    = "string or number expected before operator";
  $msg_string_number_or_boolean_value_expected_before_operator
    = "string, number or boolean value expected before operator";
  $msg_system_error
    = "system error";
  $msg_unexpected_character
    = "unexpected character";
  $msg_unexpected_element_found
    = "unexpected element found";
  $msg_unexpected_end_found
    = "unexpected end found";
  $msg_unrecognized_identifier
    = "unrecognized identifier";
  $msg_values_before_and_after_operator_need_to_be_the_same_type
    = "values before and after operator need to be the same type";

}


#
#------------------------------------------------------------------------------
#
#  END function
#

END
{
}


#
#------------------------------------------------------------------------------
#
#  evalExpression
#
#  evaluates an expression in a string.  it can be called recursively if
#  needed.
#
#  ARGS:
#
#     1  -  string with expression
#
#
#
#  NAMED ARGS
#
#
#  Syntax checking only
#
#  the syntax of the expression is checked and evaluated at the same time.
#  control of doing only syntax checking is by the 'syntax-check-only'
#  named arguement which is followed by a boolean arguement value.
#  note:  data type checking occurs just before an operation is
#  performed rather than when syntax is checked.
#
#
#  Boolean operator keywords
#
#  boolean operators are specified by &&, || or !.  the additional use
#  of boolean operator keywords AND, OR and NOT is controlled by the named
#  keyword 'boolean-keywords' which is followed by a boolean arguement value.
#  the default value is false.  note:  boolean keyword operators are
#  case insensitive.
#
#
#  Symbol tables
#
#  symbol tables can be used to named constants or variables.  each
#  key in a symbol table must be a letter or underscore and may be followed
#  by additional letters, digits or underscores.  the keys must be
#  capitalized.  (however, in the expressions, the names of constants
#  and variables are case insensitive.)  the each value in a symbol
#  table is an array which contains an expression value type, e.g.
#  $exprValueStringType, followed by a value which can be a string, number
#  hashtable, etc.
#
#  usually, at least one symbol table needs to be specified when
#  the function is called.  if more than one symbol table is needed,
#  e.g. a symbol table for constants and a symbol table for variables,
#  a list of symbol tables can be specified.  the named arguement
#  'symbol-table' followed by a symbol table can specify a single symbol
#  table.  the named arguement 'symbol-table-list' followed by an array
#  containing symbol tables can specify a list of symbol tables.  (if
#  both 'symbol-table' and 'symbol-table-list' are specified, only
#  'symbol-table' will be used and 'symbol-table-list will be ignored.)
#  if a symbol table list is specified, when a symbol is encountered,
#  each symbol table will be checked in the order of occurrence in the
#  symbol table list until the first symbol table is found which contains
#  desired symbol.
#
#
#  Token function
#
#  an optional token function can be specified in a call to this function.
#  this optional token function can be used to create tokens for
#  user-defined data types and/or operators.  an optional token
#  function is specified by including the 'token-function' arguement
#  followed by a reference to the optional token function or a
#  string containing the name of the optional token function.
#
#  the optional token function will be called with following arguements:
#
#      1  -  undef or a value specified by named arguement 'token-function-arg'
#      2  -  a boolean indicating if the syntax-check-only mode is active
#      3  -  the remaining part of the expression string which hasn't been
#	     been analyzed yet.  (the first character will be non-whitespace
#            and will not be one of the quote characters: ', ", or ` .)
#
#  the optional token function is expected to return three values.
#  most of the time, the first value is the substring analyzed to get
#  the token information. (it is VERY important that it be returned when
#  specified later on so that it can be skipped in further analysis
#  of the expression string.)  the three values can be in one of these
#  arrangements:
#
#      <ignored>, undef, <ignored> 
#
#          indicates that the function didn't find a token it was interested
#          in and that the general token scanner should look for the
#          usual token types
#
#      token-string, $tokenTypeNumber, number
#
#          indicates that the token is a number.  (can be used for a
#          numeric constant of some sort)
#
#      token-string, $tokenTypeString, string
#
#          indicates that the token is a string.  (can be used for a
#          string constant of some sort)
#
#      token-string, $tokenTypeExprValue, value-array
#
#          indicates that the token is an expression value.  the
#          value array contains an indicator for the expression value
#          type followed by the value, e.g. string, number, hashtable,
#          array, etc.  can be used for specifying a user-defined expression
#          value data type.  if it is a user-defined data type, the type
#          in the value-array is:
#
#             $minExprUserAbstractType + some-value
#
#          where some-value is a non-negative number.
#
#      token-string, $tokenTypeUnaryOperator, operator-string
#
#          indicates that the token is a user-defined prefix unary operator.
#
#      token-string, operator-precedence, operator-string
#
#          indicates that the token is a user-defined binary operator.
#          the operator-precedence is:
#
#             $minTokenTypeUserBinaryOperator + some-value
#
#          where some-value is a non-negative number.  note:  user-defined
#          binary operators ALWAYS have higher precedence than the
#          standard arithmetic, logic and comparison binary operators.
#
#      token-string, $tokenTypeIgnore, undef/string
#
#          indicates that the token is to be ignored.  it can be used
#          to skip over some part of the expression string if for some
#          reason that is need, e.g. special comment.  note:  this
#          token will be in the token list if the list is returned.
#
#      <ignored>, $tokenTypeError, error-message-string
#
#          indicates that optional token function has detected some kind
#          of error.  this token information will cause the expression
#          evaluator to exit and return the error-message-string
#          specified.
#
#
#
#  Operator function
#
#  an optional operator function can be specified in a call to this function.
#  the optional operator function is specified by the 'operator-function'
#  arguement followed by a reference to the operator function or a
#  string containing the name of the operator function.
#
#  the optional operator can be used in a couple of ways.  one is
#  to handle standard unary and binary operators acting on user-defined
#  data types.  if an optional operator function is specified, it
#  is called just before the expression evaluator attempts to execute a
#  unary or binary operator.  this approach allows for the optional
#  operator function to treat standard operators as being over-loaded
#  for user-defined data types.
#
#  another way that the optional operator function can be used is to
#  process user-defined unary or binary operators which act on
#  standard or user-defined data type values.
#
#  the operator function will be called with following arguements:
#
#      1  -  undef or a value specified by named arguement 'operator-function-arg'
#      2  -  a boolean indicating if the syntax-check-only mode is active
#      3  -  string found in expression for operator
#      4  -  $tokenTypeUnaryOperator if unary operator
#            or operator precedence if binary operator
#      5  -  value used to identify operator.  (usually same as arg 3)
#      6  -  expression value type for first operand
#      7  -  expression value for first operand
#      8  -  expression value for second operand or undef if operator is unary
#      9  -  expression value type for second operand or undef if operator
#            is unary
#
#  the operator function is expected to return two values in one of these
#  arrangements:
#
#      undef, <ignored>
#
#          indicates that the operator specified was not processed by
#          the operator function.  the expression evaluator will then try
#          to treat the operator as a standard operator.
#
#      $exprValueNumericType, number
#
#          numeric expression value
#
#      $exprValueStringType, string
#
#          string expression value
#
#      $exprValueBoolType, bool-value
#
#          boolean expression value
#
#      user-defined-type, value
#
#          indicates that the token is a user-defined data type.
#          the user-defined-type is:
#
#             $minExprUserAbstractType + some-value
#
#          where some-value is a non-negative number.  the value
#          can be a number, string, hashtable, array, etc.
#
#      $exprValueErrorType, error-message-string
#
#          indicates that function handler has detected some kind
#          of error.  this expression value will cause the expression
#          evaluator to exit and return the error-message-string
#          specified.
#
#
#  Function handler
#
#  the expression evaluator doesn't have any built-in functions.
#  if an expression can have a function call, a function to handle
#  expression function calls needs to be specified when the
#  the expression evaluator is called.  the function handler is
#  specified by the 'function-handler' arguement followed by a reference to the
#  function handler or a string containing the name of the
#  function handler.
#
#  the function handler will be called with following arguements:
#
#      1  -  undef or a value specified by named arguement 'function-handler-arg'
#      2  -  a boolean indicating if the syntax-check-only mode is active
#      3  -  string with the name of the function being called.  the name
#            can be in mixed case.
#      4  -  array containing expression value for first arguement if any.
#            the first element in the array is the indicator for the
#	     expression value type followed by the value, e.g. string,
#	     number, hashtable, array, etc.
#      5  -  array with expression value for second arguement if any.
#      6  -                   "              third       "
#      .
#      .
#      .
#
#  the function handler is expected to return two values in one of these
#  arrangements:
#
#      $exprValueNumericType, number
#
#          numeric expression value
#
#      $exprValueStringType, string
#
#          string expression value
#
#      $exprValueBoolType, bool-value
#
#          boolean expression value
#
#      user-defined-type, value
#
#          indicates that the token is a user-defined data type.
#          the user-defined-type is:
#
#             $minExprUserAbstractType + some-value
#
#          where some-value is a non-negative number.  the value
#          can be a number, string, hashtable, array, etc.
#
#      $exprValueErrorType, error-message-string
#
#          indicates that function handler has detected some kind
#          of error.  this expression value will cause the expression
#          evaluator to exit and return the error-message-string
#          specified.
#
#
#  Token lists
#
#  as the function evaluates an expression, tokens are generated.  a
#  list of these tokens can be returned when the function exits.
#  the 'save-token-list' arguement followed by a boolean value
#  controls whether a list of tokens will be returned.  (the default
#  is to not return a list of tokens.)  one use for the list of tokens is
#  that it can speed up subsequent re-evaluations of the same expression
#  with the variables set to various values.  to use a token list
#  for evaluating an expression, the function is called with the
#  arguement 'token-list' followed a token list returned by a previous
#  call to this function.  note:  the 'save-token-list' arguement
#  can be used with the 'syntax-check-only' arguement to get a token
#  list without evaluating an expression.

#
#
#  RETURNS:  a list of expression value type or undef, expression value
#  or undef, position of error in expression string or undef, error message
#  string or undef, list of tokens to be reused or undef and a developer
#  error message or undef.


sub evalExpression
{
  my $exprString = shift;
  my $parseInfo = {@_};

  $$parseInfo{'boolean-keywords'}
    = ((defined $$parseInfo{'boolean-keywords'})
        ? $$parseInfo{'boolean-keywords'}
	: "");
  $$parseInfo{'syntax-check-only'}
    = ((defined $$parseInfo{'syntax-check-only'})
        ? $$parseInfo{'syntax-check-only'}
	: "");

  my $returnType = undef;
  my $returnValue = undef;
  my $returnErrorPosition = undef;
  my $returnErrorMessage = undef;
  my $returnTokenList = undef;
  my $returnDeveloperErrorMessage = undef;
  my $saveTokens;
  my $keywordOperatorTable;
  my $symbolTableList;
  my $symbolTable;
  my $functionInfo;
  my $key;
  my $lookAheadTokenPosition;
  my $lookAheadTokenString;
  my $lookAheadTokenType;
  my $lookAheadTokenValue;

  if(defined $exprString)
  {
    $exprString =~ s/[\f\b\a]/ /g;

    if(defined $$parseInfo{'token-list'})
    {
      $$parseInfo{'token-list-position'} = 0;
    }


    $saveTokens = $$parseInfo{'save-token-list'};
    if((defined $saveTokens) && ($saveTokens ne ""))
    {
      $returnTokenList = [];
    }


    $keywordOperatorTable = undef;
    if($$parseInfo{'boolean-keywords'} ne "")
    {
      $keywordOperatorTable
        = {
	    "AND"	=> "&&",
	    "OR"	=> "||",
	    "NOT"	=> "!",
	  };
    }


    $symbolTableList = $$parseInfo{'symbol-table-list'};

    if(! defined $symbolTableList)
    {
      $symbolTable = $$parseInfo{'symbol-table'};

      if(defined $symbolTable)
      {
        $symbolTableList = [ $symbolTable ] ;
      }
    }


    $$parseInfo{'expression-string'} = $exprString;
    $$parseInfo{'remaining-string'} = $exprString;
    $$parseInfo{'new-token-list'} = $returnTokenList;
    $$parseInfo{'look-ahead-token-info'} = undef;
    $$parseInfo{'keyword-operator-table'} = $keywordOperatorTable;
    $$parseInfo{'symbol-table-list'} = $symbolTableList;
    $$parseInfo{'error-position'} = undef;
    $$parseInfo{'error-message'} = undef;
    $$parseInfo{'developer-error-message'} = undef;

    foreach $key ( 'token-function', 'operator-function', 'function-handler')
    {
      $functionInfo = $$parseInfo{$key};
      if((defined $functionInfo) && (ref($functionInfo) ne "CODE")
          && ($functionInfo !~ /::/))
      {
        $$parseInfo{$key} = "main::" . $functionInfo;
      }
    }


    eval
    {
      ($returnType, $returnValue) = getValue($parseInfo);

      ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	 $lookAheadTokenValue)
           = lookAheadNextToken($parseInfo);

      if($lookAheadTokenType != $tokenTypeEnd)
      {
        exprEvalError($parseInfo,
	    $lookAheadTokenPosition+length($lookAheadTokenString)-1,
	    $msg_unexpected_element_found,
	    tokenInfo($lookAheadTokenPosition, $lookAheadTokenString,
	          $lookAheadTokenType, $lookAheadTokenValue));
      }
    };

    if($@)
    {
      $returnType = undef;
      $returnValue = undef;
      $returnErrorPosition = $$parseInfo{'error-position'};
      $returnErrorMessage = $$parseInfo{'error-message'};
      $returnDeveloperErrorMessage = $$parseInfo{'developer-error-message'};
      $returnTokenList = undef;
    }
  }

  if($$parseInfo{'syntax-check-only'} ne "")
  {
    $returnType = undef;
    $returnValue = undef;
  }

  return ($returnType, $returnValue, $returnErrorPosition,
              $returnErrorMessage, $returnTokenList,
	      $returnDeveloperErrorMessage);
}


#
#------------------------------------------------------------------------------
#
#  getValue
#
#  gets a value
#
#  ARGS:
#
#     1  -  table of parsing information
#
#  RETURNS:  a list of expression value type and value

sub getValue
{
   my $parseInfo = shift;

   my $returnType = undef;
   my $returnValue = undef;
   my $tokenPosition;
   my $tokenString;
   my $tokenType;
   my $tokenValue;
   my $lookAheadTokenPosition;
   my $lookAheadTokenString;
   my $lookAheadTokenType;
   my $lookAheadTokenValue;
   my $tempType;
   my $tempValue;
   my $ternary1Type;
   my $ternary1Value;
   my $ternary2Type;
   my $ternary2Value;

   ($tempType, $tempValue) = getSimpleValue($parseInfo);

   ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	$lookAheadTokenValue)
          = lookAheadNextToken($parseInfo);

   while($lookAheadTokenType >= $minTokenTypeBinaryOperator)
   {
     ($tempType, $tempValue) = evalOperators($parseInfo,$tempType,$tempValue);

     ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	$lookAheadTokenValue)
          = lookAheadNextToken($parseInfo);
   }

   while($lookAheadTokenType == $tokenTypeQuestionMark)
   {
     if(($tempType != $exprValueBoolType)
       && ($$parseInfo{'syntax-check-only'} eq ""))
     {
       exprEvalError($parseInfo,
	    $lookAheadTokenPosition+length($lookAheadTokenString)-1,
	    $msg_boolean_value_expected_before,
	    tokenInfo($lookAheadTokenPosition, $lookAheadTokenString,
	          $lookAheadTokenType, $lookAheadTokenValue));
     }
     else
     {
       getNextToken($parseInfo);
       ($ternary1Type, $ternary1Value) = getValue($parseInfo);

       ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	  $lookAheadTokenValue)
            = lookAheadNextToken($parseInfo);

       if($lookAheadTokenType == $tokenTypeEnd)
       {
         exprEvalError($parseInfo, $tokenPosition, $msg_unexpected_end_found);
       }
       elsif($lookAheadTokenType != $tokenTypeColon)
       {
         exprEvalError($parseInfo,
	        $lookAheadTokenPosition+length($lookAheadTokenString)-1,
	        $msg_unexpected_element_found,
	        tokenInfo($lookAheadTokenPosition, $lookAheadTokenString,
	              $lookAheadTokenType, $lookAheadTokenValue));
       }
       else
       {
         getNextToken($parseInfo);
         ($ternary2Type, $ternary2Value) = getValue($parseInfo);

	 if($$parseInfo{'syntax-check-only'} ne "")
	 {
           $tempType = $exprValueNullType;
           $tempValue = "";
	 }
	 elsif($tempValue ne "")
	 {
           $tempType = $ternary1Type;
           $tempValue = $ternary1Value;
	 }
	 else
	 {
           $tempType = $ternary2Type;
           $tempValue = $ternary2Value;
	 }

         ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	    $lookAheadTokenValue)
              = lookAheadNextToken($parseInfo);
       }
     }
   }

   if($lookAheadTokenType == $tokenTypeEnd)
   {
     $returnType = $tempType;
     $returnValue = $tempValue;

     ($tokenPosition, $tokenString, $tokenType, $tokenValue)
        = getNextToken($parseInfo);
   }
   elsif(($lookAheadTokenType == $tokenTypeRpar)
            || ($lookAheadTokenType == $tokenTypeComma)
            || ($lookAheadTokenType == $tokenTypeColon)
            || ($lookAheadTokenType == $tokenTypeQuestionMark))
   {
     $returnType = $tempType;
     $returnValue = $tempValue;
   }

   if( ! defined $returnType)
   {
     exprEvalError($parseInfo,
	    $lookAheadTokenPosition+length($lookAheadTokenString)-1,
	    $msg_unexpected_element_found,
	    tokenInfo($lookAheadTokenPosition, $lookAheadTokenString,
	          $lookAheadTokenType, $lookAheadTokenValue));
   }

   return ($returnType, $returnValue);
}


#
#------------------------------------------------------------------------------
#
#  getSimpleValue
#
#  gets a simple value
#
#  ARGS:
#
#     1  -  table of parsing information
#
#  RETURNS:  a list of expression value type and value

sub getSimpleValue
{
   my $parseInfo = shift;

   my $returnType = undef;
   my $returnValue = undef;
   my $tokenPosition;
   my $tokenString;
   my $tokenType;
   my $tokenValue;
   my $lookAheadTokenPosition;
   my $lookAheadTokenString;
   my $lookAheadTokenType;
   my $lookAheadTokenValue;
   my $symbolTableList;
   my $symbolTable;
   my $i;
   my $symbolName;
   my $valueInfo;
   my $functionInfo;
   my $tempType;
   my $tempValue;

   ($tokenPosition, $tokenString, $tokenType, $tokenValue)
      = getNextToken($parseInfo);

   if($tokenType == $tokenTypeEnd)
   {
     exprEvalError($parseInfo, $tokenPosition, $msg_unexpected_end_found);
   }
   elsif($tokenType == $tokenTypeLpar)
   {
     ($returnType, $returnValue) = getValue($parseInfo);

     ($tokenPosition, $tokenString, $tokenType, $tokenValue)
        = getNextToken($parseInfo);

     if($tokenType == $tokenTypeEnd)
     {
       exprEvalError($parseInfo, $tokenPosition, $msg_unexpected_end_found);
     }
     elsif($tokenType != $tokenTypeRpar)
     {
       exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     		      $msg_unexpected_element_found,
                       tokenInfo($tokenPosition, $tokenString, $tokenType,
		       		   $tokenValue));
     }
   }
   elsif($tokenType == $tokenTypeNumber)
   {
     $returnType = $exprValueNumericType;
     $returnValue = $tokenValue;
   }
   elsif($tokenType == $tokenTypeString)
   {
     $returnType = $exprValueStringType;
     $returnValue = $tokenValue;
   }
   elsif($tokenType == $tokenTypeExprValue)
   {
     ($returnType, $returnValue) = @$tokenValue;
   }
   elsif($tokenType == $tokenTypeIdentifier)
   {
     $symbolTableList = $$parseInfo{'symbol-table-list'};

     if(defined $symbolTableList)
     {
       $symbolName = "\U$tokenValue";
       $i = 0;

       while(( ! defined $returnType) && ($i <= $#$symbolTableList))
       {
	 $symbolTable = $$symbolTableList[$i];
	 $i++;

	 $valueInfo = $$symbolTable{$symbolName};
	   
	 if(defined $valueInfo)
	 {
	   ($returnType, $returnValue) = @$valueInfo;
	 }
       }
     }

     if( ! defined $returnType)
     {
       exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     		     $msg_unrecognized_identifier,
                     tokenInfo($tokenPosition, $tokenString, $tokenType,
		      	   $tokenValue));
     }
   }
   elsif($tokenType == $tokenTypeFunctionCall)
   {
     ($returnType, $returnValue) = getFunctionValue($parseInfo,$tokenValue);
   }
   elsif(($tokenType == $tokenTypeUnaryOperator)
        || (($tokenType == $tokenTypeAdditiveOperator)
	       && (($tokenValue eq "+") || ($tokenValue eq "-"))))
   {
     ($tempType, $tempValue) = getSimpleValue($parseInfo);

     $functionInfo = $$parseInfo{'operator-function'};

     if(defined $functionInfo)
     {
       eval
       {
         ($returnType, $returnValue)
           = &$functionInfo($$parseInfo{'operator-function-arg'},
	       $$parseInfo{'syntax-check-only'},
	       $tokenString,$tokenType,$tokenValue,$tempType,$tempValue,
	       undef,undef);
       };

       if($@)
       {
         exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     		       $msg_system_error,
		       ((ref($functionInfo) eq "CODE")
		          ? "function is code\n"
			  : "function name = '$functionInfo'\n")
                        . tokenInfo($tokenPosition, $tokenString, $tokenType,
		       		   $tokenValue)
                        . $@);
       }
       elsif(! defined $returnType)
       {
       }
       elsif($returnType == $exprValueErrorType)
       {
         exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     		       $returnValue,
		       ((ref($functionInfo) eq "CODE")
		          ? "function is code\n"
			  : "function name = '$functionInfo'\n")
                        . tokenInfo($tokenPosition, $tokenString, $tokenType,
		       		   $tokenValue));
       }
     }

     if(defined $returnType)
     {
     }
     elsif(($tokenValue eq "+") || ($tokenValue eq "-"))
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $returnType = $exprValueNullType;
         $returnValue = "";
       }
       elsif($tempType != $exprValueNumericType)
       {
         exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     			      $msg_numeric_value_expected_next,
                              valueInfo($tempType,$tempValue));
       }
       else
       {
	 $returnType = $tempType;
         $returnValue = (($tokenValue eq "+")
	                  ? tempValue
			  : - $tempValue);
       }
     }
     elsif($tokenValue eq "!")
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $returnType = $exprValueNullType;
         $returnValue = "";
       }
       elsif($tempType != $exprValueBoolType)
       {
         exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     			      $msg_boolean_value_expected_next,
                              valueInfo($tempType,$tempValue));
       }
       else
       {
	 $returnType = $tempType;
         $returnValue = (($tempValue eq "") ? "t" : "");
       }
     }

     if( ! defined $returnType)
     {
       exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     		       $msg_operator_not_evaluated_by_function,
		       ((! defined $functionInfo)
		         ? "No function specified.\n"
			 : ((ref($functionInfo) eq "CODE")
		            ? "function is code\n"
			    : "function name = '$functionInfo'\n"))
                         . tokenInfo($tokenPosition, $tokenString, $tokenType,
		       		   $tokenValue));
     }
   }

   if( ! defined $returnType)
   {
     exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     		       $msg_unexpected_element_found,
                       tokenInfo($tokenPosition, $tokenString, $tokenType,
		       		   $tokenValue));
   }
   elsif($$parseInfo{'syntax-check-only'} ne "")
   {
     $returnType = $exprValueNullType;
     $returnValue = "";
   }

   return ($returnType, $returnValue);
}


#
#------------------------------------------------------------------------------
#
#  getFunctionValue
#
#  evaluates a function call
#
#  ARGS:
#
#     1  -  table of parsing information
#     2  -  function name
#
#  RETURNS:  a list of expression value type and value

sub getFunctionValue
{
   my $parseInfo = shift;
   my $functionIdentifier = shift;

   my $returnType = undef;
   my $returnValue = undef;
   my $tempType;
   my $tempValue;
   my $tokenPosition;
   my $tokenString;
   my $tokenType;
   my $tokenValue;
   my $lookAheadTokenPosition;
   my $lookAheadTokenString;
   my $lookAheadTokenType;
   my $lookAheadTokenValue;
   my $functionInfo;
   my @functionArgList = ();

   getNextToken($parseInfo);

   ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
   	$lookAheadTokenValue)
        = lookAheadNextToken($parseInfo);

   while($lookAheadTokenType != $tokenTypeRpar)
   {
     ($tempType, $tempValue) = getValue($parseInfo);

     push(@functionArgList,[$tempType, $tempValue]);

     ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
   	  $lookAheadTokenValue)
          = lookAheadNextToken($parseInfo);

     if($lookAheadTokenType == $tokenTypeComma)
     {
       getNextToken($parseInfo);
     }
     elsif($lookAheadTokenType == $tokenTypeEnd)
     {
       exprEvalError($parseInfo, $lookAheadTokenPosition+length($lookAheadTokenString)-1,
     			    $msg_unexpected_end_found);
     }
     elsif($lookAheadTokenType != $tokenTypeRpar)
     {
       exprEvalError($parseInfo, $lookAheadTokenPosition+length($lookAheadTokenString)-1,
     		       $msg_unexpected_element_found,
	               tokenInfo($lookAheadTokenPosition, $lookAheadTokenString,
	                   $lookAheadTokenType, $lookAheadTokenValue));
     }
   }

   ($tokenPosition, $tokenString, $tokenType, $tokenValue)
      = getNextToken($parseInfo);

   $functionInfo = $$parseInfo{'function-handler'};

   if( ! defined $functionInfo)
   {
     exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
     			      $msg_no_function_declared_for_handling_function_calls,
			      "function identifier = '$functionIdentifier'");
   }
   else
   {
     eval
     {
       ($returnType, $returnValue)
         = &$functionInfo($$parseInfo{'function-arg'},
	     $$parseInfo{'syntax-check-only'},
	     $functionIdentifier,@functionArgList);
     };

     if($@)
     {
       exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
    		      $msg_system_error,
    		      "function identifier = '$functionIdentifier'\n"
		         . ((ref($functionInfo) eq "CODE")
		             ? "function is code\n"
			     : "function name = '$functionInfo'\n")
			 . $@);
     }
     elsif( ! defined $returnType)
     {
       exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
    		      $msg_function_may_be_unknown_no_value_returned_for_function_call,
    		      "function identifier = '$functionIdentifier'\n"
		         .  ((ref($functionInfo) eq "CODE")
		               ? "function is code\n"
			       : "function name = '$functionInfo'\n"));
     }
     elsif($returnType == $exprValueErrorType)
     {
       exprEvalError($parseInfo, $tokenPosition+length($tokenString)-1,
    		      $returnValue,
    		      "function identifier = '$functionIdentifier'\n"
		         . ((ref($functionInfo) eq "CODE")
		             ? "function is code\n"
			     : "function name = '$functionInfo'\n"));
     }
   }

   if($$parseInfo{'syntax-check-only'} ne "")
   {
     $returnType = $exprValueNullType;
     $returnValue = "";
   }

   return ($returnType, $returnValue);
}


#
#------------------------------------------------------------------------------
#
#  evalOperators
#
#  evaluates operators.  this function is called recursively when
#  binary operators of higher precendence are encountered.
#
#  ARGS:
#
#     1  -  table of parsing information
#     2  -  type of first operand
#     3  -  value of first operand
#
#  RETURNS:  a list of expression value type and value

sub evalOperators
{
   my $parseInfo = shift;
   my $operand1Type = shift;
   my $operand1Value = shift;

   my $returnType = undef;
   my $returnValue = undef;
   my $operatorTokenPosition;
   my $operatorTokenString;
   my $operatorTokenType;
   my $operatorTokenValue;
   my $lookAheadTokenPosition;
   my $lookAheadTokenString;
   my $lookAheadTokenType;
   my $lookAheadTokenValue;
   my $tempType;
   my $tempValue;
   my $functionInfo;
   my $newType;
   my $newValue;
   my $errorMessage;

   ($operatorTokenPosition, $operatorTokenString, $operatorTokenType, 
     	$operatorTokenValue)
          = getNextToken($parseInfo);

   ($tempType, $tempValue) = getSimpleValue($parseInfo);


   $functionInfo = $$parseInfo{'operator-function'};


   while( ! defined $returnType)
   {
     ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	  $lookAheadTokenValue)
            = lookAheadNextToken($parseInfo);

     if($lookAheadTokenType > $operatorTokenType)
     {
       ($tempType, $tempValue) = evalOperators($parseInfo,$tempType,$tempValue);

       ($lookAheadTokenPosition, $lookAheadTokenString, $lookAheadTokenType, 
     	  $lookAheadTokenValue)
            = lookAheadNextToken($parseInfo);
     }


     $newType = undef;
     $newValue = undef;

     if(defined $functionInfo)
     {
       eval
       {
         ($newType, $newValue)
           = &$functionInfo($$parseInfo{'operator-function-arg'},
	       $$parseInfo{'syntax-check-only'},
	       $operatorTokenString,$operatorTokenType,$operatorTokenValue,
	       $operand1Type,$operand1Value,$tempType,$tempValue);
       };

       if($@)
       {
         exprEvalError($parseInfo, $operatorTokenPosition+length($operatorTokenString)-1,
     			      $msg_system_error,
		              ((ref($functionInfo) eq "CODE")
		                 ? "function is code\n"
			         : "function name = '$functionInfo'\n")
	    		      . tokenInfo($operatorTokenPosition, $operatorTokenString,
	                          $operatorTokenType, $operatorTokenValue)
	    		      . $@);
       }
       elsif( ! defined $newType)
       {
       }
       elsif($newType == $exprValueErrorType)
       {
         exprEvalError($parseInfo, $operatorTokenPosition+length($operatorTokenString)-1,
     			      $newValue,
		              ((ref($functionInfo) eq "CODE")
		                 ? "function is code\n"
			         : "function name = '$functionInfo'\n")
	    		      . tokenInfo($operatorTokenPosition, $operatorTokenString,
	                          $operatorTokenType, $operatorTokenValue));
       }
     }


     if(defined $newType)
     {
     }
     elsif($operatorTokenValue eq "+")
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $newType = $exprValueNullType;
         $newValue = "";
       }
       elsif($operand1Type == $exprValueNumericType)
       {
       }
       elsif($operand1Type != $exprValueStringType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_or_number_expected_before_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
                           . valueInfo($operand1Type,$operand1Value));
       }
       elsif(($tempType != $exprValueStringType)
               && ($tempType != $exprValueNumericType))
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_or_number_expected_after_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
	 		   . valueInfo($tempType,$tempValue));
       }
       else
       {
         $newType = $exprValueStringType;
	 $newValue = $operand1Value . $tempValue;
       }
     }
     elsif(($operatorTokenValue eq "==") || ($operatorTokenValue eq "!="))
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $newType = $exprValueNullType;
         $newValue = "";
       }
       elsif(($operand1Type == $exprValueNumericType)
           || ($operand1Type == $exprValueStringType))
       {
       }
       elsif($operand1Type != $exprValueBoolType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_number_or_boolean_value_expected_before_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
                           . valueInfo($operand1Type,$operand1Value));
       }
       elsif($tempType != $exprValueBoolType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_boolean_value_expected_after_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
	 		   . valueInfo($tempType,$tempValue));
       }
       else
       {
         $newType = $exprValueBoolType;

	 $newValue = "";

	 if((($operand1Value eq "") && ($tempValue eq ""))
	    || (($operand1Value eq "t") && ($tempValue eq "t")))
	 {
	   $newValue = "t";
	 }

	 if($operatorTokenValue eq "!=")
	 {
	   $newValue = (($newValue ne "") ? "" : "t");
	 }
       }
     }

     if(defined $newType)
     {
     }
     elsif(($operatorTokenValue eq "+") || ($operatorTokenValue eq "-")
          || ($operatorTokenValue eq "*") || ($operatorTokenValue eq "/")
          || ($operatorTokenValue eq "%"))
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $newType = $exprValueNullType;
         $newValue = "";
       }
       elsif($operand1Type != $exprValueNumericType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_number_expected_before_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
                           . valueInfo($operand1Type,$operand1Value));
       }
       elsif($tempType != $exprValueNumericType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_number_expected_after_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
	 		   . valueInfo($tempType,$tempValue));
       }
       else
       {
         $newType = $exprValueNumericType;

         if($operatorTokenValue eq "+")
         {
	   $newValue = $operand1Value + $tempValue;
         }
         elsif($operatorTokenValue eq "-")
         {
	   $newValue = $operand1Value - $tempValue;
         }
         elsif($operatorTokenValue eq "*")
         {
	   $newValue = $operand1Value * $tempValue;
         }
         elsif($operatorTokenValue eq "/")
         {
	   eval
	   {
	     $newValue = $operand1Value / $tempValue;
	   };

	   if($@)
	   {
             exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_error_occurred_when_executing_divide,$@);
	   }
         }
         elsif($operatorTokenValue eq "%")
         {
	   eval
	   {
	     $newValue = $operand1Value % $tempValue;
	   };

	   if($@)
	   {
             exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_error_occurred_when_executing_modulo,$@);
	   }
         }
       }
     }
     elsif(($operatorTokenValue eq "==") || ($operatorTokenValue eq "!=")
          || ($operatorTokenValue eq "<") || ($operatorTokenValue eq ">")
          || ($operatorTokenValue eq "<=") || ($operatorTokenValue eq ">="))
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $newType = $exprValueNullType;
         $newValue = "";
       }
       elsif(($operand1Type != $exprValueNumericType)
           && ($operand1Type != $exprValueStringType))
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_or_number_expected_before_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
                           . valueInfo($operand1Type,$operand1Value));
       }
       elsif(($tempType != $exprValueNumericType)
           && ($tempType != $exprValueStringType))
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_or_number_expected_after_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
	 		   . valueInfo($tempType,$tempValue));
       }
       elsif($operand1Type != $tempType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_values_before_and_after_operator_need_to_be_the_same_type,
                        valueInfo($operand1Type,$operand1Value)
			 . valueInfo($tempType,$tempValue));
       }
       elsif($operand1Type == $exprValueNumericType)
       {
         $newType = $exprValueBoolType;

         if($operatorTokenValue eq "==")
         {
	   $newValue = (($operand1Value == $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq "!=")
         {
	   $newValue = (($operand1Value != $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq "<")
         {
	   $newValue = (($operand1Value < $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq ">")
         {
	   $newValue = (($operand1Value > $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq "<=")
         {
	   $newValue = (($operand1Value <= $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq ">=")
         {
	   $newValue = (($operand1Value >= $tempValue) ? "t" : "");
         }
       }
       else
       {
         $newType = $exprValueBoolType;

         if($operatorTokenValue eq "==")
         {
	   $newValue = (($operand1Value eq $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq "!=")
         {
	   $newValue = (($operand1Value ne $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq "<")
         {
	   $newValue = (($operand1Value lt $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq ">")
         {
	   $newValue = (($operand1Value gt $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq "<=")
         {
	   $newValue = (($operand1Value le $tempValue) ? "t" : "");
         }
	 elsif($operatorTokenValue eq ">=")
         {
	   $newValue = (($operand1Value ge $tempValue) ? "t" : "");
         }
       }
     }
     elsif(($operatorTokenValue eq "=~") || ($operatorTokenValue eq "!~"))
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $newType = $exprValueNullType;
         $newValue = "";
       }
       elsif($operand1Type != $exprValueStringType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_expected_before_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
                           . valueInfo($operand1Type,$operand1Value));
       }
       elsif($tempType != $exprValueStringType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_string_expected_after_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
	 		   . valueInfo($tempType,$tempValue));
       }
       elsif($operatorTokenValue eq "=~")
       {
	 eval
	 {
           $newValue = (($operand1Value =~ m$tempValue) ? "t" : "");
           $newType = $exprValueBoolType;
	 };

	 if($@)
	 {
	   $errorMessage = $@;
           $errorMessage =~ s/(.*regexp)[^\000]*/\1/;

           exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$errorMessage,
			"Pattern:  /$tempValue/\n" . $@);
	 }
       }
       elsif($operatorTokenValue eq "!~")
       {
	 eval
	 {
           $newValue = (($operand1Value !~ m$tempValue) ? "t" : "");
           $newType = $exprValueBoolType;
	 };

	 if($@)
	 {
	   $errorMessage = $@;
           $errorMessage =~ s/(.*regexp)[^\000]*/\1/;

           exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$errorMessage,
			"Pattern:  /$tempValue/\n" . $@);
	 }
       }
     }
     elsif(($operatorTokenValue eq "&&") || ($operatorTokenValue eq "||"))
     {
       if($$parseInfo{'syntax-check-only'} ne "")
       {
         $newType = $exprValueNullType;
         $newValue = "";
       }
       elsif($operand1Type != $exprValueBoolType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_boolean_value_expected_before_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
                           . valueInfo($operand1Type,$operand1Value));
       }
       elsif($tempType != $exprValueBoolType)
       {
         exprEvalError($parseInfo,
	 		$operatorTokenPosition+length($operatorTokenString)-1,
	 		$msg_boolean_value_expected_after_operator,
	                tokenInfo($operatorTokenPosition, $operatorTokenString,
	                        $operatorTokenType, $operatorTokenValue)
	 		   . valueInfo($tempType,$tempValue));
       }
       else
       {
         $newType = $exprValueBoolType;

	 $newValue = "";

	 if(($operatorTokenValue eq "&&")
	        && (($operand1Value ne "") && ($tempValue ne "")))
	 {
	   $newValue = "t";
	 }
	 elsif(($operatorTokenValue eq "||")
	        && (($operand1Value ne "") || ($tempValue ne "")))
	 {
	   $newValue = "t";
	 }
       }
     }


     if( ! defined $newType)
     {
       exprEvalError($parseInfo, $operatorTokenPosition+length($operatorTokenString)-1,
     			     $msg_operator_not_evaluated_by_function,
		             ((! defined $functionInfo)
		               ? "No function specified.\n"
			       : ((ref($functionInfo) eq "CODE")
		                  ? "function is code\n"
			          : "function name = '$functionInfo'\n"))
	    		        . tokenInfo($operatorTokenPosition, $operatorTokenString,
	                             $operatorTokenType, $operatorTokenValue));
     }
     elsif($lookAheadTokenType != $operatorTokenType)
     {
       $returnType = $newType;
       $returnValue = $newValue;
     }
     elsif(($lookAheadTokenType == $tokenTypeComparator)
            && ($lookAheadTokenValue ne "==")
            && ($lookAheadTokenValue ne "!="))
     {
       exprEvalError($parseInfo,
          $lookAheadTokenPosition+length($lookAheadTokenString)-1,
          $msg_unexpected_element_found,
	  tokenInfo($lookAheadTokenPosition, $lookAheadTokenString,
	          $lookAheadTokenType, $lookAheadTokenValue));
     }
     else
     {
       $operand1Type = $newType;
       $operand1Value = $newValue;

       ($operatorTokenPosition, $operatorTokenString, $operatorTokenType, 
     	    $operatorTokenValue)
              = getNextToken($parseInfo);

       ($tempType, $tempValue) = getSimpleValue($parseInfo);
     }
   }

   if($$parseInfo{'syntax-check-only'} ne "")
   {
     $returnType = $exprValueNullType;
     $returnValue = "";
   }

   return ($returnType, $returnValue);
}


#
#------------------------------------------------------------------------------
#
#  lookAheadNextToken
#
#  returns the lookahead information for the next token
#
#  ARGS:
#
#     1  -  table of parsing information
#
#  RETURNS:  a list of beginning token position, token string,
#  token type and token value

sub lookAheadNextToken
{
   my $parseInfo = shift;

   my $lookAheadTokenInfo = $$parseInfo{'look-ahead-token-info'};

   if( ! defined $lookAheadTokenInfo)
   {
     $lookAheadTokenInfo = [ scanNextToken($parseInfo) ];
     $$parseInfo{'look-ahead-token-info'} = $lookAheadTokenInfo;
   }

   return ( @$lookAheadTokenInfo);
}


#
#------------------------------------------------------------------------------
#
#  getNextToken
#
#  returns the next token.
#
#  ARGS:
#
#     1  -  table of parsing information
#
#  RETURNS:  a list of beginning token position, token string,
#  token type and token value

sub getNextToken
{
   my $parseInfo = shift;

   my $returnTokenPosition = undef;
   my $returnTokenString = undef;
   my $returnTokenType = undef;
   my $returnTokenValue = undef;
   my $lookAheadTokenInfo = $$parseInfo{'look-ahead-token-info'};

   if(defined $lookAheadTokenInfo)
   {
     ( $returnTokenPosition, $returnTokenString, $returnTokenType,
         $returnTokenValue) = @$lookAheadTokenInfo;

     $$parseInfo{'look-ahead-token-info'} = undef;
   }
   else
   {
     ( $returnTokenPosition, $returnTokenString, $returnTokenType,
         $returnTokenValue) = scanNextToken($parseInfo);
   }

   return ( $returnTokenPosition, $returnTokenString,
             $returnTokenType, $returnTokenValue);
}


#
#------------------------------------------------------------------------------
#
#  scanNextToken
#
#  scans next token
#
#  ARGS:
#
#     1  -  table of parsing information
#
#  RETURNS:  a list of beginning token position, token string,
#  token type and token value

sub scanNextToken
{
   my $parseInfo = shift;

   my $returnTokenPosition = undef;
   my $returnTokenString = undef;
   my $returnTokenType = undef;
   my $returnTokenValue = undef;
   my $tokenList = $$parseInfo{'token-list'};
   my $newTokenList = $$parseInfo{'new-token-list'};
   my $tokenInfo;
   my $tokenString;
   my $keywordOperatorTable;
   my $numberString;
   my $functionInfo;
   my $constantInfo;
   my $upperCaseTokenString;
   my $remainingString;
   my $tokenPosition;
   my $i;

   if(defined $tokenList)
   {
     if($$parseInfo{'token-list-position'} <= $#$tokenList)
     {
       $tokenInfo = $$tokenList[$$parseInfo{'token-list-position'}];

       ( $returnTokenPosition, $returnTokenString, $returnTokenType,
           $returnTokenValue) = @$tokenInfo;

       $$parseInfo{'token-list-position'}++;
     }
     else
     {
       $returnTokenPosition = length($$parseInfo{'expression-string'});
       $returnTokenString = "";
       $returnTokenType = $tokenTypeEnd;
       $returnTokenValue = "";
     }
   }
   else
   {
     $remainingString = $$parseInfo{'remaining-string'};

     $remainingString =~ s/^[\s\r]*//;

     $tokenPosition = length($$parseInfo{'expression-string'})
                                 - length($remainingString);

     if($remainingString eq "")
     {
       $returnTokenPosition = $tokenPosition;
       $returnTokenString = "";
       $returnTokenType = $tokenTypeEnd;
       $returnTokenValue = "";
     }
     elsif($remainingString =~ /^ ( '[^']*'
                                  | "[^"]*"
				  | `[^`]*` )/x)
     {
       $returnTokenString = $1;
       $returnTokenValue = $returnTokenString;
       $returnTokenValue =~ s/^.(.*).$/\1/;
       $returnTokenType = $tokenTypeString;
       $returnTokenPosition = $tokenPosition;
     }
     elsif($remainingString =~ /^(['"`])/)
     {
       exprEvalError($parseInfo, $tokenPosition, $msg_missing_close_quote,
                      "quote = /$1/");
     }
     else
     {
       $functionInfo = $$parseInfo{'token-function'};

       if(defined $functionInfo)
       {
	 eval
	 {
           ($returnTokenString, $returnTokenType, $returnTokenValue)
	     = &$functionInfo($$parseInfo{'token-function-arg'},
	                       $$parseInfo{'syntax-check-only'},
	                       $remainingString);
	 };

	 if($@)
	 {
           exprEvalError($parseInfo, $tokenPosition, $msg_system_error,
		                ((ref($functionInfo) eq "CODE")
		                   ? "function is code\n"
			           : "function name = '$functionInfo'\n")
		                . $@);
	 }
         elsif( ! defined $returnTokenType)
	 {
	 }
         elsif($returnTokenType == $tokenTypeError)
	 {
           exprEvalError($parseInfo, $tokenPosition, $returnTokenValue,
		         ((ref($functionInfo) eq "CODE")
		            ? "function is code"
			    : "function name = '$functionInfo'"));
	 }
	 else
	 {
           $returnTokenPosition = $tokenPosition;
	 }
       }

       if( ! defined $returnTokenType)
       {
	 for($i = $maxTableTokenLength;
	      (( ! defined $returnTokenType) && ($i>0)); $i--)
	 {
           $tokenString = substr($remainingString,0,$i);
           $returnTokenType = $tokenTypeTable{$tokenString};
	 }

         if(defined $returnTokenType)
         {
           $returnTokenPosition = $tokenPosition;
           $returnTokenString = $tokenString;
           $returnTokenValue = $tokenString;
         }
       }

       if(defined $returnTokenType)
       {
       }
       elsif($remainingString =~ /^([_a-z]\w*)\s*\(/i)
       {
         $returnTokenString = $1;
         $returnTokenPosition = $tokenPosition;
         $returnTokenType = $tokenTypeFunctionCall;
         $returnTokenValue = $returnTokenString;
       }
       elsif($remainingString =~ /^([_a-z]\w*)/i)
       {
         $returnTokenString = $1;
         $returnTokenPosition = $tokenPosition;

	 $upperCaseTokenString = "\U$returnTokenString";

         $keywordOperatorTable = $$parseInfo{'keyword-operator-table'};

         if(defined $keywordOperatorTable)
	 {
           $returnTokenValue = $$keywordOperatorTable{$upperCaseTokenString};
	 }


	 if(defined $returnTokenValue)
	 {
           $returnTokenType = $tokenTypeTable{$returnTokenValue};
	 }
	 else
	 {
	   $constantInfo = $namedConstantTable{$upperCaseTokenString};

	   if(defined $constantInfo)
	   {
             $returnTokenType = $tokenTypeExprValue;
             $returnTokenValue = $constantInfo;
	   }
	   else
	   {
             $returnTokenType = $tokenTypeIdentifier;
             $returnTokenValue = $returnTokenString;
	   }
	 }
       }
       elsif($remainingString =~ /^   ( \d*[.]\d+ [eE][-+]?\d+
                                      | \d+       [eE][-+]?\d+
				      | \d+[.]?\d*
				      | [.]\d+)
				      ([^.\w]|$) /x)
       {
         $returnTokenString = $1;
         $returnTokenType = $tokenTypeNumber;
         $returnTokenPosition = $tokenPosition;

         $numberString = $returnTokenString;
         $numberString =~ s/^[.]/0./i;
	 $numberString =~ s/e/E/i;
	 $numberString =~ s/^(\d+)[.]?E/\1.0E/;
	 $numberString =~ s/E(\d)/E+\1/;
	 $returnTokenValue = eval($numberString);
       }
       elsif($remainingString =~ /^[\d.]/)
       {
         exprEvalError($parseInfo, $tokenPosition,
	   		 $msg_incorrectly_specified_number);
       }
     }

     if( ! defined $returnTokenType)
     {
       exprEvalError($parseInfo, $tokenPosition, $msg_unexpected_character,
                      "character = '"
			. substr($remainingString,0,1) . "'");
     }

     $$parseInfo{'remaining-string'}
	     = substr($remainingString,length($returnTokenString));

     $newTokenList = $$parseInfo{'new-token-list'};
     if(defined $newTokenList)
     {
       push(@$newTokenList,
             [$returnTokenPosition, $returnTokenString,
               $returnTokenType, $returnTokenValue] );
     }
   }

   if($returnTokenType == $tokenTypeIgnore)
   {
     ($returnTokenPosition, $returnTokenString, $returnTokenType,
       $returnTokenValue)
         = scanNextToken($parseInfo);
   }

   return ( $returnTokenPosition, $returnTokenString,
             $returnTokenType, $returnTokenValue);
}


#
#------------------------------------------------------------------------------
#
#  tokenInfo
#
#  creates a string with token information
#
#  ARGS:
#
#     1  -  token position
#     2  -  token string
#     3  -  token type
#     4  -  token value
#
#  RETURNS:  string with token information

sub tokenInfo
{
  my $tokenPosition = shift;
  my $tokenString = shift;
  my $tokenType = shift;
  my $tokenValue = shift;

  my $returnStr = "Token information:\n"
      . "    Position:\t$tokenPosition\n"
      . "    String:\t$tokenString\n"
      . "    Type:\t$tokenType\n"
      . "    Value:\t$tokenValue\n";

  return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  valueInfo
#
#  creates a string with value information
#
#  ARGS:
#
#     1  -  value type
#     2  -  value
#
#  RETURNS:  string with token information

sub valueInfo
{
  my $valueType = shift;
  my $value = shift;

  my $typeName = $valueTypeNameTable{$valueType};
  my $returnStr = "Value information:\n"
      . "    Type:\t$valueType"
              . ((defined $typeName) ? "  ($typeName)" : "") . "\n"
      . "    Value:\t$value\n";

  return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  exprEvalError
#
#  handles an expression error.  basically saves error information in parse
#  info table and the calls die().
#
#  ARGS:
#
#     1  -  table of parsing information
#     2  -  position in string where error occurs
#     3  -  error message
#     4  -  developer error message
#
#  NOTE:  Does not return

sub exprEvalError
{
  my $parseInfo = shift;
  my $position = shift;
  my $errorMessage = shift;
  my $developerErrorMessage = shift;

  $$parseInfo{'error-position'} = $position;
  $$parseInfo{'error-message'} = $errorMessage;
  $$parseInfo{'developer-error-message'} = $developerErrorMessage;

  die("");
}


#------------------------------------------------------------------------------
#  return 1 for require
1;


############################# Copyright #######################################

# Copyright (c) 2001 Scott Luebking. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

###############################################################################

 
