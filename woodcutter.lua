--import 'math'

minFuel=50
fuelSlot=16
sapplingSlot=1
maxSignalStrength=15
woodSlot=5
treeCount=13

-- Variables to store the current location and orientation of the turtle. x is right, left, y is up, down and
-- z is forward, back with relation to the starting orientation. y, x and z are
-- in relation to the starting point (i.e. the starting point is (0, 0, 0))
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
	if (blocks < 1) then
		return
	end
	moveToY(curY+blocks)
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
	while (turtle.getFuelLevel() < minFuel) do
		if (turtle.getItemCount(fuelSlot) < 1) then
			return false
		end
		turtle.select(fuelSlot) 
		turtle.refuel(fuelSlot)
	end
	return true
end

-- Turtle is facing a tree, cut it and replant, move back to where it started
function handleTree()
	moveForward(1) -- will cut
	while (turtle.detectUp()) do
		moveUp() -- will cut
	end
	while (not turtle.detectDown()) do
		moveDown()
	end
	-- Turtle is 1 block above root of tree
	turtle.digDown()
	turtle.select(sapplingSlot)
	turtle.placeDown()
	turnLeft(2)
	moveForward(1)
end
 
function findTree()
	moveForward(2)
	signalStrengthCrossing = redstone.getAnalogInput("down")
	turnRight(1)
	moveForward(1)
	signalStrength = redstone.getAnalogInput("down")
	if (signalStrength > signalStrengthCrossing) then
		-- Correct route
		for i=1,treeCount do
			signalStrength = redstone.getAnalogInput("down")
			if (signalStrength == maxSignalStrength) then
				turnLeft(1)
				return true
				break
			end
			moveForward(1)
		end
		
	else
		-- Take the other route
	end
	return false
end

function goHome()
end


print("-- Woodcutter script started --")

-- INIT --
curX = 0
curY = 0
curZ = 0
curDir = direction.FORWARD

-- Run some test --
if (not checkFuel()) then
	return
end

if (findTree()) then
	print("Found a tree!")
end


--while true do
--	if (redstone.getAnalogInput("bottom") > 0) then
--		print("Tree has grown!")
--		collect()
--	end
--	sleep(60)
--end
