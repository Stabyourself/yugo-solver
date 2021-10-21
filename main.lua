function love.load()
    fieldStrings = {
        "#################",
        "#               #",
        "#               #",
        "#           1   #",
        "#           ##  #",
        "#               #",
        "#  23   3     2 #",
        "######1 ## ######",
        "#################"
    }
    -- fieldStrings = {
    --     "###############",
    --     "#             #",
    --     "#             #",
    --     "#    #        #",
    --     "#             #",
    --     "#   2         #",
    --     "#   11     #  #",
    --     "#2# ####  #####",
    --     "######## ######",
    --     "###############",
    -- }
    -- fieldStrings = {
    --     "###############",
    --     "#             #",
    --     "#    3        #",
    --     "#    #        #",
    --     "#             #",
    --     "#1   2        #",
    --     "##   1     #2 #",
    --     "########  #####",
    --     "######## ######",
    --     "###############",
    -- }
    fieldStrings = {
        "#################",
        "#               #",
        "#    3          #",
        "#    #          #",
        "#               #",
        "#           2   #",
        "#          331  #",
        "####   ### ######",
        "#####12##########",
        "#################",
    }

    -- convert to table
    field = {}
    numJellies = 0

    for x = 1, #fieldStrings[1] do
        field[x] = {}

        for y = 1, #fieldStrings do
            local c = string.sub(fieldStrings[y], x, x)
            field[x][y] = c

            if tonumber(c) and tonumber(c) > numJellies then
                numJellies = tonumber(c)
            end
        end
    end

    printField(field)

    hashes = {}
    depths = {
        {
            parent = nil,
            field = field,
        }
    }

    displayStep = 1
    victorySteps = nil

    -- local objects = findObjects(field)
    -- processStep(field, objects, 3, -1)

    -- printField(field)
end


function work()
    local depthCount = #depths

    print("Current nodes/possible states: " .. depthCount .. "/" .. #hashes)

    for i = 1, depthCount do
        if processDepth(depths[i]) then
            printField(depths[i].field)
            return depths[i]
        end
    end

    for i = depthCount, 1, -1 do
        table.remove(depths, i)
    end
end

function processDepth(depth)
    local newHash = hashField(depth.field)

    for _, pastHash in ipairs(hashes) do
        if newHash == pastHash then
            return
        end
    end

    table.insert(hashes, newHash)

    local objects = findObjects(depth.field)
    -- check for victory
    if #objects == numJellies then
        return true
    end

    for i = 1, #objects do
        for xdir = -1, 1, 2 do
            local fieldCopy = copyField(depth.field)
            local objectsCopy = findObjects(fieldCopy)

            if processStep(fieldCopy, objectsCopy, i, xdir) then
                table.insert(depths, {
                    parent = depth,
                    field = fieldCopy,
                })
            end
        end
    end
end

function copyField(field)
    local newField = {}

    for x = 1, #field do
        newField[x] = {}
        for y = 1, #field[x] do
            newField[x][y] = field[x][y]
        end
    end

    return newField
end

function printField(field)
    for y = 1, #field[1] do
        local out = ""
        for x = 1, #field do
            out = out .. field[x][y]
        end
        print(out)
    end
end

function findObjects(field)
    local objects = {}

    for x = 1, #field do
        for y = 1, #field[x] do
            local c = field[x][y]

            if c ~= "#" and c ~= " " then
                -- not already part of an object
                local valid = true

                for _, object in ipairs(objects) do
                    for _, square in ipairs(object) do
                        if square.x == x and square.y == y then
                            valid = false
                        end
                    end
                end

                if valid then
                    -- find connected jelly
                    local object = {}
                    local traverseTable = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

                    function traverse(needle, x, y)
                        if field[x][y] == needle then
                            table.insert(object, {x=x, y=y})

                            for _, step in ipairs(traverseTable) do
                                local newX = x + step[1]
                                local newY = y + step[2]

                                local found = false
                                for _, square in ipairs(object) do
                                    if square.x == newX and square.y == newY then
                                        found = true
                                        break
                                    end
                                end

                                if not found then
                                    traverse(needle, newX, newY)
                                end
                            end
                        end
                    end

                    traverse(c, x, y)

                    table.insert(objects, object)
                end
            end
        end
    end

    return objects
end

function processStep(field, objects, moveId, dir)
    -- move the object
    local allowMove = true
    for _, square in ipairs(objects[moveId]) do
        local newX = square.x + dir

        if field[newX][square.y] ~= " " and field[newX][square.y] ~= field[square.x][square.y] then
            allowMove = false
            break
        end
    end

    if not allowMove then
        return false
    end

    field, objects[moveId] = moveObject(field, objects[moveId], dir, 0)

    -- gravity
    for i, object in ipairs(objects) do
        repeat
            local fell = false
            local floating = true

            for _, square in ipairs(objects[i]) do
                if field[square.x][square.y+1] ~= " " then
                    floating = false
                    break
                end
            end

            if floating then
                field, objects[i] = moveObject(field, objects[i], 0, 1)

                fell = true
            end
        until fell == false
    end

    return field
end

function moveObject(field, object, xdir, ydir)
    local c = field[object[1].x][object[1].y]
    for i, square in ipairs(object) do
        field[square.x][square.y] = " "

        object[i].x = object[i].x + xdir
        object[i].y = object[i].y + ydir
    end

    for i, square in ipairs(object) do
        field[square.x][square.y] = c
    end

    return field, object
end

function hashField(field)
    local out = ""
    for x = 1, #field do
        out = out .. table.concat(field[x])
    end

    return out
end



function love.update(dt)
    if not victoryDepth then
        victoryDepth = work()

        if victoryDepth then
            victorySteps = {}
            local depth = victoryDepth

            repeat
                table.insert(victorySteps, 1, depth)

                depth = depth.parent
            until not depth
        end
    end
end

function love.draw()
    if not victoryDepth then
        love.graphics.print("Doing dumb bruteforce stuff lmao gimme a sec")
    else
        love.graphics.print("EZ clap")

        local field = victorySteps[displayStep].field

        for y = 1, #field[1] do
            for x = 1, #field do
                love.graphics.print(field[x][y], 10 + (x-1)*20, 40 + (y-1)*20)
            end
        end
    end
end

function love.keypressed(key)
    if key == "right" then
        displayStep = math.min(#victorySteps, displayStep+1)
    elseif key == "left" then
        displayStep = math.max(1, displayStep-1)
    end
end