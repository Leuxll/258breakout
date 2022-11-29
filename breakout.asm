################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Yue Fung, 1007809052
# Student 2: Youssef Soliman, 1007715037
##############################################################################

##############################################################################
# Immutable Data
######################## Bitmap Display Configuration ########################
.eqv UNIT_WIDTH, 8 # - Unit width in pixels
.eqv UNIT_HEIGHT, 8 # - Unit height in pixels
.eqv DISPLAY_WIDTH, 512 # - Display width in pixels
.eqv DISPLAY_HEIGHT, 256 # - Display height in pixels
.eqv COLS, 256 # in bytes (DISPLAY_WIDTH / UNIT_WIDTH) * 4
.eqv ROWS, 128 # in bytes (DISPLAY_HEIGHT / UNIT_HEIGHT) * 4
.eqv MAX_PIXEL, 8192 # in bytes the location of the max pixel
.eqv ADDR_DSPL, 0x10008000 # - Base Address for Display
.eqv ADDR_KEY_DOWN, 0xffff0010 # - Base Address for Keyboard down
.eqv ADDR_KEY_UP, 0xffff0020 # - Base Address for Keyboard up
##############################################################################

.eqv RED, 0xff0000 # bricks
.eqv GREEN, 0x00ff00 # bricks
.eqv BLUE, 0x0000ff # bricks
.eqv WHITE, 0xffffff
.eqv GRAY, 0x808080
.eqv BLACK, 0x0

.eqv PADDLE_COLOR, WHITE
.eqv BALL_COLOR, WHITE
.eqv WALL_COLOR, GRAY
.eqv BACKGROUND_COLOR, BLACK

HEART_BITMAP:
.byte 0x00
.byte 0x66
.byte 0xff
.byte 0xff
.byte 0x7e
.byte 0x3c
.byte 0x18
.byte 0x00

##############################################################################
# Key Mappings
##############################################################################

.eqv VK_LEFT_ARROW, 0x25
.eqv VK_RIGHT_ARROW, 0x27
.eqv VK_Q, 0x51
.eqv VK_SPACE, 0x20

##############################################################################
# Mutable Data
##############################################################################
.data
BALL:
	.word 256 # x in 1/8ths of a unit per cycle
	.word 224 # y in 1/8ths of a unit per cycle
	.byte 0 # vel_x in 1/8ths of a unit per cycle
	.byte 0 # vel_y in 1/8ths of a unit per cycle
	
PADDLE:
	.word 216 # x in 1/8ths of a unit per cycle
	.word 240 # y in 1/8ths of a unit per cycle
	.byte 0 # vel_x in 1/8ths of a unit per cycle
	
GAME_STATE:
	.byte 0x0 # state (0 -> waiting to start; 1 -> playing level; 2 -> game over screen)
	.word 0x0 # score
	
BRICKS_LAYER_1:
	.word BLUE
	.word 0xfffffffe
	.word 0x7fffffff
	
BRICKS_LAYER_2:
	.word RED
	.word 0xfffffffe
	.word 0x7fffffff
	
BRICKS_LAYER_3:
	.word GREEN
	.word 0xfffffffe
	.word 0x7fffffff
##############################################################################
# Code
##############################################################################
.text
.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game, this is going to contain the full milestone one
    jal draw_initial_bricks

	# Enter the game loop
	game_loop:
	
	# 1. Handle keypresses
	jal read_keyboard
	
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	
	jal update_paddle
	jal update_ball
	
	# 3. Draw the screen
	jal clear_screen
	jal draw_walls
    jal draw_bricks
    jal draw_ball
    jal draw_paddle
    
    # Tell the display to update by writing to max + 1 offset
	li $t8, ADDR_DSPL
	li $t9, GRAY
	sw $t9, MAX_PIXEL($t8)
	
	# 4. Sleep for 100 ms
	li $v0, 32
	li $a0, 16
	syscall

    #5. Go back to 1
    j game_loop
    
exit:
	li $v0, 10
    syscall
	
