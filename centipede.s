# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# -$s5, $s4 preserved for gun location
# -$s2 preserved for centipede's head
# -$s6 preserved for centipede's lives


.data
displayAddress: .word 0x10008000

.text
Main: 

	lw $t0, displayAddress # $t0 stores the base address for display
	li $t1, 0xff00fc       # $t1 stores mushroom's colour 
	li $t2, 0x00ff00       # $t2 stores centpede's body colour
	li $t3, 0x00a900       # stores centpede's head colour 
	li $t4, 0x0afaff       # $t3 stores gun's colour
	
########################################################################################################################################################################
# Initialize Mushroom's Location

	add $t5, $zero, $zero # $t5 = 0
	li $t6, 20            # $t6 = 20
generate_init_mushrooms: 
	jal get_random_number 	   # stores a random number between 0-960 in $a0 
	sll $a0, $a0, 2    	   # $a0 = $a0 * 4 
	add $a0, $a0, $t0 	   # $a0 = $a0 + $t0  
	sw $t1, 0($a0)    	   # store the mushroom colour in memory at location 0($a0)
	addi $t5, $t5, 1  	   # $t5 += 1 
	bne $t5, $t6, generate_init_mushrooms # if $t5 != 20 than go back to MushroomLoop (i.e continue generating mushrooms at random locations)

######################################################################################################################
# initalize gun on screen
	addi $s5, $t0, 4032  # $s5 preserved for gun part 1/2
 	addi $s4, $t0, 3904 # $s4 preserved for gun part 2/2 
 		
 	
 	sw $t4, 0($s5) #middle location last row store gun blue colour  
 	sw $t4, 0($s4) #middle location one row before last store gun blue colour
 	
######################################################################################################################
# initalize centipede 
 	jal draw_centipede			# Reset centipede
 	
######################################################################################################################
 # GAME LOOP [Note: this section was inspired by the provided doodle sample project]
 
game_loop_main:

	# Get Keyboard Input, move gun accordingly:
		
	lw $t8, 0xffff0000			# Check MMIO location for keypress 
	beq $t8, 1, keyboard_input		# If we have input, jump to handle
	j keyboard_input_done			# else, jump till end

	keyboard_input:
		lw $t8, 0xffff0004		# Read Key value into t8
		beq $t8, 0x6A, keyboard_left	# If `j`, move left
		beq $t8, 0x6B, keyboard_right	# If `k`, move right
    		beq $t8, 0x73, keyboard_restart # If `s`, restart the game
   		beq $t8, 0x78, shot 		# If `x`, shoot a dart from the gun

		j keyboard_input_done		# Otherwise, ignore...

		keyboard_left:
			addi $t9 $t0, 3968 	      #left most corner on line 32
			beq  $s5, $t9, transfer_left  #handling the edge case
			jal draw_gun_left
			j keyboard_input_done	      # done

			transfer_left:			
				j keyboard_input_done # done

		keyboard_right:
			addi $t9 $t0, 4092 	      # rightt most corner on line 32 (bc the index is by the right index of the unit)
			beq  $s5, $t9, transfer_right #handling the edge case
			jal draw_gun_right
			j keyboard_input_done	      # done

			transfer_right:
				j keyboard_input_done #done
				
		shot: 
			jal shoot 
			li $s7, 3
			bne $s6, $s7, keyboard_input_done
			li $s6, 0 
			
			centipede_die: 
			
				li $t1, 0x000000       # $t1 stores the colour black 
				li $t2, 0x00ff00       # $t2 stores centpede's body colour
				
				sw $t1, 0($s2)
				lw $s7, 4($s2) 	       # $s7 has centipede's colour from the right
				li $t9, 9
				add $t8, $s2, $zero
				beq $s7, $t2, die_right
				jal die_left
				
					die_right: 
						beqz $t9, sad_loop #done 
						sw $t1, 4($t8)
						addi $t8, $t8, 4						
						addi $t9, $t9, -1
						j die_right
						
					die_left: 
						beqz $t9, sad_loop #done
						sw $t1, -4($t8)
						addi $t8, $t8, -4						
						addi $t9, $t9, -1
						j die_left

						
						
     j keyboard_input_done #done	

    keyboard_restart:
      jal reset_bg #procedures paints the screen belack
      j Main

    keyboard_input_done:
		# do nothing
    
    	#############################################################################################################
	# Move Centipede:
	# jal draw_flea 
	li $t7, 0x0afaff       # gun's colour 
	lw $s1, 0($s2)
	li $t1, 0xff00fc       # $t1 stores mushroom's colour 
	li $t2, 0x00ff00       # $t2 stores centpede's body colour
	lw $t3, 4($s2)	       # $t3 stores value to the right of centipede's head 
	lw $t4, -4($s2)	       # $t3 stores value to the right of centipede's head 
	right: 
		beq $s1, $t7, sad_loop
		beq $t3, $t2, left	   #checking if centipid is orinated to left direction
		beq $t3, $t1, down_to_left #checking if there is a mushroom in the way
		jal move_right_once
		j game_loop_main 
	 
	 
	left: 
		beq $s1, $t7, sad_loop
		beq $t4, $t1, down_to_right
		jal move_left_once	
		
    j game_loop_main
