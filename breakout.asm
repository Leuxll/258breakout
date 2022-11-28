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
            li $v0, 10
            syscall
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
draw_brick_line:
    # Retrieve the colour
    lw $t0, 0($a1)
    # Get the first 32 bits
    lw $t1, 4($a1)
    # Get the next 32 bits
    lw $t2, 8($a1)

draw_brick_line_loop_1:
	# Grab the LSB
	andi $t3, $t1, 1
	# Draw the brick if the brick is 1
	beqz $t3, skip_brick_line_loop_1_draw
		sw $t0, 0($a0)
	skip_brick_line_loop_1_draw:
	addiu $a0, $a0, 4
	srl $t1, $t1, 1
    bne $t1, $0, draw_brick_line_loop_1
    
draw_brick_line_loop_2:
	# Grab the LSB
	andi $t3, $t2, 1
	# Draw the brick if the brick is 1
	beqz $t3, skip_brick_line_loop_2_draw
		sw $t0, 0($a0)
	skip_brick_line_loop_2_draw:
	addiu $a0, $a0, 4
	srl $t2, $t2, 1
    bne $t2, $0, draw_brick_line_loop_2

	jr $ra


# draw_wall() -> void
#   Draws the walls for the game every single time this function is called.
#
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
    la $a1, WHITE
    li $a2, 10
    jal draw_horizontal_line
    
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


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
    # Save items onto the stack: ra, s0, s1
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)

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
	
	j update_ball_positions
	
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
	
	update_ball_positions:
	
	# Update the x and y postions
	sw $s3, BALL
	sw $s6, BALL + 4
	
	j update_ball_finish
	
	
	update_ball_finish:
	# Retrieve items from stack
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
	jr $ra

	
clear_screen:
	li $t0, ADDR_DSPL # iterator
	
	li $t1, MAX_PIXEL  # max value for iterator
	addi $t1, $t1, ADDR_DSPL
	
	li $t2, BLACK
	
clear_screen_body:
	bge $t0, $t1, clear_screen_return
	sw $t2, 0($t0) # draw the background color to the screen
	
	addi $t0, $t0, 4
	j clear_screen_body

clear_screen_return:
	jr $ra
    

	
