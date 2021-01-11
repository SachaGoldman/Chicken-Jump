#####################################################################
# Author: Sacha Goldman 
# Using any display that is 32 by 32 with starting display address o 0x10008000 ($gp)
#####################################################################

.data

platXs: .space 908 #The horizontal offsets of our platforms
platHeights: .space 908 #The heights of our platforms
displayBuffer: .space 4096 #A buffer for our display that we draw to
displayAddress: .word 0x10008000 #the address of our display in memory
gravity: .word 0 #Stored in 1/128th pixels per frame^2 (Since a frame is square, is a frame squared a four dimensional object?)
velocity: .word 0 #Stored in 1/128th pixels per frame
direction: .word 0 #The direction which our character is facsing. 0 for left, 1 for right
characterHeight: .word 0 #Stored in 1/128th pixels aligned with the bottom of the character
characterX: .word 0 #Stored in pixels 0 to 11 aligned with the left side of the character
displayOffset: .word 0 #Stored in pixels
level: .word 0 #The current level you've reached 1 to 9
numPlats: .word 0 #The number of platforms in the current level
 
skullColor: .word 0xF44336 #The color of the skull
trophyColor: .word 0xFDD835 #The color of the trophy
 
#The colors of the level dots
dotCompleteColor: .word 0xB2FF59 
dotIncompleteColor: .word 0x9E9E9E
dotNextColor: .word 0xFFFFFF
 
#The colors for the background
brickGroutColor: .word 0x616161
brickColor: .word 0x757575
 
#The colors for our character
characterBeak: .word 0xFFEB3B #Yellow
characterNeck: .word 0xFF3D00 #Red
characterBody: .word 0xFAFAFA #White-ish
 
#The HUD colors:
hudIncomplete: .word 0xE040FB
hudComplete: .word 0x8E24AA
  
#Some constant colours
black: .word 0x000000
white: .word 0xFFFFFF
grey: .word 0x424242
 
.text

START:
#Reset the level
li $t0, 0
sw $t0, level

LEVEL_FINISHED:

#Increment the level
lw $t0, level
#Check our win condition
beq $t0, 9, WIN
addi $t0, $t0, 1
sw $t0, level

#Paint the background grey
jal GREY

#Draw the dots representing the compeleted levels
DOTS:

li $t1, 0

DOTS_LOOP:
addi $t1, $t1, 1
beq $t1, 10, DOTS_LOOP_END

li $t0, 1932

COLOR_PICK:
lw $t9, level

beq $t9, $t1, NEXT_DOT
bgt $t9, $t1, COMPLETE_DOT

#Color this dot an incomplete
INCOMPLETE_DOT:
lw $t2, dotIncompleteColor
j DOT_DRAW

#Color this dot as the next level
NEXT_DOT:
lw $t2, dotNextColor
j DOT_DRAW

#Color this dot as completed
COMPLETE_DOT:
lw $t2, dotCompleteColor
j DOT_DRAW

DOT_DRAW:

#Calculate the location on the display to display our dot
li $t3, 12
mult $t1, $t3
mflo, $t3
lw $t4, displayAddress
add, $t3, $t3, $t4

#Draw the dot
sw $t2, 1920($t3)
sw $t2, 1924($t3)
sw $t2, 2048($t3)
sw $t2, 2052($t3)

j DOTS_LOOP

DOTS_LOOP_END:

#Init the values for the coming level
li $t0, 0
sw $t0, velocity
li $t0, 400
sw $t0, characterHeight
li $t0, 11
sw $t0, characterX
li $t0, 0
sw $t0, displayOffset
li $t0, 5
lw $1, level
srl $1, $1, 2
add $t0, $1, $t0
sub $t0, $zero, $t0
sw $t0, gravity

#Generate the platforms for the coming level
GENERATE_PLATFORMS:
sw $zero, numPlats #Reset the number of platfrom
la $t5, platXs #The address of our x platform info
la $t6, platHeights #The address of our platfrom height info

lw $t1, level #the current level
sra $t0, $t1, 1
addi $t0, $t0, 7 #This representents the height of a range of pixels in which we will generate a set number of random platforms. This way we know that the level is winnable

sll $t2, $t1, 6
addi $t2, $t2 -1 #How many pixels tall the current level is

