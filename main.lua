-- Version number
version = 'V1.0'

-- Timer variable
dtotal = 0

-- Enemies table
enemies = {}

function love.load()
	-- Set screen attributes
	screen = {
		width = 320,
		height = 240
	}

	-- Set player attributes
	player = {
		x = 0,
		y = 0,
		speed = 200,
		gravity = 100,
		width = 24,
		height = 24
	}

	-- Set bullet attributes
	bullet = {
		x = 0,
		y = 0,
		speed = 300,
		width = 15,
		height = 10,
		img = love.graphics.newImage('assets/bullet.png')
	}

	-- Set game state
	gamestate = 'title'

	-- Initialize score
	score = 0

	-- Set window attributes
	love.window.setTitle('Moonman')
	love.window.setMode(screen.width * 2, screen.height * 2)

	-- Set default scaling filter
	love.graphics.setDefaultFilter('nearest', 'nearest')

	-- Create new canvas
	canvas = love.graphics.newCanvas(screen.width, screen.height)

	-- Create new animation
	animPlayer = newAnimation(love.graphics.newImage('assets/moonman.png'), 24, 24, 0.5)
	animEnemy = newAnimation(love.graphics.newImage('assets/alien.png'), 24, 24, 1)

	-- Load sprites
	logo = love.graphics.newImage('assets/logo.png')
	background = love.graphics.newImage('assets/background.png')

	-- Load font
	font = love.graphics.newImageFont('assets/font.png', ' !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~')
	love.graphics.setFont(font)

	-- Load music
	musicTrack = love.audio.newSource('assets/music.wav', 'static')
	musicTrack:setLooping(true)

	-- Load sound effects
	shootSfx = love.audio.newSource('assets/laser.wav', 'static')
	shootSfx:setVolume(0.5)

	playerDestroySfx = love.audio.newSource('assets/death.wav', 'static')
	playerDestroySfx:setVolume(0.5)

	enemyDestroySfx = love.audio.newSource('assets/explosion.wav', 'static')
	enemyDestroySfx:setVolume(0.75)
end

function love.update(dt)
	if gamestate == 'play' then
		-- Left and right movement key binds
		if love.keyboard.isDown('a', 'left') then
			if player.x > 0 then
				player.x = player.x - (player.speed * dt)
			end
		elseif love.keyboard.isDown('d', 'right') then
			if player.x < (screen.width - player.width) then
				player.x = player.x + (player.speed * dt)
			end
		end

		-- Jetpack key bind
		if love.keyboard.isDown('w', 'up') then
			if player.y > 20 then
				player.y = player.y - ((player.speed + player.gravity) * dt)
			end
		end

		-- Continuously apply gravity to player
		if player.y < screen.height then
			player.y = player.y + (player.gravity * dt)
		end

		-- Game over if touching bottom of screen
		if player.y > (screen.height - player.height) then
			endGame()
		end

		-- Update animations
		animPlayer.currentTime = animPlayer.currentTime + dt
		if animPlayer.currentTime >= animPlayer.duration then
			animPlayer.currentTime = animPlayer.currentTime - animPlayer.duration
		end

		animEnemy.currentTime = animEnemy.currentTime + dt
		if animEnemy.currentTime >= animEnemy.duration then
			animEnemy.currentTime = animEnemy.currentTime - animEnemy.duration
		end

		-- Move projectile
		bullet.x = bullet.x + (bullet.speed * dt)
		if bullet.x > screen.width then
			bullet.x = 1000
		end

		-- Update enemies
		for i=#enemies, 1, -1 do
			local enemy = enemies[i]
			if not enemy.removed then
				enemy.x = enemy.x - (enemy.speed * dt)

				-- Remove enemy when off screen
				if enemy.x < (0 - enemy.width) then
					enemy.removed = true
				end

				-- Collision checking (projectile)
				if checkCollision(enemy.x,enemy.y,enemy.width,enemy.height,bullet.x,bullet.y,bullet.width,bullet.height) then
					enemy.removed = true
					bullet.x = 1000
					score = score + 100
					playSound(enemyDestroySfx)
				end

				-- Collision checking (player)
				if checkCollision(enemy.x,enemy.y,enemy.width,enemy.height,player.x,player.y,player.width,player.height) then
					endGame()
				end
			else table.remove(enemies, i) end
		end

		-- Timer (1s)
		dtotal = dtotal + dt
		if dtotal >= 1 then
			dtotal = dtotal - 1

			-- Spawn an enemy
			newEnemy(500, love.math.random(20, 216))

			-- Add to score
			score = score + 10
		end
	end
