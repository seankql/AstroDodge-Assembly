#####################################################################
#
# CSCB58 Summer 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Sean Lau Kuang Qi, 1006463464, laukuang
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8 
# -Unit height in pixels: 8 
# -Display width in pixels: 512
# -Display height in pixels: 256 
# -Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. ii, increase in difficulty as game progresses, asteroids move faster.
# 2. iii, scoring system, after each time you dodge a line of asteroids, score plus 1.
# 3. iv, added pickups that the ship can pick up, if the ship picks up the green sqaure, plus 1 health (max of 10),
#	 if the ship picks up the red square, it destroys all asteroids and sends them back to the right 
#	 side of the screen.
#
# Link to video demonstration for final submission:
# -(insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# -yes / no/ yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# -	The game level increases (up to level) as you get more points,
# 	(Score < 10: Level 1, 9 < Score < 20: Level 2, Score > 19, Level 3),
#	as game level increases, speed of the asteroids also increases.
 
#####################################################################
.eqv 	DISPLAY_ADDRESS 0x10008000
.eqv	ROW_INCREMENT 256
.eqv 	WHITE 0xFFFFFF
.eqv 	BLACK 0x000000
.eqv 	BLUE1 0XB2EFFE
.eqv 	BLUE2 0X74E2FC
.eqv 	BLUE3 0X2AD1FC
.eqv 	BLUE4 0X10748F
.eqv 	BLUE5 0X58DEFC
.eqv 	PURPLE 0XFA74F2
.eqv 	GRAY1 0X90A4AE
.eqv 	GRAY2 0X78909C
.eqv 	GRAY3 0X546E7A
.eqv 	GRAY4 0X455A64
.eqv 	GREEN 0X2EFD39
.eqv 	RED 0XEA0C33
.eqv	HEALTH 5

.data
	SHIP_COORDS: .word  0, 16, 4096
	PICKUP_COORDS: .word  32, 17, 4480
	ASTEROID_COORDS: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	ASTEROID_SPEED: .word 25 

.text
.globl main
main:
	#set pickup type
	#if $s6 = 0, pickup is health, if $s6 = 1, pickup is destroy asteroids
	la $s6, 0 				
	#set rounds to 0	
	#score: $s4 $s5
	la $s4, 0				#let $s4 = first rounds, which is 0 at the beginning
	la $s5, 0				#let $s5 = second rounds, which is 0 at the beginning
	#set hp to full health
	la $s3, HEALTH				#let $s3 = HEALTH 
	#draw hp words
	jal draw_hp_words
	#erase if there is ship
	jal erase_ship
	#reset ship start coords
	la $t2, SHIP_COORDS
	addi $t6, $zero, 0
	sw $t6, 0($t2)
	addi $t6, $zero, 16
	sw $t6, 4($t2)
	addi $t6, $zero, 4096
	sw $t6, 8($t2)
	#erase asteroid
	jal erase_asteroid
	#reset asteroid coords
	la $t2, ASTEROID_COORDS
	sw $t6, 0($t2)
	sw $t6, 4($t2)
	sw $t6, 8($t2)
	sw $t6, 12($t2)
	sw $t6, 16($t2)
	sw $t6, 20($t2)
	sw $t6, 24($t2)
	sw $t6, 28($t2)
	sw $t6, 32($t2)
	sw $t6, 36($t2)
	sw $t6, 40($t2)
	sw $t6, 44($t2)
	sw $t6, 48($t2)
	sw $t6, 52($t2)
	sw $t6, 56($t2)
	#draw ship at start coords
	jal draw_ship
	#set asteroids at random y coords at right side of screen
	jal set_asteroid
	#begin loop
	j start_loop

start_loop:
	li $t9, 0xffff0000 
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
	jal draw_pickup
	jal collision_pickup
	jal draw_hp_words
	jal collision
	jal game_over_check
	jal draw_hp_bar
	jal redraw_asteroid
	j asteroid_loop
	