li $t1, 5

GENERATE_PLATFORMS_LOOP:
bge $t1, $t2 GENERATE_PLATFORMS_LOOP_END #Branch when we are looking a range off the current level

#Generate 3 platforms in the given range
li $t3, 3
GENERATE_PLATFORMS_IN_RANGE_LOOP:
addi $t3, $t3, -1
beqz $t3, GENERATE_PLATFORMS_IN_RANGE_LOOP_END

REGEN:
 
#Load the current number of platforms
lw $t7, numPlats
sll $t7, $t7, 2

#Generate the random x
li $v0, 42 
li $a0, 0
li $a1, 27 
syscall
add $t9, $a0, $zero

add $t4, $t7, $t5
sw $t9, ($t4)
 
#Generate the random height
li $v0, 42
li $a0, 0
add $a1, $t0, $zero
addi $a1, $a1, -1
syscall
add $t9, $a0, $zero
add $t9, $t1, $t9

add $t4, $t7, $t6
sw $t9, ($t4)

#Checking this platform against the others in the same range to ensure they are NOT apporoximitly the same height. If the platform is to close the we regenerate it. This psudo-random approach allows for more diffuclt levels that are still winnable
beq $t3, 2, END_CHECKS

addi $t4, $t4, -4
lw $t7, ($t4)

beq $t7, $t9, REGEN
addi $t7, $t7, -1
beq $t7, $t9, REGEN
addi $t7, $t7, 2
beq $t7, $t9, REGEN

beq $t3, 1, END_CHECKS

addi $t4, $t4, -4
lw $t7, ($t4)

beq $t7, $t9, REGEN
addi $t7, $t7, -1
beq $t7, $t9, REGEN
addi $t7, $t7, 2
beq $t7, $t9, REGEN

END_CHECKS:

#If this platforms is off this top of the level don't store it
bgt $t9, $t2 GENERATE_PLATFORMS_IN_RANGE_LOOP

#Update numPlats
lw $t8, numPlats
addi $t8, $t8, 1
sw $t8, numPlats

j GENERATE_PLATFORMS_IN_RANGE_LOOP

GENERATE_PLATFORMS_IN_RANGE_LOOP_END:

add $t1, $t1, $t0

j GENERATE_PLATFORMS_LOOP

GENERATE_PLATFORMS_LOOP_END:

#Wait until the user wishes to proceed to the next level
LEVEL_ADVANCE_HOLD:
lw $t0, 0xffff0000
beqz $t0, LEVEL_ADVANCE_HOLD

li $v0, 32
li $a0, 16
syscall

lw $t0, 0xffff0004
beq $t0, 115, MAIN_LOOP
j LEVEL_ADVANCE_HOLD

#The main loop running during gameplay
MAIN_LOOP:

#Check if the chracter is over the finish line
CHECK_ADVANCE:

lw $t0, level
li $t2, 64
mult $t0, $t2
mflo $t0
addi $t2, $t2, -1 #How many pixels tall the current level is

lw $t1, characterHeight
sra $t1, $t1, 7 #The characters height off the ground

bge $t1, $t0, LEVEL_FINISHED

#Check if the character has it the bottom of the dispaly
CHECK_DEAD:

lw $t0, displayOffset
lw $t1, characterHeight
sra $t1, $t1, 7

ble $t1, $t0, DEAD 

#Check if the view frame needs to be raised
CHECK_VIEW_PORT:

lw $t0, displayOffset
lw $t1, characterHeight
sra $t1, $t1, 7
sub $t2, $t1, $t0 #The characters height off the ground

blt $t2, 24, CHECK_VIEW_PORT_END

#Raise the viewframe
addi $t1, $t1, -24
sw $t1, displayOffset

CHECK_VIEW_PORT_END:

#Generate the level background including the start/finish lines if applicable
BACKGROUD:

la $t0, displayBuffer #The address of our character 
li $t1, 32

BACKGROUD_LOOP:
#Loop through each pixel and make it our lovely background colour
beqz $t1, BACKGROUND_END
addi $t1, $t1, -1

#Calculate the number of the ground of our background
lw $t2, displayOffset
add $t3, $t2, $t1
lw $t4, level
sll $t4, $t4, 6

