# LAST NAME: SEMERDZHIEV
# First name: THEODOR
# Student number: 261118892
.data
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display 
errorBuffer:    .space 0x40000 # space to store match function
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gsLRtest.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128  imageFileName
errorBufferInfo:    .word errorBuffer    512 128  0
templateBufferInfo: .word templateBuffer 8   8    templateFileName

#######################
#my own stuff
newline_char: .asciiz "\n"

.text

#jal matchTemplate
j main

main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplateFast        # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	
##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:	
	
	# TODO: write this function!
	#ADDS TO STACK
	addi $sp $sp -4
	sw $ra, 0($sp)
	
	#iteration numbers
	li $s0 0
	li $s1 0
	li $s2 0
	li $s3 0
	
	#
	
	j loop1
	
###################
	loop1:
		la $t0 imageBufferInfo
		lw $t1 8($t0)
		addi $t1 $t1 -8
		
		bgt $s0 $t1 loop1_exit
		j loop2
	
###############################	
		loop2:
			la $t0 imageBufferInfo
			lw $t1 4($t0)
			addi $t1 $t1 -8
			
			bgt $s1 $t1 loop2_exit
			j loop3
	############################################
	
			loop3:
				bge $s2 7 loop3_exit
				j loop4
		
		##################################################
				loop4:
					bge $s3 7 loop4_exit
					#IMPLEMENT CODE FOR SAD[x,y] += abs( I[x+i][y+j] - T[i][j] );
					
					#loads parameters for getImagePixel(struct imageBufferInfo *image, int row, int column)
					la $a0 imageBufferInfo
					move $a1 $s0
					add $a1 $a1 $s2
					move $a2 $s1
					add $a2 $a2 $s3
					
					jal getPixelAddress # calls function
					
					
					
					#pushes the results to the stack
					addi $sp $sp -4
					sw $v0, 0($sp)
					
					#loads parameters for the getTemplatePixel(struct templateBufferInfo *template, int row, int column)
					la $a0 templateBufferInfo
					move $a1 $s2
					move $a2 $s3
					
					jal getPixelAddress #calls function
					
					
					#gets the result of getImagePixel back from the stack
					lw $t0 0($sp)
					addi $sp $sp 4
						
					#computes the difference 
					
					lbu $t1 ($t0) #loads image intensity into $t1
					lbu $t2 ($v0) #loads template intensity into $t0
					sub $t1 $t1 $t2 #computes difference
					abs $t1 $t1 #takes absolute value
					
					
					#saves the difference to the stack
					addi $sp $sp -4
					sw $t1 0($sp)
					
					#adds the difference to the errorBuffer
					la $a0 errorBufferInfo	
					move $a1 $s0
					move $a2 $s1					
					jal getPixelAddress
					
					#gets the difference from the stack
					lw $t1 0($sp)
					addi $sp $sp 4
					
					#adds the difference to SAD[X][Y]
					lw $t0 0($v0)
					add $t0 $t0 $t1
					sw $t0 0($v0)
					
				
					addi $s3 $s3 1
					j loop4
		
				loop4_exit:
					li $s3 0
					addi $s2 $s2 1
					j loop3
		###################################################
			loop3_exit:
			
				li $s2 0
				addi $s1 $s1 1
				j loop2
	############################################
		loop2_exit:
		
			li $s1 0
			addi $s0 $s0 1
			j loop1
	
#################################
	loop1_exit:
		#POPS STACK
		lw $ra 0($sp)
		addi $sp $sp 4
			
		jr $ra	
	
		
#a0: contains the struct address
#a1: contains the height 
#a2: contains the width 
#v0: return register containing the address of the pixel
getPixelAddress:
	#pushes to stack
	addi $sp $sp -4
	sw $ra, 0($sp)

	lw $t0 4($a0) #loads the width of the Image
	
	#computes 4(width * row + col)
	mult $t0 $a1 # width * row
	mflo $v0 # loads width * row into $v0
	add $v0 $v0 $a2 # width * row + col
	li $t1 4
	mult $v0 $t1 # 4(width * row + col)
	mflo $v0 # loads it into $v0
	
	lw $t0 ($a0) # loads the address of the image
	
	
	add $v0 $v0 $t0 # address + 4(width * row + col)
	
	#pops stack
	lw $ra 0($sp)
	addi $sp $sp 4
	
	jr $ra	

	