asteroid_loop:
	#increase speed the higher your score is
	#when 0-9, pause time is 30 (level 1)
	#when 10-19, pause time is 20 (level 2)
	#when >= 20, pause time is 10 (level 3)
	la $t0, ASTEROID_SPEED
	beq $s4, 0, level_1
	beq $s4, 1, level_2
	bge $s4, 2, level_3
	j asteroid_loop1
level_1:
	addi $t1, $zero, 30
	sw $t1, ($t0)
	j asteroid_loop1
level_2:
	addi $t1, $zero, 20
	sw $t1, ($t0)
	j asteroid_loop1
level_3:
	addi $t1, $zero, 10
	sw $t1, ($t0)
	j asteroid_loop1
asteroid_loop1:
	#pause
	li $v0, 32
	lw $a0, ASTEROID_SPEED			
	syscall
	jal draw_ship
	j start_loop

######################################   KEYPRESS HAPPENED   ######################################
keypress_happened:
	li $t9, 0xffff0000
	lw $t1, 4($t9) 	
	li $t0, DISPLAY_ADDRESS
	la $t2, SHIP_COORDS
	lw $t3, 0($t2)
	lw $t4, 4($t2)
	lw $t5, 8($t2)	
	beq $t1, 0x64, respond_to_d	#if d is pressed move right 1 pixel
	beq $t1, 0x61, respond_to_a	#if a is pressed move left 1 pixel
	beq $t1, 0x77, respond_to_w	#if w is pressed move up 1 pixel
	beq $t1, 0x73, respond_to_s	#if s is pressed move down 1 pixel
	beq $t1, 0x70, main		#if p is pressed, restart game
	j start_loop
######################################   MOVE RIGHT   ######################################
respond_to_d:
	beq $t3, 60, start_loop
	addi $t3, $t3, 1
	sw $t3, 0($t2)
	li $a0, 4
	j redraw_ship
######################################   MOVE LEFT   ######################################
respond_to_a:
	beq $t3, 0, start_loop
	addi $t3, $t3, -1
	sw $t3, 0($t2)
	li $a0, -4
	j redraw_ship
######################################   MOVE UP   ######################################
respond_to_w:
	beq $t4, 0, start_loop
	addi $t4, $t4, -1
	sw $t4, 4($t2)
	li $a0, -256
	j redraw_ship
######################################   MOVE DOWN   ######################################
respond_to_s:
	beq $t4, 24, start_loop
	addi $t4, $t4, 1
	sw $t4, 4($t2)
	li $a0, 256
	j redraw_ship
######################################   DRAW SHIP   ######################################
draw_ship:
	li $t0, DISPLAY_ADDRESS
	li $t1, BLUE1
	li $t2, BLUE2
	li $t3, BLUE3
	li $t4, BLUE4
	li $t5, BLUE5
	li $t6, PURPLE
	li $t7, BLACK
	la $t9, SHIP_COORDS
	lw $t8, 8($t9)
	#draw ship
	add $t0, $t0, $t8
	sw $t6, 0($t0)
	sw $t5, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	addi $t0, $t0, ROW_INCREMENT	 #shift down a row
	sw $t4, 0($t0)
	sw $t3, 4($t0)
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, ROW_INCREMENT	 #shift down a row
	sw $t6, 0($t0)
	sw $t5, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	jr $ra	
######################################   ERASE SHIP   ######################################
erase_ship:
	li $t0, DISPLAY_ADDRESS
	li $t1, BLACK
	la $t9, SHIP_COORDS
	lw $t8, 8($t9)
	#draw black (erase ship)
	add $t0, $t0, $t8
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, ROW_INCREMENT	 #shift down a row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, ROW_INCREMENT	 #shift down a row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	jr $ra	
######################################   REDRAW SHIP   ######################################
redraw_ship:
	jal erase_ship
	add $t8, $t8, $a0
	sw $t8, 8($t9)
	jal draw_ship
	j start_loop
######################################   DRAW INITIAL ASTEROID   ######################################
set_asteroid:
	addi $t4, $zero, 0		#i > 0
	addi $t5, $zero, 5		#i = 5, 5 asteroids max, could be 1 if all asteroids have same random number
	la $t9, ASTEROID_COORDS	
	
