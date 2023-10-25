local M = {}
local dbg = require("dbg")
local textredux = require("textredux")
local socket = require("socket")

local keys = keys

local reduxstyle = require("textredux.core.style")

local constants = _SCINTILLA.constants
local indicator = textredux.core.indicator

-- Define a custom style based on a default style
reduxstyle.example_style1 = reduxstyle.number..{ underlined = true, bold = true }

indicator.RED_BOX = { style = constants.INDIC_BOX, fore = "#ff0000" }
indicator.BLUE_FILL = { style = constants.INDIC_ROUNDBOX, fore = "#0000ff" }
indicator.INDIC_COMPOSITIONTHICK = { style = constants.INDIC_COMPOSITIONTHICK }
indicator.INDIC_ROUNDBOX = { style = constants.INDIC_ROUNDBOX }

local CRLF = "\r\n"
local history = {}
local currentSelector = ""
local buffer_table = {}

-- Open a socket connection to the specified host and port
local function open_Socket(host, port)
    local client = assert(socket.connect(host, port))
    return client
end

-- Send a simple request (CRLF) to the specified host and port
local function send_Request(host, port, selector)
    local client = open_Socket(host, port)
    local success, errormsg = client:send(selector .. CRLF)
    if not success then
        -- Handle the error here
        print("Failed to send request: " .. errormsg)
    end
    return client
end

-- Get data from the connection to the specified host and port
local function get_Data(host, port, selector)
    local client = send_Request(host, port, selector)
    local data, errormsg = client:receive("*a")
    if not data then
        -- Handle the error here
        print("Failed to receive message: " .. errormsg)
        ui.dialogs.message {
            title = 'Error',
            text = 'Failed to receive message.\n' .. errormsg,
            icon = 'dialog-question',
            button1 = 'Ok'
        }
    else
        print("Succeeded!")
        addToHistory(host, port, selector)
        currentSelector = selector
    end

    return data
end

-- Split a string into lines based on a custom delimiter
local function split_Lines(str, po)
    local s_lines = {}
    local function helper(line)
        table.insert(s_lines, line)
        return ""
    end
    helper((str:gsub("(.-)\r?" .. po, helper)))
    return s_lines
end

-- Extract data from a string and organize it into a table
local function organize_Tables(temp_list)
    local manipulation = {}
    for i = 1, #temp_list do
        local lines = {}
        for line in string.gmatch(temp_list[i], "[^\t]+") do
            table.insert(lines, line)
        end
        manipulation[i] = lines
    end
    return manipulation
end

-- Retrieve data and store it in a final table
local function final_Table(host, port, selector)
    local data = get_Data(host, port, selector)
    f_tables_contents = organize_Tables(split_Lines(data, "\n"))
    return f_tables_contents
end

-- Add the request to the history
function addToHistory(host, port, selector)
    table.insert(history, { host, port, selector })
end