##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
	
	# TODO: write this function!
	
	#ADDS TO STACK
	addi $sp $sp -4
	sw $ra, 0($sp)
	
	#iteration numbers
	li $s0 0
	li $s1 0
	li $s2 0
	lw $v1 0($a1) #stores the initial address for the templateBuffer
	j loop1_fast
		
		loop1_fast:
			# if j >= 8 goto loop1_fast_exit
			bge $s0 8 loop1_fast_exit
			
			#What I do is save the address of the start of the template buffer in $v1
			#I then simply add 4 each time I want to access the next pixel
			#The way the values are stored in memory, I can just increment the pointer by 4 8 times
			#which will interate through '1' row of the template
			
			# computes the pixel Intensities
			lbu $t0 0($v1)
			lbu $t1 4($v1)
			lbu $t2 8($v1)
			lbu $t3 12($v1)
			lbu $t4 16($v1)			
			lbu $t5 20($v1)
			lbu $t6 24($v1)						
			lbu $t7 28($v1)
			
			addi $v1 $v1 32
			
			#saves them to the stack
			addi $sp $sp -4
			sw $t0 0($sp)
			addi $sp $sp -4
			sw $t1 0($sp)
			addi $sp $sp -4
			sw $t2 0($sp)
			addi $sp $sp -4
			sw $t3	0($sp)
			addi $sp $sp -4
			sw $t4 0($sp)
			addi $sp $sp -4
			sw $t5 0($sp)
			addi $sp $sp -4
			sw $t6 0($sp)
			addi $sp $sp -4
			sw $t7	0($sp)
			
			lw $s3 0($a2) #stores the initial address of the error buffer
			lw $v0 0($a0) #stores the initial image buffer
			
			#takes into account the +y offset 
			lw $t0 4($a0)
			mult $s0 $t0
			mflo $t0
			li $t1 4
			mult $t0 $t1
			mflo $t0
			add $v0 $v0 $t0
			
			j loop2_fast
			
			loop2_fast:
				#loads height if image
				#la $s3 imageBufferInfo
				lw $t4 8($a0)
				addi $t4 $t4 -8
				# y > height - 8
				bgt $s1 $t4 loop2_fast_exit
				
				j loop3_fast
				
				loop3_fast:
				
					lw $t4 4($a0)
					addi $t4 $t4 -8
					# x > width - 8
					bgt $s2 $t4 loop3_fast_exit	
					
					
					# $t2 is gonna contain the sum of the difference
					# we will add the difference to the errorbuffer at the end
					li $t2 0
					
					lbu $t1 0($v0)
					lw $t7 28($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					
					lbu $t1 4($v0)
					lw $t7 24($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					lbu $t1 8($v0)
					lw $t7 20($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					lbu $t1 12($v0)
					lw $t7 16($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					lbu $t1 16($v0)
					lw $t7 12($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					lbu $t1 20($v0)
					lw $t7 8($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					lbu $t1 24($v0)
					lw $t7 4($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					lbu $t1 28($v0)
					lw $t7 0($sp)
					sub $t1 $t1 $t7
					abs $t1 $t1
					add $t2 $t2 $t1
					
					#this increments our Image pointer
					addi $v0 $v0 4
					
					#adds the difference stored in $t2 to the errorBuffer
					lw $t1 0($s3)
					add $t1 $t1 $t2
					sw $t1 0($s3)
					
					addi $s2 $s2 1 #increments int x (for loop)
					addi $s3 $s3 4 #increments out error buffer pointer
					
					j loop3_fast
				
				loop3_fast_exit:
					
					li $s2 0
					addi $s1 $s1 1
					
					addi $s3 $s3 28
					addi $v0 $v0 28
					
					j loop2_fast
			
			loop2_fast_exit:
				li $s1 0
				addi $s0 $s0 1
				addi $sp $sp 32
				j loop1_fast
		
		loop1_fast_exit:
			lw $ra 0($sp)
			addi $sp $sp 4
			jr $ra	
	

	
	
	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra

##########################################################

#Prints new line character, used for debugging purposes
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