draw_asteroid:
	# Random Number Generator
	li $v0, 42         		# Service 42, random int range
	li $a0, 0         		# Select random generator 0
	li $a1, 25         		# Select upper bound of random number
	syscall    			# Generate random int (returns in $a0)

	add $t7, $zero, $a0 		#get y coord of asteroid
	sw $t7, 4($t9)			#store y coord in y coord in asteroid array
	addi $t6, $zero, 62		#set temp value to right of screen
	sw $t6, 0($t9)			#store that value in x coord of asteroid array
	addi $t6, $zero, ROW_INCREMENT	#set temp value to row_increment		
	mult $t7, $t6			#mult the row num with the row_increment
	mflo $t7				#store that value in temp var
	addi $t7, $t7, 248		#add 248 to the value to move it to the right of the screen
	sw $t7, 8($t9)			#store that value in address of asteroid array
	j for_redraw_asteroid1
for_redraw_asteroid:
	addi $t4, $zero, 0		#i > 0
	addi $t5, $zero, 5		#i = 5, 5 asteroids max, could be 1 if all asteroids have same random number
	la $t9, ASTEROID_COORDS	
for_redraw_asteroid1:
	li $t0, DISPLAY_ADDRESS
	li $t1, GRAY1
	li $t2, GRAY2
	li $t3, GRAY3
	lw $t8, 8($t9)
	#draw asteroid
	beq $t4, $t5, stop_asteroid_draw
	add $t0, $t0, $t8
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, ROW_INCREMENT
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	#go to next three elements in asteroid_coords array (next asteroid)
	addi $t9, $t9, 12
	#i++
	addi $t4, $t4, 1
	#if i is not 5, continue drawing asteroids
	beq $a0, 1, for_redraw_asteroid1
	j draw_asteroid
stop_asteroid_draw:
	jr $ra
######################################   ERASE ASTEROID   ######################################
erase_asteroid:
	li $t1, BLACK
	la $t9, ASTEROID_COORDS
	addi $t4, $zero, 0		#i = 0
	addi $t5, $zero, 5		#i < 5
loop_erase_asteroid:
	beq $t4, $t5, stop_asteroid_erase
	li $t0, DISPLAY_ADDRESS
	lw $t8, 8($t9)
	add $t0, $t0, $t8 
	#erase
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, ROW_INCREMENT
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	#go to next three elements in asteroid_coords array (next asteroid)
	addi $t9, $t9, 12
	#i++
	addi $t4, $t4, 1
	j loop_erase_asteroid
stop_asteroid_erase:
	jr $ra
######################################   REDRAW ASTEROID   ######################################
redraw_asteroid:
	move $s0, $ra
	jal erase_asteroid
	addi $t4, $zero, 0
	addi $t5, $zero, 5
	la $t9, ASTEROID_COORDS
loop_redraw_asteroid:
	beq $t4, $t5, finish_asteroid_redraw1
	lw $t7, 0($t9) 
	lw $t8, 8($t9) 
	beq $t7, 0, finish_asteroid_redraw
	addi $t7, $t7, -1
	sw $t7, 0($t9)
	addi $t8, $t8, -4
	sw $t8, 8($t9)
	#go to next three elements in asteroid_coords array (next asteroid)
	addi $t9, $t9, 12
	#i++
	addi $t4, $t4, 1
	j loop_redraw_asteroid
finish_asteroid_redraw:
	#draw asteroid from right since it reached the left of the screen
	#increment score
	jal set_asteroid
	beq $s5, 9, add_first_dig
	addi $s5, $s5, 1
	j finish_asteroid_redraw1
add_first_dig:
	addi $s4, $s4, 1
	addi $s5, $zero, 0

finish_asteroid_redraw1:
	#asteroid has not reached the left of the screen
	#just move draw asteroid with updated coords
	li $a0, 1
	jal for_redraw_asteroid
	jr $s0
######################################   COLLISION DETECTION   ######################################
collision:
	move $s0, $ra
	addi $t1, $zero, 0
	addi $t2, $zero, 5
	la $t8, ASTEROID_COORDS