-- Navigate back to a previous page
function M.goBack()
    local buffer = buffer_table.local_buffer
    if buffer then
        buffer:clear_all()
        buffer:refresh()
        buffer:goto_pos(0)
    end
    if #history > 1 then
        -- Remove the most recent entry
        table.remove(history, #history)
        -- Get data from the new current page
        local lastIndex = #history
        if lastIndex > 0 then
            local entry = history[lastIndex]
            if entry and entry[3] ~= currentSelector then
                f_tables_contents = final_Table(entry[1], entry[2], entry[3])
                currentSelector = entry[3]
                buffer:refresh()
                buffer:goto_pos(0)
                return
            end
        else
            -- Navigate back to the root if possible
            currentSelector = "/"
            buffer:refresh()
            buffer:goto_pos(0)
        end
    end
end

-- Mapping tables for Gopher data types to readable descriptions
local types_symbols = {
	["i"] = "",
	["0"] = "🖹",
	["1"] = "🗀",
	["3"] = "❌",
	["5"] = "💾",
	["7"] = "🔍",
	["8"] = "🌐",
	["9"] = "📦",
	[""] =  "📁",
	["+"] = "🔄",
	["g"] = "🖼️",
	["I"] = "🖼️",
	["T"] = "🌐",
	[":"] = "🖼️",
	[";"] = "🎬",
	["<"] =	"🔊",
	["d"] = "📝",
	["h"] = "📄",
	["p"] = "🖼️",
	["r"] = "📃",
	["s"] = "🔊",
	["P"] = "📃",
}

-- Show an input to open a specific URL
function M.open_url()
    local button, url = ui.dialogs.inputbox{
        title = "Open URL:",
        text = "gopher.quux.org",
        button1 = "Go",
        button2 = "Cancel",
        icon = 'applications-internet'
    }

    if url == '' or url == nil then
        ui.dialogs.message{
            title = 'Error',
            text = 'Please enter a valid URL.',
            icon = 'dialog-error',
            button1 = 'Ok'
        }
    else
        f_tables_contents = final_Table(url, 70, '/')
        M.create_action_buffer()
    end
end

-- Function to display the "About" message
local function aboutMessage(buffer)
	local asciiArt = [[
    __  ____    ____  ______    ___  ____    ____ 
   /  ]|    \  /    T|      T  /  _]|    \  /    T
  /  / |  D  )Y  o  ||      | /  [_ |  D  )Y  o  |
 /  /  |    / |     |l_j  l_jY    _]|    / |     |
/   \_ |    \ |  _  |  |  |  |   [_ |    \ |  _  |
\     ||  .  Y|  |  |  |  |  |     T|  .  Y|  |  |
 \____jl__j\_jl__j__j  l__j  l_____jl__j\_jl__j__j
	]]
	buffer:add_text(asciiArt)
	buffer:add_text("\n\n")
	local start_pos = buffer.current_pos
	buffer:add_text("Welcome to Cratera 0.1\n\n")
	indicator.RED_BOX:apply(start_pos, buffer.current_pos - start_pos)
	buffer:add_text("This is just a ")
	buffer:add_text("prototype", nil, nil, indicator.BLUE_FILL)
	buffer:add_text(".\n\n")
	buffer:add_text("Shortcuts:\n\n", indicator.INDIC_BOX)
	buffer:add_text("Ctrl+Alt+g", indicator.INDIC_ROUNDBOX)
	buffer:add_text(" = Open a gopherhole address.\n")
	buffer:add_text("Ctrl+Alt+e", indicator.INDIC_ROUNDBOX)
	buffer:add_text(" = Explore a list of pre-included addresses.\n")
	buffer:add_text("Ctrl+Alt+b", indicator.INDIC_ROUNDBOX)
	buffer:add_text(" = Back.\n")
	buffer:add_text("Ctrl+Alt+s", indicator.INDIC_ROUNDBOX)
	buffer:add_text(" = Save the current buffer as a text file.\n")
	buffer:add_text("Ctrl+Alt+a", indicator.INDIC_ROUNDBOX)
	buffer:add_text(" = Show the About message.\n")
	buffer:add_text("Ctrl+Alt+k", indicator.INDIC_ROUNDBOX)
	buffer:add_text(" = Closes the buffer.\n\n")
	buffer:add_text("Controls:\n\n", indicator.INDIC_BOX)
	buffer:add_text("You can move around with your arrow keys and use the Enter key to select items.\n")
	buffer:add_text("Some Vi keys are supported as well.\n\n")
	buffer:add_text("You can read more about it on the Github page.")
	buffer:add_text("\nhttps://github.com/manipuladordedados/cratera", indicator.INDIC_COMPOSITIONTHICK)
end

-- Callback function for handling list item selection
local function on_selection(list, item)
    f_tables_contents = final_Table(item[2], 70, '/')
    M.create_action_buffer()
end

