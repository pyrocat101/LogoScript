/*
 * LogoScript parser based on ECMA script peg.js grammar.
 * (https://github.com/dmajda/pegjs/blob/master/examples/javascript.pegjs)
 *
 * The parser builds a tree representing the parsed LogoScript, composed of
 * basic JavaScript values, arrays and objects (basically JSON). It can be
 * easily used by various JavaScript processors, transformers, etc.
 */

{
  node = require('./node');
}

start
  = __ program:Program __ { return program; }

/* ===== A.1 Lexical Grammar ===== */

SourceCharacter
  = .

WhiteSpace "whitespace"
  = [\t\v\f ]

LineTerminator
  = [\n\r\u2028\u2029]

LineTerminatorSequence "end of line"
  = "\n"
  / "\r\n"
  / "\r"
  / "\u2028" // line separator
  / "\u2029" // paragraph separator

Comment "comment"
  = MultiLineComment
  / SingleLineComment

MultiLineComment
  = "/*" (!"*/" SourceCharacter)* "*/"

MultiLineCommentNoLineTerminator
  = "/*" (!("*/" / LineTerminator) SourceCharacter)* "*/"

SingleLineComment
  = "//" (!LineTerminator SourceCharacter)*

Identifier "identifier"
  = !ReservedWord name:IdentifierName { return name; }

IdentifierName "identifier"
  = start:IdentifierStart parts:IdentifierPart* {
      return start + parts.join("");
    }

IdentifierStart
  = AlphaLetter
  / "$"
  / "_"

IdentifierPart
  = IdentifierStart
  / DecimalDigit

AlphaLetter
  = [a-zA-Z]

ReservedWord
  = Keyword
  / NullLiteral
  / BooleanLiteral

Keyword
  = (
        "break"
      / "continue"
      / "delete"
      / "do"
      / "else"
      / "for"
      / "function"
      / "if"
      / "in"
      / "return"
      / "typeof"
      / "while"
      / "to"
      / "step"
    )
    !IdentifierPart

Literal
  = NullLiteral
  / BooleanLiteral
  / value:NumericLiteral { return new node.NumericLiteral(value); }
  / value:StringLiteral { return new node.StringLiteral(value); }

NullLiteral
  = NullToken { return new node.NullLiteral(); }

BooleanLiteral
  = TrueToken  { return new node.BooleanLiteral(true); }
  / FalseToken { return new node.BooleanLiteral(false); }

NumericLiteral "number"
  = literal:(HexIntegerLiteral / DecimalLiteral) !IdentifierStart {
      return literal;
    }

DecimalLiteral
  = before:DecimalIntegerLiteral
    "."
    after:DecimalDigits?
    exponent:ExponentPart? {
      return parseFloat(before + "." + after + exponent);
    }
  / "." after:DecimalDigits exponent:ExponentPart? {
      return parseFloat("." + after + exponent);
    }
  / before:DecimalIntegerLiteral exponent:ExponentPart? {
      return parseFloat(before + exponent);
    }

DecimalIntegerLiteral
  = "0" / digit:NonZeroDigit digits:DecimalDigits? { return digit + digits; }

DecimalDigits
  = digits:DecimalDigit+ { return digits.join(""); }

DecimalDigit
  = [0-9]

NonZeroDigit
  = [1-9]

ExponentPart
  = indicator:ExponentIndicator integer:SignedInteger {
      return indicator + integer;
    }

ExponentIndicator
  = [eE]

SignedInteger
  = sign:[-+]? digits:DecimalDigits { return sign + digits; }

HexIntegerLiteral
  = "0" [xX] digits:HexDigit+ { return parseInt("0x" + digits.join("")); }

HexDigit
  = [0-9a-fA-F]

StringLiteral "string"
  = parts:('"' DoubleStringCharacters? '"' / "'" SingleStringCharacters? "'") {
      return parts[1];
    }

DoubleStringCharacters
  = chars:DoubleStringCharacter+ { return chars.join(""); }