# """
# read_keyboard()
# from https://github.com/hykilpikonna/EMARS#sample
# Listen to keyboard events
# """
read_keyboard:
    
    # Save items onto the stack: ra, s0, s1
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)

    # 1. Check for key down event
    li $s0, ADDR_KEY_DOWN
    lbu $s1, 0($s0)
    beq $s1, 0, no_key_down

    # In a loop, read the keys that are down (pressed)
    check_key_down:
    blez $s1, finish_key_down
        # Move offset to the next half-word
        addi $s0, $s0, 2

        # Read half-word keycode
        lhu $t2, 0($s0)

        # If Q is pressed, quit
        bne $t2, VK_Q, else_2_0
            j exit
        else_2_0:

        # If Space is pressed
        bne $t2, VK_SPACE, else_2_2
       		lb $t0, GAME_STATE
       		# Check that the game is waiting to start
       		bne $t0, 0, else_2_2
        		jal begin_game
        else_2_2:

        # If Left arrow is pressed, set paddle to move left
        bne $t2, VK_LEFT_ARROW, else_2_3
        	li $t3, -8
        	sb $t3, PADDLE + 8
        else_2_3:

        # If Right arrow is pressed, set paddle to move right
        bne $t2, VK_RIGHT_ARROW, else_2_4
        	li $t3, 8
        	sb $t3, PADDLE + 8
        else_2_4:
        
        # Shift to next key
        addi $s1, $s1, -1
    j check_key_down
    finish_key_down:

    # When we're done, write 1 to offset 1 to clear events
    li $s0, ADDR_KEY_DOWN
    li $s1, 1
    sb $s1, 1($s0)

    no_key_down:

    # 2. Check for key up event
    li $s0, ADDR_KEY_UP
    lbu $s1, 0($s0)
    beq $s1, 0, no_key_up

    # In a loop, read the keys that are up (released)
    check_key_up:
    blez $s1, finish_key_up
    	# Move offset to the next half-word
        addi $s0, $s0, 2
        
        # Read half-word keycode
        lhu $t2, 0($s0)
        
        # If Left arrow is released, set paddle to stop
        bne $t2, VK_LEFT_ARROW, else_3_3
        	li $t3, 0
        	sb $t3, PADDLE + 8
        else_3_3:

        # If Right arrow is released, set paddle to stop
        bne $t2, VK_RIGHT_ARROW, else_3_4
        	li $t3, 0
        	sb $t3, PADDLE + 8
        else_3_4:
        
        # Shift to next key
        addi $s1, $s1, -1
    j check_key_up
    finish_key_up:

    # When we're done, write 1 to offset 1 to clear events
    li $s0, ADDR_KEY_UP
    li $s1, 1
    sb $s1, 1($s0)

    no_key_up:

    # Retrieve items from the stack: ra, s0, s1
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra
    
begin_game:
	# Set the y velocity of the ball to -4
	li $t0, -4
	sb $t0, BALL + 9
	
	# Set the y velocity of the ball to the paddles x velocity
	lb $t0, PADDLE + 8
	sra $t0, $t0, 1
	sb $t0, BALL + 8
	
	# Set the game state to 1 (playing level)
	li $t0, 1
	sb $t0, GAME_STATE
	
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
	sll $a0, $a0, 2 # Each pixel is 4 bits, so shift x by 2
	sll $a1, $a1, 8 # Multiply y by the number of columns
	li $v0, ADDR_DSPL
	addu $v0, $a0, $v0
	addu $v0, $a1, $v0
	jr $ra
	
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


# draw_vertical_line(start, colour_address, legnth) -> void
#   Draw a veritcal line with length units vertically along the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of length units

# BODY
draw_vertical_line:
    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_vline_loop:
    slt $t2, $t1, $a2           # i < length ?
    beq $t2, $0, draw_vertical_line_epi  # if not, then done

        sw $a1, 0($a0)          # Paint unit with colour
        addiu $a0, $a0, 256        # Go to next unit

    addiu $t1, $t1, 1            # i = i + 1
    j draw_vline_loop

draw_vertical_line_epi:
	jr $ra
	
	
# draw_brick_line(start, wall_address) -> void
#   Draw a horizontal line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units

