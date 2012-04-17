/*
 * Logo grammar
 */

/* Intializer */
{
    Q = {
        'flatten': function (xs) {
            if (xs instanceof Array) {
                for (var i = 0; i < xs.length; i++) {
                    xs[i] = arguments.callee(xs[i]);
                }
                return xs.join('');
            } else {
                return xs;
            }
        },
        'line': function () {
            // actually this workaround func can compute column
            var line = 1;
            var column = 1;
            var seenCR = false;
            for (var i = 0; i < pos; i++) {
                var ch = input.charAt(i);
                if (ch === '\n') {
                    if (!seenCR) { line++; }
                    column = 1;
                    seenCR = false;
                } else if (ch === '\r' | ch === '\u2028' || ch === '\u2029') {
                    line++;
                    column = 1;
                    seenCR = true;
                } else {
                    column++;
                    seenCR = false;
                }
            }
            //return { line: line, column: column, pos: pos };
            return line;
        }
    };

    function SourceElements(x) {
        this.type = 'source_elements',
        this.line = Q.line();
        this.value = x;
    };

    function FunctionDecl(name, params, body) {
        this.type = 'function_decl';
        this.line = Q.line();
        this.value = [name, params, body];
    };
    
    function ParamList(params) {
        this.type = 'param_list';
        this.line = Q.line();
        this.value = (params === "") ? [] : params;
    };

    function IfStatement (cond, stmt, el) {
        this.type = 'if_stmt';
        this.line = Q.line();
        this.value = [cond, stmt, el];
    }

    function Unary(op, u) {
        this.type = "unary";
        this.line = Q.line();
        this.value = [op, u];
    }

    function Binary(op, l, r) {
        this.type = "binary";
        this.line = Q.line();
        this.value = [op, l, r];        
    }

    function ExpressionStatement(x) {
        this.type = "expression_stmt";
        this.line = Q.line();
        this.value = x;
    }

    function CallExpression(callee, args) {
        this.type = "call_expression";
        this.line = Q.line();
        this.value = [callee, args];        
    }

    function Arguments(args) {
        this.type = "arguments";
        this.line = Q.line();
        this.value = args;     
    }

    function WhileStatement(cond, stmt) {
        this.type = "while_stmt";
        this.line = Q.line();
        this.value = [cond, stmt];  
    }

    function StatementBlock(xs) {
        this.type = "stmt_block";
        this.line = Q.line();
        this.value = xs;  
    }

    function ForStatement(iter, init, end, step, stmt) {
        this.type = "for_stmt";
        this.line = Q.line();
        this.value = [iter, init, end, step, stmt];  
    }

    function EmptyStatement() {
        this.type = "empty_stmt";
        this.line = Q.line();
        // this.value = [];  
    }

    function DoWhileStatement(stmt, cond) {
        this.type = "do_while_stmt";
        this.line = Q.line();
        this.value = [stmt, cond];  
    }

    function ReturnStatement(ret) {
        this.type = "return_stmt";
        this.line = Q.line();
        this.value = ret;  
    }

    function BreakStatement() {
        this.type = "break_stmt";
        this.line = Q.line();
        // this.value = [];  
    }

    function ContinueStatement() {
        this.type = "continue_stmt";
        this.line = Q.line();
        // this.value = [];  
    }

    function Literal(x) {
        this.type = "literal";
        this.line = Q.line();
        this.value = x;
    }

    function Identifier(s) {
        this.type = "identifier";
        this.line = Q.line();
        this.value = s;
    }
}

program
  = _ x:source_elements? _ { return x === "" ? new SourceElements([]) : x; }

source_elements "source elements"
  = x:source_element+ { return new SourceElements(x); }

source_element "source element"
  = function_decl
  / statement

/* functions */
function_decl "function declaration"
  = _ 'function' $ ident:identifier _ params:param_list _ '{' _ body:function_body _ '}' {
        return new FunctionDecl(ident, params, body);
    }

param_list "parameter list"
  = '(' params:comma_seperated_identifiers? ')' { return new ParamList(params); }

comma_seperated_identifiers "comma-separated identifiers"
  = start:(_ i:identifier _ ',' _ {return i;})* last:identifier {
        return start.concat(last);
    }

function_body "function body"
  = statement*

/* statement */
stmt_or_block "statement or block"
  = $ x:statement { return x; }
  / _ x:stmt_block { return x; }

stmt_block "statement block"
  = '{' _ stmts:statement* _ '}' {
        return new StatementBlock((stmts === "") ? [] : stmts);
    }

statement "statement"
  = empty_stmt
  / expression_stmt
  / if_stmt
  / iteration_stmt
  / continue_stmt
  / break_stmt
  / return_stmt

empty_stmt "empty statement"
  = _ ';' _ { return new EmptyStatement(); }

expression_stmt "expression statement"
  = _ exp:expression _ ';' { return new ExpressionStatement(exp); } 

