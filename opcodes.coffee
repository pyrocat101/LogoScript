# This is the opcode list of LogoScript virtual machine.
@HALT = 1 # stop the virtual machine
@POP = 2 # pop TOS
@LDCONST = 3  # load constant
@LDLOCAL = 4  # load local var
@LDGLOBAL = 5 # load global var
@STLOCAL = 6  # store local var
@STGLOBAL = 7 # store global var
@CALL = 8 # call function
@RET = 9  # return from function with TOS
@JT = 10  # jump if TOS is true, pop TOS
@JF = 11  # jump if TOS is false, pop TOS
@JMP = 12 # unconditional jump
@ADD = 13
@SUB = 14
@MUL = 15
@DIV = 16
@MOD = 17
@DELLOCAL = 18
@DELGLOBAL = 19
@INC = 20  # ++TOS
@DEC = 21  # --TOS
@POS = 22 # +TOS
@NEG = 23 # -TOS
@LSHIFT = 24  # left shift
@URSHIFT = 25 # unsigned right shift
@RSHIFT = 26 # logical right shift
@LTE = 27 # <=
@GTE = 28 # >=
@LT = 29  # <
@GT = 30  # >
@EQ = 31  # ==
@NEQ = 32 # !=
@NOT = 33 # !
@BNEG = 34  # ~
@BAND = 35  # &
@BXOR = 36  # ^
@BOR = 37 # |
@AND = 38 # &&
@OR = 39  # ||
@ROT = 40 # swap TOS and TOS1
@DUP = 41 # duplicate TOS
@TYPEOF = 42 # typeof TOS
@NRET = 43  # return without value
