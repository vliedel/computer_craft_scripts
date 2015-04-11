--require "math"

-- Fuel settings
minFuel=50
minFuelAfterRefuel=3200 -- TODO: make percentage? or maybe make a max()-set_value

-- Slots
fuelSlot=1
saplingSlot=2
woodSlotBegin=3
woodSlotEnd=16

-- ID settings
--fuelID=
--saplingID=
--woodID=

-- Redstone signal settings
maxSignalStrength=15

-- Woodcutter settings
treeCount=4

-- turtle.dig() Attempts to dig the block in front of the turtle. If successful, suck() is automatically called, placing the item in turtle inventory in the selected slot if possible (block type matches and the slot is not a full stack yet), or in the next available slot.
-- returns true if block was broken
-- TODO: how to detect if block was sucked up? Or better: how to detect when to go home?


-- Variables to store the current location and orientation of the turtle.
-- x is right (positive) and left (negative)
-- y is up (positive) and down (negative)
-- z is forward (positive) and back (negative)
-- Starting location and orientation is (0, 0, 0, direction.FORWARD)
local curX
local curY
local curZ
local curDir

-- Enumeration to store names for the 4 directions
direction = { FORWARD=0, RIGHT=1, BACK=2, LEFT=3 }

-- Makes sure the turtle is facing the given direction
function turn(newDir)
	if (curDir == newDir) then
		return
	end
	if (newDir-curDir == 2 or curDir-newDir == 2) then
		turtle.turnRight()
		turtle.turnRight()
	elseif (newDir-curDir == 1 or curDir-newDir == 3) then
		turtle.turnRight()
	elseif (newDir-curDir == 3 or curDir-newDir == 1) then
		turtle.turnLeft()
	end
	curDir = newDir
end

function moveToX(newX)
	if (newX == curX) then
		return
	end
	
	if (newX > curX) then
		-- Move right, make sure turtle is facing right
		turn(direction.RIGHT)
	else
		-- Move left, make sure turtle is facing left
		turn(direction.LEFT)
	end
	
	-- Turtle is facing the correct way, start moving forward
	while (newX ~= curX) do
		if (turtle.forward()) then
			if (curDir == direction.RIGHT) then
				curX = curX+1
			else
				curX = curX-1
			end
		else
			turtle.dig()
		end
	end
end


function moveToZ(newZ)
	if (newZ == curZ) then
		return
	end
	
	if (newZ > curZ) then
		-- Move forward, make sure turtle is facing forward
		turn(direction.FORWARD)
	else
		-- Move backward, make sure turtle is facing backward
		turn(direction.BACK)
	end
	
	-- Turtle is facing the correct way, start moving forward
	while (newZ ~= curZ) do
		if (turtle.forward()) then
			if (curDir == direction.FORWARD) then
				curZ = curZ+1
			else
				curZ = curZ-1
			end
		else
			turtle.dig()
		end
	end
end

function moveToY(newY)
	if (newY == curY) then
		return
	end
	
	while (newY > curY) do
		if (turtle.up()) then
			curY = curY+1
		else
			turtle.digUp()
		end
	end
	
	while (newY < curY) do
		if (turtle.down()) then
			curY = curY-1
		else
			turtle.digDown()
		end
	end
end

function moveTo(newX, newY, newZ, newDir)
	print("move to: x=", newX, " y=", newY, " z=", newZ, " dir=", newDir)
	moveToZ(newZ)
	moveToX(newX)
	turn(newDir)
end

function turnLeft(num)
	turn((curDir-num)%4)
end

function turnRight(num)
	turn((curDir+num)%4)
end

function moveUp(blocks)
	moveToY(curY+blocks)
end

function moveDown(blocks)
	moveToY(curY-blocks)
end

function moveForward(blocks)
	if (blocks < 1) then
		return
	end
	if (curDir == direction.FORWARD) then
		moveToZ(curZ+blocks)
	elseif (curDir == direction.BACK) then
		moveToZ(curZ-blocks)
	elseif (curDir == direction.RIGHT) then
		moveToX(curX+blocks)
	else
		moveToX(curX-blocks)
	end
end

-- TODO: should not turn around
function moveBackward(blocks)
	if (blocks < 1) then
		return
	end
	if (curDir == direction.FORWARD) then
		moveToZ(curZ-blocks)
	elseif (curDir == direction.BACK) then
		moveToZ(curZ+blocks)
	elseif (curDir == direction.RIGHT) then
		moveToX(curX-blocks)
	else
		moveToX(curX+blocks)
	end