# BODY
draw_initial_brick_line:
    # Retrieve the colour
    lw $t0, 0($a1)
    # Set the higher order byte to 1 in order to indicate an active brick
    ori $t0, $t0, 0x1000000
    # Get the first 32 bits
    lw $t1, 4($a1)
    # Get the next 32 bits
    lw $t2, 8($a1)

draw_initial_brick_line_loop_1:
	# Grab the LSB
	andi $t3, $t1, 1
	# Draw the brick if the brick is 1
	beqz $t3, skip_brick_line_loop_1_draw
		sw $t0, 0($a0)
	skip_brick_line_loop_1_draw:
	addiu $a0, $a0, 4
	srl $t1, $t1, 1
    bne $t1, $0, draw_initial_brick_line_loop_1
    
draw_initial_brick_line_loop_2:
	# Grab the LSB
	andi $t3, $t2, 1
	# Draw the brick if the brick is 1
	beqz $t3, skip_initial_brick_line_loop_2_draw
		sw $t0, 0($a0)
	skip_initial_brick_line_loop_2_draw:
	addiu $a0, $a0, 4
	srl $t2, $t2, 1
    bne $t2, $0, draw_initial_brick_line_loop_2

	jr $ra
	
draw_brick_line:
	# Retrieve the colour
    lw $t0, 0($a1)
    
    addiu $t1, $a0, 256 # Max iteration
    
    draw_brick_line_loop:
    beq $t1, $a0, finish_brick_line
    	lw $t2, 0($a0)
    	andi $t2, $t2, 0xFF000000 # Get the higher order byte
    	# Only draw active bricks
    	beqz $t2, skip_brick
    		# Restore the higher order byte
    		or $t0, $t0, $t2 
    		sw $t0, 0($a0)
    	skip_brick:
    	addiu $a0, $a0, 4
    	j draw_brick_line_loop
    
    finish_brick_line:
    jr $ra


# draw_wall() -> void
#   Draws the walls for the game every single time this function is called.
draw_walls:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# BODY
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
    	
    	addi $a0, $v0, 0
    	li $a1, GRAY
    	li $a2, 31
    	jal draw_vertical_line
    	
    	# Left Wall
    	
    	li $a0, 0
    	li $a1, 1
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	li $a1, GRAY
    	li $a2, 31
    	jal draw_vertical_line
	
	#EPILOGUE
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
draw_initial_bricks:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    # Draw all the bricks. There should be at least three rows of bricks and at least three diﬀerent coloured bricks.
    # Top Row
    	li $a0, 0
    	li $a1, 1
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, BRICKS_LAYER_1
    	jal draw_initial_brick_line
    	
    # Middle Row
    	li $a0, 0
    	li $a1, 2
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, BRICKS_LAYER_2
    	jal draw_initial_brick_line
    	
    # Bottom Row
    	li $a0, 0
    	li $a1, 3
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, BRICKS_LAYER_3
    	jal draw_initial_brick_line
    	
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

draw_bricks:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    # Draw all the bricks. There should be at least three rows of bricks and at least three diﬀerent coloured bricks.
    # Top Row
    	li $a0, 0
    	li $a1, 1
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, BRICKS_LAYER_1
    	jal draw_brick_line
    	
    # Middle Row
    	li $a0, 0
    	li $a1, 2
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, BRICKS_LAYER_2
    	jal draw_brick_line
    	
    # Bottom Row
    	li $a0, 0
    	li $a1, 3
    	jal get_location_address
    	
    	addi $a0, $v0, 0
    	la $a1, BRICKS_LAYER_3
    	jal draw_brick_line
    	
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

draw_paddle:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
    # Drawing the paddle
    lw $a0, PADDLE
    sra $a0, $a0, 3
    lw $a1, PADDLE + 4
    sra $a1, $a1, 3
    jal get_location_address
        
    addi $a0, $v0, 0
    li $a1, WHITE
    li $a2, 10
    jal draw_horizontal_line
    
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

	#EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# draw_ball() -> void
