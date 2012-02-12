var parser = require('./logo.js'),
	fs = require('fs'),
	util = require('util'),
	_ = require('underscore');

// store byte-code and context
var CodeObject = function (
	name /* string */) {
	this.args = [];
	this.name = name;
	//this.filename = __filename;
	//this.firstline = 1;
	this.var_names = [];
	this.byte_codes = [];
};
CodeObject.prototype.intern_name = function (elem) {
	//FIXME: CodeObject
	var idx = _.indexOf(this.var_names, elem);
	if (idx == -1) {
		this.var_names.push(elem);
		return this.var_names.length - 1;
	} else {
		return idx;
	}
};
var const_pool = [];
var func_pool = {};

var intern_const = function (pool /* array */, elem) {
	var idx = _.indexOf(pool, elem);
	if (idx == -1) {
		pool.push(elem);
		return pool.length - 1;
	} else {
		return idx;
	}
};
// var put_func = function (pool /* table */, func) {
// 	pool[func.name] = func;
// }
// var get_func = function (pool /* array */, name) {
// 	return pool[func.name];
// }
var gen_table = {
	'source_elements': function (ast, code) {
		_.each(ast.value, function (x) {
			gen_code(x, code);
		});
	},
	'function_decl': function (ast, code) {
		
	},
	'param_list': function (ast, code) {
		
	},
	'expression_stmt': function (ast, code) {
		gen_code(ast.value, code);
		code.byte_codes.push("POP");
	},
	'binary': function (ast, code) {
		//assignemnt
		if (ast.value[0] == '=') {
			//TODO: support more left-value
			(function () {
				var name = ast.value[1].value;
				gen_code(ast.value[2], code);
				var idx = code.intern_name(name);
				code.byte_codes.push("ST_NAME " + idx);
			})();
			return;
		}
		gen_code(ast.value[1], code),
		gen_code(ast.value[2], code);
		switch (ast.value[0]) {
		case '+':
			code.byte_codes.push("ADD");
			break;
		case '-':
			code.byte_codes.push("SUB");
			break;
		case '*':
			code.byte_codes.push("MUL");
			break;
		case '/':
			code.byte_codes.push('DIV');
			break;
		case '==':
			code.byte_codes.push('CEQ');
			break;
		case '!=':
			code.byte_codes.push('CNEQ');
			break;
		case '<':
			code.byte_codes.push('CLT');
			break;
		case '>':
			code.byte_codes.push('CGT');
			break;
		case '<=':
			code.byte_codes.push('CLTE');
			break;
		case '>=':
			code.byte_codes.push('CGTE');
			break;
		case '**':
		//FIXME: implement power operator in parser
			code.byte_codes.push('POW');
			break;
		case '&&':
			code.byte_codes.push('AND');
			break;
		case '||':
			code.byte_codes.push('OR');
			break;
		case '^':
			code.byte_codes.push('XOR');
			break;
		default:
			throw new Error('invalid binary operator');
		}
	},
	'literal': function (ast, code) {
		var idx = intern_const(const_pool, ast.value);
		code.byte_codes.push("LD_CONST " + idx);
	},
	'function_decl': function (ast, code) {
		//ast.value = [name, params, body]
		var func_name = ast.value[0].value;
		var func = new CodeObject(func_name);
		//FIXME: check parameter duplicates
		_.each(ast.value[1].value, function (x) {
			code.args.push(x.value);
		});
		//generate function body
		_.each(ast.value[2], function (x) {
			gen_code(x, func);
		});
		//add to function pool
		func_pool[func.name] = func;
	},
	'call_expression': function (ast, code) {
		//ast.value: [callee, args]
		var callee_name = ast.value[0].value;
		var argcount = ast.value[1].value.length;
		_.each(ast.value[1].value, function (x) {
			gen_code(x, code);
		});
		var argcount = ast.value[1].value.length;
		var idx = code.intern_name(callee_name);
		code.byte_codes.push('LD_FUNC ' + idx);
		code.byte_codes.push('CALL_FUNC ' + argcount);
	},
	'return_stmt': function (ast, code) {
		gen_code(ast.value, code);
		code.byte_codes.push('RET_FUNC');
	},
	'identifier': function (ast, code) {
		var idx = code.intern_name(ast.value);
		code.byte_codes.push("LD_NAME " + idx);
	}
};

var gen_code = function (ast, code) {
	return gen_table[ast.type](ast, code);
};

// process.on('uncaughtException', function(err) {
//   console.log(err);
// });
if (process.argv.length < 3) {
	throw new Error('no input file');
};
fs.readFile(process.argv[2], 'utf-8', function (err, data) {
	if (err) console.log(err);
	var ast = parser.parse(data);
	console.log(util.inspect(ast, false, null));
	var main = new CodeObject('__main__');
	gen_code(ast, main);
	console.log('====BYTECODE====');
	_.each(main.byte_codes, function (x) {
		console.log(x);
	});
	console.log('====CONST POOL====');
	console.log(const_pool);
	console.log('====NAMES====');
	console.log(main.var_names);
	console.log('====FUNCTIONS====');
	_.each(func_pool, function (v, k) {
		console.log('--' + k + '--');
		_.each(v.byte_codes, function (x) {
			console.log(x);
		});
	});
});