li $t6 31
sub $t6, $t6, $t1
sll $t9, $t6, 7
add, $t9, $t9, $t0

#Check if this line should be a starting or ending line
beq $t3, 1, CHECKERED_LINE_TWO
beq $t3, 0, CHECKERED_LINE_ONE

beq $t3, $t4, CHECKERED_LINE_TWO
addi $t4, $t4, -1
beq $t3, $t4, CHECKERED_LINE_ONE

sll $t3, $t3, 29
srl $t3, $t3, 29

#Decide which seaction of the brick pattern this is
beq $t3, 2, BRICK_SEEM
beq $t3, 6, BRICK_SEEM

beq $t3, 0, BRICK_ONE
beq $t3, 1, BRICK_ONE
beq $t3, 8, BRICK_ONE

beq $t3, 3, BRICK_TWO
beq $t3, 4, BRICK_TWO
beq $t3, 5, BRICK_TWO

BRICK_ONE:

lw $t8, brickColor
lw $t7, brickGroutColor

#Draw this line
sw $t8, ($t9)
sw $t8, 4($t9)
sw $t8, 8($t9)
sw $t7, 12($t9)
sw $t8, 16($t9)
sw $t8, 20($t9)
sw $t8, 24($t9)
sw $t8, 28($t9)
sw $t7, 32($t9)
sw $t8, 36($t9)
sw $t8, 40($t9)
sw $t8, 44($t9)
sw $t8, 48($t9)
sw $t7, 52($t9)
sw $t8, 56($t9)
sw $t8, 60($t9)
sw $t8, 64($t9)
sw $t8, 68($t9)
sw $t7, 72($t9)
sw $t8, 76($t9)
sw $t8, 80($t9)
sw $t8, 84($t9)
sw $t8, 88($t9)
sw $t7, 92($t9)
sw $t8, 96($t9)
sw $t8, 100($t9)
sw $t8, 104($t9)
sw $t8, 108($t9)
sw $t7, 112($t9)
sw $t8, 116($t9)
sw $t8, 120($t9)
sw $t8, 124($t9)
j BACKGROUD_LOOP

BRICK_TWO:

lw $t8, brickColor
lw $t7, brickGroutColor

#Draw this line
sw $t8, ($t9)
sw $t7, 4($t9)
sw $t8, 8($t9)
sw $t8, 12($t9)
sw $t8, 16($t9)
sw $t8, 20($t9)
sw $t7, 24($t9)
sw $t8, 28($t9)
sw $t8, 32($t9)
sw $t8, 36($t9)
sw $t8, 40($t9)
sw $t7, 44($t9)
sw $t8, 48($t9)
sw $t8, 52($t9)
sw $t8, 56($t9)
sw $t8, 60($t9)
sw $t7, 64($t9)
sw $t8, 68($t9)
sw $t8, 72($t9)
sw $t8, 76($t9)
sw $t8, 80($t9)
sw $t7, 84($t9)
sw $t8, 88($t9)
sw $t8, 92($t9)
sw $t8, 96($t9)
sw $t8, 100($t9)
sw $t7, 104($t9)
sw $t8, 108($t9)
sw $t8, 112($t9)
sw $t8, 116($t9)
sw $t8, 120($t9)
sw $t7, 124($t9)
j BACKGROUD_LOOP

BRICK_SEEM:

lw $t7, brickGroutColor

li $t6, 128

#Draw this line
BRICK_SEEM_LOOP:
beqz, $t6, BACKGROUD_LOOP
addi, $t6, $t6, -4
add, $t5, $t6, $t9
sw $t7, ($t5)
j BRICK_SEEM_LOOP

CHECKERED_LINE_ONE:

lw $t8, black
lw $t7, white

li $t6, 128

#Draw this line
CHECKERED_LINE_ONE_LOOP:
beqz, $t6, BACKGROUD_LOOP
addi, $t6, $t6, -8
add, $t5, $t6, $t9
sw $t7, ($t5)
sw $t8, 4($t5)
j CHECKERED_LINE_ONE_LOOP

CHECKERED_LINE_TWO:

lw $t8, white
lw $t7, black

li $t6, 128

