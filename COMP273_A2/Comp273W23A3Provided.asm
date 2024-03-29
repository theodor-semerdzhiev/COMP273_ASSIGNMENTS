# TODO: YOUR NAME AND STUDENT NUMBER
# NAME: THEODOR SEMERDZHIEV
# STUDENT NUMBER: 261118892
.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
#.float -2.5 2.5 -1.25 1.25  					# good window for viewing Julia sets
.float -3 2 -1.25 1.25  					# good window for viewing full Mandelbrot set
#.float -0.807298 -0.799298 -0.179996 -0.175996 		# double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093 	# baby Mandelbrot
 
bound: .float 100	# bound for testing for unbounded growth during iteration
maxIter: .word 100	# maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16	# scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0    0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5 
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 
JuliaC4:  .float 0.285 0.01

# a demo starting point for iteration tests
z0: .float  0 0

# TODO: define various constants you need in your .data segment here
#DONT TOUCH THIS 

q1_printComplex1: .asciiz " + "
q1_printComplex2: .asciiz " i"
verbose_x: .asciiz "x"
verbose_y: .asciiz "y"
verbose_i_equal: .asciiz " i = "
const_2: .float 2
const_4: .float 4
test_num: .float 1 0
newline_char: .asciiz "\n"
########################################################################################
.text
	
	# TODO: Write your function testing code here
	
	#this is simple tester code that will test the Julia and Mandelbrot tests, MAKE SURE THE PROPER CONSTANTS ARE SETUP IN THE .data SECTION 
	#FOR YOU SEE TO SOMETHING ON THE SCREEN!!!
	#Enjoy :)
	
	la $t0, JuliaC2
	l.s $f12 ($t0)
	l.s $f13 4($t0)
	jal drawMandelbrot
	#jal drawJulia
	li $v0 10
	syscall



# TODO: Write your functions to implement various assignment objectives here
################################################################################

drawMandelbrot:
	#add to stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	la $t1 maxIter
	lw $t5 0($t1) #loads n into $t5
	
	li $s0 0 #row
	li $s1 0 #col
	
	j drawMandelbrot_for_loop_1
	
drawMandelbrot_for_loop_1: 
		
	la $t1 resolution
	lw $t2 0($t1) # stores height in $t2
	lw $t3 4($t1) # stores width in $t3

	
	#checks exit conditions
	beq $s0 $t3 drawMandelbrot_for_loop_1_exit
	bge $s1 $t2 reset$s1_mandelbrot
	
	#saves iteration numbers to stack
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	#sets parameters and runs pixel2ComplexInWindow
	move $a0 $s1
	move $a1 $s0
	jal pixel2ComplexInWindow
	
	#runs iterate, setting all the parameters first
	la $t1 maxIter
	lw $t5 0($t1) #loads n into $t5
	
	#sets parameters and calls iterate
	move $a0 $t5
	mov.s $f12 $f0
	mov.s $f13 $f1
	mov.s $f14 $f0 
	mov.s $f15 $f1	
	jal iterate
	
	la $t2 maxIter
	lw $t5 0($t2) #loads maxiIter
	
	#gets iteration numbers
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	
	#if(maxIter < return value of iterate) goto setColor
	bgt $t5 $v0 setColor_mandelbrot
	
	#otherwise if(maxIter == return value of iterate) (row,column) in mandelbrot set, therefor set color to black
	beq $t5 $v0 setBlack_mandelbrot
	
reset$s1_mandelbrot:
	li $s1 0
	addi $s0 $s0 1
	
	j drawMandelbrot_for_loop_1
	
#sets the color to 0 (black) if number does not diverge	
setBlack_mandelbrot:
	#computes pixel address, stores it in $t1
	la $t1 resolution
	lw $t2 0($t1) # stores height in $t2
	lw $t3 4($t1) # stores width in $t3
	la $t0 bitmapDisplay
	
	#computes memory location for pixel 
	mult $t2 $s0
	mflo $t1
	add $t1 $t1 $s1
	li $t2 4
	mult $t2 $t1
	mflo $t1
	add $t1 $t1 $t0
	
	sw $zero 0($t1)

	#increments iteration number
	addi $s1 $s1 1
	j drawMandelbrot_for_loop_1
	
	