#   Draws the ball every single time this function is called.
draw_ball:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
    # Draw the ball
    lw $a0, BALL
    sra $a0, $a0, 3
    lw $a1, BALL + 4
    sra $a1, $a1, 3
    jal get_location_address
    	
    addi $a0, $v0, 0
    la $a1, WHITE
    li $a2, 1
    jal draw_horizontal_line
    
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
update_paddle:
    lb $t0, PADDLE + 8
	lw $t1, PADDLE
	add $t0, $t0, $t1
	
    # If the paddle is going to go out of bounds, then do not shift the paddle.
    slt $t2, $0, $t0 
    slti $t3, $t0, 432
    and $t2, $t2, $t3
    beqz  $t2, skip_paddle_update
    
		# Shift the paddle
		sw $t0, PADDLE
		j end_update_padle
	skip_paddle_update:
	
	# Set the speed to 0
	sb $0, PADDLE + 8
	
	end_update_padle:
	jr $ra
	
update_ball:
    # Save items onto the stack
    addi $sp, $sp, -32
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $ra, 28($sp)

	lb $t0, GAME_STATE
	bnez $t0, ball_unpaused_game_state
	
		# Move the ball with the paddle if game state is 0
		lb $t0, PADDLE + 8
		lw $t1, BALL
		add $t0, $t0, $t1
		sw $t0, BALL
	
	j update_ball_finish
	
	ball_unpaused_game_state:
	# Load the x velocity
	lb $s0, BALL + 8
	# Load the x position
	lw $s1, BALL
	add $s3, $s0, $s1
	
	# Load the y velocity
	lb $s4, BALL + 9
	# Load the y position
	lw $s5, BALL + 4
	add $s6, $s4, $s5
	
	# Check bounds
	
	# if ball.x <= 4 * 1 or ball.x >= 4 * 126, flip the x velocity
	sle $t0, $s3, 4
	sge $t1, $s3, 504
	or $t0, $t0, $t1
	bnez $t0, bounce_ball_x
	
	# if ball.y <= 4 * 1, flip the y velocity
	sle $t0, $s6, 4
	bnez $t0, bounce_ball_y
	
	# if ball.y > 4 * 64, end the game
	sge $t0, $s6, 260
	bnez $t0, exit
	
	# if ball.y == paddle.y and paddle.x <= ball.x <= paddle.x + 10 units, flip the y velocity
		# paddle.y
		lw $t0, PADDLE + 4
		# paddle.x
		lw $t1, PADDLE
		# paddle.x + 10 units
		addi $t2, $t1, 80 
	
		# ball.y == paddle.y
		seq $t0, $t0, $s6
		
		# paddle.x <= ball.x
		sle $t1, $t1, $s3
		
		# ball.x <= paddle.x + 10 units
		sle $t2, $s3, $t2
		
		and $t1, $t1, $t2
		and $t0, $t0, $t1
	bnez $t0, bounce_ball_y
	
	# if ball.x and ball.y == an active brick
		srl $a0, $s3, 3
		srl $a1, $s6, 3
    	jal get_location_address
    	lw $t0, 0($v0)
		andi $t1, $t0, 0xFF000000 # Grab the high byte
		beqz $t1, update_ball_positions # Skip if the position doesn't contain a brick
			# Break the brick
			andi $t0, $t0, 0xFFFFFF # Grab the bottom 3 bytes
			sw $t0, 0($v0)
			
			#if ball.oldx / 8 == ball.x / 8 (ball is attacking from x direction), flip x velocity
			srl $t0, $s1, 3
			srl $t1, $s3, 3
			beq $t0, $t1, bounce_ball_x
			
			#if ball.oldy / 8 == ball.y / 8 (ball is attacking from y direction), flip y velocity
			srl $t0, $s5, 3
			srl $t1, $s6, 3
			beq $t0, $t1, bounce_ball_y
			
			# else, flip both x and y velocity
			j bounce_ball_both
	
	bounce_ball_x:
		# Make x velocity negative
		sub $s0, $0, $s0
		sb $s0, BALL + 8
		add $s3, $s0, $s1
	j update_ball_positions
	
	bounce_ball_y:
		# Make y velocity negative
		sub $s4, $0, $s4
		sb $s4, BALL + 9
		add $s6, $s4, $s5
	j update_ball_positions
	
	bounce_ball_both:
		# Make x velocity negative
		sub $s0, $0, $s0
		sb $s0, BALL + 8
		add $s3, $s0, $s1
		# Make y velocity negative
		sub $s4, $0, $s4
		sb $s4, BALL + 9
		add $s6, $s4, $s5
	j update_ball_positions
	
	update_ball_positions:
	
	# Update the x and y postions
	sw $s3, BALL
	sw $s6, BALL + 4
	
	j update_ball_finish
	
	
	update_ball_finish:
	# Retrieve items from stack
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 28
	jr $ra

	#EPILOGUE
	lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# shift_paddle(x, curr_x) -> void