#Draw this line
CHECKERED_LINE_TWO_LOOP:
beqz, $t6, BACKGROUD_LOOP
addi, $t6, $t6, -8
add, $t5, $t6, $t9
sw $t7, ($t5)
sw $t8, 4($t5)
j CHECKERED_LINE_TWO_LOOP

BACKGROUND_END:

#Check for user input
INPUT:

#Check if the user has pressed a key
lw $t0, 0xffff0000
beqz $t0, INPUT_END

#Check if the user has pressed a key that we a interested
lw $t0, 0xffff0004
beq $t0, 106, J_RESPOND
beq $t0, 107, K_RESPOND
beq $t0, 115, START #Restart if the user pressed 's'

j INPUT_END

J_RESPOND:

#Update which direction the character is facing
li $t0, 0
sw $t0, direction

#Move the chracter left
lw $t1, characterX
beq $t1, 0, INPUT_END
addi $t1, $t1, -1
sw $t1, characterX

j INPUT_END

K_RESPOND:

#Update which direction the character is facing
li $t0, 1
sw $t0, direction

#Move the chracter right
lw $t1, characterX
beq $t1, 26, INPUT_END
addi $t1, $t1, 1
sw $t1, characterX

j INPUT_END

INPUT_END:

#Draw the platforms that are visible
DRAW_PLATFROMS:

la $t0, displayBuffer
la $t8, platXs
la $t9, platHeights

lw $t1, numPlats
sll $t7, $t1, 2

#Draw each platform
DRAW_PLATFORM:
beqz $t7, DRAW_PLATFORM_END
addi $t7, $t7, -4

add $t1, $t7, $t9 #the address of the height value of the current platform
lw $t1, ($t1)
add $t4, $t7, $t8 #the address of the x value of the current platform
lw $t4, ($t4)

#Break if we don't need to draw this platform because it's off screen
lw $t3, displayOffset
addi $t3, $t3, 1
blt $t1, $t3, DRAW_PLATFORM
addi $t3, $t3, 31
bge $t1, $t3, DRAW_PLATFORM

#find the where this paltform should be on our display
lw $t3, displayOffset
sub $t1, $t1, $t3

li $t3, 32
sub $t1, $t3, $t1
sll $t1, $t1, 5
add $t1, $t1, $t4
sll $t1, $t1, 2

li $t2 20

PLATFORM_LOOP:
#Draw each pixel of our platform
beqz $t2 PLATFORM_LOOP_END
addi $t2, $t2, -4
add $t3, $t1, $t2
add $t3, $t3, $t0
li $t4, 0xFFC107
sw $t4, ($t3)

j PLATFORM_LOOP

PLATFORM_LOOP_END:

j DRAW_PLATFORM

DRAW_PLATFORM_END:

#Calculate the new velocity using the old velocity and gravity
GRAVITY:

lw $t0, velocity
lw $t1, gravity
add $t0, $t0, $t1
sw $t0, velocity

#Check if our character has reached terminal velocity and ensure that they don't exceed it
TERMINAL_VELOCITY_CHECK:

bge $t0, -128, TERMINAL_VELOCITY_CHECK_END
li $t0, -128
sw $t0, velocity

TERMINAL_VELOCITY_CHECK_END:

#Update the characters vertical position
MOVE:

#Load the current position and velocity
lw $t0, characterHeight
lw $t1, velocity 

#Update the current position given the current velocity
add $t0, $t0, $t1
sw $t0, characterHeight

#Check if the character has collided with the starting line or a platform and if so make them jump
CHECK_COLLISION:

lw $t0, velocity
bgtz $t0, CHECK_COLLISION_END

lw $t0, characterHeight #Load the height
sra $t0, $t0, 7 #Convert the height to pixels

ble $t0, 2, JUMP #Jump of the character is at on the starting line

la $t1, platXs
la $t2, platHeights

lw $t9, numPlats

CHECK_COLLISION_LOOP:
beqz $t9, CHECK_COLLISION_LOOP_END
addi $t9, $t9, -1
sll $t8, $t9, 2

#Find the x and height of the current platform of interest
add $t3, $t1, $t8
add $t4, $t2, $t8

lw $t3, ($t3) #x value
lw $t4, ($t4) #height valye

#if on the line bellow our character check for collision
beq $t4, $t0, CHECK_PLATFORM

