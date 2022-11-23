################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Yue Fung, 1007809052
# Student 2: Youssef Soliman, 1007715037
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    512
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
.eqv ADDR_DSPL, 0x10008000
# The address of the keyboard. Don't forget to connect it!
.eqv ADDR_KBRD, 0xffff0000

.eqv RED, 0xff0000 # bricks
.eqv GREEN, 0x00ff00 # bricks
.eqv BLUE, 0x0000ff # bricks
.eqv WHITE, 0xffffff # paddle and ball
.eqv GRAY, 0x808080 # walls
	

##############################################################################
# Mutable Data
##############################################################################
	
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game, this is going to contain the full milestone one
    
    # Drawing the walls
    	# The Upper Wall
    	li $a0, ADDR_DSPL
    	li $a1, GRAY
    	li $a2, 64
    	jal draw_horizontal_line
    	
    	# Right Wall
    	
    	li $a0, 63
    	li $a1, 1
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	li $a1, GRAY
    	li $a2, 31
    	jal draw_veritcal_line
    	
    	# Left Wall
    	
    	li $a0, 0
    	li $a1, 1
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	li $a1, GRAY
    	li $a2, 31
    	jal draw_veritcal_line
    
    # Draw all the bricks. There should be at least three rows of bricks and at least three diﬀerent coloured bricks.
    	# Top Row
    	li $a0, 1
    	li $a1, 1
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	li $a1, RED
    	li $a2, 62
    	jal draw_horizontal_line
    	
    	# Middle Row
    	li $a0, 1
    	li $a1, 2
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	li $a1, GREEN
    	li $a2, 62
    	jal draw_horizontal_line
    	
    	# Bottom Row
    	li $a0, 1
    	li $a1, 3
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	li $a1, BLUE
    	li $a2, 62
    	jal draw_horizontal_line


    # Drawing the paddle
        li $a0, 27
        li $a1, 30
        jal get_location_address
        
        addi $a0, $v0, 0
        la $a1, WHITE
        li $a2, 10
        jal draw_horizontal_line
    
    
    # Draw the ball (at some inital location)
    	li $a0, 32
    	li $a1, 28
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, WHITE
    	li $a2, 1
    	jal draw_horizontal_line
    	
    	
game_loop:
# 1a. Check if key has been pressed
	
	li $t0, ADDR_KBRD
	lw $t1, 0($t0)
	beq $t1, 1, keyboard_input
	j game_loop
	
# If a key on the keyboard has been pressed then the location would become 1
# We then want to load the second word from the keyboard to see which key was actually pressed, then branch accordingly
keyboard_input:                 # A key is pressed
    	lw $a0, 4($t0)        	# Load second word from keyboard
    	beq $a0, 0x61, respond_to_a	# Check if the key a was pressed
    	beq $a0, 0x64, respond_to_d 	# Check if the key d was pressed

    	li $v0, 1                       # ask system to print $a0
    	syscall

    	j game_loop


respond_to_a:
	li $v0, 10                      # Quit gracefully
	syscall
	
respond_to_d:
	li $v0, 10                      # Quit gracefully
	syscall
	
	
# 1b. Check which key has been pressed
# 2a. Check for collisions
# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop
    	
	
    exit:
	li $v0, 10
	syscall

# draw_horizontal_line(start, colour_address, width) -> void
#   Draw a horizontal line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units

# BODY
draw_horizontal_line:
    # Retrieve the colour
    add $t0, $0, $a1

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_hline_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_horizontal_line_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4        # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    j draw_hline_loop

draw_horizontal_line_epi:
	jr $ra


# draw_veritcal_line(start, colour_address, legnth) -> void
#   Draw a veritcal line with length units vertically along the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of length units

# BODY
draw_veritcal_line:
    # Retrieve the colour
    add $t0, $0, $a1

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_vline_loop:
    slt $t2, $t1, $a2           # i < length ?
    beq $t2, $0, draw_vertical_line_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 256        # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    j draw_vline_loop

draw_vertical_line_epi:
	jr $ra


# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 63, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
	# BODY
	# x_bytes = x * 4, we know that each unit is stored in 4 bytes
	sll $a0, $a0, 2 # shifting logical left by 2 bits so that it multiplies by 2^2 = 4
	# y_bytes = y * 256, we know that each row has 64 units and each one being 4 bytes, therefore 256
	sll $a1, $a1, 8 # shifting logical left by 2 bits so that it multiplies by 2^8 = 4
	# location_address = base_address + x_bytes + y_bytes
	li $v0, ADDR_DSPL
	add $v0, $a0, $v0
	# return location_address
	add $v0, $a1, $v0
	
	#EPILOGUE
	jr $ra
    

	