x_loop:
	beq $t1, $t2, return
	la $t9, SHIP_COORDS
	lw $t6, 0($t9)
	lw $t7, 4($t9)
	lw $t4, 0($t8)
	beq $t4, $t6, check_y
	addi $t4, $t4, 1
	beq $t4, $t6, check_y
	lw $t4, 0($t8)
	addi $t4, $t4, -1
	beq $t4, $t6, check_y
	lw $t4, 0($t8)
	addi $t4, $t4, -2
	beq $t4, $t6, check_y
	lw $t4, 0($t8)
	addi $t4, $t4, -3
	beq $t4, $t6, check_y
	addi $t1, $t1, 1
	addi $t8, $t8, 12
	j x_loop
check_y:
	addi $t1, $zero, 0
	addi $t2, $zero, 5
	la $t8, ASTEROID_COORDS
y_loop:
	beq $t1, $t2, return
	la $t9, SHIP_COORDS
	
	lw $t5, 4($t8)
	beq $t5, $t7, lose_health
	lw $t5, 4($t8)
	addi $t5, $t5, 1
	beq $t5, $t7, lose_health
	lw $t5, 4($t8)
	addi $t5, $t5, -1
	beq $t5, $t7, lose_health
	lw $t5, 4($t8)
	addi $t5, $t5, -2
	beq $t5, $t7, lose_health
	addi $t1, $t1, 1
	addi $t8, $t8, 12
	j y_loop
lose_health:
	addi $s3, $s3, -1
	jal erase_hp_bar
	jal erase_asteroid
	jal set_asteroid
return:
	jr $s0
######################################   GAME OVER CHECK  ######################################
game_over_check:
	beq $s3, 0, game_over_screen
	jr $ra
######################################   GAME OVER   ######################################
game_over_screen:
	#reset everything
	addi $s3, $zero, HEALTH
	jal erase_ship
	jal erase_asteroid
	jal erase_hp_words
	jal erase_pickup
	
	la $t2, SHIP_COORDS
	addi $t6, $zero, 0
	sw $t6, 0($t2)
	addi $t6, $zero, 16
	sw $t6, 4($t2)
	addi $t6, $zero, 4096
	sw $t6, 8($t2)
	#draw game over screen
	li $t0, DISPLAY_ADDRESS
	li $t1, WHITE
	#G
	sw $t1, 1112($t0)
	sw $t1, 1116($t0)
	sw $t1, 1120($t0)
	sw $t1, 1124($t0)
	sw $t1, 1368($t0)
	sw $t1, 1624($t0)
	sw $t1, 1632($t0)
	sw $t1, 1636($t0)
	sw $t1, 1880($t0)
	sw $t1, 1892($t0)
	sw $t1, 2136($t0)
	sw $t1, 2140($t0)
	sw $t1, 2144($t0)
	sw $t1, 2148($t0)
	#A
	sw $t1, 1132($t0)
	sw $t1, 1136($t0)
	sw $t1, 1140($t0)
	sw $t1, 1144($t0)
	sw $t1, 1388($t0)
	sw $t1, 1400($t0)
	sw $t1, 1644($t0)
	sw $t1, 1648($t0)
	sw $t1, 1652($t0)
	sw $t1, 1656($t0)
	sw $t1, 1900($t0)
	sw $t1, 1912($t0)
	sw $t1, 2156($t0)
	sw $t1, 2168($t0)
	#M
	sw $t1, 1152($t0)
	sw $t1, 1156($t0)
	sw $t1, 1160($t0)
	sw $t1, 1164($t0)
	sw $t1, 1168($t0)
	sw $t1, 1408($t0)
	sw $t1, 1416($t0)
	sw $t1, 1424($t0)
	sw $t1, 1664($t0)
	sw $t1, 1672($t0)
	sw $t1, 1680($t0)
	sw $t1, 1920($t0)
	sw $t1, 1928($t0)
	sw $t1, 1936($t0)
	sw $t1, 2176($t0)
	sw $t1, 2184($t0)
	sw $t1, 2192($t0)
	#E
	sw $t1, 1176($t0)
	sw $t1, 1180($t0)
	sw $t1, 1184($t0)
	sw $t1, 1188($t0)
	sw $t1, 1432($t0)
	sw $t1, 1688($t0)
	sw $t1, 1692($t0)
	sw $t1, 1696($t0)
	sw $t1, 1700($t0)
	sw $t1, 1944($t0)
	sw $t1, 2200($t0)
	sw $t1, 2204($t0)
	sw $t1, 2208($t0)
	sw $t1, 2212($t0)
	#O
	sw $t1, 2648($t0)
	sw $t1, 2652($t0)
	sw $t1, 2656($t0)
	sw $t1, 2660($t0)
	sw $t1, 2904($t0)
	sw $t1, 2916($t0)
	sw $t1, 3160($t0)
	sw $t1, 3172($t0)
	sw $t1, 3416($t0)
	sw $t1, 3428($t0)
	sw $t1, 3672($t0)
	sw $t1, 3676($t0)
	sw $t1, 3680($t0)
	sw $t1, 3684($t0)
	#V
	sw $t1, 2668($t0)
	sw $t1, 2680($t0)
	sw $t1, 2924($t0)
	sw $t1, 2936($t0)
	sw $t1, 3180($t0)
	sw $t1, 3192($t0)
	sw $t1, 3436($t0)
	sw $t1, 3448($t0)
	sw $t1, 3696($t0)
	sw $t1, 3700($t0)
	#E
	sw $t1, 2688($t0)
	sw $t1, 2692($t0)
	sw $t1, 2696($t0)
	sw $t1, 2700($t0)
	sw $t1, 2944($t0)
	sw $t1, 3200($t0)
	sw $t1, 3204($t0)
	sw $t1, 3208($t0)
	sw $t1, 3212($t0)
	sw $t1, 3456($t0)
	sw $t1, 3712($t0)
	sw $t1, 3716($t0)
	sw $t1, 3720($t0)
	sw $t1, 3724($t0)
	#R
	sw $t1, 2712($t0)
	sw $t1, 2716($t0)
	sw $t1, 2720($t0)
	sw $t1, 2724($t0)
	sw $t1, 2968($t0)
	sw $t1, 2980($t0)
	sw $t1, 3224($t0)
	sw $t1, 3228($t0)
	sw $t1, 3232($t0)
	sw $t1, 3236($t0)
	sw $t1, 3480($t0)
	sw $t1, 3488($t0)
	sw $t1, 3736($t0)
	sw $t1, 3744($t0)
	sw $t1, 3748($t0)
	#show score
	jal show_score