#sets the colot to thee return of computeColor if number does diverge 
setColor_mandelbrot:
	move $a0 $v0
	#saves iteration count registers before calling computeColour
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	jal computeColour
	
	#gets iteration count registers
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	#computes pixel address, stores it in $t1
	la $t1 resolution
	lw $t2 0($t1) # stores height in $t2
	lw $t3 4($t1) # stores width in $t3
	la $t0 bitmapDisplay
	
	#computes pixel address, stores it in $t1
	mult $t2 $s0
	mflo $t1
	add $t1 $t1 $s1
	li $t2 4
	mult $t2 $t1
	mflo $t1
	add $t1 $t1 $t0
	
	sw $v0 0($t1) #stores pixel data at proper address 
	
	#increments iteration number
	addi $s1 $s1 1
	
	j drawMandelbrot_for_loop_1

drawMandelbrot_for_loop_1_exit:
	#pops stack (including the parameters) and returns to previous function
	
	lw $ra 0($sp)
	addi $sp $sp 4	
	jr $ra


################################################################################
drawJulia:
	#add to stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	la $t1 maxIter
	lw $t5 0($t1) #loads n into $t5
	
	li $s0 0 #row
	li $s1 0 #col
	mov.s $f20 $f12 #saves first parameters to $f20 save register
	mov.s $f21 $f13 #saves first parameters to $f21 save register
	

	j drawJulia_for_loop_1
	
drawJulia_for_loop_1: 
		
	la $t1 resolution
	lw $t2 0($t1) # stores height in $t2
	lw $t3 4($t1) # stores width in $t3
	
	#checks exit conditions
	beq $s0 $t3 drawJulia_for_loop_1_exit
	bge $s1 $t2 reset$s1
	
	
	#saves iteration numbers to stack
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	#stores parameters to stack
	addi $sp $sp -4
	swc1 $f20, 0($sp)
	addi $sp $sp -4
	swc1 $f21, 0($sp)
	
	#runs pixel2ComplexInWindow
	move $a0 $s1
	move $a1 $s0
	jal pixel2ComplexInWindow
	
	#gets parameters saved in stack
	lwc1 $f21 0($sp)
	addi $sp $sp 4	
	lwc1 $f20 0($sp)
	addi $sp $sp 4	
	
	#runs iterate, setting all the parameters first
	la $t1 maxIter
	lw $t5 0($t1) #loads n into $t5
	move $a0 $t5
	mov.s $f12 $f20
	mov.s $f13 $f21
	mov.s $f14 $f0
	mov.s $f15 $f1

	#saves parameters back to the stack before calling iterate
	addi $sp $sp -4
	swc1 $f20, 0($sp)
	addi $sp $sp -4
	swc1 $f21, 0($sp)
	
	jal iterate
	
	#loads paramters frim the stack, again
	lwc1 $f21 0($sp)
	addi $sp $sp 4	
	lwc1 $f20 0($sp)
	addi $sp $sp 4	
	
	la $t2 maxIter
	lw $t5 0($t2) #loads maxiIter
	
	#gets iteration numbers
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	#if(maxIter < return value of iterate) goto setColor
	bgt $t5 $v0 setColor
	
	#otherwise if(maxIter == return value of iterate) (row,column) in Julia set, therefor set color to black
	beq $t5 $v0 setBlack
	
reset$s1:
	#sets inner loop iteration number to 0 and increments outer iteration number by 1 before starting inner loop again
	li $s1 0
	addi $s0 $s0 1
	
	j drawJulia_for_loop_1
	
	
#sets the color to 0 (black) if number does not diverge	
setBlack:
	la $t1 resolution
	lw $t2 0($t1) # stores height in $t2
	lw $t3 4($t1) # stores width in $t3
	la $t0 bitmapDisplay 
	
	#computes memory location for pixel 
	mult $t2 $s0
	mflo $t1
	add $t1 $t1 $s1
	li $t2 4
	mult $t2 $t1
	mflo $t1
	add $t1 $t1 $t0
	
	sw $zero 0($t1)

	#increments iteration count
	addi $s1 $s1 1
	
	j drawJulia_for_loop_1
	
	