#   Paddle shifts from curr_x by x units
#	If x is positive, then the paddle shifts right
#	If x is negative, then the paddle shifts left.
shift_paddle:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# BODY
	# If x is positive, then the paddle shifts right
	# If x is negative, then the paddle shifts left.
	# If x is 0, then the paddle does not shift.
	add $a0, $a0, $a1
	# If the paddle is going to go out of bounds, then do not shift the paddle.
	slt $t0, $0, $a0 
	slti $t1, $a0, 53
	and $t0, $t0, $t1
	beq $t0, $0, noJump
	
clear_screen:
	li $t0, ADDR_DSPL # iterator
	
	li $t1, MAX_PIXEL  # max value for iterator
	addi $t1, $t1, ADDR_DSPL
	
	li $t2, BLACK
	
clear_screen_body:
	bge $t0, $t1, clear_screen_return
	lw $t3, 0($t0)
	andi $t3, $t3, 0xFF000000 # Get the higher order byte
	or $t3, $t3, $t2 # Merge the higher order byte with the background color
	sw $t3, 0($t0) # Draw the background color to the screen
	
	addi $t0, $t0, 4
	j clear_screen_body

clear_screen_return:
	jr $ra
    

	#EPILOGUE
	lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# shift_paddle(x, curr_x) -> void
#   Paddle shifts from curr_x by x units
#	If x is positive, then the paddle shifts right
#	If x is negative, then the paddle shifts left.
shift_paddle:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# BODY
	# If x is positive, then the paddle shifts right
	# If x is negative, then the paddle shifts left.
	# If x is 0, then the paddle does not shift.
	add $a0, $a0, $a1
	# If the paddle is going to go out of bounds, then do not shift the paddle.
	slt $t0, $0, $a0 
	slti $t1, $a0, 53
	and $t0, $t0, $t1
	beq $t0, $0, noJump
	
    li $a1, 30
    jal get_location_address

	addi $a0, $v0, 0
    li $a1, WHITE
    li $a2, 10
    jal draw_horizontal_line

	# EPILOGUE
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

noJump:

# detect_game_over(y) -> void
#   Detects if the game is over or not.
#	If the ball is at the bottom of the screen, then the game is over.
#	If the ball is not at the bottom of the screen, then loop back to game loop
	beq $a0, $0, game_over
	j game_loop

# game_over() -> void
#   Displays the game over message and exits the game.
game_over:
	# Exit the game
	li $v0, 10
	syscall


#draw_hearts(start, bitmap_address) -> void
#   Draws the hearts for the game every single time this function is called.
draw_heart:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# BODY
	# Draw the hearts
	# Retrieve the address of the first 8 bits
	lw $t0, 0($a1)

	# loop_through_bytes(start, byte) -> void
	#   Loops through the bytes of the bitmap and draws the pixels.
	loop_through_a_byte:
		li $t1, RED
		# Getting the first bit of the byte
		lw $t2, 0($a1)
		# Draw the brick if the brick is 1
		beqz $t2, skip_brick_line_loop_1_draw
			sw $t1, 0($a0)
		skip_brick_line_loop_1_draw:
		addiu $a0, $a0, 4
		srl $t2, $t2, 2 # Shift the byte to the right by 2
		bne $t2, $0, draw_brick_line_loop_1

	srl $t0, $t0, 1 # Shift the byte to the right by 1
	bne $t0, $0, loop_through_a_byte

		jr $ra