-- Show a multi-column list for exploration
function M.show_multi_column_list()
    local list = textredux.core.list.new('Explore freely')
    list.items = {
        {'SDF', 'sdf.org', id = 1},
        {'Quux', 'quux.org', id = 2},
        {'Floodgap', 'floodgap.com', id = 3}
    }
    list.column_styles = {reduxstyle.number, reduxstyle.operator}
    list.on_selection = on_selection
    list:show()
end

-- Show the "About" buffer
function M.about_buffer()
    local buffer = textredux.core.buffer.new("About Cratera")
    buffer.on_refresh = aboutMessage
    buffer:show()
end

-- Close buffer
function M.close_buffer()
	if buffer._textredux then
		buffer:close()
	end
end

-- Add the Cratera menu to the menubar
local menubar = textadept.menu.menubar
for i = 1, #menubar do
    if menubar[i].title ~= _L['View'] then
        goto continue
    end
    local cratera_menu = {
        title = _L['Cratera'],
        { _L['Open URL'], M.open_url },
        { _L['Explore'], M.show_multi_column_list },
        { '' },
        { _L['Go Back...'], M.goBack },
        { _L['Close'], M.close_buffer },
        { '' },
        { _L['About Cratera'], M.about_buffer },
    }
    table.insert(menubar, i + 1, cratera_menu)
    keys['ctrl+alt+g'] = textadept.menu.menubar['Cratera/Open URL'][2]
    keys['ctrl+alt+e'] = textadept.menu.menubar['Cratera/Explore'][2]
    keys['ctrl+alt+b'] = textadept.menu.menubar['Cratera/Go Back...'][2]
    keys['ctrl+alt+k'] = textadept.menu.menubar['Cratera/Close'][2]
    keys['ctrl+alt+a'] = textadept.menu.menubar['Cratera/About Cratera'][2]
    break
    ::continue::
end

-- Callback function for refreshing the action buffer
local function on_refresh(buffer)
	if string.sub(currentSelector, -4) == ".txt" or f_tables_contents[1][2] == nil then
		for i = 1, #f_tables_contents do
			buffer:add_text(tostring(f_tables_contents[i][1]):gsub("nil", "") .. "\n")
		end
	else
		for i = 1, #f_tables_contents do
			if f_tables_contents[i][1] == nil or string.sub(f_tables_contents[i][1], 1) == "" or string.sub(f_tables_contents[i][1], 1) == "." then
				break
			end
			if string.sub(f_tables_contents[i][1], 1, 1) == "i" then
				buffer:add_text(types_symbols[string.sub(f_tables_contents[i][1], 1, 1)] .. " " .. string.sub(f_tables_contents[i][1], 2))
				buffer:add_text("\n")
			else
				buffer:add_text(types_symbols[string.sub(f_tables_contents[i][1], 1, 1)] .. " " .. string.sub(f_tables_contents[i][1], 2), reduxstyle.example_style1)
				buffer:add_text("\n")
			end
		end
	end
end

-- Create the action buffer
function M.create_action_buffer()
    local buffer = textredux.core.buffer.new("Cratera")
    buffer_table.local_buffer = buffer
    buffer.on_refresh = on_refresh

    -- Navigation with j and k keys (similar to Vim) in Textredux
    keys['j'] = function()
        if buffer._textredux then
            buffer:line_down()
        end
    end, { repeatable = true }

    keys['k'] = function()
        if buffer._textredux then
            buffer:line_up()
        end
    end, { repeatable = true }
	
	-- Handle the 'Return' keypress event in the buffer
    buffer.keys['\n'] = function()
        local line_number = buffer:line_from_position(buffer.current_pos)
        if buffer._textredux then
            if string.sub(f_tables_contents[line_number][1], 1, 1) == "1" or string.sub(f_tables_contents[line_number][1], 1, 1) == "0" then
                f_tables_contents = final_Table(f_tables_contents[line_number][3], f_tables_contents[line_number][4], f_tables_contents[line_number][2])
                buffer:refresh()
                buffer:goto_pos(0)
			else
				return
			end
		end
	end
	
	buffer:show()
	buffer:goto_pos(0)
end

return M