#sets the colot to thee return of computeColor if number does diverge 
setColor:
	move $a0 $v0
	#saves iteration count registers before calling computeColour
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	jal computeColour
	
	#gets iteration count registers
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	#computes pixel address, stores it in $t1
	la $t1 resolution
	lw $t2 0($t1) # stores height in $t2
	lw $t3 4($t1) # stores width in $t3
	la $t0 bitmapDisplay
	
	#computes pixel address, stores it in $t1
	mult $t2 $s0
	mflo $t1
	add $t1 $t1 $s1
	li $t2 4
	mult $t2 $t1
	mflo $t1
	add $t1 $t1 $t0
	
	sw $v0 0($t1) #stores pixel data at proper address 
	
	#increments iteration count
	addi $s1 $s1 1
	
	j drawJulia_for_loop_1

drawJulia_for_loop_1_exit:
	#pops stack (including the parameters) and returns to previous function
	
	lw $ra 0($sp)
	addi $sp $sp 4	
	jr $ra
	
###########################################################################
pixel2ComplexInWindow:
	#adds to stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	#converts column param to float
	#stores it in the $f4 register
	mtc1 $a0 $f5
	cvt.s.w $f4 $f5
	
	#converts row param to float
	#stores in the $f5 register
	mtc1 $a1 $f6
	cvt.s.w $f5 $f6
	
	la $t0 resolution
	# loads width
	#stores it in the $f6 register
	lw $t1 0($t0) 
	mtc1 $t1 $f7
	cvt.s.w $f6 $f7
	
	# loads height
	# stores in the $f7 register
	lw $t1 4($t0) 
	mtc1 $t1 $f8
	cvt.s.w $f7 $f8
	
	la $t0 windowlrbt
	l.s $f8 0($t0) #loads l
	l.s $f9 4($t0) #loads r
	
	#computes x stores it in $f0 return register
	div.s $f10 $f4 $f6
	sub.s $f11 $f9 $f8
	mul.s $f0 $f10 $f11
	add.s $f0 $f0 $f8
	
	la $t0 windowlrbt
	l.s $f8 8($t0) #loads b
	l.s $f9 12($t0) #loads t
	
	#computes y stores it in the $f1 return register
	div.s $f10 $f5 $f7
	sub.s $f11 $f9 $f8
	mul.s $f1 $f10 $f11
	add.s $f1 $f1 $f8
	
	#pop stack
	lw $ra 0($sp)
	addi $sp $sp 4	
	
	jr $ra

###########################################

# same as iterateVerbose but without printing to the IO ouput
iterate:
	#adds to the stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	li $s0 0 #set intial value of interation count
	move $s1 $a0 #store are max interation count
	
	mov.s $f20 $f12 #stores a into $f4
 	mov.s $f21 $f13 #stores b into $f5
	
	j while_loop_for_iterate

while_loop_for_iterate:
	
	
	bge $s0 $s1 end_loop_for_iterate # if iteraton count > bound { break; }
	
	mul.s $f6 $f14 $f14 #computes x0^2 
	mul.s $f7 $f15 $f15 #computes y0^2
	add.s $f8 $f6 $f7 #computes x0^2 + y0^2
	
	l.s $f10 bound #$f10 will containt the bound
	c.lt.s $f10 $f8 #if (x0^2 + y0^2 > bound) 
	bc1t end_loop_for_iterate #break
	
	#saves a and b parameters to stack
	addi $sp $sp -4
	swc1 $f20, 0($sp)
	addi $sp $sp -4
	swc1 $f21, 0($sp)
	
	#sets the parameters for the 
	move $a0 $s1
	mov.s $f12 $f14
	mov.s $f13 $f15
	mov.s $f14 $f14
	mov.s $f15 $f15
	
	#loads max iteration ($s1) and iteration count ($s0) into stack
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	jal multComplex
	
	#loads max iteration ($s1) and iteration count ($s0) from stack
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	add.s $f0 $f0 $f20
	add.s $f1 $f1 $f21
	
	#loads a and b parameters into $f20 and $f21 from the stack
	lwc1 $f21 0($sp)
	addi $sp $sp 4
	lwc1 $f20 0($sp)
	addi $sp $sp 4
	
	#loads results into $f14 $f15 for next iteration
	mov.s $f14 $f0
	mov.s $f15 $f1
	
	#increment interation count register
	addi $s0 $s0 1
	
	j while_loop_for_iterate
		