game_over_screen_loop:
	#get key input to restart
	li $t9, 0xffff0000 
	lw $t8, 0($t9)
	beq $t8, 1, erase_game_over
	j game_over_screen_loop
######################################   ERASE GAME OVER   ######################################
erase_game_over:
	li $t0, DISPLAY_ADDRESS
	li $t1, BLACK
	#G
	sw $t1, 1112($t0)
	sw $t1, 1116($t0)
	sw $t1, 1120($t0)
	sw $t1, 1124($t0)
	sw $t1, 1368($t0)
	sw $t1, 1624($t0)
	sw $t1, 1632($t0)
	sw $t1, 1636($t0)
	sw $t1, 1880($t0)
	sw $t1, 1892($t0)
	sw $t1, 2136($t0)
	sw $t1, 2140($t0)
	sw $t1, 2144($t0)
	sw $t1, 2148($t0)
	#A
	sw $t1, 1132($t0)
	sw $t1, 1136($t0)
	sw $t1, 1140($t0)
	sw $t1, 1144($t0)
	sw $t1, 1388($t0)
	sw $t1, 1400($t0)
	sw $t1, 1644($t0)
	sw $t1, 1648($t0)
	sw $t1, 1652($t0)
	sw $t1, 1656($t0)
	sw $t1, 1900($t0)
	sw $t1, 1912($t0)
	sw $t1, 2156($t0)
	sw $t1, 2168($t0)
	#M
	sw $t1, 1152($t0)
	sw $t1, 1156($t0)
	sw $t1, 1160($t0)
	sw $t1, 1164($t0)
	sw $t1, 1168($t0)
	sw $t1, 1408($t0)
	sw $t1, 1416($t0)
	sw $t1, 1424($t0)
	sw $t1, 1664($t0)
	sw $t1, 1672($t0)
	sw $t1, 1680($t0)
	sw $t1, 1920($t0)
	sw $t1, 1928($t0)
	sw $t1, 1936($t0)
	sw $t1, 2176($t0)
	sw $t1, 2184($t0)
	sw $t1, 2192($t0)
	#E
	sw $t1, 1176($t0)
	sw $t1, 1180($t0)
	sw $t1, 1184($t0)
	sw $t1, 1188($t0)
	sw $t1, 1432($t0)
	sw $t1, 1688($t0)
	sw $t1, 1692($t0)
	sw $t1, 1696($t0)
	sw $t1, 1700($t0)
	sw $t1, 1944($t0)
	sw $t1, 2200($t0)
	sw $t1, 2204($t0)
	sw $t1, 2208($t0)
	sw $t1, 2212($t0)
	#O
	sw $t1, 2648($t0)
	sw $t1, 2652($t0)
	sw $t1, 2656($t0)
	sw $t1, 2660($t0)
	sw $t1, 2904($t0)
	sw $t1, 2916($t0)
	sw $t1, 3160($t0)
	sw $t1, 3172($t0)
	sw $t1, 3416($t0)
	sw $t1, 3428($t0)
	sw $t1, 3672($t0)
	sw $t1, 3676($t0)
	sw $t1, 3680($t0)
	sw $t1, 3684($t0)
	#V
	sw $t1, 2668($t0)
	sw $t1, 2680($t0)
	sw $t1, 2924($t0)
	sw $t1, 2936($t0)
	sw $t1, 3180($t0)
	sw $t1, 3192($t0)
	sw $t1, 3436($t0)
	sw $t1, 3448($t0)
	sw $t1, 3696($t0)
	sw $t1, 3700($t0)
	#E
	sw $t1, 2688($t0)
	sw $t1, 2692($t0)
	sw $t1, 2696($t0)
	sw $t1, 2700($t0)
	sw $t1, 2944($t0)
	sw $t1, 3200($t0)
	sw $t1, 3204($t0)
	sw $t1, 3208($t0)
	sw $t1, 3212($t0)
	sw $t1, 3456($t0)
	sw $t1, 3712($t0)
	sw $t1, 3716($t0)
	sw $t1, 3720($t0)
	sw $t1, 3724($t0)
	#R
	sw $t1, 2712($t0)
	sw $t1, 2716($t0)
	sw $t1, 2720($t0)
	sw $t1, 2724($t0)
	sw $t1, 2968($t0)
	sw $t1, 2980($t0)
	sw $t1, 3224($t0)
	sw $t1, 3228($t0)
	sw $t1, 3232($t0)
	sw $t1, 3236($t0)
	sw $t1, 3480($t0)
	sw $t1, 3488($t0)
	sw $t1, 3736($t0)
	sw $t1, 3744($t0)
	sw $t1, 3748($t0)
	jal erase_score
	addi $s4, $zero, 0
	addi $s5, $zero, 0
	j keypress_happened
