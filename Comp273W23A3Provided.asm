# TODO: YOUR NAME AND STUDENT NUMBER
# NAME: THEODOR SEMERDZHIEV
# STUDENT NUMBER: 261118892
.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
.float -2.5 2.5 -1.25 1.25  					# good window for viewing Julia sets
#.float -3 2 -1.25 1.25  					# good window for viewing full Mandelbrot set
#.float -0.807298 -0.799298 -0.179996 -0.175996 		# double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093 	# baby Mandelbrot
 
bound: .float 100	# bound for testing for unbounded growth during iteration
maxIter: .word 16	# maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16		# scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0    0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5 
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 

# a demo starting point for iteration tests
z0: .float  0 0

# TODO: define various constants you need in your .data segment here


q1_printComplex1: .asciiz " + "
q1_printComplex2: .asciiz " i"
float_val1: .float 23.232123
float_val2: .float 3.141123
newline_char: .asciiz "\n"
########################################################################################
.text
	
	# TODO: Write your function testing code here

	la $t0, JuliaC1
	l.s $f13 ($t0)
	l.s $f14 4($t0)
	jal printComplex

	
	li $v0 10
	syscall


# TODO: Write your functions to implement various assignment objectives here

#Prints new line character
printNewLine:
	la $a0 newline_char
	li $v0 4
	syscall
	jr $ra

#prints two floats in the following manner: %f1 + %f2 i
printComplex:
	#prints first float
	mov.s $f12 $f13
	li $v0 2
	syscall
	#prints " + "
	li $v0 4
	la $a0 q1_printComplex1
	syscall
	#prints second float
	mov.s $f12 $f14
	li $v0 2
	syscall
	#prints "i"
	li $v0 4
	la $a0 q1_printComplex2
	syscall
	#returns to previous function
	jr $ra


########################################################################################
# Computes a colour corresponding to a given iteration count in $a0
# The colours cycle smoothly through green blue and red, with a speed adjustable 
# by a scale parametre defined in the static .data segment
computeColour:
	la $t0 scale
	lw $t0 ($t0)
	mult $a0 $t0
	mflo $a0
ccLoop:
	slti $t0 $a0 256
	beq $t0 $0 ccSkip1
	li $t1 255
	sub $t1 $t1 $a0
	sll $t1 $t1 8
	add $v0 $t1 $a0
	jr $ra
ccSkip1:
  	slti $t0 $a0 512
	beq $t0 $0 ccSkip2
	addi $v0 $a0 -256
	li $t1 255
	sub $t1 $t1 $v0
	sll $v0 $v0 16
	or $v0 $v0 $t1
	jr $ra
ccSkip2:
	slti $t0 $a0 768
	beq $t0 $0 ccSkip3
	addi $v0 $a0 -512
	li $t1 255
	sub $t1 $t1 $v0
	sll $t1 $t1 16
	sll $v0 $v0 8
	or $v0 $v0 $t1
	jr $ra
ccSkip3:
 	addi $a0 $a0 -768
 	j ccLoop