j CHECK_END

CHECK_PLATFORM:

lw $t7, characterX 
li $t5, 5 #The length of platform

#Check the platform is directly below our characters foot depending on which direction our character is facing  
lw $t6, direction
beqz $t6, CHECK_PLATFORM_LEFT_FACING

CHECK_PLATFORM_RIGHT_FACING:
addi $t7, $t7, 2
j CHECK_PLATFORM_LOOP

CHECK_PLATFORM_LEFT_FACING:
addi $t7, $t7 3

#Loop through each pixel of our platform
CHECK_PLATFORM_LOOP:
beqz $t5, CHECK_END
addi $t5, $t5, -1 

add $t6, $t5, $t3 

#Jump if this platform is below our characters foot
beq $t6, $t7, JUMP
j CHECK_PLATFORM_LOOP

CHECK_END:

j CHECK_COLLISION_LOOP

CHECK_COLLISION_LOOP_END:

j CHECK_COLLISION_END

#Set the chracters velocity to some upwards constant
JUMP:
li $t0, 160
sw $t0, velocity

CHECK_COLLISION_END:

#Draw our character
DRAW_CHARACTER:

la $t0, displayBuffer 

#Calculate the location of the character on the dispaly
lw $t1, characterHeight 
srl $t1, $t1, 7
lw $t2, displayOffset
sub $t1, $t1, $t2
addi $t1, $t1, 5
li $t2, 32
sub, $t1, $t2, $t1
sll $t1, $t1, 5
lw $t2, characterX
add $t1, $t1, $t2
sll $t1, $t1, 2

add $t3, $t0, $t1

lw $t9, characterBeak 
lw $t8, black 
lw $t7, characterNeck 
lw $t6, characterBody 

#Check what direction the character is facing and draw them acordingly
lw $t2, direction 
beqz $t2 DRAW_CHARACTER_LEFT

DRAW_CHARACTER_RIGHT:

sw $t6, 16($t3)
sw $t6, 12($t3)

sw $t8, 144($t3)
sw $t6, 140($t3)

sw $t9, 276($t3)
sw $t9, 272($t3)
sw $t6, 268($t3)
sw $t6, 264($t3)
sw $t6, 260($t3)

sw $t7, 400($t3)
sw $t6, 396($t3)
sw $t6, 392($t3)
sw $t6, 388($t3)

sw $t9, 520($t3)

j DRAW_CHARACTER_END

DRAW_CHARACTER_LEFT:

sw $t6, 4($t3)
sw $t6, 8($t3)

sw $t8, 132($t3)
sw $t6, 136($t3)

sw $t9, 256($t3)
sw $t9, 260($t3)
sw $t6, 264($t3)
sw $t6, 268($t3)
sw $t6, 272($t3)

sw $t7, 388($t3)
sw $t6, 392($t3)
sw $t6, 396($t3)
sw $t6, 400($t3)

sw $t9, 524($t3)

DRAW_CHARACTER_END:

#Draw the progess bar in the top left corner
DRAW_HUD:

lw $t9, black
lw $t8, hudIncomplete
lw $t7, hudComplete

la $t0, displayBuffer

#Calculate how much of the HUD progress bar should be filled 0 to 15
lw $t2, characterHeight
sra $t2, $t2, 3
lw $t3, level
sll $t3, $t3, 6
divu $t2, $t3
mflo $t2 #How much of the HUD progress bar should be filled 0 to 15

#The left cap of the HUD
sw $t9, 64($t0)
sw $t9, 192($t0)

li $t1, 64

#Draw the HUD
HUD_LOOP:
addi, $t1, $t1, -4
beqz $t1, HUD_END

add $t3, $t1, $t0

#Draw the bottom cap
sw $t9, 192($t3)

srl $t4, $t1, 2

#Check if this pixel should be drawn as complete or incomplete
ble $t2, $t4, DRAW_PROGRESS

#Draw as incomplete
sw $t8, 64($t3)
j HUD_LOOP

#Draw as complete
DRAW_PROGRESS:
sw $t7, 64($t3)
j HUD_LOOP

HUD_END:

BUFFER_TO_DISPLAY:

la $t0, displayBuffer #The address of our buffer 
lw $t1, displayAddress #The address of our display 
li $t2, 4096

