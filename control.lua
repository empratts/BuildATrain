itemTotals = {} --holds the text fields for the item totals
itemBuffers = {} --holds the text fields for the item buffer amounts
fuelTypes = {"Wood", "Coal", "Solid fuel", "Rocket fuel", "Nuclear fuel"}
fuelPrototypeNames = {"wood", "coal", "solid-fuel", "rocket-fuel", "nuclear-fuel"}
fuelSelector = {} --holds the drop-down for the fuel type selector
fuelBuffer = {} --holds the text field for the fuel quantity buffer

function dump(o)
    if type(o) == 'table' then
       local s = '{'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..']=' .. dump(v) .. ','
       end
       return s .. '} '
    else
        if type(o) == 'number' then
            return tostring(o)
        else
            return '"'..tostring(o)..'"'
        end
    end
 end


function getRemainingCapacity(car)
    local capacity = 40
    if car == nil then
        return capacity
    end

    for _, size in pairs(car) do
        capacity = capacity - size[2]
    end

    return capacity
end

function findCarForItem(cars, v)
    local newCar = 1
    for i, car in pairs(cars) do
        if getRemainingCapacity(car) >= v[2] then
            return i
        end
        newCar = newCar + 1
    end
    return newCar
end

function splitItemsIntoCars(items)
    
    local cars = {}
    for _, v in pairs(items) do
        if v[2] > 40 then
            return nil
        end
        local car = findCarForItem(cars, v)
        if cars[car] == nil then
            cars[car] = {}
        end
        table.insert(cars[car], 1, v)
    end

    return cars
end

function getRequestFiltersFromCars(cars)

    local chests = {}
    for i, car in pairs(cars) do
        local requests = {}
        for j, item in pairs(car) do
            local request = {["index"]=j,["name"]=item[1],["count"]=item[4]}
            table.insert(requests,j,request)
        end
        table.insert(chests, i, requests)
    end
    return chests
end

function getCombinatorSettingsFromCars(cars)

    local combinators = {}
    for i, car in pairs(cars) do
        local signals = {}
        for j, item in pairs(car) do
            local signal = {["signal"]={["type"]="item",["name"]=item[1],},["count"]=item[3],["index"]=j}
            table.insert(signals,j,signal)
        end
        table.insert(combinators, i, signals)
    end
    return combinators
end

function getCursorBPItemCount(player)
    local bpItems = {}
    local itemCount = 0
    local bpItem = ""
    if player.is_cursor_blueprint() then
        local bpEntities = player.get_blueprint_entities()

        --player.print(dump(bpEntities))
        --player.print(serpent.block(bpEntities))
        --game.write_file("bat_log.log", serpent.block(bpEntities))
        --table.save(bpEntities, "bat_log.log")
        game.write_file("bat_log.log", dump(bpEntities).."\n")
        
        local name = ""
        local count = 0
        local subCount

        if bpEntities ~= nil then
            for _, bpItem in pairs(bpEntities) do
                name = bpItem.name
                count = 1
                subCount = 0
                if name == "curved-rail" then
                    name = "rail"
                    count = 4
                else 
                    if name == "straight-rail" then
                        name = "rail"
                    end
                end

                if bpItems[name] == nil then
                    bpItems[name] = count
                else
                    bpItems[name] = bpItems[name] + count
                end
                --sub items are the modules/fuel that the entity will request on being placed
                local subItems = bpItem.items

                if subItems ~= nil then
                    for name, subCount in pairs(subItems) do
                        if bpItems[name] == nil then
                            bpItems[name] = subCount
                        else
                            bpItems[name] = bpItems[name] + subCount
                        end
                    end
                end

                itemCount = itemCount + count + subCount
            end
        end

        if player.cursor_stack.valid_for_read then
            local bpTiles = player.cursor_stack.get_blueprint_tiles()
            if bpTiles ~= nil then
                for _, bpItem in pairs(bpTiles) do
                    name = bpItem.name
                    count = 1

                    if bpItems[name] == nil then
                        bpItems[name] = count
                    else
                        bpItems[name] = bpItems[name] + count
                    end
                    itemCount = itemCount + count
                end
            end
        else
            player.print("Blueprints from the library will not properly import tiles. To have tiles (including landfill) counted correctly, please copy the blueprint to the player inventory")
        end
    end
    return bpItems, itemCount
end

