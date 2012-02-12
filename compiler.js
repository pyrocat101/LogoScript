var parser = require('./logo.js'),
	fs = require('fs'),
	util = require('util');
	_ = require('underscore');

var var_names = [];
var glob_vars = [];
var glob_names = [];
var const_pool = [];
var byte_codes = [];
var is_glob = true;
var intern_const = function (pool /* array */, elem) {
	var idx = _.indexOf(pool, elem);
	if (idx == -1) {
		pool.push(elem);
		return pool.length - 1;
	} else {
		return idx;
	}
};
var intern_glob = function (names /* string array */, elem) {
	var idx = _.indexOf(names, elem);
	if (idx == -1) {
		names.push(elem);
		return names.length - 1;
	} else {
		return idx;
	}
};
//FIXME: same logic as intern_glob
var intern_local = function (names /* string */, elem) {
	var idx = _.indexOf(names, elem);
	if (idx == -1) {
		names.push(elem);
		return names.length - 1;
	} else {
		return idx;
	}
};
var gen_table = {
	'source_elements': function (ast) {
		_.each(ast.value, gen_code);
	},
	'function_decl': function (ast) {
		
	},
	'param_list': function (ast) {
		
	},
	'expression_stmt': function (ast) {
		gen_code(ast.value);
		byte_codes.push("POP");
	},
	'binary': function (ast) {
		//assignemnt
		if (ast.value[0] == '=') {
			//TODO: support more left-value
			(function () {
				var name = ast.value[1].value;
				gen_code(ast.value[2]);
				if (_.indexOf(glob_vars, name) != -1) {
					//undefined in global scope
					if (is_glob) {
						//store in global scope
						var idx = intern_glob(glob_names, name);
						byte_codes.push("ST_GLOBAL " + idx);
						glob_names.push(name);
					} else {
						//store in local scope
						var idx = intern_local(var_names, name);
						byte_codes.push("ST_LOCAL " + idx);
					}
				} else {
					//defined in global scope
					var idx = intern_glob(glob_names, name);
					byte_codes.push("ST_GLOBAL " + idx);
				}
			})();
			return;
		}
		gen_code(ast.value[1]),
		gen_code(ast.value[2]);
		switch (ast.value[0]) {
		case '+':
			byte_codes.push("ADD");
			break;
		case '-':
			byte_codes.push("SUB");
			break;
		case '*':
			byte_codes.push("MUL");
			break;
		case '/':
			byte_codes.push('DIV');
			break;
		case '==':
			byte_codes.push('CEQ');
			break;
		case '!=':
			byte_codes.push('CNEQ');
			break;
		case '<':
			byte_codes.push('CLT');
			break;
		case '>':
			byte_codes.push('CGT');
			break;
		case '<=':
			byte_codes.push('CLTE');
			break;
		case '>=':
			byte_codes.push('CGTE');
			break;
		case '**':
		//FIXME: implement power operator in parser
			byte_codes.push('POW');
			break;
		case '&&':
			byte_codes.push('AND');
			break;
		case '||':
			byte_codes.push('OR');
			break;
		case '^':
			byte_codes.push('XOR');
			break;
		default:
			throw new Error("invalid binary operator");
		}
	},
	'literal': function (ast) {
		var idx = intern_const(const_pool, ast.value);
		byte_codes.push("LD_CONST " + idx);
	},
};

var gen_code = function (ast) {
	return (gen_table[ast.type])(ast);
};

process.on('uncaughtException', function(err) {
  console.log(err);
});
if (process.argv.length < 3) {
	throw new Error('no input file');
};
fs.readFile(process.argv[2], 'utf-8', function (err, data) {
	if (err) console.log(err);
	var ast = parser.parse(data);
	console.log(util.inspect(ast, true, null));
	gen_code(ast);
	console.log('====BYTECODE====');
	_.each(byte_codes, function (x) {
		console.log(x);
	});
	console.log('====CONST POOL====');
	console.log(const_pool);
	console.log('====GLOBAL NAMES====');
	console.log(glob_names);
})