end_loop_for_iterate:  
	#pop stack
	lw $ra 0($sp)
	addi $sp $sp 4	
	#update return register
	move $v0 $s0
	jr $ra


###################################################

iterateVerbose:
	#adds to the stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	li $s0 0 #set intial value of interation count
	move $s1 $a0 #store are max interation count
	
	mov.s $f20 $f12 #stores a into $f4
 	mov.s $f21 $f13 #stores b into $f5
	
	j while_loop_for_verbose

while_loop_for_verbose:
	
	
	bge $s0 $s1 end_loop_for_verbose # if iteraton count > bound { break; }
	
	mul.s $f6 $f14 $f14 #computes x0^2 
	mul.s $f7 $f15 $f15 #computes y0^2
	add.s $f8 $f6 $f7 #computes x0^2 + y0^2
	
	l.s $f10 bound #$f10 will containt the bound
	c.lt.s $f10 $f8 #if (x0^2 + y0^2 > bound) 
	bc1t end_loop_for_verbose #break
	
	#saves a and b parameters to stack
	addi $sp $sp -4
	swc1 $f20, 0($sp)
	addi $sp $sp -4
	swc1 $f21, 0($sp)
	
	#sets parameters for the printComplex function
	mov.s $f12 $f14 
	mov.s $f13 $f15
	
	#saves max iteration ($s1) and iteration count ($s0) into stack
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	#prints complex numbers
	move $a0 $s0
	jal print_xy_label
	jal printComplex
	jal printNewLine
	
	#loads max iteration ($s1) and iteration count ($s0) from stack
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	#sets the parameters for the 
	move $a0 $s1
	mov.s $f12 $f14
	mov.s $f13 $f15
	mov.s $f14 $f14
	mov.s $f15 $f15
	
	#loads max iteration ($s1) and iteration count ($s0) into stack
	addi $sp $sp -4
	sw $s0, 0($sp)
	addi $sp $sp -4
	sw $s1, 0($sp)
	
	jal multComplex
	
	#loads max iteration ($s1) and iteration count ($s0) from stack
	lw $s1 0($sp)
	addi $sp $sp 4	
	lw $s0 0($sp)
	addi $sp $sp 4	
	
	add.s $f0 $f0 $f20
	add.s $f1 $f1 $f21
	
	#loads a and b parameters into $f20 and $f21 from the stack
	lwc1 $f21 0($sp)
	addi $sp $sp 4
	lwc1 $f20 0($sp)
	addi $sp $sp 4
	
	#loads results into $f14 $f15 for next iteration
	mov.s $f14 $f0
	mov.s $f15 $f1
	
	#increment interation count register
	addi $s0 $s0 1
	
	j while_loop_for_verbose
		
#exit label for iterateVerbose
end_loop_for_verbose:  
	#pop stack
	lw $ra 0($sp)
	addi $sp $sp 4	
	#update return register
	move $v0 $s0
	jr $ra
	
#this function prints the x[0-9] + y[0-9] i label
print_xy_label:
	#adds to stack
	addi $sp $sp -4
	sw $ra, 0($sp)
	
	#stores input $a0 into temp reg $t0
	move $t0 $a0
	
	#prints "x"
	la $t1 verbose_x
	li $v0 4
	move $a0 $t1
	syscall
	
	#prints iteration number
	li $v0 1
	move $a0 $t0
	syscall
	
	#prints " + "
	la $t1 q1_printComplex1
	li $v0 4
	move $a0 $t1
	syscall
	
	#Prints "y"
	la $t1 verbose_y
	li $v0 4
	move $a0 $t1
	syscall
	
	#prints iteration number
	li $v0 1
	move $a0 $t0
	syscall
	
	#Prints " i = "
	la $t1 verbose_i_equal
	li $v0 4
	move $a0 $t1
	syscall
	
	#pops stack
	lw $ra 0($sp)
	addi $sp $sp 4	
	
	jr $ra

#########################################################################

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
	
###########################################	

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

#############################################

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
 	
 	
 	
 #this assignment was not worth my time and sanity :(