function generateBP(carCount, itemRequests, combinatorSettings, fuelType, fuelCount)
    local blueprint = {
        [1]={["entity_number"]=1,["name"]="locomotive",["position"]={["x"]=6,["y"]=1,},["orientation"]=0.75,["schedule"]={[1]={["station"]="BAT_MassBuild_Loading",["wait_conditions"]={[1]={["compare_type"]="or",["type"]="item_count",["condition"]={["first_signal"]={["type"]="item",["name"]="fast-inserter",},["constant"]=25,["comparator"]="≥",},},[2]={["compare_type"]="and",["type"]="item_count",["condition"]={["first_signal"]={["type"]="item",["name"]="big-electric-pole",},["constant"]=19,["comparator"]="≥",},},[3]={["compare_type"]="and",["type"]="inactivity",["ticks"]=300,},},},},},
        [2]={["entity_number"]=2,["name"]="logistic-chest-requester",["position"]={["x"]=8.5,["y"]=-1.5,},["request_filters"]={{["index"]=1,["name"]=fuelType,["count"]=fuelCount},},},
        [3]={["entity_number"]=3,["name"]="train-stop",["position"]={["x"]=3,["y"]=-1,},["direction"]=6,["control_behavior"]={["send_to_train"]="false",["read_from_train"]="true",["read_stopped_train"]="true",["train_stopped_signal"]={["type"]="virtual",["name"]="signal-T",},}, ["connections"]={["1"]={["red"]={[1]={["entity_id"]=14,},},["green"]={[1]={["entity_id"]=4,["circuit_id"]=1,},},},}, ["station"]="BAT_MassBuild_Loading",["manual_trains_limit"]=1,},
        [4]={["entity_number"]=4,["name"]="decider-combinator",["position"]={["x"]=5,["y"]=-0.5,},["direction"]=2,["control_behavior"]={["decider_conditions"]={["first_signal"]={["type"]="virtual",["name"]="signal-T",},["constant"]=0,["comparator"]="≠",["output_signal"]={["type"]="virtual",["name"]="signal-T",},["copy_count_from_input"]="true",},},["connections"]={["1"]={["green"]={[1]={["entity_id"]=3,},},},["2"]={["green"]={[1]={["entity_id"]=5,["circuit_id"]=1,},},},},},
        [5]={["entity_number"]=5,["name"]="decider-combinator",["position"]={["x"]=7,["y"]=-0.5,},["direction"]=2,["control_behavior"]={["decider_conditions"]={["first_signal"]={["type"]="virtual",["name"]="signal-T",},["constant"]=0,["comparator"]="≠",["output_signal"]={["type"]="virtual",["name"]="signal-T",},["copy_count_from_input"]="true",},},["connections"]={["1"]={["green"]={[1]={["entity_id"]=4,["circuit_id"]=2,},},},["2"]={["green"]={[1]={["entity_id"]=14,},},},},},
        [6]={["entity_number"]=6,["name"]="rail-signal",["position"]={["x"]=1.5,["y"]=-0.5,},["direction"]=2,},
        [7]={["entity_number"]=7,["name"]="fast-inserter",["position"]={["x"]=8.5,["y"]=-0.5,},},
        [8]={["entity_number"]=8,["name"]="straight-rail",["position"]={["x"]=1,["y"]=1,},["direction"]=2,},
        [9]={["entity_number"]=9,["name"]="straight-rail",["position"]={["x"]=3,["y"]=1,},["direction"]=2,},
        [10]={["entity_number"]=10,["name"]="straight-rail",["position"]={["x"]=5,["y"]=1,},["direction"]=2,},
        [11]={["entity_number"]=11,["name"]="straight-rail",["position"]={["x"]=6,["y"]=1,},["direction"]=2,},
        [12]={["entity_number"]=12,["name"]="straight-rail",["position"]={["x"]=9,["y"]=1,},["direction"]=2,},
        [13]={["entity_number"]=13,["name"]="medium-electric-pole",["position"]={["x"]=4.5,["y"]=-1.5,},["neighbours"]={[1]=14,},},
        [14]={["entity_number"]=14,["name"]="medium-electric-pole",["position"]={["x"]=9.5,["y"]=-1.5,},["connections"]={["1"]={["red"]={[1]={["entity_id"]=18,["circuit_id"]=1,},[2]={["entity_id"]=27,}, [3]={["entity_id"]=3,},},["green"]={[1]={["entity_id"]=5,["circuit_id"]=2,},[2]={["entity_id"]=19,["circuit_id"]=1,},[3]={["entity_id"]=27,},},},},["neighbours"]={[1]=13,[2]=27,},},
    }
    
    local xOffset = 0
    local entityOffset = 0

    for i = 1, carCount do
        xOffset = 3 + 7 * i
        entityOffset = 1 + 13 * i
        
        blueprint[entityOffset+1]={["entity_number"]=entityOffset+1,["name"]="constant-combinator",["position"]={["x"]=xOffset+0.5,["y"]=-1.5,},["control_behavior"]={["filters"]=combinatorSettings[i]}, ["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset+3,["circuit_id"]=1,},[2]={["entity_id"]=entityOffset+4,["circuit_id"]=2,},},},},}
        blueprint[entityOffset+2]={["entity_number"]=entityOffset+2,["name"]="logistic-chest-requester",["position"]={["x"]=xOffset+5.5,["y"]=-1.5,},["request_filters"]=itemRequests[i],}
        blueprint[entityOffset+3]={["entity_number"]=entityOffset+3,["name"]="decider-combinator",["position"]={["x"]=xOffset+1.5,["y"]=-1,},["direction"]=4,["control_behavior"]={["decider_conditions"]={["first_signal"]={["type"]="virtual",["name"]="signal-anything",},["constant"]=0,["comparator"]=">",["output_signal"]={["type"]="virtual",["name"]="signal-anything",},["copy_count_from_input"]="true",},},["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset+1,},},},["2"]={["red"]={[1]={["entity_id"]=entityOffset+5,["circuit_id"]=1,},[2]={["entity_id"]=entityOffset+6,["circuit_id"]=1,},},},},}
        blueprint[entityOffset+4]={["entity_number"]=entityOffset+4,["name"]="arithmetic-combinator",["position"]={["x"]=xOffset+2.5,["y"]=-1,},["control_behavior"]={["arithmetic_conditions"]={["first_signal"]={["type"]="virtual",["name"]="signal-each",},["second_constant"]=-1,["operation"]="*",["output_signal"]={["type"]="virtual",["name"]="signal-each",},},},["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset,},},},["2"]={["red"]={[1]={["entity_id"]=entityOffset+1,},},},},}
        blueprint[entityOffset+5]={["entity_number"]=entityOffset+5,["name"]="decider-combinator",["position"]={["x"]=xOffset+3.5,["y"]=-1,},["direction"]=4,["control_behavior"]={["decider_conditions"]={["first_signal"]={["type"]="virtual",["name"]="signal-T",},["constant"]=0,["comparator"]="≠",["output_signal"]={["type"]="virtual",["name"]="signal-everything",},["copy_count_from_input"]="true",},},["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset+3,["circuit_id"]=2,},},["green"]={[1]={["entity_id"]=entityOffset,},},},["2"]={["red"]={[1]={["entity_id"]=entityOffset+12,},},},},}
        blueprint[entityOffset+6]={["entity_number"]=entityOffset+6,["name"]="arithmetic-combinator",["position"]={["x"]=xOffset+4.5,["y"]=-1,},["direction"]=4,["control_behavior"]={["arithmetic_conditions"]={["first_signal"]={["type"]="virtual",["name"]="signal-each",},["second_constant"]=1,["operation"]="*",["output_signal"]={["type"]="virtual",["name"]="signal-I",},},},["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset+3,["circuit_id"]=2,},},},["2"]={["red"]={[1]={["entity_id"]=entityOffset+12,},},},},}
        blueprint[entityOffset+7]={["entity_number"]=entityOffset+7,["name"]="cargo-wagon",["position"]={["x"]=xOffset+3,["y"]=1,},["orientation"]=0.25,}
        
        if i % 2 == 1 then
            --odd cars get 4 peices of rail
            blueprint[entityOffset+8]={["entity_number"]=entityOffset+8,["name"]="straight-rail",["position"]={["x"]=xOffset+1,["y"]=1,},["direction"]=2,}
            blueprint[entityOffset+9]={["entity_number"]=entityOffset+9,["name"]="straight-rail",["position"]={["x"]=xOffset+3,["y"]=1,},["direction"]=2,}
            blueprint[entityOffset+10]={["entity_number"]=entityOffset+10,["name"]="straight-rail",["position"]={["x"]=xOffset+5,["y"]=1,},["direction"]=2,}
            blueprint[entityOffset+11]={["entity_number"]=entityOffset+11,["name"]="straight-rail",["position"]={["x"]=xOffset+7,["y"]=1,},["direction"]=2,}
            
        else
            --even cars get 3 peices of rail
            blueprint[entityOffset+8]={["entity_number"]=entityOffset+8,["name"]="straight-rail",["position"]={["x"]=xOffset+2,["y"]=1,},["direction"]=2,}
            blueprint[entityOffset+9]={["entity_number"]=entityOffset+9,["name"]="straight-rail",["position"]={["x"]=xOffset+4,["y"]=1,},["direction"]=2,}
            blueprint[entityOffset+10]={["entity_number"]=entityOffset+10,["name"]="straight-rail",["position"]={["x"]=xOffset+6,["y"]=1,},["direction"]=2,}
        end

        blueprint[entityOffset+12]={["entity_number"]=entityOffset+12,["name"]="stack-filter-inserter",["position"]={["x"]=xOffset+5.5,["y"]=-0.5,},["control_behavior"]={["circuit_mode_of_operation"]=1,["circuit_set_stack_size"]="true",["stack_control_input_signal"]={["type"]="virtual",["name"]="signal-I",},},["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset+5,["circuit_id"]=2,},[2]={["entity_id"]=entityOffset+6,["circuit_id"]=2,},},},},}
        blueprint[entityOffset+13]={["entity_number"]=entityOffset+13,["name"]="medium-electric-pole",["position"]={["x"]=xOffset+6.5,["y"]=-1.5,},["connections"]={["1"]={["red"]={[1]={["entity_id"]=entityOffset,},},["green"]={[1]={["entity_id"]=entityOffset,},},},},["neighbours"]={[1]=entityOffset,},}

    end

    blueprint[2+13*(carCount+1)]={["entity_number"]=2+13*(carCount+1),["name"]="rail-signal",["position"]={["x"]=9.5+7*carCount,["y"]=-0.5,},["direction"]=2,}
    
    return blueprint
end

function generateSubScreenFromBPItems(player, bpItems)
    local screen_element = player.gui.screen
    if screen_element.bat_sub_frame ~= nil then
        --close the previous sub frame if it is already open
        screen_element.bat_sub_frame.destroy()
    end
    if screen_element.bat_sub_frame == nil then
        local sub_frame = screen_element.add{type="frame", name="bat_sub_frame", caption={"bat.sub_window_title"}}

        local sub_content_frame = sub_frame.add{type="frame", name="bat_sub_content_frame", direction="vertical", style="bat_content_frame"}
        --TODO: Add the header flow here
        local sub_scroll_pane = sub_content_frame.add{type="scroll-pane", name="bat_sub_scroll_pane", direction="vertical", style="bat_scroll_pane"}

        itemTotals = {}
        itemBuffers = {}
        
        for k, v in pairs(bpItems) do
            local sub_content_flow = sub_scroll_pane.add{type="flow", name="bat_controls_flow_"..k, direction="horizontal", style="bat_content_flow"}
            local stack_size = 0
            if game.item_prototypes[k] ~= nil then
               stack_size = game.item_prototypes[k].stack_size
            end
            sub_content_flow.add{type="sprite-button", sprite=("item/" .. k), style="recipe_slot_button"}
            local label_flow = sub_content_flow.add{type="flow", direction="horizontal", style="bat_label_flow"}
            label_flow.add{type="label", name="bat_label"..k, caption={"bat.contains", k, tostring(v), stack_size}}
            itemTotals[k] = sub_content_flow.add{type="textfield", name="bat_controls_quantity_"..k, text=tostring(v), numeric=true, allow_decimal=false, allow_negative=false, style="bat_content_textfield"}
            local buffered_amount = math.min(v, stack_size)
            itemBuffers[k] = sub_content_flow.add{type="textfield", name="bat_controls_buffer_"..k, text=tostring(buffered_amount), numeric=true, allow_decimal=false, allow_negative=false, style="bat_content_textfield"}
        end

        sub_content_frame.add{type="line"}

        local sub_fuel_flow = sub_content_frame.add{type="flow", name="fuel", direction="horizontal", style="bat_content_flow"}
        sub_fuel_flow.add{type="label", caption="Power trains with:"}
        fuelSelector = sub_fuel_flow.add{type="drop-down", name="bat_fuel_list", items=fuelTypes, selected_index=5}
        sub_fuel_flow.add{type="label", caption="Fuel buffer:"}
        fuelBuffer = sub_fuel_flow.add{type="textfield", name="bat_fuel_buffer", text="3", numeric=true, allow_decimal=false, allow_negative=false, style="bat_content_textfield"}

        sub_content_frame.add{type="line"}

        local sub_close_flow = sub_content_frame.add{type="flow", name="close", direction="horizontal", style="bat_content_flow"}
        sub_close_flow.add{type="button", name="bat_close_sub_frame", caption={"bat.close"}}
        local sub_go_flow = sub_close_flow.add{type="flow", name="close", direction="horizontal", style="bat_go_flow"}
        sub_go_flow.add{type="button", name="bat_go", caption={"bat.go"}}
    end
end

script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then  -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
    end
    global.batTempBPInventory = game.create_inventory(1)
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)


    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="bat_main_frame", caption={"bat.main_window_title"}}
    main_frame.style.size = {350, 165}

    local main_content_frame = main_frame.add{type="frame", name="main_content_frame", direction="vertical", style="bat_content_frame"}
    local main_content_flow = main_content_frame.add{type="flow", name="main_content_flow", direction="horizontal", style="bat_content_flow"}

    main_content_flow.add{type="button", name="bat_main_activate", caption={"bat.activate"}}
    main_content_flow.add{type="button", name="bat_main_reload", caption="Reload"}

end)

script.on_event(defines.events.on_gui_click, function(event)
    --event handler for the actiavte button on the main frame
    if event.element.name == "bat_main_activate" then
        local player = game.get_player(event.player_index)

        local bpItems = {}
        local bpItemCount = 0

        bpItems, bpItemCount = getCursorBPItemCount(player)
        
        if bpItemCount > 0 then
            generateSubScreenFromBPItems(player, bpItems)
        else
            player.print("Item is not a Bluerprint, or Blueprint is empty.")
        end

    elseif event.element.name == "bat_main_reload" then
        local player = game.get_player(event.player_index)
        player.print("Reloading")
        
        game.reload_mods()
    
    --event handler for the close button on the sub-frame
    elseif event.element.name == "bat_close_sub_frame" then
        local player = game.get_player(event.player_index)
        local screen_element = player.gui.screen

        if screen_element.bat_sub_frame ~= nil then
            screen_element.bat_sub_frame.destroy() 
        end

    elseif event.element.name == "bat_go" then
        local player = game.get_player(event.player_index)
        local screen_element = player.gui.screen
        local itemsSortedByStackSize = {}
        local totalStackSize = 0
        
        if player.is_cursor_empty() then
            if itemTotals ~= nil then
                for k, v in pairs(itemTotals) do
                    local stackCount = math.ceil(tonumber(v.text) / game.item_prototypes[k].stack_size)
                    local i = 0
                    while true do
                        i = i + 1
                        if itemsSortedByStackSize[i] == nil or itemsSortedByStackSize[i][2] <= stackCount then
                            table.insert(itemsSortedByStackSize, i, {k, stackCount, tonumber(v.text), tonumber(itemBuffers[k].text)})
                            totalStackSize = totalStackSize + stackCount
                            break
                        end
                    end
                end
                --player.print(dump(itemsSortedByStackSize))
                --player.print("For ".. totalStackSize .. " stacks, ".. tostring(math.ceil(totalStackSize /40)).." minimum train cars are needed")
            end

            local cars = splitItemsIntoCars(itemsSortedByStackSize)
            local carCount = #cars
            --player.print(dump(cars).." with a total of "..carCount.." cars")

            local itemRequests = getRequestFiltersFromCars(cars)
            local combinatorSettings = getCombinatorSettingsFromCars(cars)

            local fuelType = fuelPrototypeNames[fuelSelector.selected_index]
            local fuelCount = tonumber(fuelBuffer.text)

            local stack = global.batTempBPInventory[1]
            stack.set_stack("blueprint")

            stack.set_blueprint_entities(generateBP(carCount, itemRequests, combinatorSettings, fuelType, fuelCount))


            player.cursor_stack.set_stack(stack)
            
            if screen_element.bat_sub_frame ~= nil then
                screen_element.bat_sub_frame.destroy()
            end
            player.print("Went")
        else
            player.print("Cursor must be empty before creating a new blueprint")
        end
        
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if event.element.name == "bat_fuel_list" then
        if fuelSelector.selected_index >= 4 then
            fuelBuffer.text = "3"
        else
            fuelBuffer.text = "50"
        end
    end

end)