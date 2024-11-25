require 'level1'

function love.load()
    
    --Sets fullscreen
    love.window.setFullscreen(true, "desktop")

    --love.window.setTitle('Level One')
    wf = require 'Libraries/windfield'
love.graphics.print("You Win!!!", 100, 100, 100, 100)
    
    -- in brackets (x -> y for gravity)
    world = wf.newWorld(0, 500)
    world:addCollisionClass('platform')
    world:addCollisionClass('playerClass')
    world:addCollisionClass('death')
    world:addCollisionClass('victory')

    -- loads camera
    camera = require 'Libraries/camera'
    cam = camera()

    -- loads map
    sti = require 'Libraries/sti'
    path = 'Maps/Map1.lua'
    gameMap = sti(path)

    -- loads sprite animation
    anim8 = require 'Libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- creates player
    player = {}
    player.sprite = love.graphics.newImage('Sprites/Square.png')
    player.collider = world:newRectangleCollider(16, 860, 32, 32)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('playerClass')
    player.is_on_ground = false
    player.is_hitting_wall_from_left = false
    player.is_hitting_wall_from_right = true
    player.is_finished = false
    player.x = 150
    player.y = 355

    local function custom_collision(collider_1, collider_2, contact)
        if collider_1.collision_class == 'playerClass' and collider_2.collision_class == 'platform' then
            -- check normal direction of the collision
            local nx, ny = contact:getNormal()
            
            if nx > 0 then
                player.is_hitting_wall_from_left = true
            elseif nx < 0 then
                player.is_hitting_wall_from_right = true
            elseif ny > 0 then
                player.is_on_ground = true
            end
        end
        if collider_1.collision_class == 'playerClass' and collider_2.collision_class == 'death' then
            love.event.quit('restart')
        end
        if collider_1.collision_class == 'playerClass' and collider_2.collision_class == 'victory' then
            local nx, ny = contact:getNormal()
            
            if  ny > 0 then
                player.is_on_ground = true
            end

            if player.is_on_ground == true then
                love.graphics.print("You Win!!!", 100, 100)
            end
        end
    end
    
    player.collider:setPreSolve(custom_collision)

    local w = gameMap.width * gameMap.tilewidth
    local h = gameMap.height * gameMap.tileheight
    tWallOne = world:newLineCollider(0, 8, w * 0.2, 8)
    tWallOne:setType('static')
    tWallTwo = world:newLineCollider(w * 0.2, 8, w * 0.6, 8)
    tWallTwo:setType('static')
    tWallTwo:setCollisionClass('death')
    tWallThree = world:newLineCollider(w * 0.6, 8, w * 0.9, 8)
    tWallThree:setType('static')
    tWallFour = world:newLineCollider(w * 0.9, 8, w, 8)
    tWallFour:setType('static')
    tWallFour:setCollisionClass('death')

    bWallOne = world:newLineCollider(0, h - 8, w * 0.8, h - 8)
    bWallOne:setType('static')
    bWallOne:setCollisionClass('death')
    bWallTwo = world:newRectangleCollider(w * 0.8, h - 8, 1000, 25)
    bWallTwo:setType('static')
    bWallTwo:setCollisionClass('platform')
    

    lWall = world:newLineCollider(8, 0, 8, h)
    lWall:setType('static')
    lWall:setCollisionClass('death')
    rWall = world:newLineCollider(w - 8, 0, w - 8, h)
    rWall:setType('static')
    rWall:setCollisionClass('death')

    walls = {}
    if gameMap.layers["Ground"] then
        for i, obj in pairs(gameMap.layers["Ground"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType('static')
            wall:setCollisionClass('platform')
            table.insert(walls, wall)
        end
    end

    deadwalls = {}
    if gameMap.layers["Death"] then
        for i, obj in pairs(gameMap.layers["Death"].objects) do
            local deadwall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            deadwall:setType('static')
            deadwall:setCollisionClass('death')
            table.insert(deadwalls, deadwall)
        end
    end

    vicwalls = {}
    if gameMap.layers["Victory"] then
        for i, obj in pairs(gameMap.layers["Victory"].objects) do
            local vicwall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            vicwall:setType('static')
            vicwall:setCollisionClass('victory')
            table.insert(vicwalls, vicwall)
        end
    end
end

function love.update(dt)
    player.is_on_ground = false
    player.is_hitting_wall_from_left = false
    player.is_hitting_wall_from_right = false
    world:update(dt)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    -- moves camera
    cam:lookAt(player.x, player.y)

    -- stop camera going over map
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    -- left border
    if cam.x < w/2 then
        cam.x = w/2
    end
    -- top border
    if cam.y < h/2 then
        cam.y = h/2
    end
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight
    -- right border
    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end
    -- bottom border
    if cam.y >(mapH - h/2) then
        cam.y = (mapH - h/2)
    end

    
end

function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Base (Ground)"])
        gameMap:drawLayer(gameMap.layers["Base (Death)"])
        gameMap:drawLayer(gameMap.layers["Base (Victory)"])
        love.graphics.draw(player.sprite, player.x - 16, player.y - 16, nil, 1)
        --world:draw()
    cam:detach()
end

function love.keypressed(key)
    --prevents player from moving too quickly
    local px, py = player.collider:getLinearVelocity()
    if (key == 'd' or key == 'right') and px > -300 and not player.is_hitting_wall_from_right then
        player.collider:applyLinearImpulse(600, 0)
    elseif (key == 'a' or key == 'left') and px < 300 and not player.is_hitting_wall_from_left then
        player.collider:applyLinearImpulse(-600, 0)
    end

    --jump
    if (key == 'w' or key == 'up' or key == 'space') and player.is_on_ground then 
        -- quick force pushing on collidor (-600 going up)
        player.collider:applyLinearImpulse(0, -600)
    end
end

function love.keyreleased(key)
    local px, py = player.collider:getLinearVelocity()

    if (key == 'a' or key == 'left') then
        player.collider:setLinearVelocity(0, py)
    end

    if (key == 'd' or key == 'right') then
        player.collider:setLinearVelocity(0, py)
    end
end