end

function checkFuel()
--	while (turtle.getFuelLevel() < minFuel) do
	turtle.select(fuelSlot) 
	while (turtle.getFuelLevel() < minFuelAfterRefuel) do
		-- Always leave 1 fuel item in the slot
		if (turtle.getItemCount(fuelSlot) < 2) then
			if (turtle.getFuelLevel() > minFuel) then
				return true
			else
				return false
			end
		end
		turtle.refuel(fuelSlot)
	end
	return true
end

function getFuel()

end



-----------------------------------
-- Woodcutter specific functions --
-----------------------------------

-- Turtle is facing a tree, but with redstone dust in between.
-- Cut it and replant, move back to where it started, facing away from tree
function handleTree()
	moveUp(1)
	moveForward(1)
	turtle.select(woodSlotBegin)
	moveForward(1) -- will cut
	
	-- TODO: use: turtle.compareUp() 	Detects if the block above is the same as the one in the currently selected slot
	-- or use: turtle.inspectUp() 	Returns the ID string and metadata of the block above the Turtle
	while (turtle.detectUp()) do
		moveUp(1) -- will cut
	end
--	while (not turtle.detectDown()) do
--		moveDown()
--	end
	moveToY(1)
	-- Turtle is 1 block above root of tree
	turtle.digDown()
	-- Plant new tree, but always leave 1 sapling in the slot
	turtle.select(saplingSlot)
	if (turtle.getItemCount() > 1) then
		turtle.placeDown()
	end
	turnLeft(2)
	moveForward(2)
	moveDown(1)
end

-- Start at crossing, signal is on the left side of the turtle
-- Options are: straight or right
function checkCrossing()
	signalStrengthCrossing = redstone.getAnalogInput("left")
	turnRight(1)
	signalStrength = redstone.getAnalogInput("left")
	if (signalStrength < signalStrengthCrossing) then
		-- Go straight
	end
	-- Go right
end

-- Follows the redstone dust (on the left side), finding the place where the signal strength is maxSignalStrength
-- Turn towards the found maxSignalStrength
function findTree()
	-- Just to have some maximum, if this function is called half way, it could go through the wall
	for i=1,treeCount do
		moveForward(1)
		signalStrength = redstone.getAnalogInput("left")
		if (signalStrength == maxSignalStrength) then
			turnLeft(1)
			return true
		end
	end
	return false
end

-- Makes the turtle go to the chest, where it can get fuel, get saplings and dump wood
function goToChest()
	-- First move to correct X, so that turtle doesn't go through the wall
	moveToX(0)
	moveTo(0, 0, 0, direction.FORWARD)
end



print("-- Woodcutter script started --")
print("-- Start with turtle facing the chest! --")

-- INIT --
curX = 0
curY = 0
curZ = 0
curDir = direction.FORWARD

while (true) do
	-- Just to make sure we're at the start position again
	goToChest()
	if (checkFuel()) then
		print(redstone.getAnalogInput("right"))
		if (redstone.getAnalogInput("right") > 0) then
			print("A tree has grown!")
			
			-- First go to crossing
			moveTo(0, 0, 0, direction.BACK)
			moveForward(1)
			checkCrossing()
			
			-- Keep up position of crossing
			crossingX = curX
			crossingZ = curZ
			
			-- Search for tree in straight line
			while (findTree()) do
				print("Found a tree!")
				handleTree()
				turnLeft(1)
			end
			
			-- Collect some saplings on the way back, suckDown each step
			-- Move 3 further than last found tree, and then back to the crossing
			turtle.select(saplingSlot)
			for i=1,3 do
				turtle.suckDown()
				moveForward(1)
			end
			turnLeft(2)
			while (curX ~= crossingX and curZ ~= crossingZ) do
				turtle.suckDown()
				moveForward(1)
			end
			
			-- Go back to start
			goToChest()
			
			-- Dump materials
			for i=woodSlotBegin, woodSlotEnd do
				turtle.select(i)
				turtle.drop()
			end
			
			-- TODO: get materials
			
			
		else
			print("No tree has grown yet")
		end
	else
		print("Not enough fuel!")
	end
	sleep(5)
end
print("End of program")

