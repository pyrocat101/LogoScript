# Control Flow

VariableDeclaration: `STLOCAL/STGLOBAL x`

VariableStatement: `POP`

IfStatement:

```
	if (cond) {
		trueExp;
	}
```

```
	cond
	JF label1
	trueExp (pop)
label1:	...
```

```
	if (cond) {
		trueExp;
	} else {
		falseExp;
	}
```

```
	cond
	JF label1
	trueExp (pop)
	JMP label2
label1:	falseExp (pop)
label2:	...
```

DoWhileStatement:

```
	do {
		exp
		break;
		continue;
	} while (cond);
```

```
label1:	exp (pop)
	JMP label3 (this is break!)
	JMP label2 (this is continue!)
label2:	cond
	JT label1
label3:	...
```

WhileStatement:

```
while (cond) {
    exp
    break;
    continue;
}
```

```
label1:	cond
	JF label2
	exp (pop)
	JMP label2 (this is break!)
	JMP label1 (this is continue!)
	JMP label1
label2:	...
```

ForStatement:

```
for (init; test; counter) {
    exp
    break;
    continue;
}
```

```
	init (pop)
label1:	test
	JF label3
	exp (pop)
	JMP label3 (this is break!)
	JMP label2 (this is continue!)
label2:	counter (pop)
	JMP label1
label3:	...
```

In case that there are no 'test' part, the code is:

```
	init (pop)
label1:	exp (pop)
	JMP label3 (this is break!)
	JMP label2 (this is continue!)
label2: counter (pop)
	JMP label1
label3: ...
```

# Data Structure & Interface

We use scopes to implement code back-patching.
This is intended for 'continue' and 'break'

```
function Scope (codeObj) {
	this.continueSlots = [];
	this.breakSlots = [];
	this.codeObj = codeObj;
}
function ScopeChain () {
	this._chain = [];
}
ScopeChain.prototype.pushScope = function () {
	this._chain.push(new Scope());
}
ScopeChain.prototype.popScope = function () {
	return this._chain.pop();
}
ScopeChain.prototype.patchContinue = function (label) {
	if (this._chain.length < 1) {
		throw new Error('No scope in chain')
	}	
	var _top = this._chain[this._chain.length - 1];
	_top.continueSlots.forEach(function(slot) {
		this.codeObj.currentCode[slot] = label;
	}
}
ScopeChain.prototype.patchBreak = function (label) {
	if (this._chain.length < 1) {
		throw new Error('No scope in chain')
	}	
	var _top = this._chain[this._chain.length - 1];
	_top.breakSlots.forEach(function(slot) {
		this.codeObj.currentCode[slot] = label;
	}
}
ScopeChain.prototype.addContinueSlot = function (slot) {
	var _top = this._chain[this._chain.length - 1];
	_top.continueSlots.push(slot);
}
ScopeChain.prototype.addContinueSlot = function (slot) {
	var _top = this._chain[this._chain.length - 1];
	_top.breakSlots.push(slot);
}
CodeObject.prototype.reserveSlot = function () {
	var _ret = this.currentCode.length;
	this.emit(-1);
	return _ret;
}
CodeObject.prototype.genSlot = function () {
	return this.currentCode.length - 1;
}
```
