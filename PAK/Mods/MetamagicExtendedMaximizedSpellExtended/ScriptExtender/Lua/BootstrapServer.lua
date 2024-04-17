debugMode = false

local function getMaximizedDiceRoll(rollObject)
	local damageDiceCount = rollObject.AmountOfDices
	local damageDiceType = rollObject.DiceValue
	local damageDiceSides = tonumber(string.sub(tostring(damageDiceType), 2))
	local maxRoll = damageDiceCount * damageDiceSides
	
	if (debugMode) then
		print('-- getMaximizedDiceRoll')
		print('Damage dice count:', damageDiceCount)
		print('Damage dice type:', damageDiceType)
		print('Damage dice sides:', damageDiceSides)
		print('Max roll:', maxRoll)
	end
	
	return maxRoll
end

--- Maximizes the damage based on the damage dice type and count
local function MaximizeDamage(e)
	local conditionRollParams = e.Hit.Results.ConditionRoll.RollParams[1]
	local originalNaturalRoll = conditionRollParams.Result.NaturalRoll
	local originalTotalRoll = conditionRollParams.Result.Total

	-- Adjust damage roll
	local maximizedRoll = getMaximizedDiceRoll(conditionRollParams.Roll.Roll)
	local damageOffset = maximizedRoll - originalTotalRoll
	conditionRollParams.Result.NaturalRoll = maximizedRoll
	conditionRollParams.Result.Total = maximizedRoll
	
	-- Adjust damage modifier rolls
	for _, modifier in pairs(e.Hit.Results.Modifiers2) do
		if (debugMode) then
			print('-- MaximizeDamage on Modifier')
			print('Modifier:')
			_D(modifier)
		end

		local rollParams = modifier.Argument.RollParams[1]

		if rollParams.Result.NaturalRoll > 0 then
			local originalModifierNaturalRoll = rollParams.Result.NaturalRoll
			local originalModifierTotalRoll = rollParams.Result.Total
			local maximizedModifierRoll = getMaximizedDiceRoll(rollParams.Roll.Roll)
			local modifierDamageOffset = maximizedModifierRoll - originalModifierTotalRoll

			rollParams.Result.NaturalRoll = maximizedModifierRoll
			rollParams.Result.Total = maximizedModifierRoll
			damageOffset = damageOffset + modifierDamageOffset
			
			if (debugMode) then
				print('Original modifier natural roll:', maximizedModifierNaturalRoll)
				print('Original modifier total roll:', maximizedModifierTotalRoll)
				print('Maximized modifier roll:', maximizedModifierRoll)
				print('Modifier damage offset:', modifierDamageOffset)
			end
		end
	end
	
	-- Adjust overall damage
	local originalDamage = e.Hit.TotalDamageDone
	local maximizedDamage = originalDamage + damageOffset
	local damageType = e.Hit.DamageType
	e.Hit.TotalDamageDone = maximizedDamage
	e.Hit.DamageList[1].Amount = maximizedDamage
	e.Hit.Results.FinalDamage = maximizedDamage
	e.Hit.Results.FinalDamagePerType[damageType] = maximizedDamage
	e.Hit.Results.TotalDamage = maximizedDamage
	e.Hit.Results.TotalDamagePerType[damageType] = maximizedDamage

	if (debugMode) then
		print('-- MaximizeDamage')
		print('Original damage:', originalDamage)
		print('Original natural roll:', originalNaturalRoll)
		print('Original total roll:', originalTotalRoll)
		print('Maximized damage:', maximizedDamage)
	end
end

local function DumpHit(e)
	if (debugMode) then
		print('-- DumpHit')
		print('--- Hit')
		_D(e.Hit)
	end
end

--- Executes before DealDamage to maximize damage
---@param e EsvLuaBeforeDealDamageEvent
local function DealDamageEventHandler(e)
	if (e.Hit ~= nil and e.Hit.Inflicter ~= nil and e.Hit.Results ~= nil) then
		local inflicter = e.Hit.Inflicter.Uuid.EntityUuid
		local isMaximized = HasActiveStatus(inflicter, "METAMAGIC_MAXIMIZED") == 1
		
		if (Osi.IsPlayer(inflicter)) then
			if (isMaximized) then
				MaximizeDamage(e)
			end

			if (debugMode) then
				DumpHit(e)
			end
		end
	end
end

Ext.Events.BeforeDealDamage:Subscribe(DealDamageEventHandler)