######################################   DRAW THE WORD HP   ######################################
draw_hp_words:
	li $t0, DISPLAY_ADDRESS
	li $t1, WHITE
	#H
	sw $t1, 7180($t0)
	sw $t1, 7188($t0)
	sw $t1, 7436($t0)
	sw $t1, 7440($t0)
	sw $t1, 7444($t0)
	sw $t1, 7692($t0)
	sw $t1, 7700($t0)
	#P
	sw $t1, 7196($t0)
	sw $t1, 7200($t0)
	sw $t1, 7204($t0)
	sw $t1, 7452($t0)
	sw $t1, 7456($t0)
	sw $t1, 7460($t0)
	sw $t1, 7708($t0)
	jr $ra
######################################   ERASE THE WORD HP   ######################################
erase_hp_words:
	li $t0, DISPLAY_ADDRESS
	li $t1, BLACK
	#H
	sw $t1, 7180($t0)
	sw $t1, 7188($t0)
	sw $t1, 7436($t0)
	sw $t1, 7440($t0)
	sw $t1, 7444($t0)
	sw $t1, 7692($t0)
	sw $t1, 7700($t0)
	#P
	sw $t1, 7196($t0)
	sw $t1, 7200($t0)
	sw $t1, 7204($t0)
	sw $t1, 7452($t0)
	sw $t1, 7456($t0)
	sw $t1, 7460($t0)
	sw $t1, 7708($t0)
	jr $ra