SingleStringCharacters
  = chars:SingleStringCharacter+ { return chars.join(""); }

DoubleStringCharacter
  = !('"' / "\\" / LineTerminator) char_:SourceCharacter { return char_;     }
  / "\\" sequence:EscapeSequence                         { return sequence;  }
  / LineContinuation

SingleStringCharacter
  = !("'" / "\\" / LineTerminator) char_:SourceCharacter { return char_;     }
  / "\\" sequence:EscapeSequence                         { return sequence;  }
  / LineContinuation

LineContinuation
  = "\\" sequence:LineTerminatorSequence { return sequence; }

EscapeSequence
  = CharacterEscapeSequence
  / "0" !DecimalDigit { return "\0"; }
  / HexEscapeSequence
  / UnicodeEscapeSequence

CharacterEscapeSequence
  = SingleEscapeCharacter
  / NonEscapeCharacter

SingleEscapeCharacter
  = char_:['"\\bfnrtv] {
      return char_
        .replace("b", "\b")
        .replace("f", "\f")
        .replace("n", "\n")
        .replace("r", "\r")
        .replace("t", "\t")
        .replace("v", "\x0B") // IE does not recognize "\v".
    }

NonEscapeCharacter
  = (!EscapeCharacter / LineTerminator) char_:SourceCharacter { return char_; }

EscapeCharacter
  = SingleEscapeCharacter
  / DecimalDigit
  / "x"
  / "u"

HexEscapeSequence
  = "x" h1:HexDigit h2:HexDigit {
      return String.fromCharCode(parseInt("0x" + h1 + h2));
    }

UnicodeEscapeSequence
  = "u" h1:HexDigit h2:HexDigit h3:HexDigit h4:HexDigit {
      return String.fromCharCode(parseInt("0x" + h1 + h2 + h3 + h4));
    }


/* Tokens */

BreakToken      = "break"            !IdentifierPart
ContinueToken   = "continue"         !IdentifierPart
DeleteToken     = "delete"           !IdentifierPart { return "delete"; }
DoToken         = "do"               !IdentifierPart
ElseToken       = "else"             !IdentifierPart
FalseToken      = "false"            !IdentifierPart
ForToken        = "for"              !IdentifierPart
FunctionToken   = "function"         !IdentifierPart
IfToken         = "if"               !IdentifierPart
NullToken       = "null"             !IdentifierPart
ReturnToken     = "return"           !IdentifierPart
TrueToken       = "true"             !IdentifierPart
TypeofToken     = "typeof"           !IdentifierPart { return "typeof"; }
WhileToken      = "while"            !IdentifierPart
ToToken         = "to"               !IdentifierPart
StepToken       = "step"             !IdentifierPart


/* Automatic Semicolon Insertion */

EOS
  = __ ";"
  / _ LineTerminatorSequence
  / _ &"}"
  / __ EOF

EOSNoLineTerminator
  = _ ";"
  / _ LineTerminatorSequence
  / _ &"}"
  / _ EOF

EOF
  = !.

  
/* Whitespace */

_
  = (WhiteSpace / MultiLineCommentNoLineTerminator / SingleLineComment)*

__
  = (WhiteSpace / LineTerminatorSequence / Comment)*

/* ===== A.2 Number Conversions ===== */

/*
 * Rules from this section are either unused or merged into previous section of
 * the grammar.
 */

/* ===== A.3 Expressions ===== */

PrimaryExpression
  = name:Identifier { return new node.Variable(name); }
  / Literal
  / "(" __ expression:Expression __ ")" { return expression; }

CallExpression
  = name:PrimaryExpression __ arguments:Arguments {
      return new node.FunctionCall(name, arguments);
    }

Arguments
  = "(" __ arguments:ArgumentList? __ ")" {
    return arguments !== "" ? arguments : [];
  }

ArgumentList
  = head:AssignmentExpression tail:(__ "," __ AssignmentExpression)* {
    var result = [head];
    for (var i = 0; i < tail.length; i++) {
      result.push(tail[i][3]);
    }
    return result;
  }