######################################################################################################################
			
Exit:
li $v0, 10 # terminate the program gracefully
syscall

######################################################################################################################
get_random_number:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 960        # upper bound is 960     
  	syscall
  	jr $ra             # Generate random int (returns in $a0)
######################################################################################################################
# Draw Centipede 

draw_centipede: 
	li $t2, 0x00ff00	
	add $s0, $zero, $zero # $ counter is s0; i = 0 
	li $s1, 9 # $s1 = 9 
DrawBody:
	sll $s2, $s0, 2 
	add $s2, $s2, $t0 
	sw  $t2, 0($s2)
	addi $s0, $s0, 1	
	bne $s0, $s1, DrawBody
	
	addi $s2, $s2, 4
	sw $t3, 0($s2) # head address is saved at $s2
	
	jr $ra 	
######################################################################################################################
 # Draw Gun 
 
 draw_gun_left:
 
 	li $t4, 0x0afaff       			# $t3 stores gun's & gun shots colour
  	li $t2, 0x000000		        # Colour of the background
 	
 	sw $t2, 0($s5) 				# Erasing location of gun 1/2
 	sw $t2, 0($s4)				# Erasing location of gun 2/2
 	 	   	  
 	addi $s5, $s5, -4  # $s5 preserved for gun part 1/2
 	addi $s4, $s4, -4 # $s4 preserved for gun part 2/2 
 		
 	
 	sw $t4, 0($s5) #middle location last row store gun blue colour  
 	sw $t4, 0($s4) #middle location one row before last store gun blue colour 
 	
 	jr $ra 	
######################################################################################################################
 # Draw Gun 
 draw_gun_right:
 
 	li $t4, 0x0afaff       # $t3 stores gun's & gun shots colour
  	li $t2, 0x000000		        # Colour of the background
 	
 	sw $t2, 0($s5) 				# Erasing location of gun 1/2
 	sw $t2, 0($s4)				# Erasing location of gun 2/2
 	 	   	  
 	addi $s5, $s5, 4  # $s5 preserved for gun part 1/2
 	addi $s4, $s4, 4 # $s4 preserved for gun part 2/2 
 		
 	
 	sw $t4, 0($s5) #middle location last row store gun blue colour  
 	sw $t4, 0($s4) #middle location one row before last store gun blue colour 
 	
 	jr $ra 
######################################################################################################################	
# paint background balck [Note: the code here is inspired by the provided doodle code]
reset_bg:	
	addi $t1, $t0, 4096			# Location of last pixel data
	li $t2, 0x000000		        # Colour of the background
	
draw_bg_loop:
	sw $t2, 0($t0)				# Store the colour
	addi $t0, $t0, 4			# Next pixel
	blt $t0, $t1, draw_bg_loop
	jr $ra	 
######################################################################################################################	
# move: move centipede to the appropiate new location 
	li $t2, 0x00ff00       # $t2 stores centpede's body colour
	li $t3, 0x00a900       # stores centpede's head colour 
	li $t4, 0x000000       # $t4 stores the colour black 	
######################################################################################################################
# Move centipede right

move_right_once:

	li $t9, 0x7b
	div $s2,$t9
	mfhi $t1
	beqz $t1, down_to_left


	li $t7, 0x0afaff       # $t7 stores gun's colour
	lw $s1, 4($s2)	       # colour of next square
	beq $t7, $s1, sad_loop
	
	li $t2, 0x00ff00       # $t2 stores centipede's body colour
	li $t3, 0x00a900       # stores centipede's head colour 
	li $t4, 0x000000       # colour black 
	
	sw $t2, 0($s2)	       # turn the head into the body colour 
	sw $t4, -36($s2)       # erase last segment (cover with black)
	addi $s2, $s2, 4
	sw $t3, 0($s2) 	       # add an head one space to the right 
	
	li $v0, 32
	li $a0, 50	       # slows down the centipedes speed 
	syscall
	
	jr $ra  
######################################################################################################################
# Move centipede left

move_left_once:

	li $t9, 0x7f
	div $s2, $t9
	mfhi $t1
	beqz $t1, down_to_left


	li $t7, 0x0afaff       # $t7 stores gun's colour
	lw $s1, -4($s2)	       # colour of next square
	beq $t7, $s1, sad_loop

	li $t2, 0x00ff00       # $t2 stores centipede's body colour
	li $t3, 0x00a900       # stores centipede's head colour 
	li $t4, 0x000000       # colour black 

	sw $t4, 36($s2)        # erase last segment (cover with black)	
	sw $t2, 0($s2)	       # turn the head into the body colour 
	addi $s2, $s2, -4
	sw $t3, 0($s2) 	       # add an head one space to the left 
	
	li $v0, 32
	li $a0, 50	       # slows down the centipedes speed 
	syscall
	
	jr $ra  