######################################   DRAW HP BAR   ######################################
draw_hp_bar:
	li $t0, DISPLAY_ADDRESS
	li $t1, WHITE
	addi $t9, $zero, 7216
	addi $t4, $zero, 0
	add $t0, $t0, $t9
loop_draw_hp_bar:
	beq $t4, $s3, return_hp_bar
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, -256
	addi $t4, $t4, 1
	addi $t0, $t0, 16
	j loop_draw_hp_bar
return_hp_bar:
	jr $ra
######################################   ERASE HP BAR   ######################################
erase_hp_bar:
	li $t0, DISPLAY_ADDRESS
	li $t1, BLACK
	addi $t9, $zero, 7216
	addi $t4, $zero, 0
	add $t0, $t0, $t9
loop_erase_hp_bar:
	beq $t4, 10, return_erase_hp_bar
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, -256
	addi $t4, $t4, 1
	addi $t0, $t0, 16
	j loop_erase_hp_bar
return_erase_hp_bar:
	jr $ra
######################################   DRAW SCORE   ######################################
show_score:
	#use two addresses for two digit score
	#$s4 is first digit, $s5 is second digit
	#$s4 $s5
	li $t0, DISPLAY_ADDRESS
	li $t1, WHITE
	addi $t2, $zero, 0		
	addi $t9, $zero, 5484
	addi $t8, $zero, 5504
	add $t0, $t0, $t9
	
	beq $s4, 0, draw_0
	beq $s4, 1, draw_1
	beq $s4, 2, draw_2
	beq $s4, 3, draw_3
	beq $s4, 4, draw_4
	beq $s4, 5, draw_5
	beq $s4, 6, draw_6
	beq $s4, 7, draw_7
	beq $s4, 8, draw_8
	beq $s4, 9, draw_9
	j return_score
second_digit_check:
	beq $t2, 2, return_score
	li $t0, DISPLAY_ADDRESS
	add $t0, $t0, $t8
	beq $s5, 0, draw_0
	beq $s5, 1, draw_1
	beq $s5, 2, draw_2
	beq $s5, 3, draw_3
	beq $s5, 4, draw_4
	beq $s5, 5, draw_5
	beq $s5, 6, draw_6
	beq $s5, 7, draw_7
	beq $s5, 8, draw_8
	beq $s5, 9, draw_9
	j return_score
draw_0:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_1:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_2:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_3:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_4:
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_5:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_6:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_7:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_8:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
draw_9:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check
return_score:
    	jr $ra
######################################   ERASE SCORE   ######################################
erase_score:
	#use two addresses for two digit score
	#$s4 is first digit, $s5 is second digit
	#$s4 $s5
	li $t0, DISPLAY_ADDRESS
	li $t1, BLACK
	addi $t2, $zero, 0		
	addi $t9, $zero, 5484
	addi $t8, $zero, 5504
	add $t0, $t0, $t9
	
	beq $s4, 0, erase_0
	beq $s4, 1, erase_1
	beq $s4, 2, erase_2
	beq $s4, 3, erase_3
	beq $s4, 4, erase_4
	beq $s4, 5, erase_5
	beq $s4, 6, erase_6
	beq $s4, 7, erase_7
	beq $s4, 8, erase_8
	beq $s4, 9, erase_9
	j return_score_erase
second_digit_check1:
	beq $t2, 2, return_score_erase
	li $t0, DISPLAY_ADDRESS
	add $t0, $t0, $t8
	beq $s5, 0, erase_0
	beq $s5, 1, erase_1
	beq $s5, 2, erase_2
	beq $s5, 3, erase_3
	beq $s5, 4, erase_4
	beq $s5, 5, erase_5
	beq $s5, 6, erase_6
	beq $s5, 7, erase_7
	beq $s5, 8, erase_8
	beq $s5, 9, erase_9
	j return_score_erase