/* maybe some FIX for 'else' */
if_stmt "if statement"
  = _ 'if' _ '(' cond:expression ')' stmt:stmt_or_block _ 'else' el:stmt_or_block {
        return new IfStatement(cond, stmt, el);
    }
  / _ 'if' _ '(' _ cond:expression _ ')' stmt:stmt_or_block {
        return new IfStatement(cond, stmt, undefined);
    }

iteration_stmt "iteration statement"
  = do_while_stmt
  / while_stmt
  / for_stmt

do_while_stmt "do-while statement"
  = _ 'do' stmt:stmt_or_block _ 'while' _ '(' _ cond:expression _ ')' _ ';' _ {
        return new DoWhileStatement(stmt, cond);
    }

while_stmt "while statement"
  = _ 'while' _ '(' _ cond:expression _ ')' stmt:stmt_or_block {
        return new WhileStatement(cond, stmt);
    }

for_stmt "for statement"
  = _ 'for' _ '(' _ iter:lvalue_expression _ '=' _ init:additive $ 'to' $
    end:additive $ 'step' $ step:additive _ ')' stmt:stmt_or_block {
        return new ForStatement(iter, init, end, step, stmt);
    }
  / _ 'for' _ '(' _ iter:lvalue_expression _ '=' _ init:additive $ 'to' $
    end:additive _ ')' stmt:stmt_or_block {
        return new ForStatement(iter, init, end, undefined, stmt);
    }

continue_stmt "continue statement"
  = _ 'continue' _ ';' { return new ContinueStatement(); }

break_stmt "break statement"
  = _ 'break' _ ';' { return new BreakStatement(); }

return_stmt "return statement"
  = _ 'return' $ ret:expression? _ ';' {
        return new ReturnStatement(ret);
    }

/* expression */
expression "expression"
  = x:assignment { return x; }

call_expression "call expression"
  = callee:identifier _ args:arguments { return new CallExpression(callee, args); }

arguments
  = '(' args:comma_separated_args? ')' { return new Arguments((args === "") ? [] : args); }

comma_separated_args "comma-separated arguments"
  = start:(_ i:expression _ ',' _ {return i;})* last:expression { return start.concat(last); }

assignment "assignment expression"
  = _ l:lvalue_expression _ op:'=' _ r:assignment {
        return new Binary(op, l, r);
    }
  / _ x:logical_or { return x; }

logical_or "logical OR expression"
  = _ l:logical_and _ op:('||'/'^') _ r:logical_or {
        return new Binary(op, l, r);
    }
  / _ x:logical_and { return x; }

logical_and "logical AND expression"
  = _ l:equality _ op:'&&' _ r:logical_and {
        return new Binary(op, l, r);  
    }
  / _ x:equality { return x; }

equality "equality expression"
  = _ l:relational _ op:('=='/'!=') _ r:equality {
        return new Binary(op, l, r);
    }
  / _ x:relational { return x; }

relational "relational expression"
  = _ l:additive _ op:('<'/'>'/'<='/'>=') _ r:relational {
        return new Binary(op, l, r);
    }
  / _ x:additive { return x; }

additive "additive expression"
  = _ l:multiplicative _ op:('+'/'-') _ r:additive {
        return new Binary(op, l, r);
    }
  / _ x:multiplicative { return x; }

multiplicative "multiplicative expression"
  = _ l:unary _ op:('*'/'/'/'%') _ r:multiplicative {
        return new Binary(op, l, r);
    }
  / _ x:unary { return x; }

unary "unary expression"
  = _ x:primary { return x; }
  / _ '!' _ x:unary { return new Unary('!', x); }
  / _ '-' _ x:unary { return new Unary('-', x); }
  / _ '+' _ x:unary { return new Unary('+', x); }

lvalue_expression "left-value expression"
  = x:identifier { return x; }

primary "primary expression"
  = literal
  / _ '(' exp:expression _ ')' { return exp; }
  / call_expression /* maybe need FIX */
  / identifier

literal "literal"
  = 'true' { return new Literal(true); }
  / 'false' { return new Literal(false); }
  / numeric

/* lexer rules */
numeric "numeric literal"
  = x:decimal { return new Literal(parseFloat(Q.flatten(x))); } 

decimal "decimal numeric literal"
  = [0-9]+[\.][0-9]*([eE][\+\-]?[0-9]+)?
  / [\.]?[0-9]+([eE][\+\-]?[0-9]+)?

identifier "identifier"
  = !keyword x:([_a-zA-Z][_a-zA-Z0-9]*) { return new Identifier(Q.flatten(x)); }

keyword "reserved keyword"
  = 'if'/'else'/'do'/'while'/'for'/'continue'/'break'/'return'

comment "comment"
  = block_comment
  / single_comment

block_comment "block comment"
  = "/*" (!"*/" .)* "*/"

single_comment "single-line comment"
  = "//" (!linebreak .)*

linebreak "line break"
  = [\r\n]

whitespace "whitespace"
  = [ \t\v\f]

_ "whitespace"
  = (whitespace  / linebreak / comment)*

$ "whitespace"
  = (whitespace  / linebreak / comment)+

__unknown__ "unknown character"
  = . // TODO: throw error