######################################################################################################################
# Move centipede down and left 
down_to_left: 
	
	li $t1, 0xff00fc       # $t1 stores mushroom's colour 
	li $t2, 0x00ff00       # $t2 stores centipede's body colour
	li $t3, 0x00a900       # stores centipede's head colour 
	li $t4, 0x000000       # colour black 

	#base case: 
	addi $t6, $s2, -36    # $t6 stores the tale of the centipede 
	sw $t2, 0($s2)	      # erasing the head 
	addi, $s2, $s2, 128   # location of new head
	sw $t3, 0($s2)	      # storing the head
	sw $t4, 0($t6)	      # erasing the tale 

	li $t7, 9
	#loop
centipede_l_loop:	
	beqz $t7, moved_down_l 
	addi $t6, $t6, 4      # the tale of the centipede 
	sw $t2, 0($s2)	      # erasing the head 
	addi $s2, $s2, -4
	sw $t3, 0($s2)
	addi $t7, $t7, -1 
	sw $t4, 0($t6)	      # erasing the tale
	
	li $v0, 32
	li $a0, 100	       # slows down the centipedes speed 
	syscall

	j  centipede_l_loop
	
moved_down_l:	
	jr $ra
	
######################################################################################################################
# Move centipede down and right 
down_to_right: 

	li $t1, 0xff00fc       # $t1 stores mushroom's colour 
	li $t2, 0x00ff00       # $t2 stores centipede's body colour
	li $t3, 0x00a900       # stores centipede's head colour 
	li $t4, 0x000000       # colour black 
	

	#base case: 
	addi $t6, $s2, 36     # $t6 stores the tale of the centipede 
	sw $t2, 0($s2)	      # erasing the head 
	addi, $s2, $s2, 128   # location of new head
	sw $t3, 0($s2)	      # storing the head
	sw $t4, 0($t6)	      # erasing the tale 

	li $t7, 9
	#loop
centipede_r_loop:	
	beqz $t7, moved_down_r 
	addi $t6, $t6, -4      # the tale of the centipede 
	sw $t2, 0($s2)	       # erasing the head 
	addi $s2, $s2, 4
	sw $t3, 0($s2)
	addi $t7, $t7, -1 
	sw $t4, 0($t6)	      # erasing the tale
	
	li $v0, 32
	li $a0, 100	       # slows down the centipedes speed 
	syscall

	j  centipede_r_loop
	
moved_down_r:	
	jr $ra
######################################################################################################################
# shooting: 
shoot: 	
	li $t1, 0xffffff       # $t4 stores gun's shots colour
	li $t2, 0x00ff00       # $t2 stores centpede's body colour
	li $t3, 0x00a900       # stores centpede's head colour 
	li $t4, 0x00ff00       # $t4 stores gun's shots colour

	
	add $t5, $zero, $s4
	li $t1, 31
	
dart:
	beqz $t1, shoot_end
	addi $t5, $t5, -128
	lw $t6, 0($t5)
	sw $t4, 0($t5)
	
	li $v0, 32
	li $a0, 3	       # slows down the centipedes speed 
	syscall

	
	sw $t6, 0($t5)
	beq $t6, $t3, count
	beq $t6, $t2, count
	addi $t1, $t1, -1
	j dart
	
count: 
	addi $s6, $s6, 1
	j shoot_end
	
shoot_end:
	jr $ra		
######################################################################################################################
#draw flea: draws the flea and than restores previous colours unless colour hit was a gun colour (then its game over). 
draw_flea: 
		li $t8, 0x10008900
		li $t1, 0xffc0c0 # $t1 store's the flea colour 
		li $t2, 0x0afaff # $t3 stores gun's colour
		

  		li $v0, 42        # Service 42, random int bounded
  		li $a0, 0         # Select random generator 0
  		li $a1, 512
  		syscall
		
		
		sll $a0, $a0, 2    	   # $a0 = $a0 * 4 
		add $a0, $a0, $t8

		add $t3, $zero, $a0
			
		lw $t4, 0($t3)
		
		beq $t4, $t2, sad_loop
		sw $t1, 0($t3)
		
		li $v0, 32
		li $a0, 450	       # slows down the fleas 
		syscall
	
		sw $t4, 0($t3)

	jr $ra	
######################################################################################################################
#SAD 
sad_loop:

li $v0, 32
li $a0, 20	       # slows down the centipedes speed 
syscall

	li $t1, 0xff0000 # red colour 
	addi $t2, $t0, 1408
	
	# Eye 1
	sw $t1, 176($t2)
	sw $t1, 180($t2)
	sw $t1, 48($t2)
	sw $t1, 52($t2)
	
	# Eye 1
	sw $t1, 196($t2)
	sw $t1, 200($t2)
	sw $t1, 68($t2)
	sw $t1, 72($t2)
	
	# Sad 
	
	sw $t1, 704($t2)
	sw $t1, 708($t2)
	sw $t1, 712($t2)
	sw $t1, 700($t2)
	sw $t1, 696($t2)
	sw $t1, 692($t2)
	sw $t1, 688($t2)
	
	sw $t1, 840($t2)
	sw $t1, 816($t2)	

li $v0, 32
li $a0, 1000	       # slows down the centipedes speed 
syscall


j     keyboard_restart