BUFFER_TO_DISPLAY_LOOP:
# Loop through each pixel in the dispaly buffer and move it to the display
beqz $t2, BUFFER_TO_DISPLAY_LOOP_END
addi $t2, $t2, -4

# Add our offset
add $t8, $t0, $t2
add $t9, $t1, $t2

# Move the value
lw $t7, ($t8)
sw $t7, ($t9)
j BUFFER_TO_DISPLAY_LOOP

BUFFER_TO_DISPLAY_LOOP_END:

#Sleep so the game doesn't move to fast
SLEEP:
li $v0, 32
li $a0, 16
syscall
 
j MAIN_LOOP

#Fill the entire screen with grey
GREY:

lw $t0, displayAddress 
li $t1, 4096

GREY_LOOP:
beqz $t1, GREY_END
addi $t1, $t1, -4
add $t2, $t1, $t0
lw $t3, grey
sw $t3, ($t2)
j GREY_LOOP

GREY_END:

jr $ra

#Display a skull of the character is dead
DEAD:

jal GREY

lw $t0, displayAddress 
lw $t1, skullColor

#Draw the skull
sw $t1, 1192($t0)
sw $t1, 1196($t0)
sw $t1, 1200($t0)
sw $t1, 1204($t0)
sw $t1, 1208($t0)
sw $t1, 1212($t0)
sw $t1, 1216($t0)
sw $t1, 1220($t0)
sw $t1, 1224($t0)
sw $t1, 1228($t0)
sw $t1, 1232($t0)
sw $t1, 1236($t0)

sw $t1, 1316($t0)
sw $t1, 1320($t0)
sw $t1, 1324($t0)
sw $t1, 1328($t0)
sw $t1, 1332($t0)
sw $t1, 1336($t0)
sw $t1, 1340($t0)
sw $t1, 1344($t0)
sw $t1, 1348($t0)
sw $t1, 1352($t0)
sw $t1, 1356($t0)
sw $t1, 1360($t0)
sw $t1, 1364($t0)
sw $t1, 1368($t0)

sw $t1, 1440($t0)
sw $t1, 1444($t0)
sw $t1, 1448($t0)
sw $t1, 1452($t0)
sw $t1, 1456($t0)
sw $t1, 1460($t0)
sw $t1, 1464($t0)
sw $t1, 1468($t0)
sw $t1, 1472($t0)
sw $t1, 1476($t0)
sw $t1, 1480($t0)
sw $t1, 1484($t0)
sw $t1, 1488($t0)
sw $t1, 1492($t0)
sw $t1, 1496($t0)
sw $t1, 1500($t0)

sw $t1, 1568($t0)
sw $t1, 1572($t0)
sw $t1, 1576($t0)

sw $t1, 1588($t0)
sw $t1, 1592($t0)
sw $t1, 1596($t0)
sw $t1, 1600($t0)
sw $t1, 1604($t0)
sw $t1, 1608($t0)

sw $t1, 1620($t0)
sw $t1, 1624($t0)
sw $t1, 1628($t0)

sw $t1, 1696($t0)
sw $t1, 1700($t0)

sw $t1, 1720($t0)
sw $t1, 1724($t0)
sw $t1, 1728($t0)
sw $t1, 1732($t0)

sw $t1, 1752($t0)
sw $t1, 1756($t0)

sw $t1, 1824($t0)
sw $t1, 1828($t0)

sw $t1, 1848($t0)
sw $t1, 1852($t0)
sw $t1, 1856($t0)
sw $t1, 1860($t0)

sw $t1, 1880($t0)
sw $t1, 1884($t0)

sw $t1, 1952($t0)
sw $t1, 1956($t0)
sw $t1, 1960($t0)

sw $t1, 1972($t0)
sw $t1, 1976($t0)
sw $t1, 1980($t0)
sw $t1, 1984($t0)
sw $t1, 1988($t0)
sw $t1, 1992($t0)

sw $t1, 2004($t0)
sw $t1, 2008($t0)
sw $t1, 2012($t0)

sw $t1, 2080($t0)
sw $t1, 2084($t0)
sw $t1, 2088($t0)
sw $t1, 2092($t0)
sw $t1, 2096($t0)
sw $t1, 2100($t0)

