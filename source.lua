-- GitHub: JoshSCF/shift-enter-fix

local dodgyCharacter = string.char(226)

local function recurse(object)
	-- check if script and handle any changes to source
	pcall(function()
		if object:IsA("LuaSourceContainer") then
			local canModify = true
			
			object:GetPropertyChangedSignal("Source"):Connect(function()
				-- ignore if script is already being modified by plugin
				if not canModify then return end
				
				local source = object.Source
				local newSource = ""
				local lineNumber
				
				-- iterate through lines in source, rewrite & remove dodgy chars if found
				for line, code in pairs(source:split("\n")) do
					if code:find(dodgyCharacter) then
						local charPosition = code:find(dodgyCharacter)
						lineNumber = line + 1
						newSource = newSource
							.. code:sub(1, charPosition - 1)
							.. "\n"
							.. code:sub(charPosition):gsub("[^%z\1-\127]", "")
							.. "\n"
					else
						newSource = newSource .. code .. "\n"
					end
				end
				
				-- if line number modified, update script and move user to line number
				if lineNumber then
					canModify = false
					object.Source = newSource:sub(1, -2)
					plugin:OpenScript(object, lineNumber)
					canModify = true
				end
			end)
			
		end
	end)
	
	-- handle children and any that are added
	pcall(function()
		for _, child in pairs(object:GetChildren()) do
			recurse(child)
		end
	end)
	
	pcall(function()
		object.ChildAdded:Connect(function(child)
			recurse(child)
		end)
	end)
end

-- start recursing through children of game to find scripts
for _, object in pairs(game:GetChildren()) do
	recurse(object)
end
