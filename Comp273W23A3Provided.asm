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
const_2: .float 2
test_num: .float 1 0
newline_char: .asciiz "\n"
########################################################################################
.text
	
	# TODO: Write your function testing code here

	
	
	la $t0, JuliaC1
	l.s $f12 ($t0)
	l.s $f13 4($t0)
	
	la $t0, JuliaC2
	l.s $f14 ($t0)
	l.s $f15 4($t0)
	
	
	jal multComplex
	
	mov.s $f12 $f0
	mov.s $f13 $f1
	
	jal printComplex
	jal printNewLine
	jal printNewLine
	
	
	## tests iterateVerbose
	li $a0 10
	la $t0, JuliaC1
	l.s $f12 ($t0)
	l.s $f13 4($t0)
	la $t0, test_num
	l.s $f14 ($t0)
	l.s $f15 4($t0)
	
	jal iterateVerbose
	
	#prints out the return value of iterateVerbose
	move $a0 $v0
	li $v0 1
	syscall
	
	li $v0 10
	syscall


# TODO: Write your functions to implement various assignment objectives here

iterateVerbose:
	#adds to the stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	li $t0 0 #set intial value of interation count
	move $t1 $a0 #store are max interation count
	l.s $f10 bound #$f10 will containt the bound
	mov.s $f4 $f12 #stores a into $f4
 	mov.s $f5 $f13 #stores b into $f5
	
	#sets initial parameters for the printComplex function
	mov.s $f12 $f14
	mov.s $f13 $f15
	
	j while_loop

while_loop:
	
	bge $t0 $t1 end_loop # if iteraton count > bound { break; }
	mul.s $f6 $f14 $f14 #computes x0^2 
	mul.s $f7 $f15 $f15 #computes y0^2
	add.s $f8 $f6 $f7 #computes x0^2 + y0^2
	
	c.lt.s $f10 $f8 #if (x0^2 + y0^2 > bound) 
	bc1t end_loop #break
	
	#sets parameters for the printComplex function
	mov.s $f12 $f14 
	mov.s $f13 $f15
	
	jal printComplex
	jal printNewLine
	
	#computes x0^2 - y0^2 + a 
	sub.s $f8 $f6 $f7
	add.s $f8 $f8 $f4
	
	#computes 2 * x0 * y0 + b
	mul.s $f9 $f14 $f15
	l.s $f6 const_2 #loads constant 2
	mul.s $f9 $f9 $f6
	add.s $f9 $f9 $f5
	
	# updates $f14 and $f15 for the next iteration
	mov.s $f14 $f8
	mov.s $f15 $f9
	
	#increment interation count register
	addi $t0 $t0 1
	j while_loop
		
end_loop:  
	#pop stack
	lw $ra 0($sp)
	addi $sp $sp 4	
	#update return register
	move $v0 $t0
	jr $ra



#Computes the multiplication of compelx numbers i.e (a + bi)(c + di)
# arguments a: $f12, b: $f13, c: $f14, d: $f15
multComplex:
	#adds to stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	#computes real number, stores it in the $f0 register
	mul.s $f4 $f12 $f14
	mul.s $f5 $f13 $f15
	sub.s $f0 $f4 $f5
	#computes the imaginary part, stores in the $f1 register
	mul.s $f4 $f12 $f15
	mul.s $f5 $f13 $f14
	add.s $f1 $f4 $f5
	
	#pops stack
	lw $ra 0($sp)
	addi $sp $sp 4
	
	jr $ra
	
	

#Prints new line character
printNewLine:
	#adds to the stack
	addi $sp $sp -4
	sw $ra 0($sp)
	
	#prints \n
	la $a0 newline_char
	li $v0 4
	syscall
	
	#pops the stack
	lw $ra 0($sp)
	addi $sp $sp 4
	#returns to prev function
	jr $ra


#prints two floats in the following manner: %f1 + %f2 i
#arguments are $f12 for real number and $f13 for complex number
printComplex:
	#adds to stack
	addi $sp $sp -4
	sw $ra 0($sp)
	
	#prints first float
	li $v0 2
	syscall
	
	#prints " + "
	li $v0 4
	la $a0 q1_printComplex1
	syscall
	
	#prints second float
	mov.s $f12 $f13
	li $v0 2
	syscall
	
	#prints "i"
	li $v0 4
	la $a0 q1_printComplex2
	syscall
	
	#pops stack
	lw $ra 0($sp)
	addi $sp $sp 4
	
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