erase_0:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_1:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_2:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_3:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_4:
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_5:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_6:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_7:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_8:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
erase_9:
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	sw $t1, 12($t0)
	addi $t2, $t2, 1
	j second_digit_check1
return_score_erase:
    	jr $ra
######################################   DRAW PICKUP   ######################################
draw_pickup:
	li $t0, DISPLAY_ADDRESS
	beq $s6, 0, draw_green
	beq $s6, 1, draw_red
draw_green:
	li $t1, GREEN
	j continue_drawing_pickup
draw_red:
	li $t1, RED
continue_drawing_pickup:
	la $t9, PICKUP_COORDS
	lw $t8, 8($t9)
	#draw pickup
	add $t0, $t0, $t8
	sw $t1, 0($t0)
	jr $ra
######################################   ERASE PICKUP   ######################################
erase_pickup:
	li $t0, DISPLAY_ADDRESS
	li $t1, BLACK
	la $t9, PICKUP_COORDS
	lw $t8, 8($t9)
	#erase pickup
	add $t0, $t0, $t8
	sw $t1, 0($t0)
	jr $ra
######################################   PICKUP COLLISION   ######################################
collision_pickup:
	move $s0, $ra
	la $t9, SHIP_COORDS
	la $t0, PICKUP_COORDS
	
	lw $t6, 0($t9)
	lw $t7, 4($t9)
	lw $t4, 0($t0)
	lw $t5, 4($t0)
	
	beq $t4, $t6, check_y_pickup
	lw $t4, 0($t0)
	addi $t4, $t4, -1
	beq $t4, $t6, check_y_pickup
	lw $t4, 0($t0)
	addi $t4, $t4, -2
	beq $t4, $t6, check_y_pickup
	lw $t4, 0($t0)
	addi $t4, $t4, -3
	beq $t4, $t6, check_y_pickup
	j return1
check_y_pickup:
	beq $t5, $t7, pickup_effect
	lw $t5, 4($t0)
	addi $t5, $t5, -1
	beq $t5, $t7, pickup_effect
	lw $t5, 4($t0)
	addi $t5, $t5, -2
	beq $t5, $t7, pickup_effect
	j return1
pickup_effect:
	jal erase_pickup
	li $v0, 42         		# Service 42, random int range
	li $a0, 0         		# Select random generator 0
	li $a1, 26         		# Select upper bound of random number
	syscall    
	add $t1, $zero, $a0
	la $t0, PICKUP_COORDS
	sw $t1, 4($t0)
	li $v0, 42         		# Service 42, random int range
	li $a0, 0         		# Select random generator 0
	li $a1, 50         		# Select upper bound of random number
	syscall    
	add $t2, $zero, $a0
	la $t0, PICKUP_COORDS
	sw $t2, 0($t0)
	addi $t3, $zero, ROW_INCREMENT
	mult $t1, $t3
	mflo $t1
	addi $t9, $zero, 4
	mult $t2, $t9
	mflo $t2
	add $t3, $t1, $t2
	la $t0, PICKUP_COORDS
	sw $t3, 8($t0)
	jal draw_pickup
	beq $s6, 0, add_health
	beq $s6, 1, destroy_asteroids
	j return1
add_health:
	#if already max health (10) dont add health
	beq $s3, 10, return1
	addi $s3, $s3, 1
	jal erase_hp_bar
	#make the next pickup random
	li $v0, 42         		# Service 42, random int range
	li $a0, 0         		# Select random generator 0
	li $a1, 2         		# Select upper bound of random number
	syscall   
	add $t1, $zero, $a0
	add $s6, $zero, $t1
	j return1
destroy_asteroids:
	jal erase_asteroid
	jal set_asteroid
	#make the next pickup random
	li $v0, 42         		# Service 42, random int range
	li $a0, 0         		# Select random generator 0
	li $a1, 2         		# Select upper bound of random number
	syscall   
	add $t1, $zero, $a0
	add $s6, $zero, $t1
return1:
	jr $s0