LeftHandSideExpression
  = PrimaryExpression

PostfixExpression
  = expression:LeftHandSideExpression _ operator:PostfixOperator {
      return new node.PostfixExpression(operator, expression);
    }
  / CallExpression
  / PrimaryExpression

PostfixOperator
  = "++"
  / "--"

UnaryExpression
  = PostfixExpression
  / operator:UnaryOperator __ expression:UnaryExpression {
      return UnaryExpression(operator, expression);
    }

UnaryOperator
  = DeleteToken
  / "++"
  / "--"
  / "+"
  / "-"
  / "~"
  /  "!"

MultiplicativeExpression
  = head:UnaryExpression
    tail:(__ MultiplicativeOperator __ UnaryExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

MultiplicativeOperator
  = operator:("*" / "/" / "%") !"=" { return operator; }

AdditiveExpression
  = head:MultiplicativeExpression
    tail:(__ AdditiveOperator __ MultiplicativeExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

AdditiveOperator
  = "+" !("+" / "=") { return "+"; }
  / "-" !("-" / "=") { return "-"; }

ShiftExpression
  = head:AdditiveExpression
    tail:(__ ShiftOperator __ AdditiveExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

ShiftOperator
  = "<<"
  / ">>>"
  / ">>"

RelationalExpression
  = head:ShiftExpression
    tail:(__ RelationalOperator __ ShiftExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

RelationalOperator
  = "<="
  / ">="
  / "<"
  / ">"

EqualityExpression
  = head:RelationalExpression
    tail:(__ EqualityOperator __ RelationalExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

EqualityOperator
  = "=="
  / "!="

BitwiseANDExpression
  = head:EqualityExpression
    tail:(__ BitwiseANDOperator __ EqualityExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

BitwiseANDOperator
  = "&" !("&" / "=") { return "&"; }

BitwiseXORExpression
  = head:BitwiseANDExpression
    tail:(__ BitwiseXOROperator __ BitwiseANDExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

BitwiseXOROperator
  = "^" !("^" / "=") { return "^"; }

BitwiseORExpression
  = head:BitwiseXORExpression
    tail:(__ BitwiseOROperator __ BitwiseXORExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

BitwiseOROperator
  = "|" !("|" / "=") { return "|"; }

LogicalANDExpression
  = head:BitwiseORExpression
    tail:(__ LogicalANDOperator __ BitwiseORExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

LogicalANDOperator
  = "&&" !"=" { return "&&"; }

LogicalORExpression
  = head:LogicalANDExpression
    tail:(__ LogicalOROperator __ LogicalANDExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

LogicalOROperator
  = "||" !"=" { return "||"; }

ConditionalExpression
  = condition:LogicalORExpression __
    "?" __ trueExpression:AssignmentExpression __
    ":" __ falseExpression:AssignmentExpression {
      return new node.ConditionalExpression(
          condition, trueExpression, falseExpression);
    }
  / LogicalORExpression

AssignmentExpression
  = left:LeftHandSideExpression __
    operator:AssignmentOperator __
    right:AssignmentExpression {
      return AssignmentExpression(operator, left, right);
    }
  / ConditionalExpression

AssignmentOperator
  = "*="
  / "/="
  / "%="
  / "+="
  / "-="
  / "<<="
  / ">>="
  / ">>>="
  / "&="
  / "^="
  / "|="

Expression
  = head:AssignmentExpression
    tail:(__ "," __ AssignmentExpression)* {
      var result = head;
      for (var i = 0; i < tail.length; i++) {
        result = new node.BinaryExpression(
            tail[i][1], result, tail[i][3]);
      }
      return result;
    }

/* ===== A.4 Statements ===== */

/* We do not consider |FunctionDeclaration| as statements. */
Statement
  = Block
  / VariableStatement
  / EmptyStatement
  / ExpressionStatement
  / IfStatement
  / IterationStatement
  / ContinueStatement
  / BreakStatement
  / ReturnStatement

Block
  = "{" __ statements:(StatementList __)? "}" {
      return new node.Block(statements !== "" ? statements[0] : []);
    }

StatementList
  = head:Statement tail:(__ Statement)* {
      var result = [head];
      for (var i = 0; i < tail.length; i++) {
        result.push(tail[i][1]);
      }
      return result;
    }

VariableStatement
  = declarations:VariableDeclarationList EOS {
      return new node.VariableStatement(declarations);
    }

VariableDeclarationList
  = head:VariableDeclaration tail:(__ "," __ VariableDeclaration)* {
      var result = [head];
      for (var i = 0; i < tail.length; i++) {
        result.push(tail[i][3]);
      }
      return result;
    }

VariableDeclaration
  = name:Identifier __ value:Initialiser {
      return new node.VariableDeclaration(name, value);
    }

Initialiser
  = "=" (!"=") __ expression:(VariableDeclaration/AssignmentExpression) { return expression; }

EmptyStatement
  = ";" { return new node.EmptyStatement(); }

ExpressionStatement
  = !("{" / FunctionToken) expression:Expression EOS { return expression; }

IfStatement
  = IfToken __
    "(" __ condition:Expression __ ")" __
    ifStatement:Statement
    elseStatement:(__ ElseToken __ Statement)? {
      return new node.IfStatement(condition, ifStatement,
          elseStatement !== "" ? elseStatement[3] : null);
    }

IterationStatement
  = DoWhileStatement
  / WhileStatement
  / ForStatement

DoWhileStatement
  = DoToken __
    statement:Statement __
    WhileToken __ "(" __ condition:Expression __ ")" EOS {
      return new node.DoWhileStatement(condition, statement);
    }

WhileStatement
  = WhileToken __ "(" __ condition:Expression __ ")" __ statement:Statement {
      return new node.WhileStatement(condition, statement);
    }

ForStatement
  = ForToken __
    "(" __
    initializer:(
        declarations:VariableDeclarationList {
          return new node.VariableStatement(declarations);
        }
      / Expression?
    ) __
    ";" __
    test:Expression? __
    ";" __
    counter:Expression? __
    ")" __
    statement:Statement
    {
      return new node.ForStatement(
          initializer !== "" ? initializer : null,
          test !== "" ? test : null,
          counter !== "" ? counter : null,
          statement);
    }

ContinueStatement
  = ContinueToken _ EOSNoLineTerminator {
      return new node.ContinueStatement();
    }

BreakStatement
  = BreakToken _ EOSNoLineTerminator {
      return new node.BreakStatement();
    }

ReturnStatement
  = ReturnToken _
    value:(
        expression:Expression EOS { return expression; }
      / EOSNoLineTerminator       { return ""; }
    ) {
      return new node.ReturnStatement(value !== "" ? value : null);
    }

/* ===== A.5 Functions and Programs ===== */

FunctionDeclaration
  = FunctionToken __ name:Identifier __
    "(" __ params:FormalParameterList? __ ")" __
    "{" __ elements:FunctionBody __ "}" {
      return new node.Function_(
          name, params !== "" ? params : [], elements);
    }

FormalParameterList
  = head:Identifier tail:(__ "," __ Identifier)* {
      var result = [head];
      for (var i = 0; i < tail.length; i++) {
        result.push(tail[i][3]);
      }
      return result;
    }

FunctionBody
  = elements:SourceElements? { return elements !== "" ? elements : []; }

Program
  = elements:SourceElements? {
      return new node.Program(elements !== "" ? elements : []);
    }

SourceElements
  = head:SourceElement tail:(__ SourceElement)* {
      var result = [head];
      for (var i = 0; i < tail.length; i++) {
        result.push(tail[i][1]);
      }
      return result;
    }

/* We allow |FunctionDeclaration| here. */
SourceElement
  = Statement
  / FunctionDeclaration
