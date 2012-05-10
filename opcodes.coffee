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
@JT = 10  # jump if TOS is true
@JF = 11  # jump if TOS is false
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
@LSHIFT = 22  # left shift
@URSHIFT = 23 # unsigned right shift
@RSHIFT = 24 # logical right shift
@LTE = 25 # <=
@GTE = 26 # >=
@LT = 27  # <
@GT = 28  # >
@EQ = 29  # ==
@NEQ = 30 # !=
@NOT = 31 # !
@BNEG = 32  # ~
@BAND = 33  # &
@BXOR = 34  # ^
@BOR = 35 # |
@AND = 36 # &&
@OR = 37  # ||
@COND = 38 # TOS ? TOS1 : TOS2
@ROT = 39 # swap TOS and TOS1