sw $t1, 2108($t0)
sw $t1, 2112($t0)

sw $t1, 2120($t0)
sw $t1, 2124($t0)
sw $t1, 2128($t0)
sw $t1, 2132($t0)
sw $t1, 2136($t0)
sw $t1, 2140($t0)

sw $t1, 2208($t0)
sw $t1, 2212($t0)
sw $t1, 2216($t0)
sw $t1, 2220($t0)
sw $t1, 2224($t0)
sw $t1, 2228($t0)

sw $t1, 2236($t0)
sw $t1, 2240($t0)

sw $t1, 2248($t0)
sw $t1, 2252($t0)
sw $t1, 2256($t0)
sw $t1, 2260($t0)
sw $t1, 2264($t0)
sw $t1, 2268($t0)

sw $t1, 2340($t0)
sw $t1, 2344($t0)
sw $t1, 2348($t0)
sw $t1, 2352($t0)
sw $t1, 2356($t0)
sw $t1, 2360($t0)
sw $t1, 2364($t0)
sw $t1, 2368($t0)
sw $t1, 2372($t0)
sw $t1, 2376($t0)
sw $t1, 2380($t0)
sw $t1, 2384($t0)
sw $t1, 2388($t0)
sw $t1, 2392($t0)

sw $t1, 2472($t0)
sw $t1, 2476($t0)
sw $t1, 2480($t0)
sw $t1, 2484($t0)
sw $t1, 2488($t0)
sw $t1, 2492($t0)
sw $t1, 2496($t0)
sw $t1, 2500($t0)
sw $t1, 2504($t0)
sw $t1, 2508($t0)
sw $t1, 2512($t0)
sw $t1, 2516($t0)

sw $t1, 2608($t0)
sw $t1, 2612($t0)

sw $t1, 2620($t0)
sw $t1, 2624($t0)

sw $t1, 2632($t0)
sw $t1, 2636($t0)

sw $t1, 2736($t0)
sw $t1, 2740($t0)

sw $t1, 2748($t0)
sw $t1, 2752($t0)

sw $t1, 2760($t0)
sw $t1, 2764($t0)

#Wait for the user to proceed
DEAD_HOLD:
lw $t0, 0xffff0000
beqz $t0, DEAD_HOLD

li $v0, 32
li $a0, 16
syscall

lw $t0, 0xffff0004
beq $t0, 115, START
j DEAD_HOLD

#Display a trophy if the player wins
WIN:

jal GREY

lw $t0, displayAddress 
lw $t1, trophyColor

#Draw the trophy
sw $t1, 804($t0)
sw $t1, 808($t0)
sw $t1, 812($t0)
sw $t1, 816($t0)
sw $t1, 820($t0)
sw $t1, 824($t0)
sw $t1, 828($t0)
sw $t1, 832($t0)
sw $t1, 836($t0)
sw $t1, 840($t0)
sw $t1, 844($t0)
sw $t1, 848($t0)
sw $t1, 852($t0)
sw $t1, 856($t0)

sw $t1, 928($t0)

sw $t1, 940($t0)
sw $t1, 944($t0)
sw $t1, 948($t0)
sw $t1, 952($t0)
sw $t1, 956($t0)
sw $t1, 960($t0)
sw $t1, 964($t0)
sw $t1, 968($t0)
sw $t1, 972($t0)
sw $t1, 976($t0)

sw $t1, 988($t0)

sw $t1, 1052($t0)

sw $t1, 1068($t0)
sw $t1, 1072($t0)
sw $t1, 1076($t0)
sw $t1, 1080($t0)
sw $t1, 1084($t0)
sw $t1, 1088($t0)
sw $t1, 1092($t0)
sw $t1, 1096($t0)
sw $t1, 1100($t0)
sw $t1, 1104($t0)

sw $t1, 1120($t0)

sw $t1, 1180($t0)

sw $t1, 1196($t0)
sw $t1, 1200($t0)
sw $t1, 1204($t0)
sw $t1, 1208($t0)
sw $t1, 1212($t0)
sw $t1, 1216($t0)
sw $t1, 1220($t0)
sw $t1, 1224($t0)
sw $t1, 1228($t0)
sw $t1, 1232($t0)