end

function love.keypressed(key)
	-- Quit when escape is pressed
	if key == 'escape' then
		love.event.push('quit')
	end

	-- Space to start game or shoot
	if key == 'space' then
		if gamestate == 'title' then
			gamestate = 'play'
			startGame()
		elseif gamestate == 'play' then
			shootGun()
		elseif gamestate == 'dead' then
			gamestate = 'title'
		end
	end
end

function love.draw(dt)
	if gamestate == 'title' then
		-- Draw title screen
		love.graphics.clear()
		love.graphics.draw(logo, 58, 92, 0, 2, 2)
		love.graphics.printf('PRESS SPACE TO START', 0, 300, 320, 'center', 0, 2, 2)
		love.graphics.printf('A GAME BY ALEX ABBATIELLO'..string.char(10)..'@SYNTHIC 2019', 0, 410, 320, 'center', 0, 2, 2)
		love.graphics.print(version)
	else
		-- Set drawing target to canvas
		love.graphics.setCanvas(canvas)

		-- Clear previous drawing
		love.graphics.clear()

		-- Draw background
		love.graphics.draw(background, 0, 0)

		-- Draw score
		love.graphics.print('SCORE'..string.char(10)..math.floor(score))

		-- Animate player sprite
		local spriteNum = math.floor(animPlayer.currentTime / animPlayer.duration * #animPlayer.quads) + 1
		love.graphics.draw(animPlayer.spriteSheet, animPlayer.quads[spriteNum], player.x, player.y)

		-- Animate enemies
		for i=#enemies, 1, -1 do
			local enemy = enemies[i]

			local spriteNum = math.floor(animEnemy.currentTime / animEnemy.duration * #animEnemy.quads) + 1
			love.graphics.draw(animEnemy.spriteSheet, animEnemy.quads[spriteNum], enemy.x, enemy.y)
		end

		-- Draw projectiles
		love.graphics.draw(bullet.img, bullet.x, bullet.y)

		-- Set drawing target to window
		love.graphics.setCanvas()

		-- Draw full canvas and scale
		love.graphics.draw(canvas, 0, 0, 0, 2, 2)

		-- Draw game over screen
		if gamestate == 'dead' then
			love.graphics.setCanvas(canvas)
			love.graphics.setColor(0, 0, 0)
			love.graphics.rectangle('fill', 75, 85, 170, 55)
			love.graphics.setColor(255, 255, 255)
			love.graphics.printf('GAME OVER', 0, 100, 160, 'center', 0, 2, 2)
			love.graphics.setCanvas()
			love.graphics.draw(canvas, 0, 0, 0, 2, 2)
		end
	end
end

function newEnemy(x,y)
	local enemy = {}
	enemy.x = x
	enemy.y = y
	enemy.width = 24
	enemy.height = 24
	enemy.speed = love.math.random(100, 300)
	enemy.removed = false
	table.insert(enemies, enemy)
end

function startGame()
	-- Reset positions
	player.x = 40
	player.y = 40
	bullet.x = 1000

	-- Reset score
	score = 0

	-- Reset enemies
	enemies = {}

	-- Start music
	musicTrack:play()

	-- Spawn enemies
	for i=1,2 do
		newEnemy(500, love.math.random(20, 216))
	end
end

function endGame()
	-- Stop music
	musicTrack:stop()

	-- Play sound
	playSound(playerDestroySfx)

	-- Game over
	gamestate = 'dead'
end

function shootGun()
	-- Shoot if no projectile on screen
	if bullet.x > screen.width then
		bullet.x = player.x + player.width
		bullet.y = player.y + ((player.height / 2) - (bullet.height / 2))
		playSound(shootSfx)
	end
end

function playSound(sound)
	sound:stop()
	pitchMod = 0.8 + love.math.random(0, 10) / 25
	sound:setPitch(pitchMod)
	sound:play()
end

--[[
Create animation from sprite sheet
https://love2d.org/wiki/Tutorial:Animation
--]]
function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image
    animation.quads = {}

    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    animation.duration = duration or 1
    animation.currentTime = 0

    return animation
end

--[[
Collision detection function
https://love2d.org/wiki/BoundingBox.lua
--]]
function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
	return x1 < x2+w2 and
		   x2 < x1+w1 and
		   y1 < y2+h2 and
		   y2 < y1+h1
end