sw $t1, 1248($t0)

sw $t1, 1308($t0)

sw $t1, 1324($t0)
sw $t1, 1328($t0)
sw $t1, 1332($t0)
sw $t1, 1336($t0)
sw $t1, 1340($t0)
sw $t1, 1344($t0)
sw $t1, 1348($t0)
sw $t1, 1352($t0)
sw $t1, 1356($t0)
sw $t1, 1360($t0)

sw $t1, 1376($t0)

sw $t1, 1440($t0)

sw $t1, 1452($t0)
sw $t1, 1456($t0)
sw $t1, 1460($t0)
sw $t1, 1464($t0)
sw $t1, 1468($t0)
sw $t1, 1472($t0)
sw $t1, 1476($t0)
sw $t1, 1480($t0)
sw $t1, 1484($t0)
sw $t1, 1488($t0)

sw $t1, 1500($t0)

sw $t1, 1568($t0)

sw $t1, 1580($t0)
sw $t1, 1584($t0)
sw $t1, 1588($t0)
sw $t1, 1592($t0)
sw $t1, 1596($t0)
sw $t1, 1600($t0)
sw $t1, 1604($t0)
sw $t1, 1608($t0)
sw $t1, 1612($t0)
sw $t1, 1616($t0)

sw $t1, 1628($t0)

sw $t1, 1700($t0)

sw $t1, 1708($t0)
sw $t1, 1712($t0)
sw $t1, 1716($t0)
sw $t1, 1720($t0)
sw $t1, 1724($t0)
sw $t1, 1728($t0)
sw $t1, 1732($t0)
sw $t1, 1736($t0)
sw $t1, 1740($t0)
sw $t1, 1744($t0)

sw $t1, 1752($t0)

sw $t1, 1832($t0)
sw $t1, 1836($t0)
sw $t1, 1840($t0)
sw $t1, 1844($t0)
sw $t1, 1848($t0)
sw $t1, 1852($t0)
sw $t1, 1856($t0)
sw $t1, 1860($t0)
sw $t1, 1864($t0)
sw $t1, 1868($t0)
sw $t1, 1872($t0)
sw $t1, 1876($t0)

sw $t1, 1968($t0)
sw $t1, 1972($t0)
sw $t1, 1976($t0)
sw $t1, 1980($t0)
sw $t1, 1984($t0)
sw $t1, 1988($t0)
sw $t1, 1992($t0)
sw $t1, 1996($t0)

sw $t1, 2100($t0)
sw $t1, 2104($t0)
sw $t1, 2108($t0)
sw $t1, 2112($t0)
sw $t1, 2116($t0)
sw $t1, 2120($t0)

sw $t1, 2232($t0)
sw $t1, 2236($t0)
sw $t1, 2240($t0)
sw $t1, 2244($t0)

sw $t1, 2364($t0)
sw $t1, 2368($t0)

sw $t1, 2492($t0)
sw $t1, 2496($t0)

sw $t1, 2620($t0)
sw $t1, 2624($t0)

sw $t1, 2748($t0)
sw $t1, 2752($t0)

sw $t1, 2868($t0)
sw $t1, 2872($t0)
sw $t1, 2876($t0)
sw $t1, 2880($t0)
sw $t1, 2884($t0)
sw $t1, 2888($t0)

sw $t1, 2992($t0)
sw $t1, 2996($t0)
sw $t1, 3000($t0)
sw $t1, 3004($t0)
sw $t1, 3008($t0)
sw $t1, 3012($t0)
sw $t1, 3016($t0)
sw $t1, 3020($t0)

sw $t1, 3116($t0)
sw $t1, 3120($t0)
sw $t1, 3124($t0)
sw $t1, 3128($t0)
sw $t1, 3132($t0)
sw $t1, 3136($t0)
sw $t1, 3140($t0)
sw $t1, 3144($t0)
sw $t1, 3148($t0)
sw $t1, 3152($t0)

#Wait for the user to proceed
WIN_HOLD:
lw $t0, 0xffff0000
beqz $t0, WIN_HOLD

li $v0, 32
li $a0, 16
syscall

lw $t0, 0xffff0004
beq $t0, 115, START
j WIN_HOLD





















